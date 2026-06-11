# Writing Rules

Technical writing decisions — consult this file when creating or reviewing interface copy.

---

## Verbs and actions

- Use imperative verbs on buttons and CTAs: "Save", "Send", "Cancel"
- Primary CTAs describe the outcome, not the mechanical action
  > ✅ "Create account" — ❌ "Submit form"
- Be specific: avoid generic verbs without context
  > ✅ "Delete project" — ❌ "Delete"

---

## Punctuation

- Use a period at the end of complete messages (errors, confirmations, instructions)
- No period on titles, labels, buttons, or placeholders
- Avoid exclamation marks — reserved for genuine celebratory moments, sparingly
- Ellipsis only in loading states: "Loading…", "Saving…"

---

## Capitalization

- Section titles and feature names: sentence case
  > ✅ "Account settings" — ❌ "Account Settings"
- Buttons: sentence case
  > ✅ "Create project" — ❌ "Create Project"
- Acronyms and abbreviations: follow established conventions
  > ✅ URL, API, ID, UI, UX

---

## Numbers

- Numbers 1–9: spell out in running text
  > "You have three notifications"
- Numbers 10 and above: use digits
  > "You have 14 notifications"
- In data interfaces and metrics: always digits, regardless of value
- Percentages: digit + symbol, no space
  > ✅ "10%" — ❌ "10 %"

---

## Terminology

- Be consistent: pick one term per concept and stick to it across the product
- Prefer plain language over technical terms when both are clear
  > ✅ "Sign in" — ❌ "Authenticate"
  > ✅ "Load more" — ❌ "Paginate"
- Never expose raw technical errors to the user: "timeout", "null pointer", "not found"

---

## Accessibility in writing

- Prefer inclusive constructions wherever possible
- Avoid generalizations that assume user profile

**Clarity for screen readers:**
- Never use visual-only elements to convey information — accompany with text
  > ✅ "Error: invalid email" — ❌ A red icon alone
- Links and buttons must make sense out of context
  > ✅ "View order details" — ❌ "Click here"
- Alternative texts describe function, not appearance
  > ✅ "Warning icon: irreversible action" — ❌ "Yellow triangle"

**Plain language:**
- Prefer short, direct sentences — one idea per sentence
- Avoid double negatives
  > ✅ "Only users with permission can edit" — ❌ "It is not possible to edit without access permission"
- Use active voice whenever possible
  > ✅ "The system saved your changes" — ❌ "Your changes were saved by the system"
