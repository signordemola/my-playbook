## Timezone Handling

> General UTC/DST rules for any project. Domain-specific timezone edge cases
> (e.g., recurring booking appointments) live in their respective playbooks.

### The Golden Rule

**Store in UTC. Display in the user's timezone. Convert at the last possible moment.**

---

### Two Types of Time

Not all timestamps are the same. The strategy depends on what kind of time you're storing:

| Type | Example | Storage Strategy |
| ---- | ------- | ---------------- |
| **Absolute instant** | "Payment processed", "Order placed" | Store as UTC. Always correct regardless of timezone rules changing. |
| **Wall-clock time** | "Meeting every Monday at 9:00 AM" | Store **local time + IANA timezone ID**. Recalculate UTC instances. |

**Why the distinction matters:** If you store a recurring "9:00 AM" event as UTC, and the timezone's DST rules change, the event will silently shift to 8:00 AM or 10:00 AM local time. The user scheduled *9:00 AM in their timezone*, not a specific UTC offset.

---

### IANA Timezone IDs

Always use **IANA timezone identifiers**, never fixed offsets:

```
✅  America/New_York, Europe/London, Africa/Lagos
❌  EST, GMT+5, UTC-4
```

Fixed offsets don't account for DST transitions or political timezone changes. `America/New_York` is `UTC-5` in winter and `UTC-4` in summer — a fixed offset will be wrong half the year.

---

### DST Edge Cases

#### "Fall Back" (Clocks Go Back)

The hour 1:00 AM – 1:59 AM occurs **twice**. A scheduled event at "1:30 AM" is ambiguous.

**Pattern:** Flag or reject events that fall within the ambiguous window. Or default to the first occurrence (before the transition).

#### "Spring Forward" (Clocks Go Forward)

The hour 2:00 AM – 2:59 AM **doesn't exist**. A scheduled event at "2:30 AM" is impossible.

**Pattern:** If a recurring event lands on a non-existent time, shift it to the next valid time (3:00 AM) and notify the user.

---

### Common Bugs This Prevents

| Bug | Cause |
| --- | ----- |
| Notification sent at wrong time | `Date` comparison done in UTC instead of the business timezone |
| Fee wrongly applied | "< 48 hours" calculated in UTC, not the user's local time |
| Entity shows wrong date in portal | Server renders in UTC, client is in a different timezone |
| Recurring event shifts by 1 hour after DST | Stored as a fixed UTC offset instead of local time + IANA zone |

---

### Rules

- **The server determines "today" and "tomorrow"** — never the client. Convert to the business timezone server-side, then compare.
- **Store the business timezone as a config value** — not hardcoded. A business may move or serve multiple timezones.
- **Use IANA-aware libraries** — never raw `Date` math. Any library that dynamically calculates offsets based on date + IANA ID works.
- **Display conversion happens at the edge** — API responses return UTC, the frontend converts to the user's timezone for display.
- **Never assume an offset is permanent** — governments change timezone rules. Your code must handle this.
- **Log in UTC** — audit trails, payment timestamps, and server logs are always UTC. Only display/business logic uses local time.
