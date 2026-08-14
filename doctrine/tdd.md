## Test-Driven Development

> Copied from Superpowers `test-driven-development` v5.0.7 (MIT, © 2025 Jesse Vincent).
> The blunt passages are verbatim by design — see NOTICE. Do not soften them.

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

### When to Use

**Always:** new features · bug fixes · refactoring · behavior changes

**Exceptions (ask your human partner):** throwaway prototypes · generated code · configuration files · legacy code with no test infrastructure (see Legacy escape below)

Thinking "skip TDD just this once"? Stop. That's rationalization.

### The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

### Resolving the test command

Verify RED and Verify GREEN below are MANDATORY and both need a real command. Resolve it once,
in this order, before the first task:

```
CLAUDE.md ## Commands (test, and test-single)
  → detect: package.json scripts.test · pom.xml · Makefile · pyproject.toml · Cargo.toml · go.mod
  → ask the user once, and offer to write the answer into CLAUDE.md
  → still unresolved: STOP. Do not proceed.
```

An unresolvable test command is a hard stop, not a silent degrade — without it the Iron Law is
a slogan. Below, `<TEST>` means the resolved single-test command.

### Legacy escape

When adding to code with **zero existing test coverage** AND no resolvable test command for
this module, ask the user explicitly:

> "No test infrastructure exists for this path. Skip TDD for this task? I'll record it."

If they approve, emit the forced output line:

```
LEGACY: no test infrastructure for <path>, approved by user
```

This line is visible in review. The escape is a conscious, auditable decision — not a silent
skip. It does not apply when a test command exists but the code is merely hard to test; that is
a design problem, not a legacy problem.

### Red-Green-Refactor

```
RED → verify fails correctly → GREEN → verify passes, all green → REFACTOR → stay green → next
                     ↑ wrong failure? back to RED          ↑ not passing? back to GREEN
```

#### RED — Write Failing Test

Write one minimal test showing what should happen. When the task comes from an OpenSpec
scenario, the test IS the EARS scenario: GIVEN → setup, WHEN → the call, THEN → the assertion.

Good — clear name, tests real behavior, one thing:

```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

Bad — vague name, tests mock not code:

```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```

**Requirements:** one behavior · clear name · real code (no mocks unless unavoidable)

#### Verify RED — Watch It Fail

**MANDATORY. Never skip.**

Run `<TEST>`. Paste the assertion error, not just "FAILED".

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

**Test passes?** You're testing existing behavior. Fix test.

**Test errors?** Fix error, re-run until it fails correctly.

#### GREEN — Minimal Code

Write simplest code to pass the test. Don't add features, refactor other code, or "improve"
beyond the test. Options objects with `maxRetries`, `backoff`, `onRetry` that no test demands
are YAGNI.

#### Verify GREEN — Watch It Pass

**MANDATORY.**

Run `<TEST>`, then the full suite.

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.

**Other tests fail?** Fix now.

#### REFACTOR — Clean Up

After green only: remove duplication · improve names · extract helpers.

Keep tests green. Don't add behavior.

Apply the architect ladder here — this is where the fresher stops at formatting and the
architect deletes. Emit the line:

```
REFACTOR: deleted N lines / inlined <X> / no change because <Y>
```

"No change because it is already minimal" is a valid answer. "No change" with no reason is not.

### Test Validity — a green test can still be worthless

A test is **invalid**, and the task is not done, if it:

- asserts nothing
- only asserts that a mock was called
- is marked skip / xfail / `@Disabled` / `.only` on something else
- asserts a value the implementation computes, rather than a value the spec demands
- passes with the implementation reverted

Before checking a task off: mentally revert your implementation. Would the test still pass?
Then it is worthless — rewrite it.

**Never weaken a test to make it pass.** Deleting a test, skipping it, or loosening an
assertion is a *spec change*, not a fix. Say so out loud and get approval first.

### Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

### Why Order Matters

**"I'll write tests after to verify it works"** — Tests written after code pass immediately.
Passing immediately proves nothing: might test wrong thing, might test implementation rather
than behavior, might miss edge cases you forgot. You never saw it catch the bug. Test-first
forces you to see the test fail, proving it actually tests something.

**"I already manually tested all the edge cases"** — Manual testing is ad-hoc. No record of
what you tested, can't re-run when code changes, easy to forget cases under pressure. "It
worked when I tried it" ≠ comprehensive.

**"Deleting X hours of work is wasteful"** — Sunk cost fallacy. The time is already gone. The
"waste" is keeping code you can't trust. Working code without real tests is technical debt.

**"TDD is dogmatic, being pragmatic means adapting"** — TDD IS pragmatic: finds bugs before
commit, prevents regressions, documents behavior, enables refactoring. "Pragmatic" shortcuts =
debugging in production = slower.

**"Tests after achieve the same goals - it's spirit not ritual"** — No. Tests-after answer
"What does this do?" Tests-first answer "What should this do?" Tests-after are biased by your
implementation. You test what you built, not what's required.

### Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it. Add tests for existing code. |

### Red Flags - STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

### Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered
- [ ] No test asserts nothing, is skipped, or would pass with the code reverted

Can't check all boxes? You skipped TDD. Start over.

### When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

### Testing Anti-Patterns

When adding mocks or test utilities, avoid: testing mock behavior instead of real behavior;
adding test-only methods to production classes; mocking without understanding dependencies.

### Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without your human partner's permission.
