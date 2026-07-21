# craft — spec-driven SDLC toolkit

A lean, cross-IDE toolkit. Give it a **problem statement**; it drives requirements → design →
tasks → implement → review → archive using [OpenSpec], with [Superpowers] discipline built in.
Works with **Claude Code, Cursor, and GitHub Copilot**.

---

## How it works

You describe a problem. craft asks ONE clarifying question at a time, builds a spec, implements
test-first, reviews against the spec, and archives — fully guided. You never pick a skill,
agent, or model manually.

```
/craft-explore    →   /craft-propose   →   /craft-apply
  (fuzzy idea?)         (build spec)         (TDD impl)

/craft-review-spec →  /craft-review     →   /craft-archive   →   /craft-pr
  (spec vs code)        (code vs spec)        (verify + move)      (PR + survey)

/craft-pr-review                        ← review anyone's PR (standalone)
  (worktree → review → comment)

                  or just:

/craft-sdlc "describe your problem"   ← drives the full pipeline automatically
```

---

## Commands

| Command | When to use |
|---|---|
| `/craft-sdlc` | **Main entry point.** Describe any problem — drives the full pipeline. |
| `/craft-explore` | Fuzzy problem? Think it through first. Explore ideas, investigate code, compare options. No code written. |
| `/craft-propose` | Create OpenSpec artifacts (proposal + specs + design + tasks) in one step. |
| `/craft-apply` | Implement tasks test-first. RED → GREEN → REFACTOR per task. Iron Law enforced. |
| `/craft-review-spec` | Review specs against the codebase BEFORE implementation — find edge cases, missing scenarios, infeasible assumptions. Inverse of `/craft-review`. |
| `/craft-review` | Review implementation — spec compliance, code quality, security, definition-of-done gate. |
| `/craft-archive` | Verify review passed, assess delta spec sync, then archive the change. |
| `/craft-pr` | Create a PR from the project template + collect a Claude Code experience survey → Jira. |
| `/craft-pr-review` | **Standalone.** Review any PR in an isolated worktree — quality, security, defense-in-depth. Posts inline comments. |
| `/craft-init` | First-time setup. Re-run anytime to refresh `CLAUDE.md` or wire a new IDE. |

---

## Quick start

**Step 1 — Prerequisites**

```bash
# Superpowers plugin (Claude Code)
/plugin marketplace add obra/superpowers
/plugin install superpowers

# OpenSpec CLI
npm i -g @fission-ai/openspec@latest
openspec init
```

**Step 2 — Set up in your repo**

Copy the `craft/` folder into your repo, then in Claude Code:

```
/craft-init
```

This profiles your project, validates or creates `CLAUDE.md` (the single source of truth every
skill reads automatically), and wires Claude / Cursor / Copilot.

**Step 3 — Build something**

```
/craft-sdlc "add rate limiting to the public API"
/craft-sdlc "the login endpoint returns 500 when email has a plus sign"
/craft-sdlc "refactor the payment module to support multiple currencies"
```

Or drive phases manually:

```
/craft-explore "thinking about switching from REST to gRPC"
/craft-propose add-dark-mode
/craft-apply add-dark-mode
/craft-review add-dark-mode
/craft-archive add-dark-mode
/craft-pr TICKET-1234
```

---

## What's inside

```
craft/
├── commands/          Slash commands (10 total)
│   ├── craft-init.md
│   ├── craft-sdlc.md
│   ├── craft-explore.md
│   ├── craft-propose.md
│   ├── craft-apply.md
│   ├── craft-review-spec.md
│   ├── craft-review.md
│   ├── craft-archive.md
│   ├── craft-pr.md
│   └── craft-pr-review.md
├── skills/            Auto-activated by description (no manual invocation)
│   ├── spec-driven-sdlc/       Pipeline orchestrator
│   ├── writing-requirements/   EARS spec authoring
│   ├── designing-architecture/ Design validation
│   ├── planning-tasks/         Task ordering + TDD sequencing
│   ├── implementing-with-tdd/  RED-GREEN-REFACTOR discipline
│   └── reviewing-and-verifying/ Spec compliance + quality + archive
├── agents/            Context-isolated subagents
│   ├── codebase-explorer.md   Profiles the repo (read-only, Sonnet)
│   ├── pre-impl-spec-reviewer.md  Reviews specs vs codebase before implementation (read-only, Opus)
│   ├── post-impl-code-reviewer.md Reviews code vs specs after implementation (read-only, Opus)
│   └── pr-reviewer.md             Reviews any PR in isolation (read-only, Opus)
```

---

## IDE setup

| Tool | How craft works |
|---|---|
| **Claude Code** | Symlink `commands/` → `~/.claude/commands/`, `skills/` → `~/.claude/skills/`, `agents/` → `~/.claude/agents/`. `/craft-init` validates `CLAUDE.md` as the single source of truth. |
| **Cursor** | Reads `SKILL.md` natively — no extra setup. |
| **Copilot** | `/craft-init` can add `.github/copilot-instructions.md` as a pointer. |

---

## Design principles

**Less, but effective** — ten commands; you never pick a skill, agent, or model.

**Superpowers discipline baked in** — every command carries HARD-GATEs (no code without
a failing test, no "done" without real command output), AskUserQuestion one-at-a-time
for all clarification, and explicit Related skills cross-references.

**External verification only** — tests, linters, and `openspec validate` prove correctness.
Self-inspection is not verification. One correction round maximum.

**One source of truth** — the OpenSpec change folder. Each phase reads one artifact, writes one.
Delta specs merge to `openspec/specs/` on archive — the living spec stays current.

---

## Built on

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) — change lifecycle CLI
- [Superpowers](https://github.com/obra/superpowers) — HARD-GATEs, TDD, debugging discipline
- [Agent Skills spec](https://agentskills.io/specification) — portable `SKILL.md` format
