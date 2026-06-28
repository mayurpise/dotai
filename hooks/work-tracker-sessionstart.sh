#!/usr/bin/env bash
# SessionStart hook: injects the work-tracker operating directive into model context.
# Fires on session startup/resume/clear (wired into ~/.claude/settings.json by install.sh).
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"[work-tracker] Operating mode: for any multi-step or multi-item task, use the work-tracker skill — build/maintain docs/WORK_TRACKER.md with the verify-first protocol (re-confirm the gap against main before coding), per-task checkboxes, and the overall progress bar; route long-form reports/plans/audits to docs/ per the skill. Skip the tracker for trivial single-step edits."}}
JSON
