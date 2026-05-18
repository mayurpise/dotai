---
name: skill-review
description: "Audit SKILL.md files with the Tessl CLI, then triage each suggestion against a strict regression-aware framework before applying any edit. Use when the user says 'review this skill', 'run skill review', 'audit skills', '/skill-review', or wants to verify a skill before merging. Installs tessl on first use if missing."
---

# Skill Review (Tessl + Triage)

Run `tessl skill review` against one or more `SKILL.md` files, then apply only the suggestions that survive an adversarial review. This skill exists because Tessl's content judge has documented biases (favors shorter skills, over-trusts "Claude already knows X") — its score is one signal, not the goal.

## Red Flags - STOP if you're:

- Applying any Tessl suggestion without verifying the underlying claim against the actual file
- Treating the Tessl score as a target rather than one signal
- Removing anti-pattern guards (Red Flags sections, validation checkpoints) because "Claude understands best practices"
- Trimming placeholders in templates without checking whether each one is a *directive* or a *typeshape*
- Making "split into reference files" refactors mid-review (these are scoped changes, not feedback fixes)
- Touching multiple skills in one editing pass without running build/tests between

**Score is one signal. Verify every claim. Refuse to delete documented anti-patterns.**

---

## Step 0: Locate or install `tessl`

Search order (use the first one that exists and is executable):

1. `command -v tessl`
2. `~/.local/bin/tessl`
3. `~/.claude/bin/tessl`

If none exists, **ask the user before installing**. Show them the command and wait for confirmation:

```bash
curl -fsSL https://get.tessl.io | sh
```

After install, re-check the search order. If `tessl` is still not on PATH, tell the user the install dir and suggest adding it to PATH; do not proceed.

Verify with `tessl --version`. Capture the path in a variable (`TESSL`) used by every later step.

## Step 1: Select skills to review

Argument handling:

| Invocation | Behavior |
|---|---|
| `/skill-review` | Review every changed `**/SKILL.md` in the current git working tree (staged + unstaged + untracked). If none changed, list candidates and ask. |
| `/skill-review <path>` | Review the given path. May be a `SKILL.md` file or a directory containing one. |
| `/skill-review --skill <name>` | Review `skills/<name>/SKILL.md` (or `~/.claude/skills/<name>/SKILL.md` for global skills). |
| `/skill-review --all` | Review every `**/SKILL.md` under the current repo (or `~/.claude/skills/**/SKILL.md` if invoked outside a repo). Confirm count > 5 with the user before proceeding — each review takes ~30 seconds. |
| `/skill-review --auto` | Modifier (combinable with the above). Skip per-edit confirmation for Accept-class suggestions. Still asks before Evaluate/Defer edits. |

For each selected skill, record `skill_dir` (the directory containing `SKILL.md`).

## Step 2: Pre-flight bug scan (cheap, deterministic)

Before invoking `tessl`, run these checks on each `SKILL.md`. They catch the highest-impact bugs faster than the LLM judge and are unambiguous:

| Check | Command | If found |
|---|---|---|
| Unresolved git merge markers | `grep -nE '^(<<<<<<< \|>>>>>>> )' <file>` | Treat as **bug**, must fix |
| Absolute `file://` URLs | `grep -n 'file://' <file>` | Treat as **bug**, must fix (use relative paths) |
| Frontmatter body shape | `awk 'NR==4 && $0 != "---" {exit 1} NR==6 && $0 !~ /^# / {exit 1}' <file>` | If not `---` on line 4 and `# Title` on line 6, build pipeline assumptions broken — flag, do not auto-fix |
| Trailing whitespace | `git diff --check <file>` (only if in git) | Cosmetic, fix when touching the file anyway |

Surface these as **bugs**, not suggestions. They precede the Tessl run and are not subject to triage.

## Step 3: Run Tessl

For each skill:

```bash
"$TESSL" skill review --json "<skill_dir>" > /tmp/tessl-<name>.raw 2>&1
```

Note: `tessl` prefixes its JSON output with a status line (`- Reviewing skill...`). Strip it:

```bash
if head -1 /tmp/tessl-<name>.raw | grep -q '^- '; then
  tail -n +2 /tmp/tessl-<name>.raw > /tmp/tessl-<name>.json
else
  cp /tmp/tessl-<name>.raw /tmp/tessl-<name>.json
fi
```

Parse the resulting JSON. Key fields:
- `review.reviewScore` — overall 0-100
- `validation.overallPassed`, `validation.checks[]` — structural validation (frontmatter, line count, etc.)
- `contentJudge.evaluation.scores` — `conciseness`, `actionability`, `workflow_clarity`, `progressive_disclosure` (each 0-3)
- `contentJudge.evaluation.suggestions[]` — the things to triage

If `tessl` exits non-zero, capture stderr and surface it to the user; do not invent a triage.

## Step 4: Triage framework (the core of this skill)

Apply this framework to **every** suggestion before any edit. Do not skip.

### Step 4a: Verify the claim

For each suggestion:

1. Read the relevant section of `SKILL.md` (use line numbers, not summary).
2. Ask: **is what Tessl says about the file actually true?**
3. If the suggestion references a command, file, or tool, **check it exists with the right syntax**. Tessl frequently invents example commands that don't match the real tool's CLI. Verify with `--help` or by reading the tool source.

If the claim is false, **reject** with a note.

### Step 4b: Classify by category

