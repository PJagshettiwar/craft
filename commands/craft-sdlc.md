---
description: Run the spec-driven SDLC pipeline. User provides a problem statement; the skill asks clarifying questions, then drives brainstorming → OpenSpec → implement (TDD) → review → archive.
argument-hint: "<problem statement>"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Agent, AskUserQuestion
---

# /sdlc

Problem: **$ARGUMENTS**

Use the `spec-driven-sdlc` skill. It will handle everything — you focus on answering questions,
not on prompts.

**If no problem statement was given** (empty `$ARGUMENTS`), use **AskUserQuestion** first:
> "What do you want to build or fix? Describe the problem and what success looks like."

**If a problem statement was given**, read `PROJECT.md` (run `/init` first if missing),
then immediately begin `superpowers:brainstorming` — ask ONE clarifying question at a time
to understand intent, constraints, and success criteria before proposing any design or code.

**IMPORTANT**: The brainstorming skill must STOP after the user approves the design (step 5 of its
checklist). Do NOT write a spec file to `docs/superpowers/specs/` — skip steps 6-8 of brainstorming.
Instead, proceed directly to `craft-propose` which creates the proper OpenSpec artifacts under
`openspec/changes/`. The approved design from brainstorming becomes the input to `craft-propose`.

The pipeline (fully driven by skills — you don't pick models or agents):
1. `superpowers:brainstorming` → clarify intent, approve design (stop after approval — no spec file)
2. `craft-propose` → create OpenSpec artifacts (proposal, design, specs, tasks)
3. `craft-review-spec` → drill specs against codebase, find edge cases and gaps before coding
4. `craft-apply` + `implementing-with-tdd` → TDD implementation
5. `craft-review` → spec compliance, quality, security, DoD
6. `craft-archive` → archive and merge delta specs
