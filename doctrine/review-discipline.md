## Review Discipline

How to read, and what to say. Both halves matter: a review that reads everything costs more
than it returns, and a review that says everything gets muted.

### Read budget — you are not indexing the repo

**Do not read every changed file in full.** On a ten-file change that is thousands of lines of
context to answer questions most of them don't raise.

| Read | When |
|---|---|
| diff hunks + ~40 lines of surrounding context | default, every file |
| the whole file | it is new · it is under ~150 lines · the diff changes control flow you cannot follow from the hunk |
| a file not in the diff | a symbol query or the spec told you it matters — a caller, an interface, a test |

Everything else: answer it with a symbol query or a targeted grep, not a read.

**Declare what you read in full, and why.** One line at the end of the review. A budget nobody
can audit is a preference.

### Cite as you read — there is no second pass

When you read a line you intend to cite, **capture the quote and its line number then**. Do not
plan to re-read files at the end to check citations; that doubles the cost of the entire review
to catch line drift.

If you reach the write-up without a verbatim quote for a finding, **cite the file and drop the
line number**. A finding with no line is honest. A finding with a guessed line is worse than no
finding — a wrong line number posted on a teammate's PR costs more trust than the finding was
worth.

### Effort proportional to the change

| Size | How |
|---|---|
| < 300 lines changed | diff + targeted queries. No worktree needed. |
| 300 - 1500 | the standard path |
| > 1500 | ask the user which files matter most before starting |

A review spread evenly over 2,000 lines finds nothing. Say what you prioritised.

### Model, and when to escalate

Run on **sonnet**. The intelligence in this review comes from the project knowledge you loaded
and the queries you ran, not from the model tier.

If you identify a **probable Critical** — a security vulnerability, data-loss risk, or race
condition — state it and add:

```
ESCALATE: opus re-review of <file> — <one line on the suspected mechanism>
```

Then stop reasoning about it. Deep exploit analysis on the cheap tier produces confident
nonsense. The escalation path is what makes running on sonnet safe.

### Finding discipline — the review nobody reads is worth nothing

Teams ignore 70-90% of AI review comments. The cost is not the noise; it is that the one
finding that mattered was comment #43 and nobody got that far.

**Honour `## Review Config`.** Never review generated code, migrations, lockfiles, snapshots or
vendored paths. If the section is absent, apply the obvious defaults and say you did.

**Cap at 10 findings — after sorting by severity.** Over that, report the top 10 and one line:
`N further nits suppressed.` The cap can never suppress a Critical; if you have 11 Criticals,
report 11 and say why.

**Nits never become inline comments.** They go in one collapsed summary block. Inline threads
are for Critical and Important only.

**Tag every finding with confidence:**

- `CERTAIN` — you quoted the code that proves it
- `LIKELY` — you inferred it from strong evidence but did not fully trace it
- anything weaker → **delete it**, do not post it

**The last filter, applied to every finding before it ships:**

> Would a senior engineer on this team actually leave this comment?

If no, delete it. Reviewing is not proving you looked.
