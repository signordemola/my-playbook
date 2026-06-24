## Cheat Sheets — Booking Platforms

> Booking-specific quick-reference tables. For general cheat sheets, see `core/cheat-sheets.md`.

---

### State Machine Transitions

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

BOOKING LIFECYCLE:
  PENDING → DEPOSIT_PAID (deposit received)
  DEPOSIT_PAID → FULLY_PAID (balance received)
  FULLY_PAID → COMPLETED (service delivered)
  PENDING → CANCELLED (cancelled before payment)
  DEPOSIT_PAID → CANCELLED (cancelled after deposit — refund policy applies)
```

---

### Booking Stripe Idempotency Keys

```typescript
const key = `${visitId}-post-clean-charge`       // Charge for a visit
const key = `${bookingId}-deposit`                // Initial deposit
const key = `${bookingId}-balance`                // Balance payment
const key = `${planId}-setup-intent`              // Initial card save
const key = `${visitId}-skip-fee`                 // Late cancellation fee
const key = `${clientId}-refund-${visitId}`       // Refund
```

---

### Booking Zod Schemas

```typescript
import { z } from "zod"

export const BookingFormSchema = z.object({
  name: z.string().min(2, "Name is required"),
  email: z.string().email("Please enter a valid email"),
  phone: z.string().min(10, "Phone number too short"),
  zip: z.string().regex(/^\d{5}$/, "Enter a 5-digit zip code"),
  bedrooms: z.number().int().min(1).max(10),
  bathrooms: z.number().int().min(1).max(10),
  frequency: z.enum(["ONE_TIME", "WEEKLY", "BI_WEEKLY", "MONTHLY"]),
  startDate: z.coerce.date().min(new Date(), "Date must be in the future"),
  specialRequests: z.string().max(500).optional(),
})
```

---

### Booking Event Names

```
booking/created
booking/confirmed
booking/cancelled
visit/completed
visit/skipped
payment/deposit-paid
payment/balance-paid
payment/failed
reminder/24hr
reminder/balance-due
review/requested
```
