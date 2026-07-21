---
description: Learn this project and configure the craft SDLC toolkit. Validates or creates CLAUDE.md as the single source of truth, wires cross-IDE files, and checks for Superpowers and OpenSpec.
argument-hint: "[optional: notes about the project, or 'just create it' to skip interview]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Agent, AskUserQuestion
---

# /craft-init — set up and onboard

Set up the `craft` spec-driven SDLC toolkit in this repo. `CLAUDE.md` is the single source of
truth for project context — craft reads it, enriches it, and never creates a separate file.

Be conversational and educational in the final output — init is the start of a relationship,
not just a configuration script.

---

## Step 1 — Check Superpowers
Look for `superpowers` in `~/.claude/plugins/installed_plugins.json` or
`~/.claude/plugins/cache/*/superpowers`. If absent, tell the user:

> **Superpowers plugin not found.** This toolkit builds on Superpowers for brainstorming,
> TDD discipline, and verification. To install:
> ```
> /plugin marketplace add obra/superpowers
> /plugin install superpowers
> ```
> Continuing without it — but install it for the best experience.

Continue either way.

## Step 2 — Learn the project
Dispatch the `codebase-explorer` agent to profile the repo (keeps exploration out of main context).
Ask it for:
- Language(s) + version, build/test/lint commands (including single-test command), test framework
- Directory layout, DI/framework patterns, code style
- Existing agent conventions (CLAUDE.md, AGENTS.md, .cursor/rules, .cursorrules,
  .github/copilot-instructions.md, openspec/)
- **Do-NOT candidates**: files with `@Generated`, `auto-generated`, or `DO NOT EDIT` headers;
  migration directories (`db/migrations/`, `flyway/`, `liquibase/`, `alembic/`);
  lock files (`package-lock.json`, `Cargo.lock`, `yarn.lock`);
  CI/CD configs (`.github/workflows/`, `Jenkinsfile`, `.gitlab-ci.yml`);
  infra-as-code (`terraform/`, `.cloudos/`, `cdk/`);
  vendor/third-party directories (`vendor/`, `node_modules/`, `third_party/`)

It must quote config files as evidence.
Incorporate any notes the user passed in `$ARGUMENTS`.

