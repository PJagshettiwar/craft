---
name: implementing-with-tdd
description: Use when implementing tasks from an OpenSpec tasks.md — writing each task test-first (RED-GREEN-REFACTOR) as openspec-apply-change drives the task list. Use for every code change, not just new features.
---

# Implementing with TDD

## Overview
Implement each task from `tasks.md` test-first using `openspec-apply-change` to drive
the loop. TDD is the discipline applied INSIDE each task the apply skill walks through.

**REQUIRED BACKGROUND:** You MUST understand `superpowers:test-driven-development` before
implementing any task. That skill defines the RED-GREEN-REFACTOR cycle and its Iron Law.

## The Iron Law (from superpowers:test-driven-development)
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```
Wrote code before the test? Delete it. Start over with the test.
No exceptions — not for "obvious" changes, not "I'll add it after."

## Execution strategy
When the task list has independent groups (flagged during planning), prefer
`superpowers:subagent-driven-development` — dispatch one fresh subagent per independent task
with precisely crafted context. This keeps each agent focused and preserves the coordinator's
context. For tightly coupled sequential tasks, execute them inline.

## How to use with openspec-apply-change
`openspec-apply-change` drives the task loop (selecting change, reading context files,
showing progress, pausing on blockers). For EACH task it presents, apply TDD:

**RED** — write the smallest test that expresses the task's EARS scenario (GIVEN/WHEN/THEN).
Run it. Watch it fail for the right reason. A test that passes immediately = broken test.

**GREEN** — write minimum code to pass. Run test. See it pass (show real output).

**REFACTOR** — clean up while keeping tests green. Run suite.

**CHECK OFF** — flip `- [ ]` → `- [x]` in `tasks.md`. `openspec-apply-change` does this.

Use **TodoWrite** to track your progress through the task list alongside openspec.

## When to pause (don't guess — pause and ask)
Use **AskUserQuestion** when:
- A task is ambiguous: "Task 3 says 'handle errors' — what types of error? What should the response be?"
- Implementation reveals a design conflict: pause, explain the conflict, ask whether to update `design.md` or take a different approach.
- A bug is found during implementation: invoke `superpowers:systematic-debugging` (root cause before any fix).

Read `PROJECT.md` for exact build/test/lint commands and code conventions. Follow existing patterns.

## Progress output (per task)
```
Working on task N/M: <description>
[RED] Test written → running → FAIL (expected: <reason>)
[GREEN] Implementation → running → PASS
[REFACTOR] Suite → PASS
✓ Task N complete
```

## Definition of done (required before claiming tasks complete)
Use `superpowers:verification-before-completion`. Show real output for:
- Full test suite passes.
- Linter/type-check clean.
- `openspec validate` passes.
- All `tasks.md` items are `- [x]`.

<HARD-GATE>
Do NOT claim implementation complete or move to review until superpowers:verification-before-completion
has been applied with real command output shown.
</HARD-GATE>

## Related skills
- **REQUIRED background:** `superpowers:test-driven-development`
- **Task driver:** `openspec-apply-change`
- **Parallel tasks:** `superpowers:subagent-driven-development` (one subagent per independent task)
- **Parallel dispatch:** `superpowers:dispatching-parallel-agents` (when 2+ tasks have no shared state)
- **Verification:** `superpowers:verification-before-completion`
- **Bugs during implementation:** `superpowers:systematic-debugging`
- **Context isolation:** dispatch `codebase-explorer` agent for deep exploration
- **After this skill:** `reviewing-and-verifying`
