# Animation Guidelines

Principles and motion specifications for UI interfaces. Token values are in `design/DESIGN.md` → `animation` section.

---

## Principles

**1. Purposeful**
Every animation must have a functional purpose: guide attention, communicate state, confirm an action, or create continuity between screens. Purely decorative animations are avoided.

**2. Subtle**
Animation should never compete with content. The user should not notice the animation — they should notice the result.

**3. Responsive**
Animations must respect `prefers-reduced-motion`. When the user signals a preference for less motion, use opacity transitions or disable non-essential animations.

**4. Consistent**
Use the `animation` tokens from `DESIGN.md`. Never create ad-hoc durations or easings.

---

## Reference tokens

| Token | Value | Usage |
|---|---|---|
| `animation.duration.instant` | 100ms | Hover, focus, click feedback |
| `animation.duration.fast` | 200ms | Component state transitions |
| `animation.duration.normal` | 300ms | Default for most animations |
| `animation.duration.slow` | 500ms | Screen entrances, modals, drawers |
| `animation.easing.default` | ease-in-out | General use |
| `animation.easing.decelerate` | ease-out | Elements entering the screen |
| `animation.easing.accelerate` | ease-in | Elements leaving the screen |

---

## Patterns by type

### Element entering the screen

```css
opacity: 0 → 1;
transform: translateY(8px) → translateY(0);
duration: slow (500ms);
easing: decelerate;
```

Use for: modals, drawers, toasts, side panels, async-loaded content.

### Element leaving the screen

```css
opacity: 1 → 0;
transform: translateY(0) → translateY(4px);
duration: fast (200ms);
easing: accelerate;
```

> Exits are faster than entrances — the user already knows what's disappearing.

### Button / interactive element hover

```css
background-color: [color] → [color-hover];
duration: instant (100ms);
easing: default;
```

### Loading skeleton

```css
background: linear-gradient(90deg, neutral.surface, neutral.border, neutral.surface);
background-size: 200%;
animation: shimmer 1.5s infinite;
easing: linear;
```

### Action feedback (success/error)

```css
opacity: 0 → 1;
transform: scale(0.8) → scale(1);
duration: fast (200ms);
easing: decelerate;
```

### Screen transition

```css
/* Current screen exit */
opacity: 1 → 0;
transform: translateX(0) → translateX(-16px);
duration: fast (200ms);

/* New screen entrance */
opacity: 0 → 1;
transform: translateX(16px) → translateX(0);
duration: normal (300ms);
```

---

## Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## What to avoid

- ❌ Bounce and spring on functional elements (reserve for celebratory moments, sparingly)
- ❌ Durations above 600ms for any routine interaction
- ❌ Looping animations without pause or user interaction
- ❌ Heavy parallax on content-heavy pages
- ❌ Linear easing on visually heavy elements (feels mechanical)
