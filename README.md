# dotai

[![GitHub stars](https://img.shields.io/github/stars/mayurpise/dotai?style=flat-square&color=gold)](https://github.com/mayurpise/dotai/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/mayurpise/dotai?style=flat-square)](https://github.com/mayurpise/dotai/network/members)
[![GitHub last commit](https://img.shields.io/github/last-commit/mayurpise/dotai?style=flat-square)](https://github.com/mayurpise/dotai/commits/main)

AI coding tool configs that reduce wasted tokens and prevent scope creep. Works with Claude Code, Cursor, and GitHub Copilot.

## What's included

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project-level agent operating instructions |
| `skills/scrub/SKILL.md` | `/scrub` skill — tiered code review that applies fixes within a behavior-preserving safety envelope; skips changes it can't lock with a test |
| `skills/skill-review/SKILL.md` | `/skill-review` skill — audit SKILL.md files with Tessl, then triage suggestions before applying |
| `skills/work-tracker/SKILL.md` | `/work-tracker` skill — route long-form docs and maintain one canonical master tracker with a verify-first protocol |
| `skills/minimalist/SKILL.md` | `/minimalist` skill — classify the task (NEW/CHANGE/REFACTOR/MIXED), freeze a manifest, lock the definition of done (tests for new behavior, characterization tests for refactors), execute surgically, then delete everything not traceable to a passing test |
| `hooks/work-tracker-sessionstart.sh` | SessionStart hook that auto-activates the work-tracker skill each session (wired into `~/.claude/settings.json` by `install.sh`; Claude Code only) |
| `install.sh` | Copies files to the right location for each tool |

## Install

```bash
# Skills + config for all detected tools (recommended)
./install.sh --config
```

That's it. One command installs every skill under `skills/` and copies `CLAUDE.md` to the global config dir of every tool it detects (`~/.claude/`, `~/.cursor/`, `~/.github-copilot/`).

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

**Retired-skill pruning:** installing also removes skills dotai used to ship but has since retired (tracked in the `RETIRED_SKILLS` list in `install.sh`), so an upgrade never leaves orphaned `SKILL.md` files behind. Each removed skill's `SKILL.md` is backed up to a sibling `.bak` first. Pruning is scoped to that explicit list — skills dotai never installed are never touched — and runs only in skill-install mode, not `--config <dir>` project mode.

## Docs

Full write-up at [mayurpise.github.io/dotai](https://mayurpise.github.io/dotai/) or in [`docs/`](docs/).
