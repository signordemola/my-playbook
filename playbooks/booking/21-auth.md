## 21. Auth & Authorization

> **Sources:** [Better Auth docs](https://www.better-auth.com/docs),
> [Better Auth Next.js guide](https://www.better-auth.com/docs/integrations/next-js)

---

### Why Better Auth (2026)

| Feature | Better Auth | Clerk | Auth.js v5 |
| ------- | ----------- | ----- | ---------- |
| **Self-hosted** | ✅ Full ownership | ❌ Managed | ✅ |
| **TypeScript-first** | ✅ Full inference | ✅ | Partial |
| **Database adapter** | ✅ Prisma, Drizzle | N/A (managed) | ✅ |
| **CSRF built-in** | ✅ | ✅ | ✅ |
| **Session in your DB** | ✅ | ❌ (their DB) | ✅ |
| **Plugin ecosystem** | ✅ Rich | N/A | Limited |
| **Free** | ✅ Open source | Paid at scale | ✅ |

Better Auth is the recommended choice when you need full control over your data, schema, and infrastructure. Use Clerk if you need managed enterprise features (SSO, org management) and don't mind vendor lock-in.

---

### Server Setup

```typescript
// lib/auth.ts
import "server-only"
import { betterAuth } from "better-auth"
import { prismaAdapter } from "better-auth/adapters/prisma"
import { prisma } from "./db"

export const auth = betterAuth({
  database: prismaAdapter(prisma, { provider: "postgresql" }),
  user: {
    additionalFields: {
      role: {
        type: "string",
        defaultValue: "member",
        input: false,  // Users can't set their own role
      },
    },
  },
  session: {
    cookieCache: { enabled: true, maxAge: 60 * 5 }, // 5 min cache
  },
  // Production: support secret rotation without downtime
  // Set BETTER_AUTH_SECRETS="current-secret,previous-secret"
})

// app/api/auth/[...all]/route.ts
import { toNextJsHandler } from "better-auth/next-js"
import { auth } from "@/lib/auth"
export const { GET, POST } = toNextJsHandler(auth)
```

---

### Client Setup

```typescript
// lib/auth-client.ts
import { createAuthClient } from "better-auth/react"

export const authClient = createAuthClient({
  baseURL: process.env.NEXT_PUBLIC_APP_URL,
})

// Usage in a Client Component:
// const { data: session } = authClient.useSession()
```

---

### RBAC (Role-Based Access Control)

#### Permission Mapping

```typescript
// lib/permissions.ts
const PERMISSIONS = {
  admin: [
    "booking:create", "booking:delete", "booking:manage",
    "client:manage", "settings:manage",
  ],
  owner: [
    "booking:create", "booking:delete", "booking:manage", "client:view",
  ],
  member: [
    "booking:create", "booking:view",
  ],
} as const

type Role = keyof typeof PERMISSIONS

export const hasPermission = (role: Role, permission: string): boolean =>
  (PERMISSIONS[role] as readonly string[]).includes(permission)
```

#### Where to Check Permissions

| Layer | Check Type | Purpose |
| ----- | ---------- | ------- |
| **`proxy.ts`** (middleware) | Coarse-grained | Redirect unauthenticated users away from `/dashboard` |
| **Server Action** | Fine-grained | Verify user owns the resource before mutating |
| **Server Component** | Fine-grained | Control what data is fetched and shown |
| **Client Component** | UX only | Hide/show buttons — **never** treat this as security |

**Rule:** The server is ALWAYS the security boundary. Client-side role checks are cosmetic.

---

### Data Access Layer (DAL)

The DAL is where auth meets data. Every Server Action calls through it.

```typescript
// lib/dal.ts
import "server-only"
import { auth } from "./auth"
import { headers } from "next/headers"
import { redirect } from "next/navigation"
import { hasPermission, type Role } from "./permissions"

export const requireSession = async () => {
  const session = await auth.api.getSession({ headers: await headers() })
  if (!session) redirect("/login")
  return session
}

export const requireRole = async (role: string) => {
  const session = await requireSession()
  if (session.user.role !== role) {
    throw new Error("Forbidden")
  }
  return session
}

export const requirePermission = async (permission: string) => {
  const session = await requireSession()
  if (!hasPermission(session.user.role as Role, permission)) {
    throw new Error("Forbidden")
  }
  return session
}

// For owner-only admin routes
export const requireOwner = async () => requireRole("owner")
```

---

### CSRF Protection

Better Auth includes built-in CSRF protection:
- Origin header validation on all state-changing requests (POST, PUT, DELETE)
- Metadata checks to verify request legitimacy
- **Never disable** `disableCSRFCheck` in production

```typescript
// ❌ DON'T
export const auth = betterAuth({
  advanced: { disableCSRFCheck: true }, // NEVER in production
})

// ✅ DO — just leave the default (CSRF enabled)
export const auth = betterAuth({
  // CSRF is on by default — no config needed
})
```

---

### The CVE-2025-29927 Lesson

In 2025, a **middleware bypass vulnerability** was discovered in Next.js. An attacker could craft a request that skipped middleware entirely — meaning any auth check that relied solely on middleware was bypassed.

**The fix is architectural:**

```
❌ DON'T: Only check auth in proxy.ts / middleware.ts
   → Middleware can be bypassed

✅ DO: Defense in depth
   1. proxy.ts → redirects (UX convenience, not security)
   2. DAL (lib/dal.ts) → requireSession() in every Server Action
   3. Database constraints → final safety net
```

**Rule:** Middleware is for UX (redirects). The DAL is for security (session verification). Always have both layers.

---

### Session Management Rules

| Rule | Why |
| ---- | --- |
| **Always verify server-side** | Never trust client-side `useSession()` for security |
| **httpOnly cookies** | Better Auth handles by default — verify in production |
| **Session expiry** | 1 day for client portals, 8 hours for admin dashboards |
| **Role changes = re-auth** | After role update, invalidate existing sessions |
| **Audit role changes** | Log who changed what role and when (see §7 Audit Trails) |
| **Secret rotation** | Use `BETTER_AUTH_SECRETS` with comma-separated current + previous |

---

### Token-Based Access (Client Portal)

For public-facing portals where clients don't create accounts:

```typescript
// Portal access uses opaque tokens, not sessions
// Client clicks a link: /my/{portalToken}/plan

export async function validatePortalToken(token: string) {
  const client = await prisma.client.findUnique({
    where: { portalToken: token },
  })
  if (!client) return null
  return client
}

// Rules:
// - Tokens are nanoid(21) — ~125 bits of entropy
// - Never expose client database IDs in URLs
// - Rate limit portal token lookups (see §11 Security)
// - Tokens don't expire but can be rotated by the owner
```
