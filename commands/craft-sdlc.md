---
description: Run the spec-driven SDLC pipeline. User provides a problem statement; the skill asks clarifying questions, then drives brainstorming → OpenSpec → implement (TDD) → review → archive.
argument-hint: "<problem statement>"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion
---

# /sdlc

Problem: **$ARGUMENTS**

You are the driver. Each phase is a separate command that carries everything it needs. Your job
is to work out which phase the work is in, hand off to it, and enforce the gates between.

**If `$ARGUMENTS` is empty**, use **AskUserQuestion**:
> "What do you want to build or fix? Describe the problem and what success looks like."

**Then** read `CLAUDE.md`. If it is missing, run `/craft-init` first — the pipeline works
without it, but every convention claim becomes an unknown.

<HARD-GATE>
Do NOT write any code, create any OpenSpec change, or take any implementation action until a
design has been presented and the user has approved it. Every change, regardless of perceived
simplicity.
</HARD-GATE>

---

## Work out where you are

| State | Go to |
|---|---|
| Problem is fuzzy, or a decision needs thinking through | `/craft-explore` |
| A decision record exists, or the problem is genuinely clear | `/craft-propose` |
| Artifacts exist, not yet reviewed against the codebase | `/craft-review-spec` |
| Artifacts validated, tasks pending | `/craft-apply` |
| All tasks `[x]` | `/craft-review-implementation` — **in a fresh session** |
| Review returned APPROVE | `/craft-archive` |
| Archived | `/craft-pr` |

`openspec list --json` tells you what changes exist. `openspec status --change "<name>" --json`
tells you how far one has got. Check before assuming.

## The gates

Each is a stop, not a suggestion:

1. **After explore** — the user approves the design. Nothing is created before this.
2. **After propose** — `openspec validate` passes AND the user approves the task list.
3. **After apply** — full suite passes, lint clean, every task `[x]`, real output shown.
4. **After review** — verdict is APPROVE or APPROVE WITH NITS.

A user may say "skip this gate". Honour it, note it, and carry on — but never skip one silently.

## One phase, one session

Quality degrades from roughly 70% context fill: the model starts re-proposing ruled-out ideas
and reintroducing fixed bugs. Five phases in one session puts the review in the worst part of
it, which is exactly where you least want it.

So at every phase boundary:

> `Phase complete → <artifact path>. Run /compact, then <next command>.`

Phases read files, never conversation history. Past ~60% context, treat that prompt as
mandatory. `/craft-review-implementation` in particular should start clean — a reviewer that watched the code
get written is a poor judge of it.

## Trivial change exception

Pure questions, explanations, or one-line typo fixes: skip the pipeline, answer directly.
If a "simple" fix turns out to have depth, restart at `/craft-explore`.

## What you do not do

- Do not pick models, agents, or sub-skills — there are none to pick
- Do not implement anything yourself; `/craft-apply` does that, test-first
- Do not summarise a phase's work in place of that phase writing its file
