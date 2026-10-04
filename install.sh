#!/usr/bin/env bash
#
# harness-builder installer
#
# Installs payload/ into the target project root and records a manifest for
# drift checks. Project-owned config such as .claude/settings.json and
# .claude/quality-gates.json is merged or copied without overwriting local
# settings.
#
# Usage:
#   ./install.sh [TARGET_DIR] [--update] [--dry-run]
#   curl -fsSL https://raw.githubusercontent.com/persson86/harness-builder/main/install.sh | bash -s -- /path/to/project --update
#
set -euo pipefail

REPO="${HB_REPO:-persson86/harness-builder}"
REF="${HB_REF:-main}"
TMP_ROOT=""
DRY_RUN=0

cleanup() {
  [[ -n "$TMP_ROOT" ]] && rm -rf "$TMP_ROOT" || true
}
trap cleanup EXIT

download_url() {
  local url="$1" label="$2" attempt=1 max_attempts=5 status=0
  while [[ "$attempt" -le "$max_attempts" ]]; do
    if curl -fsSL --connect-timeout 10 --max-time 60 "$url"; then
      return 0
    else
      status=$?
    fi
    if [[ "$attempt" -lt "$max_attempts" ]]; then
      echo "warning: failed to download $label (attempt $attempt/$max_attempts); retrying..." >&2
      sleep 1
    fi
    attempt=$((attempt + 1))
  done
  echo "error: failed to download $label from $url" >&2
  return "$status"
}

SRC=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
fi

if [[ -n "$SRC" && -d "$SRC/payload" ]]; then
  VERSION="$(tr -d '[:space:]' < "$SRC/VERSION" 2>/dev/null || echo "unknown")"
else
  command -v curl >/dev/null 2>&1 || { echo "error: curl is required for remote install." >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || { echo "error: tar is required for remote install." >&2; exit 1; }
  TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/harness-builder-install.XXXXXX")"
  ARCHIVE="$TMP_ROOT/hb.tar.gz"
  ARCHIVE_URL="https://codeload.github.com/$REPO/tar.gz/$REF"
  echo "Downloading harness-builder ($REF)..." >&2
  download_url "$ARCHIVE_URL" "harness-builder archive ($REF)" > "$ARCHIVE" || exit 1
  tar -xzf "$ARCHIVE" -C "$TMP_ROOT" || { echo "error: failed to extract archive." >&2; exit 1; }
  PKG_DIRS=("$TMP_ROOT"/harness-builder-*)
  [[ -d "${PKG_DIRS[0]}" ]] || { echo "error: archive did not contain harness-builder." >&2; exit 1; }
  SRC="${PKG_DIRS[0]}"
  VERSION="$(tr -d '[:space:]' < "$SRC/VERSION" 2>/dev/null || echo "unknown")"
fi

PAYLOAD="$SRC/payload"
SETTINGS_TEMPLATE="$PAYLOAD/.claude/settings.json"
TEMPLATE_CONFIG="$SRC/templates/project/quality-gates.json"
[[ -d "$PAYLOAD" ]] || { echo "error: payload/ missing from package." >&2; exit 1; }
[[ -f "$SETTINGS_TEMPLATE" ]] || { echo "error: payload/.claude/settings.json missing from package." >&2; exit 1; }
[[ -f "$TEMPLATE_CONFIG" ]] || { echo "error: templates/project/quality-gates.json missing from package." >&2; exit 1; }

print_help() {
  cat <<'EOF'
harness-builder installer

Usage:
  ./install.sh [TARGET_DIR] [--update] [--dry-run]
  ./install.sh [TARGET_DIR] --force

Flags:
  --update     Update an existing install, preserving project-owned config.
  --force      Alias for --update.
  --dry-run    Print planned copy/merge/stale actions without writing files.
  -h, --help   Show this help.

Environment:
  HB_REPO       GitHub repo for remote installs, default persson86/harness-builder.
  HB_REF        Git ref for remote installs, default main.
  HB_INSTALLER  Local installer path used by harness/scripts/update.sh.
EOF
}

TARGET=""
UPDATE=0
for arg in "$@"; do
  case "$arg" in
    --update|--force) UPDATE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      print_help
      exit 0
      ;;
    -*) echo "error: unknown flag: $arg" >&2; exit 2 ;;
    *) TARGET="$arg" ;;
  esac
