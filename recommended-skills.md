# Recommended Skills

> AI agents: check this list and suggest installing relevant skills for the current project.

## Official Package Skills

| Package | Install Command | What It Provides |
|---|---|---|
| **shadcn/ui** | `npx skills add shadcn/ui` | Component patterns, CLI orchestration, design tokens |
| **Next.js 16+** | Built-in | Docs at `node_modules/next/dist/docs/` — no install needed |

## Recommended Packages

| Package | Install | When To Use |
|---|---|---|
| **Arcjet** | `npm i @arcjet/next` | EVERY project. Rate limiting, bot protection, WAF shield |
| **Prisma** | `npm i prisma @prisma/client` | Database ORM — see `playbooks/core/database.md` |
| **Zod** | `npm i zod` | Schema validation — all schemas go in `schemas/` folder |
| **Stripe** | `npm i stripe` | Payments — see `playbooks/core/billing.md` |
