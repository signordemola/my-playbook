# Core Playbook — Index

> Universal engineering patterns for any project.
> Project-agnostic. Updated as new patterns are learned.
>
> **For AI agents:** Read this file FIRST. Use the routing table below to find
> the right reference for your current task. Do NOT read all files — only the
> ones relevant to your task.

## Core Principles

These principles govern every section. Every feature, every file, every decision:

1. **Single Source of Truth (SSOT)** — One function per business rule. Defined in one place. Called from everywhere.
2. **Database as Safety Net** — Application logic validates first, but DB constraints are the final defence.
3. **Never Trust the Client** — All inputs are re-validated server-side. All mutations are authenticated.
4. **Audit Everything** — Every state transition, every charge, every permission change gets logged. Append-only.
5. **Idempotency by Default** — Every side effect uses a business-derived idempotency key.

## Routing Table

| File | Covers | Read when you are... |
| ---- | ------ | -------------------- |
| [database.md](./database.md) | N+1, Prisma Extensions, Neon pooling | Writing queries, optimizing performance |
| [security.md](./security.md) | BOLA, CSRF, rate limiting, CSP | Securing endpoints, handling auth tokens |
| [email.md](./email.md) | SPF/DKIM/DMARC, Resend, warming | Setting up transactional email |
| [auth.md](./auth.md) | Better Auth, RBAC, sessions | Adding authentication, role-based access |
| [billing.md](./billing.md) | Stripe flows, webhooks, dunning | Integrating payments (general) |
| [idempotency.md](./idempotency.md) | Key derivation, duplicate prevention | Adding external side effects |
| [timezones.md](./timezones.md) | UTC storage, DST, IANA zones | Working with dates and scheduling |
| [audit-trails.md](./audit-trails.md) | AuditLog schema, compliance, retention | Logging state changes, activity feeds |
| [events.md](./events.md) | Fan-out, saga, outbox, DLQ, queues | Adding background jobs, event-driven flows |
| [nextjs.md](./nextjs.md) | Server Actions, caching, DAL | Building Next.js 16 features |
| [testing.md](./testing.md) | Vitest, Playwright, Prisma mocking | Writing tests, setting up CI |
| [accessibility.md](./accessibility.md) | WCAG 2.2, ARIA rules | Building forms, ensuring compliance |
| [performance.md](./performance.md) | Core Web Vitals, PPR, next/image | Optimizing page speed |
| [deployment.md](./deployment.md) | Env validation, security headers | Deploying to production |
| [monitoring.md](./monitoring.md) | Pino, OTel, Sentry, SLOs | Setting up error tracking, alerts |
| [file-uploads.md](./file-uploads.md) | Presigned URLs, security | Adding file/image uploads |
| [anti-patterns.md](./anti-patterns.md) | Race conditions, N+1, God service | Reviewing code for common mistakes |
| [cheat-sheets.md](./cheat-sheets.md) | Stripe, Prisma, HTTP codes, Zod | Quick lookup during implementation |
