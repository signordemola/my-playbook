## Events — Booking Platforms

> Booking-specific event flows. For general event-driven patterns, see `core/events.md`.

---

### Booking Fan-Out

When a booking is completed, multiple independent side effects trigger:

```
booking.completed (event)
  ├── send confirmation email (immediate)
  ├── charge payment method (immediate)
  ├── send receipt (after payment succeeds)
  └── request review (2-hour delay)
```

Each handler is independent — if the email fails, the charge still happens.

---

### Booking Saga: Reserve → Charge → Confirm

```
Check availability → Reserve slot → Charge deposit → Confirm booking
```

Compensations if any step fails:

```
If charge fails → Release slot reservation
If confirmation fails → Refund deposit → Release slot
```

**Use orchestration** — the coordinator has visibility into the entire booking flow, making debugging and retry logic clearer.

---

### Booking Event Naming Convention

```
booking/created
booking/confirmed
booking/cancelled
visit/completed
visit/skipped
payment/deposit-paid
payment/balance-paid
payment/failed
reminder/24hr
reminder/balance-due
review/requested
```

---

### Booking-Specific Flow Control

| Pattern | Booking Use Case |
| ------- | ---------------- |
| **Concurrency: 1 per client** | Prevent double-charging the same client |
| **Debounce: 30s** | Client updates booking details multiple times — process only the final version |
| **Delay: 2 hours** | Send review request 2 hours after service completion |
| **Cancel on: booking/cancelled** | Stop pending side effects if booking is cancelled |
| **Cron: daily 9am** | Send 24-hour reminders for tomorrow's bookings |
