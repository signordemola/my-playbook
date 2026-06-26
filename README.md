# My Playbook

A reusable, AI-readable engineering playbook for building production-ready platforms.

Clone it into any project. Your AI agent reads the rules. You ship faster.

> **AI agents: the current date matters.** Always check the current date/time. Never research or use patterns older than 6 months. Build with the latest tools, not legacy approaches.

---

## What's Inside

```
my-playbook/
├── rules/                     ← Personal coding rules (symlinked into projects)
│   ├── code-style.md          ← Karpathy + Loops + personal rules
│   ├── project-structure.md   ← Kebab-case, code splitting
│   ├── mistakes.md            ← Known AI mistakes to avoid (living file)
│   └── git-workflow.md        ← Git conventions (placeholder)
│
├── playbooks/
│   ├── core/                  ← Universal patterns (18 chapters)
│   │   └── INDEX.md           ← Routing table for AI agents
│   ├── booking/               ← Booking platform patterns (8 chapters)
│   │   └── INDEX.md
│   ├── ecommerce/             ← E-commerce patterns (outline)
│   ├── ui-ux/                 ← UI/UX design patterns (outline)
│   └── dashboard/             ← Admin dashboard patterns (outline)
│
├── learnings-template.md      ← Post-project knowledge capture template
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
1. Clone the playbook into `.playbook/` (gitignored)
2. Symlink each rule file into the project root
3. Create `AGENTS.md` with build/test command placeholders
4. Symlink `CLAUDE.md` → `AGENTS.md` and `GEMINI.md` → `AGENTS.md`

Re-running pulls the latest playbook without overwriting your files.

---

## Rules vs Playbooks

| | Rules | Playbooks |
|---|---|---|
| **What** | Personal coding style | Domain-specific knowledge |
| **Scope** | Every project | Only relevant projects |
| **Examples** | "No comments", "Kebab-case" | "How to prevent double bookings" |
| **Loaded by** | `setup.sh` → symlinked | Referenced on demand via INDEX.md |

---

## Post-Project Learnings

After finishing a project, AI generates a `LEARNINGS.md` using the template in `learnings-template.md`. You review it, then update the playbook with anything worth keeping. This is how the playbook grows over time.

---

## Playbooks

### Core (18 chapters)
Universal patterns — database, security, auth, billing, events, testing, deployment, monitoring, and more. See [core/INDEX.md](playbooks/core/INDEX.md).

### Booking (8 chapters)
Booking-specific — concurrency, state machines, availability, cancellations, deposit/balance billing. See [booking/INDEX.md](playbooks/booking/INDEX.md).

### E-Commerce *(outline)*
Cart, inventory, checkout, shipping. See [ecommerce/INDEX.md](playbooks/ecommerce/INDEX.md).

### UI/UX *(outline)*
Design taste, components, dark mode, animations. See [ui-ux/INDEX.md](playbooks/ui-ux/INDEX.md).

### Dashboard *(outline)*
Admin panels, data tables, RBAC. See [dashboard/INDEX.md](playbooks/dashboard/INDEX.md).

---

## Keeping Rules Effective

> Research shows AI agent compliance drops sharply when rule files exceed ~200 lines.

- Keep each rule file **under 50 lines** — ours are currently 36, 39, and 12 lines
- Use the **"remove test"**: if deleting a rule wouldn't cause the AI to make a mistake, remove it
- Update `rules/mistakes.md` whenever you notice a recurring AI behavior problem
- Prune rules that aren't working — a stale rule file works against you
