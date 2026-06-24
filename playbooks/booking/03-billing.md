## 3. Subscription Billing & Dunning

### On-Session vs Off-Session Charging

| Type | Who Initiates | Example | Requirements |
| ---- | ------------- | ------- | ------------ |
| **On-session** | Customer is present | Checkout, initial booking payment | Standard payment form |
| **Off-session** | Merchant initiates | Recurring subscription, post-visit charge | Saved payment method + prior consent |

---

### Saving a Payment Method for Later

Before you can charge off-session, you must capture and store a payment method while the customer is actively present:

1. **Create a setup flow** with `usage: "off_session"` — tells the payment provider this method will be used later without the customer present
2. **Customer completes authentication** (3D Secure, bank verification)
3. **Store the payment method reference** against the customer in your database
4. **Now you can charge later** without the customer being present

---

### Off-Session Charging Pattern

1. Create a charge with `off_session: true` + the saved payment method
2. **Always include an idempotency key** (see §4) — prevents duplicate charges on retry
3. If the charge fails with a soft decline (insufficient funds, temporary issue) → enter dunning
4. If the charge fails with a hard decline (stolen card, invalid) → stop retrying immediately

---

### Dunning (Failed Payment Recovery)

When a recurring charge fails, don't cancel immediately. Use a tiered retry strategy:

```
Day 0:  Charge fails → mark as FAILED, notify customer
Day 3:  1st retry → try again automatically
Day 7:  2nd retry → try again, send stronger notification
Day 14: 3rd retry → final attempt
Day 15: Mark as CANCELLED, revoke access, send final notice
```

#### Rules

- **Distinguish soft vs hard declines.** Retry soft declines (insufficient funds, temporary errors). Never retry hard declines (stolen card, closed account).
- **Notify the customer** at each retry step with instructions to update their payment method.
- **Grace period:** During dunning, the customer should retain limited access — don't cut them off on the first failure.
- **Capped retries:** 3–4 attempts max. Beyond that, you're wasting API calls and annoying the customer.

---

### Webhook-Driven Payment Confirmation

**Never trust the client.** A frontend callback ("payment succeeded!") can be forged, dropped, or delayed. Only update payment status from server-to-server webhook events.

#### The Pattern

```
Payment provider → Webhook → Your server → Update database
```

1. **Verify the signature** — cryptographically validate that the webhook came from your payment provider (HMAC-SHA256 or equivalent)
2. **Return 200 immediately** — acknowledge receipt before processing business logic
3. **Push heavy work to a background queue** — database updates, emails, audit logs
4. **Handle duplicate deliveries** — webhooks can be sent more than once; your handler must be idempotent (see §4)

#### What to Listen For

| Event | Action |
| ----- | ------ |
| `payment.succeeded` | Mark booking as PAID, send confirmation, trigger side effects |
| `payment.failed` | Mark as FAILED, start dunning sequence |
| `payment_method.attached` | Store method reference for off-session use |
| `refund.created` | Log refund, update booking status |

---

### Reconciliation Backstop

Webhooks can fail or be delayed. Implement a periodic reconciliation job:

- **Daily job** compares your internal payment records against the provider's reporting API
- **Catches drift** — orphaned payments, missing webhook deliveries, status mismatches
- **Logs discrepancies** for manual review
- **Never auto-fix** without logging — financial data requires an audit trail (see §7)

### Rules

- **The webhook is your source of truth for payment status.** Not the frontend, not the API response.
- **Every charge must have an idempotency key** (see §4).
- **Never hold a database lock while calling the payment API.** Separate the DB transaction from the external call.
- **Log everything.** Every charge attempt, every webhook received, every retry — append-only audit trail.
- **Test with the provider's test/sandbox mode** before going live. Simulate declined cards, expired methods, and webhook failures.
