# dotai

AI coding tool configs that reduce wasted tokens and prevent scope creep — for Claude Code, Cursor, and GitHub Copilot.

## Install

```bash
git clone https://github.com/mayurpise/dotai.git
cd dotai
./install.sh --config
```

See the [repo](https://github.com/mayurpise/dotai) for all options.

---

## Why dotai

Why [CLAUDE.md](https://github.com/mayurpise/dotai/blob/main/CLAUDE.md) and the skills under [`skills/`](https://github.com/mayurpise/dotai/tree/main/skills): two levers that shape LLM behavior. **CLAUDE.md** controls _how_ the model responds in every session; the skills control _what_ it does in specific high-risk workflows (`/scrub` for code cleanup, `/skill-review` for auditing other skills). Together they reduce wasted tokens, prevent scope creep, and make outputs reliably actionable.

### CLAUDE.md

**Token Efficiency**

| Mechanism | How it saves tokens |
|-----------|-------------------|
| **Absolute Mode** | Eliminates filler, hedging, emotional softening, continuation bias. A typical Claude response without guidance adds 20-40% padding — this strips it. |
| **Output routing** | Reports >20 lines go to a file; console returns 3-5 bullets. Prevents the context window from being consumed by long inline prose. |
| **Gated clarifying questions** | "Ask only when blocked" stops the back-and-forth loop that doubles session length. LLMs default to asking; this default is reversed. |
| **Thinking frameworks as conditionals** | Frameworks (First Principles, Expert Panel, etc.) only fire when the trigger condition matches. Without this, models apply heavy reasoning scaffolding to trivial prompts. |
| **No comments by default** | Cuts generated code size. Comments on obvious code are pure token waste in both generation and future context loads. |

**Steering Better Decisions**

**Simplicity First + Surgical Changes** work as a pair against the LLM's strongest failure mode: pattern-matching to "best practices" and gold-plating. Models trained on public code associate quality with abstractions, interfaces, and configurability. These rules explicitly override that bias:
- "Minimum code that solves the problem" — no strategy patterns for a single calculation
- "Touch only what is required" — no opportunistic reformatting, type-hint additions, or adjacent cleanup
- The anti-patterns table gives _negative_ examples, which suppresses trained associations more effectively than positive rules alone

**Goal-Driven Execution** converts vague tasks into verifiable checkpoints before the model touches code. This matters because LLMs default to optimistic execution — they start writing and discover ambiguity mid-flight, which leads to restarts and rework. Stating assumptions upfront surfaces disagreements cheaply.

**Precedence ordering** (User Prefs → Absolute Mode → Coding Guidelines → Workflow) gives the model an explicit conflict-resolution rule. Without it, models blend instructions inconsistently when they conflict.

**Workflow Rules** (test before commit, clean status before push, conventional commits) encode guardrails that prevent the most common agentic failure: a model that makes changes, declares success, and leaves the repo in a broken state.

---

### skills/scrub

**Token Efficiency**

| Mechanism | How it saves tokens |
|-----------|-------------------|
| **Phase 1: scope upfront** | Globs and reads every source file once before agents launch. The three agents share that single read pass instead of each re-globbing and re-reading independently — a 3x cut in file-IO tokens. Also forces the user to confirm the target directory when missing, so agents never wander off-scope. |
| **Phase 2: three parallel agents** | Wall-clock time cut by ~3x vs sequential. Each agent receives the same file list but focuses on one dimension (reuse / quality / efficiency), preventing cross-contamination that bloats findings. |
| **Structured report template** | Exact schema (Applied / Skipped / Pending / Budget) means the LLM doesn't improvise format. Format improvisation inflates output tokens and makes results hard to parse programmatically. |
| **Budget caps (30 findings / 500 lines)** | Hard stops a runaway session before it consumes unbounded context. Also forces prioritization — the model must rank, not just list. |

**Steering Better Decisions**

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

### skills/skill-review

**Token Efficiency**

| Mechanism | How it saves tokens |
|-----------|-------------------|
| **Pre-flight scan before LLM judge** | Deterministic grep/awk checks for merge markers, `file://`, and frontmatter shape run first. The highest-impact bugs are caught without spending Tessl's LLM tokens. |
| **Per-suggestion triage table** | Fixed category → default-action mapping replaces ad-hoc deliberation per suggestion. The model classifies and acts; it doesn't re-derive the rubric each time. |
| **Structured per-skill report** | Exact schema (Pre-flight / Accepted / Deferred / Rejected / Build) prevents format improvisation across batch runs. |

**Steering Better Decisions**

**Claim verification first** — every Tessl suggestion is checked against the actual file before any edit. Tessl's content judge has documented biases (favors shorter skills, invents example CLI syntax). Treating the score as a target produces regressions; verifying each claim produces fixes.

**Categorical reject list** — "Trim Red Flags / anti-pattern guards" and "Remove placeholders Claude already knows" are pre-rejected by default. These are the two failure modes observed across a 33-skill batch: the LLM judge erodes anti-regression guards because it can't measure their value.

**Regression-risk check before any edit** — three explicit questions (cross-references? user-visible artifact? build-pipeline contract?) before touching the file. A "yes" or "unsure" on any one defers the edit. Prevents the common pattern of accepting an LLM suggestion that breaks downstream consumers.

**Watch the suggestion list, not the score** — explicit calibration note that the content judge is non-deterministic (±5 points) and additive fixes can lower the conciseness score. Chasing the score produces worse skills.

---

## Combined Effect

1. **Defensive rules** — explicit anti-patterns, skip constraints, gates, and budget caps that limit how much damage an autonomous agent can do
2. **Token discipline** — output routing, gated questions, and format templates that make sessions leaner without losing quality
