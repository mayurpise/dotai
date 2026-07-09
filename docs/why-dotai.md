# Why dotai: Benefits of CLAUDE.md and the dotai skills

Two levers that shape LLM behavior: **CLAUDE.md** controls _how_ the model responds in every session; the skills under `skills/` control _what_ it does in specific high-risk workflows (`/scrub` for code cleanup, `/minimalist` for writing and restructuring code with a minimal diff, `/skill-review` for auditing other skills). Together they reduce wasted tokens, prevent scope creep, and make outputs reliably actionable.

---

## CLAUDE.md

### Token Efficiency

| Mechanism | How it saves tokens |
|-----------|-------------------|
| **Absolute Mode** | Eliminates filler, hedging, emotional softening, continuation bias. A typical Claude response without guidance adds 20-40% padding — this strips it. |
| **Output routing** | Reports >20 lines go to a file; console returns 3-5 bullets. Prevents the context window from being consumed by long inline prose. |
| **Gated clarifying questions** | "Ask only when blocked" stops the back-and-forth loop that doubles session length. LLMs default to asking; this default is reversed. |
| **Thinking frameworks as conditionals** | Frameworks (First Principles, Expert Panel, etc.) only fire when the trigger condition matches. Without this, models apply heavy reasoning scaffolding to trivial prompts. |
| **No comments by default** | Cuts generated code size. Comments on obvious code are pure token waste in both generation and future context loads. |

### Steering Better Decisions

**Simplicity First + Surgical Changes** work as a pair against the LLM's strongest failure mode: pattern-matching to "best practices" and gold-plating. Models trained on public code associate quality with abstractions, interfaces, and configurability. These rules explicitly override that bias:
- "Minimum code that solves the problem" — no strategy patterns for a single calculation
- "Touch only what is required" — no opportunistic reformatting, type-hint additions, or adjacent cleanup
- The anti-patterns table gives _negative_ examples, which suppresses trained associations more effectively than positive rules alone

**Goal-Driven Execution** converts vague tasks into verifiable checkpoints before the model touches code. This matters because LLMs default to optimistic execution — they start writing and discover ambiguity mid-flight, which leads to restarts and rework. Stating assumptions upfront surfaces disagreements cheaply.

**Precedence ordering** (User Prefs → Absolute Mode → Coding Guidelines → Workflow) gives the model an explicit conflict-resolution rule. Without it, models blend instructions inconsistently when they conflict.

**Workflow Rules** (test before commit, clean status before push, conventional commits) encode guardrails that prevent the most common agentic failure: a model that makes changes, declares success, and leaves the repo in a broken state.

---

## skills/scrub

### Token Efficiency

| Mechanism | How it saves tokens |
|-----------|-------------------|
| **Phase 1: scope upfront** | Globs and reads every source file once before agents launch. The three agents share that single read pass instead of each re-globbing and re-reading independently — a 3x cut in file-IO tokens. Also forces the user to confirm the target directory when missing, so agents never wander off-scope. |
| **Phase 2: three parallel agents** | Wall-clock time cut by ~3x vs sequential. Each agent receives the same file list but focuses on one dimension (reuse / quality / efficiency), preventing cross-contamination that bloats findings. |
| **Structured report template** | Exact schema (Applied / Skipped / Pending / Budget) means the LLM doesn't improvise format. Format improvisation inflates output tokens and makes results hard to parse programmatically. |
| **Budget caps (30 findings / 500 lines)** | Hard stops a runaway session before it consumes unbounded context. Also forces prioritization — the model must rank, not just list. |

### Steering Better Decisions

**Tiered classification (T1/T2/T3)** is the central safety mechanism. It maps directly to risk:
- T1 (mechanical swap): apply freely — no human needed
- T2 (structural refactor): apply with per-file validation gate — catch regressions early
- T3 (semantic change): never apply silently — always confirm

Without this, models either over-apply (making risky changes autonomously) or under-apply (flagging everything as "needs review"). The tiers give precise autonomy boundaries.

**Skip category constraints** are unusually strong: only three valid reasons to skip a finding (output would change, test broke, project rule forbids it). "Low impact," "cosmetic," and "not worth it" are explicitly invalid. This prevents the model's natural conservatism — LLMs frequently self-censor findings they judge as minor, creating silent gaps in the audit. The constraint forces completeness.

**"Skipping is the exception, not the default"** in the opening line sets the execution posture before the model reads any rules. Framing bias is real: a prompt that opens with "be thorough" produces more findings than one that opens with "be careful." This phrasing front-loads the aggressive posture.

