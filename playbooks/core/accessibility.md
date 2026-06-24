## 15. Accessibility Patterns

> **Legal context:** The European Accessibility Act (EAA) enforcement began June 2025.
> WCAG 2.2 AA is the current compliance target.
> Source: [W3C WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/)

---

### The First Rule of ARIA

> If you can use a native HTML element, **do not use ARIA.**
> Incorrect ARIA makes things _worse_ than no ARIA.

Use `<form>`, `<label>`, `<button>`, `<input>`, `<select>` — never repurpose `<div>` as buttons.

---

### Booking Form Fundamentals

| Principle                         | Rule                                                                                            |
| --------------------------------- | ----------------------------------------------------------------------------------------------- |
| **Semantic HTML first**           | Use `<form>`, `<label>`, `<button>`, `<input>`, `<select>` — never repurpose `<div>` as buttons |
| **Every input needs a `<label>`** | Placeholders are NOT labels. Use `aria-describedby` for format hints.                           |
| **Keyboard navigation**           | All fields reachable via `Tab` in logical order. Visible focus states required.                 |
| **Error messages**                | Descriptive: "Please select a date after today" not "Invalid input"                             |
| **Required fields**               | Don't rely on `*` alone. Use `aria-required="true"` or text labels like "(required)".           |

---

### Accessible Date Pickers

The most accessible approach: provide manual text entry **alongside** a calendar widget.

```
✅ DO: Allow manual text input — "Date (MM/DD/YYYY)" with aria-describedby for format
✅ DO: Use a button to open the calendar — never auto-open on input focus
✅ DO: Make calendar grid keyboard-navigable:
       Arrow keys = move between days
       Page Up/Down = navigate months
       Home/End = first/last day of month
       Enter/Space = select date and close dialog
✅ DO: Move focus INTO the calendar when opened (to today's date or pre-selected date)
✅ DO: Return focus to the trigger button when calendar closes
✅ DO: Announce selected date to screen readers via aria-live="polite"

❌ DON'T: Force users to use a calendar-only widget
❌ DON'T: Use a date picker that traps keyboard focus (Esc must always close it)
❌ DON'T: Auto-advance to next step when a date is selected (unexpected for keyboard users)
```

> **W3C pattern reference:** [Date Picker Dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/)

---

### Accessible Time Slot Selection

