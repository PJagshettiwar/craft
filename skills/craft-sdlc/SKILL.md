---
name: craft-sdlc
description: Use when given any problem statement, feature request, bug, or change to build. Drives the full think → work → implement → review → archive pipeline, emitting OpenSpec artifacts. Use before writing any code for a non-trivial change. Prefer this over the openspec-* skills when driving a whole change.
---

# craft — spec-driven SDLC

Turn a problem statement into shipped, verified code. You ask; you don't assume.

This skill is the **spine**: it decides which phase you are in and hands off to that phase's
command. Each command is self-contained — it carries its own doctrine and needs nothing else
loaded. There is exactly one hop, and it is the same hop the user makes by typing the command.

<HARD-GATE>
Do NOT write any code, create any OpenSpec change, or take any implementation action until
a design has been presented and the user has approved it. This applies to every change
regardless of perceived simplicity.
</HARD-GATE>

## Step 0 — Understand the problem

If the problem statement is missing or vague, use **AskUserQuestion** (open-ended):
> "What do you want to build or fix? Describe the problem and what success looks like."

One question at a time. Most important thing first; follow-ups based on the answers.

Read `CLAUDE.md` for this project's commands, conventions and Do-NOT rules before acting.
If `scripts/craft-doctor.sh` is available, run it — a CLAUDE.md with drift is a set of hints,
not rules.

## The pipeline

```
1 Explore  ──design approved──▶  2 Propose  ──artifacts valid──▶  3 Apply
   /craft-explore                  /craft-propose                  /craft-apply
                                                                       │
                                                                  tasks done
                                                                       ▼
   5 Archive  ◀──review passed──  4 Review
   /craft-archive                  /craft-review-implementation
```

| Phase | Command | Produces | Gate |
|---|---|---|---|
| 1 Explore & design | `/craft-explore` | decision record — problem, scope, options, decision, rejected | **user approves the design** |
| 2 Artifacts | `/craft-propose` | `proposal.md`, `design.md`, delta specs, `tasks.md` | `openspec validate` passes |
| 3 Implement | `/craft-apply` | code + tests, task-by-task, test-first | tests pass, all tasks `[x]` |
| 4 Review | `/craft-review-implementation` | findings, verdict | APPROVE / APPROVE WITH NITS |
| 5 Archive | `/craft-archive` | deltas merged, knowledge written back | `openspec validate --strict` |

## The Architect lens runs through all five

craft does not behave like a competent fresher who does what the spec says. It behaves like the
senior engineer who wrote the codebase. Each phase emits its architect line, and a phase that
skips it is incomplete:

| Phase | Line |
|---|---|
| Explore | `SCOPE:` + `CUT:` |
| Propose | `STRUCTURE: N files, M new symbols` |
| Apply | `REUSE:` / `NEW:` per task, `REFACTOR:` per task |
| Review | a Conciseness & Reuse finding section |
| Archive | the knowledge write-back prompt |

Full definition lives in `doctrine/architect.md`, inlined into every command.

## Every phase starts with a Context Preflight

No phase acts on an assumption. Each opens by establishing what it knows — owning module,
siblings, callers, covering tests, recent history — and declaring what it does **not** know:

```
CONTEXT: module=… siblings=… callers=… tests=… last-touched=…
KNOWN:   …
UNKNOWN: …
MODE:    serena | grep-only
```

`UNKNOWN:` may not be empty by default. An author knows the edge of their knowledge; a fresher
assumes. Full definition in `doctrine/preflight.md`, inlined into every command.

## Handoff protocol — files, never conversation

Quality degrades from roughly 70% context fill: the model starts re-suggesting ruled-out
approaches and reintroducing fixed bugs. Running five phases in one session guarantees the
review happens in the worst part of it.

So each phase **ends by writing its output to a file** and says:

> `Phase complete → <path>. Run /compact, then <next command>.`

Each phase **starts by reading files**, never by relying on conversation history. Past ~60%
context at a boundary, treat the compaction prompt as mandatory rather than advisory.

`/craft-review-implementation` in particular should run in a **fresh session**. A reviewer that watched the
code get written is a poor judge of it; reading only the diff, the specs and CLAUDE.md is the
isolation that matters — and unlike a subagent, you can watch it happen.

## Trivial change exception

Pure questions, explanations, or one-line typo fixes: skip the pipeline, answer directly.
If a "simple" fix reveals unexpected complexity, restart at Phase 1.

## Entry points

- Fuzzy problem, or a decision to think through → `/craft-explore`
- Problem already clear → `/craft-propose`
- Artifacts exist, ready to build → `/craft-apply`
- Code written, needs judging → `/craft-review-implementation` (fresh session)
- Reviewing someone else's PR → `/craft-review-pr` (independent of this pipeline)

Never pick a model, agent, or sub-skill manually. There are none to pick.

## A note on the openspec-* skills

`openspec init` installs its own skills into `.claude/skills/`, and `openspec update` recreates
them. They trigger on the same intent as this pipeline. When a whole change is being driven,
**this pipeline takes precedence** — it calls the same `openspec` CLI, and adds the design gate,
the reuse check, TDD enforcement and the review discipline that those skills do not carry.
