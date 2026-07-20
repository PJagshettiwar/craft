---
description: Implement tasks from an OpenSpec change, test-first. Use after craft-propose or to continue an in-progress change. Applies TDD Iron Law — RED-GREEN-REFACTOR per task.
argument-hint: "[change name — leave blank to pick]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion
---

# /craft-apply — implement test-first

Read `PROJECT.md` for exact build/test/lint commands and code conventions before starting.

**REQUIRED BACKGROUND:** You MUST understand `superpowers:test-driven-development` before
implementing any task. That skill defines the RED-GREEN-REFACTOR cycle and its Iron Law.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? Delete it. Start over with the test.
No exceptions — not for "obvious" changes, not "I'll add it after."

---

## Step 1 — Select the change

If a name is provided, use it. Otherwise:
- Infer from conversation context if the user mentioned a change
- Auto-select if only one active change exists
- If ambiguous, run `openspec list --json` then use **AskUserQuestion** to let the user choose

Always announce: "Using change: `<name>`"

---

## Step 2 — Check status and schema

```bash
openspec status --change "<name>" --json
```

Parse:
- `schemaName` — workflow in use (e.g. "spec-driven")
- `planningHome`, `changeRoot`, `actionContext` — use for all paths
- Which artifact contains the tasks (typically `tasks` — confirm from status)

**Workspace guard:** If `actionContext.mode: "workspace-planning"` and `allowedEditRoots` is empty,
explain that full workspace apply is not supported. Treat linked repos and folders as read-only
context, ask the user to select an affected area through an explicit implementation workflow,
and STOP before editing any files.

**If `state: "blocked"` (missing artifacts):** show message, suggest `/craft-propose`.
**If `state: "all_done"`:** congratulate, suggest `/craft-review`.

---

## Step 3 — Get apply instructions

```bash
openspec instructions apply --change "<name>" --json
```

Returns:
- `contextFiles` — artifact paths (proposal, specs, design, tasks — varies by schema)
- Progress: total, complete, remaining
- Task list with status
- Dynamic instruction for current state

---

## Step 4 — Read all context files

Read every file listed in `contextFiles`. Understand the EARS scenarios before writing any code.

---

## Step 5 — Show progress

```
Schema: <schema-name>
Progress: N/M tasks complete
Remaining: <overview>
```

---

## Step 6 — Implement tasks with TDD (loop until done or blocked)

Use **TodoWrite** to track progress through the task list alongside openspec.

**For each pending task — apply RED-GREEN-REFACTOR:**

**RED** — write the smallest test that expresses the task's EARS scenario (GIVEN/WHEN/THEN).
Run it. Watch it fail for the right reason. A test that passes immediately = broken test.

**GREEN** — write minimum code to pass. Run test. Show real output.

**REFACTOR** — clean up while keeping tests green. Run full suite.

**CHECK OFF** — flip `- [ ]` → `- [x]` in tasks.md immediately after completing.

**Progress output per task:**
```
Working on task N/M: <description>
[RED]      Test written → running → FAIL (expected: <reason>)
[GREEN]    Implementation → running → PASS
[REFACTOR] Suite → PASS
✓ Task N complete
```

**Pause and use AskUserQuestion when:**
- Task is ambiguous: "Task N says X — what exactly should happen when Y?"
- Implementation reveals a design conflict — explain the conflict, ask whether to update `design.md`
- A bug is found: invoke `superpowers:systematic-debugging` — root cause before any fix
- Error or blocker encountered

Never guess. Never push past ambiguity.

---

## Step 7 — On completion or pause, show status

**If all done:**
```
## Implementation Complete

Change: <name>  Schema: <schema-name>  Progress: M/M tasks ✓

Completed this session:
- [x] Task 1 ...
- [x] Task 2 ...

All tasks complete! Next: /craft-review <name>
```

**If paused:**
```
## Implementation Paused

Change: <name>  Progress: N/M tasks complete

Issue: <description>

Options:
1. <option 1>
2. <option 2>
What would you like to do?
```

---

<HARD-GATE>
Do NOT claim implementation complete or move to review until:
1. superpowers:verification-before-completion has been applied.
2. Full test suite passes — show real output.
3. Lint/type-check clean — show real output.
4. openspec validate passes — show real output.
5. All tasks.md items are - [x].
</HARD-GATE>

---

## Fluid workflow

This command supports interleaved usage — it is not phase-locked:
- **Can be invoked anytime:** before all artifacts are done (if tasks exist), after partial
  implementation, or interleaved with other actions like `/craft-explore` or `/craft-propose`.
- **Allows artifact updates:** if implementation reveals design issues, suggest updating the
  relevant artifact (design.md, specs, tasks.md) — then continue. Work fluidly.

## Guardrails

- Keep going through tasks until done or blocked
- Always read context files before starting
- Use contextFiles from CLI output — do not assume file names
- Keep code changes minimal and scoped to each task
- Update task checkbox immediately after completing each task
- Pause on errors, blockers, or unclear requirements — don't guess

## Related skills
- **REQUIRED background:** `superpowers:test-driven-development`
- **Verification:** `superpowers:verification-before-completion`
- **Bugs:** `superpowers:systematic-debugging`
- **Before this:** `/craft-propose`
- **After this:** `/craft-review`
- **Full pipeline:** `spec-driven-sdlc`