- Use `role="radiogroup"` with `role="radio"` for time slots — or native radio buttons
- Show `aria-disabled="true"` + visual dimming for unavailable slots (don't remove them entirely — helps user understand the full schedule)
- If a slot has a TTL hold (soft lock), allow users to extend the timer (WCAG 2.2.1 — Timing Adjustable)
- Use `aria-live="polite"` regions to announce when selecting a slot changes availability

---

### Multi-Step Booking Wizards

#### Step Indicator
```html
<nav aria-label="Booking progress">
  <ol>
    <li aria-current="step">Step 1: Home Details</li>
    <li>Step 2: Service Selection</li>
    <li>Step 3: Schedule</li>
    <li>Step 4: Contact Info</li>
    <li>Step 5: Review & Pay</li>
  </ol>
</nav>
```

- Use `aria-current="step"` on the active step
- Update the page `<title>` to reflect progress: "Step 2 of 5: Service Selection — Book a Clean"

#### Focus Management Between Steps
1. When advancing to a new step → move focus to the **step heading** (`<h2>Step 2: Select Your Service</h2>`)
2. When going back → return focus to the same heading (not the "Back" button)
3. When validation fails → focus the **error summary** at the top of the form

#### Error Summary Pattern
```html
<div role="alert" aria-live="assertive" tabindex="-1" id="error-summary">
  <h3>There are 2 errors in this form</h3>
  <ul>
    <li><a href="#bedrooms">Please select the number of bedrooms</a></li>
    <li><a href="#zipcode">Please enter a valid zip code</a></li>
  </ul>
</div>

<input id="bedrooms" aria-invalid="true" aria-describedby="bedrooms-error" />
<span id="bedrooms-error">Please select the number of bedrooms</span>
```

- Focus the error summary container after validation fails
- Each error links to its corresponding field
- Each field with an error has `aria-invalid="true"` and `aria-describedby` pointing to the error message

---

### Color Contrast

| Element | Minimum Ratio | Notes |
| ------- | ------------- | ----- |
| **Normal text** (< 18pt / 14pt bold) | **4.5:1** | Most body copy, labels, descriptions |
| **Large text** (≥ 18pt / 14pt bold) | **3:1** | Headings, hero text |
| **UI components** (buttons, inputs, icons) | **3:1** | Against adjacent colors |
| **Focus indicators** | **3:1** | Must be visible against the background |

**Rules:**
- Test contrast in both light and dark modes — a color that passes in light mode may fail in dark
- Never use color alone to convey information (e.g., red for errors). Always pair with text or icons
- Placeholder text must meet 4.5:1 ratio (most defaults fail this — override them)
- Tool: [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

---

### Motion Reduction

Users with vestibular disorders, migraines, or epilepsy can experience nausea or seizures from excessive animation.

```css
/* Reduce non-essential animations when user prefers reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**Rules:**
- Don't remove ALL animation — replace complex motion with opacity fades or instant transitions
- Progress indicators and loading spinners are "essential motion" and can remain
- Auto-playing carousels must have a pause button (WCAG 2.2.2)
- Parallax scrolling effects must be disabled when `prefers-reduced-motion: reduce` is active

> **Source:** [W3C — Understanding SC 2.3.3: Animation from Interactions](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions)

---

### WCAG 2.2–Specific Requirements

These are **new in 2.2** (not in 2.1) and often missed:

| Criterion | What It Means | Booking System Impact |
| --------- | ------------- | --------------------- |
| **2.5.8 Target Size (Minimum)** | Interactive elements ≥ 24x24 CSS pixels | Calendar day cells, time slot buttons, "Skip" buttons |
| **2.4.11 Focus Not Obscured (Minimum)** | Focused element must not be fully hidden behind sticky headers or modals | Floating "Book Now" bar must not cover focused form fields |
| **3.3.7 Redundant Entry** | Don't ask for info the user already provided earlier in the flow | If they entered their name in Step 1, pre-fill it in Step 5's review |
| **3.2.6 Consistent Help** | Help mechanisms (chat, FAQ, phone) must be in the same location across pages | Put support link in the same spot in booking flow, portal, and dashboard |
| **2.4.13 Focus Appearance** | Focus indicator must be ≥ 2px thick and contrast ≥ 3:1 | Style `:focus-visible` with a bold outline — default browser outlines often fail |

---

### Skip to Content

The "Skip to content" link must be the **first focusable element** on every page:

```html
<body>
  <a href="#main-content" class="skip-link">Skip to content</a>
  <nav><!-- navigation --></nav>
  <main id="main-content"><!-- page content --></main>
</body>
```

```css
.skip-link {
  position: absolute;
  left: -9999px;
  z-index: 999;
}
.skip-link:focus {
  left: 1rem;
  top: 1rem;
  padding: 0.5rem 1rem;
  background: var(--color-primary);
  color: white;
  border-radius: 4px;
}
```

---

### Testing Checklist

| Test | Tool | Pass Criteria |
| ---- | ---- | ------------- |
| **Automated scan** | axe DevTools / Lighthouse | 0 critical or serious violations |
| **Keyboard navigation** | Manual (Tab, Shift+Tab, Enter, Esc, Arrow keys) | All interactive elements reachable and operable |
| **Screen reader** | NVDA (Windows), VoiceOver (Mac), TalkBack (Android) | All form labels, errors, and state changes announced correctly |
| **Color contrast** | WebAIM Contrast Checker | All text and UI components meet ratios above |
| **Motion** | Toggle `prefers-reduced-motion` in DevTools | Non-essential animations stop or simplify |
| **Zoom** | Browser zoom to 200% | No content overflow, no horizontal scrolling, all text readable |
