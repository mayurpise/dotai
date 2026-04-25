#!/usr/bin/env bash
# Installs the scrub skill and/or project config files for supported AI coding tools.
# CLAUDE.md is the single source of truth; config files are generated at install time.
#
# Usage:
#   ./install.sh                        # install skill for all detected tools
#   ./install.sh --cursor               # skill for Cursor only
#   ./install.sh --claude               # skill for Claude Code only
#   ./install.sh --copilot              # skill for GitHub Copilot only
#   ./install.sh --all                  # skill for all tools (explicit)
#   ./install.sh --config [dir]         # generate + copy config files into [dir] (default: .)
#   ./install.sh --all --config .       # skill + all configs into current dir
#   ./install.sh --cursor --config ~/p  # Cursor skill + Cursor config into ~/p

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/scrub.md"
CLAUDE_SRC="$SCRIPT_DIR/CLAUDE.md"
SKILL_NAME="scrub"
SKILL_FILE="SKILL.md"

# Global skill install paths
CURSOR_SKILL="$HOME/.cursor/skills/$SKILL_NAME/$SKILL_FILE"
CLAUDE_SKILL="$HOME/.claude/skills/$SKILL_NAME/$SKILL_FILE"
COPILOT_SKILL="$HOME/.github-copilot/skills/$SKILL_NAME/$SKILL_FILE"

install_skill() {
  local dest="$1" tool="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$SKILL_SRC" "$dest"
  echo "  ✓ skill  $tool → $dest"
}

# Generate config files from CLAUDE.md at install time
install_config() {
  local dir="$1" tools="$2"

  if [[ "$tools" == *"claude"* ]]; then
    cp "$CLAUDE_SRC" "$dir/CLAUDE.md"
    echo "  ✓ config Claude Code → $dir/CLAUDE.md"
  fi

  if [[ "$tools" == *"agents"* ]]; then
    # AGENTS.md is identical to CLAUDE.md (open cross-tool standard)
    cp "$CLAUDE_SRC" "$dir/AGENTS.md"
    echo "  ✓ config AGENTS.md  → $dir/AGENTS.md"
  fi

  if [[ "$tools" == *"cursor"* ]]; then
    local dest="$dir/.cursor/rules/project.mdc"
    mkdir -p "$(dirname "$dest")"
    # Prepend Cursor YAML frontmatter, then append CLAUDE.md content
    { printf -- '---\ndescription: Project-level coding and agent guidelines\nalwaysApply: true\n---\n\n'
      cat "$CLAUDE_SRC"
    } > "$dest"
    echo "  ✓ config Cursor     → $dest"
  fi

  if [[ "$tools" == *"copilot"* ]]; then
    local dest="$dir/.github/copilot-instructions.md"
    mkdir -p "$(dirname "$dest")"
    cp "$CLAUDE_SRC" "$dest"
    echo "  ✓ config Copilot    → $dest"
  fi
}

detect_and_install_skills() {
  local installed=0
  [[ -d "$HOME/.cursor" ]]         && { install_skill "$CURSOR_SKILL"  "Cursor";         installed=1; }
  [[ -d "$HOME/.claude" ]]         && { install_skill "$CLAUDE_SKILL"  "Claude Code";    installed=1; }
  [[ -d "$HOME/.github-copilot" ]] && { install_skill "$COPILOT_SKILL" "GitHub Copilot"; installed=1; }
  if [[ $installed -eq 0 ]]; then
    echo "No supported tools detected. Use --cursor, --claude, or --copilot to install explicitly."
    exit 1
  fi
}

# --- parse args ---
do_cursor=0; do_claude=0; do_copilot=0; do_all=0
do_config=0; config_dir="$(pwd)"

if [[ $# -eq 0 ]]; then
  echo "Installing scrub skill for detected tools..."
  detect_and_install_skills
  exit 0
fi

i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  case "$arg" in
    --cursor)  do_cursor=1 ;;
    --claude)  do_claude=1 ;;
    --copilot) do_copilot=1 ;;
    --all)     do_all=1 ;;
    --config)
      do_config=1
      next=$(( i + 1 ))
      if [[ $next -le $# && "${!next}" != --* ]]; then
        config_dir="${!next}"
        i=$next
      fi
      ;;
    *)
      echo "Unknown flag: $arg"
      echo "Usage: ./install.sh [--cursor] [--claude] [--copilot] [--all] [--config [dir]]"
      exit 1
      ;;
  esac
  i=$(( i + 1 ))
done

# install skills
if [[ $do_all -eq 1 ]]; then
  install_skill "$CURSOR_SKILL"  "Cursor"
  install_skill "$CLAUDE_SKILL"  "Claude Code"
  install_skill "$COPILOT_SKILL" "GitHub Copilot"
else
  [[ $do_cursor  -eq 1 ]] && install_skill "$CURSOR_SKILL"  "Cursor"
  [[ $do_claude  -eq 1 ]] && install_skill "$CLAUDE_SKILL"  "Claude Code"
  [[ $do_copilot -eq 1 ]] && install_skill "$COPILOT_SKILL" "GitHub Copilot"
fi

# generate + install config files
if [[ $do_config -eq 1 ]]; then
  # default: all tools; narrow if specific tool flags were given
  config_tools="claude,agents,cursor,copilot"
  if [[ $do_all -eq 0 && $(( do_cursor + do_claude + do_copilot )) -gt 0 ]]; then
    config_tools=""
    [[ $do_claude  -eq 1 ]] && config_tools+="claude,agents,"
    [[ $do_cursor  -eq 1 ]] && config_tools+="cursor,"
    [[ $do_copilot -eq 1 ]] && config_tools+="copilot,"
  fi
  echo "Generating config files in $config_dir ..."
  mkdir -p "$config_dir"
  install_config "$config_dir" "$config_tools"
fi
