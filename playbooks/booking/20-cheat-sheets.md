## 20. Cheat Sheets

Quick-reference tables for the most common patterns. Scan these, don't read them.

---

### Stripe Object Cheat Sheet

| Object            | Purpose                             | When to Create                                   |
| ----------------- | ----------------------------------- | ------------------------------------------------ |
| `Customer`        | Represents a person/business        | At signup or first booking                       |
| `SetupIntent`     | Save a card without charging        | During onboarding (card-on-file)                 |
| `PaymentIntent`   | Charge a card                       | At booking time or off-session                   |
| `PaymentMethod`   | The saved card/bank details         | Attached to Customer via SetupIntent             |
| `Webhook`         | Server-to-server event notification | Listen for `payment_intent.succeeded`, `.failed` |
| `Idempotency Key` | Prevent duplicate operations        | Every mutating API call                          |

#### Stripe Lifecycle Flows

```
SAVE CARD (SetupIntent):
  Client creates SetupIntent → Stripe Elements collects card
  → stripe.confirmSetup() → webhook: setup_intent.succeeded
  → PaymentMethod attached to Customer automatically

CHARGE CARD (PaymentIntent — on_session):
  Server creates PaymentIntent → Client confirms in browser
  → webhook: payment_intent.succeeded → mark booking as PAID

CHARGE SAVED CARD (off_session):
  Server creates PaymentIntent with:
    customer, payment_method, off_session: true, confirm: true
  → webhook: payment_intent.succeeded → mark visit as CHARGED
  → OR webhook: payment_intent.payment_failed → start dunning
```

#### Stripe Idempotency Key Patterns

```typescript
// Naming convention: {entityId}-{action}
const key = `${visitId}-post-clean-charge`       // Charge for a visit
const key = `${planId}-setup-intent`              // Initial card save
const key = `${visitId}-skip-fee`                 // Late cancellation fee
const key = `${clientId}-refund-${visitId}`       // Refund

// Usage:
await stripe.paymentIntents.create(
  { amount: 18500, customer: stripeCustomerId, ... },
  { idempotencyKey: `${visitId}-post-clean-charge` }
)
```

---

### Prisma Query Cheat Sheet

| Need                          | Pattern                                                 |
| ----------------------------- | ------------------------------------------------------- |
| **Fetch with relations**      | `findMany({ include: { client: true } })`               |
| **Fetch only needed fields**  | `findMany({ select: { id: true, name: true } })`        |
| **Atomic multi-write**        | `$transaction([update, create, delete])`                |
| **Conditional update**        | `$executeRaw` with `WHERE status = 'AVAILABLE'`         |
| **Prevent duplicates**        | `upsert({ where, create, update })`                     |
| **Soft delete**               | Prisma Extension (see Section 9)                        |
| **Count efficiently**         | `count({ where: { status: "ACTIVE" } })`                |
| **Paginate**                  | `findMany({ take: 20, skip: 0, cursor: { id } })`      |
| **Order by relation count**   | `orderBy: { visits: { _count: "desc" } }`               |
| **Filter by relation**        | `where: { client: { status: "ACTIVE" } }`               |

#### Prisma Transaction Patterns

```typescript
// Sequential batch — all succeed or all fail
await prisma.$transaction([
  prisma.plan.update({ where: { id }, data: { status: "PAUSED" } }),
  prisma.visit.deleteMany({ where: { planId: id, status: "SCHEDULED" } }),
  prisma.auditLog.create({ data: { ... } }),
])

// Interactive — when you need logic between writes
await prisma.$transaction(async (tx) => {
  const plan = await tx.plan.findUniqueOrThrow({ where: { id } })
  if (plan.status !== "ACTIVE") throw new Error("Plan is not active")
  await tx.plan.update({ where: { id }, data: { status: "PAUSED" } })
  await tx.auditLog.create({ data: { ... } })
})

// ⚠️ NEVER do external API calls inside $transaction
// The lock is held until the transaction closes
```

---

### Inngest Function Cheat Sheet

