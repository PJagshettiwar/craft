# craft — spec-driven SDLC toolkit

**AI doesn't need to write better code. It needs to stop writing code nobody asked for.**

craft encodes what a senior engineer does before touching the keyboard — check what exists, know
the edge of your own knowledge, remember what was tried and reverted — into doctrine the model
can't rationalise away. Give it a problem statement; it drives explore → propose → implement → review → archive, emitting
[OpenSpec] artifacts. Works with **Claude Code, Cursor, and GitHub Copilot**.

craft is **self-contained**. It installs nothing, invokes no other plugin, and spawns no
subagents. Every command is one file you can read top to bottom.

---

## Why your team should adopt craft

1. **Architect lens, not a fresher.** craft reads your codebase *before* reading the spec — like the senior who's been paged at 3am, not the intern who just read the ticket.
2. **Anti-hallucination gate.** Every phase forces AI to declare `UNKNOWN:` — what it could not determine and what would resolve it. Silent assumptions become visible ones you correct in five seconds.
3. **Reuse-first enforcement.** `/craft-apply` cannot write a test until it proves nothing reusable exists — killing the #1 AI defect: the fourth copy of a helper that already lives three files over.
4. **Git as institutional memory.** "We tried that in March and reverted it" is knowledge no docs hold. craft derives it from `git log -S` and `blame`, and flags a diff that undoes a prior deliberate commit.
5. **TDD Iron Law.** No production code without a failing test first. Wrote code before the test? Delete it, start over. The doctrine is blunt because the rationalizations are predictable.

---

## How it thinks

**It behaves like the engineer who wrote your codebase, not one who just read the ticket.**

Every phase opens by establishing what it actually knows — the owning module, the nearest
sibling implementation, who calls the thing, which tests cover it, when it last changed — and
then declares what it does *not* know:

```
CONTEXT: module=auth siblings=SessionFilter.java callers=4 tests=AuthFilterTest last-touched=2026-03-11 a7981ec
KNOWN:   token validation already lives in TokenValidator; the Reuse Map points at it
UNKNOWN: whether the refresh path is expected to share that validator — needs the ticket author
MODE:    grep-only
```

`UNKNOWN:` may not be empty by default. An author knows the edge of their knowledge; a fresher
assumes. That line turns a silent assumption into one you can correct in five seconds.

---

## Pipeline

```
/craft-explore    →   /craft-propose   →   /craft-apply
  (fuzzy idea?)         (build spec)         (TDD impl)

/craft-review-spec →  /craft-review-implementation  →  /craft-archive  →  /craft-pr
  (spec vs code)        (code vs spec)                  (verify + learn)    (PR + survey)

/craft-review-pr                        ← review anyone's PR (standalone)

                  or just:

/craft-sdlc "describe your problem"   ← drives the whole thing
```

One phase per session. Each ends by writing a file and telling you to `/compact` — quality
degrades from about 70% context fill, and you do not want the review happening there.

## Commands

| Command | When to use |
|---|---|
| `/craft-init` | **Run this first.** Setup. `--repair` fixes CLAUDE.md drift. Re-run anytime. |
| `/craft-sdlc` | **Main entry point.** Describe any problem; it drives the pipeline. |
| `/craft-explore` | Fuzzy problem? Think it through. Checks whether it's been tried before. No code. |
| `/craft-propose` | OpenSpec artifacts in one step. Each scenario names the symbols it touches. |
| `/craft-apply` | Implement test-first. Reuse check blocks the first test of every task. |
| `/craft-review-spec` | Drill the specs against the codebase *before* coding. |
| `/craft-review-implementation` | Spec compliance, quality, security, conciseness & reuse, definition of done. |
| `/craft-archive` | Verify, sync delta specs, write back what was learned, archive. |
| `/craft-pr` | PR from the project template + experience survey. |
| `/craft-review-pr` | **Standalone.** Review any PR in an isolated worktree. Posts inline comments. |

## Quick start (5 minutes)

