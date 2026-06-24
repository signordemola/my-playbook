## 14. Testing

### Testing Priority for Booking Systems

Not all code deserves the same test coverage. Prioritize by business impact:

| Priority | What to Test | Why | Test Type |
| -------- | ------------ | --- | --------- |
| **1 (Critical)** | State transitions | Prevents impossible states | Unit |
| **2 (Critical)** | Pricing & billing calculations | One bug = wrong charges on every booking | Unit |
| **3 (High)** | Scheduling / slot generation | Wrong dates = missed appointments | Unit + Integration |
| **4 (High)** | Idempotency (charges, emails) | Prevents duplicate charges and notifications | Integration |
| **5 (High)** | Concurrency (double-booking) | Race conditions only surface under load | Load + Integration |
| **6 (Medium)** | Cancellation policy logic | Fee miscalculations cause disputes | Unit |
| **7 (Medium)** | Capacity checks | Prevents overbooking | Integration |
| **8 (Medium)** | Full booking flow (E2E) | Validates the user journey end-to-end | E2E |

---

### The Testing Pyramid

| Layer | Purpose | Speed | Isolation | When to Use |
| ----- | ------- | ----- | --------- | ----------- |
| **Unit** | Test pure business logic (pricing, state transitions, validations) | Fast (ms) | Full — no DB, no network | Every function with business rules |
| **Integration** | Test database interactions, service boundaries, real transactions | Medium (s) | Partial — real DB, mocked externals | DAL functions, concurrency, data constraints |
| **E2E** | Test complete user flows through the real UI | Slow (s–min) | None — full system | Critical booking flow, payment flow |
| **Load** | Test behavior under concurrent traffic | Variable | None | Double-booking prevention, slot generation under spike |

---

### Unit Testing Patterns

#### Test Business Logic, Not Implementation

```
✅  Test: "Cancellation 12 hours before appointment incurs 100% fee"
❌  Test: "prisma.booking.update is called with status CANCELLED"
```

Test **what** the function does, not **how** it does it. Implementation changes shouldn't break tests.

#### Use Factories, Not Fixtures

Generate test data dynamically instead of using static JSON or SQL fixtures:

```
✅  Factory: createBooking({ status: "CONFIRMED", startTime: tomorrow() })
❌  Fixture: static booking_123.json that depends on a specific database state
```

**Why:** Factories produce fresh, isolated data per test. Fixtures create hidden dependencies between tests.

#### Validation Schema Tests

Test your validation schemas with both valid and invalid inputs:

| Input Type | Test |
| ---------- | ---- |
| Valid input | Schema accepts and returns parsed data |
| Missing required fields | Schema rejects with specific field errors |
| Invalid types | Schema rejects (string where number expected) |
| Boundary values | Empty strings, zero, negative numbers, max-length strings |
| Injection attempts | SQL injection strings, XSS payloads — should be rejected or sanitized |

---

### Integration Testing Patterns

#### Use a Real Database

For critical paths (concurrency, pricing, constraints), mocks are insufficient:

```
1. Before each test suite: reset the test database (run migrations, clear data)
2. Before each test: seed only the data that test needs (via factories)
3. Run the test against the real database
4. After the test: clean up (transaction rollback or truncate)
```

**When to use mocks vs real DB:**

| Situation | Use |
| --------- | --- |
| Testing pure business logic (fee calculation) | Mocks — fast, isolated |
| Testing DB constraints (unique indexes, exclusion constraints) | Real DB — mocks can't simulate constraints |
| Testing transaction behavior (atomicity, locking) | Real DB — mocks can't simulate transaction rollback |
| Mocks are becoming complex (simulating relations, joins) | Switch to real DB |

#### Concurrency Tests

Race conditions can't be reliably reproduced with single-threaded tests. You need parallel execution:

```
1. Seed a slot with capacity = 1
2. Fire N concurrent booking requests for the same slot
3. Assert: exactly 1 succeeds, N-1 fail with "slot unavailable"
4. Assert: the database has exactly 1 booking for that slot
```

---

### E2E Testing Patterns

Test the complete user journey through a real browser:

| Flow | What to Test |
| ---- | ------------ |
| **Booking creation** | Search → select slot → fill form → submit → see confirmation |
| **Cancellation** | View booking → cancel → see fee warning → confirm → booking status changes |
| **Payment flow** | Add payment method → charge → verify receipt email |
| **Edge cases** | Double-click submit, back button during checkout, expired session |

**Rules for E2E tests:**
- Keep them focused on **critical revenue paths** — don't E2E test every UI element
- Use unique, descriptive IDs on interactive elements for reliable selectors
- Seed test data at the start of each test — never depend on data from a previous test

---

### Edge Cases Every Booking System Must Test

| Category | Edge Case |
| -------- | --------- |
| **Time** | Leap year (Feb 29), DST transition, midnight boundary, January 1 |
| **Concurrency** | Last slot booked simultaneously by 2 users |
| **Payment** | Card declined, network timeout during charge, webhook arrives before redirect |
| **User behavior** | Double-click submit, back button mid-checkout, session expires during booking |
| **State** | Cancel a completed booking (should be rejected), rebook a cancelled slot |
| **Capacity** | Book the last seat, book seat N+1 (should fail), waitlist overflow |
| **Data** | Empty strings, max-length inputs, Unicode characters in names, SQL injection in notes |

---

### Query Budget Testing

Add query counters to your test suite. Fail the build if a single request fires more than N database queries:

```
Dashboard page budget: max 5 queries
Booking creation budget: max 3 queries
API listing endpoint budget: max 2 queries
```

This catches N+1 regressions before they reach production (see `core/database.md`).

---

### Test Environment Setup

| Concern | Pattern |
| ------- | ------- |
| **Database** | Separate test database. Reset between suites. Use same migrations as production. |
| **External services** | Mock payment providers, email APIs, calendar sync. Never hit real external services in tests. |
| **Time** | Freeze or mock the current time for deterministic date-based tests. |
| **Secrets** | Use test-specific env vars. Never share production credentials with tests. |
| **Isolation** | Each test gets fresh data. No test depends on another test's side effects. |

---

### Rules

- **Prioritize by business impact.** Pricing bugs and double-bookings cost real money. Test those first.
- **Factories over fixtures.** Generate test data dynamically for isolation and readability.
- **Use a real database for integration tests.** Mocks can't simulate constraints, transactions, or race conditions.
- **Test concurrency with parallel requests.** Single-threaded tests can't find race conditions.
- **Freeze time in date-sensitive tests.** Non-deterministic tests are worse than no tests.
- **Set query budgets.** Catch N+1 regressions before they reach production.
- **Mock externals, never production services.** Tests should never charge real cards or send real emails.
- **Edge case tests are mandatory** for time, concurrency, payment, and user behavior boundaries.
