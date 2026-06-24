## Anti-Pattern Gallery

> General software anti-patterns. Domain-specific anti-patterns
> (e.g., double-booking, booking-specific race conditions) live in their respective playbooks.

Concrete "don't do this → do this" from real production bugs.

---

### 1. Check-Then-Act Race Condition

The #1 cause of data corruption in concurrent systems. Two requests read the same state before either writes.

```typescript
// ❌ DON'T: Two separate operations — race condition window between check and act
const item = await prisma.item.findFirst({
  where: { id: selectedId, status: "AVAILABLE" },
})
if (item) {
  await prisma.item.update({
    where: { id: item.id },
    data: { status: "RESERVED" },
  })
}

// ✅ DO: Atomic conditional update — no race window
const result = await prisma.$executeRaw`
  UPDATE item SET status = 'RESERVED', user_id = ${userId}
  WHERE id = ${selectedId} AND status = 'AVAILABLE'
`
if (result === 0) throw new Error("Item no longer available")
```

**Why it matters:** Under load, two users can both read `AVAILABLE`, both pass the `if` check, and both write `RESERVED`. The atomic update ensures only one succeeds.

---

### 2. Business Logic in Multiple Places

```
❌ DON'T:
  app/actions/create-order.ts   →  calculates price inline
  app/(portal)/checkout/page.tsx →  calculates price (different formula!)
  lib/workers/charge.ts         →  calculates price (yet another copy)

✅ DO:
  lib/pricing.ts                →  calculatePrice() — THE ONLY PLACE
  Everything else imports and calls calculatePrice()
```

**Real bug:** A promotional discount was applied in the order action but not in the charging function. Clients were quoted $85 but charged $110.

---

### 3. Missing Idempotency on Retried Jobs

Background job systems retry failed jobs automatically. Without idempotency, a retry = duplicate side effect.

```typescript
// ❌ DON'T: No idempotency — retry = duplicate email
await resend.emails.send({
  to: user.email,
  subject: "Your order is confirmed",
})

// ✅ DO: Check before sending + use idempotency key
const alreadySent = await prisma.emailLog.findFirst({
  where: { entityId, type: "CONFIRMATION" },
})
if (!alreadySent) {
  await resend.emails.send({
    to: user.email,
    subject: "Your order is confirmed",
  })
  await prisma.emailLog.create({
    data: { entityId, type: "CONFIRMATION", sentAt: new Date() },
  })
}
```

---

### 4. Holding DB Locks During External Calls

External API calls take 2–5 seconds. A database lock held during that time blocks ALL other transactions on the same row.

```typescript
// ❌ DON'T: Lock held while waiting for Stripe (2–5 seconds)
await prisma.$transaction(async (tx) => {
  const order = await tx.order.update({
    where: { id },
    data: { status: "PROCESSING" },
  })
  await stripe.paymentIntents.create({ amount: order.total }) // SLOW
  await tx.order.update({ where: { id }, data: { status: "PAID" } })
})

// ✅ DO: Separate DB transaction from external call
await prisma.order.update({ where: { id }, data: { status: "PROCESSING" } })
const payment = await stripe.paymentIntents.create({ amount: order.total })
// Final status set by webhook, not by this function
```

---

### 5. The "God Service" Trap

Centralising ALL logic into one service or one file makes every change high-risk.

```
❌ DON'T:
  lib/order-service.ts  →  2000 lines
    - calculatePrice()
    - checkInventory()
    - createOrder()
    - processPayment()
    - sendConfirmation()
    - handleReturn()

✅ DO: Separate by domain
  lib/pricing.ts         →  calculatePrice()
  lib/inventory.ts       →  checkStock(), reserveItem()
  lib/notifications.ts   →  sendConfirmation(), sendReceipt()
  actions/create-order.ts → orchestrates the above
```

**Rule:** Each `lib/` module should do one thing. If the file is > 300 lines, it's doing too much.

---

### 6. Fetching Everything, Showing Little (N+1 & Over-Fetching)

```typescript
// ❌ DON'T: Fetch full records when you only need 3 fields for a list view
const users = await prisma.user.findMany({
  include: {
    orders: { include: { items: true, payments: true } },
    addresses: true,
    auditLogs: true,
  },
})
// Returns 50KB of JSON when the UI card only shows name + status

// ✅ DO: Select only what the UI needs
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    orders: {
      select: { status: true },
      where: { status: "ACTIVE" },
      take: 1,
    },
  },
})
```

**Rule:** Start with `select` (whitelist). Only use `include` when you genuinely need the full related record.

---

### 7. Using `throw` in Server Actions

```typescript
// ❌ DON'T: Throw errors from Server Actions — Next.js shows a generic error page
export async function updateOrder(formData: FormData) {
  "use server"
  const session = await requireAuth()
  if (!session) throw new Error("Unauthorized") // User sees a blank error page
}

// ✅ DO: Return structured results — the component handles UI feedback
export async function updateOrder(
  prevState: ActionResult<Order>,
  formData: FormData
): Promise<ActionResult<Order>> {
  "use server"
  const session = await requireAuth()
  if (!session) return { success: false, errors: { _form: ["Unauthorized"] } }

  // ... business logic
  return { success: true, data: updatedOrder }
}
```

**Exception:** `redirect()` is fine inside Server Actions — it throws internally but Next.js handles it gracefully.

---

### 8. Trusting Client-Side Payment Confirmation

Never mark an entity as paid based on a frontend callback. The client can be spoofed.

```typescript
// ❌ DON'T: Mark as paid based on frontend callback
const handlePayment = async (formData: FormData) => {
  await prisma.order.update({ where: { id }, data: { status: "PAID" } })
}

// ✅ DO: Only mark as paid from Stripe webhook (server-to-server)
// app/api/stripe-webhook/route.ts handles payment_intent.succeeded
// That handler is the ONLY code that sets status to PAID
```

---

### 9. Not Testing Concurrent Access

```
❌ DON'T: Only write sequential unit tests
   test("creates order") → passes with 1 request
   → deploys to production → fails with 50 concurrent requests

✅ DO: Write a concurrency test
   test("prevents double-reservation under concurrent load")
   → Fire 10 simultaneous requests for the same item
   → Assert exactly 1 succeeds and 9 fail with "item unavailable"
```

**Rule:** If a function touches shared state (inventory, capacity, payment status), it needs a concurrency test, not just a unit test.
