---
description: Generate a HANDOFF.md for context continuity between chat sessions
---

# Handoff

Generate a `HANDOFF.md` file in the project root with the following sections:

## Structure

```markdown
# Handoff — [Project Name]

Generated: [current date/time]

## Goal
What we are building. One paragraph max.

## Current State
What is done and what is in progress. Use a checklist:
- [x] Completed items
- [/] In progress items
- [ ] Not started items

## Decisions Made
Architectural choices already settled. Do NOT re-litigate these in the next session.

## Blocked On
Current issues, pending user input, or unresolved questions.

## Next Steps
Explicit, actionable items for the next session. Be specific — file paths, function names, what to implement.
```

## Rules

1. Read the codebase and recent changes before generating
2. Keep it concise — the next agent reads this first, token efficiency matters
3. Only include decisions that were explicitly made, not assumptions
4. Next steps must be actionable, not vague ("implement X in Y file" not "continue working")
5. Overwrite any existing HANDOFF.md
