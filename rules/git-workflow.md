# Git Workflow Rules

> My git conventions. AI agents must follow these for commits and branches.

## Commits

- **Conventional Commits** — always:
  ```
  feat: add booking cancellation flow
  fix: prevent double-charge on retry
  chore: update dependencies
  refactor: extract pricing logic to lib/pricing.ts
  docs: update README with setup instructions
  test: add concurrency test for slot booking
  ```
- **Lowercase** — no capital letters in commit messages
- **Present tense** — "add feature" not "added feature"
- **Short subject** — max 72 characters. Details go in the body.
- **One logical change per commit** — don't bundle unrelated changes.

## Branches

- `main` — production-ready, always deployable
- `dev` — integration branch (if used)
- `feature/short-description` — new features
- `fix/short-description` — bug fixes
- `chore/short-description` — maintenance, deps, config

## Pull Requests

- Title matches commit convention: `feat: add booking cancellation flow`
- Description includes: what changed, why, and how to test
- Keep PRs small — < 400 lines of diff when possible
