#!/usr/bin/env bash
#
# harness-builder installer
#
# Installs payload/ into the target project root and records a manifest for
# drift checks. Project-owned config such as .claude/quality-gates.json is
# copied from templates/ only when absent.
#
# Usage:
#   ./install.sh [TARGET_DIR] [--update]
#   curl -fsSL https://raw.githubusercontent.com/persson86/harness-builder/main/install.sh | bash -s -- /path/to/project --update
#
set -euo pipefail

REPO="persson86/harness-builder"
REF="${HB_REF:-main}"
TMP_ROOT=""

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
TEMPLATE_CONFIG="$SRC/templates/project/quality-gates.json"
[[ -d "$PAYLOAD" ]] || { echo "error: payload/ missing from package." >&2; exit 1; }
[[ -f "$TEMPLATE_CONFIG" ]] || { echo "error: templates/project/quality-gates.json missing from package." >&2; exit 1; }

TARGET=""
UPDATE=0
for arg in "$@"; do
  case "$arg" in
    --update|--force) UPDATE=1 ;;
    -h|--help)
      sed -n '1,16p' "$SRC/install.sh"
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
done < <(cd "$PAYLOAD" && find . -type f | sed 's|^\./||' | sort)
[[ "${#PAYLOAD_FILES[@]}" -gt 0 ]] || { echo "error: payload/ is empty." >&2; exit 1; }

if [[ "$UPDATE" -eq 0 ]]; then
  collisions=()
  for rel in "${PAYLOAD_FILES[@]}"; do
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
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "$dest.tmp.XXXXXX")"
  cp "$src" "$tmp"
  mv "$tmp" "$dest"
}

echo "Installing harness-builder v$VERSION into $TARGET" >&2
for rel in "${PAYLOAD_FILES[@]}"; do
  install_one "$rel"
done
echo "  + installed ${#PAYLOAD_FILES[@]} payload files" >&2

chmod +x "$TARGET"/.claude/hooks/*.sh "$TARGET"/harness/scripts/verify.sh "$TARGET"/statusline-command.sh 2>/dev/null || true

if [[ -f "$TARGET/.claude/quality-gates.json" ]]; then
  echo "  = kept existing .claude/quality-gates.json" >&2
else
  mkdir -p "$TARGET/.claude"
  cp "$TEMPLATE_CONFIG" "$TARGET/.claude/quality-gates.json"
  echo "  + copied .claude/quality-gates.json template" >&2
fi

mkdir -p "$TARGET/harness"
MANIFEST="$TARGET/harness/.manifest"
: > "$MANIFEST"
for rel in "${PAYLOAD_FILES[@]}"; do
  printf '%s  %s\n' "$(sha256_of "$TARGET/$rel")" "$rel" >> "$MANIFEST"
done
printf '%s\n' "$VERSION" > "$TARGET/harness/.version"
echo "  + wrote harness/.version and harness/.manifest" >&2

echo "" >&2
echo "Validate with: bash harness/scripts/verify.sh" >&2
