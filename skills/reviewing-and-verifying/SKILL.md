---
name: reviewing-and-verifying
description: Use when implementation tasks are complete — reviewing code against the OpenSpec delta specs (spec compliance first, then quality and security), running the definition-of-done gate, and archiving the change. Use after openspec-apply-change reports all tasks done.
---

# Reviewing and Verifying

## Overview
Prove the implementation satisfies the approved spec, is safe and clean, and then archive.
Verification is EXTERNAL — run tools and show output. Self-inspection is not verification.

**REQUIRED:** Apply `superpowers:verification-before-completion` before claiming anything done.
**REQUIRED:** For any bug found during review, use `superpowers:systematic-debugging`.

<HARD-GATE>
Do NOT claim the change is done, clean, or ready to merge until:
1. superpowers:verification-before-completion has been applied (all commands run, output shown).
2. post-impl-code-reviewer agent has returned APPROVE or APPROVE WITH NITS.
3. openspec validate --strict passes.
</HARD-GATE>

## Stage 1 — Spec compliance (always first)
Dispatch the `post-impl-code-reviewer` agent (read-only, strong model, context-isolated). Give it:
- Paths to `proposal.md`, delta specs, `design.md`, `tasks.md` (from `openspec status --json`)
- The repo root for code access.

It will verify each EARS scenario maps to a real, passing assertion and every task is checked.

If post-impl-code-reviewer returns REQUEST CHANGES:
- Apply `superpowers:receiving-code-review` — evaluate each item technically before implementing.
  Verify against the codebase reality; push back on suggestions that don't apply.
- Identify which requirement is unmet.
- Return to `implementing-with-tdd` and fix it.
- ONE correction loop only — then re-review. If still failing, report to the user.

## Stage 2 — Code quality & security
post-impl-code-reviewer also covers quality (conventions, clarity, no dead code, no added scope) and
security (input validation, no injection, no secrets in logs, least privilege). Its output:
```
Verdict: APPROVE | APPROVE WITH NITS | REQUEST CHANGES | BLOCK
Spec compliance: <met / gaps with file:line>
Quality: <findings with file:line>
Security: <findings with file:line>
Required changes: <specific, ordered — empty if APPROVE>
```

## Stage 3 — Definition of done (apply superpowers:verification-before-completion)
Run each of these and show the real output before claiming the gate is passed:
- Full test suite: `<test command from PROJECT.md>`
- Lint/type-check: `<lint command from PROJECT.md>`
- `openspec validate --strict`

## Stage 4 — Finish the branch
When post-impl-code-reviewer is APPROVE(-WITH-NITS) and all commands pass, apply
`superpowers:finishing-a-development-branch` to decide next steps: merge, PR, or cleanup.
Use `superpowers:requesting-code-review` if an additional human or agent review is warranted
before merging.

## Stage 5 — Archive
When the branch is finalized, invoke `openspec-archive-change`. It will:
1. Check artifact + task completion (prompt if anything incomplete).
2. Show delta spec sync assessment.
3. Run `mv "<changeRoot>" "<changesDir>/archive/YYYY-MM-DD-<name>"`.
4. Confirm deltas are merged into `openspec/specs/`.

Output on success:
```
## Archive Complete
Change: <name>
Archived to: openspec/changes/archive/YYYY-MM-DD-<name>/
Specs: ✓ Synced
Verdict: APPROVE
All tasks complete ✓
```

## Related skills
- **REQUIRED before claiming done:** `superpowers:verification-before-completion`
- **Handling review feedback:** `superpowers:receiving-code-review` (technical evaluation, not blind implementation)
- **Requesting additional review:** `superpowers:requesting-code-review` (dispatch reviewer subagent with crafted context)
- **Branch completion:** `superpowers:finishing-a-development-branch` (verify tests → present options → execute)
- **For any bugs found:** `superpowers:systematic-debugging`
- **Code review execution:** dispatch `post-impl-code-reviewer` agent
- **Archive execution:** `openspec-archive-change`
- **Before this skill:** `implementing-with-tdd`, `openspec-apply-change`
