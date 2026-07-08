---
name: minimal-code
description: "Author the smallest change that makes the declared tests pass. A pre-coding discipline: freeze a manifest, write the tests that define done, implement only to green, then delete everything not strictly required. Operationalizes CLAUDE.md's Simplicity First / Surgical Changes / Goal-Driven guidelines with concrete gates. Use when the user says 'minimal code', 'smallest change', 'no gold-plating', '/minimal-code', or before writing implementation code for a test-backed task."
---

# Minimal-Code Protocol

The smallest change that makes the declared tests pass. Any code not traceable to a failing test or the stated task is unnecessary by definition and must not be written. This skill adds the *mechanism* to CLAUDE.md's Simplicity First / Surgical Changes / Goal-Driven principles — a manifest you freeze, tests that define done, and a deletion pass that removes the rest.

## Red Flags — STOP if you're:

- Writing code before the manifest exists (Phase 1) — scope creep starts here
- Adding a file, function, parameter, or abstraction not in the frozen manifest — amend it explicitly or don't add it
- Writing implementation before a failing test demands it
- Weakening, skipping, or deleting a test to make code go green
- Introducing a class, interface, or strategy with fewer than 3 real call sites
- Adding error handling for inputs that cannot occur in the calling context
- Making a "while I'm here" edit to adjacent code
- Declaring done without running the deletion pass (Phase 4) and the self-critique gate (Phase 5)

**Done = the named tests green, nothing more. Every other line is a liability.**

## When this applies — and when it doesn't

Applies to **test-backed implementation work**: a feature, a bug fix, or a change with a runtime surface a test can exercise.

Skip it for docs, config-only edits, one-line changes, and any task with no test harness to define "done" — the manifest/test machinery is pure overhead there. For cleaning up code that **already exists** across a directory, use `/scrub` instead (this skill governs code you're about to write; scrub reviews code already written).

---

## Phase 1: Manifest & freeze

Before writing any code, produce a manifest and then write **only** to it:

- **Files to touch** — exact paths
- **Functions / classes to add or change** — exact signatures
- **Out of scope** — the §3 defaults below, plus any task-specific exclusions

State assumptions in the manifest and proceed (per Absolute Mode — ask only when blocked). If the task later forces a deviation, **amend the manifest explicitly and say why**. Never add silently.

## Phase 2: Test-as-spec

The tests are the definition of done — write them first, watch them fail.

- Write the failing tests that encode the task. These *are* the spec.
- Write only implementation code that turns a currently-failing test green.
- Stop when the named tests pass. Do not add code for cases no test covers.
- Never weaken or delete a test to make code pass.

## Phase 3: Implement to green

Write the minimum that flips red to green. During implementation, treat these as **out of scope unless a test requires them**:

- Error handling for inputs that cannot occur in the calling context
- Configuration or parameters for a single caller
- Abstraction (class, base class, interface, strategy) before ≥3 real call sites exist
- A new class where a module-level function works
- Logging, caching, retries, or validation no test demands
- "While I'm here" edits to adjacent code

Anything on this list that a test *does* require moves into the manifest first (Phase 1 amendment), then gets written.

## Phase 4: Deletion pass

Once the named tests are green, re-read the **full diff**. For every function, class, parameter, and abstraction you added, either:

- justify in one line why it cannot be inlined or removed while tests stay green, **or**
- remove it.

Delete every line not strictly required; deleting must not break a test. This is a `/scrub` on your own diff — for a broader sweep of the surrounding tree, hand off to `/scrub` after this skill completes. Present the justification list alongside the diff.

## Phase 5: Self-critique gate

Before declaring done, report pass/fail on each. If any fails, revise before presenting — never present failing work with caveats.

- [ ] Every changed line traces to a specific test or the stated task
- [ ] Every abstraction has ≥3 current call sites or a test that requires it
- [ ] No speculative generality, config, or error handling
- [ ] A senior engineer would not call this overcomplicated

## Standards

Green before done, using the project's configured toolchain (Python reference in parentheses):

- **Tests** — one behavior per test, arrange-act-assert, no logic in the test body, fixtures over setup duplication, parametrize over copy-paste, assert on behavior not implementation (`pytest`)
- **Types** — type hints on all signatures; strict type-check passes (`mypy --strict`)
- **Lint & format** — linter clean including complexity limits, formatter applied (`ruff check` incl. C901, `ruff format`)
- **No dead code** — no unused imports or variables (`ruff` F401 / F841)

Substitute the equivalent checker for other languages; the gate is "the project's checks pass," not a specific tool.

## Workflow

```
1. Confirm scope → test-backed implementation? If docs/config/trivial, skip this skill. If cleaning existing code, use /scrub.
2. Phase 1 → write the manifest (files, signatures, out-of-scope) → freeze it.
3. Phase 2 → write failing tests that encode the task → confirm they fail.
4. Phase 3 → implement the minimum to turn each test green → stop at green.
5. Phase 4 → re-read the diff → justify or delete each addition → present the justification list.
6. Phase 5 → report pass/fail on the four gate items → revise until all pass.
7. Run the Standards checks → all green → done. Optionally /scrub the touched files.
```