done
TARGET="${TARGET:-.}"
[[ -d "$TARGET" ]] || { echo "error: target is not a directory: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
[[ "$TARGET" != "$SRC" ]] || { echo "error: target is the source package; choose a project directory." >&2; exit 1; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

PAYLOAD_FILES=()
while IFS= read -r file; do
  PAYLOAD_FILES+=("$file")
done < <(cd "$PAYLOAD" && find . -type f ! -name '.DS_Store' ! -name '*.tmp.*' | sed 's|^\./||' | sort)
[[ "${#PAYLOAD_FILES[@]}" -gt 0 ]] || { echo "error: payload/ is empty." >&2; exit 1; }

INSTALL_FILES=()
COPY_FILES=()
for rel in "${PAYLOAD_FILES[@]}"; do
  case "$rel" in
    .claude/settings.json) ;;
    CLAUDE.md|AGENTS.md)
      INSTALL_FILES+=("$rel")
      ;;
    *)
      INSTALL_FILES+=("$rel")
      COPY_FILES+=("$rel")
      ;;
  esac
done

if [[ "$UPDATE" -eq 0 ]]; then
  collisions=()
  for rel in "${INSTALL_FILES[@]}"; do
    [[ -e "$TARGET/$rel" ]] && collisions+=("$rel")
  done
  if [[ "${#collisions[@]}" -gt 0 ]]; then
    echo "error: target already has harness files (use --update to overwrite):" >&2
    printf '  %s\n' "${collisions[@]}" >&2
    exit 1
  fi
fi

install_one() {
  local rel="$1" src="$PAYLOAD/$1" dest="$TARGET/$1" tmp
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -e "$dest" ]]; then
      echo "  + copy $rel" >&2
    else
      echo "  + copy $rel" >&2
    fi
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "$dest.tmp.XXXXXX")"
  cp "$src" "$tmp"
  mv "$tmp" "$dest"
}

DOC_LOCAL_START="<!-- harness-builder:local-scope:start -->"
DOC_LOCAL_END="<!-- harness-builder:local-scope:end -->"

doc_has_local_block() {
  local file="$1"
  grep -Fqx "$DOC_LOCAL_START" "$file" && grep -Fqx "$DOC_LOCAL_END" "$file"
}

extract_doc_local_block() {
  local file="$1"
  awk -v start="$DOC_LOCAL_START" -v end="$DOC_LOCAL_END" '
    $0 == start { in_block = 1; next }
    $0 == end { exit }
    in_block { print }
  ' "$file"
}

extract_legacy_scope() {
  local file="$1"
  awk '
    /^\*\*Exceptions \(read-only\):\*\*/ { print; found = 1; exit }
    END { exit found ? 0 : 1 }
  ' "$file"
}

write_doc_with_local_block() {
  local template="$1" block_file="$2" out="$3"
  awk -v start="$DOC_LOCAL_START" -v end="$DOC_LOCAL_END" -v block_file="$block_file" '
    $0 == start {
      print
      while ((getline line < block_file) > 0) print line
      close(block_file)
      in_block = 1
      next
    }
    $0 == end {
      in_block = 0
      print
      next
    }
    !in_block { print }
  ' "$template" > "$out"
}

