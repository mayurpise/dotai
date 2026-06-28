---
name: work-tracker
description: "Route long-form work products into the right docs/ location and consolidate scattered status into one canonical master tracker (docs/WORK_TRACKER.md). Enforces the verify-first protocol: re-confirm a gap still exists against main before writing any code. Use when the user says 'build a work tracker', 'consolidate status', 'reconcile the docs', 'where should this go', 'track this work', 'start a backlog', '/work-tracker', or before starting any multi-item backlog."
---

# Work Tracker & Docs Routing

One canonical tracker holds status; source docs hold detail; verify before you build. This skill enforces two habits: (1) route long-form output to a predictable place instead of dumping it in chat, and (2) keep a single source-of-truth tracker so done-vs-pending never goes stale and you never re-implement shipped work.

## Red Flags - STOP if you're:

- About to implement a backlog item without re-verifying the gap still exists against the main branch
- Putting status into a plan/audit/design doc instead of the tracker (status drifts the moment it lives in two places)
- Creating a second tracker when one already exists — update the canonical one
- Deleting a superseded doc before repointing its inbound references (you'll leave dangling links)
- Dumping a >20-line report/plan/audit into the chat instead of a file
- Marking a row DONE without evidence (commit SHA, merged PR, or a grep showing the symbol exists)
- Flipping a task's status without re-checking its checkbox and recomputing the progress bars (stale bar = lie)

**One tracker is canonical. Verify the gap before coding. Status never lives in two places.**

---

## Part A: Output Routing

Long-form **non-code** output (reports, analyses, plans, research, audits) over ~20 lines goes to a markdown file. The chat returns a **3-5 bullet summary + the file path** — never the full document.

| Output type | Destination |
|---|---|
| Report / analysis | `docs/` |
| Research | `docs/research/` |
| Plan | `docs/` or `draft/` |
| Audit | `docs/audit/` |
| Master tracker | `docs/WORK_TRACKER.md` (see Part B) |

**Exempt — these stay inline, never file-routed:** code, diffs, test output, review feedback.

After writing any new doc, register it in the project's docs index (the `docs/` README or index file) so it is discoverable.

## Part B: The Master Tracker

### When to build or update one

Build or reconcile `docs/WORK_TRACKER.md` when **any** of these fire:
- Status/work is scattered across multiple docs (plans, audits, designs) and done-vs-pending is unclear
- The user asks to review, consolidate, or track work
- You are about to start a multi-item backlog

Apply on every project. If a tracker already exists, **update it** — never fork a second one.

### Canonical structure

The tracker is laid out top-down in this exact order:

1. **Overall progress bar** — a rendered bar + `done/total (N%)` at the very top, so progress is visible at a glance (see Progress rendering)
2. **Status taxonomy** — the legend, used everywhere: `DONE` / `IN-PROGRESS` / `PLANNED` / `GAP` / `DESIGN-ONLY` / `WON'T-DO` / `SIGN-OFF`
3. **Workstream rollup dashboard** — one row per workstream, counts by status, **plus a per-workstream progress bar**
4. **Prioritized tiered backlog** — risk/impact-first, each row a **checkbox** with a stable referenceable ID (e.g. `WT-012`)
5. **Per-workstream detail** — grouped **checkbox** items under each workstream
6. **Source-document map** — which source doc each item's detail lives in
7. **Reconciliation log** — recently-shipped items flipped to DONE with evidence

Status is canonical **only** in the tracker. Detail stays in source docs. Never let status leak back into source docs.

### Progress rendering

Every task is a checkbox so progress is scannable, and every progress total rolls up into a rendered bar.

- **Checkbox per task** — `- [x]` only when status is `DONE` or `SIGN-OFF` (all subtasks complete); `- [ ]` for everything else, **including `IN-PROGRESS`**. `WON'T-DO` is excluded from the count entirely (strike it: `- [x] ~~WT-009~~`).
- **Progress bar** — 10 cells, `█` filled and `░` empty, followed by the percentage and counts. Recompute on every tracker touch.

  ```
  Overall: [███████░░░] 67% — 18 done · 4 in-progress / 30
  ```

- **Percentage** = `((DONE + SIGN-OFF) + 0.5 × IN-PROGRESS) ÷ (total tasks excluding WON'T-DO)`, rounded to a whole number. **An `IN-PROGRESS` task counts as half.** Filled cells = `round(percent ÷ 10)`.
- **Per-workstream bar** — same formula, scoped to that workstream's tasks; render it in the rollup row.

### Subtasks and the in-session todo list

Three layers — keep them distinct:

| Layer | Where | Lifespan | Granularity |
|---|---|---|---|
| Master tracker | `docs/WORK_TRACKER.md` | durable, cross-session | one row per `WT-ID` |
| Subtask checklist | nested under the item in per-workstream detail | durable | the TODO steps of one item |
| In-session todo list | the live task tool (TaskCreate / TodoWrite) | ephemeral, this session only | execution scratchpad |

- **A multi-step item expands into a nested checklist** under its `WT-ID` in per-workstream detail. The parent stays `- [ ]` until every child is checked:

  ```
  - [ ] **WT-004** — migrate auth to OIDC (IN-PROGRESS); detail → docs/auth.md
    - [x] add provider config
    - [ ] swap token middleware
    - [ ] cut over callback URLs
  ```

  An item is `IN-PROGRESS` when some-but-not-all subtasks are checked, `DONE` when all are. That partial state is exactly what earns the item its half-credit in the bar.
- **Sync direction.** At pick-up, expand the chosen `WT-ID` into the live in-session todo list and execute against it. At completion, collapse back into the tracker: tick the subtasks/checkbox, set Status, recompute the bars, add a reconciliation row. The ephemeral list is the scratchpad; the tracker is the record — never treat the session todo list as the source of truth.

### Verify-first protocol (mandatory, embed it in the tracker)

Before starting **any** backlog item — write **no code** until all four pass:

1. **Re-read state** — the tracker row and its source doc.
2. **Verify the gap still exists against main** — `git log` for recent related commits **and** `grep` the named symbol/file. If it already exists, the gap is closed.
3. **Confirm it is still required** — requirements may have moved.
4. **Flip stale rows with evidence** — already-done → `DONE` (cite SHA/PR); obsolete → `WON'T-DO` (cite why). Only then, if the gap is real, write code.

This protocol exists because scattered/stale status causes redundant rework on already-shipped items. Embed the four steps verbatim at the top of the backlog section so every future pass follows them.

### Maintenance rules

- **Reconcile against the repo's current state** on every tracker touch — flip what shipped since last time.
- **Retiring a superseded doc:** repoint its inbound references first (source-code comments + cross-links → point them at the tracker), *then* delete. Nothing dangles.
- Keep the tracker reconciled; keep detail in source docs. The two never duplicate status.

## Tracker template

Copy this skeleton into `docs/WORK_TRACKER.md` on first build:

```markdown
# Work Tracker

**Overall: [░░░░░░░░░░] 0% — 0 done · 0 in-progress / 0**

> Canonical status lives here. Detail lives in the linked source docs.
> **Verify-first (before coding any item):** 1) re-read state · 2) verify the gap
> still exists on main (`git log` + grep the symbol) · 3) confirm still required ·
> 4) flip done/obsolete rows to DONE/WON'T-DO with evidence. Only then write code.

## Status taxonomy
DONE · IN-PROGRESS · PLANNED · GAP · DESIGN-ONLY · WON'T-DO · SIGN-OFF

## Workstream rollup
| Workstream | Progress | DONE | IN-PROGRESS | PLANNED | GAP | Notes |
|---|---|---|---|---|---|---|
|  | `[░░░░░░░░░░] 0%` |  |  |  |  |  |

## Backlog (risk/impact-first)
| Done | ID | Item | Workstream | Status | Priority | Source doc |
|---|---|---|---|---|---|---|
| [ ] | WT-001 |  |  |  |  |  |

## Per-workstream detail
### <Workstream>
- [ ] **WT-001** — <one line>; detail → `docs/<source>.md`

## Source-document map
| Source doc | Covers IDs |
|---|---|
|  |  |

## Reconciliation log
| Date | ID | Change | Evidence |
|---|---|---|---|
```

## Workflow

```
1. Determine intent → routing-only, or build/reconcile the tracker?
2. (Routing) Pick destination from Part A → write file → return 3-5 bullets + path → register in docs index.
3. (Tracker) Locate existing docs/WORK_TRACKER.md.
   → exists: reconcile it against the repo.  → absent: scaffold from the template.
4. Inventory scattered status across source docs → fold into the tracker's backlog with stable IDs.
5. Run verify-first on each open item → flip stale rows to DONE/WON'T-DO with evidence → tick checkboxes and recompute the overall + per-workstream bars.
6. Retire superseded docs: repoint inbound references to the tracker, THEN delete.
7. Register the tracker in the docs index. Report: counts moved, rows flipped, docs retired.
```