**Per-file commits** reduce the blast radius of any single bad application. One file = one revertable unit. Without this instruction, models batch changes across files into one commit, making targeted rollbacks impossible.

**Gates between tiers** (typecheck after T1, typecheck + tests after each T2 file) create mandatory feedback loops. Without gates, errors in early files compound silently into later files, and the final state is broken in ways the model can't attribute to a specific change.

---

## skills/skill-review

### Token Efficiency

| Mechanism | How it saves tokens |
|-----------|-------------------|
| **Pre-flight scan before LLM judge** | Deterministic grep/awk checks for merge markers, `file://`, and frontmatter shape run first. The highest-impact bugs are caught without spending Tessl's LLM tokens. |
| **Per-suggestion triage table** | Fixed category → default-action mapping replaces ad-hoc deliberation per suggestion. The model classifies and acts; it doesn't re-derive the rubric each time. |
| **Structured per-skill report** | Exact schema (Pre-flight / Accepted / Deferred / Rejected / Build) prevents format improvisation across batch runs. |

### Steering Better Decisions

**Claim verification first** — every Tessl suggestion is checked against the actual file before any edit. Tessl's content judge has documented biases (favors shorter skills, invents example CLI syntax). Treating the score as a target produces regressions; verifying each claim produces fixes.

**Categorical reject list** — "Trim Red Flags / anti-pattern guards" and "Remove placeholders Claude already knows" are pre-rejected by default. These are the two failure modes observed across a 33-skill batch: the LLM judge erodes anti-regression guards because it can't measure their value.

**Regression-risk check before any edit** — three explicit questions (cross-references? user-visible artifact? build-pipeline contract?) before touching the file. A "yes" or "unsure" on any one defers the edit. Prevents the common pattern of accepting an LLM suggestion that breaks downstream consumers.

**Watch the suggestion list, not the score** — explicit calibration note that the content judge is non-deterministic (±5 points) and additive fixes can lower the conciseness score. Chasing the score produces worse skills.

---

## skills/minimalist

### Token Efficiency

| Mechanism | How it saves tokens |
|-----------|-------------------|
| **Classify-first gate (§0)** | Forces NEW / CHANGE / REFACTOR / MIXED up front. A mixed task is split before any code is touched, so the model never interleaves two intents and then unwinds the tangle — the single largest source of refactor rework. |
| **Manifest freeze before coding (§1)** | The model commits to exact files and signatures up front, so it cannot wander into unplanned files or abstractions mid-session. Unplanned scope is the largest source of wasted generation; freezing the surface area caps it. |
| **Definition of done as a hard stop (§2)** | Tests-as-spec for new behavior, lock tests for refactors — "stop when the named tests pass" is a termination signal. Without it, models keep elaborating extra branches, defensive checks, and speculative helpers long after the task is met. |
| **Deletion pass on the diff (§5)** | Every added function or parameter must justify itself in one line or be removed. This inverts the default additive bias, shrinking both the diff and the context every future session must load. |

### Steering Better Decisions

**Classify before coding** — one decision at the top selects the definition of done. NEW/CHANGE write tests *toward* intended behavior; REFACTOR writes characterization tests *against* current behavior (bugs included); MIXED must split into REFACTOR then CHANGE, never interleaved. This blocks the common failure of "improving" behavior under the banner of a refactor.

**Smallest diff, not least code** — a behavior-neutral rename or extract that *adds* lines is a success. The objective is the smallest change that satisfies the task type's definition of done, not the least total code. Stating the target explicitly stops the model from "cleaning up" during a refactor and silently changing behavior.

**Out-of-scope defaults** name the gold-plating explicitly — no abstraction under 3 call sites, no config for a single caller, no class where a function works, no error handling for impossible inputs. Models associate these patterns with quality; stating them as _defaults to avoid_ overrides the trained bias more reliably than a generic "keep it simple."

**Self-critique gate (§6)** makes the model report pass/fail on an explicit checklist (every line traces to a test, every abstraction has ≥3 call sites, no speculative generality, no unrelated edits, lock tests unchanged for refactors) before declaring done. An explicit checklist catches over-engineering that a vague "review your work" misses.

**Relationship to /scrub** — minimalist governs code being written or restructured; `/scrub` reviews code already written across a directory. The §5 deletion pass is a scrub on the model's own diff and hands off to `/scrub` for the surrounding tree.

---

## Combined Effect

1. **Defensive rules** — explicit anti-patterns, skip constraints, gates, and budget caps that limit how much damage an autonomous agent can do
2. **Token discipline** — output routing, gated questions, and format templates that make sessions leaner without losing quality
