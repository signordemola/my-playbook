## 1. Concurrency & Double-Booking Prevention

### Two-Phase Reservation

Never "check then book" — the slot can be taken between the check and the write.

1. **Soft Lock** — Hold the resource in Redis/cache with a TTL (3–10 min) while the user completes payment or a multi-step form.
2. **Hard Booking** — On success, write an ACID-compliant record to your primary database. If the user abandons, the TTL expires and the slot frees automatically.

---

### Redis Soft Lock Pattern

Use `SET key value NX EX ttl` — atomic "set if not exists" with auto-expiry.

```
ACQUIRE:  SET  lock:slot:{resourceId}:{time}  {uniqueId}  NX  EX  300
RELEASE:  Lua script — only delete if value matches {uniqueId}
```

| Step | What Happens |
| ---- | ------------ |
| User selects slot | `SET NX EX` creates a soft lock with a unique ID |
| User completes payment | Hard booking written to DB, lock released |
| User abandons | TTL expires, slot becomes available automatically |
| Another user tries same slot | `SET NX` fails → "Slot is being held, try again shortly" |

**Critical:** Always use a unique ID as the lock value. Release with a Lua script that checks the value before deleting — prevents accidentally releasing someone else's lock.

---

### Database-Level Invariants

Application bugs happen. The database is your last line of defence:

- **`UNIQUE` indexes** prevent duplicate records
- **PostgreSQL GiST exclusion constraints** prevent overlapping time ranges
- If the app has a bug AND the DB constraint catches it, you're still safe

```sql
-- Prevent overlapping bookings for the same resource (PostgreSQL)
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE booking ADD CONSTRAINT no_overlap
  EXCLUDE USING gist (
    resource_id WITH =,
    tstzrange(start_time, end_time) WITH &&
  );
```

> **Source:** [PostgreSQL — Exclusion Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-EXCLUSION)

---

### Locking Strategies

| Strategy | When to Use | Watch Out For |
| -------- | ----------- | ------------- |
| **Optimistic** (version column) | Low contention (< 20 concurrent writes to same resource) | Need retry logic on version mismatch |
| **Pessimistic** (`SELECT FOR UPDATE`) | High contention (tickets, flash sales) | Thread exhaustion, deadlocks |
| **Distributed** (Redis lock + TTL) | Multi-node / serverless | Orphaned locks without TTL |

#### Optimistic Locking

Add a `version` column. On update, increment it and filter by the expected version. If no rows are affected, another request modified it first — retry or fail.

```
WHERE id = :id AND version = :expectedVersion
SET   version = version + 1, ...
```

#### Pessimistic Locking

Lock the row so other transactions must wait:

```sql
SELECT * FROM seat WHERE id = :id AND status = 'AVAILABLE' FOR UPDATE;
-- Row is locked until this transaction commits or rolls back
```

---

### Decision Flowchart

```
Is your app serverless / multi-node?
├── YES → Redis Soft Lock (SET NX EX) for reservation phase
│         + DB constraint as safety net
└── NO  → Is contention high? (>50 concurrent writes to same resource)
          ├── YES → SELECT FOR UPDATE (pessimistic)
          └── NO  → Version column (optimistic, with retry)
```

### Rules

- **Redis lock = coordination.** The database constraint = source of truth. Always have both layers.
- **Start with optimistic locking.** Most booking systems for small service businesses never need pessimistic locks.
- **Never hold a DB lock during an external API call** (e.g., Stripe). The lock blocks all other transactions on that row.
- **Always set a TTL** on distributed locks. Without it, a crashed process holds the lock forever.
