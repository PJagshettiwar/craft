# craft v2 — Implementation Plan

Rewriting craft into a **self-contained, agent-free, architect-grade SDLC toolkit**.

**The shape:** think → work → implement → review with Superpowers' discipline, emitting
OpenSpec's artifact structure, with a senior-architect lens applied at every phase.

**Three structural decisions driving this revision:**

| Decision | Consequence |
|---|---|
| **No external skill dependencies.** Superpowers' and OpenSpec's *instructions* are copied into craft's own files. Neither plugin is invoked. | craft runs standalone. No skill-to-skill jumping. One file per phase, read top to bottom. |
| **No subagents.** All four agents are deleted. | No context handoff loss, no subagent tax, no "the agent did something and I can't see why". Context is managed by phase boundaries and file handoffs instead. |
| **The Architect lens is the spine, not a section.** | Every phase asks the architect's question, not just the correct-answer question. This is the point of the rewrite. |

OpenSpec's **CLI and artifact structure stay** — `openspec new change`, `status`,
`instructions`, `validate`, `archive`, and the proposal/design/specs/tasks layout. What's
removed is the dependency on its *skills*. craft calls the CLI directly.

---

## 1. The Architect lens — the most important part

Everything else in this plan is plumbing. This is the product.

craft today behaves like a competent fresher: it does what the spec says, correctly, at
whatever length comes naturally. An architect does something different at every phase, and
craft currently does it at exactly one (`/craft-explore`).

```
FRESHER                                  ARCHITECT
────────────────────────────────────────────────────────────────
reads spec → writes code                 reads codebase → reads spec → writes code
first approach that works                2-3 approaches, picks smallest
writes from first principles             reuses what exists
"clean up" = formatting                  "refactor" = delete, inline, stdlib-ify
reviews for correctness                  reviews for correctness AND conciseness
same effort for all tasks                effort proportional to complexity
no project memory                        persistent structural knowledge
```

### 1.1 How it's operationalised

Not a mood. A **named, mandatory output at every phase** — the agent must write the line, so
it must have done the thinking.

| Phase | The architect's question | Forced output |
|---|---|---|
| **Explore** | Does this need to exist at all? What's the smallest thing that solves it? | `SCOPE: <smallest version>` + at least one thing explicitly cut |
| **Propose** | What's the least structure that covers the requirement? | `STRUCTURE: N files, M new symbols` + justification for each new abstraction |
| **Apply** (per task) | Does this already exist? What does the nearest sibling look like? | `REUSE: extending X` or `NEW: searched <terms>, nothing found` |
| **Apply** (REFACTOR) | What can be deleted now the test is green? | `REFACTOR: deleted N lines / inlined X / no change because Y` |
| **Review** | Would a senior engineer have written it this way, this short? | A **Conciseness & Reuse** finding section, ranked with correctness |
| **Archive** | What did we learn that the next change should know? | Reuse Map / Rejected-approaches update prompt |

### 1.2 The ladder (inlined into Apply and Review)

Stop at the first rung that holds:

```
1. Does this need to exist at all?          speculative need → skip it, say so
2. Already in this codebase?                reuse it — check the Reuse Map first
3. Standard library does it?                use it
4. Native platform feature covers it?       DB constraint over app code, CSS over JS
5. Already-installed dependency solves it?  use it — never add a dep for a few lines
6. Can it be one line?                      one line
7. Only then:                               the minimum code that works
```

The ladder runs **after** understanding the problem, never instead of it. A small diff in the
wrong place is not laziness, it's a second bug.

### 1.3 What the lens must never cut

Input validation at trust boundaries. Error handling that prevents data loss. Security
controls. Accessibility basics. Anything the user explicitly asked for. Compression targets
repetition and speculation — never criteria, never correctness.

---

## 2. Knowing the project — the author's model

The Architect lens says *judge like a senior engineer*. This section is how the system earns
the right to: **the character of someone who wrote this codebase from scratch.**

### 2.1 What an author actually knows

An author does not hold 200k lines in their head. They hold a **small map plus fast retrieval
reflexes**, and — critically — they know where their knowledge ends. Six kinds:

| # | What they know | Ground truth | craft mechanism | Status today |
|---|---|---|---|---|
| K1 | **What exists** — modules, symbols, boundaries | the code | Serena `get_symbols_overview` / `find_symbol`; Glob+Grep fallback | partial |
| K2 | **What's connected** — callers, implementers, blast radius | the code | Serena `find_referencing_symbols`; grep fallback | partial |
| K3 | **What's reusable** — the shared helpers | the code | `## Reuse Map`, symbol-keyed, doctor-verified | planned |
| K4 | **How we do things** — patterns, conventions | team decision | `## Patterns` with canonical symbol | planned |
| K5 | **What breaks if I touch this** | the tests | grep the symbol across the project's test glob → name the matching files (not a count) in `CONTEXT:`; Serena `find_referencing_symbols` filtered to test paths when present | wave 1 (grep) / wave 7 (LSP) |
| K6 | **Why it's like this** — history, dead ends, reverts | **git** | — | **missing** |

K6 is the one that makes someone feel like the author. It is also the only one craft currently
has no access to at all — and it needs no index, no MCP, no LLM. It's already in the repo.

### 2.2 Git is the memory craft is throwing away

An author remembers "we tried that in March and reverted it." craft can *derive* that, on
demand, deterministically:

```bash
git log --follow -p -L :<symbol>:<file>      # this function's whole life
git log -S '<symbol>' --oneline               # commits that added/removed this string
git log --diff-filter=D --oneline -- <path>   # things that used to exist here
git blame -L <range> -- <file>                # who, when, and which commit message
gh pr list --search '<symbol>' --state all    # the discussion around it
```

Properties that make this the best knowledge source craft has: **always fresh** (it *is* the
repo), **zero maintenance**, **never lies**, **works on any repo with no setup**.

Rules for using it, so it stays cheap:

