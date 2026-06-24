## 19. Anti-Pattern Gallery

Concrete "don't do this → do this" from real booking system bugs and common production mistakes.

---

### 1. Check-Then-Act Race Condition

The #1 cause of double bookings. Two requests read the same "available" state before either writes.

```typescript
// ❌ DON'T: Two separate operations — race condition window between check and book
const slot = await prisma.slot.findFirst({
  where: { time: selectedTime, status: "AVAILABLE" },
})
if (slot) {
  await prisma.slot.update({
    where: { id: slot.id },
    data: { status: "BOOKED" },
  })
}

// ✅ DO: Atomic conditional update — no race window
const result = await prisma.$executeRaw`
  UPDATE slot SET status = 'BOOKED', client_id = ${clientId}
  WHERE time = ${selectedTime} AND status = 'AVAILABLE'
`
if (result === 0) throw new Error("Slot no longer available")
```

**Why it matters:** Under load, two users can both read `AVAILABLE`, both pass the `if` check, and both write `BOOKED`. The atomic update ensures only one succeeds.

---

### 2. Trusting Client-Side Payment Confirmation

Never mark a booking as paid based on a frontend callback. The client can be spoofed, the network can drop, or the user can close the tab mid-flow.

```typescript
// ❌ DON'T: Mark as paid based on frontend callback
const handleBooking = async (formData: FormData) => {
  // Client says "payment succeeded" — but they could forge this
  await prisma.booking.update({ where: { id }, data: { status: "PAID" } })
}

// ✅ DO: Only mark as paid from Stripe webhook (server-to-server)
// app/api/stripe-webhook/route.ts handles payment_intent.succeeded
// That handler is the ONLY code that sets status to PAID
```

**Rule of thumb:** The webhook is your source of truth for payment status. The frontend can show "processing..." but the database state only changes from the webhook.

---

### 3. Timezone Math in Local Time

```typescript
// ❌ DON'T: Compare dates without timezone context
const isLate = differenceInHours(booking.startTime, new Date()) < 24

// ✅ DO: All comparisons in the business timezone
import { utcToZonedTime } from "date-fns-tz"
const BUSINESS_TZ = env.BUSINESS_TIMEZONE  // e.g., "America/Chicago"
const now = utcToZonedTime(new Date(), BUSINESS_TZ)
const start = utcToZonedTime(booking.startTime, BUSINESS_TZ)
const isLate = differenceInHours(start, now) < 24
```

**Real bug:** Cancellation fee wrongly applied at 11pm CT because `new Date()` returned UTC midnight (the next day). The client was charged $65 for a "late cancel" that was actually 25 hours away in their timezone.

---

### 4. Business Logic in Multiple Places

```
❌ DON'T:
  app/actions/create-booking.ts  →  calculates price inline
  app/(portal)/book/page.tsx     →  calculates price (different formula!)
  lib/inngest/charge.ts          →  calculates price (yet another copy)

✅ DO:
  lib/pricing.ts                 →  calculatePrice() — THE ONLY PLACE
  Everything else imports and calls calculatePrice()
```

**Real bug:** A promotional discount was applied in the booking action but not in the charging function. Clients were quoted $85 but charged $110. One function was updated, the other was forgotten.

---

### 5. Missing Idempotency on Retried Jobs

Background job systems retry failed jobs automatically. Without idempotency, a retry = duplicate side effect.

```typescript
// ❌ DON'T: No idempotency — retry = duplicate email
await resend.emails.send({
  to: client.email,
  subject: "Your booking is confirmed",
})

// ✅ DO: Check before sending + use idempotency key
const alreadySent = await prisma.emailLog.findFirst({
  where: { bookingId, type: "CONFIRMATION" },
})
if (!alreadySent) {
  await resend.emails.send({
    to: client.email,
    subject: "Your booking is confirmed",
  })
  await prisma.emailLog.create({
    data: { bookingId, type: "CONFIRMATION", sentAt: new Date() },
  })
}
```

