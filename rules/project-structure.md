# Project Structure

> How I organize my Next.js projects. AI agents must follow this layout.

## Naming

- **Kebab-case everything.** Files, folders, routes — all kebab-case.
  ```
  ✅ booking-form/booking-form.tsx
  ✅ use-booking.ts
  ✅ booking-schema.ts
  ❌ BookingForm/BookingForm.tsx
  ❌ useBooking.ts
  ```

## Code Splitting

Split by concern, not by feature. Dedicated folders for each type of code:

```
app/
├── (public)/             ← Public-facing pages
├── (admin)/              ← Admin/dashboard pages
└── api/                  ← API routes (webhooks only)

types/                    ← All TypeScript types/interfaces
schemas/                  ← All Zod validation schemas
actions/                  ← All Server Actions
hooks/                    ← All custom React hooks
lib/                      ← Utility functions, helpers
components/               ← UI components
```

## Principles

- **Readability first.** If someone opens a folder, they should immediately know what's inside.
- **Scalability.** The structure should work for 10 files and 1000 files.
- **One source of truth.** A function lives in one place. Everything else imports it.
