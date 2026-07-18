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
2. spec-reviewer agent has returned APPROVE or APPROVE WITH NITS.
3. openspec validate --strict passes.
</HARD-GATE>

## Stage 1 — Spec compliance (always first)
Dispatch the `spec-reviewer` agent (read-only, strong model, context-isolated). Give it:
- Paths to `proposal.md`, delta specs, `design.md`, `tasks.md` (from `openspec status --json`)
- The repo root for code access.

It will verify each EARS scenario maps to a real, passing assertion and every task is checked.

If spec-reviewer returns REQUEST CHANGES:
- Identify which requirement is unmet.
- Return to `implementing-with-tdd` and fix it.
- ONE correction loop only — then re-review. If still failing, report to the user.

## Stage 2 — Code quality & security
spec-reviewer also covers quality (conventions, clarity, no dead code, no added scope) and
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

## Stage 4 — Archive
When spec-reviewer is APPROVE(-WITH-NITS) and all commands pass, invoke
`openspec-archive-change`. It will:
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
- **For any bugs found:** `superpowers:systematic-debugging`
- **Code review execution:** dispatch `spec-reviewer` agent
- **Archive execution:** `openspec-archive-change`
- **Before this skill:** `implementing-with-tdd`, `openspec-apply-change`
