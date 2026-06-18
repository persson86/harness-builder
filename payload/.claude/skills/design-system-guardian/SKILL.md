---
name: design-system-guardian
description: Review UI implementation against the Builder design tokens and flag hardcoded choices that should come from design/DESIGN.md.
---

# Design System Guardian

Use this skill when UI code must be checked against the Builder design system. The source of truth is `design/DESIGN.md`; `design/index.html` is the visual reference. Tokens are constraints, not hints.

## First Step

Run the scanner first:

```bash
bash .claude/hooks/design-slop-scan.sh .
```

Treat scanner findings as deterministic evidence, especially hard-coded radius, width, motion, and generated-design tells.

## Token Review

Inspect the implementation and compare it to `design/DESIGN.md`:

- Colors: use the defined primary, neutral, feedback, and accent roles. Do not add decorative palettes when an existing role fits.
- Spacing: use the 8px-based spacing scale. Explain any value outside the scale.
- Typography: use the declared font families, hierarchy, line heights, and letter spacing. Do not use viewport-scaled type.
- Radius: match the component role. Large soft radii need an explicit reason.
- Motion: use the duration/easing tokens and verify `prefers-reduced-motion`.
- Components: buttons, cards, inputs, and states should match the declared component contracts before creating variants.

## Judgment

Use one verdict:

- `aligned` - implementation follows the token system with only justified exceptions.
- `drift` - implementation mostly works but contains hardcoded values or variant choices that should be normalized.
- `block` - implementation ignores core tokens or creates a separate visual system.

## Output

Return:

```text
Verdict: aligned | drift | block
Scanner evidence: ...
Token evidence: ...
Required changes: ...
```

Prefer concrete substitutions, for example "replace `border-radius: 24px` on cards with `radius.lg` unless this is a badge/chip using `radius.full`."
