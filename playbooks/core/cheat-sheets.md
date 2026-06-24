## Cheat Sheets

> General quick-reference tables. Domain-specific cheat sheets
> (e.g., booking state machines) live in their respective playbooks.

Scan these, don't read them.

---

### Stripe Object Cheat Sheet

| Object | Purpose | When to Create |
| --- | --- | --- |
| `Customer` | Represents a person/business | At signup or first purchase |
| `SetupIntent` | Save a card without charging | During onboarding (card-on-file) |
| `PaymentIntent` | Charge a card | At checkout or off-session |
| `PaymentMethod` | The saved card/bank details | Attached to Customer via SetupIntent |
| `Webhook` | Server-to-server event notification | Listen for `payment_intent.succeeded`, `.failed` |
| `Idempotency Key` | Prevent duplicate operations | Every mutating API call |

#### Stripe Lifecycle Flows

```
SAVE CARD (SetupIntent):
  Client creates SetupIntent → Stripe Elements collects card
  → stripe.confirmSetup() → webhook: setup_intent.succeeded
  → PaymentMethod attached to Customer automatically

CHARGE CARD (PaymentIntent — on_session):
  Server creates PaymentIntent → Client confirms in browser
  → webhook: payment_intent.succeeded → mark entity as PAID

CHARGE SAVED CARD (off_session):
  Server creates PaymentIntent with:
    customer, payment_method, off_session: true, confirm: true
  → webhook: payment_intent.succeeded → mark as CHARGED
  → OR webhook: payment_intent.payment_failed → start dunning
```

---

### Prisma Query Cheat Sheet

| Need | Pattern |
| --- | --- |
| **Fetch with relations** | `findMany({ include: { user: true } })` |
| **Fetch only needed fields** | `findMany({ select: { id: true, name: true } })` |
| **Atomic multi-write** | `$transaction([update, create, delete])` |
| **Conditional update** | `$executeRaw` with `WHERE status = 'AVAILABLE'` |
| **Prevent duplicates** | `upsert({ where, create, update })` |
| **Soft delete** | Prisma Extension (see `core/database.md`) |
| **Count efficiently** | `count({ where: { status: "ACTIVE" } })` |
| **Paginate** | `findMany({ take: 20, skip: 0, cursor: { id } })` |
| **Order by relation count** | `orderBy: { orders: { _count: "desc" } }` |
| **Filter by relation** | `where: { user: { status: "ACTIVE" } }` |

#### Prisma Transaction Patterns

```typescript
// Sequential batch — all succeed or all fail
await prisma.$transaction([
  prisma.order.update({ where: { id }, data: { status: "PROCESSING" } }),
  prisma.auditLog.create({ data: { ... } }),
])

// Interactive — when you need logic between writes
await prisma.$transaction(async (tx) => {
  const order = await tx.order.findUniqueOrThrow({ where: { id } })
  if (order.status !== "PENDING") throw new Error("Order is not pending")
  await tx.order.update({ where: { id }, data: { status: "CONFIRMED" } })
  await tx.auditLog.create({ data: { ... } })
})

// ⚠️ NEVER do external API calls inside $transaction
// The lock is held until the transaction closes
```

---

### HTTP Status Code Cheat Sheet

| Code | Meaning | Context |
| --- | --- | --- |
| `200` | OK | Successful read |
| `201` | Created | Resource created |
| `400` | Bad Request | Validation failed (Zod error) |
| `401` | Unauthorized | Missing or invalid auth token |
| `403` | Forbidden | Authenticated but not permitted (BOLA) |
| `404` | Not Found | Resource doesn't exist or not yours |
| `409` | Conflict | Concurrent modification conflict |
| `422` | Unprocessable Entity | Business rule violation (e.g., past date) |
| `429` | Too Many Requests | Rate limit exceeded |
| `500` | Internal Server Error | Unexpected failure — log + alert |
| `503` | Service Unavailable | Database down, external service outage |

---

### Zod Validation Cheat Sheet

```typescript
import { z } from "zod"

// Common reusable schemas
const emailSchema = z.string().email("Please enter a valid email")
const phoneSchema = z.string().min(10, "Phone number too short")
const priceSchema = z.number().int().positive() // Store in cents
const dateSchema = z.coerce.date().min(new Date(), "Date must be in the future")
const urlSchema = z.string().url("Please enter a valid URL")
const uuidSchema = z.string().uuid("Invalid ID format")

// Reuse across client AND server
export const ContactFormSchema = z.object({
  name: z.string().min(2, "Name is required"),
  email: emailSchema,
  phone: phoneSchema.optional(),
  message: z.string().max(1000, "Message too long"),
})
```

---

### Next.js File Conventions Cheat Sheet

| File | Purpose | When to Add |
| --- | --- | --- |
| `page.tsx` | Route component | Every route |
| `layout.tsx` | Shared wrapper | Route groups |
| `loading.tsx` | Suspense fallback (skeleton) | Every route |
| `error.tsx` | Error boundary | Every route group |
| `not-found.tsx` | 404 page | Top-level + important routes |
| `route.ts` | API endpoint | External callers only (webhooks) |
| `proxy.ts` | Auth middleware | Project root |
| `instrumentation.ts` | OTel/Sentry init | Project root |
| `global-error.tsx` | Root error boundary | `app/` root |

---

### Inngest Function Cheat Sheet

| Config | Syntax | Use Case |
| --- | --- | --- |
| **Retry count** | `retries: 3` | Override default 4 retries |
| **No retry** | `throw new NonRetriableError()` | Hard declines, invalid data |
| **Delay** | `await step.sleep("wait", "2h")` | Delayed follow-up actions |
| **Concurrency** | `concurrency: { limit: 1, key: "event.data.userId" }` | Prevent double-processing |
| **Throttle** | `throttle: { limit: 10, period: "1m" }` | Protect API rate limits |
| **Debounce** | `debounce: { key: "event.data.id", period: "30s" }` | Process only last update |
| **Parallel steps** | `Promise.all([step.run("a", ...), step.run("b", ...)])` | Fan-out side effects |
| **Cron job** | `cron: "0 9 * * *"` | Daily scheduled tasks |
| **Cancel on** | `cancelOn: [{ event: "entity/cancelled" }]` | Stop if entity is cancelled |

#### Inngest Event Naming Convention

```
Noun/verb:
  order/created
  payment/failed
  user/updated
  subscription/paused
  reminder/24hr

Avoid generic names:
  ❌ update
  ❌ process
  ❌ handle
```