**Prerequisites:** [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed.

```bash
# 1. Install OpenSpec CLI (required, >= 1.6.0)
npm i -g @fission-ai/openspec@latest
openspec init

# 2. Install craft as a Claude Code plugin
claude plugin add /path/to/craft
# — or symlink manually: —
# /craft-init handles this for you
```

**First session:**

```
/craft-init
```

This verifies or creates `CLAUDE.md`, drafts a Reuse Map with your approval, asks what your
team has already tried and rejected, and wires Cursor/Copilot if present.

**Start working:**

```
/craft-sdlc "add rate limiting to the public API"
/craft-sdlc "the login endpoint returns 500 when email has a plus sign"
```

craft drives the full pipeline: explore, propose, implement (TDD), review, archive, PR.
Each phase is one session. After each phase, `/compact` and run the next command.

**Just want to review a PR?** `/craft-review-pr` works standalone — no setup beyond
`/craft-init`.

## What you need

| Requirement | Required? | Notes |
|---|---|---|
| Claude Code | Yes | Primary runtime |
| OpenSpec CLI >= 1.6.0 | Yes | `npm i -g @fission-ai/openspec@latest` |
| git | Yes | Used for history lookups |
| A test runner | Yes, for `/craft-apply` | Resolved from CLAUDE.md or auto-detected |
| Cursor / Copilot | No | craft-init detects and wires if present |
| Serena (LSP MCP) | No | Optional; craft degrades to grep |

## What's inside

```
craft/
├── commands/     10 slash commands, each fully self-contained
├── doctrine/     shared instruction text, single source of truth
│   ├── architect.md          the lens + the ladder + forced per-phase output
│   ├── preflight.md          CONTEXT/KNOWN/UNKNOWN, source hierarchy, git-as-memory
│   ├── review-discipline.md  read budget, cite-as-you-read, finding caps
│   ├── tdd.md                Iron Law, RED-GREEN-REFACTOR, test-validity rules
│   ├── debugging.md          root cause before fixes, four phases
│   └── verification.md       evidence before claims
├── skills/craft-sdlc/        the one skill — a thin spine, auto-triggers on a problem
└── scripts/
    ├── craft-doctor.sh       verifies CLAUDE.md; --tests catches suite weakening
    ├── sync-doctrine.sh      inlines doctrine into commands (--check gates CI)
    └── check-doctrine.sh     proves the copied doctrine is present and intact
```

Doctrine is **inlined into commands at build time**, not referenced at runtime. Edit
`doctrine/*.md`, run `scripts/sync-doctrine.sh`. Commands stay literally self-contained; there
is no hop that can silently fail to happen.

## Measuring impact

`/craft-pr` collects a 6-question experience survey after every PR — time with AI vs without,
percentage AI-written, manual steps needed. Results are logged locally to
`.craft/survey-log.jsonl` (one JSON line per change) and optionally posted to Jira.

**View your survey data:**

```bash
# Pretty-print all survey entries
cat .craft/survey-log.jsonl | python3 -m json.tool --json-lines

# Quick summary: time saved per change
cat .craft/survey-log.jsonl | python3 -c "
import json, sys
for line in sys.stdin:
    d = json.loads(line)
    print(f\"{d['date'][:10]}  {d.get('ticket','—'):12s}  without={d['time_without_ai']:15s}  with={d['time_with_ai']:15s}  ai={d['ai_pct']}\")
"
```

Even 5–10 entries make the ROI case concrete. If your team uses Jira, survey answers are also
posted as ticket comments — search for "Ticket AI debrief" to aggregate across the project.

## Design principles

**No dependencies at runtime.** No plugin invocations, no subagents, no required MCP server.
Optional structural tooling is detected and degrades to grep, and every command states which
mode it ran in.

**No subagents, deliberately.** Review runs in a fresh session reading files, not in a spawned
agent. Same isolation, no context-handoff loss, and you can watch it work.

**Evidence before claims.** Tests, linters and `openspec validate` prove correctness.
Self-inspection is not verification.

**Human-authored knowledge, machine-verified.** `CLAUDE.md` is written by people and checked by
a script. craft never regenerates it — auto-generated context files measurably reduce task
success.

**Code beats prose.** When `CLAUDE.md` and the codebase disagree, the codebase wins and the doc
is wrong. That is what makes a stale doc survivable instead of dangerous.

## Built on

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) — change lifecycle CLI (>= 1.6.0)
- [Superpowers](https://github.com/obra/superpowers) — TDD, debugging and verification doctrine,
  copied under MIT with attribution. See [NOTICE](NOTICE).
- [Agent Skills spec](https://agentskills.io/specification) — portable `SKILL.md` format

[OpenSpec]: https://github.com/Fission-AI/OpenSpec
