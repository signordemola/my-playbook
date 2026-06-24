# Code Style Rules

> These are my personal coding preferences. AI agents must follow these exactly.

## Language & Runtime

- **TypeScript** — strict mode, no `any`, no `as` casts unless truly necessary
- **ES2015+** — arrow functions, `const`/`let` (never `var`), template literals, destructuring
- **Node.js** — latest LTS

## Naming

- `camelCase` for variables, functions, hooks
- `PascalCase` for components, types, interfaces, classes
- `SCREAMING_SNAKE_CASE` for env vars and constants
- Boolean variables: prefix with `is`, `has`, `should`, `can` — e.g., `isActive`, `hasPermission`
- Event handlers: prefix with `handle` — e.g., `handleClick`, `handleSubmit`
- Async functions: name describes the action — e.g., `fetchUser`, `createBooking`

## Functions

- **Early returns** — avoid nesting beyond 2 levels. Guard clause first, happy path last.
- **Named exports** — no default exports except Next.js pages/layouts.
- **Small functions** — if a function is > 30 lines, it's doing too much. Extract.
- **Pure where possible** — no side effects unless the function's purpose IS the side effect.

## Error Handling

- **Server Actions return typed results** — never `throw` from Server Actions. Use `{ success, data, errors }` pattern.
- **Exception:** `redirect()` and `notFound()` are fine — Next.js handles them.
- **Try/catch at boundaries** — catch at the top-level handler, not deep inside business logic.
- **Typed errors** — use discriminated unions or Zod error maps, not string messages.

## Validation

- **Zod v4** — use top-level validators (`z.url()`, `z.email()`, `z.uuid()`)
- **Validate on both sides** — same schema shared between client form and server action.
- **Parse, don't validate** — use `schema.parse()` to get typed output, not manual checks.

## Database (Prisma)

- **Client Extensions** — not deprecated `$use` middleware.
- **`select` over `include`** — whitelist fields. Only `include` when you need the full relation.
- **Never call external APIs inside `$transaction`** — the lock is held until the transaction closes.
- **Atomic operations** for shared state — no check-then-act patterns.

## Imports & Organization

- Group imports: 1) external packages, 2) internal modules, 3) relative files
- No circular imports — if two files import each other, extract the shared code.
- Co-locate related code — component, hook, types, tests in the same feature folder.

## Comments

- **Don't comment what the code does** — the code should be readable enough.
- **Do comment why** — business logic context, non-obvious decisions, edge case explanations.
- **TODO format:** `// TODO(username): description — TICKET-123`
