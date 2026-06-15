#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REPO="${HB_REPO:-persson86/harness-builder}"
REF="${HB_REF:-main}"
INSTALL_META="harness/.install.json"

if [[ -f "$INSTALL_META" ]] && command -v jq >/dev/null 2>&1; then
  saved_repo="$(jq -r '.repo // empty' "$INSTALL_META" 2>/dev/null || printf '')"
  saved_ref="$(jq -r '.ref // empty' "$INSTALL_META" 2>/dev/null || printf '')"
  REPO="${HB_REPO:-${saved_repo:-$REPO}}"
  REF="${HB_REF:-${saved_ref:-$REF}}"
fi

if [[ -n "${HB_INSTALLER:-}" ]]; then
  echo "Updating harness-builder using local installer: $HB_INSTALLER" >&2
  bash "$HB_INSTALLER" "$ROOT" --update
else
  command -v curl >/dev/null 2>&1 || { echo "error: curl is required to update harness-builder." >&2; exit 1; }
  URL="https://raw.githubusercontent.com/$REPO/$REF/install.sh"
  echo "Updating harness-builder from $URL" >&2
  curl -fsSL "$URL" | bash -s -- "$ROOT" --update
fi

bash harness/scripts/verify.sh
