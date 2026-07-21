# AGENTS.md — generic spec-driven SDLC

Always-on operating rules for any AI coding agent (Claude Code, Cursor, Copilot, …) working in
this repo. Cursor and Copilot read this file natively; Claude Code reads it via a CLAUDE.md
`@import` set up by `/init`.

## How to work here
When given a problem statement, follow the **spec-driven SDLC pipeline**. Do not jump straight to
code. Read `PROJECT.md` (written by `/init`) for this project's build/test commands, style, and
module layout before acting.

### Pipeline
1. **Requirements** → `openspec/changes/<name>/proposal.md` + delta specs. Write acceptance
   criteria in EARS. **Gate: user approves.**
2. **Design** → `design.md` (approach, decisions, data flow, file changes). **Gate: user approves.**
3. **Tasks** → `tasks.md` (numbered `- [ ]` checklist, one item traceable to a requirement).
   **Gate: `openspec validate`.**
4. **Implement** (TDD: failing test first) → code + flip `- [ ]`→`- [x]`. **Gate: tests pass.**
5. **Review & verify** → spec-compliance then code-quality + security; definition-of-done.
   **Gate: `openspec validate --strict`.**
6. **Archive** → `openspec archive <name>` (deltas merge into `openspec/specs/`).

Each stage reads the upstream artifact and writes exactly one downstream artifact. The change
folder is the shared source of truth.

### EARS acceptance-criteria forms
- Ubiquitous: `The <system> SHALL <response>`
- Event: `WHEN <trigger>, the <system> SHALL <response>`
- State: `WHILE <state>, the <system> SHALL <response>`
- Optional: `WHERE <feature>, the <system> SHALL <response>`
- Unwanted: `IF <trigger>, THEN the <system> SHALL <response>`
Map to OpenSpec scenarios: precondition→GIVEN, trigger→WHEN, response→THEN.

## Accuracy rules (apply every turn)
1. **Ground in provided context.** Use the repo, artifacts, and `PROJECT.md`; do not invent APIs,
   files, or facts. If unsure whether something exists, check (grep/read) before relying on it.
2. **Quote before answering** from code/docs on any claim about existing behavior.
3. **Say "I don't have enough information"** rather than guess. A correct "I don't know" beats a
   confident wrong answer.
4. **Cite-then-retract.** Before finalizing, drop any claim you cannot back with a quote or a
   command result.
5. **Definition of done.** Never say "done", "fixed", or "passing" without running the command and
   showing its real output.
6. **External verification only.** Trust tests, linters, type-checkers, `openspec validate` — not
   self-inspection. Cap correction at ONE feedback round per failure; if still failing, report it.
7. **State assumptions + confidence** (high/medium/low) on non-trivial design decisions.

## Model selection (handled internally — user never picks)
Reasoning-heavy work (requirements, design, review, security, validation) → strongest model.
Build/test/debug → balanced model. Docs/formatting → fast model. Agents declare their own model.

## Skills available

**Craft pipeline skills** (auto-activate by description — you do not name them):
`spec-driven-sdlc` (entry), `writing-requirements`, `designing-architecture`, `planning-tasks`,
`implementing-with-tdd`, `reviewing-and-verifying`.

**Superpowers skills** (referenced by craft skills at specific gates):
`superpowers:brainstorming`, `superpowers:test-driven-development`,
`superpowers:verification-before-completion`, `superpowers:systematic-debugging`,
`superpowers:writing-plans`, `superpowers:executing-plans`,
`superpowers:subagent-driven-development`, `superpowers:dispatching-parallel-agents`,
`superpowers:requesting-code-review`,
`superpowers:receiving-code-review`, `superpowers:finishing-a-development-branch`,
`superpowers:using-git-worktrees`.

**Standalone commands** (independent of the pipeline):
`/craft-pr-review` — review any PR in an isolated worktree using the `pr-reviewer` agent.
