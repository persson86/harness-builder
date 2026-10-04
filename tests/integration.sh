#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/harness-builder-tests.XXXXXX")"
JUNK_FILE="$ROOT/payload/.DS_Store"

cleanup() {
  rm -rf "$TMP_ROOT"
  rm -f "$JUNK_FILE"
}
trap cleanup EXIT

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

assert() {
  local msg="$1"
  shift
  "$@" || { echo "FAIL: $msg" >&2; exit 1; }
}

assert_file() {
  [[ -f "$1" ]] || { echo "FAIL: missing file $1" >&2; exit 1; }
}

assert_no_file() {
  [[ ! -e "$1" ]] || { echo "FAIL: unexpected file $1" >&2; exit 1; }
}

assert_jq() {
  local file="$1" expr="$2" msg="$3"
  jq -e "$expr" "$file" >/dev/null || { echo "FAIL: $msg" >&2; exit 1; }
}

snapshot_tree() {
  local dir="$1"
  (
    cd "$dir"
    find . -type f \
      ! -path './.git/*' \
      ! -path './harness/backups/*' \
      ! -path './.claude/.quality-gates-ok' \
      -print | sort |
      while IFS= read -r file; do
        printf '%s  %s\n' "$(sha256_of "$file")" "$file"
      done
  )
}

install_into() {
  local target="$1"
  mkdir -p "$target"
  bash "$ROOT/install.sh" "$target" "$@"
}

echo "[integration] clean install and verify"
touch "$JUNK_FILE"
CLEAN="$TMP_ROOT/clean"
install_into "$CLEAN" >/dev/null
(cd "$CLEAN" && bash harness/scripts/verify.sh --quiet)
assert_file "$CLEAN/.claude/settings.json"
assert_jq "$CLEAN/.claude/settings.json" '.statusLine.command == "$CLAUDE_PROJECT_DIR/statusline-command.sh"' "clean install should include statusline"
assert_jq "$CLEAN/.claude/settings.json" '.autoCompactWindow == 300000' "clean install should set the compaction window"
assert_jq "$CLEAN/.claude/settings.json" 'has("env") | not' "clean install should not ship the legacy env"
assert_file "$CLEAN/.claude/skills/integration-card/SKILL.md"
grep -q "Execution gate" "$CLEAN/.claude/skills/integration-card/SKILL.md" || { echo "FAIL: integration card must define the execution gate" >&2; exit 1; }
grep -q "docs/integrations/<service>.md" "$CLEAN/CLAUDE.md" || { echo "FAIL: CLAUDE.md must point to integration cards" >&2; exit 1; }
assert_no_file "$CLEAN/payload/.DS_Store"
if find "$CLEAN" -name .DS_Store -print | grep -q .; then
  echo "FAIL: .DS_Store copied into target" >&2
  exit 1
fi
if grep -q '.DS_Store' "$CLEAN/harness/.manifest"; then
  echo "FAIL: .DS_Store recorded in manifest" >&2
  exit 1
fi

echo "[integration] update idempotence"
bash "$ROOT/install.sh" "$CLEAN" --update >/dev/null
snapshot_tree "$CLEAN" > "$TMP_ROOT/snap1"
bash "$ROOT/install.sh" "$CLEAN" --update >/dev/null
snapshot_tree "$CLEAN" > "$TMP_ROOT/snap2"
diff -u "$TMP_ROOT/snap1" "$TMP_ROOT/snap2"

