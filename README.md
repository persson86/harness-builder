# harness-builder

Versioned harness config for coding agents: behavior guidelines, settings, statusline, and design guidance.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/persson86/harness-builder/main/install.sh)
```

Copies `CLAUDE.md`, `AGENTS.md`, `.claude/settings.example.json`, and `statusline-command.sh` into the current directory. Existing files are skipped.

After installing, copy `.claude/settings.example.json` → `.claude/settings.json` and set your paths.

## Contents

- **`CLAUDE.md` / `AGENTS.md`** — agent behavior guidelines (think before coding, simplicity, surgical changes, goal-driven execution, preferred tools). Kept mirrored: edit both together.
- **`.claude/settings.example.json`** — harness settings template (autocompact, permissions). Copy to `settings.json` and adjust paths.
- **`statusline-command.sh`** — Claude Code statusline: cumulative session cost and tokens per model, 5h rate-limit usage, and reset countdown.
- **`design/`** — design tokens (`DESIGN.md`), WCAG accessibility, animation, voice & tone, writing rules, and a visual demo (`index.html`).
