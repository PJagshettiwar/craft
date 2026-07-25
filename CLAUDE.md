# CLAUDE.md

craft is a self-contained spec-driven SDLC toolkit for Claude Code. Slash commands guide a
developer through explore → propose → implement (TDD) → review → archive, emitting OpenSpec
artifacts. It invokes no other plugin and spawns no subagents. Installed as a plugin or via
symlinks.

## Commands            <!-- verified: 2026-07 -->

- Verify CLAUDE.md: `scripts/craft-doctor.sh`
- Test-suite weakening check: `scripts/craft-doctor.sh --tests`
- Test (the only suite craft has): `scripts/craft-doctor.sh --selftest`
- Doctrine present in commands: `scripts/check-doctrine.sh`
- Doctrine matches upstream: `scripts/check-doctrine.sh --sources`
- Regenerate inlined doctrine: `scripts/sync-doctrine.sh`
- CI gate for the above: `scripts/sync-doctrine.sh --check`
- OpenSpec: `openspec validate` | `openspec archive <name>`

## Architecture        <!-- verified: 2026-07 -->

- `commands/` — 10 slash commands, each fully self-contained, read top to bottom
- `doctrine/` — shared instruction text, the single source of truth
- `skills/craft-sdlc/` — the only skill; a thin spine that routes to commands
- `scripts/` — deterministic checkers, no LLM involved

Doctrine is **inlined into commands at build time**, never referenced at runtime. Generated
regions sit between `<!-- doctrine:<name>:start -->` and `:end` markers.

## Reuse Map           <!-- verified: 2026-07 -->

- `scripts/craft-doctor.sh` — the only place that parses CLAUDE.md. Add checks here, not in a
  new script.
- `scripts/sync-doctrine.sh` — the only writer of generated command regions.
- `doctrine/preflight.md` — the CONTEXT/KNOWN/UNKNOWN block. Every phase gets it from here.
- `doctrine/architect.md` — the lens and the ladder. Every phase gets it from here.
- `doctrine/review-discipline.md` — read budget and finding caps. Both reviewers share it.

## Patterns            <!-- verified: 2026-07 -->

- YAML front-matter on every command: `description`, `argument-hint`, `allowed-tools`,
  and `model` where the tier matters
- `<HARD-GATE>` blocks for anything that must not be rationalised away
- One question at a time via `AskUserQuestion`
- Anchor knowledge by **symbol**, never `file:line` — line anchors rot on the next commit

## Rejected            <!-- verified: 2026-07 -->

- **Subagents for review and exploration** — removed in v2. They lost decision context across
  the handoff and made the process unwatchable. Review now runs in a fresh session instead.
- **`@file` references to pull in shared doctrine** — investigated in wave 0 and rejected: no
  installed plugin command uses `@`-expansion, and the one real-world usage is prose telling
  the model to Read a file, i.e. the runtime hop v2 exists to remove. Build-time inlining
  replaced it.
- **Reporting unverifiable symbol claims as DRIFT** — a looser path rule produced 12 false
  positives and 0 real ones on a 283-line CLAUDE.md. Ambiguity now resolves to `UNCHECKED`.

## Do NOT              <!-- verified: 2026-07 -->

- Do not hand-edit generated regions in `commands/*.md` — edit `doctrine/*.md` and run
  `scripts/sync-doctrine.sh`
- Do not paraphrase text marked verbatim in `NOTICE` — its exact wording is what makes it work
- Do not modify files in `openspec/` directly — managed by the `openspec` CLI
- Do not modify `.claude-plugin/plugin.json` without asking — marketplace manifest
- Do not modify untracked working files (`medium-post*.md`, `craft-gap-analysis.md`,
  `NOTES.md`) — personal drafts, not part of the toolkit
