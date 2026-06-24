## 7. Audit Trails

### Why Audit Trails ≠ Application Logs

| Concept | Purpose | Consumer | Lifetime |
| ------- | ------- | -------- | -------- |
| **Application logs** | Debug errors, trace requests | Developers | Days to weeks |
| **Audit trail** | Prove what happened to a business entity | Business, compliance, legal, dispute resolution | Months to years |

Your application logs answer "why did the server throw a 500?" Audit trails answer "who changed this booking, when, and why?" They serve entirely different purposes and should be stored separately.

---

### What to Log

Every state change to a core business entity must capture:

| Field | What It Records | Example |
| ----- | --------------- | ------- |
| **Who** (actor) | User, admin, system process, or API key | `client:abc123`, `admin:maya`, `system:scheduler` |
| **What** (action + diff) | The change that occurred, with before/after state | `booking.cancelled`, before: `{ status: "CONFIRMED" }` → after: `{ status: "CANCELLED" }` |
| **When** (timestamp) | UTC with high precision | `2026-06-24T14:30:00.000Z` |
| **Why** (reason) | Human-readable justification | `"Client requested"`, `"Auto-cancelled: payment failed after 3 retries"` |
| **Context** (metadata) | Request ID, IP address, user agent | Enables correlation across services |

### What NOT to Log

- **PII in cleartext** — mask credit card numbers, hash emails if stored long-term
- **Full request/response bodies** — log only the fields that changed, not the entire entity
- **Secrets** — never log tokens, passwords, or API keys, even accidentally

---

### Schema Pattern

An audit log table typically looks like:

| Column | Type | Purpose |
| ------ | ---- | ------- |
| `id` | Primary key | Unique identifier for this log entry |
| `entity` | String | What type of thing changed: `booking`, `payment`, `plan` |
| `entity_id` | String | The specific record that changed |
| `action` | String | What happened: `booking.confirmed`, `payment.refunded` |
| `actor` | String | Who did it |
| `before` | JSON (nullable) | Previous state of changed fields |
| `after` | JSON (nullable) | New state of changed fields |
| `reason` | String (nullable) | Why the change was made |
| `request_id` | String (nullable) | Correlation ID for cross-service tracing |
| `created_at` | Timestamp (UTC) | When the event occurred |

**Indexes:** `(entity, entity_id)` for looking up an entity's history. `(created_at)` for time-range queries. `(actor)` for "what did this user do?" queries.

---

### Immutability & Tamper Resistance

Audit trails must be **provably unmodified**. If someone disputes a charge, your evidence must be credible.

| Level | Technique | Protects Against |
| ----- | --------- | ---------------- |
| **Basic** | Database permissions — revoke UPDATE/DELETE on the audit table | Accidental modification |
| **Strong** | Append-only storage, no admin delete access | Intentional modification by staff |
| **Cryptographic** | Hash chaining — each entry includes a hash of the previous entry | Undetectable tampering (any modification breaks the chain) |
| **External** | WORM storage (Write-Once-Read-Many) — S3 Object Lock, immutable blob storage | Even infrastructure admins can't modify |

**For most booking systems:** Basic + Strong is sufficient. Cryptographic hashing is for financial-grade or regulated industries. Pick the level that matches your compliance requirements.

---

### Writing Audit Logs

**Rule:** The audit log must be written in the **same transaction** as the mutation it records. If the mutation fails, the audit log rolls back. If the audit log fails, the mutation rolls back. They are atomic.

```
BEGIN TRANSACTION
  1. Update booking status to CANCELLED
  2. Insert audit log entry (who, what, when, why)
COMMIT
```

If you can't use a transaction (e.g., the mutation is an external API call), write the audit log entry **after** confirming the external operation succeeded — and make the write idempotent (see §4).

---

### Retention & Compliance

| Regulation | Requirement | Implication |
| ---------- | ----------- | ----------- |
| **GDPR** | Storage limitation — don't keep data longer than necessary | Define a retention policy (e.g., 2 years for bookings, 7 years for financial records) |
| **SOC 2** | Prove logs exist, are protected, and are reviewed | Centralize logs, restrict access, alert on anomalies |
| **PCI DSS** | Log access to cardholder data | Mask card numbers, log who accessed payment info |

#### Tiered Retention

- **Hot** (0–90 days): Full detail, fast queries, active troubleshooting
- **Warm** (90 days – 2 years): Compressed, still queryable, for dispute resolution
- **Cold** (2–7 years): Encrypted archive, for legal/compliance holds only
- **Delete** (after retention period): Automated, defensible deletion with a log of *what was deleted and when*

---

### Using Audit Trails for Dispute Resolution

When a customer disputes a charge, your audit trail is your evidence:

| Evidence Needed | Audit Trail Provides |
| --------------- | -------------------- |
| "Customer agreed to the policy" | `booking.created` entry with policy version accepted |
| "Customer was notified" | `notification.sent` entry with channel and timestamp |
| "Cancellation happened after the deadline" | `booking.cancelled` entry with timestamp vs. booking start time |
| "Refund was already processed" | `payment.refunded` entry with amount and transaction ID |

**If you can't prove it from the audit trail, it didn't happen** — at least as far as a payment dispute is concerned.

---

### Activity Feeds (User-Facing Audit)

Audit trails also power user-facing activity feeds ("Booking history", "Recent changes"):

- **Filter by audience** — clients see their own events. Admins see all events. System-level events (cron jobs, automated retries) are admin-only.
- **Use human-readable descriptions** — transform `booking.confirmed` into "Booking confirmed by Maya" for display.
- **Paginate** — activity feeds grow unbounded. Always paginate, never load all.

---

### Rules

- **Append-only.** Never update or delete audit records. If a correction is needed, add a new entry that supersedes the old one.
- **Atomic with the mutation.** Write the audit log in the same transaction as the state change.
- **Not for debugging.** Use structured application logs for debugging. Audit trails are for business accountability.
- **Minimize PII.** Store only what you need. Mask sensitive fields. Follow data minimization principles.
- **Audit the auditors.** Log who *accesses* the audit trail, not just who creates entries.
- **Define retention early.** Don't figure it out after you have 10 million rows. Set policies before launch.
- **Separate storage.** If your primary database is compromised, the audit trail should survive. Consider writing to a separate, read-only store.
