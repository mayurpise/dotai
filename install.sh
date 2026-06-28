#!/usr/bin/env bash
# Installs the dotai skills and/or project config files for supported AI coding tools.
# CLAUDE.md is the single source of truth; config files are generated at install time.
# Skills live under skills/<name>/SKILL.md and are installed to each tool's skills dir.
#
# Usage:
#   ./install.sh                        # skills for detected tools
#   ./install.sh --cursor               # skills for Cursor only
#   ./install.sh --claude               # skills for Claude Code only
#   ./install.sh --copilot              # skills for GitHub Copilot only
#   ./install.sh --all                  # skills for all three tools (forced, no detection)
#   ./install.sh --config               # skills + global config for detected tools
#   ./install.sh --config <dir>         # config into a project dir ONLY (no global skills)
#   ./install.sh --all --config         # skills + global config for all three tools
#   ./install.sh -h | --help            # show usage
#
# Safety: an existing destination is backed up to <file>.bak before it is replaced;
# files that are already identical are left untouched.
#
# Global config destinations (no dir given):
#   Claude Code  → ~/.claude/CLAUDE.md
#   Cursor       → ~/.cursor/rules/project.mdc
#   Copilot      → project-level only; supply a dir
#   AGENTS.md    → project-level only; supply a dir
#
# NOTE: "skills" (SKILL.md) are primarily a Claude Code construct. The Cursor and
# Copilot skill dirs are best-effort; verify those tools actually consume SKILL.md
# before relying on them. The Cursor global rules path below is likewise best-effort.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
CLAUDE_SRC="$SCRIPT_DIR/CLAUDE.md"
SKILL_FILE="SKILL.md"

# Per-tool skills install roots
CURSOR_SKILLS_ROOT="$HOME/.cursor/skills"
CLAUDE_SKILLS_ROOT="$HOME/.claude/skills"
COPILOT_SKILLS_ROOT="$HOME/.github-copilot/skills"

# Global config install paths
CURSOR_CONFIG="$HOME/.cursor/rules/project.mdc"
CLAUDE_CONFIG="$HOME/.claude/CLAUDE.md"

CURSOR_FRONTMATTER='---\ndescription: Project-level coding and agent guidelines\nalwaysApply: true\n---\n\n'

print_usage() {
  sed -n '6,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Membership test: has <needle> <list...>
has() {
  local needle="$1"; shift
  local x
  for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
  return 1
}

# Back up an existing file to <file>.bak so an overwrite is recoverable.
backup_if_exists() {
  if [[ -f "$1" ]]; then
    cp "$1" "$1.bak"
    echo "    ↳ backed up existing → $1.bak"
  fi
  return 0
}

# Copy src→dest idempotently: skip if identical, back up before replacing.
# Portable same-file/same-content handling via cmp (no realpath dependency).
install_file() {
  local src="$1" dest="$2" label="$3"
  if cmp -s "$src" "$dest" 2>/dev/null; then
    echo "  = $label unchanged → $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  backup_if_exists "$dest"
  cp "$src" "$dest"
  echo "  ✓ $label → $dest"
}

# Generate the Cursor config (frontmatter + CLAUDE.md) and install it via install_file.
install_cursor_config() {
  local dest="$1"
  local tmp; tmp="$(mktemp)"
  { printf -- "$CURSOR_FRONTMATTER"; cat "$CLAUDE_SRC"; } > "$tmp"
  install_file "$tmp" "$dest" "config Cursor"
  rm -f "$tmp"
}

install_skills_to_root() {
  local dest_root="$1" tool="$2"
  shopt -s nullglob
  local installed_any=0
  for skill_dir in "$SKILLS_DIR"/*/; do
    local name src dest
    name="$(basename "$skill_dir")"
    src="$skill_dir$SKILL_FILE"
    [[ -f "$src" ]] || continue
    dest="$dest_root/$name/$SKILL_FILE"
    install_file "$src" "$dest" "skill  $tool/$name"
    installed_any=1
  done
  shopt -u nullglob
  [[ $installed_any -eq 0 ]] && echo "  ! no skills found under $SKILLS_DIR"
  return 0
}

# Install config to each targeted tool's global home dir.
install_config_global() {
  if has claude "$@"; then
    install_file "$CLAUDE_SRC" "$CLAUDE_CONFIG" "config Claude Code"
  fi
  if has cursor "$@"; then
    install_cursor_config "$CURSOR_CONFIG"
  fi
  if has copilot "$@"; then
    echo "  ! config Copilot    → project-level only; use --config <dir>"
  fi
}

# Install config into a specific project directory for each targeted tool.
install_config_project() {
  local dir="$1"; shift
  mkdir -p "$dir"
  if has claude "$@"; then
    install_file "$CLAUDE_SRC" "$dir/CLAUDE.md"  "config Claude Code"
    install_file "$CLAUDE_SRC" "$dir/AGENTS.md" "config AGENTS.md"
  fi
  if has cursor "$@"; then
    install_cursor_config "$dir/.cursor/rules/project.mdc"
  fi
  if has copilot "$@"; then
    install_file "$CLAUDE_SRC" "$dir/.github/copilot-instructions.md" "config Copilot"
  fi
}

# --- parse args ---
do_cursor=0; do_claude=0; do_copilot=0; do_all=0
do_config=0; config_dir=""

i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  case "$arg" in
    --cursor)  do_cursor=1 ;;
    --claude)  do_claude=1 ;;
    --copilot) do_copilot=1 ;;
    --all)     do_all=1 ;;
    -h|--help) print_usage; exit 0 ;;
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
      print_usage
      exit 1
      ;;
  esac
  i=$(( i + 1 ))
done

# --- resolve target tools (explicit > --all > detection) ---
tools=()
if [[ $do_all -eq 1 ]]; then
  tools=(cursor claude copilot)
elif [[ $(( do_cursor + do_claude + do_copilot )) -gt 0 ]]; then
  [[ $do_cursor  -eq 1 ]] && tools+=(cursor)
  [[ $do_claude  -eq 1 ]] && tools+=(claude)
  [[ $do_copilot -eq 1 ]] && tools+=(copilot)
else
  [[ -d "$HOME/.cursor" ]]         && tools+=(cursor)
  [[ -d "$HOME/.claude" ]]         && tools+=(claude)
  [[ -d "$HOME/.github-copilot" ]] && tools+=(copilot)
fi

if [[ ${#tools[@]} -eq 0 ]]; then
  echo "No supported tools detected. Use --cursor, --claude, --copilot, or --all to install explicitly."
  exit 1
fi

# --- install skills (global-only; skipped entirely in project-config mode) ---
if [[ -n "$config_dir" ]]; then
  echo "Project-config mode: skipping global skill install (skills are global-only; run without <dir> to install them)."
else
  echo "Installing skills for: ${tools[*]}"
  for tool in "${tools[@]}"; do
    case "$tool" in
      cursor)  install_skills_to_root "$CURSOR_SKILLS_ROOT"  "Cursor" ;;
      claude)  install_skills_to_root "$CLAUDE_SKILLS_ROOT"  "Claude Code" ;;
      copilot) install_skills_to_root "$COPILOT_SKILLS_ROOT" "GitHub Copilot" ;;
    esac
  done
fi

# --- install config ---
if [[ $do_config -eq 1 ]]; then
  if [[ -n "$config_dir" ]]; then
    echo "Installing config into $config_dir for: ${tools[*]}"
    install_config_project "$config_dir" "${tools[@]}"
  else
    echo "Installing global config for: ${tools[*]}"
    install_config_global "${tools[@]}"
  fi
fi
