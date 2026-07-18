---
name: planning-tasks
description: Use when OpenSpec artifacts (proposal, design) exist and the tasks.md needs review or refinement before implementation starts — verifying tasks are small, ordered, and each has a matching test task.
---

# Planning Tasks

## Overview
Review the `tasks.md` created by `/craft-propose` to ensure each task is small, verifiable,
TDD-ordered, and directly traceable to a requirement. This is a validation step, not a
re-creation step — `/craft-propose` already created the file.

**REQUIRED BACKGROUND:** `/craft-propose` must have completed and `openspec validate` must pass.

## Step 1 — Get the current task list
```bash
openspec status --change "<name>" --json
```
Use `artifactPaths` from the output to find the actual `tasks.md` path. Read it.
If the change name is unclear, run `openspec list --json` and use **AskUserQuestion** to
let the user select.

## Step 2 — Validate each task against these rules

**Small & verifiable** — each task can be completed and verified in a single focused step.
Flag any task that spans multiple unrelated changes as "needs splitting."

**TDD-ordered** — for every behavior task there must be a preceding "write failing test" task.
Order: test task → implementation task → verify task.

**Traceable** — each task maps to a requirement or design decision. Use **AskUserQuestion**
for any orphan task: "Task N doesn't trace to a requirement — should it be removed or is there
a requirement I missed?"

**Includes verification** — final tasks must include: run full test suite, run lint/type-check,
`openspec validate`.

## Step 3 — Refine if needed
Edit `tasks.md` directly if tasks need splitting, reordering, or a test task is missing.
Keep groups and `## N.` structure. Keep items as `- [ ] N.M <action>`.

Show the refined list to the user briefly:
> "Here's the task breakdown — N tasks across M groups. Does this look right before we start?"

## Gate
`openspec validate` passes. User has seen the task list. Then invoke `/craft-apply`.

## Related skills
- **REQUIRED before this skill:** `/craft-propose`, `writing-requirements`
- **Artifact creation:** `/craft-propose` (creates tasks.md from CLI template)
- **After this skill:** `/craft-apply` + `implementing-with-tdd`
