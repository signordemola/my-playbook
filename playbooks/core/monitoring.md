## 18. Monitoring & Observability

> **Sources:** [OpenTelemetry docs](https://opentelemetry.io/docs/),
> [Sentry Next.js SDK](https://docs.sentry.io/platforms/javascript/guides/nextjs/),
> [Vercel Observability](https://vercel.com/docs/observability)

---

### The Three Pillars

Production observability requires correlating **Logs, Metrics, and Traces** using a shared context. Isolated tools create blind spots.

| Pillar | What It Answers | Tool |
| ------ | --------------- | ---- |
| **Logs** | "What happened?" | Structured JSON logs (Pino) |
| **Metrics** | "How much / how often?" | Counters, gauges, histograms |
| **Traces** | "Where did the time go?" | Distributed traces (OpenTelemetry → Sentry) |

---

### Structured Logging

Every log entry must be a queryable JSON object — never free-text strings.

```typescript
// lib/logger.ts
import pino from "pino"

export const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
  formatters: {
    level: (label) => ({ level: label }),
  },
  // In production, Vercel captures stdout as structured logs
})

// Usage in a Server Action:
logger.info({
  event: "booking.created",
  clientId: "clx_abc123",
  planFrequency: "BI_WEEKLY",
  quoteAmount: 18500,  // cents
}, "New booking created")

// Usage in an error handler:
logger.error({
  event: "payment.failed",
  visitId: "visit_xyz",
  stripeDeclineCode: "insufficient_funds",
  clientId: "clx_abc123",
}, "Post-clean charge failed")
```

**Rules:**
- Use **Pino** — it's the fastest Node.js logger and outputs structured JSON by default
- Always include `event` (machine-readable action name) and relevant entity IDs
- Never log PII in plain text (email, phone, card numbers). Use IDs that can be looked up.
- Include `traceId` when available to correlate logs with traces

---

### OpenTelemetry Integration

```typescript
// instrumentation.ts (root of project)
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    // Initialise OTel SDK before app code runs
    const { NodeSDK } = await import("@opentelemetry/sdk-node")
    const { getNodeAutoInstrumentations } = await import(
      "@opentelemetry/auto-instrumentations-node"
    )

    const sdk = new NodeSDK({
      instrumentations: [getNodeAutoInstrumentations()],
      // Export to Sentry, Jaeger, SigNoz, etc.
    })

    sdk.start()
  }
}
```

**Or with Vercel's zero-config package:**
```typescript
// instrumentation.ts
import { registerOTel } from "@vercel/otel"

export function register() {
  registerOTel({ serviceName: "greenleaf-web" })
}
```

---

### Error Tracking (Sentry)

```typescript
// sentry.server.config.ts
import * as Sentry from "@sentry/nextjs"

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 0.1,   // 10% of transactions in production
  profilesSampleRate: 0.1,
  environment: process.env.NODE_ENV,

  beforeSend(event) {
    // Scrub PII before it leaves the server
    if (event.user) {
      delete event.user.email
      delete event.user.ip_address
    }
    return event
  },

  // Ignore noisy, non-actionable errors
  ignoreErrors: [
    "ResizeObserver loop limit exceeded",
    "Non-Error promise rejection captured",
  ],
})
```

**Sentry + OTel integration:**
- Sentry can consume OpenTelemetry data — jump from an error to the full distributed trace
- See exactly which database query or external API call caused the failure
- Don't choose between Sentry and OTel — use both together

---

### Service Level Objectives (SLOs)

Don't monitor "everything." Focus on what impacts users.

| SLO                      | Target  | SLI (How to Measure)                               |
| ------------------------ | ------- | -------------------------------------------------- |
| **Booking success rate** | ≥ 99.5% | `(successful bookings) / (booking attempts)`       |
| **Payment processing**   | ≥ 99.9% | `(charges succeeded) / (charges attempted)`        |
| **API latency (p95)**    | ≤ 500ms | Server Actions + Route Handler response time       |
| **Uptime**               | ≥ 99.9% | Health check endpoint (`/api/health`)              |
| **Email delivery**       | ≥ 98%   | `(delivered) / (sent)` — track via Resend webhooks |

#### Error Budgets

Instead of alerting on absolute thresholds, use **error budgets**:

- SLO of 99.9% uptime = **43 minutes of allowed downtime per month**
- Track how much of the budget has been consumed
- Alert when the **burn rate** exceeds normal — e.g., "We're consuming error budget 10x faster than sustainable"
- This prevents alert fatigue from one-off blips while catching real incidents

---

### What to Alert On (Not Everything)

| Alert                          | Threshold          | Action                                          |
| ------------------------------ | ------------------ | ----------------------------------------------- |
| **Payment failure spike**      | > 5% in 10 min     | Check Stripe status page + review decline codes |
| **5xx error rate**             | > 1% in 5 min      | Investigate immediately                         |
| **Webhook delivery failures**  | Any 3 consecutive  | Check endpoint + Stripe dashboard               |
| **Queue backlog**              | > 100 pending jobs  | Scale workers or investigate stuck jobs         |
| **Database connection errors** | Any                | Check Neon status, connection pool exhaustion   |
| **Error budget burn rate**     | > 5x normal        | Slow deployments, investigate root cause        |

**Rules:**
- Every alert must have a **runbook** — a documented action to take
- Never alert on things you can't act on
- Route critical alerts to on-call (PagerDuty, Opsgenie). Route warnings to Slack/email.
- Review and prune alert rules monthly — unused alerts become noise

---

### Health Check Endpoint

```typescript
// app/api/health/route.ts
import { prisma } from "@/lib/db"

export async function GET() {
  try {
    // Verify database connectivity
    await prisma.$queryRaw`SELECT 1`

    return Response.json({
      status: "ok",
      timestamp: new Date().toISOString(),
      version: process.env.VERCEL_GIT_COMMIT_SHA?.slice(0, 7) ?? "dev",
    })
  } catch (error) {
    return Response.json(
      { status: "error", message: "Database unreachable" },
      { status: 503 }
    )
  }
}
```

> **Note:** On Neon free tier, avoid hitting `/api/health` too frequently — each call
> wakes the database and consumes compute hours. Use a 5-minute interval, not 30 seconds.

---

### Monitoring Checklist by Phase

| Phase | What to Set Up | Tool |
| ----- | ------------- | ---- |
| **Dev** | Structured logging (Pino) | Console output |
| **Preview** | Error tracking | Sentry (dev DSN) |
| **Production** | Error tracking + tracing | Sentry + OTel |
| **Production** | Uptime monitoring | Better Stack / UptimeRobot |
| **Production** | Performance (RUM) | Vercel Speed Insights |
| **Production** | Log aggregation | Vercel Log Drains → Datadog/Axiom |
| **Scale** | Custom dashboards | Grafana + Prometheus |

---

### Cost-Conscious Monitoring (Free Tier Stack)

| Service | Free Tier | Good Enough For |
| ------- | --------- | --------------- |
| **Sentry** | 5K errors/month | Error tracking + basic performance |
| **Better Stack** | 5 monitors | Uptime checks from multiple regions |
| **Vercel Analytics** | Included with Hobby | Web Vitals + basic traffic data |
| **Vercel Logs** | 1 hour retention (Hobby) | Real-time debugging |

> For demo/portfolio projects, the free tiers above are sufficient.
> For production with paying clients, invest in Sentry Team ($26/mo) for longer retention
> and alerting, plus Better Stack or Axiom for log retention.
