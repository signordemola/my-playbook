# Project Structure Rules

> How I organize my projects. AI agents must follow this layout.

## Architecture

- **Next.js 16** — App Router, Server Components by default
- **Server Components first** — only add `"use client"` when you need interactivity
- **Server Actions for mutations** — no API routes unless an external caller needs it (webhooks)

## Folder Layout

```
app/
├── (public)/           ← Public-facing pages (landing, booking form, portal)
├── (admin)/            ← Admin/dashboard pages (protected)
├── api/                ← API routes (webhooks only)
├── layout.tsx
└── global-error.tsx

lib/
├── dal/                ← Data Access Layer — all database queries live here
├── actions/            ← Server Actions — thin orchestration layer
├── validations/        ← Zod schemas (shared between client + server)
├── utils/              ← Pure utility functions
└── constants.ts        ← App-wide constants

components/
├── ui/                 ← shadcn/ui base components
├── shared/             ← Reusable composed components (e.g., DataTable, StatusBadge)
└── [feature]/          ← Feature-specific components (e.g., booking-form/, dashboard/)
```

## Key Principles

- **Feature folders** — co-locate components, hooks, types, tests by feature, not by file type.
- **DAL pattern** — all database queries go through `lib/dal/`. No raw Prisma calls in components or actions.
- **Actions are thin** — a Server Action validates input, calls the DAL, and returns a result. No business logic inline.
- **One component per file** — exceptions only for tightly coupled sub-components.
- **Barrel exports sparingly** — only for public APIs of a module. Don't barrel everything.

## File Naming

- Components: `PascalCase.tsx` (e.g., `BookingForm.tsx`)
- Utils/hooks/lib: `camelCase.ts` (e.g., `formatDate.ts`, `useBooking.ts`)
- Server Actions: `camelCase.ts` grouped by domain (e.g., `lib/actions/booking.ts`)
- Tests: `*.test.ts` co-located next to the source file
