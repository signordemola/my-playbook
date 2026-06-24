# Booking Playbook — Index

> A living reference for building production-ready booking and service platforms.
> Project-agnostic. Updated as new patterns are learned.
>
> **For AI agents:** Read this file FIRST. Use the routing table below to find
> the right reference for your current task. Do NOT read all files — only the
> ones relevant to your task.

## Core Principles

These principles govern every section in the playbook. Every feature, every file, every decision:

1. **Single Source of Truth (SSOT)** — One function per business rule. Defined in one place. Called from everywhere. If a rule exists in two places, one of them is wrong. The domain layer is the authority — UI, API, and background jobs all defer to it.
2. **Database as Safety Net** — Application logic validates first, but DB constraints (unique indexes, exclusion constraints, check constraints, enums) are the final defence. Never trust application code alone.
3. **Never Trust the Client** — All inputs are re-validated server-side. All mutations are authenticated. All state derives from server/DB, not client-side optimism.
4. **Audit Everything** — Every state transition, every charge, every permission change gets logged. Append-only. Who, what, when, why.
5. **Idempotency by Default** — Every side effect (charge, email, event) uses a business-derived idempotency key. Retries produce the same outcome.

## Code Standards

All code examples in this playbook follow these rules:

- **ES2015+ only** — arrow functions, `const`/`let`, template literals, destructuring
- **TypeScript** — strict mode, no `any`
- **Zod v4** — top-level validators (`z.url()`, `z.email()`, `z.uuid()`), unified `{ error }` param
- **Prisma** — Client Extensions (not deprecated `$use` middleware)
- **Next.js 16** — Server Actions, `use cache`, App Router, Server Components by default
- **UI** — shadcn/ui components with baseui design system

## Routing Table

| File                                                           | Covers                                                                                                             | Read when you are...                                                         |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| [01-concurrency.md](./01-concurrency.md)                       | Locking, GiST constraints, two-phase reservation, Redis soft locks                                                 | Preventing double bookings, handling race conditions, capacity limits        |
| [02-state-machines.md](./02-state-machines.md)                 | Transition maps, XState vs plain code, boolean flag avoidance                                                      | Managing booking/subscription/payment status lifecycle                       |
| [03-billing.md](./03-billing.md)                               | Stripe flows (SetupIntent, PaymentIntent, off-session), dunning, webhooks                                          | Integrating payments, charging cards, handling declines                      |
| [04-idempotency.md](./04-idempotency.md)                       | Key derivation, Stripe/Inngest/Resend idempotency, duplicate prevention                                            | Adding external side effects (charges, emails, events)                       |
| [05-timezones.md](./05-timezones.md)                           | UTC storage, wall-clock vs absolute time, DST, recurring appointments                                             | Working with dates, scheduling, "is this tomorrow?" logic                    |
| [06-availability.md](./06-availability.md)                     | Slot generation, buffer time, capacity/waitlists, schedule rules, calendar sync, availability search               | Building the availability engine, generating slots, querying what's open      |
| [07-audit-trails.md](./07-audit-trails.md)                     | AuditLog schema, who/what/when/why, append-only rules                                                              | Logging state changes, building activity feeds                               |
| [08-cancellation-policies.md](./08-cancellation-policies.md)   | Time-based fees, grace periods, owner overrides                                                                    | Implementing cancellation/refund logic                                       |
| [09-database.md](./09-database.md)                             | N+1 prevention, Prisma Extensions (soft-delete, audit), Neon pooling                                               | Writing queries, optimizing performance, adding cross-cutting DB concerns    |
| [10-email.md](./10-email.md)                                   | SPF/DKIM/DMARC, deliverability rules, domain warming                                                               | Setting up transactional email, debugging spam issues                        |
| [11-security.md](./11-security.md)                             | BOLA, CSRF, rate limiting (Upstash), hashing (Argon2id), cookies, input validation, CSP                            | Securing endpoints, handling auth tokens, protecting PII, adding rate limits |
| [12-events.md](./12-events.md)                                 | Fan-out, compensating transactions, Inngest flow control, queues comparison (Inngest vs BullMQ vs Trigger.dev)     | Adding background jobs, event-driven side effects, choosing a queue system   |
| [13-nextjs.md](./13-nextjs.md)                                 | Server Actions, Server Components, `use cache`, caching, DAL, architecture patterns (guards/DTOs), feature folders | Building Next.js 16 features, caching data, structuring large apps           |
| [14-testing.md](./14-testing.md)                               | Vitest + Playwright, Prisma mocking, integration tests, testing priority                                           | Writing tests, mocking database, setting up CI test pipeline                 |
| [15-accessibility.md](./15-accessibility.md)                   | WCAG 2.2, date pickers, time slots, ARIA rules                                                                     | Building forms, booking UIs, ensuring compliance                             |
| [16-performance.md](./16-performance.md)                       | Core Web Vitals 2026 (LCP/INP/CLS), resource budgets, booking-specific rules                                       | Optimizing page speed, setting performance budgets                           |
| [17-deployment.md](./17-deployment.md)                         | Env validation (Zod v4), security headers, go-live checklist                                                       | Deploying to production, configuring Vercel, pre-launch review               |
| [18-monitoring.md](./18-monitoring.md)                         | Structured logging, SLOs, Sentry, alert thresholds, PII scrubbing                                                  | Setting up error tracking, defining alerts, debugging production             |
| [19-anti-patterns.md](./19-anti-patterns.md)                   | 6 concrete ❌→✅ examples (race conditions, payment trust, timezone bugs)                                          | Reviewing code for common mistakes, onboarding new developers                |
| [20-cheat-sheets.md](./20-cheat-sheets.md)                     | HTTP codes, state machine transitions, quick-reference tables                                                      | Quick lookup during implementation                                           |
| [21-auth.md](./21-auth.md)                                     | Better Auth setup, RBAC, roles/permissions, session management                                                     | Adding authentication, implementing role-based access                        |
| [22-file-uploads.md](./22-file-uploads.md)                     | Presigned URLs, S3 direct upload, multipart, security                                                              | Adding file/image upload features                                            |

## Changelog

| Date       | What Changed                                                                                                                                                                                                        |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-06-24 | **v3** — Restructured from single file to folder. Added §21 Auth, §22 File Uploads. Deepened §11 (security), §12 (queues), §13 (caching/architecture), §14 (testing). Updated all code to Zod v4 + arrow functions. |
| 2026-06-24 | **v2** — Deepened §1, §3, §9, §12. Added §15–§20.                                                                                                                                                                   |
| 2026-06-24 | **v1** — Initial 14 sections.                                                                                                                                                                                       |
