## 17. Deployment Checklist

> Sources: [Vercel Deployment Docs](https://vercel.com/docs/deployments),
> [Next.js Security Headers](https://nextjs.org/docs/app/building-your-application/configuring/headers)

---

### Pre-Deploy: Environment Validation

Every secret and config value must be validated at build time. If a variable is missing or malformed, the build fails with a clear error — not a cryptic runtime crash.

```typescript
// lib/env.ts — Import this from your app entry points
import { z } from "zod"

const envSchema = z.object({
  // Database
  DATABASE_URL:            z.string().url(),
  DIRECT_DATABASE_URL:     z.string().url(),

  // Auth
  BETTER_AUTH_SECRET:      z.string().min(32),

  // Stripe
  STRIPE_SECRET_KEY:       z.string().startsWith("sk_"),
  STRIPE_WEBHOOK_SECRET:   z.string().startsWith("whsec_"),
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: z.string().startsWith("pk_"),

  // Email
  RESEND_API_KEY:          z.string().min(1),

  // Redis
  UPSTASH_REDIS_REST_URL:  z.string().url(),
  UPSTASH_REDIS_REST_TOKEN: z.string().min(1),

  // Inngest
  INNGEST_SIGNING_KEY:     z.string().optional(), // Optional in dev
  INNGEST_EVENT_KEY:       z.string().optional(),

  // App
  NEXT_PUBLIC_APP_URL:     z.string().url(),
})

export const env = envSchema.parse(process.env)
// If ANY variable is missing or malformed → build fails immediately
```

> **Rule:** Variables prefixed `NEXT_PUBLIC_` are inlined into client JS at build time.
> They cannot be changed after deployment without a rebuild. Never prefix secrets.

---

### Security Headers

```typescript
// next.config.ts
const securityHeaders = [
  {
    key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload",
  },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=()",
  },
]

const nextConfig = {
  async headers() {
    return [{ source: "/(.*)", headers: securityHeaders }]
  },
}
```

> **Test after deploy:** [securityheaders.com](https://securityheaders.com) — aim for A+ score.

---

### Content Security Policy (CSP)

For production apps that handle payment data, add a CSP:

```typescript
// proxy.ts (Next.js 16) or middleware.ts
import { NextRequest, NextResponse } from "next/server"
import { nanoid } from "nanoid"

export function middleware(request: NextRequest) {
  const nonce = nanoid()
  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' https://js.stripe.com`,
    `style-src 'self' 'unsafe-inline'`,  // Required for many UI libraries
    `frame-src https://js.stripe.com`,   // Stripe Elements iframes
    `img-src 'self' data: https:`,
    `connect-src 'self' https://api.stripe.com https://*.upstash.io`,
    `font-src 'self'`,
  ].join("; ")

  const response = NextResponse.next()
  response.headers.set("Content-Security-Policy", csp)
  response.headers.set("x-nonce", nonce)
  return response
}
```

**Rules:**
- Avoid `unsafe-inline` for scripts — use nonces instead
- Avoid `unsafe-eval` entirely — no legitimate use case in production
- Stripe Elements require `frame-src https://js.stripe.com` and `script-src https://js.stripe.com`
- Test CSP with `Content-Security-Policy-Report-Only` first, then switch to enforcing mode

---

### Deployment Strategy

#### Preview Deployments
- Vercel creates a preview deployment for every PR automatically
- Treat previews as your staging environment
- Run E2E tests against preview URLs before merging to main
- Enable deployment protection (Vercel Authentication) so previews aren't publicly accessible

#### Production Deployment
- Production deploys happen on push to `main` branch (or your configured production branch)
- **Never** deploy to production on Fridays or before holidays
- Monitor error rates for 15 minutes after each deploy

#### Rollback Strategy
```bash
# Instant rollback — re-assigns production domain to a previous deployment
vercel rollback <deployment-url>
```

- Vercel keeps all previous deployments accessible by URL
- Rollback is instant (< 1 second) — no rebuild required
- If a deploy breaks production, rollback first, then investigate
- Consider a "canary" approach for high-risk changes: deploy to a custom domain first, verify, then promote

---

### Go-Live Checklist

| Category          | Item                                                    | Status |
| ----------------- | ------------------------------------------------------- | ------ |
| **Env**           | All secrets in Vercel dashboard (not committed)         | ☐      |
| **Env**           | `NEXT_PUBLIC_` only on non-secret values                | ☐      |
| **Env**           | Zod validation of all env vars at build time            | ☐      |
| **DB**            | Pooled connection string for app, direct for migrations | ☐      |
| **DB**            | Database backup schedule confirmed                      | ☐      |
| **DNS**           | SPF + DKIM + DMARC records verified                     | ☐      |
| **DNS**           | Custom domain configured + SSL verified                 | ☐      |
| **Stripe**        | Webhook endpoint registered + signature verified        | ☐      |
| **Stripe**        | Live mode keys (not test keys)                          | ☐      |
| **Stripe**        | Test a real charge end-to-end in live mode              | ☐      |
| **Auth**          | `BETTER_AUTH_SECRET` is unique, ≥ 32 chars              | ☐      |
| **Auth**          | Owner account seeded in production DB                   | ☐      |
| **Headers**       | Security headers applied and tested (A+ on securityheaders.com) | ☐ |
| **Headers**       | CSP configured and tested in report-only mode           | ☐      |
| **Monitoring**    | Error tracking (Sentry) connected to production         | ☐      |
| **Monitoring**    | Log drains configured                                   | ☐      |
| **Performance**   | Lighthouse CI score ≥ 90 on public pages                | ☐      |
| **Accessibility** | axe scan: 0 critical/serious violations                 | ☐      |
| **SEO**           | `robots.txt` and `sitemap.xml` verified                 | ☐      |
| **SEO**           | `<title>` and `<meta description>` on all public pages  | ☐      |
| **Email**         | Test email delivery from production domain              | ☐      |
| **Inngest**       | All functions registered and test events processed      | ☐      |
| **Backup**        | Rollback procedure documented and tested                | ☐      |

---

### Post-Deploy Verification

Run these checks within 15 minutes of every production deploy:

1. **Public booking flow** — complete a test booking end-to-end
2. **Stripe webhook** — trigger a test event and verify processing
3. **Email delivery** — verify confirmation email arrives
4. **Portal access** — verify portal token loads dashboard
5. **Owner login** — verify auth + dashboard loads
6. **Error tracking** — check Sentry for new errors (should be zero)
