## 12. Event-Driven Architecture

### When to Use Events vs Direct Calls

| Pattern | Use When |
| ------- | -------- |
| **Direct call** (synchronous) | Must succeed together, same process, latency-sensitive |
| **Event emission** (asynchronous) | Can fail independently, has delays, multiple consumers, fan-out |

**Rule of thumb:** If one action triggers multiple independent side effects, use events. If everything must succeed or fail together, use a transaction.

---

### Fan-Out Pattern

When one action triggers multiple independent side effects:

```
booking.completed (event)
  ├── send confirmation email (immediate)
  ├── charge payment method (immediate)
  ├── send receipt (after payment succeeds)
  └── request review (2-hour delay)
```

**Key:** Each downstream handler is **independent**. If the email fails, the charge still happens. If the charge fails, the review request still sends. This is the opposite of a transaction — it's intentional.

---

### The Saga Pattern (Distributed Transactions)

When a workflow spans multiple services and you need coordinated outcomes:

```
Reserve seat → Charge payment → Confirm booking
```

If any step fails, previous steps must be **compensated** (reversed):

```
If charge fails → Release seat reservation
If confirmation fails → Refund payment → Release seat
```

| Approach | How It Works | Best For |
| -------- | ------------ | -------- |
| **Orchestration** | A central coordinator manages the workflow, calling each step and handling failures | Complex, multi-step booking flows |
| **Choreography** | Each service reacts to events independently, emitting new events | Loosely coupled, simpler flows |

**Orchestration is preferred for booking systems** — the coordinator has visibility into the entire workflow, making debugging and retry logic clearer.

#### Compensating Transaction Rules

- **Don't undo upstream actions that represent reality** — if the cleaning already happened, you can't un-do it. Mark it as `paymentStatus: FAILED` and enter a recovery flow.
- **Compensating actions must be idempotent** (see §4) — they may be retried.
- **Log every step and every compensation** — the audit trail (see §7) must reconstruct the full sequence.

---

### The Outbox Pattern

Prevents the "dual write" problem: you update the database AND publish an event, but what if the event publish fails?

```
❌  Update DB → Publish event (event might be lost if publish fails)
✅  Update DB + write event to "outbox" table (same transaction)
    → Background worker polls outbox → publishes event → marks as processed
```

This guarantees: if the DB write succeeded, the event will eventually be published.

---

### Flow Control Patterns

When processing background jobs, you need to control how work is distributed:

| Pattern | What It Does | Example |
| ------- | ------------ | ------- |
| **Concurrency limit** | Max N parallel executions of the same function | 1 concurrent charge per client — prevents double-charging |
| **Throttle** | Max N executions per time period | 10 emails/minute — prevents hitting provider rate limits |
| **Debounce** | Only process the last event in a time window | Client updates preferences 5 times in 10 seconds — process only the last one |
| **Priority queue** | Process high-priority jobs first | Payment retries before review requests |

---

### Retry Strategy

| Failure Type | Retry? | Strategy |
| ------------ | ------ | -------- |
| **Transient** (network timeout, 500) | Yes | Exponential backoff: 1s → 2s → 4s → 8s → max 3–5 retries |
| **Rate limit** (429) | Yes | Wait for `Retry-After` header, then retry |
| **Permanent** (400, invalid data, hard decline) | No | Fail immediately, don't retry. Log and alert. |

**Non-retriable errors:** When a step fails permanently (e.g., stolen card, invalid data), throw a non-retriable error so the workflow engine stops retrying and escalates.

---

### Dead Letter Queues (DLQ)

When a job fails all retry attempts:

1. Move it to a Dead Letter Queue (DLQ)
2. **Never silently drop failed jobs** — financial data and booking state changes must never be lost
3. Alert ops/engineering for manual inspection
4. DLQ items should include the original event, failure reason, and retry count

---

### Queue / Workflow Engine Comparison

| Tool Type | Characteristics | Best For |
| --------- | --------------- | -------- |
| **Durable workflow engine** (serverless) | Managed, event-driven, built-in retries/delays, no infra | Post-booking side effects, fan-out, delays |
| **Long-running task engine** | Managed compute, supports 5+ minute jobs | Heavy processing, report generation, AI tasks |
| **Traditional queue + workers** (Redis-backed) | Self-hosted, full control, high throughput | 10K+ jobs/hour, granular priority queues |
| **DB-backed job queue** | State lives in your primary database, simple setup | Simple reliable tasks, minimal infrastructure |

#### When to Use What

| Scenario | Tool Type |
| -------- | --------- |
| Post-booking side effects (email + charge + review) | Durable workflow engine |
| Nightly report generation (heavy, 5+ min) | Long-running task engine |
| 10K+ bookings/hour, need granular priority queues | Traditional queue + workers |
| Simple reliable tasks, minimal infra | DB-backed job queue |

---

### Rules

- **Never do heavy processing in the request path.** Offload to a background system. The user shouldn't wait for email sends or report generation.
- **Each step in a workflow must be idempotent.** Background workers will retry on failure (see §4).
- **Decouple event producers from consumers.** The booking service should not know which services consume its events.
- **Use compensating transactions, not rollbacks.** In distributed systems, you can't undo an external API call — you issue a compensation (refund, release, etc.).
- **Dead letter queues are mandatory.** Never silently drop failed jobs.
- **Monitor background job failures.** Use tools with visual dashboards. A failed charge that sits unprocessed is lost revenue.
- **Separate functions by failure domain.** If the email handler fails, it should not prevent the payment handler from running.
- **Log every event emission and consumption.** Combined with the audit trail, this makes debugging asynchronous workflows possible.
