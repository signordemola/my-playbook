## Event-Driven Architecture

> General event-driven patterns for any project. Domain-specific event flows
> (e.g., booking fan-out sequences) live in their respective playbooks.

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
order.completed (event)
  ├── send confirmation email (immediate)
  ├── update inventory (immediate)
  ├── generate invoice (immediate)
  └── request feedback (2-hour delay)
```

**Key:** Each downstream handler is **independent**. If the email fails, the inventory still updates. If the invoice fails, the feedback request still sends. This is intentional — it's the opposite of a transaction.

---

### The Saga Pattern (Distributed Transactions)

When a workflow spans multiple services and you need coordinated outcomes:

```
Reserve inventory → Charge payment → Confirm order
```

If any step fails, previous steps must be **compensated** (reversed):

```
If charge fails → Release inventory reservation
If confirmation fails → Refund payment → Release inventory
```

| Approach | How It Works | Best For |
| -------- | ------------ | -------- |
| **Orchestration** | A central coordinator manages the workflow, calling each step and handling failures | Complex, multi-step workflows |
| **Choreography** | Each service reacts to events independently, emitting new events | Loosely coupled, simpler flows |

**Orchestration is preferred for most transactional workflows** — the coordinator has visibility into the entire flow, making debugging and retry logic clearer.

#### Compensating Transaction Rules

- **Don't undo actions that represent reality** — if the service was already delivered, you can't un-do it. Mark it as failed and enter a recovery flow.
- **Compensating actions must be idempotent** (see `core/idempotency.md`) — they may be retried.
- **Log every step and every compensation** — the audit trail (see `core/audit-trails.md`) must reconstruct the full sequence.

---

### The Outbox Pattern

Prevents the "dual write" problem: you update the database AND publish an event, but what if the event publish fails?

```
❌  Update DB → Publish event (event might be lost if publish fails)
✅  Update DB + write event to "outbox" table (same transaction)
    → Background worker polls outbox → publishes event → marks as processed
```

This guarantees: if the DB write succeeded, the event will eventually be published.

**2026 tip:** Include a `schema_version` field in event payloads for backward compatibility as your events evolve.

---

### Flow Control Patterns

| Pattern | What It Does | Example |
| ------- | ------------ | ------- |
| **Concurrency limit** | Max N parallel executions of the same function | 1 concurrent charge per customer — prevents double-charging |
| **Throttle** | Max N executions per time period | 10 emails/minute — prevents hitting provider rate limits |
| **Debounce** | Only process the last event in a time window | User updates preferences 5 times in 10 seconds — process only the last one |
| **Priority queue** | Process high-priority jobs first | Payment retries before notification sends |

---

### Retry Strategy

| Failure Type | Retry? | Strategy |
| ------------ | ------ | -------- |
| **Transient** (network timeout, 500) | Yes | Exponential backoff: 1s → 2s → 4s → 8s → max 3–5 retries |
| **Rate limit** (429) | Yes | Wait for `Retry-After` header, then retry |
| **Permanent** (400, invalid data, hard decline) | No | Fail immediately, don't retry. Log and alert. |

**Non-retriable errors:** When a step fails permanently, throw a non-retriable error so the workflow engine stops retrying and escalates.

---

### Dead Letter Queues (DLQ)

When a job fails all retry attempts:

1. Move it to a Dead Letter Queue (DLQ)
2. **Never silently drop failed jobs** — financial data and state changes must never be lost
3. Alert ops/engineering for manual inspection
4. DLQ items should include the original event, failure reason, and retry count

---

### Queue / Workflow Engine Comparison

| Tool Type | Characteristics | Best For |
| --------- | --------------- | -------- |
| **Durable workflow engine** (serverless) | Managed, event-driven, built-in retries/delays, no infra | Post-action side effects, fan-out, delays |
| **Long-running task engine** | Managed compute, supports 5+ minute jobs | Heavy processing, report generation, AI tasks |
| **Traditional queue + workers** (Redis-backed) | Self-hosted, full control, high throughput | 10K+ jobs/hour, granular priority queues |
| **DB-backed job queue** | State lives in your primary database, simple setup | Simple reliable tasks, minimal infrastructure |

---

### Rules

- **Never do heavy processing in the request path.** Offload to a background system.
- **Each step in a workflow must be idempotent.** Background workers will retry on failure.
- **Decouple event producers from consumers.** The producing service should not know which services consume its events.
- **Use compensating transactions, not rollbacks.** In distributed systems, you can't undo an external API call — you issue a compensation.
- **Dead letter queues are mandatory.** Never silently drop failed jobs.
- **Monitor background job failures.** A failed payment charge that sits unprocessed is lost revenue.
- **Monitor consumer lag.** Track how far behind consumers are — this is the most critical metric.
- **Separate functions by failure domain.** If the email handler fails, it should not prevent the payment handler from running.
- **Log every event emission and consumption.** Combined with the audit trail, this makes debugging asynchronous workflows possible.
