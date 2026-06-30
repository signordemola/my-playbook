# Code Style

> These rules are non-negotiable. AI agents must follow every single one.

## My Rules

- **No comments in code.** The code must be readable without them.
- **One source of truth.** Every function, every business rule — defined in one place, called from everywhere. Never duplicate logic.
- **Code splitting.** Separate concerns into dedicated folders: `types/`, `schemas/`, `actions/`, `hooks/`, etc. Readability and scalability over convenience.
- **Don't assume. Don't guess.** If something is unclear or you're stuck, research using official docs. Never silently pick an interpretation.
- **Plan first, code after approval.** Always present a plan before writing any code. Wait for explicit approval before implementing.
- **Date/time awareness.** Always check the current date. Never research or reference anything older than 6 months. We are building with the latest tools — not legacy patterns.

---

## Karpathy's 4 Principles

1. **Think Before Coding** — State assumptions explicitly. If ambiguous, present multiple interpretations. Ask for clarification when confused. Never silently assume.
2. **Simplicity First** — Write the minimum code necessary to solve the exact request. No speculative features, no unnecessary abstractions, no "flexibility" that wasn't asked for.
3. **Surgical Changes** — Touch only what is strictly necessary. Do not refactor adjacent code, "improve" formatting, or clean up dead code unless it is part of the task.
4. **Goal-Driven Execution** — Define clear, verifiable success criteria before starting. Loop until all criteria are met. Use tests-first where possible.

---

## Loop Engineering (2026)

The unit of engineering in 2026 is the **loop**, not the prompt.

- **Design closed-loop systems.** Every task follows: action → evaluate → repair. The agent acts, checks the result against objective truth, and iterates until verified.
- **Every loop needs 3 things:**
  1. **Trigger** — what starts the loop
  2. **Evaluation cycle** — agent checks if the goal is met after each action
  3. **Stop condition** — guardrails that prevent infinite loops, goal drift, and runaway costs
- **Verification is the critical step.** Never assume something works — check it. Run the test, read the output, confirm the result.
- **The quality of the system is limited by the design of the loop, not the model.**
