# Booking Playbook — Index

> Patterns for building production-ready booking and service platforms.
> For general patterns (database, security, auth, etc.), see `core/INDEX.md`.
>
> **For AI agents:** Read `core/INDEX.md` FIRST for universal patterns.
> Then read this file for booking-specific patterns. Only load the files
> relevant to your current task.

## Booking-Specific Patterns

These chapters cover what makes booking platforms unique — slot management,
recurring services, cancellation policies, and booking-specific payment flows.

## Routing Table

| File | Covers | Read when you are... |
| ---- | ------ | -------------------- |
| [concurrency.md](./concurrency.md) | Double-booking prevention, slot locking, GiST constraints | Preventing race conditions on slots/capacity |
| [state-machines.md](./state-machines.md) | Booking/plan/visit lifecycle, transition maps | Managing booking status lifecycle |
| [availability.md](./availability.md) | Slot generation, buffer time, capacity, calendar sync | Building the availability engine |
| [cancellation.md](./cancellation.md) | Time-based fees, grace periods, refund policies, timezone math | Implementing cancellation/refund logic |
| [billing.md](./billing.md) | Deposit/balance model, post-service charging | Booking-specific payment flows |
| [events.md](./events.md) | Booking fan-out, reserve→charge→confirm saga | Building booking side-effect workflows |
| [anti-patterns.md](./anti-patterns.md) | Double-booking race, timezone bugs, slot testing | Reviewing booking code for common mistakes |
| [cheat-sheets.md](./cheat-sheets.md) | State machine transitions, booking Zod schemas | Quick reference during implementation |

## Also Read (from Core)

These core chapters are essential for any booking platform:

| Core File | Why It's Relevant |
| --------- | ----------------- |
| `core/billing.md` | General Stripe integration (webhooks, dunning, idempotency) |
| `core/idempotency.md` | Prevent duplicate charges, emails, and bookings |
| `core/audit-trails.md` | Log every booking state change for dispute resolution |
| `core/security.md` | Protect booking endpoints, rate limit submissions |
| `core/database.md` | Prisma patterns, N+1 prevention for booking queries |