echo "[integration] settings merge preserves local state"
SETTINGS="$TMP_ROOT/settings"
mkdir -p "$SETTINGS/.claude"
cat > "$SETTINGS/.claude/settings.json" <<'JSON'
{
  "permissions": {"deny": ["WebFetch"]},
  "env": {"CUSTOM_ENV": "kept", "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"},
  "hooks": {
    "Stop": [
      {"hooks": [
        {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/old-quality-gates.sh"},
        {"type": "command", "command": "$CLAUDE_PROJECT_DIR/local-stop.sh"}
      ]}
    ],
    "PreToolUse": [
      {"hooks": [{"type": "command", "command": "$CLAUDE_PROJECT_DIR/pre.sh"}]}
    ]
  }
}
JSON
install_into "$SETTINGS" --update >/dev/null
assert_jq "$SETTINGS/.claude/settings.json" '.permissions.deny[0] == "WebFetch"' "permissions should be preserved"
assert_jq "$SETTINGS/.claude/settings.json" '.env.CUSTOM_ENV == "kept"' "local env should be preserved"
assert_jq "$SETTINGS/.claude/settings.json" '.env | has("CLAUDE_AUTOCOMPACT_PCT_OVERRIDE") | not' "legacy harness env value should be removed"
assert_jq "$SETTINGS/.claude/settings.json" '.autoCompactWindow == 300000' "compaction window should be added when absent"

echo "[integration] compaction settings respect local choices"
for local_json in '{"autoCompactWindow": 500000}' '{"autoCompactWindow": "auto"}' '{"env": {"CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "70"}}' '{"env": {"CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"}}'; do
  LOCAL="$TMP_ROOT/compact-$RANDOM"
  mkdir -p "$LOCAL/.claude"
  printf '%s\n' "$local_json" > "$LOCAL/.claude/settings.json"
  install_into "$LOCAL" --update >/dev/null 2>&1
  install_into "$LOCAL" --update >/dev/null 2>&1
  expected_window="$(printf '%s' "$local_json" | jq '.autoCompactWindow // 300000')"
  assert_jq "$LOCAL/.claude/settings.json" ".autoCompactWindow == $expected_window" "local compaction window should win: $local_json"
  case "$local_json" in
    *'"70"'*) assert_jq "$LOCAL/.claude/settings.json" '.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE == "70"' "non-harness env value should be kept" ;;
    *'"80"'*) assert_jq "$LOCAL/.claude/settings.json" 'has("env") | not' "empty env should be dropped after legacy removal" ;;
  esac
done
assert_jq "$SETTINGS/.claude/settings.json" '.statusLine.command == "$CLAUDE_PROJECT_DIR/statusline-command.sh"' "statusline should be added when absent"
assert_jq "$SETTINGS/.claude/settings.json" '[.hooks.Stop[]?.hooks[]?.command] | map(select(. == "$CLAUDE_PROJECT_DIR/.claude/hooks/check-quality-gates.sh")) | length == 1' "harness hook should appear once"
assert_jq "$SETTINGS/.claude/settings.json" '[.hooks.Stop[]?.hooks[]?.command] | index("$CLAUDE_PROJECT_DIR/.claude/hooks/old-quality-gates.sh") == null' "legacy harness hook should be removed"
assert_jq "$SETTINGS/.claude/settings.json" '[.hooks.Stop[]?.hooks[]?.command] | index("$CLAUDE_PROJECT_DIR/local-stop.sh") != null' "non-harness Stop hook should be preserved"
assert_jq "$SETTINGS/.claude/settings.json" '[.hooks.PreToolUse[]?.hooks[]?.command] | index("$CLAUDE_PROJECT_DIR/pre.sh") != null' "unrelated hook event should be preserved"

echo "[integration] docs merge and quality-gates preservation"
DOCS="$TMP_ROOT/docs"
install_into "$DOCS" >/dev/null
cat > "$DOCS/CLAUDE.md" <<'MD'
# Custom
<!-- harness-builder:local-scope:start -->
**Exceptions (read-only):** /tmp/reference
<!-- harness-builder:local-scope:end -->
MD
cat > "$DOCS/AGENTS.md" <<'MD'
# Legacy
**Exceptions (read-only):** /tmp/legacy-reference
MD
cat > "$DOCS/.claude/quality-gates.json" <<'JSON'
{"lint":"custom lint","test":"","build":"","design":"","gates":{"lint_on_stop":false,"test_on_stop":false,"build_on_stop":false,"design_on_stop":false}}
JSON
bash "$ROOT/install.sh" "$DOCS" --update >/dev/null
grep -Fq '/tmp/reference' "$DOCS/CLAUDE.md"
grep -Fq '/tmp/legacy-reference' "$DOCS/AGENTS.md"
find "$DOCS/harness/backups" -type f | grep -q 'AGENTS.md'
assert_jq "$DOCS/.claude/quality-gates.json" '.lint == "custom lint"' "quality-gates should be project-owned"

