## 2. State Machine Design

### Never Use Boolean Flags for Status

```
❌  isPaused: true, isCancelled: false, isActive: false
✅  status: "PAUSED"
```

Boolean flags create **impossible states** — a record can be `isPaused: true` AND
`isActive: true`. A single `status` enum with a transition map makes illegal transitions impossible.

---

### Define a Transition Map

A simple record that maps each state to its allowed next states:

```typescript
const ALLOWED_TRANSITIONS: Record<Status, Status[]> = {
  PENDING: ["CONFIRMED", "CANCELLED"],
  CONFIRMED: ["IN_PROGRESS", "CANCELLED"],
  IN_PROGRESS: ["COMPLETED"],
  COMPLETED: ["DISPUTED"],
  CANCELLED: [],   // terminal — no transitions out
  DISPUTED: [],     // terminal
};
```

Validate **before** writing to the database. Reject invalid transitions at the application layer, and back it up with a DB check constraint if possible.

---

### Common Booking System Lifecycles

#### Booking

```
PENDING → CONFIRMED → IN_PROGRESS → COMPLETED
PENDING → CANCELLED (free cancel)
CONFIRMED → CANCELLED (may incur fee — see §8)
COMPLETED → DISPUTED
```

#### Subscription / Recurring Plan

```
ACTIVE → PAUSED → ACTIVE (resume)
ACTIVE → CANCELLED (terminal)
PAUSED → CANCELLED (terminal)
```

#### Payment

```
PENDING → PROCESSING → SUCCEEDED
PROCESSING → FAILED → RETRYING → SUCCEEDED
PROCESSING → FAILED → RETRYING → FAILED (dunning)
SUCCEEDED → REFUNDED (terminal)
```

---

### Discriminated Unions for Type-Safe States

When each status carries different data, use a discriminated union so TypeScript enforces exhaustive handling:

```typescript
type BookingState =
  | { status: "PENDING"; createdAt: Date }
  | { status: "CONFIRMED"; confirmedAt: Date; paymentId: string }
  | { status: "COMPLETED"; completedAt: Date; rating?: number }
  | { status: "CANCELLED"; cancelledAt: Date; reason: string; fee: number };
```

The compiler forces you to handle every case in `switch` statements — no forgotten edge cases.

---

### Database Integration Pattern

Always transition + audit atomically in a single transaction:

1. **Read** the current status
2. **Validate** the transition against the transition map
3. **Write** the new status + create an audit log entry (see §7)
4. All in **one transaction** — if the audit log insert fails, the status change rolls back

---

### When to Use a Library vs Plain Code

| Approach | Use When |
| -------- | -------- |
| **Plain TypeScript map** | < 6 states, flat lifecycle, team knows the domain well |
| **Discriminated unions** | Each state carries different data, need exhaustive type checking |
| **XState / state machine library** | Complex nested states, need visual debugging, model-based test generation |

**Rule of thumb:** If you can draw the state machine on a napkin, use plain code.
If you need a tool to understand it, use a library.

**Migration signal:** When your manual logic starts handling async side effects, race conditions, or deeply nested sub-states — that's when to adopt a library.

### Rules

- **Define terminal states explicitly** — they return `[]` from the transition map.
- **Log every transition** — who, when, from what, to what (see §7 Audit Trails).
- **Never skip states** — if a booking goes from PENDING → COMPLETED, something is wrong.
- **Status should be an enum in your DB schema** — not a free-text string column.
