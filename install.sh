#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/persson86/harness-builder"
DEST="${1:-.}"
REPO_DIR="$DEST/projects/harness-builder"

echo "Installing harness-builder workspace into $DEST"

# 1. Clone the full repo into projects/ (versioned copy; serves as backup)
if [ -d "$REPO_DIR/.git" ]; then
  echo "  skip  projects/harness-builder (already cloned)"
else
  mkdir -p "$DEST/projects"
  git clone --quiet "$REPO_URL" "$REPO_DIR"
  echo "  done  projects/harness-builder (cloned)"
fi

# 2. Symlink files kept in sync with the repo
links=(
  "AGENTS.md"
  "statusline-command.sh"
  ".claude/settings.example.json"
)

for file in "${links[@]}"; do
  if [ -e "$DEST/$file" ] && [ ! -L "$DEST/$file" ]; then
    echo "  skip  $file (already exists)"
    continue
  fi
  mkdir -p "$(dirname "$DEST/$file")"
  case "$file" in
    */*) ln -sf "../projects/harness-builder/$file" "$DEST/$file" ;;
    *)   ln -sf "projects/harness-builder/$file" "$DEST/$file" ;;
  esac
  echo "  link  $file"
done

# 3. Copy files meant to be customized locally
if [ -f "$DEST/CLAUDE.md" ]; then
  echo "  skip  CLAUDE.md (already exists)"
else
  cp "$REPO_DIR/CLAUDE.md" "$DEST/CLAUDE.md"
  echo "  copy  CLAUDE.md"
fi

if [ -d "$DEST/design" ]; then
  echo "  skip  design/ (already exists)"
else
  cp -R "$REPO_DIR/design" "$DEST/design"
  echo "  copy  design/"
fi

echo ""
echo "Next: copy .claude/settings.example.json → .claude/settings.json and adjust paths."
