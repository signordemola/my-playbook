# My Playbook

A reusable, AI-readable engineering playbook for building production-ready platforms.

Clone it into any project. Your AI agent reads the rules. You ship faster.

---

## What's Inside

```
my-playbook/
├── rules/                     ← Personal coding style + preferences
│   ├── code-style.md          ← TypeScript, naming, error handling
│   ├── project-structure.md   ← Feature folders, file organization
│   └── git-workflow.md        ← Commits, branches, PRs
│
├── playbooks/                 ← Domain-specific deep knowledge
│   ├── booking/               ← 22 chapters on booking platforms
│   ├── ecommerce/             ← Shopping, inventory, checkout
│   ├── ui-ux/                 ← Design taste, components, animations
│   └── dashboard/             ← Admin panels, tables, RBAC
│
├── setup.sh                   ← One-command install into any project
└── README.md                  ← This file
```

## Quick Start

### Install into a project

```bash
# From your project root:
bash /path/to/my-playbook/setup.sh
```

This will:
1. Clone the playbook into `.playbook/` in your project
2. Append your rules to `CLAUDE.md`, `GEMINI.md`, and `AGENTS.md`
3. Your AI agent picks them up automatically

### Use a specific playbook

Tell your AI agent:

```
Read .playbook/playbooks/booking/INDEX.md — follow those patterns.
```

Each playbook has an `INDEX.md` that acts as a routing table — the AI reads only what's relevant to the current task.

---

## Rules vs Playbooks

| | Rules | Playbooks |
|---|---|---|
| **What** | Your personal coding style | Domain-specific knowledge |
| **Scope** | Every project | Only relevant projects |
| **Examples** | "Use early returns", "No `any`" | "How to prevent double bookings" |
| **Loaded by** | `setup.sh` → appended to agent files | Referenced on demand by INDEX.md |

---

## Playbooks

### Booking (22 chapters)
Production patterns for service booking platforms — concurrency, payments, state machines, availability, cancellations, and more. See [playbooks/booking/INDEX.md](playbooks/booking/INDEX.md).

### E-Commerce *(in progress)*
Shopping cart, inventory management, checkout flows, shipping. See [playbooks/ecommerce/INDEX.md](playbooks/ecommerce/INDEX.md).

### UI/UX *(in progress)*
Design taste, component patterns, dark mode, typography, animations. See [playbooks/ui-ux/INDEX.md](playbooks/ui-ux/INDEX.md).

### Dashboard *(in progress)*
Admin panels, data tables, charts, filters, RBAC patterns. See [playbooks/dashboard/INDEX.md](playbooks/dashboard/INDEX.md).

---

## Tech Stack These Patterns Target

| Layer | Tool |
|---|---|
| Framework | Next.js 16 (App Router, Server Components) |
| Auth | Better Auth |
| Database | PostgreSQL (Neon) + Prisma |
| Payments | Stripe |
| Background Jobs | Inngest |
| Email | Resend + React Email |
| Cache | Upstash Redis |
| Monitoring | Sentry + OpenTelemetry |
| Testing | Vitest + Playwright |
| Deployment | Vercel |
