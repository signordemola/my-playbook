---
description: Pre-deployment checklist before going to production
---

# Deploy Check

When triggered, verify all deployment requirements are met.

## Checklist

### Environment
- [ ] All required env vars are set (check `.env.example` against production)
- [ ] No `.env` files committed to git
- [ ] Secrets are in a secrets manager, not plain text

### Database
- [ ] All migrations are applied
- [ ] No pending schema changes
- [ ] Indexes exist on frequently queried columns
- [ ] Seed data is not present in production

### Code Quality
- [ ] Build passes: `npm run build` with zero errors
- [ ] No `TODO`, `FIXME`, or `HACK` in production code
- [ ] No `console.log` in production code
- [ ] No suppression comments (`@ts-expect-error`, `eslint-disable`)
- [ ] No hardcoded localhost URLs

### Security
- [ ] Arcjet is configured in `middleware.ts`
- [ ] CSRF protection is active on all mutations
- [ ] Session cookies have correct flags
- [ ] CSP headers are configured
- [ ] Rate limiting is active on auth endpoints

### Testing
- [ ] All tests pass
- [ ] Critical paths have test coverage (auth, payments, booking flow)

## Output

Present as a pass/fail checklist with action items for any failures.
