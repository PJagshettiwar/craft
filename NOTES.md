# generic — Design & Progress Notes

A lean, cross-IDE, self-configuring **spec-driven SDLC toolkit**. User provides a problem
statement; the kit runs requirements → design → tasks → implement → verify → archive using
OpenSpec artifacts, auto-selecting the right skill and model internally.

## Principles (why this shape)
- **Less, but effective** — 6 skills + 2 read-only agents. No user-picked agents or models.
- **One entry point** — `/sdlc "<problem>"`. Skills auto-activate by `description`.
- **Self-configuring** — `/init` learns the project (Superpowers + explorer agent) and writes
  ONE `PROJECT.md` profile that every skill references for "flavor". No per-file edits.
- **Cross-IDE** — authored as portable `SKILL.md` + root `AGENTS.md`. `/init` mirrors into
  Cursor (`.cursor/rules`) and Copilot (`.github/instructions`) and wires Claude via CLAUDE.md.
- **Accuracy first** — grounding, quote-before-answer, "I don't know", definition-of-done gate,
  external-verification-only loops. Placed in AGENTS.md so all tools apply them every turn.

## Research basis (late-2025)
- **Superpowers** (obra) — process-discipline skills, hard gates, verification-before-completion. Base model.
- **Agent Skills spec** (agentskills.io) — SKILL.md now read by Claude, Cursor, Copilot, 40+ tools. <500 lines, description = when-to-use only.
- **AGENTS.md** (Linux Foundation, Aug 2025) — cross-tool always-on file. Cursor/Copilot read natively; Claude does NOT (needs @import/symlink).
- **OpenSpec** (Fission-AI) — delta-spec lifecycle: `openspec/changes/<name>/{proposal,design,tasks}.md` + delta `specs/`; `openspec validate`/`archive`. Deltas merge into `openspec/specs/` on archive.
- **EARS notation** — `WHEN <trigger> THE SYSTEM SHALL <response>` (6 forms). Each scenario → a test.
- **Context engineering** (Anthropic) — accuracy comes from grounding + external verification, NOT self-critique (mirrors lower accuracy). Cap correction at one external-feedback round. Subagents for context isolation.
- **Model routing** (wshobson) — opus: reasoning-heavy (requirements/design/review); sonnet: build/test/debug; haiku: docs/ops.

## Components
| Type | Name | Model | Role |
|------|------|-------|------|
| skill | spec-driven-sdlc | (main) | Orchestrator/entry. Routes the pipeline. |
| skill | writing-requirements | (main) | proposal.md + EARS delta specs |
| skill | designing-architecture | (main) | design.md + ADRs |
| skill | planning-tasks | (main) | tasks.md checklist |
| skill | implementing-with-tdd | (main) | code + tests, check off tasks |
| skill | reviewing-and-verifying | (main) | two-stage review + security + DoD + openspec validate/archive |
| agent | codebase-explorer | sonnet | read-only; learns project (used by /init + grounding) |
| agent | spec-reviewer | opus | read-only; reviews code + validates vs delta specs + security |
| command | /init | — | learn project → PROJECT.md; prompt Superpowers install; mirror cross-IDE |
| command | /sdlc | — | take problem statement → run spec-driven-sdlc |
| hook | suggest-sdlc.sh | — | optional UserPromptSubmit hint (Claude only) |

## The pipeline (gates)
1. Requirements → `proposal.md` + delta specs (EARS) — **gate: user approves**
2. Design → `design.md` — **gate: user approves**
3. Tasks → `tasks.md` — **gate: `openspec validate`**
4. Implement (TDD) → code + `[x]` boxes — **gate: tests pass**
5. Review & Verify → spec-reviewer + DoD — **gate: `openspec validate --strict`**
6. Archive → `openspec archive` (deltas merge to specs)

## Progress log
- [x] Research (agents/skills best practices, OpenSpec, context engineering, cross-IDE)
- [x] Scaffold `generic/` + this NOTES.md
- [x] AGENTS.md, plugin.json
- [x] 6 skills
- [x] 2 agents
- [x] 2 commands + optional hook (executable)
- [x] README.md
- [x] v0.2 — Added Superpowers skill references, OpenSpec skill delegation, HARD-GATEs, AskUserQuestion clarification pattern, TodoWrite, Related skills sections, output format templates
- [ ] Pressure-test skills with subagents (Superpowers Iron Law) — follow-up
- [ ] Try end-to-end on a real ticket; refine wording

## Open follow-ups
- Pressure-test each skill with subagents (Superpowers Iron Law) — recommended before wide rollout.
- Optional: publish as a marketplace plugin.
