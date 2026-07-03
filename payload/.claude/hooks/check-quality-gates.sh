#!/usr/bin/env bash
set -u

INPUT="$(cat || true)"
if command -v jq >/dev/null 2>&1 &&
   printf '%s' "$INPUT" | jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CONFIG="$ROOT/.claude/quality-gates.json"
CACHE_FILE="$ROOT/.claude/.quality-gates-ok"

[[ -f "$CONFIG" ]] || exit 0

plain_block() {
  printf '{"decision":"block","reason":"%s"}\n' "$1"
  exit 0
}

block() {
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '{"decision":"block","reason":%s}\n' "$(jq -Rn --arg r "$reason" '$r')"
  else
    plain_block "quality gates require jq to report failures safely"
  fi
  exit 0
}

command -v jq >/dev/null 2>&1 || plain_block "quality gates require jq; install jq or remove .claude/quality-gates.json"

if ! jq empty "$CONFIG" >/dev/null 2>&1; then
  block ".claude/quality-gates.json is invalid JSON. Fix it before ending the session."
fi

if ! jq -e '
  ((.lint // "") | type == "string") and
  ((.test // "") | type == "string") and
  ((.build // "") | type == "string") and
  ((.design // "") | type == "string") and
  ((.gates // {}) | type == "object") and
  ((.gates.lint_on_stop // true) | type == "boolean") and
  ((.gates.test_on_stop // true) | type == "boolean") and
  ((.gates.build_on_stop // false) | type == "boolean") and
  ((.gates.design_on_stop // false) | type == "boolean") and
  ((.gates.cache // false) | type == "boolean")
' "$CONFIG" >/dev/null; then
  block ".claude/quality-gates.json has an invalid shape. Expected string lint/test/build/design commands and boolean gates."
fi

config_value() {
  local expr="$1"
  jq -r "$expr" "$CONFIG" 2>/dev/null || printf ''
}

gate_enabled() {
  local key="$1"
  local default="$2"
  local value
  value="$(config_value ".gates.${key}_on_stop // \"$default\"")"
  [[ "$value" == "true" ]]
}

gate_command() {
  local key="$1"
  config_value ".${key} // \"\""
}

cache_enabled() {
  [[ "$(config_value '.gates.cache // false')" == "true" ]]
}

sha256_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

working_tree_key() {
  cd "$ROOT" || return 1
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

  local head status_hash diff_hash
  head="$(git rev-parse HEAD 2>/dev/null)" || return 1
  status_hash="$(git status --porcelain=v1 -- . ':(exclude).claude/.quality-gates-ok' 2>/dev/null | sha256_stdin)" || return 1
  diff_hash="$(git diff --no-ext-diff --binary HEAD -- . ':(exclude).claude/.quality-gates-ok' 2>/dev/null | sha256_stdin)" || return 1
  printf '%s:%s:%s\n' "$head" "$status_hash" "$diff_hash"
}

cache_matches() {
  cache_enabled || return 1
  [[ -f "$CACHE_FILE" ]] || return 1

  local key old
  key="$(working_tree_key)" || return 1
  old="$(cat "$CACHE_FILE" 2>/dev/null || printf '')"
  [[ "$key" == "$old" ]]
}

write_cache() {
  cache_enabled || return 0
  local key
  key="$(working_tree_key)" || return 0
  mkdir -p "$(dirname "$CACHE_FILE")"
  printf '%s\n' "$key" > "$CACHE_FILE"
}

run_gate() {
  local key="$1"
  local cmd="$2"
  local output status snippet

  output="$(cd "$ROOT" && bash -c "$cmd" 2>&1)"
  status=$?

  if [[ "$status" -ne 0 ]]; then
    rm -f "$CACHE_FILE" 2>/dev/null || true
    snippet="$(printf '%s\n' "$output" | tail -n 80)"
    block "Quality gate failed: $key\nCommand: $cmd\nExit code: $status\n\n$snippet\n\nTo skip this gate once, set gates.${key}_on_stop=false in .claude/quality-gates.json (revert after)."
  fi
}

run_if_declared() {
  local key="$1"
  local default_enabled="$2"
  local cmd

  gate_enabled "$key" "$default_enabled" || return 0
  cmd="$(gate_command "$key")"
  [[ -n "$cmd" ]] || return 0
  run_gate "$key" "$cmd"
}

if cache_matches; then
  exit 0
fi

run_if_declared "lint" "true"
run_if_declared "test" "true"
run_if_declared "build" "false"
run_if_declared "design" "false"

write_cache
exit 0
