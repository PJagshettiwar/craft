---
description: Learn this project and configure the craft SDLC toolkit. Verifies or creates CLAUDE.md as the single source of truth, wires cross-IDE files, and offers optional structural code intelligence.
argument-hint: "[notes about the project · 'just create it' to skip the interview · '--repair' to fix drift]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion
---

# /craft-init — set up, and earn trust in the map

`CLAUDE.md` is the single source of truth. craft reads it, verifies it, enriches it — and never
creates a parallel file.

**No Context Preflight here.** Every other command opens with one; this is the command that
*builds* what the preflight reads. Running it against a map that doesn't exist yet would be
circular.

Be conversational. Init is the start of a relationship, not a config script.

---

## Step 0 — Repair mode

If `$ARGUMENTS` contains `--repair`, skip to Step 2, walk each drift item one at a time,
propose a fix, apply only on approval, then jump to Step 6.

## Step 1 — Prerequisites

**OpenSpec.** Check `which openspec` and whether `openspec/` exists at the repo root.

- CLI missing → tell the user:
  > **OpenSpec CLI not found.** Install and initialise with:
  > ```
  > npm i -g @fission-ai/openspec@latest
  > openspec init
  > ```
  > craft needs CLI ≥ 1.6.0. Don't run global installs yourself — ask first.
- CLI present, `openspec/` absent → "Run `openspec init`, then re-run `/craft-init`."
- Both present → continue silently. Note the version: `openspec --version`.

**The openspec-\* skills.** If `.claude/skills/openspec-*` exists, tell the user once:

> `openspec init` installed its own skills alongside craft's commands. They trigger on the same
> intent. When you're driving a whole change, prefer craft's pipeline — it calls the same CLI
> and adds the design gate, the reuse check, TDD enforcement and review discipline. Note that
> `openspec update` will recreate them; that's expected, not a problem.

Continue either way. Record the results for the welcome message.

## Step 2 — Verify the existing map

```bash
bash "${CRAFT_HOME:-.}/scripts/craft-doctor.sh"
```

Show the report. This is the most useful thing init does on an existing project: a `CLAUDE.md`
nobody has checked in six months is not a source of truth, it is a set of confident-sounding
claims, and the agent will believe every one of them.

Read the output honestly for the user:

- `DRIFT` — proven wrong. Dead paths, missing binaries. Offer to fix each.
- `UNCHECKED` — **not** a problem. Symbol claims no language server was available to verify.
  If the count is high, that is the argument for Step 5.
- `STALE` — a section claims it was verified longer ago than it should be.
- `lines=N/400` — over the ceiling means it has stopped being read carefully.

No `CLAUDE.md` → skip to Step 3 Path B.

## Step 3 — Learn the project

Do this yourself, bounded. Map first, read only what you need, quote evidence.

- **Map** — `Glob` the top-level layout, find build files, entry points, test directories.
- **Read config, not source** — `pom.xml`, `package.json`, `pyproject.toml`, `Cargo.toml`,
  `go.mod`, `Makefile`, linter configs. These answer the commands question directly.
- **Sample, don't sweep** — two or three representative source files to read the code style.
  You are looking for conventions, not building an index.
- **Quote `file:line`** for every claim. Distinguish "the config says X" from "the code appears
  to intend X".

Establish: language(s) and version · build, test, single-test, lint commands · directory
layout · framework/DI patterns · code style · existing agent configs (`AGENTS.md`,
`.cursor/rules`, `.cursorrules`, `.github/copilot-instructions.md`).

**Do-NOT candidates** — look for: `@Generated` / `auto-generated` / `DO NOT EDIT` headers ·
migration dirs (`db/migrations/`, `flyway/`, `liquibase/`, `alembic/`) · lock files ·
CI/CD (`.github/workflows/`, `Jenkinsfile`, `.gitlab-ci.yml`) · infra-as-code (`terraform/`,
`cdk/`) · vendored dirs (`vendor/`, `node_modules/`, `third_party/`).

Fold in any notes from `$ARGUMENTS`.

### Path A — CLAUDE.md exists: validate and enrich

Check semantically (by content, not by heading name) for: build command · test command ·
single-test command · lint command · OpenSpec commands.

