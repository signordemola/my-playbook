## 13. Full-Stack Framework Patterns

### Server-First Architecture

Modern frameworks blur the boundary between frontend and backend. The patterns below apply to any server-first framework (Next.js, Remix, SvelteKit, Nuxt, etc.).

---

### Server Actions vs API Routes

| | Server Actions (Mutations) | API Route Handlers (Webhooks/Integrations) |
| --- | --- | --- |
| **Triggered by** | Human clicking a button or submitting a form | External system calling your server |
| **Examples** | Create booking, cancel plan, update settings | Stripe webhook, calendar sync callback, third-party API |
| **CSRF** | Usually built-in (framework handles) | Must implement manually |
| **HTTP method** | POST only (implicit) | Any HTTP method |

**Rule:** Use server actions for user-initiated mutations. Use API routes for machine-to-machine communication.

---

### Server Components for Data Fetching

Server components execute on the server — they can query the database directly, access secrets, and never ship code to the client.

```
Server Component (page)
  → Query database directly (no fetch(), no useEffect, no loading state)
  → Pass data as props to interactive child components
```

- Layouts and pages should be server components by default
- Only interactive widgets (forms, dialogs, buttons with state) need client-side JavaScript
- Never import a client component in a way that forces the entire page to render client-side

---

### Data Access Layer (DAL)

**All database access must go through a centralized Data Access Layer** — never call the database directly from components, actions, or route handlers.

```
features/
  bookings/
    dal.ts          → DB queries (the "service" layer)
    schemas.ts      → Validation schemas (the "DTO" layer)
    actions.ts      → Server actions (the "controller" layer)
    components/     → UI components
```

#### Why

- **Security boundary:** The DAL verifies authentication and authorization before every query
- **Single source of truth:** All booking logic lives in one place, not scattered across components
- **Testability:** You can unit test the DAL independently of the framework

#### Pattern

```
Every server action:
  1. Verify authentication (requireAuth())
  2. Validate input (schema.parse(input))
  3. Call DAL function (dalFunction(validatedInput))
  4. Invalidate cache / revalidate UI
  5. Return result
```

---

### Rendering Strategy

Choose the right rendering mode per route:

| Strategy | When | Characteristics |
| -------- | ---- | --------------- |
| **Static (SSG)** | Marketing, pricing, docs | Generated at build time, fastest possible |
| **Dynamic (SSR)** | Dashboard, authenticated pages | Rendered per-request, always fresh |
| **Incremental (ISR)** | Product catalogs, public listings | Re-generates periodically, balances speed + freshness |
| **Streaming** | Pages with multiple data sources | Send static shell immediately, stream dynamic holes |
| **Partial Prerendering (PPR)** | Mix of static + dynamic on same page | Static shell at build → dynamic data slots stream in |

**Rule:** Public pages = static. Authenticated pages = dynamic. Don't mix them in the same component tree without a streaming boundary.

---

### Caching

| Method | When | How |
| ------ | ---- | --- |
| **Function-level cache** | Data fetching functions with stable results | Cache the entire function result with a TTL |
| **On-demand invalidation** | After a mutation changes data | Invalidate by tag or path so the UI reflects the change |
| **Time-based (SWR)** | Data that changes slowly (product lists, settings) | Serve stale, revalidate in background |

**The framework must never show stale data after a mutation.** Every server action that changes data must invalidate the relevant cache before returning.

---

### Middleware / Proxy Layer

The request-level middleware (proxy) runs before every request:

- **Use for:** Auth redirects (unauthenticated → login), rate limiting, geolocation headers
- **NOT your security boundary** — server actions and DAL functions verify auth independently
- Keep it lightweight — middleware runs on every request, including static assets

---

### Error and Loading Boundaries

Every route group needs:

| Boundary | Purpose | User Sees |
| -------- | ------- | --------- |
| **Error boundary** | Catches thrown errors, prevents blank screen | Branded error message with retry button |
| **Loading boundary** | Shows while async data is fetched | Skeleton or spinner (streaming UI) |

**Never let the user see a blank white page or an unhandled error.**

---

### Server Action Return Pattern

Standardize how server actions communicate results:

```
Success: { success: true, data: <result> }
Failure: { success: false, errors: { fieldName: ["error message"] } }
```

- **Never throw from a server action** unless it's a redirect — thrown errors are harder to handle gracefully in the UI
- Return structured error objects that the form can map to specific fields

---

### Server-Only Imports

Critical modules (DAL, auth, db client) must be marked as server-only:

- This causes a **build-time error** if a client component accidentally imports them
- Prevents database credentials, API keys, and business logic from leaking to the browser
- Every file in `lib/dal/`, `lib/auth/`, and `lib/db/` should have this protection

---

### Rules

- **Server components by default.** Only opt into client-side rendering for interactive widgets.
- **All database access through the DAL.** Components, actions, and handlers never import the DB client directly.
- **Every mutation invalidates its cache.** The user must see fresh data after making a change.
- **Middleware is not a security boundary.** It's a convenience layer. Real auth checks happen in the DAL.
- **Don't mix static and dynamic** in the same component tree without a streaming boundary.
- **Mark sensitive imports as server-only.** Prevent accidental client-side exposure.
- **Structured error returns.** Never throw from server actions — return error objects.
