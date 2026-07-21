#!/usr/bin/env bash
# Deterministic vendoring sync: mirror selected upstream files into
# vendor/open-code-review/ at a pinned commit. Files there are VERBATIM mirrors —
# do NOT edit them; adapt in skills/ instead. Re-fetching the same SHA is byte-identical.
#
# Usage:
#   scripts/sync-upstream.sh          # resolve REF -> SHA, fetch, write, report
#   scripts/sync-upstream.sh --check  # report drift only, write nothing (CI/hook dry-run)
#   REF=<sha|tag|branch> scripts/sync-upstream.sh   # hard-pin to a specific ref
#
# Exit codes: 0 = up to date, 3 = mirror changed (drift), 2 = network/fetch error.
# Deps: git, curl (no jq/gh).

set -euo pipefail

UPSTREAM="alibaba/open-code-review"
REF="${REF:-main}"
DEST="vendor/$(basename "$UPSTREAM")"   # vendor/open-code-review
LOCK="$DEST/UPSTREAM.lock"

# Files to mirror (upstream repo paths). Edit this list to change what is vendored.
FILES=(
  "LICENSE"                                          # Apache-2.0 — travels with the mirror (compliance)
  "internal/config/rules/rule_docs/default.md"
  "internal/config/rules/rule_docs/python.md"
  "internal/config/rules/rule_docs/ts_js_tsx_jsx.md"
  ".claude/commands/open-code-review.md"
)

check_only=0
[[ "${1:-}" == "--check" ]] && check_only=1

cd "$(git rev-parse --show-toplevel)"

# Resolve REF -> commit SHA (deterministic pin). A 40-hex REF is used as-is.
if [[ "$REF" =~ ^[0-9a-f]{40}$ ]]; then
  sha="$REF"
else
  sha="$(git ls-remote "https://github.com/$UPSTREAM" "$REF" 2>/dev/null | cut -f1)"
fi
if [[ -z "${sha:-}" ]]; then
  echo "sync-upstream: could not resolve $UPSTREAM@$REF (offline?)" >&2
  exit 2
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
changed=0

for path in "${FILES[@]}"; do
  if ! curl -fsSL "https://raw.githubusercontent.com/$UPSTREAM/$sha/$path" -o "$tmp/f" 2>/dev/null; then
    echo "sync-upstream: fetch failed: $path" >&2
    exit 2
  fi
  dest="$DEST/$path"
  if [[ -f "$dest" ]] && cmp -s "$tmp/f" "$dest"; then
    continue
  fi
  changed=1
  echo "  changed: $path"
  if [[ $check_only -eq 0 ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$tmp/f" "$dest"
  fi
done

if [[ $check_only -eq 0 ]]; then
  mkdir -p "$DEST"
  {
    echo "# Verbatim upstream mirror — do not edit. Managed by scripts/sync-upstream.sh."
    echo "upstream: https://github.com/$UPSTREAM"
    echo "license:  Apache-2.0"
    echo "ref:      $REF"
    echo "commit:   $sha"
    echo "files:"
    printf '  - %s\n' "${FILES[@]}"
  } > "$LOCK"
fi

if [[ $changed -eq 1 ]]; then
  echo "sync-upstream: mirror updated to $UPSTREAM@${sha:0:12}"
  exit 3
fi
echo "sync-upstream: up to date at $UPSTREAM@${sha:0:12}"
exit 0
