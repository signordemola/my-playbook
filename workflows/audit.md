---
description: Security and performance audit of the current codebase
---

# Audit

When triggered, perform a full audit against the playbook standards.

## Security Checks

1. **BOLA** — Every query that reads/updates/deletes a record includes an ownership filter
2. **Rate limiting** — Arcjet is installed and configured in `middleware.ts`
3. **CSRF** — Server Actions have CSRF protection, API routes have anti-CSRF tokens
4. **Cookies** — All session cookies are `httpOnly`, `secure`, `sameSite=lax`
5. **Input validation** — Three layers: client → server (Zod) → database constraints
6. **Secrets** — No hardcoded secrets in source code, all in env vars
7. **CSP headers** — Content Security Policy is configured
8. **Suppression comments** — No `// @ts-expect-error`, `// eslint-disable`, `# type: ignore`

## Performance Checks

1. **Bundle size** — No unnecessary client-side JavaScript, use Server Components
2. **Database** — Indexes on frequently queried columns, no N+1 queries
3. **Images** — Using `next/image` with proper sizing
4. **Caching** — Static pages use ISR or static generation where possible

## Output

Present findings as a table:

| Category | Check | Status | Action Needed |
|---|---|---|---|
| Security | BOLA prevention | ✅/❌ | Description |
| ... | ... | ... | ... |

## Rules

- Check every file, not just a sample
- Reference specific file paths and line numbers for failures
- Prioritize: Critical (security) → High (performance) → Medium (best practices)