**Real bug:** Inngest retried a failed charge function 3 times. Each retry also sent a "payment failed" email. Client received 3 identical "please update your card" emails in 2 minutes.

---

### 6. Holding DB Locks During External Calls

Stripe API calls take 2–5 seconds. A database lock held during that time blocks ALL other transactions on the same row.

```typescript
// ❌ DON'T: Lock held while waiting for Stripe (2–5 seconds)
await prisma.$transaction(async (tx) => {
  const booking = await tx.booking.update({
    where: { id },
    data: { status: "PROCESSING" },
  })
  await stripe.paymentIntents.create({ amount: booking.price }) // SLOW
  await tx.booking.update({ where: { id }, data: { status: "PAID" } })
})

// ✅ DO: Separate DB transaction from external call
await prisma.booking.update({ where: { id }, data: { status: "PROCESSING" } })
const payment = await stripe.paymentIntents.create({ amount: booking.price })
// Final status set by webhook, not by this function
```

---

### 7. The "God Service" Trap

Centralising ALL logic (pricing, inventory, payments, notifications, scheduling) into one service or one file makes every change high-risk.

```
❌ DON'T:
  lib/booking-service.ts  →  2000 lines
    - calculatePrice()
    - checkAvailability()
    - createBooking()
    - processPayment()
    - sendConfirmation()
    - generateRecurringVisits()
    - handleCancellation()

✅ DO: Separate by domain
  lib/pricing.ts          →  calculatePrice()
  lib/availability.ts     →  checkCapacity(), getAvailableSlots()
  lib/scheduling.ts       →  generateVisits(), rescheduleVisit()
  lib/plan.ts             →  pausePlan(), cancelPlan(), resumePlan()
  actions/create-booking.ts → orchestrates the above
```

**Rule:** Each `lib/` module should do one thing. If the file is > 300 lines, it's doing too much.

---

### 8. Fetching Everything, Showing Little (N+1 & Over-Fetching)

```typescript
// ❌ DON'T: Fetch full records when you only need 3 fields for a list view
const clients = await prisma.client.findMany({
  include: {
    plans: { include: { visits: true, assignedCrew: { include: { cleaners: true } } } },
    payments: true,
    auditLogs: true,
  },
})
// Returns 50KB of JSON when the UI card only shows name + status + next visit date

// ✅ DO: Select only what the UI needs
const clients = await prisma.client.findMany({
  select: {
    id: true,
    name: true,
    plans: {
      select: { status: true },
      where: { status: "ACTIVE" },
      take: 1,
    },
  },
})
```

**Rule:** Start with `select` (whitelist). Only use `include` (include all fields) when you genuinely need the full related record.

---

### 9. Using `throw` in Server Actions

```typescript
// ❌ DON'T: Throw errors from Server Actions — Next.js shows a generic error page
export async function pausePlan(formData: FormData) {
  "use server"
  const session = await requireOwner()
  if (!session) throw new Error("Unauthorized") // User sees a blank error page
}

// ✅ DO: Return structured results — the component handles UI feedback
export async function pausePlan(
  prevState: ActionResult<Plan>,
  formData: FormData
): Promise<ActionResult<Plan>> {
  "use server"
  const session = await requireOwner()
  if (!session) return { success: false, errors: { _form: ["Unauthorized"] } }

  // ... business logic
  return { success: true, data: updatedPlan }
}
```

**Exception:** `redirect()` is fine inside Server Actions — it throws internally but Next.js handles it gracefully.

---

### 10. Not Testing Concurrent Access

```
❌ DON'T: Only write sequential unit tests
   test("creates booking") → passes with 1 request
   → deploys to production → fails with 50 concurrent requests

✅ DO: Write a concurrency test
   test("prevents double-booking under concurrent load")
   → Fire 10 simultaneous requests for the same slot
   → Assert exactly 1 succeeds and 9 fail with "slot unavailable"
```

**Rule:** If a function touches shared state (slots, crew capacity, payment status), it needs a concurrency test, not just a unit test.
