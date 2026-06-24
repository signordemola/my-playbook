## 11. Security

### BOLA Prevention (OWASP #1 Risk)

**Broken Object Level Authorization** — the most exploited API vulnerability in 2025–2026.

**Never trust user-supplied IDs. Always verify ownership server-side.**

```
❌  Fetch record by ID only:    findById(bookingId)
✅  Fetch record by ID + owner:  findById(bookingId, WHERE owner = authenticatedUser)
```

If the record doesn't belong to the authenticated user, return "Not Found" — never "Unauthorized" (leaks that the record exists).

#### BOLA Checklist

- Every query that reads, updates, or deletes a record **must include an ownership filter**
- Never rely on the client to send the correct `userId` — derive it from the session/token server-side
- Test with two accounts — can Account A access Account B's resources by changing the ID in the URL?

---

### Authorization Patterns

| Pattern | How It Works | Best For |
| ------- | ------------ | -------- |
| **RBAC** (Role-Based) | Users have roles (`admin`, `provider`, `client`); roles have permissions | Most booking systems — simple, predictable |
| **ABAC** (Attribute-Based) | Access based on attributes of the user, resource, and context | Complex rules: "Managers can only modify bookings within 48 hours" |
| **Ownership check** | Record belongs to the authenticated user | All user-facing data access |

**Layer them:** RBAC determines *what endpoints* a user can access. Ownership checks determine *which records* within those endpoints.

---

### CSRF Protection

| Context | Protection | Notes |
| ------- | ---------- | ----- |
| **Server Actions / mutations** | Framework-built-in CSRF (if available) | Most modern frameworks handle this automatically for mutations |
| **API route handlers** | Manual anti-CSRF tokens required | Generate a unique token, embed in forms, validate server-side |
| **SameSite cookies** | Set `SameSite=Lax` on session cookies | Secondary defense layer — not sufficient alone |

**Defense-in-depth:** Even with CSRF protection, always verify authentication inside the mutation handler. CSRF protection ≠ authentication.

---

### Rate Limiting

#### Algorithm Selection

| Algorithm | Behavior | Best For |
| --------- | -------- | -------- |
| **Fixed window** | Resets at intervals; prone to boundary spikes | Simple, low-risk endpoints |
| **Sliding window** | Rolling window, smooth enforcement | Most general use cases |
| **Token bucket** | Allows short bursts, enforces steady average | APIs where bursts are acceptable |

#### Tier Table for Booking Systems

| Endpoint | Limit | Rationale |
| -------- | ----- | --------- |
| Public pricing/availability | 10 req / 10 sec | Prevents scraping and pricing abuse |
| Booking creation | 5 req / 60 sec | Prevents automated spam bookings |
| Portal / authenticated actions | 20 req / 60 sec | Normal usage with margin |
| Login / password reset | 5 req / 5 min | Brute-force protection |

#### Implementation Rules

- **Identification:** Use the authenticated user ID for logged-in users, IP address for anonymous
- **Return 429** with a `Retry-After` header — don't silently drop requests
- **Never use in-memory counters in serverless** — state doesn't persist across invocations. Use an external store (Redis, etc.)
- **Rate limit before expensive work** — check the limit before validating inputs or querying the database

---

### Encryption & Hashing

#### Passwords: Hash, Never Encrypt

| Rule | Why |
| ---- | --- |
| **Hash passwords, never encrypt them** | Encryption is reversible — if the key leaks, all passwords are exposed |
| **Use a memory-hard algorithm** (Argon2id recommended) | Resistant to GPU brute-force attacks |
| **Bcrypt is acceptable** with work factor ≥ 10 | But has a 72-byte input limit — truncates long passwords |
| **Always hash asynchronously** | Never block the main thread |
| **Use a pepper** (secret in env vars, added before hashing) | DB dump alone isn't enough to crack passwords |

#### PII Encryption at Rest

Encrypt sensitive fields (phone numbers, addresses, sensitive notes) using authenticated encryption (AES-256-GCM or equivalent):

- Use a unique initialization vector (IV/nonce) per encryption operation
- Store the IV alongside the ciphertext
- Keep encryption keys in a secrets manager — never in the database or source code
- **Never encrypt passwords** — hashing is the correct approach for passwords

---

### Cookie & Session Security

All session cookies must have these flags:

| Flag | Value | Why |
| ---- | ----- | --- |
| `httpOnly` | `true` | Prevents XSS from stealing the token (JavaScript can't read it) |
| `secure` | `true` | HTTPS only — blocks interception on insecure networks |
| `sameSite` | `lax` | CSRF protection layer |
| `maxAge` | `86400` (1 day) | Prevents indefinite sessions on shared devices |

**Rules:**
- **Never store auth tokens in `localStorage`** — use `httpOnly` cookies
- **Rotate session tokens** after privilege changes (login, role change)
- **Set absolute session expiry** — don't let sessions live forever, even with activity

---

### Secrets Management

| Rule | Why |
| ---- | --- |
| **Never hardcode secrets in source code** | They end up in version control and are irrecoverable |
| **Use environment variables** at minimum | Separates config from code |
| **Secrets manager for production** (Vault, cloud KMS, etc.) | Centralized rotation, audit logging |
| **Rotate secrets on a schedule** | Limits damage window from a leak |
| **Different secrets per environment** | Dev/staging secrets must never work in production |

---

### Input Validation

Three-layer defense:

| Layer | Where | Purpose |
| ----- | ----- | ------- |
| **Client-side validation** | Browser (form library) | Instant UX feedback — not a security control |
| **Server-side validation** | Server (schema validator) | Re-validate everything — the actual security boundary |
| **Database constraints** | DB (enums, check constraints, NOT NULL) | Final safety net — catches bugs in application logic |

**Never trust the client.** Client-side validation is a UX feature, not a security feature. Any value the client sends can be forged.

---

### Content Security Policy (CSP)

Set CSP headers to prevent XSS and data injection:

| Directive | Recommended Value | Purpose |
| --------- | ----------------- | ------- |
| `default-src` | `'self'` | Only load resources from your own domain |
| `script-src` | `'self'` (+ nonce for inline scripts) | Prevent injection of malicious scripts |
| `style-src` | `'self' 'unsafe-inline'` (if needed) | Control stylesheet sources |
| `img-src` | `'self' data: https:` | Allow images from your domain + HTTPS sources |
| `connect-src` | `'self'` + specific API domains | Restrict outbound API calls |

Start with a strict policy and relax as needed — not the other way around.

---

### Rules

- **Every mutating endpoint must verify ownership**, not just authentication.
- **Rate limit before expensive work.** Check the rate limit before validating inputs or hitting the database.
- **Hash passwords with Argon2id.** Encrypt PII with AES-256-GCM. Never confuse the two.
- **All session cookies are `httpOnly`, `secure`, `sameSite=lax`.** No exceptions.
- **Three-layer validation: client → server → database.** The server is the security boundary.
- **Never log secrets, tokens, or passwords.** Even in development.
- **Assume the client is compromised.** Derive user identity from the session, not from request parameters.
- **Audit access to sensitive data.** Log who accessed PII, when, and from where (see `core/audit-trails.md`).
