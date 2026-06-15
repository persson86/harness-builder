# harness-builder

Versioned harness config for coding agents: behavior guidelines, Claude settings,
quality gates, statusline, and design guidance.

## Install

From a local clone:

```bash
./install.sh /path/to/project
```

Remote install:

```bash
curl -fsSL https://raw.githubusercontent.com/persson86/harness-builder/main/install.sh | bash -s -- /path/to/project
```

Update an existing install:

```bash
cd /path/to/project
bash harness/scripts/update.sh
```

The installer copies `payload/` into the project root and records:

```text
project/
├── CLAUDE.md
├── AGENTS.md
├── statusline-command.sh
├── design/
├── harness/
│   ├── .manifest
│   ├── .version
│   ├── .install.json
│   └── scripts/
│       ├── update.sh
│       └── verify.sh
└── .claude/
    ├── settings.json
    ├── quality-gates.json
    └── hooks/check-quality-gates.sh
```

Most `payload/` files are harness-managed and overwritten by update.
`CLAUDE.md` and `AGENTS.md` are merged: content inside
`harness-builder:local-scope` markers is preserved, and legacy
`**Exceptions (read-only):** ...` lines are migrated into that block.
`.claude/settings.json` is project-owned: updates preserve local `env`,
`permissions`, and unrelated hooks while refreshing the harness Stop hook.
`.claude/quality-gates.json` is project-owned: it is copied only when absent and
is never overwritten by update.
`harness/.manifest` records final hashes for managed files after merge, but
excludes `.claude/settings.json` because that file is local project config.

## Quality Gates

Configure `.claude/quality-gates.json` in the installed project:

```json
{
  "lint": "npm run lint",
  "test": "npm test",
  "build": "",
  "gates": {
    "lint_on_stop": true,
    "test_on_stop": true,
    "build_on_stop": false
  }
}
```

On Claude Code `Stop`, `check-quality-gates.sh` runs declared commands from the
project root. Empty commands are skipped. Failed commands block session end with
the command, exit code, and the last 80 output lines.

## Verify

After install or update:

```bash
bash harness/scripts/verify.sh
```

`verify.sh` checks installed files, executable bits, JSON validity, hook syntax,
and manifest drift. Manifest drift is diagnostic-only so local hotfixes are
visible without bricking the workspace.

## Contents

- `payload/CLAUDE.md` and `payload/AGENTS.md` - agent behavior guidelines.
- `payload/.claude/settings.json` - Claude Code hook wiring.
- `payload/.claude/hooks/check-quality-gates.sh` - Stop hook for lint/test/build.
- `payload/harness/scripts/update.sh` - one-command harness update.
- `payload/statusline-command.sh` - Claude Code statusline helper.
- `payload/design/` - design tokens, accessibility, animation, voice, writing
  rules, and a visual demo.
