#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

failures=0

check() {
  local name="$1"
  shift
  printf '[verify] %s\n' "$name"
  if "$@"; then
    printf '  => ok\n'
  else
    printf '  => FAIL\n' >&2
    failures=$((failures + 1))
  fi
}

diagnose() {
  local name="$1"
  shift
  printf '[verify] %s\n' "$name"
  if "$@"; then
    printf '  => ok\n'
  else
    printf '  => WARN (diagnostic reported issues)\n' >&2
  fi
}

exists() {
  [[ -e "$1" ]]
}

executable() {
  [[ -x "$1" ]]
}

valid_json() {
  command -v jq >/dev/null 2>&1 && jq empty "$1" >/dev/null
}

quality_gates_shape() {
  [[ -f .claude/quality-gates.json ]] || return 0
  jq -e '
    ((.lint // "") | type == "string") and
    ((.test // "") | type == "string") and
    ((.build // "") | type == "string") and
    ((.gates // {}) | type == "object") and
    ((.gates.lint_on_stop // true) | type == "boolean") and
    ((.gates.test_on_stop // true) | type == "boolean") and
    ((.gates.build_on_stop // false) | type == "boolean")
  ' .claude/quality-gates.json >/dev/null
}

has_local_scope_markers() {
  local file="$1"
  grep -Fqx '<!-- harness-builder:local-scope:start -->' "$file" &&
    grep -Fqx '<!-- harness-builder:local-scope:end -->' "$file"
}

has_quality_gate_hook() {
  jq -e '
    any(.hooks.Stop[]?.hooks[]?; .command == "$CLAUDE_PROJECT_DIR/.claude/hooks/check-quality-gates.sh")
  ' ".claude/settings.json" >/dev/null
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

installed_matches_manifest() {
  local manifest="harness/.manifest"
  [[ -f "$manifest" ]] || { printf '  (sem harness/.manifest; install antigo ou manual)\n'; return 0; }

  local drift=0 rel want got line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    want="${line%% *}"
    rel="${line#* }"
    rel="${rel# }"
    if [[ ! -f "$rel" ]]; then
      printf '  AUSENTE: %s\n' "$rel" >&2
      drift=$((drift + 1))
      continue
    fi
    got="$(sha256_of "$rel")"
    if [[ "$want" != "$got" ]]; then
      printf '  DRIFT: %s\n' "$rel" >&2
      drift=$((drift + 1))
    fi
  done < "$manifest"

  [[ "$drift" -eq 0 ]]
}

check "CLAUDE.md exists" exists "CLAUDE.md"
check "AGENTS.md exists" exists "AGENTS.md"
check "statusline command exists" exists "statusline-command.sh"
check "Claude settings exist" exists ".claude/settings.json"
check "install metadata exists" exists "harness/.install.json"
check "quality gate hook exists" exists ".claude/hooks/check-quality-gates.sh"
check "verify script executable" executable "harness/scripts/verify.sh"
check "update script executable" executable "harness/scripts/update.sh"
check "quality gate hook executable" executable ".claude/hooks/check-quality-gates.sh"

check "jq is available" command -v jq
check "Claude settings JSON is valid" valid_json ".claude/settings.json"
check "install metadata JSON is valid" valid_json "harness/.install.json"
check "quality gates JSON is valid" valid_json ".claude/quality-gates.json"
check "quality gates schema is valid" quality_gates_shape
check "Claude settings include quality gate hook" has_quality_gate_hook
check "CLAUDE.md has local scope markers" has_local_scope_markers "CLAUDE.md"
check "AGENTS.md has local scope markers" has_local_scope_markers "AGENTS.md"
check "quality gate hook syntax" bash -n ".claude/hooks/check-quality-gates.sh"
check "statusline syntax" bash -n "statusline-command.sh"
check "update script syntax" bash -n "harness/scripts/update.sh"
diagnose "installed files match manifest" installed_matches_manifest

if (( failures > 0 )); then
  printf '[verify] %d failure(s)\n' "$failures" >&2
  exit 1
fi

printf '[verify] all checks passed\n'
