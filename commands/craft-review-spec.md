---
description: Review OpenSpec artifacts against the actual codebase — find edge cases, missing scenarios, infeasible assumptions, and gaps before implementation begins. The inverse of craft-review.
argument-hint: "[change name — leave blank to pick]"
allowed-tools: Read, Grep, Glob, Bash, Agent, AskUserQuestion
---

# /craft-review-spec — drill into specs before you implement

Review OpenSpec change artifacts against the actual codebase to catch gaps, edge cases, and
wrong assumptions BEFORE implementation begins.

**This is the inverse of `/craft-review`:**
- `/craft-review` checks code against specs (post-implementation)
- `/craft-review-spec` checks specs against code (pre-implementation)

## Step 1 — Select the change

If `$ARGUMENTS` is provided, use it as the change name. Otherwise, list available changes:

```bash
ls openspec/changes/
```

Ask the user to pick one via **AskUserQuestion**.

## Step 2 — Load context

```bash
openspec status --change "<name>" --json
```

Read ALL artifacts: `proposal.md`, `design.md`, all `specs/**/spec.md`, `tasks.md`.
Read `CLAUDE.md` for project conventions.

## Step 3 — Dispatch the drilldown reviewer

Dispatch the `pre-impl-spec-reviewer` agent with:
- The full path to the change directory
- The repo root

The agent is **read-only** — it reviews but does not modify files.

Wait for the agent's verdict.

## Step 4 — Present findings

Show the agent's full report to the user. Then:

**If APPROVE:**
```
## Spec Review Passed

Change: <name>
Verdict: APPROVE

Specs are grounded in the codebase and ready for implementation.
Next: /craft-apply <name>
```

**If NEEDS REVISION:**

Show the findings grouped by severity (Critical → Important → Advisory).
For each "Missing Scenario" finding, show the ready-to-paste EARS text.

Ask the user:
> "Want me to apply these fixes to the spec files, or would you like to review them first?"

If the user says yes, update the spec files directly:
- Add missing scenarios to the appropriate `specs/<capability>/spec.md`
- Fix task ordering or add missing tasks to `tasks.md`
- Correct any factual errors in `design.md`

Then re-run `openspec status --change "<name>"` to confirm everything is still valid.

## Step 5 — Gate

<HARD-GATE>
Do NOT suggest moving to `/craft-apply` until the drilldown reviewer returns APPROVE.
If it returns NEEDS REVISION, the specs must be fixed and re-reviewed first.
One revision loop is expected. If a second review still finds Critical issues,
escalate to the user for a design discussion.
</HARD-GATE>

## Related skills
- **Before this:** `/craft-propose` (creates the artifacts to review)
- **After this:** `/craft-apply` (implements the reviewed specs)
- **Post-implementation review:** `/craft-review` (checks code against specs)
- **Full pipeline:** `craft-sdlc`
