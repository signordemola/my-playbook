---
description: Force requirements gathering before planning — prevent assumptions
---

# Spec

When triggered, do NOT plan or write code. Instead, interview the user.

## Process

1. Read the user's initial request
2. Identify ambiguities, missing requirements, and assumptions
3. Ask clarifying questions — present them as a numbered list
4. Wait for answers before proceeding
5. After answers, produce a short spec document

## Spec Document Structure

```markdown
# Spec — [Feature Name]

## What
One paragraph describing the feature.

## Requirements
- Numbered list of specific, testable requirements

## Out of Scope
- What this feature does NOT include

## Technical Approach
- Key technical decisions (which files, patterns, packages)

## Open Questions
- Anything still unclear after the interview
```

## Rules

- NEVER skip the interview — even if the request seems clear
- Ask at most 5 questions at a time — don't overwhelm
- Requirements must be testable ("user can X" not "improve UX")
- Present the spec for approval before planning or coding
