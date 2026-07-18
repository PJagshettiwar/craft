---
description: Run the spec-driven SDLC pipeline. User provides a problem statement; the skill asks clarifying questions, then drives brainstorming → OpenSpec → implement (TDD) → review → archive.
argument-hint: "<problem statement>"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Agent, AskUserQuestion
---

# /craft-sdlc

Problem: **$ARGUMENTS**

Use the `spec-driven-sdlc` skill. It will handle everything — you focus on answering questions,
not on prompts.

**If no problem statement was given** (empty `$ARGUMENTS`), use **AskUserQuestion** first:
> "What do you want to build or fix? Describe the problem and what success looks like."

**If a problem statement was given**, read `PROJECT.md` (run `/craft-init` first if missing),
then immediately begin `superpowers:brainstorming` — ask ONE clarifying question at a time
to understand intent, constraints, and success criteria before proposing any design or code.

The pipeline (fully driven by skills — you don't pick models or agents):
1. `superpowers:brainstorming` → clarify intent, approve design direction (produces a **design brief**, NOT the final spec)
2. `/craft-propose` → create OpenSpec artifacts (proposal, specs, design, tasks) — this is the **canonical spec**
3. `/craft-apply` + `implementing-with-tdd` → TDD implementation
4. `reviewing-and-verifying` → spec compliance, quality, security, DoD
5. `/craft-archive` → archive and merge delta specs

**IMPORTANT:** After brainstorming approval, ALWAYS proceed to `/craft-propose` to create
proper OpenSpec artifacts. The brainstorming design doc is a working draft — the OpenSpec
change folder (`openspec/changes/<name>/`) is the source of truth. Do NOT stop after
brainstorming or treat its output as the final spec.
