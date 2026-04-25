#!/usr/bin/env bash
# Installs scrub.md as scrub/SKILL.md for supported AI coding tools.
# Usage: ./install.sh [--cursor] [--claude] [--copilot] [--all]
#        With no flags, installs for all detected tools.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/scrub.md"
SKILL_NAME="scrub"
SKILL_FILE="SKILL.md"

# Tool install paths
CURSOR_DEST="$HOME/.cursor/skills/$SKILL_NAME/$SKILL_FILE"
CLAUDE_DEST="$HOME/.claude/skills/$SKILL_NAME/$SKILL_FILE"
COPILOT_DEST="$HOME/.github-copilot/skills/$SKILL_NAME/$SKILL_FILE"

install_skill() {
  local dest="$1"
  local tool="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$SKILL_SRC" "$dest"
  echo "  ✓ $tool → $dest"
}

detect_and_install() {
  local installed=0

  if [[ -d "$HOME/.cursor" ]]; then
    install_skill "$CURSOR_DEST" "Cursor"
    installed=1
  fi

  if [[ -d "$HOME/.claude" ]]; then
    install_skill "$CLAUDE_DEST" "Claude Code"
    installed=1
  fi

  if [[ -d "$HOME/.github-copilot" ]]; then
    install_skill "$COPILOT_DEST" "GitHub Copilot"
    installed=1
  fi

  if [[ $installed -eq 0 ]]; then
    echo "No supported tools detected. Use --cursor, --claude, or --copilot to install explicitly."
    exit 1
  fi
}

if [[ $# -eq 0 ]]; then
  echo "Installing scrub skill for detected tools..."
  detect_and_install
  exit 0
fi

for arg in "$@"; do
  case "$arg" in
    --cursor)  install_skill "$CURSOR_DEST"  "Cursor" ;;
    --claude)  install_skill "$CLAUDE_DEST"  "Claude Code" ;;
    --copilot) install_skill "$COPILOT_DEST" "GitHub Copilot" ;;
    --all)
      install_skill "$CURSOR_DEST"  "Cursor"
      install_skill "$CLAUDE_DEST"  "Claude Code"
      install_skill "$COPILOT_DEST" "GitHub Copilot"
      ;;
    *)
      echo "Unknown flag: $arg"
      echo "Usage: ./install.sh [--cursor] [--claude] [--copilot] [--all]"
      exit 1
      ;;
  esac
done
