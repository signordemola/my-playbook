## 8. Cancellation Policy Engines

### Cancellation ≠ Just a Status Change

A cancellation is a **multi-step orchestration**, not a single database update:

```
1. Validate the cancellation is allowed (policy check)
2. Calculate the fee (time-based rules)
3. Process the refund or charge (payment provider)
4. Update the booking status (state machine — see §2)
5. Free the availability slot (see §6)
6. Notify the customer (email/SMS)
7. Log the entire sequence (audit trail — see §7)
```

If any step fails, the system enters an inconsistent state. Treat cancellation as a workflow, not a flag flip.

---

### Time-Based Fee Logic

Fees increase as the cancellation gets closer to the appointment:

| Window | Fee | Rationale |
| ------ | --- | --------- |
| **72+ hours before** | 0% (free cancel) | Plenty of time to fill the slot |
| **48–72 hours** | 25% | Short notice, but slot may still fill |
| **24–48 hours** | 50% | Unlikely to fill, partial recovery |
| **< 24 hours** | 100% | Slot is effectively lost |
| **No-show** | 100% + potential surcharge | Worst outcome — no notice, wasted resources |

#### Key Decisions

- **What does "hours before" mean?** → Use the **business timezone**, not UTC (see §5). A 48-hour check in UTC can be 47 or 49 hours in the customer's timezone.
- **Is the fee based on the full price or the amount paid?** → Usually the full service price, not just the deposit.
- **Who gets the fee — the business or the provider?** → Define this in your business model. For marketplaces, the fee may split.

---

### Cancellation vs No-Show

These are different events with different handling:

| Event | Customer Action | System Response |
| ----- | --------------- | --------------- |
| **Cancellation** | Customer actively cancels before the appointment | Apply time-based fee, free the slot, send confirmation |
| **No-show** | Customer never arrives, never communicates | Mark as no-show after a grace window (e.g., 15 min past start), charge the full fee |

**No-show detection:** The provider (or system) marks the customer as a no-show. This should require explicit action — never auto-assume no-show just because a booking wasn't checked in.

---

### Grace Periods & Goodwill

#### First-Offence Grace

Auto-waive the first late cancellation fee for new customers:

- Builds trust, reduces churn
- Track per-customer: `first_cancellation_waived: true`
- Only applies once — subsequent late cancellations incur the full fee

#### Post-Booking Grace

Allow a brief free-cancel window immediately after booking (e.g., 15–30 minutes), regardless of how close the appointment is:

- Catches impulse bookings and accidental clicks
- Prevents "buyer's remorse" disputes
- Common in consumer protection law in many jurisdictions

---

### Refund Types

| Type | When to Use | Impact |
| ---- | ----------- | ------ |
| **Full refund** | Free cancellation window, business error | Customer gets full amount back via original payment method |
| **Partial refund** | Late cancellation within fee window | Customer gets (price - fee) back |
| **Store credit / voucher** | Goodwill gesture, or as an alternative to cash refund | Retains revenue within the business, incentivizes return |
| **No refund** | No-show, very late cancellation | Customer already charged; no money returned |

**Critical:** Always process refunds through the **same payment method** used for the original charge. Never issue a refund to a different method — this is a money laundering red flag.

---

### Owner Override

Admins and business owners must be able to override any cancellation policy:

- Waive fees for VIP customers or special circumstances (medical emergency, bereavement)
- Issue discretionary refunds outside normal policy
- **Every override must be logged** with the admin's identity and reason (see §7)
- Track override frequency — excessive overrides suggest the policy itself is too strict

---

### Dispute & Chargeback Prevention

Most cancellation-related chargebacks happen because of poor communication, not bad intent:

| Prevention | How |
| ---------- | --- |
| **Show the fee before confirmation** | "Cancelling will incur a $65 fee. Continue?" |
| **Display the policy at booking time** | Require explicit acceptance (checkbox or "I agree") |
| **Include policy in confirmation email** | Customer can't claim they weren't informed |
| **Send reminder before the deadline** | "Your free cancellation window closes in 24 hours" |
| **Provide easy self-service cancellation** | A link in the confirmation email — don't force them to call/email support |

If a dispute does occur, your audit trail (see §7) should contain:
1. The policy version the customer accepted at booking time
2. The timestamp of the cancellation request
3. The fee calculation and how it was derived
4. The refund (or explanation of why no refund was issued)

---

### Rescheduling as an Alternative

Before applying a cancellation fee, offer rescheduling:

- Customer keeps their booking, just moves it to a new date/time
- Business retains the revenue
- The original slot is freed for someone else
- Limit the number of reschedules (e.g., 2 max) to prevent abuse

**Rescheduling should follow the same availability rules as a new booking** (see §6). The customer can't reschedule to a slot that doesn't exist.

---

### Rules

- **Cancellation is a workflow, not a flag.** It involves policy checks, payment processing, slot freeing, notifications, and audit logging — all coordinated.
- **Show the fee before the user confirms.** No surprises. Transparency reduces disputes.
- **Calculate fees in the business timezone.** Not UTC, not the server's timezone.
- **Distinguish cancellation from no-show.** They have different fees, different triggers, and different customer communication.
- **Log every override and its reason.** Discretionary refunds are fine — undocumented ones are a liability.
- **Offer rescheduling before cancellation.** It's better for the business and better for the customer.
- **Process refunds through the original payment method.** No exceptions.
- **Track cancellation patterns.** High cancellation rates signal a pricing, communication, or UX problem — not just "flaky customers."