backup_legacy_doc() {
  local rel="$1" dest="$TARGET/$1" stamp backup_dir backup
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_dir="$TARGET/harness/backups/$stamp"
  backup="$backup_dir/$rel"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  ! would back up legacy $rel to ${backup#$TARGET/}" >&2
    return 0
  fi
  mkdir -p "$(dirname "$backup")"
  cp "$dest" "$backup"
  echo "  ! backed up legacy $rel to ${backup#$TARGET/}" >&2
}

prune_backups() {
  local backup_root="$TARGET/harness/backups"
  [[ "$DRY_RUN" -eq 0 ]] || return 0
  [[ -d "$backup_root" ]] || return 0
  find "$backup_root" -mindepth 1 -maxdepth 1 -type d | sort -r | awk 'NR > 5' |
    while IFS= read -r old; do
      rm -rf "$old"
      echo "  - pruned old backup ${old#$TARGET/}" >&2
    done
}

merge_doc() {
  local rel="$1" src="$PAYLOAD/$1" dest="$TARGET/$1" tmp block_tmp
  [[ -f "$src" ]] || { echo "error: payload/$rel missing from package." >&2; exit 1; }
  doc_has_local_block "$src" || {
    echo "error: payload/$rel is missing harness-builder local-scope markers." >&2
    exit 1
  }

  if [[ "$DRY_RUN" -eq 1 ]]; then
    tmp="$(mktemp "${TMPDIR:-/tmp}/harness-builder-doc.XXXXXX")"
  else
    mkdir -p "$(dirname "$dest")"
    tmp="$(mktemp "$dest.tmp.XXXXXX")"
  fi
  block_tmp="$(mktemp "${TMPDIR:-/tmp}/harness-builder-local-block.XXXXXX")"

  if [[ -e "$dest" && ! -f "$dest" ]]; then
    rm -f "$tmp" "$block_tmp"
    echo "error: cannot merge $rel because target exists and is not a regular file: $dest" >&2
    exit 1
  fi

  if [[ -f "$dest" ]]; then
    if doc_has_local_block "$dest"; then
      extract_doc_local_block "$dest" > "$block_tmp"
      write_doc_with_local_block "$src" "$block_tmp" "$tmp"
      echo "  = merged $rel (local scope block preserved)" >&2
    elif extract_legacy_scope "$dest" > "$block_tmp"; then
      backup_legacy_doc "$rel"
      write_doc_with_local_block "$src" "$block_tmp" "$tmp"
      echo "  = merged $rel (legacy read-only exception migrated)" >&2
    else
      backup_legacy_doc "$rel"
      cp "$src" "$tmp"
      echo "  = replaced legacy $rel (backup kept; no local scope block found)" >&2
    fi
  else
    cp "$src" "$tmp"
    if [[ -L "$dest" ]]; then
      echo "  = replaced broken $rel symlink" >&2
    else
      echo "  + copied $rel" >&2
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    rm -f "$tmp"
  else
    mv "$tmp" "$dest"
  fi
  rm -f "$block_tmp"
}

merge_settings() {
  local dest="$TARGET/.claude/settings.json" tmp

  if [[ ! -f "$dest" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "  + copied .claude/settings.json" >&2
      return 0
    fi
    mkdir -p "$TARGET/.claude"
    cp "$SETTINGS_TEMPLATE" "$dest"
    echo "  + copied .claude/settings.json" >&2
    return 0
  fi

  command -v jq >/dev/null 2>&1 || {
    echo "error: jq is required to merge existing .claude/settings.json" >&2
    echo "       install jq or move the settings file aside before updating." >&2
    exit 1
  }

  if [[ "$DRY_RUN" -eq 1 ]]; then
    tmp="$(mktemp "${TMPDIR:-/tmp}/harness-builder-settings.XXXXXX")"
  else
    mkdir -p "$TARGET/.claude"
    tmp="$(mktemp "$dest.tmp.XXXXXX")"
  fi
  managed_hooks_json="$(
    find "$PAYLOAD/.claude/hooks" -maxdepth 1 -type f -name '*.sh' -exec basename {} \; 2>/dev/null |
      awk 'BEGIN{printf "["} {printf "%s\"%s\"", sep, $0; sep=","} END{printf ",\"legacy-quality-gates.sh\",\"old-quality-gates.sh\"]"}'
  )"
  jq -s '
    def is_harness_entry($managed):
      (.command // "") as $cmd |
      ($cmd | test("^\\$CLAUDE_PROJECT_DIR/\\.claude/hooks/")) and
      (($managed | index($cmd | split("/")[-1])) != null);
    def is_harness_entry:
      ((.hooks // []) | any(is_harness_entry($managed)));
    def clean_hooks($hooks):
      ($hooks // {}) | with_entries(
        .value = (
          (.value // [])
          | map(.hooks = ((.hooks // []) | map(select(is_harness_entry($managed) | not))))
          | map(select((.hooks // []) | length > 0))
        )
      );
    def merged_hooks($local; $template):
      clean_hooks($local.hooks) as $local_hooks |
      ($template.hooks // {}) as $template_hooks |
      reduce ($template_hooks | keys_unsorted[]) as $event ($local_hooks;
        .[$event] = ((.[$event] // []) + ($template_hooks[$event] // []))
      );

    .[0] as $local |
    .[1] as $template |
    ($local // {})
    | .env = (($template.env // {}) + (.env // {}))
    # Legacy: harness <= 1.3.0 shipped CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80. It is not in the
    # current Claude Code docs and, as a percentage of a 1M window, would not cap anything.
    # Remove it only when it still holds the value the harness wrote.
    | (if .env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE == "80" then .env |= del(.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE) else . end)
    | (if .env == {} then del(.env) else . end)
    | (if $template.autoCompactWindow != null and .autoCompactWindow == null
       then .autoCompactWindow = $template.autoCompactWindow else . end)
    | .statusLine = (.statusLine // $template.statusLine)
    | .hooks = merged_hooks($local; $template)
  ' --argjson managed "$managed_hooks_json" "$dest" "$SETTINGS_TEMPLATE" > "$tmp" || {
    rm -f "$tmp"
    echo "error: failed to merge .claude/settings.json" >&2
    exit 1
  }
  if [[ "$(jq -r '.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE // empty' "$dest")" == "80" ]]; then
    echo "  - removed legacy env CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80 (now autoCompactWindow)" >&2
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    rm -f "$tmp"
  else
    mv "$tmp" "$dest"
  fi
  echo "  = merged .claude/settings.json (local settings preserved)" >&2
}

array_contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

protected_from_stale_cleanup() {
  case "$1" in
    .claude/settings.json|.claude/quality-gates.json|CLAUDE.md|AGENTS.md) return 0 ;;
    *) return 1 ;;
  esac
}

remove_stale_managed_files() {
  local manifest="$TARGET/harness/.manifest"
  [[ -f "$manifest" ]] || return 0

  local line want rel got
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    want="${line%% *}"
    rel="${line#* }"
    rel="${rel# }"
    protected_from_stale_cleanup "$rel" && continue
    array_contains "$rel" "${INSTALL_FILES[@]}" && continue
    [[ -e "$TARGET/$rel" ]] || continue
    [[ -f "$TARGET/$rel" ]] || { echo "  ! stale but not a regular file, kept: $rel" >&2; continue; }
    got="$(sha256_of "$TARGET/$rel")"
    if [[ "$got" == "$want" ]]; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "  - stale $rel" >&2
      else
        rm -f "$TARGET/$rel"
        echo "  - removed stale $rel" >&2
      fi
    else
      echo "  ! stale but locally modified, kept: $rel" >&2
    fi
  done < "$manifest"
}

print_gate_suggestion() {
  local lint="" test="" kind="" package_scripts

  if [[ -f "$TARGET/package.json" ]] && command -v jq >/dev/null 2>&1; then
    package_scripts="$(jq -r '.scripts // {} | keys[]?' "$TARGET/package.json" 2>/dev/null || printf '')"
    printf '%s\n' "$package_scripts" | grep -Fxq lint && lint="npm run lint"
    printf '%s\n' "$package_scripts" | grep -Fxq test && test="npm test"
    [[ -n "$lint$test" ]] && kind="npm"
  fi

  if [[ -z "$kind" && -f "$TARGET/pyproject.toml" ]]; then
    lint="ruff check ."
    test="pytest"
    kind="python"
  fi

  if [[ -z "$kind" && -f "$TARGET/Makefile" ]]; then
    grep -Eq '^lint:' "$TARGET/Makefile" && lint="make lint"
    grep -Eq '^test:' "$TARGET/Makefile" && test="make test"
    [[ -n "$lint$test" ]] && kind="make"
  fi

  echo "" >&2
  if [[ -n "$kind" ]]; then
    echo "Suggested .claude/quality-gates.json commands (copy manually if correct):" >&2
    printf '{\n  "lint": "%s",\n  "test": "%s"\n}\n' "$lint" "$test" >&2
  else
    echo "Configure .claude/quality-gates.json when this project has lint/test commands; see README.md." >&2
  fi
}

echo "Installing harness-builder v$VERSION into $TARGET" >&2
for rel in "${COPY_FILES[@]}"; do
  install_one "$rel"
done
echo "  + installed ${#COPY_FILES[@]} copied payload files" >&2

merge_doc "CLAUDE.md"
merge_doc "AGENTS.md"

merge_settings

if [[ "$DRY_RUN" -eq 0 ]]; then
  chmod +x "$TARGET"/.claude/hooks/*.sh "$TARGET"/harness/scripts/*.sh "$TARGET"/statusline-command.sh 2>/dev/null || true
fi

if [[ -f "$TARGET/.claude/quality-gates.json" ]]; then
  echo "  = kept existing .claude/quality-gates.json" >&2
else
  if [[ "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$TARGET/.claude"
    cp "$TEMPLATE_CONFIG" "$TARGET/.claude/quality-gates.json"
  fi
  echo "  + copied .claude/quality-gates.json template" >&2
fi

remove_stale_managed_files
prune_backups

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  = would write harness/.version, harness/.install.json and harness/.manifest" >&2
  echo "" >&2
  echo "Dry run only; no files changed." >&2
  exit 0
fi

mkdir -p "$TARGET/harness"
MANIFEST="$TARGET/harness/.manifest"
: > "$MANIFEST"
for rel in "${INSTALL_FILES[@]}"; do
  printf '%s  %s\n' "$(sha256_of "$TARGET/$rel")" "$rel" >> "$MANIFEST"
done
printf '%s\n' "$VERSION" > "$TARGET/harness/.version"
cat > "$TARGET/harness/.install.json" <<JSON
{
  "repo": "$REPO",
  "ref": "$REF",
  "version": "$VERSION"
}
JSON
echo "  + wrote harness/.version, harness/.install.json and harness/.manifest" >&2

echo "" >&2
echo "Validate with: bash harness/scripts/verify.sh" >&2
echo "Next update: bash harness/scripts/update.sh" >&2
print_gate_suggestion