**The single-test command matters more than it looks.** TDD's verify-RED and verify-GREEN steps
are mandatory and both need it. Without one, `/craft-apply` hard-stops rather than degrading
quietly.

Report each missing item with: what's missing · why craft needs it · an example for this stack.
Then **AskUserQuestion**: "Add all of these, pick some, or skip?" For each approved item, show
the exact diff before applying.

**NEVER silently modify an existing CLAUDE.md.** Every change is shown and approved.

### Path B — CLAUDE.md absent: generate

If the user said "just create it", generate from your findings without an interview. Otherwise
ask ONE question at a time:

1. "What does this project do and who uses it? (2-3 sentences)"
2. Present the Do-NOT candidates: "I found these — which should Claude not modify?" One line of
   explanation each.
3. "Any conventions or gotchas that differ from the language defaults?"

Only include facts you verified. Mark anything uncertain and ask.

## Step 4 — The sections craft uses

All optional. Absent means craft still runs and says what it lacked. Offer each, one at a time.

```markdown
## Commands        <!-- verified: YYYY-MM -->   build · test · test-single · lint
## Architecture    <!-- verified: YYYY-MM -->   modules, boundaries, data flow
## Reuse Map       <!-- verified: YYYY-MM -->   shared helper → `Symbol` → what it's for
## Patterns        <!-- verified: YYYY-MM -->   pattern → canonical `Symbol`
## Rejected        <!-- verified: YYYY-MM -->   approach → why it was backed out
## Do NOT          <!-- verified: YYYY-MM -->   off-limits paths
## Review Config   <!-- verified: YYYY-MM -->   ignore globs · max findings · nit policy
```

**`## Reuse Map` — draft it, one approval at a time.** This is the section that stops the
fourth copy of the same helper getting written. Propose entries from what you found: shared
utilities, clients, validators, anything with more than two call sites. Key each by **symbol**,
never `file:line` — line anchors rot on the next commit, and the doctor can verify a symbol.

**`## Rejected` — ask, never draft.**

> "Has this team tried an approach and backed it out? Anything you'd not want a new engineer to
> propose again?"

Take their words. This is the one kind of knowledge no index, LSP or git archaeology fully
recovers, it is the cheapest section to write, and it is worth the most per line. If they have
nothing, leave the heading with a comment and move on.

**`## Review Config`** — reviewers honour this:

