# dotai

[![GitHub stars](https://img.shields.io/github/stars/mayurpise/dotai?style=flat-square&color=gold)](https://github.com/mayurpise/dotai/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/mayurpise/dotai?style=flat-square)](https://github.com/mayurpise/dotai/network/members)
[![GitHub last commit](https://img.shields.io/github/last-commit/mayurpise/dotai?style=flat-square)](https://github.com/mayurpise/dotai/commits/main)

AI coding tool configs that reduce wasted tokens and prevent scope creep. Works with Claude Code, Cursor, and GitHub Copilot.

## What's included

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project-level agent operating instructions |
| `scrub.md` | `/scrub` skill — structured code review and cleanup |
| `install.sh` | Copies files to the right location for each tool |

## Install

```bash
# Skills + config for all detected tools (recommended)
./install.sh --config
```

That's it. One command installs the `/scrub` skill and copies `CLAUDE.md` to the global config dir of every tool it detects (`~/.claude/`, `~/.cursor/`, `~/.github-copilot/`).

**Other options:**

```bash
# Skills only, auto-detect tools
./install.sh

# Target a specific tool (skill only)
./install.sh --claude     # Claude Code
./install.sh --cursor     # Cursor
./install.sh --copilot    # GitHub Copilot
./install.sh --all        # all three

# Skills + config for all tools (same as --config alone)
./install.sh --all --config

# Install config into a specific project directory
./install.sh --config <dir>
```

## Docs

Full write-up at [mayurpise.github.io/dotai](https://mayurpise.github.io/dotai/) or in [`docs/`](docs/).
