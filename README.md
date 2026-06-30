# My Playbook

A reusable, AI-readable engineering playbook for building production-ready platforms.

Clone it into any project. Your AI agent reads the rules. You ship faster.

> **AI agents: the current date matters.** Always check the current date/time. Never research or use patterns older than 6 months. Build with the latest tools, not legacy approaches.

---

## What's Inside

```
my-playbook/
├── rules/                     ← Personal coding rules
│   ├── code-style.md          ← Karpathy + Loops + personal rules
│   ├── project-structure.md   ← Kebab-case, code splitting
│   ├── mistakes.md            ← Known AI mistakes to avoid (living file)
│   ├── cursor-rules.md        ← Copy-paste rules for Cursor settings UI
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
├── recommended-skills.md      ← Package skills to install per project
├── learnings-template.md      ← Post-project knowledge capture template
├── setup.sh                   ← One-command install (supports --global and --force)
└── README.md                  ← This file
```

## Quick Start

### Project setup

```bash
bash /path/to/my-playbook/setup.sh
```

This clones `.playbook/` into your project and creates `AGENTS.md`.

### Global rules (all AI tools)

```bash
bash /path/to/my-playbook/setup.sh --global
```

This also installs your non-negotiable rules into:

| Tool | Global Config |
|---|---|
| **Claude Code** | `~/.claude/CLAUDE.md` |
| **Gemini CLI** | `~/.gemini/GEMINI.md` |
| **OpenAI Codex** | `~/.codex/AGENTS.md` |
| **Cursor** | Manual — paste `rules/cursor-rules.md` into Settings → Rules for AI |


Re-running pulls the latest playbook without overwriting your files.

---

## Framework Skills (Don't Duplicate These)

Some tools ship their own AI-readable docs. Don't write custom rules for them — reference the built-in docs instead.

| Tool | Built-in Docs | How to Use |
|---|---|---|
| **Next.js 16+** | `node_modules/next/dist/docs/` | Already referenced in generated `AGENTS.md` |
| **shadcn/ui** | Official SKILL.md | `npx skills add https://github.com/shadcn-ui/ui --skill shadcn` |

---

## Rules vs Playbooks

| | Rules | Playbooks |
|---|---|---|
| **What** | Personal coding style | Domain-specific knowledge |
| **Scope** | Every project | Only relevant projects |
| **Examples** | "No comments", "Kebab-case" | "How to prevent double bookings" |
| **Loaded by** | AI reads `.playbook/rules/` | AI reads `INDEX.md` on demand |

---

## Post-Project Learnings

After finishing a project, AI generates a `LEARNINGS.md` using `learnings-template.md`. You review it, then update the playbook. This is how the playbook grows.

---

## Keeping Rules Effective

> AI agent compliance drops when rule files exceed ~200 lines.

- Keep each rule file **under 50 lines**
- Use the **"remove test"**: if deleting a rule wouldn't cause a mistake, remove it
- Update `rules/mistakes.md` when you notice recurring AI problems
- Prune rules that aren't working
