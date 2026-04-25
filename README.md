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
# Auto-detect installed tools
./install.sh

# Target a specific tool
./install.sh --claude     # Claude Code
./install.sh --cursor     # Cursor
./install.sh --copilot    # GitHub Copilot
./install.sh --all        # all three

# Install config into a project directory
./install.sh --config <dir>
```

## Docs

Full write-up at [mayurpise.github.io/dotai](https://mayurpise.github.io/dotai/) or in [`docs/`](docs/).
