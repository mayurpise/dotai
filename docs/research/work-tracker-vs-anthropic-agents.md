# Work-Tracker Skill vs. Anthropic Native Task Tracking

Comparison of the `work-tracker` skill against how Claude Code / the Claude Agent SDK track tasks natively. Source for native behavior: Claude Code Tools Reference, Agent SDK "Todo Tracking", Scheduled Tasks docs, and "Building Effective Agents" (verified 2026-06-28 via claude-code-guide agent).

## Bottom line

The skill and Anthropic's native task tools operate at **two different layers and are complementary, not competing**. Native tasks are ephemeral conversational working memory; the skill is durable, committed project state. Anthropic *explicitly* says to use external files for cross-session durability — `docs/WORK_TRACKER.md` is exactly that recommended pattern. The skill is well-aligned. One factual fix is needed (deprecated tool reference) and one real capability is missing that native tasks have (dependency/blocked modeling).

## The two layers

| Dimension | Anthropic native (Task tools / TodoWrite) | `work-tracker` skill |
|---|---|---|
| Layer | Ephemeral conversational working memory | Durable project state |
| Persistence | Session-scoped; restored only on `--resume`/`--continue` within window | Committed `.md`, cross-session, git-tracked |
| Status model | `pending` / `in_progress` / `completed` / `deleted` (4) | 7-state: DONE / IN-PROGRESS / PLANNED / GAP / DESIGN-ONLY / WON'T-DO / SIGN-OFF |
| Granularity | Flat list | WT-IDs + nested subtask checklists + workstreams |
| Progress display | Checklist (checkmark + spinner); no % | Progress bars + half-credit percentage |
| Dependencies | **Native** (`blockedBy` / `addBlocks`) | Not modeled (priority ordering only) |
| Ownership | **Native** (`owner` field) | Not modeled |
| Verification | "Use automated tests to verify progress" (advisory) | Verify-first protocol (mandatory gate) |
| Audit trail | None | Reconciliation log with SHA/PR evidence |
| Tooling state | TodoWrite deprecated v2.1.142 → Task tools (incremental, deps, owner) | N/A — markdown file |

## Where the skill aligns with Anthropic

- **Durable tracking belongs in external files.** Anthropic's own guidance: native tasks are conversational state, not artifacts; for cross-session durability use external systems (files, routines, MCP PM tools). The skill's committed `docs/WORK_TRACKER.md` is the canonical instance of that recommendation — not a reinvention.
- **The skill already models the native list as the ephemeral scratchpad layer.** Its three-layer model (durable tracker / durable subtask checklist / ephemeral in-session list) matches Anthropic's framing of native tasks as session-scoped working memory.
- **Verify-first ≈ "verify intermediate progress," but stronger.** Anthropic recommends automated tests to confirm progress; the skill turns this into a mandatory pre-coding gate (re-read → grep/git-log against main → confirm required). Same intent, harder enforcement.
- **Simplicity-first.** "Building Effective Agents" pushes minimal complexity. The skill stays markdown-only rather than building bespoke tooling — consistent.

## Gaps the skill could close (borrowed from the native model)

1. **No dependency / blocked modeling.** This is the one capability native Task tools have that the skill lacks. The backlog has Priority but cannot express "WT-005 is blocked by WT-002." For multi-item backlogs this is a real omission. Fix options: add a `Blocked by` column referencing other WT-IDs, and/or a `BLOCKED` status to the taxonomy.
2. **No ownership.** Native tasks carry `owner`. Irrelevant for solo use; needed if the tracker coordinates multiple agents/people. Optional `Owner` column.
3. **No WIP discipline.** Native convention trends toward ~one `in_progress` task. The skill allows unlimited IN-PROGRESS rows (each worth 0.5 in the bar), which invites work-in-progress sprawl and a misleadingly "half-full" bar. Consider a soft WIP cap note.

## Where the skill is deliberately richer — and justified

The 7-state taxonomy, progress bars, verify-first gate, reconciliation evidence, and docs routing have **no native equivalent** because native tasks are not meant to be durable project state. These fill exactly the gap Anthropic delegates to "external systems." The added complexity is warranted by the durable, cross-session, audit-trail use case — it is not premature.

The one cost of the durable layer is **double-entry**: expanding a WT-ID into the live in-session list and collapsing results back is manual sync that native single-source tracking avoids. The skill should minimize it by only expanding items that are genuinely multi-step / multi-session.

## Recommendations (prioritized)

| # | Change | Type | Status |
|---|---|---|---|
| 1 | Fix `TaskCreate / TodoWrite` reference — TodoWrite deprecated v2.1.142; lead with Task tools | Accuracy bug | Applied |
| 2 | Add dependency modeling — `Blocked by` column (WT-ID refs) + `BLOCKED` status | Feature | Applied |
| 3 | Add WIP-cap note — flag excessive concurrent IN-PROGRESS | Polish | Applied |
| 4 | Add optional `Owner` column for multi-agent/team trackers | Feature | Applied |
| 5 | Note: only expand genuinely multi-step items to the session list (minimize double-entry) | Polish | Applied |

All five recommendations applied.
