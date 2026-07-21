---
description: Archive a completed OpenSpec change — verifies review passed, checks artifact and task completion, assesses delta spec sync, then moves the change to archive. Use after craft-review returns APPROVE.
argument-hint: "[change name — leave blank to pick]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion, Agent
---

# /craft-archive — verify and archive

Read `CLAUDE.md` for test/lint commands.

<HARD-GATE>
Do NOT archive until:
1. /craft-review has returned APPROVE or APPROVE WITH NITS.
2. superpowers:verification-before-completion applied (all commands run, output shown).
3. openspec validate --strict passes.
If any of these have not been done, run /craft-review first.
</HARD-GATE>

---

## Step 1 — Select the change

If a name is provided, use it. Otherwise run `openspec list --json` to get active changes.
Use **AskUserQuestion** to let the user select — show only non-archived changes.

**Do NOT auto-select or guess. Always confirm the change.**

---

## Step 2 — Check artifact completion

```bash
openspec status --change "<name>" --json
```

Parse:
- `schemaName` — workflow in use
- `planningHome`, `changeRoot`, `artifactPaths`, `actionContext` — use for all paths
- `artifacts` — list with `status` per artifact

**Workspace guard:** If `actionContext.mode: "workspace-planning"`, explain that workspace
archive is not supported. STOP — do not move workspace changes to repo-local archives.

**If any artifacts are not `done`:**
- List incomplete artifacts
- Use **AskUserQuestion**: "Some artifacts are incomplete. Proceed anyway?"
- Continue only if user confirms.

---

## Step 3 — Check task completion

Read the tasks file (`tasks.md` or equivalent from status JSON).

Count `- [ ]` (incomplete) vs `- [x]` (complete).

**If incomplete tasks found:**
- Show the count and which tasks remain
- Use **AskUserQuestion**: "N tasks are still incomplete. Proceed with archive?"
- Continue only if user confirms.

If no tasks file exists, proceed without this check.

---

## Step 4 — Run verification gate (superpowers:verification-before-completion)

Run each command and show real output. Do not claim the gate passed without output.

- Full test suite: `<test command from CLAUDE.md>`
- Lint/type-check: `<lint command from CLAUDE.md>`
- `openspec validate --strict`

All three must pass. If any fail, stop and send user back to `/craft-apply`.

---

## Step 5 — Assess delta spec sync

Use `artifactPaths.specs.existingOutputPaths` from status JSON to find delta specs.

**If no delta specs exist:** proceed to archive without this step.

**If delta specs exist:**
- Compare each delta spec with its corresponding main spec at `openspec/specs/<capability>/spec.md`
- Determine what changes would be applied (adds, modifications, removals, renames)
- Show a combined summary before prompting

Prompt options:
- If changes needed: "Sync now (recommended)" or "Archive without syncing"
- If already synced: "Archive now", "Sync anyway", or "Cancel"

If user chooses sync, dispatch a general-purpose subagent:
> "Use the Skill tool to invoke openspec-sync-specs for change '<name>'. Delta spec analysis: <summary>"

Proceed to archive regardless of the sync choice.

---

## Step 6 — Archive

Create the archive directory if it doesn't exist:
```bash
mkdir -p "<planningHome.changesDir>/archive"
```

Target name: `YYYY-MM-DD-<change-name>` (use today's date).

Check if target already exists — if yes, fail with error and suggest renaming.

Move the change:
```bash
mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"
```

---

## Output on success

```
## Archive Complete

Change: <name>
Schema: <schema-name>
Archived to: <planningHome.changesDir>/archive/YYYY-MM-DD-<name>/
Specs: ✓ Synced  (or "No delta specs" or "Sync skipped")
Tests: PASS  Lint: PASS  openspec validate: PASS
Verdict: APPROVE
All tasks complete ✓

Next: /craft-pr
```

---

## Guardrails

- Always confirm change selection — never auto-select
- Use artifact graph from `openspec status --json` for completion checking
- Never block archive on warnings — inform and confirm
- Preserve `.openspec.yaml` when moving to archive (it moves with the directory)
- Show delta spec summary before any sync prompt
- If sync is requested, use subagent — never do it inline

## Related skills
- **REQUIRED before archiving:** `superpowers:verification-before-completion`
- **Review execution:** `/craft-review`
- **Before this:** `/craft-review`
- **After this:** `/craft-pr`
- **Full pipeline:** `spec-driven-sdlc`
