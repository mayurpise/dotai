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
#   ./install.sh --config               # install config to each tool's global home dir
#   ./install.sh --config <dir>         # install config into a specific project dir
#   ./install.sh --all --config         # skill + config, both to global tool dirs
#
# Global config destinations (no dir given):
#   Claude Code  → ~/.claude/CLAUDE.md
#   Cursor       → ~/.cursor/rules/project.mdc
#   Copilot      → project-level only; supply a dir
#   AGENTS.md    → project-level only; supply a dir

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

# Global config install paths
CURSOR_CONFIG="$HOME/.cursor/rules/project.mdc"
CLAUDE_CONFIG="$HOME/.claude/CLAUDE.md"

install_skill() {
  local dest="$1" tool="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$SKILL_SRC" "$dest"
  echo "  ✓ skill  $tool → $dest"
}

# Install config to each tool's global home dir
install_config_global() {
  local tools="$1"

  if [[ "$tools" == *"claude"* ]]; then
    mkdir -p "$(dirname "$CLAUDE_CONFIG")"
    cp "$CLAUDE_SRC" "$CLAUDE_CONFIG"
    echo "  ✓ config Claude Code → $CLAUDE_CONFIG"
  fi

  if [[ "$tools" == *"cursor"* ]]; then
    mkdir -p "$(dirname "$CURSOR_CONFIG")"
    { printf -- '---\ndescription: Project-level coding and agent guidelines\nalwaysApply: true\n---\n\n'
      cat "$CLAUDE_SRC"
    } > "$CURSOR_CONFIG"
    echo "  ✓ config Cursor     → $CURSOR_CONFIG"
  fi

  if [[ "$tools" == *"copilot"* ]]; then
    echo "  ! config Copilot    → project-level only; use --config <dir>"
  fi
}

# Install config into a specific project directory
install_config_project() {
  local dir="$1" tools="$2"
  mkdir -p "$dir"

  if [[ "$tools" == *"claude"* ]]; then
    local dest="$dir/CLAUDE.md"
    [[ "$(realpath "$CLAUDE_SRC")" == "$(realpath "$dest" 2>/dev/null || echo "")" ]] \
      && echo "  ! config Claude Code → skipped (same file)" \
      || { cp "$CLAUDE_SRC" "$dest"; echo "  ✓ config Claude Code → $dest"; }
  fi

  if [[ "$tools" == *"agents"* ]]; then
    cp "$CLAUDE_SRC" "$dir/AGENTS.md"
    echo "  ✓ config AGENTS.md  → $dir/AGENTS.md"
  fi

  if [[ "$tools" == *"cursor"* ]]; then
    local dest="$dir/.cursor/rules/project.mdc"
    mkdir -p "$(dirname "$dest")"
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
do_config=0; config_dir=""

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

# resolve which tools are in scope
if [[ $do_all -eq 1 || $(( do_cursor + do_claude + do_copilot )) -eq 0 ]]; then
  skill_tools="cursor claude copilot"
  config_tools="claude,agents,cursor,copilot"
else
  skill_tools=""
  config_tools=""
  [[ $do_cursor  -eq 1 ]] && { skill_tools+=" cursor";  config_tools+="cursor,"; }
  [[ $do_claude  -eq 1 ]] && { skill_tools+=" claude";  config_tools+="claude,agents,"; }
  [[ $do_copilot -eq 1 ]] && { skill_tools+=" copilot"; config_tools+="copilot,"; }
fi

# install skills
for tool in $skill_tools; do
  case "$tool" in
    cursor)  install_skill "$CURSOR_SKILL"  "Cursor" ;;
    claude)  install_skill "$CLAUDE_SKILL"  "Claude Code" ;;
    copilot) install_skill "$COPILOT_SKILL" "GitHub Copilot" ;;
  esac
done

# install config
if [[ $do_config -eq 1 ]]; then
  if [[ -n "$config_dir" ]]; then
    echo "Installing config files into $config_dir ..."
    install_config_project "$config_dir" "$config_tools"
  else
    echo "Installing config files to global tool dirs..."
    install_config_global "$config_tools"
  fi
fi