echo "[integration] quality gate hook behavior"
cat > "$DOCS/.claude/quality-gates.json" <<'JSON'
{"lint":"","test":"exit 7","build":"","design":"","gates":{"lint_on_stop":true,"test_on_stop":true,"build_on_stop":false,"design_on_stop":false,"cache":false}}
JSON
gate_out="$(cd "$DOCS" && printf '{}\n' | bash .claude/hooks/check-quality-gates.sh)"
printf '%s\n' "$gate_out" | jq -e '.decision == "block" and (.reason | contains("Quality gate failed: test")) and (.reason | contains("To skip this gate once"))' >/dev/null
active_out="$(cd "$DOCS" && printf '{"stop_hook_active":true}\n' | bash .claude/hooks/check-quality-gates.sh)"
[[ -z "$active_out" ]] || { echo "FAIL: stop_hook_active should exit quietly" >&2; exit 1; }

echo "[integration] stale managed cleanup"
STALE="$TMP_ROOT/stale"
install_into "$STALE" >/dev/null
mkdir -p "$STALE/obsolete"
printf 'old managed\n' > "$STALE/obsolete/old.txt"
printf '%s  %s\n' "$(sha256_of "$STALE/obsolete/old.txt")" "obsolete/old.txt" >> "$STALE/harness/.manifest"
bash "$ROOT/install.sh" "$STALE" --update >/dev/null
assert_no_file "$STALE/obsolete/old.txt"
printf 'old managed\n' > "$STALE/obsolete/kept.txt"
printf '%s  %s\n' "$(sha256_of "$STALE/obsolete/kept.txt")" "obsolete/kept.txt" >> "$STALE/harness/.manifest"
printf 'local edit\n' > "$STALE/obsolete/kept.txt"
bash "$ROOT/install.sh" "$STALE" --update >/dev/null
assert_file "$STALE/obsolete/kept.txt"

echo "[integration] dry run does not change files"
snapshot_tree "$STALE" > "$TMP_ROOT/dry-before"
bash "$ROOT/install.sh" "$STALE" --update --dry-run >/dev/null
snapshot_tree "$STALE" > "$TMP_ROOT/dry-after"
diff -u "$TMP_ROOT/dry-before" "$TMP_ROOT/dry-after"

echo "[integration] gate cache"
CACHE="$TMP_ROOT/cache"
install_into "$CACHE" >/dev/null
(cd "$CACHE" && git init -q && git config user.email a@example.com && git config user.name a && git add . && git commit -qm init)
cat > "$CACHE/.claude/quality-gates.json" <<'JSON'
{"lint":"","test":"n=$(cat .claude/count 2>/dev/null || echo 0); n=$((n+1)); echo $n > .claude/count","build":"","design":"","gates":{"lint_on_stop":true,"test_on_stop":true,"build_on_stop":false,"design_on_stop":false,"cache":true}}
JSON
(cd "$CACHE" && printf '{}\n' | bash .claude/hooks/check-quality-gates.sh)
[[ "$(cat "$CACHE/.claude/count")" == "1" ]] || { echo "FAIL: first cached gate run should execute" >&2; exit 1; }
(cd "$CACHE" && printf '{}\n' | bash .claude/hooks/check-quality-gates.sh)
[[ "$(cat "$CACHE/.claude/count")" == "1" ]] || { echo "FAIL: second cached gate run should skip" >&2; exit 1; }
printf 'changed\n' > "$CACHE/changed.txt"
(cd "$CACHE" && printf '{}\n' | bash .claude/hooks/check-quality-gates.sh)
[[ "$(cat "$CACHE/.claude/count")" == "2" ]] || { echo "FAIL: changed tree should invalidate cache" >&2; exit 1; }

echo "[integration] changed scanner"
SCAN="$TMP_ROOT/scan"
mkdir "$SCAN"
(cd "$SCAN" && git init -q && git config user.email a@example.com && git config user.name a &&
  printf '.a{border-radius:24px}\n' > committed.css &&
  git add committed.css && git commit -qm init &&
  printf '.b{border-radius:24px}\n' > changed.css)
changed_scan="$(cd "$SCAN" && bash "$ROOT/payload/.claude/hooks/design-slop-scan.sh" --changed .)"
printf '%s\n' "$changed_scan" | grep -q 'changed.css'
if printf '%s\n' "$changed_scan" | grep -q 'committed.css'; then
  echo "FAIL: --changed scanned untouched committed file" >&2
  exit 1
fi

echo "[integration] ok"
