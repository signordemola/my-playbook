# My Playbook

A reusable, AI-readable engineering playbook for building production-ready platforms.

Clone it into any project. Your AI agent reads the rules. You ship faster.

---

## What's Inside

```
my-playbook/
├── rules/                     ← Personal coding style + preferences
│   ├── code-style.md          ← TypeScript, naming, error handling
│   ├── project-structure.md   ← Feature folders, DAL pattern, file naming
│   └── git-workflow.md        ← Conventional commits, branches, PRs
│
├── playbooks/
│   ├── core/                  ← Universal patterns (18 chapters)
│   │   └── INDEX.md           ← Routing table for AI agents
│   ├── booking/               ← Booking platform patterns (8 chapters)
│   │   └── INDEX.md
│   ├── ecommerce/             ← E-commerce patterns (outline)
│   ├── ui-ux/                 ← Design taste + component patterns (outline)
│   └── dashboard/             ← Admin panel patterns (outline)
│
├── setup.sh                   ← One-command install into any project
└── README.md                  ← This file
```

## Quick Start

### Install into a project

```bash
# From your project root:
bash /path/to/my-playbook/setup.sh

# Or download and run:
curl -sL https://raw.githubusercontent.com/signordemola/my-playbook/main/setup.sh | bash
```

This will:
1. Clone the playbook into `.playbook/` (hidden folder in your project)
2. Append your coding rules to `CLAUDE.md`, `GEMINI.md`, and `AGENTS.md`
3. Add `.playbook/` to `.gitignore`

Re-running the script updates existing rules without duplication.

### Tell your AI agent

```
Read .playbook/playbooks/core/INDEX.md — follow those patterns.
```

For booking projects:
```
Read .playbook/playbooks/core/INDEX.md and .playbook/playbooks/booking/INDEX.md
```

---

## Rules vs Playbooks

| | Rules | Playbooks |
|---|---|---|
| **What** | Your personal coding style | Domain-specific knowledge |
| **Scope** | Every project | Only relevant projects |
| **Examples** | "Use early returns", "No `any`" | "How to prevent double bookings" |
| **Loaded by** | `setup.sh` → appended to agent files | Referenced on demand via INDEX.md |

---

## Playbooks

### Core (18 chapters)
Universal engineering patterns — database, security, auth, billing, events, testing, deployment, monitoring, and more. See [core/INDEX.md](playbooks/core/INDEX.md).

### Booking (8 chapters)
Booking-specific patterns — concurrency, state machines, availability, cancellations, deposit/balance billing, and more. See [booking/INDEX.md](playbooks/booking/INDEX.md).

### E-Commerce *(outline)*
Shopping cart, inventory, checkout, shipping. See [ecommerce/INDEX.md](playbooks/ecommerce/INDEX.md).

### UI/UX *(outline)*
Design taste, components, dark mode, animations. See [ui-ux/INDEX.md](playbooks/ui-ux/INDEX.md).

### Dashboard *(outline)*
Admin panels, data tables, charts, RBAC. See [dashboard/INDEX.md](playbooks/dashboard/INDEX.md).

---

## Tech Stack

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
