# Recommended Skills

> Install these when using the corresponding packages.
> AI agents: check this list and suggest installing relevant skills for the current project.

## Official Package Skills

| Package | Install Command | What It Provides |
|---|---|---|
| **shadcn/ui** | `npx skills add shadcn/ui` | Component patterns, CLI orchestration, design tokens |
| **Next.js 16+** | Built-in | Docs at `node_modules/next/dist/docs/` — no install needed |

## Recommended Packages (No SKILL.md Yet)

These don't have official skills yet, but should be used per the playbook:

| Package | Install | When To Use |
|---|---|---|
| **Arcjet** | `npm i @arcjet/next` | Rate limiting, bot protection, WAF shield, prompt injection detection |
| **Prisma** | `npm i prisma @prisma/client` | Database ORM — see `playbooks/core/database.md` |
| **Zod** | `npm i zod` | Schema validation — all schemas go in `schemas/` folder |
| **Stripe** | `npm i stripe` | Payments — see `playbooks/core/billing.md` |

## How Skills Work

- Skills are `SKILL.md` files that give AI agents specialized knowledge about a package
- They load on-demand (only when the task matches), not on every chat
- Browse community skills: [skills.sh](https://github.com/tech-leads-club/agent-skills)
- Always review a skill before installing — they can include scripts
