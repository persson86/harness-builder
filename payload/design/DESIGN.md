---
version: "1.0.0"
product: "my-product"
updated: "2026-06-08"

colors:
  primary:
    default: "#1A73E8"
    hover: "#1557B0"
    active: "#0D47A1"
    subtle: "#E8F0FE"
  neutral:
    background: "#FFFFFF"
    surface: "#F8F9FA"
    border: "#DADCE0"
    muted: "#5F6368"
    text: "#202124"
  feedback:
    success: "#1E8E3E"
    warning: "#F9AB00"
    error: "#D93025"
    info: "#1A73E8"
  accent:
    default: "#E8710A"

typography:
  fontFamily:
    sans: "Inter, sans-serif"
    mono: "JetBrains Mono, monospace"
  heading:
    fontFamily: "Inter, sans-serif"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.01em"
    scale:
      h1: { size: "2.25rem", lineHeight: 1.15, letterSpacing: "-0.025em" }
      h2: { size: "1.875rem", lineHeight: 1.2,  letterSpacing: "-0.02em" }
      h3: { size: "1.5rem",   lineHeight: 1.25, letterSpacing: "-0.015em" }
      h4: { size: "1.25rem",  lineHeight: 1.3,  letterSpacing: "-0.01em" }
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
  code:
    fontFamily: "JetBrains Mono, monospace"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.6

spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  2xl: "48px"
  3xl: "64px"

radius:
  sm: "4px"
  md: "8px"
  lg: "12px"
  xl: "24px"
  full: "9999px"

shadow:
  none: "none"
  xs: "0 1px 2px rgba(0,0,0,0.08)"
  sm: "0 1px 3px rgba(0,0,0,0.12)"
  md: "0 4px 12px rgba(0,0,0,0.15)"
  lg: "0 8px 24px rgba(0,0,0,0.18)"

animation:
  duration:
    instant: "100ms"
    fast: "200ms"
    normal: "300ms"
    slow: "500ms"
  easing:
    default: "cubic-bezier(0.4, 0, 0.2, 1)"
    decelerate: "cubic-bezier(0, 0, 0.2, 1)"
    accelerate: "cubic-bezier(0.4, 0, 1, 1)"

breakpoint:
  sm: "640px"
  md: "768px"
  lg: "1024px"
  xl: "1280px"
  2xl: "1536px"

components:
  button:
    primary:
      background: "{colors.primary.default}"
      color: "#FFFFFF"
      radius: "{radius.md}"
      padding: "10px 20px"
    secondary:
      background: "transparent"
      border: "1px solid {colors.primary.default}"
      color: "{colors.primary.default}"
      radius: "{radius.md}"
      padding: "10px 20px"
    hover:
      primary:
        background: "{colors.primary.hover}"
      secondary:
        background: "{colors.primary.subtle}"
  card:
    background: "{colors.neutral.background}"
    border: "1px solid {colors.neutral.border}"
    radius: "{radius.lg}"
    padding: "{spacing.lg}"
  input:
    border: "1px solid {colors.neutral.border}"
    radius: "{radius.md}"
    padding: "10px 14px"
    focus:
      border: "2px solid {colors.primary.default}"
---

## Overview

Clean, professional interface focused on clarity and usability. Neutral palette with a high-trust primary blue, legible typography, and generous spacing. Clear visual hierarchy and explicit user feedback.

## Colors

**Primary (`#1A73E8`)** — primary actions, links, active states. Never use as background on large areas.

**Neutrals** — base for surfaces and text. `surface` (#F8F9FA) for secondary containers; `text` (#202124) for body text.

**Feedback** — use only for system states (success, error, warning). Not decorative.

**Accent** — use sparingly to highlight important secondary elements.

Minimum contrast of 4.5:1 for normal text (WCAG AA). Large text: 3:1. See `accessibility/wcag.md` for full criteria.

## Typography

Single typeface **Inter** for consistency. JetBrains Mono exclusively for code.

- `heading` — h1–h4 hierarchy, always bold (700). Use `rem` — never fixed `px` (ensures 200% zoom)
- `body` — running text, 16px base, lineHeight 1.5
- `label` — form labels, badges, metadata
- `code` — inline code and code blocks

Never mix more than two typeface families on the same screen.

## Layout

12-column grid on desktop, 4 columns on mobile. Spacing scale based on multiples of **8px**.

- Component internal gap: `sm` (8px) to `md` (16px)
- Section separation: `xl` (32px) to `2xl` (48px)
- Mobile side margins: `md` (16px)
- Max container: 1280px (`breakpoint.xl`), centered

## Elevation & Depth

Use shadows sparingly — depth should be functional, not decorative.

- **`none`** — no shadow (cards on surface, flat elements)
- **`xs`** — subtle highlight (list item hover)
- **`sm`** — cards and highlighted panels
- **`md`** — dropdowns, tooltips
- **`lg`** — modals, popovers

## Shapes

Progressive rounding as component size increases:

- Inputs and buttons: `md` (8px) — structural, not overly soft
- Cards and panels: `lg` (12px) — friendly containment
- Badges and chips: `full` (9999px) — status elements
- Never mix very different radii on the same screen

## Motion

Use `animation` tokens for all transitions — never ad-hoc durations or easings. Exits always faster than entrances (the user already knows what's leaving).

- Hover and click feedback: `instant` (100ms)
- Component state transitions: `fast` (200ms)
- General default: `normal` (300ms)
- Screen entrances, modals, drawers: `slow` (500ms)

Always respect `prefers-reduced-motion`. See `animation.md` for patterns by type.

## Components

**Primary button** — `primary.default` background, white text, `radius.md`. Hover darkens to `primary.hover`.

**Secondary button** — `primary.default` border, `primary.default` text, transparent background. Hover fills with `primary.subtle`.

**Card** — white background, `neutral.border` border, `lg` padding. `sm` shadow when elevated.

**Input** — `neutral.border` border; on focus switches to double `primary.default` border for clear accessibility.

Required states for interactive components: default, hover, focus, loading, error, success, disabled, empty state.

## Do's and Don'ts

**Do:**
- Use `spacing` tokens for all spacing — never arbitrary values
- Use `animation` tokens for all transitions — never ad-hoc durations
- Prefer `surface` as background for secondary containers, not custom greys
- Maintain consistent typographic hierarchy (heading → body → label)
- Test contrast before finalizing any color/text combination

**Don't:**
- Use `primary` as a background color on large areas
- Create new component variants without first checking if an existing one fits
- Mix more than 3 typographic weights on the same screen
- Use shadows on flat or status elements
- Ignore `prefers-reduced-motion`
