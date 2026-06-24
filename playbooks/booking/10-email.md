## 10. Email Deliverability & Notifications

### Email is Infrastructure, Not a Feature

A booking without an instant confirmation email creates customer anxiety and support debt. Treat email as load-bearing infrastructure — if it fails silently, the business loses trust.

---

### DNS Authentication (Non-Negotiable)

Before sending any email from your domain, configure these three records:

| Record | What It Does | Without It |
| ------ | ------------ | ---------- |
| **SPF** | Declares which servers are authorized to send email for your domain | Emails rejected or flagged as spoofed |
| **DKIM** | Adds a cryptographic signature to every email, proving it wasn't tampered with | Emails flagged as potentially forged |
| **DMARC** | Tells receiving servers what to do if SPF/DKIM fail (monitor, quarantine, or reject) | No visibility into authentication failures |

**In 2026, Gmail and Yahoo require all three.** A monitoring-only DMARC policy (`p=none`) is the minimum — but move toward `p=quarantine` or `p=reject` as your setup matures.

---

### Domain Separation

**Never send transactional and marketing email from the same domain.**

| Stream | Domain | Why |
| ------ | ------ | --- |
| **Transactional** (confirmations, receipts, password resets) | `notifications.yourdomain.com` | Protected reputation — a spam complaint on marketing doesn't affect booking confirmations |
| **Marketing** (promotions, newsletters) | `marketing.yourdomain.com` | Can be more aggressive; damage is isolated |

If your marketing emails get flagged as spam, your booking confirmations still land in the inbox.

---

### Sending Reliability: The Outbox Pattern

The most common email failure: the booking is created, but the confirmation email is never sent (API timeout, queue crash, deployment restart).

#### The Pattern

```
1. In the SAME database transaction as the booking:
   - Create the booking
   - Insert an email record into an "outbox" table (status: PENDING)
2. A background worker polls the outbox table
3. Worker sends the email via the email provider
4. On success: mark the outbox record as SENT
5. On failure: retry with exponential backoff (max 3 retries)
6. On permanent failure: mark as FAILED, alert ops
```

This guarantees that if the booking exists, the email record exists. No silent email drops.

---

### Bounce Handling

| Bounce Type | Meaning | Action |
| ----------- | ------- | ------ |
| **Hard bounce** | Address doesn't exist, domain invalid | **Remove immediately.** Never send to this address again. |
| **Soft bounce** | Mailbox full, server temporarily down | Retry up to 3 times over 3–5 days. If still failing, suppress. |
| **Spam complaint** | Recipient marked your email as spam | **Suppress immediately.** Continued sending tanks your reputation. |

**The 1% rule:** Total bounce rate above 1% triggers provider scrutiny. Above 2% risks temporary blocks.

---

### Domain Warming

New domains have no sender reputation. Sending 500 emails on day one will trigger spam filters.

```
Week 1:   10–20 emails/day
Week 2:   50–100 emails/day
Week 3:   200–500 emails/day
Week 4:   Full volume
```

**Monitor at each stage:** If bounce rates spike or delivery rates drop, pause and investigate before increasing volume.

**Maintenance:** Even after warming, maintain a consistent sending baseline. Disappearing for weeks and then resuming high volume triggers alarms.

---

### Template Management

#### Structure

Keep templates modular:

| Component | Example | Change Frequency |
| --------- | ------- | ---------------- |
| **Layout** (header, footer, styles) | Shared across all emails | Rarely |
| **Content block** (body text, CTA) | Per-email-type | When business logic changes |
| **Data slots** (customer name, booking date, price) | Injected at send time | Every email |

#### Versioning

- Treat templates as code — version control them
- Test across clients (Gmail, Outlook, Apple Mail) before deployment
- When changing a template, create a new version rather than editing in place. In-flight emails should use the version that was active when they were queued.

---

### Transactional Email Types for Booking Systems

| Email | Trigger | Priority | Idempotency Key |
| ----- | ------- | -------- | --------------- |
| **Booking confirmation** | Booking created | Critical — send immediately | `email:confirmation:{bookingId}` |
| **Payment receipt** | Payment succeeded | Critical | `email:receipt:{paymentId}` |
| **Reminder** | 24–48 hours before appointment | High | `email:reminder:{bookingId}:{date}` |
| **Cancellation confirmation** | Booking cancelled | High | `email:cancellation:{bookingId}` |
| **Review request** | 24 hours after appointment | Medium | `email:review:{bookingId}` |
| **Failed payment** | Payment attempt failed | High | `email:payment-failed:{paymentId}` |

Every email must have an **idempotency key** (see §4) to prevent duplicate sends during retries.

---

### Compliance

| Regulation | Requirement | Implementation |
| ---------- | ----------- | -------------- |
| **CAN-SPAM** (US) | Unsubscribe mechanism, postal address, honor opt-outs within 10 days | One-click unsubscribe header, physical address in footer |
| **GDPR** (EU) | Explicit consent for marketing; transactional emails exempt | Consent tracking, easy opt-out |
| **Gmail/Yahoo 2024+ rules** | One-click unsubscribe header mandatory for bulk senders | `List-Unsubscribe` and `List-Unsubscribe-Post` headers |

**Transactional emails** (confirmations, receipts) are generally exempt from marketing consent requirements — but still need unsubscribe options for any promotional content included within them.

---

### Notification Channels Beyond Email

Email is one channel. Production booking systems need multi-channel delivery:

| Channel | Best For | Fallback |
| ------- | -------- | -------- |
| **Email** | Confirmations, receipts, detailed information | Primary channel for records |
| **SMS** | Reminders (highest open rate), urgent updates | Falls back to email if phone number unavailable |
| **Push notifications** | Real-time status changes (appointment starting, provider en route) | Falls back to SMS/email |
| **In-app messages** | Non-urgent updates, system announcements | No fallback — only visible when user is in the app |

**Pattern:** Let users configure their **notification preferences** per channel and per event type. Some want SMS reminders but not email reminders. Respect their choices.

---

### Rules

- **DNS first.** SPF, DKIM, DMARC — non-negotiable before sending a single email.
- **Separate transactional from marketing.** Different subdomains, different reputations.
- **Use the outbox pattern.** If the booking exists, the email record must exist.
- **Handle bounces automatically.** Hard bounces get suppressed immediately.
- **Warm new domains gradually.** 10/day → 500/day over 3–4 weeks.
- **Every email has an idempotency key.** Retries must not produce duplicate sends.
- **Keep emails under 102KB.** Gmail clips larger emails — your CTA may be invisible.
- **Always include a plain-text version.** HTML-only emails get flagged.
- **Use a real reply-to address.** `hello@` not `no-reply@` — replies improve sender reputation.
- **Test across email clients.** What renders in Gmail may break in Outlook.
