## Billing & Payment Integration

> General Stripe patterns for any project. Domain-specific billing flows
> (e.g., booking deposits, ecommerce checkout) live in their respective playbooks.

---

### On-Session vs Off-Session Charging

| Type | Who Initiates | Example | Requirements |
| ---- | ------------- | ------- | ------------ |
| **On-session** | Customer is present | Checkout, one-time purchase | Standard payment form |
| **Off-session** | Merchant initiates | Subscription renewal, post-service charge | Saved payment method + prior consent |

---

### Saving a Payment Method for Later

Before you can charge off-session, you must capture and store a payment method while the customer is actively present:

1. **Create a setup flow** with `usage: "off_session"` — tells Stripe this method will be used later without the customer present
2. **Customer completes authentication** (3D Secure, bank verification)
3. **Store the payment method reference** (`pm_xxx`) against the Stripe Customer in your database
4. **Now you can charge later** without the customer being present

---

### Off-Session Charging Pattern

1. Create a PaymentIntent with `off_session: true` + the saved payment method
2. **Always include an idempotency key** (see `core/idempotency.md`) — prevents duplicate charges on retry
3. If the charge fails with a **soft decline** (insufficient funds, temporary issue) → enter dunning
4. If the charge fails with a **hard decline** (stolen card, invalid) → stop retrying immediately

---

### Dunning (Failed Payment Recovery)

When an off-session charge fails, don't cancel immediately. Use a tiered retry strategy:

```
Day 0:  Charge fails → mark as FAILED, notify customer
Day 3:  1st retry → try again automatically
Day 7:  2nd retry → try again, send update-payment-method link
Day 14: 3rd retry → final attempt
Day 15: Mark as CANCELLED, revoke access, send final notice
```

#### Rules

- **Distinguish soft vs hard declines.** Retry soft declines (insufficient funds, temporary errors). Never retry hard declines (stolen card, closed account).
- **Notify the customer** at each retry step with a login-free link to update their payment method.
- **Grace period:** During dunning, keep limited access — don't cut them off on the first failure.
- **Capped retries:** 3–4 attempts max. Use Stripe Smart Retries where available.
- **Pre-dunning:** Send notifications before a card expires. Prevention beats recovery.

---

### Webhook-Driven Payment Confirmation

**Never trust the client.** A frontend callback ("payment succeeded!") can be forged, dropped, or delayed. Only update payment status from server-to-server webhook events.

#### The Pattern

```
Stripe → Webhook → Your server → Verify signature → Return 200 → Queue processing
```

1. **Verify the HMAC signature** — `stripe.webhooks.constructEvent(body, sig, secret)`
2. **Return 200 immediately** — acknowledge receipt before processing business logic
3. **Push heavy work to a background queue** — database updates, emails, audit logs
4. **Track processed event IDs** — store each Stripe event ID in a `processed_events` table with a unique constraint. Skip duplicates.
5. **Handle out-of-order events** — events can arrive in unexpected order. Check current state before applying.

#### Common Events to Listen For

| Event | Action |
| ----- | ------ |
| `payment_intent.succeeded` | Mark entity as PAID, send confirmation |
| `payment_intent.payment_failed` | Mark as FAILED, start dunning |
| `setup_intent.succeeded` | Store payment method for future use |
| `charge.refunded` | Log refund, update entity status |
| `customer.subscription.deleted` | Handle subscription cancellation |
| `invoice.payment_failed` | Start subscription dunning sequence |

---

### Reconciliation Backstop

Webhooks can fail or be delayed. Implement a periodic reconciliation job:

- **Daily job** compares your internal payment records against Stripe's reporting API
- **Catches drift** — orphaned payments, missing webhook deliveries, status mismatches
- **Logs discrepancies** for manual review
- **Never auto-fix** without logging — financial data requires an audit trail (see `core/audit-trails.md`)

---

### Database Isolation

- Store only Stripe identifiers in your database: `stripe_customer_id`, `stripe_payment_method_id`, `stripe_subscription_id`
- **Never store raw card data** — let Stripe handle PCI compliance
- Pin your **Stripe API version** in code — update deliberately, not accidentally

---

### Rules

- **The webhook is your source of truth for payment status.** Not the frontend, not the API response.
- **Every charge must have an idempotency key** (see `core/idempotency.md`).
- **Never hold a database lock while calling a payment API.** Separate the DB transaction from the external call.
- **Log everything.** Every charge attempt, every webhook received, every retry — append-only audit trail.
- **Test with Stripe's test mode** before going live. Simulate declined cards, expired methods, and webhook failures using the Stripe CLI.