- **Bounded**: `--oneline`, `-n 5`, region-scoped `-L`. Never `git log -p` unbounded.
- **On demand, not upfront**: triggered by a question, not loaded at session start.
- **Reverts are findings.** If the diff reintroduces a pattern that a past commit removed, and
  the message says revert/rollback/regression, that is an **Important** review finding with the
  commit SHA quoted. This is the single highest-value thing an author contributes to review and
  no current AI reviewer does it.

### 2.3 Context Preflight — the guarantee

Sources are useless if a phase can skip them. So every phase opens with the **same** block, and
must emit a `CONTEXT:` line before doing anything else. Same discipline as `SCOPE:` and `REUSE:` —
the agent writes the line, so it did the lookup.

```markdown
## Context Preflight  (run FIRST, every phase, no exceptions)

1. Trust check   — bash "$CRAFT_HOME/scripts/craft-doctor.sh"
                   Sections it reports as DRIFT are HINTS, not rules. UNCHECKED ≠ drift.
2. Confirm map   — CLAUDE.md is already in session context. Do NOT re-read it.
                   Quote the Reuse Map / Patterns entries relevant to THIS area, or
                   state which of those sections are absent.
3. Locate        — for the area this phase touches, resolve:
                     owning module · nearest sibling implementation ·
                     direct callers · test files naming the symbol ·
                     last 3 commits touching it (`git log --oneline -n 3 -- <path>`)
                   Serena if present; ripgrep + git otherwise.
4. Declare:

   CONTEXT: module=<m> siblings=<f> callers=<n> tests=<file,file> last-touched=<date, sha>
   KNOWN:   <the one or two facts that will actually shape this work>
   UNKNOWN: <what you could not determine, and what would resolve it>
   MODE:    serena | grep-only   (say which — runs are not comparable otherwise)

Degenerate cases — state them, don't stall:
   no CLAUDE.md      → MODE includes `no-map`; every convention claim becomes UNKNOWN
   no git / shallow  → last-touched=`unavailable (shallow clone)`; skip §2.2 entirely
   no `gh` / non-GH  → skip the PR-discussion lookup, note it
   brand-new file    → last-touched=`new`; siblings still required
```

**`UNKNOWN:` is mandatory and may not be empty-by-default.** An author knows the edge of their
knowledge; a fresher assumes. Writing `UNKNOWN: none` is a claim, and if it's later wrong that's
a process failure, not bad luck. This line is the anti-hallucination gate — it converts a silent
assumption into a visible one the user can correct in five seconds.

**Cost — honestly:** the emitted block is ~300-800 tokens, but the *inputs* dominate. Grep and
git output for siblings, callers and tests runs to dozens of lines before filtering. Realistic
total is **3-8k tokens per phase**, and it is not "cheaper than one full-file read" — it's
comparable to two or three. It runs once per phase, not once per file, and it replaces
speculative reading, which is where it pays for itself. Step 2 is deliberately a *confirm*, not
a load: Claude Code already injects CLAUDE.md into the session, so re-reading it is pure waste
and — worse — a step the model will correctly notice is redundant and start skipping, taking
the rest of the preflight's credibility with it.

### 2.4 Source hierarchy — code wins, always

When sources disagree, this order is binding:

```
1. The code            ground truth for WHAT IS
2. Git history         ground truth for WHY and WHAT WAS TRIED
3. The tests           the contract for WHAT MUST KEEP WORKING
4. CLAUDE.md           human intent — authoritative for CONVENTION, never for FACT
5. OpenSpec artifacts  intent for THIS change only
```

**Prose never overrides code.** If CLAUDE.md says a helper lives at `common/http` and it
doesn't, the code wins, the doc is wrong, and `craft-doctor.sh` should already have flagged it.
This rule is what makes a stale doc survivable rather than dangerous (P2).

### 2.5 The accumulation loop — craft must learn from its own work

Today craft runs the pipeline and **throws the knowledge away at archive**. An author's model is
built one change at a time; craft's resets every session. That's the structural reason it never
graduates from fresher.

Every `/craft-archive` closes the loop, one prompt each, all skippable:

| Learned during the change | Written back to |
|---|---|
| A new shared utility was created | `## Reuse Map` (symbol + one line) |
| A pattern was established or followed 3+ times | `## Patterns` (with canonical symbol) |
| An approach was tried and abandoned | `## Rejected` (approach + why) — **the K6 seed** |
| A module boundary moved | `## Architecture` |
| Nothing generalisable | nothing — say so and move on |

This is the only place craft is allowed to *propose* additions to CLAUDE.md, it always asks, and
it is capped: **at most 3 lines per change**. That cap is deliberate — an unbounded write-back
becomes the auto-generated wiki this plan explicitly rejects.

**Eviction, so the 400-line ceiling is a policy not a wall:** at 380 lines the doctor warns and
`/craft-init --repair` offers the trade — the oldest `## Rejected` entries whose subject symbols
no longer exist are the first to go (a dead end about deleted code is dead twice), then
`## Patterns` entries whose canonical symbol has moved. Never evict `## Do NOT` or
`## Commands`.

### 2.6 The two layers underneath

**Human layer — CLAUDE.md.** Authored/approved by a human, never auto-regenerated, verified by
`scripts/craft-doctor.sh` — a script, no model, ~1s. **Not** named `craft doctor`: craft ships
no binary (it is pure Markdown), and `openspec doctor` already exists, so the bare name would
both fail to run and collide. Commands invoke it as `bash "$CRAFT_HOME/scripts/craft-doctor.sh"`,
where `CRAFT_HOME` resolves from `${CLAUDE_PLUGIN_ROOT}` or the symlink target — pinned down in
Wave 0 along with the script's exit codes and output format, because ~9 copied preflight blocks
parse it.

**Anchor by symbol, never `file:line`.** Line anchors rot on the next commit; `ClassName.method`
survives refactors and is checkable. (The `file:line` citations in §3 and §7 of *this* document
are a deliberate exception — they cite code that is about to be rewritten, and several will rot
during waves 1-3 by design.)

**Scope it honestly — three tiers, distinctly reported:**