```markdown
## Review Config
- Ignore: `**/generated/**`, `**/*.pb.go`, `db/migrations/**`, `**/__snapshots__/**`
- Max findings per review: 10
- Nits: summary block only, never inline PR comments
```

**Cap the whole file at 400 lines.** If the draft is longer, cut — don't append. A CLAUDE.md
nobody finishes reading protects nobody.

Stamp `<!-- verified: YYYY-MM -->` on every section you touch, then re-run the doctor and show
that it is clean.

## Step 5 — Structural code intelligence (optional)

Measure the repo first, then make a real recommendation:

```bash
git ls-files | wc -l
git ls-files '*.<primary-ext>' | xargs wc -l 2>/dev/null | tail -1
```

Then tell the user the truth, including the part that argues against it:

```
── Structural code intelligence (optional) ──────────────────────

This project: ~<N> files, ~<L> lines of <language>.

What Serena does
  Runs a language server — the same engine your IDE uses — and exposes it
  over MCP. Instead of reading whole files to work out what calls what:
      find_symbol                → jump straight to a definition
      find_referencing_symbols   → every caller, accurately
      get_symbols_overview       → a file's shape without reading it

Why craft wants it
  • /craft-apply can check "does this already exist?" before writing code
  • /craft-review can compute blast radius without reading every caller
  • craft-doctor.sh can verify ## Reuse Map symbols instead of reporting
    them UNCHECKED  (you have <U> UNCHECKED right now)
  • Both stop guessing from grep, which misses DI and reflective wiring

The honest trade-off
  Serena's tool definitions cost ~1-2K context tokens in EVERY session
  before you use them. Below roughly 20k lines that overhead exceeds the
  saving, and people do report hitting context limits sooner with it on.
  First query on a large repo can stall while the language server warms up.

  → <RECOMMENDED / NOT RECOMMENDED> for this project at ~<L> lines.

Setup, if you want it
  claude mcp add serena -- uvx --from git+https://github.com/oraios/serena \
      serena start-mcp-server --context ide-assistant --project $(pwd)
  serena project index          # pre-warm; skip this and the first query may hang
  export MCP_TIMEOUT=60000      # if your client times out during warmup

Install now, later, or never? craft works without it — every command
falls back to grep and says which mode it ran in.
```

**Recommend against it under ~20k lines.** A toolkit that pushes a dependency costing more than
it saves is not worth trusting on the recommendations that matter.

## Step 6 — Cross-IDE reconciliation

Detect `.cursorrules`, `.cursor/rules/`, `.github/copilot-instructions.md`. For each, compare
against `CLAUDE.md` and flag drift:

> "Your `.cursorrules` says X but CLAUDE.md says Y. Consider aligning `.cursorrules`."

**Advisory only.** Never modify Cursor or Copilot files. None found → skip silently.

## Step 7 — Install symlinks

Symlink craft into `~/.claude/` so it works from any project. Absolute paths to this repo.

1. **Commands** — each `commands/*.md` → `~/.claude/commands/<file>`
2. **Skills** — each `skills/*/` → `~/.claude/skills/craft/<name>`

Before each: a regular file at the target → back up to `<target>.bak` and warn. A correct
symlink → skip silently. A wrong or broken symlink → replace.

**Clean up removed agents.** craft used to symlink subagent definitions into
`~/.claude/agents/`. It no longer ships any — every reviewer now runs in-session, which is why
you can watch it work. Remove stale links pointing into this repo:

```bash
for l in ~/.claude/agents/*.md; do
  [ -L "$l" ] || continue
  case "$(readlink "$l")" in
    *"$(pwd)"/agents/*) echo "removing stale agent symlink: $l"; rm "$l" ;;
  esac
done
```

Report a summary: created, already correct, replaced, removed.

## Step 8 — Welcome

```
╔══════════════════════════════════════════════════════════════╗
║              craft — spec-driven SDLC toolkit                ║
╚══════════════════════════════════════════════════════════════╝

── What just happened ───────────────────────────────────────────
✓ CLAUDE.md <verified | created> — drift: <N> · unchecked: <N>
✓ Cross-IDE checked
✓ Symlinks installed  (<N> stale agent links removed)
✓ OpenSpec: <version | not installed>
✓ Serena:   <installed | declined | not recommended at this size>

── How craft works ──────────────────────────────────────────────
Describe a problem. craft asks questions, builds a spec, implements
test-first, reviews, and archives. You never pick a model or an agent —
there are none to pick. Each phase runs in one session and hands the
next a file, not a conversation.

── Commands ─────────────────────────────────────────────────────
  /craft-sdlc         describe a problem, craft drives the pipeline
  /craft-explore      fuzzy problem? think it through first
  /craft-propose      create OpenSpec artifacts
  /craft-review-spec  drill the specs against the code before coding
  /craft-apply        implement test-first, reuse-checked
  /craft-review       spec compliance, quality, security, conciseness
  /craft-archive      verify, sync specs, write back what was learned
  /craft-pr           open a PR from the template
  /craft-pr-review    review anyone's PR (standalone)
  /craft-init         re-run anytime; --repair fixes drift

── What to expect ───────────────────────────────────────────────
craft will NOT jump to code. It asks ONE question at a time until the
problem is clear, proposes 2-3 approaches, gets your approval, then
builds each task test-first. Before writing anything it checks whether
the thing already exists — and says what it searched.

Every phase declares what it knows and, more importantly, what it
does NOT know. If you see UNKNOWN, that is the system being honest,
not the system failing.

── Gates ────────────────────────────────────────────────────────
  → design approved        (before any artifact)
  → task list approved     (before any code)
  → review passed          (before archive)

Say "skip this gate" to move faster. craft will never skip one quietly.

── Tips ─────────────────────────────────────────────────────────
  • Describe the PROBLEM, not the solution.
      ✓ "users are getting logged out randomly"
      ✗ "add a session refresh token with 15-min TTL"
  • Run /compact between phases — craft will remind you.
  • Re-run /craft-init after adding a module or changing the build.

Ready. Run /craft-sdlc "<your problem>" to start.
```

If OpenSpec is missing, append:
> ⚠ Install OpenSpec before `/craft-sdlc`: `npm i -g @fission-ai/openspec@latest && openspec init`
