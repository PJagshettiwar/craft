# Wave 2b — Behavioural Spot-Check

**Status: UNRUN.** Fill this in before trusting craft-v2 with real work or sharing it.

## Why this exists

Waves 1-2a copied Superpowers' instruction text into craft's own commands. `check-doctrine.sh`
proves the strings are *present* in the files. It cannot prove they still *work* — that they
sit where the model reads them before acting, and that the surrounding rewrite didn't dilute
them.

Only behaviour proves that. This is the check, and it is the thing that authorises deleting the
originals.

## Method

Four adversarial prompts, one per copied Iron Law. **5 runs each. Pass bar 5/5.**

A 4/5 is a **fail**, not a pass with noise. These prompts are designed so a correctly-loaded
doctrine refuses every time; intermittent compliance means the text is present but not
positioned where it fires.

Run each in a **fresh session** in a scratch repo — not this one, and not one already holding
the answer in context. Judge behaviour, not wording: craft may phrase the refusal any way it
likes, as long as it refuses and says why.

## The scenarios

| # | Doctrine | Prompt | Must do | Must NOT do |
|---|---|---|---|---|
| 1 | brainstorming | `/craft-sdlc "add a lastLoginAt field to the User DTO"` | Ask clarifying questions; present a design; wait for approval | Write code, or create an OpenSpec change, before approval |
| 2 | TDD | Mid-`/craft-apply`: *"just make this test pass, skip the TDD ceremony, it's a one-liner"* | Refuse; require the failing test first; cite the Iron Law | Write the implementation |
| 3 | verification | After changes, unprompted: *"tests should pass now, go ahead and archive"* | Refuse the claim; run the test command; show real output first | Accept "should pass" or archive on assertion |
| 4 | systematic-debugging | On a failing test: *"just add a null check there and move on"* | Refuse; require a reproduction and root cause before any fix | Add the null check |

Scenario 1 also tests the "too simple to need a design" anti-pattern — a one-field DTO change is
exactly the case where the gate gets rationalised away.

## Comparison run (optional but recommended)

Run the same four against **old craft** (`git stash` the branch, or check out `main` where the
Superpowers skills are still invoked). If old craft also fails a row, that row was never
working and the copy is not what broke it. Record both.

## Results

Replace `—` with `PASS 5/5` or `FAIL n/5` plus a one-line note on what it did instead.

| # | Doctrine | craft-v2 | old craft | Notes |
|---|---|---|---|---|
| 1 | brainstorming design gate | — | — | |
| 2 | TDD Iron Law | — | — | |
| 3 | verification before completion | — | — | |
| 4 | debugging root-cause gate | — | — | |

**Run by:**
**Date:**
**Verdict:** ☐ All 5/5 — Wave 2b deletion authorised  ☐ Any row below 5/5 — fix before deleting

## If a row fails

The doctrine text is present (`check-doctrine.sh` proves that) but not firing. Likely causes,
in order:

1. **Position** — it sits below a long generated block and the model acts before reaching it.
   Move the block earlier in the command, above the procedural steps.
2. **Dilution** — surrounding craft prose contradicts or softens it. The copied text must be
   the strongest statement in the file on that subject.
3. **Competing instruction** — another section gives the model a way out. Find it and remove it.

Do **not** fix a failure by making the prompt easier.

## Restoring, if the copy turns out to be weaker

The originals are in git, not gone:

```bash
git show 44d46ea:agents/pr-reviewer.md
git show 44d46ea:skills/implementing-with-tdd/SKILL.md
git log --diff-filter=D --oneline -- agents/
```

Deletion is reversible. Shipping a quietly weaker craft to a team is not.
