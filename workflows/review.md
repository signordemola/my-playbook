---
description: Review recent changes against playbook rules
---

# Review

When triggered, review the most recent changes against playbook rules.

## Process

1. Read `.playbook/rules/` — all rule files
2. Identify all recently changed files (check git diff or ask which files)
3. Review each file against every applicable rule

## What to Check

### Code Style (code-style.md)
- No comments in code
- No duplicate logic — one source of truth
- Code split by concern (types/, schemas/, actions/, hooks/)
- No assumptions or guessed patterns

### Structure (project-structure.md)
- Kebab-case for all file and folder names
- Files are in the correct folders (types in types/, schemas in schemas/, etc.)
- No feature-folder mixing

### Mistakes (mistakes.md)
- No suppression comments
- No speculative features
- No placeholder content
- No refactoring of untouched code

## Output

Present as a list of issues, grouped by severity:

**🔴 Critical** — Must fix before commit
**🟡 Warning** — Should fix
**✅ Clean** — No issues

Include file path and line number for each issue.
