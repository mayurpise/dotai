#!/usr/bin/env bash
# Deterministic ruleset sync: mirror selected open-code-review rulesets into the
# review skill's bundled rulesets/ dir at a pinned commit. Files there are VERBATIM
# upstream mirrors — do NOT edit; re-fetching the same SHA is byte-identical. Because
# they live under skills/review/, install.sh ships them alongside the skill.
#
# Usage:
#   scripts/sync-upstream.sh          # resolve REF -> SHA, fetch, write, report
#   scripts/sync-upstream.sh --check  # report drift only, write nothing (CI/hook dry-run)
#   REF=<sha|tag|branch> scripts/sync-upstream.sh   # hard-pin to a specific ref
#
# Exit codes: 0 = up to date, 3 = changed (drift), 2 = network/fetch error.
# Deps: git, curl (no jq/gh).

set -euo pipefail

UPSTREAM="alibaba/open-code-review"
REF="${REF:-main}"
DEST="skills/review/rulesets"
RULE_PREFIX="internal/config/rules/rule_docs"

# Rulesets to mirror (basenames under $RULE_PREFIX upstream). Edit to change coverage.
RULES=( default.md python.md ts_js_tsx_jsx.md )

check_only=0
[[ "${1:-}" == "--check" ]] && check_only=1

cd "$(git rev-parse --show-toplevel)"

# Resolve REF -> commit SHA (deterministic pin). A 40-hex REF is used as-is.
if [[ "$REF" =~ ^[0-9a-f]{40}$ ]]; then
  sha="$REF"
else
  sha="$(git ls-remote "https://github.com/$UPSTREAM" "$REF" 2>/dev/null | cut -f1)"
fi
[[ -n "${sha:-}" ]] || { echo "sync-upstream: could not resolve $UPSTREAM@$REF (offline?)" >&2; exit 2; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
changed=0

# "<upstream path>|<local basename under $DEST>"
declare -a MAP=( "LICENSE|LICENSE" )
for r in "${RULES[@]}"; do MAP+=( "$RULE_PREFIX/$r|$r" ); done

for pair in "${MAP[@]}"; do
  up="${pair%%|*}"; base="${pair##*|}"
  if ! curl -fsSL "https://raw.githubusercontent.com/$UPSTREAM/$sha/$up" -o "$tmp/f" 2>/dev/null; then
    echo "sync-upstream: fetch failed: $up" >&2; exit 2
  fi
  dest="$DEST/$base"
  if [[ -f "$dest" ]] && cmp -s "$tmp/f" "$dest"; then continue; fi
  changed=1; echo "  changed: $base"
  [[ $check_only -eq 0 ]] && { mkdir -p "$DEST"; cp "$tmp/f" "$dest"; }
done

if [[ $check_only -eq 0 ]]; then
  mkdir -p "$DEST"
  {
    echo "# Verbatim upstream mirror — do not edit. Managed by scripts/sync-upstream.sh."
    echo "upstream: https://github.com/$UPSTREAM"
    echo "license:  Apache-2.0"
    echo "ref:      $REF"
    echo "commit:   $sha"
    echo "rules:"
    printf '  - %s\n' "${RULES[@]}"
  } > "$DEST/UPSTREAM.lock"
fi

if [[ $changed -eq 1 ]]; then
  echo "sync-upstream: rulesets updated to $UPSTREAM@${sha:0:12}"; exit 3
fi
echo "sync-upstream: up to date at $UPSTREAM@${sha:0:12}"; exit 0