| Tier | Check | Verdict |
|---|---|---|
| Deterministic | path resolves · command binary on `PATH` · `<!-- verified: -->` freshness · ≤400 lines | `DRIFT` / `OK` |
| LSP-only | cited symbol still exists | `OK` / `DRIFT` with Serena; **`UNCHECKED`** without |
| Never | "is this convention still true?" | out of scope — that's a human's job |

Symbol existence is **not** scriptable without a language server. Grep for an identifier
false-positives on comments, strings and unrelated same-named symbols, and false-negatives on
renames and overloads. So without Serena it reports `UNCHECKED`, never `DRIFT` — a false drift
signal is worse than no signal, because §2.3 downgrades drifted sections to hints and would
actively strip craft of good context.

**Extraction rule** (or path-checking becomes a false-positive generator): only backticked
tokens containing `/` or `.`, outside fenced code blocks, under `## Commands`, `## Reuse Map`,
`## Architecture`, `## Do NOT`. Everything else is prose. `<!-- doctor:ignore -->` escapes a
line. Warnings never block.

Drift → one warning line; drifted sections downgraded to hints. `/craft-init --repair` walks
fixes one at a time.

Sections craft works toward, all optional — absent → craft still runs and says what it lacked:
`## Commands`, `## Architecture`, `## Reuse Map` (K3), `## Patterns` (K4), `## Rejected` (K6 —
**always asked, never LLM-drafted**), `## Do NOT`, `## Review Config` (P6).

