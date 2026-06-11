#!/bin/bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/persson86/harness-builder/main"
DEST="${1:-.}"

files=(
  "CLAUDE.md"
  "AGENTS.md"
  ".claude/settings.example.json"
  "statusline-command.sh"
)

echo "Installing harness-builder into $DEST"

for file in "${files[@]}"; do
  dir="$(dirname "$DEST/$file")"
  mkdir -p "$dir"
  if [ -f "$DEST/$file" ]; then
    echo "  skip  $file (already exists)"
  else
    curl -fsSL "$REPO/$file" -o "$DEST/$file"
    echo "  done  $file"
  fi
done

chmod +x "$DEST/statusline-command.sh" 2>/dev/null || true

echo ""
echo "Next: copy .claude/settings.example.json → .claude/settings.json and adjust paths."