| Config             | Syntax                                                  | Use Case                      |
| ------------------ | ------------------------------------------------------- | ----------------------------- |
| **Retry count**    | `retries: 3`                                            | Override default 4 retries    |
| **No retry**       | `throw new NonRetriableError()`                         | Hard declines, invalid data   |
| **Delay**          | `await step.sleep("wait", "2h")`                        | Review request after visit    |
| **Concurrency**    | `concurrency: { limit: 1, key: "event.data.clientId" }` | Prevent double-charge         |
| **Throttle**       | `throttle: { limit: 10, period: "1m" }`                 | Protect email API rate limits |
| **Debounce**       | `debounce: { key: "event.data.id", period: "30s" }`     | Process only last update      |
| **Parallel steps** | `Promise.all([step.run("a", ...), step.run("b", ...)])` | Fan-out side effects          |
| **Cron job**       | `cron: "0 9 * * *"`                                     | Daily morning reminders       |
| **Cancel on**      | `cancelOn: [{ event: "plan/cancelled" }]`               | Stop if plan is cancelled     |

#### Inngest Event Naming Convention

```
Noun/verb:
  booking/created
  visit/completed
  payment/failed
  plan/paused
  reminder/24hr

Avoid generic names:
  ❌ update
  ❌ process
  ❌ handle
```

---

### HTTP Status Code Cheat Sheet

| Code  | Meaning               | Booking Context                           |
| ----- | --------------------- | ----------------------------------------- |
| `200` | OK                    | Successful read                           |
| `201` | Created               | Booking confirmed                         |
| `400` | Bad Request           | Validation failed (Zod error)             |
| `401` | Unauthorized          | Missing or invalid auth token             |
| `403` | Forbidden             | Authenticated but not the owner (BOLA)    |
| `404` | Not Found             | Booking doesn't exist or not yours        |
| `409` | Conflict              | Slot already booked (race condition)      |
| `422` | Unprocessable Entity  | Business rule violation (e.g., past date) |
| `429` | Too Many Requests     | Rate limit exceeded                       |
| `500` | Internal Server Error | Unexpected failure — log + alert          |
| `503` | Service Unavailable   | Database down, Stripe outage              |

---

### State Machine Transitions Cheat Sheet

```
PLAN LIFECYCLE:
  ACTIVE → PAUSED (client pauses)
  ACTIVE → CANCELLED (client cancels — terminal)
  PAUSED → ACTIVE (resume, auto or manual)
  PAUSED → CANCELLED (cancel while paused — terminal)

VISIT LIFECYCLE:
  SCHEDULED → CONFIRMED (24hr reminder sent)
  CONFIRMED → IN_PROGRESS (crew checked in)
  IN_PROGRESS → COMPLETED (crew checked out → triggers charge)
  SCHEDULED → SKIPPED (client skips — may incur fee)
  SCHEDULED → CANCELLED (owner cancels)

PAYMENT LIFECYCLE:
  PENDING → PROCESSING (charge initiated)
  PROCESSING → SUCCEEDED (webhook: payment_intent.succeeded)
  PROCESSING → FAILED (webhook: payment_intent.payment_failed)
  FAILED → RETRYING (dunning — automatic retry)
  RETRYING → SUCCEEDED (retry worked)
  RETRYING → FAILED (all retries exhausted — escalate to owner)
```

---

### Zod Validation Cheat Sheet

```typescript
import { z } from "zod"

// Common booking form schemas
const emailSchema = z.string().email("Please enter a valid email")
const phoneSchema = z.string().min(10, "Phone number too short")
const zipSchema = z.string().regex(/^\d{5}$/, "Enter a 5-digit zip code")
const bedroomsSchema = z.number().int().min(1).max(10)
const dateSchema = z.coerce.date().min(new Date(), "Date must be in the future")
const priceSchema = z.number().int().positive() // Store in cents

// Reuse across client AND server
export const BookingFormSchema = z.object({
  name: z.string().min(2, "Name is required"),
  email: emailSchema,
  phone: phoneSchema,
  zip: zipSchema,
  bedrooms: bedroomsSchema,
  bathrooms: z.number().int().min(1).max(10),
  frequency: z.enum(["ONE_TIME", "WEEKLY", "BI_WEEKLY", "MONTHLY"]),
  startDate: dateSchema,
  specialRequests: z.string().max(500).optional(),
})
```

---

### Next.js File Conventions Cheat Sheet

| File | Purpose | When to Add |
| ---- | ------- | ----------- |
| `page.tsx` | Route component | Every route |
| `layout.tsx` | Shared wrapper | Route groups |
| `loading.tsx` | Suspense fallback (skeleton) | Every route |
| `error.tsx` | Error boundary | Every route group |
| `not-found.tsx` | 404 page | Top-level + important routes |
| `route.ts` | API endpoint | External callers only (webhooks) |
| `proxy.ts` | Auth middleware | Project root |
| `instrumentation.ts` | OTel/Sentry init | Project root |
| `global-error.tsx` | Root error boundary | `app/` root |
