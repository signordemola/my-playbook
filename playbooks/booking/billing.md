## Billing — Booking Platforms

> Booking-specific billing patterns. For general Stripe integration, see `core/billing.md`.

---

### Deposit + Balance Payment Model

Most booking platforms split payment into two phases:

| Phase | When | Amount | Method |
| ----- | ---- | ------ | ------ |
| **Deposit** | At booking time | 30–50% of total | On-session (customer present) |
| **Balance** | Before or after service delivery | Remaining amount | Off-session or payment link |

#### Flow

```
1. Customer books → PaymentIntent for deposit (on-session)
2. Webhook: payment_intent.succeeded → mark booking as DEPOSIT_PAID
3. Service date approaches → send balance payment link
4. Customer pays balance → webhook → mark as FULLY_PAID
5. Service delivered → mark as COMPLETED
```

#### Edge Cases

- **Customer doesn't pay balance:** Send reminders at Day -7, Day -3, Day -1. If still unpaid at service time, decide: deliver and chase payment, or cancel with policy-based fee.
- **Balance paid but service cancelled:** Refund balance, keep deposit (or apply cancellation policy from `booking/cancellation.md`).
- **Partial refunds:** After service, if quality issue — refund a % of the balance, never the deposit.

---

### Post-Service Charging

For recurring service models (e.g., cleaning subscriptions):

```
Service completed → crew checks out → triggers charge event
→ Off-session PaymentIntent with saved method
→ Webhook confirms → mark visit as CHARGED
```

**Key rule:** Never charge before the service is confirmed as completed. The "checkout" action is the trigger.

---

### Booking-Specific Webhook Events

| Event | Booking Action |
| ----- | -------------- |
| `payment_intent.succeeded` | Set booking to `DEPOSIT_PAID` or `FULLY_PAID` depending on amount |
| `payment_intent.payment_failed` | Start dunning, notify customer with update-payment link |
| `charge.refunded` | Update booking to `REFUNDED`, log in audit trail |

---

### Booking-Specific Idempotency Keys

```typescript
const key = `${visitId}-post-service-charge`    // Charge after service
const key = `${bookingId}-deposit`               // Initial deposit
const key = `${bookingId}-balance`               // Balance payment
const key = `${visitId}-skip-fee`                // Late cancellation fee
const key = `${clientId}-refund-${visitId}`      // Refund
```

---

### Rules

- **Deposit is non-refundable** (unless your cancellation policy says otherwise — see `booking/cancellation.md`).
- **Balance payment link should be login-free** — include a signed token so the customer can pay without creating an account.
- **Track `balanceReminderSentAt`** — so admins can see when the reminder was sent and whether to resend.
- **Off-session charges require prior consent** — the customer must have explicitly saved their card with `usage: "off_session"` during the deposit step.