## Step 3 — Check OpenSpec
If `openspec/` is absent, tell the user:
> OpenSpec is not initialised. Install and init with:
> ```
> npm i -g @fission-ai/openspec@latest
> openspec init
> ```
> Then re-run `/craft-init`. (Don't run global installs yourself — ask first.)

## Step 4 — Handle CLAUDE.md

Branch based on whether `CLAUDE.md` exists at the repo root.

### Path A — CLAUDE.md exists: Validate and enrich

1. Read the existing `CLAUDE.md`.

2. **Validate craft essentials.** Semantically check (not by section name — by content) whether
   CLAUDE.md contains:
   - Build command
   - Test command (full suite)
   - Test command (single test)
   - Lint / type-check command
   - OpenSpec commands (`openspec validate`, `openspec archive`)
   - `@AGENTS.md` import

3. **Check for Do-NOT section.** If no "Do NOT" / "Do not" / "Off-limits" section exists,
   propose one using the Do-NOT candidates detected by the explorer.

4. **Report findings:**
   - If everything is present: "Your CLAUDE.md has everything craft needs. No changes required."
   - If items are missing: list each missing item with:
     - **What's missing** (e.g., "Single-test command")
     - **Why craft needs it** (e.g., "The TDD skill runs individual tests during RED-GREEN cycles")
     - **Example content** (e.g., `mvn test -Dtest=ClassName#methodName`)

5. **Ask user:** "Want me to add all of these, pick specific ones, or skip?"

6. **For each approved item:** show the exact diff (what will be added and where), then apply
   only after user confirms.

7. **NEVER silently modify an existing CLAUDE.md.** Every change requires explicit approval
   with reasoning shown.

### Path B — CLAUDE.md absent: Generate

Check if the user said "just create it" (in `$ARGUMENTS` or conversation).

**If "just create it":** auto-generate `CLAUDE.md` from explorer findings without interview.

**Otherwise:** interview the user ONE question at a time:
1. "What does this project do and who uses it? (2-3 sentences for the overview)"
2. Present the detected Do-NOT candidates: "I found these files/directories that Claude should
   probably not modify. Which ones should I include?" Show each candidate with a brief
   explanation (e.g., "`.github/workflows/` — CI/CD pipelines, changes could break deployments").
3. "Any conventions or gotchas that differ from the language defaults?"

**Generated CLAUDE.md structure** (under 200 lines, directives not suggestions):

```markdown
# CLAUDE.md

<2-3 sentence project overview>

@AGENTS.md

## Commands

- Build: `<detected>`
- Test: `<detected>`
- Test single: `<detected>`
- Lint: `<detected>`
- OpenSpec: `openspec validate` | `openspec archive <name>`

## Conventions

<only rules that differ from language defaults — from explorer + user input>

## Do NOT

<approved Do-NOT candidates, as directives — e.g.:>
- Do not modify files in `src/generated/` — auto-generated code
- Do not edit migration files in `db/migrations/` — managed by migration tool
- Do not modify CI workflows in `.github/workflows/` without asking
```

Only include facts the explorer verified. Mark anything uncertain; ask the user.

## Step 5 — Migrate legacy PROJECT.md (if present)

If `PROJECT.md` exists at the repo root:

1. Read it and compare against `CLAUDE.md`.
2. If it contains unique content not in `CLAUDE.md`, show it as proposed additions (same
   diff-with-reasoning format as Path A).
3. If all content is redundant, report: "PROJECT.md content is already covered by CLAUDE.md."
4. Suggest deleting `PROJECT.md` and removing its `.gitignore` entry (if present).

## Step 6 — Cross-IDE reconciliation

Detect cross-IDE config files:
- `.cursorrules` or `.cursor/rules/`
- `.github/copilot-instructions.md`

For each file found:
1. Compare its content against `CLAUDE.md` (the canonical source).
2. Flag any drift: conventions, commands, or rules that differ.
3. Suggest alignment: "Your `.cursorrules` has `X` but CLAUDE.md says `Y`. Consider updating
   `.cursorrules` to match."

**Advisory only** — do NOT modify Cursor or Copilot files automatically.

If no cross-IDE configs are found, skip silently.

---

## Step 7 — Welcome message (always show this last, in full)

After completing the above, output the following welcome block. Adapt the examples to match
what the explorer found (use the real stack, real commands, real module names).

---

```
╔══════════════════════════════════════════════════════════════╗
║              craft — spec-driven SDLC toolkit                ║
║         You're set up. Here's how to use it.                 ║
╚══════════════════════════════════════════════════════════════╝

── What just happened ───────────────────────────────────────────
✓ CLAUDE.md validated  — your project's commands, conventions,
  and Do-NOT rules. Every skill reads this automatically.
  (or: ✓ CLAUDE.md created — ... if newly generated)
✓ Cross-IDE checked   — Cursor / Copilot configs compared.
✓ Superpowers: <installed ✓ | not installed — see above>

── How craft works ──────────────────────────────────────────────
You describe a problem. craft asks questions, builds a spec,
implements test-first, reviews, and archives — all guided.
You never pick a model, skill, or agent manually.

── Commands ─────────────────────────────────────────────────────
  /craft-sdlc      Main entry point — describe any problem and
                   craft drives the full pipeline automatically.

  /craft-explore   Fuzzy problem? Think it through first.
                   Explore ideas, investigate the codebase,
                   crystallise decisions — no code written.

  /craft-propose   Create OpenSpec artifacts (proposal + design
                   + tasks) for a named change in one step.

  /craft-apply     Implement tasks test-first (TDD Iron Law).
                   RED → GREEN → REFACTOR per task.

  /craft-review    Review implementation — spec compliance,
                   code quality, security, definition-of-done.

  /craft-archive   Verify review passed, then archive the change.

  /craft-pr        Create a PR from the template + collect a
                   Claude Code experience survey → Jira.

  /craft-init      Re-run anytime to refresh CLAUDE.md or
                   wire a new IDE.

── Examples (try one of these) ─────────────────────────────────
  /craft-sdlc "add rate limiting to the public API"
  /craft-sdlc "the login endpoint returns 500 when email has a plus sign"
  /craft-explore "thinking about switching from REST to gRPC"
  /craft-propose add-dark-mode

── What to expect ───────────────────────────────────────────────
craft will NOT jump to code. It will:

  1. Ask you ONE clarifying question at a time until it
     understands the problem, constraints, and success criteria.

  2. Propose 2–3 approaches with trade-offs, get your approval.

  3. Create OpenSpec artifacts (proposal → design → tasks)
     using the openspec CLI. You review before implementation.

  4. Implement each task test-first (failing test → code → pass).
     You see progress task by task.

  5. Run a two-stage review: spec compliance first, then
     code quality and security. Real command output only —
     no "should be fine" claims.

  6. Archive the change so your living spec stays current.

── Gates (what you'll be asked to approve) ──────────────────────
  → After brainstorming design    (before any artifacts)
  → After OpenSpec tasks are ready (before implementation)
  → After review passes           (before archive)

  You can always say "skip this gate" to move faster,
  but the gates exist to catch problems early.

── Tips ─────────────────────────────────────────────────────────
  • Describe the PROBLEM, not the solution. Let craft ask.
    ✓ "users are getting logged out randomly"
    ✗ "add a session refresh token with 15-min TTL"

  • If something seems wrong mid-pipeline, say so.
    craft will pause and ask what to do.

  • Re-run /craft-init after adding a new module or changing
    your build setup — it refreshes CLAUDE.md in place.

── Files craft uses ────────────────────────────────────────────
  CLAUDE.md           project context — commands, conventions,
                      Do-NOT rules (yours to edit freely)
  AGENTS.md           always-on pipeline rules for all IDEs
  openspec/           spec artifacts live here (after first run)

Ready. Run /craft-sdlc "<your problem>" to start.
```

---

If OpenSpec is not yet installed, add a note at the bottom of the welcome block:
> ⚠  OpenSpec not found — install it before running /craft-sdlc:
>    npm i -g @fission-ai/openspec@latest && openspec init
