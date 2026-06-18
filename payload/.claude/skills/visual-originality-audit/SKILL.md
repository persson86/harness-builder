---
name: visual-originality-audit
description: Audit rendered UI for category cliches, generic composition, and visual tells that deterministic scanners cannot judge.
---

# Visual Originality Audit

Use this skill when a UI has been implemented and needs a design judgment beyond linting. The goal is to decide whether the result has a point of view, or whether it falls back to generic generated-layout patterns.

## First Step

Run the deterministic scanner first and treat it as evidence, not as the verdict:

```bash
bash .claude/hooks/design-slop-scan.sh .
```

If the scanner is unavailable, state that limitation and continue with manual review. Do not pretend the scanner ran.

## Required Visual Inspection

Inspect the rendered output with agent-browser before judging originality. Prefer the live app or built HTML over raw source. Raw HTML/CSS is acceptable only as a fallback, and the verdict must say that visual confidence is lower.

Check:

- Category reflex: does the page look like the first obvious template for its category?
- Second cliche: after the first obvious pattern, does it use the second obvious pattern too?
- Repeated scaffolds: stacked cards, oversized heroes, decorative blobs, split text/media panels, generic gradients, and repeated three-column blocks.
- Product fit: does the layout serve the actual workflow, object, or audience?
- Brand/product/system register: does the screen feel like its domain, or like a neutral template wearing content?

## Judgment

Ground the verdict in visible evidence. Name the specific pattern and where it appears.

Use one verdict:

- `distinctive` - the UI has a clear point of view and the choices support the product.
- `acceptable but safe` - the UI is competent but relies on familiar patterns that should be sharpened if this is a flagship surface.
- `generic-blocking` - the UI is dominated by category cliches or generated-design tells and should be revised before shipping.

## Output

Return:

```text
Verdict: distinctive | acceptable but safe | generic-blocking
Scanner evidence: ...
Visual evidence: ...
Required changes: ...
```

Keep recommendations concrete. Replace broad advice like "make it more premium" with specific moves such as "remove the split hero card, make the product state the first-viewport signal, and reduce the decorative gradient background."
