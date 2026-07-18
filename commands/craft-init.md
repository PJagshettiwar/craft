---
description: Learn this project and configure the craft SDLC toolkit for Claude, Cursor, and Copilot. Writes PROJECT.md, wires cross-IDE files, checks for Superpowers, and walks the user through what to do next.
argument-hint: "[optional: notes about the project]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Agent, AskUserQuestion
---

# /craft-init — set up and onboard

Set up the `craft` spec-driven SDLC toolkit in this repo, then walk the user through how to use
it. Be conversational and educational in the final output — init is the start of a relationship,
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
Ask it for: language(s) + version, build/test/lint commands, test framework, directory layout,
DI/framework patterns, code style, and any existing agent conventions (CLAUDE.md, AGENTS.md,
.cursor/rules, openspec/). It must quote config files as evidence.
Incorporate any notes the user passed in `$ARGUMENTS`.

## Step 3 — Write `PROJECT.md`
Write `PROJECT.md` at the repo root from the explorer's findings. This is the single "flavor"
file every skill and agent reads — do NOT edit individual skills.

```markdown
# PROJECT.md — project profile (read by the craft SDLC toolkit)
## Stack
<languages, versions, key frameworks>
## Commands
- Build: <cmd>
- Test: <cmd>   (single test: <cmd>)
- Lint / type-check: <cmd>
- OpenSpec: openspec validate | openspec archive <name>
## Layout
<top-level modules/dirs and what they hold>
## Conventions
<indent, naming, line length, error handling, logging, DI, test naming>
## Notes
<anything unusual an implementer must know>
```
Only include facts the explorer verified. Mark anything uncertain; ask the user.

## Step 4 — Check OpenSpec
If `openspec/` is absent, tell the user:
> OpenSpec is not initialised. Install and init with:
> ```
> npm i -g @fission-ai/openspec@latest
> openspec init
> ```
> Then re-run `/craft-init`. (Don't run global installs yourself — ask first.)

## Step 5 — Wire cross-IDE
Ask which tools to wire (Claude / Cursor / Copilot / all):
- **Claude Code:** add `@AGENTS.md` and `@PROJECT.md` to `CLAUDE.md` (create if missing) so
  Claude reads the always-on pipeline rules. Also add the source-of-truth rule:
  ```
  ## Spec Workflow
  - ALL specs MUST use OpenSpec format (`openspec/changes/<name>/`)
  - NEVER treat brainstorming design docs as the final spec
  - After brainstorming approval, ALWAYS proceed to `/craft-propose`
  ```
- **Cursor:** `AGENTS.md` is read natively — no changes needed.
- **Copilot:** `AGENTS.md` is read natively. Optionally create
  `.github/copilot-instructions.md` as a pointer. Ask before creating.
Use symlinks, not copies. Idempotent — safe to re-run.

---

## Step 6 — Welcome message (always show this last, in full)

After completing the above, output the following welcome block. Adapt the examples to match
what the explorer found (use the real stack, real commands, real module names from PROJECT.md).

---

```
╔══════════════════════════════════════════════════════════════╗
║              craft — spec-driven SDLC toolkit                ║
║         You're set up. Here's how to use it.                 ║
╚══════════════════════════════════════════════════════════════╝

── What just happened ───────────────────────────────────────────
✓ PROJECT.md written  — your project's stack, commands, and
  conventions. Every skill reads this automatically.
✓ Cross-IDE wired     — Claude / Cursor / Copilot are configured.
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

  /craft-init      Re-run anytime to refresh PROJECT.md or
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
    your build setup — it refreshes PROJECT.md in place.

── Files craft created ──────────────────────────────────────────
  PROJECT.md          project profile (edit freely)
  AGENTS.md           always-on pipeline rules for all IDEs
  openspec/           spec artifacts live here (after first run)

Ready. Run /craft-sdlc "<your problem>" to start.
```

---

If OpenSpec is not yet installed, add a note at the bottom of the welcome block:
> ⚠  OpenSpec not found — install it before running /craft-sdlc:
>    npm i -g @fission-ai/openspec@latest && openspec init
