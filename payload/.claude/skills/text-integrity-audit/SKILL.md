---
name: text-integrity-audit
description: Audit product and technical copy for generated-text tells, weak specificity, rhythm problems, and tone drift.
---

# Text Integrity Audit

Use this skill when UI copy, documentation, or launch copy needs a judgment pass after the deterministic scanner. Anchor decisions in `design/voice-and-tone.md` and `design/writing-rules.md`.

## First Step

Run the text rules first:

```bash
bash .claude/hooks/design-slop-scan.sh .
```

Use scanner findings as evidence. Do not let a clean scan substitute for judgment.

## Review Passes

1. First and last sentence test: the first sentence must say something concrete, and the last sentence must not collapse into a generic recap.
2. Specificity pass: replace category claims with observable product facts, user actions, constraints, states, or outcomes.
3. Syntax variation: look for repeated sentence skeletons, especially "not just X but Y", "X is a concept that", and three-item quality stacks.
4. Punctuation and typography: verify punctuation follows `writing-rules.md`; review Unicode punctuation in Portuguese instead of blocking it automatically.
5. Tone fit: compare the copy to `voice-and-tone.md`; it should be direct, clear, and helpful without hype.

## Judgment

Use one verdict:

- `pass` - copy is specific, useful, and consistent with the voice rules.
- `revise` - copy is understandable but has generated-text tells or weak specificity.
- `block` - copy overpromises, hides behind generic phrasing, or violates the product voice in user-facing surfaces.

## Output

Return:

```text
Verdict: pass | revise | block
Scanner evidence: ...
Copy evidence: ...
Required edits: ...
```

When asking for changes, rewrite representative lines directly. Keep the fixes short and in the same language as the source text.
