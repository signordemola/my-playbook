---
description: Post-project knowledge capture for playbook improvement
---

# Learnings

When triggered, generate a `LEARNINGS.md` using the template at `.playbook/learnings-template.md`.

## Process

1. Read `.playbook/learnings-template.md` for the structure
2. Review the project codebase and recent history
3. Fill in every section with specific, actionable insights
4. Save as `LEARNINGS.md` in the project root

## What to Capture

- **Patterns that worked** — architecture decisions worth repeating
- **Mistakes made** — add these to `.playbook/rules/mistakes.md`
- **Missing playbook content** — gaps discovered during the project
- **Tool/package insights** — gotchas, workarounds, version-specific issues
- **Performance learnings** — what was slow, what fixed it

## Rules

- Be specific — "Prisma N+1 queries on booking list page fixed with `include`" not "database was slow"
- Only capture insights that would help a FUTURE project
- If a mistake was recurring, add it to `rules/mistakes.md` directly