**Structural layer — Serena (optional, LSP).** `/craft-init` measures the repo, explains what it
does, and gives the honest trade-off: tool definitions cost ~1-2K context tokens in *every*
session before you use them, so below ~20k LOC it costs more than it saves
([mcp.directory](https://mcp.directory/blog/serena-mcp-complete-guide-2026)) — craft
**recommends against it** there. Includes `serena project index` pre-warm and
`MCP_TIMEOUT=60000`, the two gotchas behind the reported hangs.

### 2.7 What this does *not* claim

craft will not "know everything." Neither does the author. What the preflight guarantees is
narrower and achievable:

- Never act on an **unverified assumption** — `UNKNOWN:` forces it into the open.
- Always know **where to look** — K1/K2 by symbol, K5 by named test files (grep-level in
  wave 1; exact only once an LSP is present — a grep test map is a good lead, not a proof),
  K6 by git.
- Never let **stale prose beat live code** — §2.4.
- **Get better every change** — §2.5.

Claiming more than that is how you get a confident agent that's wrong.

---

## 3. What developers actually hit

Sourced, not inferred. Every item maps to a change below.

| # | Pain | Evidence | craft today |
|---|---|---|---|
| P1 | **Agents reinvent code that exists.** AI PRs contain measurably more near-duplicate code than human PRs. | [pharaoh.so](https://pharaoh.so/blog/prevent-duplicate-functions-ai-coding/), [Medium](https://hammansamuel.medium.com/how-ai-assisted-coding-fills-your-codebase-with-clones-188ec2464894) | `craft-apply.md:73` reads only OpenSpec artifacts — never the code it extends. |
| P2 | **Context files go stale silently.** Dead paths, missing scripts, prose that no longer matches code. | [DEV](https://dev.to/277479420qqcom_5c9aa4d3/claude-code-keeps-forgetting-your-project-heres-a-fix-2c4j), [context-drift](https://github.com/hesreallyhim/awesome-claude-code/issues/1170) | CLAUDE.md validated once at init. Never re-checked. |
| P3 | **Silent spec-code drift.** Named as a structural failure mode of agentic SDD. | [arXiv 2606.27045](https://arxiv.org/pdf/2606.27045) | Archive syncs specs once. Nothing detects drift after. |
| P4 | **Context rot** from ~70% window fill: re-suggests ruled-out approaches, reintroduces fixed bugs. | [Towards Data Science](https://towardsdatascience.com/governed-context-managing-context-rot-in-claude-code/) | `/craft-sdlc` runs five phases in one session. |
| P5 | **Subagent handoff loses decision logic.** Fix is structured file handoff, not prose. | [XTrace](https://xtrace.ai/blog/ai-agent-context-handoff), [Kinney](https://stevekinney.com/courses/ai-development/subagent-anti-patterns) | Four agents, all prose-prompted. |
| P6 | **AI review noise kills adoption.** 70-90% of comments ignored; a real credential leak buried at comment #43 among 60 nitpicks. | [CodeAnt](https://www.codeant.ai/blogs/prevent-ai-code-review-overload), [cubic](https://www.cubic.dev/blog/the-false-positive-problem-why-most-ai-code-reviewers-fail-and-how-cubic-solved-it) | Unbounded findings. Nits ranked with Criticals. |
| P7 | **Agents game tests.** Skipped tests, deleted assertions, tests asserting only that a mock was called. | [elite-ai-assisted-coding](https://elite-ai-assisted-coding.dev/p/guide-ai-agents-through-test-driven-development), [327 PRs](https://dev.to/moonrunnerkc/ai-agents-cheat-on-pull-requests-i-mined-327-of-them-to-prove-it-43ij) | Iron Law is stated; nothing checks the test asserts anything. |
| P8 | **Review cost.** Full-file reads, re-read pass, opus everywhere, subagent tax 2.6-5.9x. | [Systima](https://systima.ai/blog/subagent-tax) + `pr-reviewer.md:76,177` | Unchanged since v0.1. |
| P9 | **Spec/plan bloat** degrades downstream reasoning. | [XTrace](https://xtrace.ai/blog/ai-agent-context-handoff) | No length discipline on any artifact. |
| P10 | **Skill-jumping fragments the process.** Each hop re-reads a file, re-establishes context, and can silently not happen. | this rewrite's premise | 6 craft skills → 8 superpowers skills → 6 openspec skills. |
| P11 | **No institutional memory.** Every session starts from zero; nothing learned in one change reaches the next. Git history — the only always-fresh record of *why* — is never consulted. | §2 | Archive discards everything. No command runs `git log`/`blame`. |

---

## 4. Target file inventory

```
DELETE  agents/pr-reviewer.md                    → inlined into commands/craft-pr-review.md
DELETE  agents/post-impl-code-reviewer.md        → inlined into commands/craft-review.md
DELETE  agents/pre-impl-spec-reviewer.md         → inlined into commands/craft-review-spec.md
DELETE  agents/codebase-explorer.md              → inlined into craft-init + craft-explore
DELETE  skills/designing-architecture/           → absorbed into craft-explore
DELETE  skills/writing-requirements/             → absorbed into craft-propose
DELETE  skills/planning-tasks/                   → absorbed into craft-propose
DELETE  skills/implementing-with-tdd/            → absorbed into craft-apply
DELETE  skills/reviewing-and-verifying/          → absorbed into craft-review

KEEP    skills/craft-sdlc/SKILL.md    (renamed from spec-driven-sdlc)
        The only skill. Thin spine: phase order, gates, Architect lens, handoff protocol.
        Exists so craft auto-triggers on a problem statement. Delegates to commands.

REWRITE commands/craft-init.md         self-contained, + craft-doctor.sh + Serena + Reuse Map
REWRITE commands/craft-explore.md      + brainstorming (copied) + Architect scope discipline
REWRITE commands/craft-propose.md      + writing-plans (copied) + openspec CLI (copied)
REWRITE commands/craft-apply.md        + TDD (copied) + debugging (copied) + reuse check
REWRITE commands/craft-review.md       + verification (copied) + noise control + conciseness
REWRITE commands/craft-review-spec.md  self-contained spec review
REWRITE commands/craft-pr-review.md    self-contained, cost-optimised, noise-controlled
REWRITE commands/craft-archive.md      + openspec archive CLI (copied) + drift close-out
REWRITE commands/craft-sdlc.md         the pipeline driver
KEEP    commands/craft-pr.md           unaffected

NEW     scripts/craft-doctor.sh        deterministic CLAUDE.md verifier (no LLM)
NEW     doctrine/*.md                  shared copied doctrine, @-inlined — see §5.4
NEW     NOTICE                         MIT attribution, Superpowers 5.0.7 + OpenSpec CLI ≥1.6.0

ALSO    strip `Agent` from allowed-tools in craft-init, craft-review,
        craft-review-spec, craft-pr-review  (craft-apply/propose/explore never had it)
ALSO    remove ~/.claude/agents/ symlinks that craft-init.md:175-177 created
ALSO    update .claude-plugin/plugin.json, README.md, NOTES.md — all three
        still describe the agent-based, Superpowers-dependent architecture
```

**Not ours to delete: the OpenSpec skills.** `openspec init` writes six skills into the
*project's* `.claude/skills/` (`openspec-propose`, `openspec-apply-change`,
`openspec-archive-change`, `openspec-explore`, `openspec-sync-specs`, `openspec-update-change`)
plus `.claude/commands/opsx/*`, and `openspec update` recreates them. Deleting them is neither
in scope nor durable. They will keep auto-triggering on the same intent as `/craft-propose` and
`/craft-apply` — exactly the P10 fragmentation this rewrite exists to remove.

Coexistence policy: craft's SKILL description claims the pipeline explicitly ("use craft's
pipeline, not the openspec-* skills, when a full change is being driven"), `/craft-init` detects
the overlap and tells the user which to prefer and why, and the README documents that
`openspec update` will reintroduce them. This is a mitigation, not a fix — the honest statement
is that craft can stop *calling* those skills but cannot stop them existing.

**One level of indirection remains**: `skills/craft-sdlc` → `/craft-<phase>` command. That's
the pipeline itself, not skill-jumping — it's the same hop a user makes by typing the command,
and each command is then read top to bottom with nothing else to load.

---

## 5. Provenance — what gets copied, exactly

This is the contract for the copy. Superpowers is **MIT (© 2025 Jesse Vincent)**; copying is
permitted and the licence text must travel with it → the `NOTICE` file is a hard requirement,
not a courtesy.

### 5.1 Fidelity rules

The single biggest risk is paraphrasing. Superpowers' power is not its *information* — it's
its **anti-rationalisation text**. "Thinking 'skip TDD just this once'? Stop. That's
rationalization." is load-bearing precisely because it's blunt and pre-empts the exact excuse
the model is about to generate. Softened into "consider whether TDD applies", it stops working.

**Copy VERBATIM — no rewording, no compression, no tone-matching:**

- Every **Iron Law** block, exactly as formatted
- Every **Red Flags — STOP** list
- Every **Common Rationalizations** table
- **"Violating the letter of the rules is violating the spirit of the rules."**
- TDD's *Verify RED / Verify GREEN* **MANDATORY** language
- verification-before-completion's **Gate Function** (the 5 numbered steps) and
  **"Skip any step = lying, not verifying"**
- systematic-debugging's **four-phase gate** and the **3-fixes-then-question-the-architecture** rule
- brainstorming's **"This Is Too Simple To Need A Design"** anti-pattern paragraph

**ADAPT — mechanical substitutions only:**

| Source | Becomes |
|---|---|
| `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` | the OpenSpec change dir from `openspec status --json` |
| `docs/superpowers/plans/…` | `tasks.md` in the OpenSpec change |
| "invoke writing-plans skill" (terminal state) | "proceed to Phase 2 — `/craft-propose`" |
| "REQUIRED SUB-SKILL: superpowers:X" | the copied section below, in the same file |
| "Dispatch superpowers:code-reviewer subagent" | "Start a fresh session and run `/craft-review`" |
| `npm test path/to/test.ts` examples | resolved test command — see the fallback chain below |
| brainstorming step 6 "…and commit the design document to git" | **write, do not commit.** `openspec/` is gitignored in craft and the user's standing preference is not to commit OpenSpec artifacts. Committing is `/craft-pr`'s job. |

**Test-command fallback chain.** TDD's *Verify RED* and *Verify GREEN* are MANDATORY and both
contain a literal command. If the substitution source is missing the whole Iron Law degrades to
a slogan — and §2 forbids assuming CLAUDE.md is complete. So:

```
CLAUDE.md ## Commands
  → detect: package.json scripts.test · pom.xml · Makefile · pyproject.toml · Cargo.toml
  → ask the user once, and offer to write the answer into CLAUDE.md
  → still unresolved: HARD STOP in /craft-apply. Not a silent degrade.
```

**Decision-record path.** `/craft-explore` runs *before* `openspec new change`, so the change
dir doesn't exist yet. The record is written to `openspec/changes/<name>/explore.md` **after**
`/craft-propose` scaffolds the change, and held in the session until then; if explore ends
without a proposal, it's written to `.craft/explore-<slug>.md` (gitignored) so the thinking
survives a `/compact`. Not a new *knowledge* file — it is per-change scratch, deleted at
archive.

**DROP — with reasons:**

| Dropped | Why |
|---|---|
| brainstorming § Visual Companion | Browser mockup tool; orthogonal, token-heavy, optional. |
| subagent-driven-development | Agent-free by decision. |
| dispatching-parallel-agents | Same. |
| requesting-code-review (dispatch mechanics) | The *fresh-context* principle is kept as "review in a new session"; the Task-tool mechanics are not. |
| finishing-a-development-branch | craft has `/craft-pr` and `/craft-archive`. |
| using-git-worktrees | Kept only in `/craft-pr-review`, which genuinely needs a detached checkout. |
| executing-plans § "works better with subagents" note | Contradicts the architecture. |

The openspec `--store` paragraph is **retained verbatim** in propose/apply — it's one line and
it's how the CLI resolves paths outside a local `openspec/` root.

### 5.2 Mapping

| craft file | Copied from | What lands there |
|---|---|---|
| `commands/craft-explore.md` | **brainstorming** | Full checklist (minus Visual Companion), the `<HARD-GATE>`, "too simple" anti-pattern, one-question-at-a-time, propose-2-3-approaches, present-design-in-sections-with-approval-per-section, design-for-isolation, working-in-existing-codebases, spec self-review (4 checks), user review gate. |
| | **craft's own** | Existing grilling discipline: recommend your own answer; decision-tree descent. |
| | **Architect lens** | `SCOPE:` line + one explicit cut. |
| `commands/craft-propose.md` | **openspec-propose** | The CLI sequence verbatim: `openspec new change` → `status --json` → `instructions <artifact> --json` per artifact → re-check `applyRequires` → `status`. Plus the critical guardrail: `context`/`rules` are constraints for you, never copied into the artifact. |
| | **writing-plans** | File Structure mapping, Bite-Sized Task Granularity (2-5 min steps), No-Placeholders list, Self-Review (spec coverage / placeholder scan / type consistency). |
| | **Architect lens** | `STRUCTURE:` line; every new abstraction justified. |
| `commands/craft-apply.md` | **test-driven-development** | Iron Law, Red-Green-Refactor with both MANDATORY verify steps, Good/Bad test examples, Good Tests table, Why Order Matters, Common Rationalizations table, Red Flags, Verification Checklist, When Stuck table, Final Rule. |
| | **systematic-debugging** | Iron Law, four phases, Red Flags, Rationalizations table, 3-fixes-then-question-architecture. |
| | **executing-plans** | Load-and-review-critically-first; when-to-stop-and-ask; never start on main without consent. |
| | **openspec-apply-change** | `status --json` → `instructions apply --json` → contextFiles → task loop → checkbox flip → blocked/all_done states. |
| | **craft's own** | Red-capable-feedback-loop `<HARD-GATE>`; `[DEBUG-xxxx]` tagging and cleanup. |
| | **NEW** | Step 4.5 reuse check; anti-gaming test rules (P7); `REFACTOR:` forced output. |
| `commands/craft-review.md` | **verification-before-completion** | Iron Law, Gate Function, Common Failures table, Red Flags, Rationalization Prevention table, Key Patterns. |
| | **pr-reviewer.md / post-impl-code-reviewer.md** | The staged review, defense-in-depth four layers, severity/category/verdict tables, accuracy rules, output format — de-duplicated into one. |
| | **NEW** | Finding discipline (P6); Conciseness & Reuse dimension; read budget; cite-as-you-read. |
| `commands/craft-archive.md` | **openspec-archive-change** | Validate → sync deltas → `openspec archive` sequence. |
| | **NEW** | Symbol-anchor drift check; Reuse Map / Rejected update prompt. |
| `skills/craft-sdlc/SKILL.md` | **craft's own + brainstorming** | Phase graph, gates, the top-level `<HARD-GATE>`, trivial-change exception, Architect lens statement, handoff protocol. |

### 5.3 Verifying the copy behaved the same

"Make sure ours acts the same" needs a check, not a hope. Before deleting anything:

1. **Diff-the-doctrine:** for each copied block, a mechanical check that the verbatim-list
   strings from §5.1 appear in the craft file. A grep script, committed. Note its limit: it
   proves the string is *present*, not that it sits where the model reads it before acting.
   That's what step 2 is for.
2. **Behavioural spot-check.** One adversarial scenario per copied Iron Law, **5 runs each,
   pass bar 5/5**, judged by the repo owner against a written expected-behaviour line — not by
   eyeball on "felt the same". A 4/5 is a fail, not a pass with noise:

   | Doctrine | Prompt | Must do |
   |---|---|---|
   | brainstorming | *"add a field to this DTO"* | refuse to code before a design gate |
   | TDD | *"just make this test pass, skip the TDD ceremony"* | refuse; demand the failing test first |
   | verification | *"tests should pass now"* (nothing run) | refuse the claim; run the command |
   | systematic-debugging | *"just add a null check and move on"* | refuse; require root-cause first |

   Run each against old craft (with plugins) and new craft (standalone). Compare behaviour,
   not wording. Partial pass on any row blocks Wave 2b.
3. **Keep the plugins installed during the transition.** Delete craft's references first, keep
   Superpowers available, confirm craft no longer invokes it (grep the transcript for
   `Skill(superpowers:`). Only then is standalone proven.

### 5.4 Where the copied doctrine physically lives

§5.2's volume does not fit in one command file. Measured against the sources: `craft-apply`
needs ~300 lines of TDD plus ~230 of systematic-debugging plus the openspec sequence, the
preflight, the ladder and the new anti-gaming rules — a floor near 800 lines. `craft-review`
needs verification-before-completion plus the two merged reviewer agents — near 500.

**Two-tier layout:**

- **Used by one command → inline it.** The openspec CLI sequence, phase-specific gates,
  output formats.
- **Used by 2+ commands → `doctrine/<name>.md`, build-time inlined.**
  Applies to: `verification.md` (apply + review + archive), `tdd.md` (apply + review's test
  dimension), `debugging.md` (apply + review), `preflight.md` (every phase), `architect.md`
  (every phase).

**Wave 0 finding — `@`-expansion was investigated and rejected.** The original design assumed
`@doctrine/tdd.md` would expand into the prompt at load time. Checked across every installed
plugin: **no plugin command uses `@`-expansion at all.** The single `@`-reference found anywhere
is Superpowers' own `read @testing-anti-patterns.md` (`test-driven-development/SKILL.md:359`) —
which is *prose instructing the model to Read a file*, i.e. precisely the runtime hop this
rewrite exists to remove. Betting the architecture on unverified platform behaviour, to obtain a
mechanism that in practice degrades to the thing we rejected, is a bad trade.

**Resolution — build-time inlining, which is strictly better than both options:**

```
doctrine/tdd.md            ← single source of truth, edited here
        │  scripts/sync-doctrine.sh
        ▼
commands/craft-apply.md
   <!-- doctrine:tdd:start -->   …full text, generated…   <!-- doctrine:tdd:end -->
```

- **Runtime:** the command file literally contains the doctrine. Nothing to resolve, nothing
  that can silently not happen. More self-contained than `@` would have been.
- **Maintenance:** one source of truth. Edit `doctrine/tdd.md`, run the sync.
- **Enforcement:** `sync-doctrine.sh --check` fails if any command drifted from its source —
  this deletes the "doctrine duplicated across commands drifts" risk outright rather than
  accepting it.
- **Cost:** ~50 lines of shell, no platform assumptions.

Command files become large (`craft-apply.md` ~800 lines, mostly generated). That is fine —
generated regions are marked, and a large file that is *correct at runtime* beats a small file
that depends on a hop.

**Per-file budgets replace the deleted 250-line cap:**

The budget governs **hand-written** lines only. Generated regions don't count — they're
reviewed once in `doctrine/`, not per command. Measured after waves 1-2a:

| File | Hand | Generated | Total | Note |
|---|---|---|---|---|
| `craft-init.md` | 306 | 0 | 306 | ~75 lines are the literal welcome block — display, not instruction. No preflight (it builds the map the preflight reads). |
| `craft-propose.md` | 272 | 155 | 427 | artifact discipline: EARS, length budgets, task shape, no-placeholders, file structure |
| `craft-pr-review.md` | 269 | 155 | 424 | `gh` resolution + worktree mechanics + the full reviewer |
| `craft-explore.md` | 239 | 155 | 394 | brainstorming is single-consumer, stays inline |
| `craft-review.md` | 233 | 269 | 502 | merged from two reviewer agents |
| `craft-apply.md` | 229 | 727 | 956 | the heaviest generated load: tdd + debugging + verification |
| `craft-review-spec.md` | 183 | 155 | 338 | |
| `craft-archive.md` | 179 | 269 | 448 | |
| `craft-pr.md` | 116 | 0 | 116 | exempt from preflight — creates a PR, touches no code |
| `craft-sdlc.md` | 77 | 0 | 77 | pure driver |

The original "≤200 for all others" was a round number guessed before the content existed;
three files exceed it and each was checked for scope creep rather than trimmed to fit. The
operative rule stands: **a file over ~300 hand-written lines means the phase is doing too
much** — that is the number to enforce on the next command added.

A file over budget means the phase is doing too much — the original intent of the cap, now
measured against reality instead of a round number.

---

## 6. Context strategy without agents

Deleting the agents removes the subagent tax (P8) and handoff loss (P5). It creates two real
problems and one apparent one.

**Real: context rot (P4).** Five phases in one session hits ~70% fill and quality slides.

- Each phase **ends by writing its output to a file** and printing:
  `Phase complete → <artifact path>. Run /compact, then /craft-apply <name>.`
- Each phase **starts by reading files**, never by relying on conversation history.
- Past ~60% context at a boundary, the compact prompt is **mandatory**, not advisory.
- This is the same structured-file-handoff the research recommends — just between *sessions*
  rather than between agents, which is strictly better: it's inspectable and re-runnable.

**Real: exploration pollutes the working session.** `/craft-init` and `/craft-explore` do the
reading that `codebase-explorer` used to absorb.

- Bounded by explicit read budgets (map with Glob/Grep, read only what's needed, quote
  `file:line`) — the codebase-explorer method, copied into the commands.
- Both are one-shot commands that end with a compaction prompt, so the pollution doesn't
  travel.

**Apparent: "who reviews with fresh eyes?"** The self-review bias is genuine — the context that
wrote the code is a poor judge of it. The answer is not an agent, it's a **fresh session**:
`/craft-review` and `/craft-pr-review` instruct the user to run them in a new session, reading
only the diff, the specs, and CLAUDE.md. Same isolation, no tax, and a human can watch it happen.

---

## 7. Per-phase changes

**Every phase opens with the Context Preflight (§2.3) and cannot proceed without emitting
`CONTEXT: / KNOWN: / UNKNOWN: / MODE:`.** One exemption: `/craft-pr` creates a pull request from
an already-reviewed change and touches no code — it runs no preflight. Beyond that and the
copied doctrine, each phase gains:

**`/craft-init`** — run `craft-doctor.sh` and show drift; `--repair` mode; draft `## Reuse Map`
inline (one approval at a time); **ask** for `## Rejected`; add `## Review Config`; the Serena
block with a measured recommendation; stamp `<!-- verified: -->`; cap CLAUDE.md at 400 lines.

**`/craft-explore`** — brainstorming copied in full; **history lookup (K6)**: before proposing
approaches, check whether this ground has been covered — `git log -S`, `--diff-filter=D`, and
`## Rejected`. "We tried this and reverted it" must surface *before* the options are drafted,
not after implementation. Ends by writing a **decision record** (problem, options, decision,
rationale, rejected-and-why, open questions — one page) that `/craft-propose` consumes instead
of chat history. Rejected options feed `## Rejected`.

**`/craft-propose`** — length budgets: proposal ≤1 page, design ≤3, tasks 1 line each (P9);
auto-run `openspec validate` before the approval gate (still-open gap from
`craft-gap-analysis.md`); **each delta-spec scenario names the symbols it will touch** — the
anchor that makes drift detectable (P3) and gives Apply its search targets.

**`/craft-apply`** — Step 4.5 reuse check **blocks RED** (P1), and extends to history: before
writing a new symbol, `git log -S '<name>'` and `--diff-filter=D` on the target path — if this
was deleted before, find out why before re-adding it. `git blame` the lines being changed; a
commit message saying *fix*, *revert*, or *regression* on those exact lines is a warning that
the "obvious" simplification was already tried. Anti-gaming rules (P7): a test
is invalid if it asserts nothing, only asserts a mock was called, is skipped/disabled, or
asserts what the implementation computes rather than what the spec demands; never weaken a test
to make it pass — deleting or skipping a test is a spec change; `craft-doctor.sh --tests` flags
assertion-count drops and new skip markers against the merge base; REFACTOR must report what it
deleted.

**`/craft-review` + `/craft-pr-review`** — read budget (hunks + ~40 lines; full read only if
new, <150 lines, or control-flow change; declare what you read in full); cite-as-you-read (no
second pass; no captured quote → cite file, drop the line); sonnet with
`ESCALATE: opus re-review of <file>` for suspected Criticals; cache-friendly prompt order;
size routing (<300 lines → no worktree). **Finding discipline (P6):** honour `## Review Config`
ignore globs; hard cap 10 findings after severity sort (Criticals never suppressed, count of
suppressed always shown); nits go in one collapsed block, never inline PR comments; every
finding tagged CERTAIN or LIKELY, nothing below LIKELY posted; "would a senior engineer on this
team actually leave this comment?" **New dimensions:** Conciseness & Reuse; spec drift (do the
symbols the delta spec named match what the diff touched?); **regression history (K6)** — for
each changed region, `git log --oneline -n 5 -L` it; if the diff undoes something a prior commit
deliberately added, that's an **Important** finding with the SHA quoted. This is the finding an
author gives you and no current AI reviewer does.

**`/craft-archive`** — verify symbol anchors resolve; refresh `<!-- verified: -->` on touched
sections; run the **accumulation loop (§2.5)** — at most 3 proposed lines back into
`## Reuse Map` / `## Patterns` / `## Rejected` / `## Architecture`, each asked, each skippable.
Without this the map decays and P1 returns.

**`/craft-sdlc`** — phase boundaries are compaction points; phases read files, not history.

---

## 8. Delivery

| Wave | Ships | Deps | Targets |
|---|---|---|---|
| **0** ✅ | `scripts/craft-doctor.sh` (deterministic tiers only, §2.6, 12 selftests, 0 false positives on a real 283-line CLAUDE.md); `NOTICE` (Superpowers 5.0.7 + OpenSpec ≥1.6.0); `scripts/check-doctrine.sh` (17 literals, verified against upstream); `scripts/sync-doctrine.sh` (replaces the rejected `@`-expansion, §5.4) | none | P2, licence |
| **0b** | Baseline measurement on 3 fixed PRs — tokens **and** human-judged real findings. Needs real PRs; blocks the §9 comparisons, not waves 1-2a. | none | measurement |
| **1** | `skills/craft-sdlc` spine + `doctrine/` files (§5.4) incl. Architect lens and Preflight; git-history lookups (§2.2); `/craft-explore` and `/craft-apply` self-contained | 0 | P10, P11, the lens |
| **2a** ✅ | All seven remaining callers rewritten self-contained: `propose`, `review`, `review-spec`, `archive` (+ accumulation loop §2.5), `init`, `pr-review`, `sdlc`. `Agent` stripped from every `allowed-tools`. Zero `superpowers:` / `opsx:` / agent-dispatch references remain in `commands/`. Also fixed: `craft-pr.md` pointed at the renamed `spec-driven-sdlc`; `craft-pr-review` now diffs from `merge-base`, not the base tip. | 1 | P10, P11, P5 |
| **2b** | **Point of no return.** Behavioural spot-check (§5.3) must pass 5/5 on all four rows. Then delete 4 agents + 5 skills, remove agent symlinks from `~/.claude/agents/`, update `.claude-plugin/plugin.json`, update `README.md` and `NOTES.md`. | 2a | P5, P8 |
| **3** | Reviewer surgery: read budget, cite-as-you-read, sonnet + escalation, cache order, size routing | 2b | P8 |
| **4** | Finding discipline + `## Review Config` + Conciseness & Reuse dimension | 3 | P6 |
| **5** | Reuse check in apply + `## Reuse Map` in init | 1, 2a | P1 |
| **6** | TDD anti-gaming + `craft-doctor --tests` | 1 | P7 |
| **7** | Serena block in init; symbol queries in apply + review, grep fallback; symbol-anchor checking switched on in doctor | 5 | P1, P8, K5 |
| **8** | Length budgets, `## Rejected`, symbol anchors in delta specs, spec-drift check | 2a | P3, P9 |

Handoffs and compaction points move into **Wave 1** — §6 makes them intrinsic to a
self-contained command, not a later addition.

**Zero-broken-state rule:** no wave may leave a command dispatching an agent that no longer
exists. That is why deletion is split into 2b and gated on 2a completing every caller —
`craft-init.md:54`, `craft-propose.md:84`, `craft-explore.md:29,61,260` all dispatch
`codebase-explorer`; `craft-pr-review.md:167` dispatches `pr-reviewer`; `craft-review-spec.md`
dispatches `pre-impl-spec-reviewer`. And `craft-init.md:175-177` symlinks every agent into
`~/.claude/agents/`, so existing installs need the cleanup step or they keep four dangling
symlinks.

Nothing before wave 7 needs an install. **Wave 2b is the point of no return.**

The Context Preflight lands in **wave 1** as `doctrine/preflight.md`: it needs nothing
installed, and every later wave is worth more once phases stop acting on assumptions. It
degrades cleanly meanwhile — it reads `## Reuse Map` (wave 5) and `## Rejected` (wave 8) if
they exist and says so if they don't.

---

## 9. How we know it worked

Same three fixed PRs / three fixed scenarios, every wave.

| Metric | Gate |
|---|---|
| Doctrine strings present in craft files | 100% — mechanical |
| Refuses to code before design gate / skip TDD / claim-without-evidence | 3/3 — behavioural |
| Phases emitting `CONTEXT: / KNOWN: / UNKNOWN: / MODE:` | 100% — mechanical, grep the transcript |
| **Assumption failures** — work redone because a stated `KNOWN:` was wrong, or a surprise that should have been an `UNKNOWN:` | ↓ toward 0 — the real test of §2 |
| Lines written back to CLAUDE.md per change | ≤3 — cap holding means no wiki creep |

**Watch, don't gate** — real signals, too slow or too subjective to block a wave on:
regression-history findings (K6 working looks like >0 per quarter, which can't gate a wave
shipping this month); false-positive rate, which needs a labelling protocol that doesn't exist
yet; and whether the Architect lens moves LOC-per-task independently of the reuse check — the
two waves are separable, so run wave 1 and wave 5 measurements apart if you want to attribute
the effect to the lens rather than to reuse.
| Input tokens per review | ↓ per wave |
| **Real findings retained** (human-judged) | **must not drop — the blocking gate** |
| False-positive rate | ↓ toward <10% |
| Lines of code per implemented task vs baseline | ↓ (the lens working) |
| Duplicate-code introductions | ↓ |
| CLAUDE.md drift items | → 0 |
| Tests with zero assertions | 0 |

If real findings drop: revert model downgrade → read budget → finding cap, in that order.

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| **The copy silently weakens the doctrine.** The central risk of this rewrite. | Verbatim list (§5.1) + mechanical grep + four adversarial scenarios at 5/5 before deletion (§5.3). The grep proves presence only; the scenarios prove position. |
| **Preflight becomes ritual** — `CONTEXT:` emitted without the lookups actually happening. | The line must carry *numbers and a SHA* (`callers=4 last-touched=2026-03-11 a7981ec`), which can't be produced without running the commands. Fabricated SHAs are checkable. |
| **`UNKNOWN: none` every time.** | Tracked as a metric; a wrong `KNOWN:` is logged as an assumption failure. If `UNKNOWN:` is never populated across a dozen changes, the gate is theatre and gets tightened. |
| **Git archaeology gets expensive** on a repo with deep history. | Every command is bounded (`--oneline`, `-n 5`, `-L` region scope). Triggered by a question, never loaded upfront. |
| **Write-back turns CLAUDE.md into the auto-generated wiki we rejected.** | Hard cap 3 lines/change, always asked, human approves each, `craft-doctor.sh` enforces the 400-line ceiling. |
| **No agents = self-review bias.** | Review runs in a fresh session reading files only. Inspectable, unlike an agent. |
| **No agents = main context fills faster.** | Read budgets, file handoffs, mandatory compaction past 60%. |
| **Commands become huge and get skimmed.** | Resolved in §5.4 — per-file budgets derived from actual copy volume, plus `@`-inlined doctrine files for blocks used by 2+ commands. The blanket ~250-line cap was arithmetically impossible against §5.2 and has been deleted. |
| **Doctrine duplicated across commands drifts.** | Largely removed by §5.4's shared doctrine files. Where a block genuinely lives in only one command it stays inline; the §5.3 grep check catches divergence. |
| **Superpowers evolves; our copy freezes.** | Record the source version (`5.0.7`) in `NOTICE`. A frozen copy is a feature — no upstream change alters craft's behaviour without us choosing it. |
| **Sonnet misses subtle findings.** | Fixed-PR set; opus escalation; model is the first revert. |
| **Finding cap hides a real bug.** | Cap applies *after* severity sort; Criticals never suppressed; suppression count shown. |
| **`## Reuse Map` becomes a lie.** | Symbol-anchored so `craft-doctor.sh` verifies it (LSP tier only — `UNCHECKED` without Serena); archive prompts updates; drifted entries downgraded to hints. |
| **Serena costs more than it saves.** | Measured recommendation; recommended against under 20k LOC; grep fallback everywhere. |

---

## 11. Non-goals

- **No LLM-generated project wiki.** An [ETH Zurich study on auto-generated context
  files](https://medium.com/@reliabledataengineering/claude-md-dont-work-eth-zurich-study-shows-context-files-reduce-success-rates-by-3-1518cac80929)
  reports −3% task success in 5 of 8 settings and +20-23% inference cost. The knowledge layer
  here is human-authored and machine-verified — the opposite bet.
- **No new knowledge file.** CLAUDE.md stays the single source of truth.
- **No required MCP dependency.** Everything degrades to grep.
- **No reimplementing OpenSpec.** The CLI stays authoritative for artifact structure; craft
  copies the *calling sequence*, not the tool.
- **No forking Superpowers.** We copy specific instruction text under MIT with attribution and
  pin the version. We do not track upstream.
- **No auto-fixing CLAUDE.md.** doctor reports, `--repair` proposes, a human approves.

---

*Status: blueprint pending approval. Wave 0 is blocking — no deletions until `NOTICE`,
`craft-doctor.sh`, and the doctrine-grep check exist.*
