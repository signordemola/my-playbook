---
description: Systematic debugging — reproduce, isolate, fix, verify
---

# Debug

When triggered, follow this 4-phase debugging process. Do NOT skip steps.

## Phase 1: Reproduce

- Reproduce the bug deterministically
- Write the exact steps or test that triggers it
- If you cannot reproduce it, stop and ask for more information

## Phase 2: Isolate

- Narrow down to the smallest possible scope
- Identify the exact file, function, and line causing the issue
- Form a hypothesis about the root cause
- State the hypothesis explicitly before proceeding

## Phase 3: Fix

- Fix ONLY the root cause — not the symptoms
- Do not refactor adjacent code
- The fix must be surgical

## Phase 4: Verify

- Run the test that reproduced the bug — it must pass
- Run the full test suite — nothing else must break
- Explain what caused the bug and why the fix works

## Rules

- NEVER guess at a fix without reproducing first
- NEVER apply multiple fixes at once ("shotgun debugging")
- NEVER declare "fixed" without verification
- If the original hypothesis was wrong, go back to Phase 2
