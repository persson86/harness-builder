# harness-builder

Versioned harness config for coding agents: behavior guidelines, settings, statusline, and design guidance.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/persson86/harness-builder/main/install.sh)
```

Sets up the current directory as a workspace:

```
workspace/
├── CLAUDE.md                  ← copy: customize per machine/workspace
├── AGENTS.md                  ← symlink into the repo clone
├── statusline-command.sh      ← symlink into the repo clone
├── design/                    ← copy: working version (repo clone is the backup)
├── .claude/
│   └── settings.example.json  ← symlink into the repo clone
└── projects/
    └── harness-builder/       ← full repo clone; evolve the harness from here
```

Symlinked files update automatically when the clone is pulled or edited; copied files (`CLAUDE.md`, `design/`) are yours to customize locally. Existing files are never overwritten.

After installing, copy `.claude/settings.example.json` → `.claude/settings.json` and set your paths.

## Contents

- **`CLAUDE.md` / `AGENTS.md`** — agent behavior guidelines (think before coding, simplicity, surgical changes, goal-driven execution, preferred tools). Kept mirrored: edit both together.
- **`.claude/settings.example.json`** — harness settings template (autocompact, permissions). Copy to `settings.json` and adjust paths.
- **`statusline-command.sh`** — Claude Code statusline: cumulative session cost and tokens per model, 5h rate-limit usage, and reset countdown.
- **`design/`** — design tokens (`DESIGN.md`), WCAG accessibility, animation, voice & tone, writing rules, and a visual demo (`index.html`).
