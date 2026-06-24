## 4. Idempotency

### Why It Matters

In distributed systems, retries are inevitable — network timeouts, serverless cold starts, queue redeliveries. Without idempotency, a retry can result in:

- **Double charges** — customer billed twice for the same booking
- **Duplicate emails** — "Your booking is confirmed" sent 3 times
- **Duplicate records** — two bookings created for the same slot

Idempotency guarantees that performing the same operation multiple times produces the same result as performing it once.

---

### Idempotency Key Pattern

Every unsafe operation (creates, updates, charges, emails) should accept a unique key that identifies the intent. If the same key is seen again, return the original result instead of re-executing.

#### Key Derivation

Derive keys from **business context**, not random UUIDs:

| Operation | Key Formula | Why |
| --------- | ----------- | --- |
| Charge for a visit | `charge:{visitId}` | One charge per visit, always |
| Booking confirmation email | `email:confirmation:{bookingId}` | One confirmation per booking |
| Review request | `email:review:{visitId}` | One review request per visit |
| Subscription renewal | `charge:renewal:{planId}:{billingPeriod}` | One charge per billing cycle |

**Why not random UUIDs?** A random key only prevents duplicate requests within a single retry session. A business-derived key prevents duplicates across all time — even if two separate processes independently try to charge the same visit.

---

### Implementation Pattern

```
1. Receive operation request with idempotency key
2. Check: have we already processed this key?
   ├── YES → return the stored result (don't re-execute)
   └── NO  → execute the operation
3. Store the key + result atomically in the same transaction
4. Return the result
```

#### Storage Options

| Approach | Pros | Cons |
| -------- | ---- | ---- |
| **Database table** (key + result + timestamp) | Durable, queryable, survives restarts | Slightly slower |
| **Redis** (key with TTL) | Fast, auto-expires | Lost on restart if not persisted |
| **Payment provider passthrough** | Provider handles dedup for you | Only covers payment operations |

**Recommended:** Use a database table for critical operations (payments, bookings). Use Redis for short-lived dedup (API rate limiting, form submissions).

---

### Provider-Level Idempotency

Most payment providers and external APIs support idempotency keys natively. Always pass your key through:

- **Payment charges** — the provider won't process the same key twice
- **Email sends** — some providers support dedup headers
- **Event systems** — durable workflow engines typically handle step-level idempotency automatically

---

### The Email Idempotency Problem

Emails are the most common source of duplicate side effects. Pattern:

```
1. Check: has this email type already been sent for this entity?
   (query an email_log table: bookingId + type)
2. If not sent → send email → record in email_log
3. If already sent → skip
```

The check and the record must happen in the same context to avoid race conditions. If two workers process the same event simultaneously, both might pass the check before either records — use a unique constraint on `(entityId, emailType)` as a safety net.

---

### Rules

- **Derive keys from business context** — `charge:{visitId}` not `charge:{randomUUID}`.
- **Store the key atomically** with the operation result — not before, not after.
- **Pass keys to external providers** — let them handle dedup on their side too.
- **Set a TTL on idempotency records** — keys from 6 months ago don't need to be checked. 24–72 hours is usually sufficient.
- **Unique constraints are your safety net** — even if application logic fails, the database catches duplicates.
- **Log duplicate attempts** — they indicate retries or bugs worth investigating.
