# craft — spec-driven SDLC toolkit

Give it a **problem statement**; it drives explore → propose → implement → review → archive,
emitting [OpenSpec] artifacts. Works with **Claude Code, Cursor, and GitHub Copilot**.

craft is **self-contained**. It installs nothing, invokes no other plugin, and spawns no
subagents. Every command is one file you can read top to bottom.

---

## What makes it different

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

**It looks before it writes.** `/craft-apply` cannot write a test until it has emitted
`REUSE: extending X` or `NEW: searched <terms>, nothing found` — checked against the Reuse Map,
the symbol table, and git history. The most common defect in AI-written code is the fourth copy
of a helper that already exists; this is the thing that stops it.

**It reads git as memory.** "We tried that in March and reverted it" is knowledge no index or
language server holds. craft derives it — bounded `git log -S`, `--diff-filter=D`, `blame` — and
a diff that undoes a prior deliberate commit is a review finding with the SHA attached.

**It doesn't trust the docs blindly.** `scripts/craft-doctor.sh` verifies `CLAUDE.md` against
reality — dead paths, missing binaries, stale sections — with no model involved. Anything it
cannot prove is reported `UNCHECKED`, never `DRIFT`: a false drift signal is worse than none.

**It learns.** `/craft-archive` writes back at most three lines to `CLAUDE.md` — a new shared
utility, an established pattern, an approach that was tried and abandoned. The cap is what keeps
it from becoming an auto-generated wiki, which measurably makes agents worse.

---

## Pipeline

```
/craft-explore    →   /craft-propose   →   /craft-apply
  (fuzzy idea?)         (build spec)         (TDD impl)

/craft-review-spec →  /craft-review-implementation     →   /craft-archive   →   /craft-pr
  (spec vs code)        (code vs spec)        (verify + learn)     (PR + survey)

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

## Quick start

```bash
npm i -g @fission-ai/openspec@latest   # CLI >= 1.6.0
openspec init
```

Then in Claude Code:

```
/craft-init
```

It verifies or creates `CLAUDE.md`, drafts a Reuse Map with your approval, asks what your team
has already tried and rejected, wires Cursor/Copilot, and — after measuring your repo — tells
you honestly whether optional structural code intelligence is worth its per-session cost.

```
/craft-sdlc "add rate limiting to the public API"
/craft-sdlc "the login endpoint returns 500 when email has a plus sign"
```

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
