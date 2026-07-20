---
description: Review implementation against the OpenSpec — spec compliance first, then code quality and security, then definition-of-done gate. Use after craft-apply before craft-archive.
argument-hint: "[change name — leave blank to pick]"
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion, Agent
---

# /craft-review — review before you archive

Read `PROJECT.md` for test/lint commands. Then invoke the `reviewing-and-verifying` skill.

Apply these **Superpowers layers** on top of the base skill:

<HARD-GATE>
Do NOT claim the change is reviewable until:
1. All tasks.md items are `- [x]`.
2. Branch is clean — run `git status` and show output.
If either fails, send the user back to `/craft-apply`.
</HARD-GATE>

## Stage 1 — Spec compliance (always first)

Dispatch the `post-impl-code-reviewer` agent (read-only, opus model, context-isolated). Provide:
- Paths to `proposal.md`, delta specs, `design.md`, `tasks.md`
  (from `openspec status --change "<name>" --json`)
- Repo root for code access.

It verifies each EARS scenario maps to a real, passing assertion and every task is checked.

**If REQUEST CHANGES:**
- Identify the unmet requirement with `file:line` precision.
- Return to `/craft-apply` to fix it.
- ONE correction loop only — then re-review. Still failing → report to user.

## Stage 2 — Code quality & security

post-impl-code-reviewer also covers: conventions, clarity, no dead code, no added scope,
input validation, no injection, no secrets in logs, least privilege.

Expected verdict format:
```
Verdict: APPROVE | APPROVE WITH NITS | REQUEST CHANGES | BLOCK
Spec compliance: <met / gaps with file:line>
Quality: <findings with file:line>
Security: <findings with file:line>
Required changes: <specific, ordered — empty if APPROVE>
```

## Stage 3 — Definition of done (superpowers:verification-before-completion)

Run each command and show real output. Do not claim the gate passed without output.

- Full test suite: `<test command from PROJECT.md>`
- Lint/type-check: `<lint command from PROJECT.md>`
- `openspec validate --strict`

<HARD-GATE>
Do NOT report review as passed until:
1. post-impl-code-reviewer returns APPROVE or APPROVE WITH NITS.
2. superpowers:verification-before-completion applied with real command output shown.
3. openspec validate --strict passes.
</HARD-GATE>

## On pass — report and hand off

```
## Review Passed ✓

Change: <name>
Verdict: <APPROVE | APPROVE WITH NITS>
Tests: PASS  Lint: PASS  openspec validate: PASS

Ready to archive → /craft-archive <name>
```

## Related skills
- **Spec compliance + quality:** dispatch `post-impl-code-reviewer` agent
- **Verification:** `superpowers:verification-before-completion`
- **Bugs found:** `superpowers:systematic-debugging`
- **Before this:** `/craft-apply`
- **After this:** `/craft-archive`
- **Full pipeline:** `spec-driven-sdlc`
