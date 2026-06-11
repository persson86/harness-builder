# harness-builder

Versioned harness config for coding agents: behavior guidelines, settings, statusline, and design guidance.

## Contents

- **`CLAUDE.md` / `AGENTS.md`** — agent behavior guidelines (think before coding, simplicity, surgical changes, goal-driven execution, preferred tools). Kept mirrored: edit both together.
- **`.claude/settings.example.json`** — harness settings template (autocompact, permissions). Copy to `settings.json` and adjust paths.
- **`statusline-command.sh`** — Claude Code statusline: cumulative session cost and tokens per model, 5h rate-limit usage, and reset countdown.
- **`design/`** — design tokens (`DESIGN.md`), WCAG accessibility, animation, voice & tone, writing rules, and a visual demo (`index.html`).

## Usage

Files are read automatically by Claude Code when a session runs in the repo folder.
