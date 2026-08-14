## Systematic Debugging

> Copied from Superpowers `systematic-debugging` v5.0.7 (MIT, © 2025 Jesse Vincent).
> Verbatim by design — see NOTICE.

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

### The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

### When to Use

Any technical issue: test failures · bugs in production · unexpected behavior · performance
problems · build failures · integration issues.

**ESPECIALLY when:** under time pressure · "just one quick fix" seems obvious · you've already
tried multiple fixes · previous fix didn't work · you don't fully understand the issue.

**Don't skip when:** the issue seems simple (simple bugs have root causes too) · you're in a
hurry (rushing guarantees rework) · someone wants it fixed NOW (systematic is faster than
thrashing).

### What is and is not an unexpected failure

Not every red test is a bug. Do not escalate normal TDD.

**NOT unexpected (normal TDD, keep going):**
- RED phase: test fails because the implementation doesn't exist yet → proceed to GREEN
- GREEN phase: test fails because the implementation is incomplete → keep writing code

**IS unexpected (escalate to the four phases):**
- A previously-passing test now fails after your change
- GREEN-phase code causes failures in unrelated tests
- Test fails for environmental reasons (missing config, service unavailable, flaky dependency)
- Error doesn't match what the test asserts — wrong failure mode entirely

### Feedback loop before hypothesis — HARD GATE

When an unexpected failure occurs, you MUST build a red-capable feedback loop BEFORE forming
any hypothesis about the cause. A red-capable loop is a single command that reliably
reproduces the specific failure. If you catch yourself reasoning about the cause before that
command exists — STOP. No feedback loop, no hypothesis.

If you cannot build a reliable loop after multiple attempts, STOP. List what you tried and ask
the user for help. Do not proceed without a signal.

### The Four Phases

You MUST complete each phase before proceeding to the next.

#### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully** — don't skip past errors or warnings; they often contain
   the exact solution. Read stack traces completely. Note line numbers, file paths, error codes.

2. **Reproduce Consistently** — can you trigger it reliably? What are the exact steps? Does it
   happen every time? If not reproducible → gather more data, don't guess.

3. **Check Recent Changes** — what changed that could cause this? `git diff`, recent commits,
   new dependencies, config changes, environmental differences.

4. **Gather Evidence in Multi-Component Systems** — when the system has multiple components
   (CI → build → signing, API → service → database), add diagnostic instrumentation BEFORE
   proposing fixes:

   ```
   For EACH component boundary:
     - Log what data enters component
     - Log what data exits component
     - Verify environment/config propagation
     - Check state at each layer

   Run once to gather evidence showing WHERE it breaks
   THEN analyze evidence to identify failing component
   THEN investigate that specific component
   ```

   Tag every temporary log with a unique prefix — `[DEBUG-a4f2]` — so you can grep and remove
   all of them before continuing.

5. **Trace Data Flow** — when the error is deep in the call stack: where does the bad value
   originate? What called this with the bad value? Keep tracing up until you find the source.
   Fix at source, not at symptom.

#### Phase 2: Pattern Analysis

1. **Find Working Examples** — locate similar working code in the same codebase. What works
   that's similar to what's broken?
2. **Compare Against References** — if implementing a pattern, read the reference
   implementation COMPLETELY. Don't skim — read every line.
3. **Identify Differences** — list every difference, however small. Don't assume "that can't
   matter".
4. **Understand Dependencies** — what other components does this need? What settings, config,
   environment? What assumptions does it make?

#### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis** — state clearly: "I think X is the root cause because Y." Write
   it down. Be specific, not vague.
2. **Test Minimally** — make the SMALLEST possible change to test the hypothesis. One variable
   at a time. Don't fix multiple things at once.
3. **Verify Before Continuing** — did it work? Yes → Phase 4. No → form a NEW hypothesis.
   DON'T add more fixes on top.
4. **When You Don't Know** — say "I don't understand X". Don't pretend to know. Ask for help.

#### Phase 4: Implementation

1. **Create Failing Test Case** — simplest possible reproduction. MUST have before fixing.
   Follow the TDD doctrine for writing it.
2. **Implement Single Fix** — address the root cause. ONE change at a time. No "while I'm
   here" improvements. No bundled refactoring.
3. **Verify Fix** — test passes now? No other tests broken? Issue actually resolved?
4. **If Fix Doesn't Work** — STOP. Count how many fixes you have tried.
   If < 3: return to Phase 1 and re-analyse with the new information.
   **If ≥ 3: STOP and question the architecture** (step 5). DON'T attempt Fix #4 without
   architectural discussion.
5. **If 3+ Fixes Failed: Question Architecture** — the pattern indicating an architectural
   problem: each fix reveals new shared state or coupling somewhere else; fixes require
   "massive refactoring"; each fix creates new symptoms elsewhere.
   Ask: is this pattern fundamentally sound? Are we sticking with it through sheer inertia?
   Should we refactor the architecture instead of fixing symptoms?
   **Discuss with your human partner before attempting more fixes.**
   This is NOT a failed hypothesis — this is a wrong architecture.

### Red Flags - STOP and Follow Process

If you catch yourself thinking:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

### Signals from your human partner that you're doing it wrong

- "Is that not happening?" — you assumed without verifying
- "Will it show us...?" — you should have added evidence gathering
- "Stop guessing" — you're proposing fixes without understanding
- "Ultrathink this" — question fundamentals, not just symptoms
- "We're stuck?" (frustrated) — your approach isn't working

**When you see these:** STOP. Return to Phase 1.

### Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

### Before you continue

Grep for your `[DEBUG-xxxx]` tag and remove every temporary artifact. A debug log shipped to
main is a finding against you in the next review.

### When Process Reveals "No Root Cause"

If systematic investigation shows the issue is truly environmental, timing-dependent, or
external: you've completed the process — document what you investigated, implement appropriate
handling (retry, timeout, error message), and add monitoring for future investigation.

**But:** 95% of "no root cause" cases are incomplete investigation.
