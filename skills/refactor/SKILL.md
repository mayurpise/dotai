---
name: refactor
description: "Change the structure of existing code without changing its behavior. A pre-coding discipline: classify the task, lock current behavior with tests, freeze a manifest, execute surgically, then prove the same tests still pass. The brownfield counterpart to /minimal-code — where that skill uses tests as a spec for new behavior, this uses them as a lock on existing behavior. Use when the user says 'refactor', 'restructure', 'rename', 'extract', 'inline', 'clean up without changing behavior', 'preserve behavior', '/refactor', or before modifying existing code whose behavior must not change."
---

# Refactor Protocol (Brownfield)

The smallest **diff** that changes structure while preserving behavior — not the least code. A behavior-neutral rename that *adds* lines can be correct; a small behavior-*changing* edit is not. This is the brownfield counterpart to `/minimal-code`: that skill treats tests as the **spec** for behavior you're about to write; this treats them as the **lock** on behavior that already exists.

**Precedence:** for a refactor task, this overrides `/minimal-code`'s test-as-spec. Behavior preservation replaces test-as-spec as the definition of done.

## Red Flags — STOP if you're:

- Changing code before classifying the task (Phase 0) — a refactor mixed with a behavior change must be split, never interleaved
- Refactoring code you cannot lock — no covering test exists and you haven't written a characterization test yet
- Editing a lock test to make it pass — if the test had to change, behavior changed; that's a violation, not a refactor
- Changing a public signature, return type, raised exception, or side effect the task did not ask for — a signature change *is* a behavior change
- Improving, reformatting, retyping, or rewording adjacent code the goal did not name
- Rewriting when a mechanical rename / extract / inline would achieve the goal
- Declaring done before the same lock tests pass, unchanged, both before and after

**Done = structure changed, behavior identical, the lock tests green and unmodified on both sides. Every changed line traces to the stated goal.**

## When this applies — and when it doesn't

Applies to **modifying existing code where behavior must not change**: rename, extract, inline, move, restructure, dedupe.

- Authoring **new** behavior with a test harness → `/minimal-code` (tests as spec, not lock).
- A **directory-wide** review-and-cleanup sweep → `/scrub` (finding-driven, tiers findings by fix risk).
- A **behavior change / feature** → not this skill; that behavior change is intended and belongs in `/minimal-code`.
- Docs, config-only edits, trivial one-liners → skip; the lock/manifest machinery is pure overhead.

---

## Phase 0: Classify the task

State which one this is, then follow the matching rule. Do not proceed until classified.

- **Pure refactor** (behavior MUST NOT change) → this skill.
- **Behavior change / feature** (new behavior intended) → wrong skill; use `/minimal-code`.
- **Mixed** (refactor + change) → **SPLIT** into two steps: refactor first (this skill), behavior change second (`/minimal-code`). Never interleave.

If mixed and not split, stop and split it.

## Phase 1: Lock behavior before touching code

Identify the exact code under change and its observable behavior — return values, side effects, raised exceptions, I/O, ordering.

- **Covered by tests already?** Run them, confirm green, record the result. That is the lock.
- **Not covered?** Write characterization tests that pin **current** behavior — including current quirks and bugs. Assert what the code does *now*, not what it *should* do. That is the lock.
- **Cannot lock it?** Say so and stop. Do not refactor code you cannot lock.

## Phase 2: Manifest & freeze

Before changing code, freeze a manifest (as `/minimal-code` Phase 1: files to touch, signatures, out-of-scope) and add:

- **The lock relied on** — which tests, confirmed green pre-change.
- **Guaranteed unchanged** — public signatures, return types, raised exceptions, side effects.
- **Blast radius** — every caller / importer of the changed surface.

If the task later forces a deviation, amend the manifest explicitly and say why. Never expand scope silently.

## Phase 3: Execute surgically

- Prefer **mechanical, reversible** steps — rename, extract, inline — over rewrites. If a rewrite is genuinely simpler than incremental change, say so and get confirmation before replacing working code.
- Touch only lines the goal requires. Every changed line traces to it.
- Do **not** change public signatures, return types, raised exceptions, or side effects unless the task asks — a signature change is a behavior change.
- Preserve current **bug-for-bug** behavior unless fixing the bug *is* the task. If fixing, that is a behavior change → reclassify (Phase 0), update the lock test to the new expectation, and note it explicitly.
- Surgical scope is CLAUDE.md §3 (Surgical Changes) — no adjacent reformatting, retyping, or "while I'm here" edits; remove only imports/variables your own change orphaned; note other dead code, don't delete it.
- **One refactor type per commit** — conventional `refactor:`. Never mix `refactor:` and `feat:` in one commit.

## Phase 4: Neutrality gate

The **same** lock tests must pass, **unmodified**, before AND after. If you had to change a test to make it pass, behavior changed — that is a violation, not a refactor. Revert and reclassify.

## Phase 5: Self-critique gate

Before declaring done, report pass/fail on each. If any fails, revise before presenting — never present failing work with caveats.

- [ ] Lock tests unchanged and green, both pre- and post-change
- [ ] No public signature / return / exception / side-effect change (unless the task required it)
- [ ] Diff contains zero unrelated edits — no style, adjacent code, or imports not orphaned by this change
- [ ] Every changed line traces to the stated goal
- [ ] All callers in the blast radius still compile / pass

## Standards

Green before done, using the project's configured toolchain (Python reference in parentheses):

- **Types** — strict type-check passes (`mypy --strict`)
- **Lint & format** — linter clean including complexity limits, formatter applied (`ruff check`, `ruff format`)
- **No dead code** — no unused imports or variables orphaned by the change (`ruff` F401 / F841)

Substitute the equivalent checker for other languages; the gate is "the project's checks pass," not a specific tool.

## Workflow

```
1. Classify (Phase 0) → pure refactor? If mixed, split (refactor first). If new behavior, use /minimal-code.
2. Lock (Phase 1) → existing tests green, or write characterization tests that pin current behavior → confirm the lock.
3. Manifest (Phase 2) → files, guaranteed-unchanged surface, blast radius → freeze it.
4. Execute (Phase 3) → mechanical, reversible, surgical → one refactor type per commit.
5. Neutrality gate (Phase 4) → the same lock tests pass, unchanged, before and after.
6. Self-critique (Phase 5) → report pass/fail on the five gate items → revise until all pass.
7. Run the Standards checks → all green → done.
```
