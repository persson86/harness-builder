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

Preview an update without touching files:

```bash
./install.sh /path/to/project --update --dry-run
```

Remote installs and updates honor:

- `HB_REPO` - GitHub repo, default `persson86/harness-builder`.
- `HB_REF` - Git ref, default `main`.
- `HB_INSTALLER` - local installer path used by `harness/scripts/update.sh`.

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
    ├── hooks/
    │   ├── check-quality-gates.sh
    │   └── design-slop-scan.sh
    └── skills/
        ├── design-system-guardian/
        ├── text-integrity-audit/
        └── visual-originality-audit/
```

Most `payload/` files are harness-managed and overwritten by update. Update also
removes stale harness-managed files when their current hash still matches the old
manifest; locally modified stale files are kept with a warning.
`CLAUDE.md` and `AGENTS.md` are merged: content inside
`harness-builder:local-scope` markers is preserved, and legacy
`**Exceptions (read-only):** ...` lines are migrated into that block.
Legacy doc migrations are backed up under `harness/backups/`; projects that commit
installed harness files should usually add `harness/backups/` to their own
`.gitignore`.
`.claude/settings.json` is project-owned: updates preserve local `env`,
`permissions`, custom `statusLine`, and unrelated hooks while refreshing the
harness Stop hook. If absent, updates add harness defaults such as
`statusLine` and `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`.
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
  "design": "bash .claude/hooks/design-slop-scan.sh --changed .",
  "gates": {
    "lint_on_stop": true,
    "test_on_stop": true,
    "build_on_stop": false,
    "design_on_stop": false,
    "cache": false
  }
}
```

On Claude Code `Stop`, `check-quality-gates.sh` runs declared commands from the
project root using `bash -c`. Commands should be self-contained; if a project
depends on shell profile setup, put that setup in the configured command. Empty
commands are skipped. Failed commands block session end with the command, exit
code, the last 80 output lines, and the one-time skip setting to change if the
user is legitimately stuck.

Set `gates.cache` to `true` to skip gates when the git working tree key is
unchanged since the last successful run. The cache is stored at
`.claude/.quality-gates-ok`; projects that commit installed harness files should
usually add that path to their own `.gitignore`.

The design gate is opt-in. New installs get the `design` command with
`design_on_stop: false`; existing installs keep their project-owned
`.claude/quality-gates.json`, so updates do not add these keys automatically. To
enable design scanning in an existing project, add the `design` command and set
`gates.design_on_stop` to `true`.

`design-slop-scan.sh` scans markup/CSS and docs for deterministic design and text
tells. It is a heuristic regex/Perl scanner, not a CSS or HTML parser. The
default template uses `--changed`, which scans dirty tracked files plus untracked
files in git repos and falls back to full-path scanning outside git. Text Unicode
punctuation is review-only by default; use `--strict-text` when a project wants
that to fail. Human-readable output aggregates repeated findings by rule and file;
`--json` keeps all individual findings and includes aggregate metadata.

After install, the installer prints suggested quality-gate commands for common
project types (`package.json`, `pyproject.toml`, or `Makefile`) without writing
those commands into project-owned config.

Manual design skills provide the judgment layer after scanner evidence:

- `/visual-originality-audit` - rendered UI originality and category-cliche review.
- `/text-integrity-audit` - copy specificity, rhythm, punctuation, and tone review.
- `/design-system-guardian` - token adherence against `design/DESIGN.md`.

## Verify

After install or update:

```bash
bash harness/scripts/verify.sh
```

Use `--quiet` to print only warnings/failures and the final result.
`verify.sh` checks installed files, executable bits, JSON validity, hook syntax,
skills, statusline wiring, and manifest drift. Manifest drift is diagnostic-only
so local hotfixes are visible without bricking the workspace. When network access
is available, it also checks whether the installed `harness/.version` is behind
the repo/ref recorded in `harness/.install.json`; network failures are ignored.

## Contents

- `payload/CLAUDE.md` and `payload/AGENTS.md` - agent behavior guidelines.
- `payload/.claude/settings.json` - Claude Code hook wiring.
- `payload/.claude/hooks/check-quality-gates.sh` - Stop hook for lint/test/build/design.
- `payload/.claude/hooks/design-slop-scan.sh` - deterministic design/text scanner.
- `payload/.claude/skills/` - manual design quality audit skills.
- `payload/harness/scripts/update.sh` - one-command harness update.
- `payload/statusline-command.sh` - Claude Code statusline helper.
- `payload/design/` - design tokens, accessibility, animation, voice, writing
  rules, and a visual demo.