| Category | Examples | Default action | Notes |
|---|---|---|---|
| **Real bug** | Merge conflicts, broken links, wrong CLI syntax, factually incorrect instruction | **Accept** after verification | These don't need debate. |
| **Add concrete command/example** | "Include the exact invocation of X", "show a sample of the output structure" | **Accept** if claim true and example syntax verified against real tool | Additive, low regression risk. Verify the example syntax yourself; don't copy Tessl's literal example. |
| **Add validation step** | "Verify all referenced files exist before saving" | **Accept** if the skill produces files | Bug-prevention beats brevity for file-producing skills. |
| **Handle ambiguous case** | "User input could match multiple intents" | **Accept** if the gap is real | Usually a small clarifying-question rule. |
| **Use a table instead of prose** | "Convert the checkpoint paragraphs to a table" | **Accept** if no information is lost | Verify the table preserves all directives, not just facts. |
| **Trim Red Flags / anti-pattern guards** | "Reduce to 2-3 items, Claude knows ADR best practices" | **Reject** | These are anti-regression guards. Project convention (e.g., Draft uses Red Flags in 30/33 skills). Don't remove on the strength of a generic LLM judge. |
| **Remove "placeholders Claude already knows"** | "Strip `[State decision in active voice]` from the template" | **Reject by default** | Many placeholders are directives, not typeshapes. Reject unless you can prove each individual placeholder is a typeshape AND you've inspected real generated artifacts to verify the placeholder doesn't survive. |
| **Split into reference files** | "Move evaluate/design modes to separate files" | **Defer** | These are architectural refactors. The skill's runtime behavior depends on what content is loaded at decision time. Needs scoped change with live testing — not a feedback-pass edit. |
| **Generic "condense" / "consolidate"** | "Condense the metadata block into a single compact script" | **Evaluate strictly** | Often the current form is already efficient. Accept only if you can show a concrete win without losing clarity. |
| **"Conciseness" complaints with no concrete fix** | "The skill is verbose at 200+ lines" | **Reject** | Length alone is not a defect. The Tessl line-count warning is generic advisory, not a finding. |
| **Other** | Anything not in this table | **Case-by-case** with the same standard: claim true AND fix safe AND real issue |

### Step 4c: Regression-risk check before any edit

For every suggestion you classified as Accept or Evaluate, before editing answer all three:

1. **Does the edit drop any command, file path, or directive that's referenced elsewhere?** (Cross-reference the file. Tessl can't see external references.)
2. **Does the edit change a user-visible artifact?** (Template files saved to disk, generated reports — these have shape that downstream users depend on.)
3. **Does the edit break the build pipeline contract?** (Frontmatter must have `---` on line 4, `# Title` on line 6. Body extraction depends on this exact shape.)

If any answer is "yes" or "unsure" — **defer** the suggestion and tell the user why.

## Step 5: Apply accepted edits

For each Accept that survived Step 4c:

1. Show the user the exact edit you plan to make (file, line range, before/after).
2. Wait for confirmation **unless the user invoked `/skill-review --auto`**, in which case proceed on Accept (still not on Evaluate or Defer).
3. Apply edits surgically — one suggestion per Edit tool call. Do not bundle.
4. After each edit, re-read the changed section to verify the result matches intent.

## Step 6: Verify

After all edits to a skill:

1. **Re-run pre-flight scan** (Step 2) to confirm no merge markers, `file://`, or frontmatter damage was introduced.
2. **If the repo has a build/test pipeline** (`Makefile` with `build`/`test` targets, or a `package.json` with `test`), run them. Surface failures to the user immediately; do not move to the next skill.
3. **Re-run Tessl on edited skills** to confirm no new bug-class suggestions appeared. **Do not chase the score** — score can drop slightly even for correct fixes (the conciseness judge penalizes added content). Verify the *suggestion list* changed sensibly.

## Step 7: Report

Output one structured summary per skill:

```
## skills/<name>
- Pre-flight bugs: <N> (list each with line numbers)
- Tessl score: <before> → <after>
- Suggestions: <total>
  - Accepted: <count>, applied:
    - <one-line per applied edit>
  - Deferred: <count>
    - <suggestion> — reason: <why deferred>
  - Rejected: <count>
    - <suggestion> — reason: <why rejected>
- Build/tests: <pass | fail | n/a>
```

Then a single top-level summary:

```
## Summary
Skills reviewed: <N>
Pre-flight bugs fixed: <N>
Suggestions: <total> · accepted <a> · deferred <d> · rejected <r>
Build status: <pass | fail | n/a>
```

## Calibration notes — what Tessl is good at and not

These are biases observed across the Draft plugin's 33 skills. They will likely apply to other skill sets too.

**Trustworthy signals:**
- Merge conflict detection
- `file://` and other absolute-path bugs
- Frontmatter validation
- "Skill description is too generic" — when true, this is real
- Pointing out missing concrete CLI examples (but verify the syntax Tessl suggests — it often invents bad examples)

**Biased signals (down-weight):**
- "Too verbose / too long" — Tessl prefers ~150-line skills; many skills legitimately need more
- "Claude already knows X" — frequently applied to load-bearing directives, not just typeshapes
- "Split into reference files" — architecturally interesting but never urgent
- "Remove the Red Flags section" — anti-pattern guards have anti-regression value Tessl can't measure

**Score volatility:**
- The content judge is LLM-based and non-deterministic. Identical runs can differ by ~5 points.
- A correct, additive fix can *lower* the conciseness score. This is expected.
- Watch the *suggestion list*, not the score.

## Error Handling

**If `tessl` install fails:** Show the user the curl command output. Likely network or permissions issue. Do not proceed.

**If `tessl skill review` errors on one file:** Capture stderr, report it, continue with remaining skills. Do not abort the batch.

**If `make build` or `make test` fails after edits:** Stop. Roll back the most recent edit (`git checkout <file>`) and tell the user which suggestion's edit broke it. Do not continue applying suggestions.

**If `git status` shows the skill in `UU` (unmerged) state after manual conflict resolution:** Run `git add <file>` to clear the merge state. The file content is fine; git just needs to be told the merge is done.
