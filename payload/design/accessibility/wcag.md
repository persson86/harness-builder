# Accessibility — WCAG 2.1 AA

Essential criteria every component and screen must meet. Minimum required level: **AA**.

---

## 1. Color contrast

| Text type | Minimum ratio |
|---|---|
| Normal text (< 18pt / < 14pt bold) | **4.5:1** |
| Large text (≥ 18pt / ≥ 14pt bold) | **3:1** |
| UI components and graphics | **3:1** |

**WCAG criterion:** 1.4.3, 1.4.11

> Never convey information by color alone. Always combine color with an icon, text, or pattern.

---

## 2. Forms

- Every field must have a visible associated `<label>`
- Error messages must be descriptive ("Invalid email" — not "Field error")
- Required fields signaled visually AND in text (not only with an asterisk)
- Fill hints placed outside the placeholder (which disappears on typing)

**WCAG criterion:** 1.3.1, 3.3.1, 3.3.2

---

## 3. Keyboard navigation

- Every interactive element reachable via `Tab`
- Focus order follows logical visual order
- Focus never gets trapped in an element (except modals — see below)
- Visible focus indicator with contrast of at least 3:1

**In modals and dialogs:**
- Focus trapped inside the modal while open
- `Esc` closes the modal
- On close, focus returns to the element that opened the modal

**WCAG criterion:** 2.1.1, 2.4.3, 2.4.7

---

## 4. Alternative text

- Informative images: `alt` describing the content ("Bar chart showing 40% growth in January")
- Decorative images: `alt=""` (empty string)
- Interactive icons without visible text: `aria-label` describing the action ("Close modal")
- Icons next to text: decorative — `aria-hidden="true"`

**WCAG criterion:** 1.1.1

---

## 5. Minimum target size

- Minimum clickable area: **44 × 44px** (even if the visual element is smaller)
- Spacing between targets: at least **8px** to avoid accidental taps on mobile

**WCAG criterion:** 2.5.5

---

## 6. State feedback

- State changes that don't shift focus must use `aria-live` (e.g., character counter, inline success messages)
- Async actions must indicate loading state (spinner with `aria-label="Loading"`)
- Validation errors must be announced by screen readers

**WCAG criterion:** 4.1.3

---

## 7. Text scaling

- The interface must not break at up to 200% zoom
- Never use fixed `px` for `font-size` in CSS — prefer `rem`

**WCAG criterion:** 1.4.4

---

## Recommended tools

| Tool | For | When to use |
|---|---|---|
| axe DevTools | Automated browser audit | Visual QA |
| NVDA / VoiceOver | Screen reader testing | Visual QA |
| Manual keyboard testing | Verify keyboard navigation | Visual QA |

---

## References

- [WCAG 2.1 full spec](https://www.w3.org/TR/WCAG21/)
- Criteria covered: 1.1.1, 1.3.1, 1.4.3, 1.4.4, 1.4.11, 2.1.1, 2.4.3, 2.4.7, 2.5.5, 3.3.1, 3.3.2, 4.1.3
