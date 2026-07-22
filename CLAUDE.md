# CLAUDE.md

craft is a spec-driven SDLC toolkit for Claude Code. It provides slash commands, skills, and agents that guide developers through a structured pipeline: explore, propose, implement (TDD), review, archive. Installed as a Claude Code plugin or via symlinks.

## Commands

- OpenSpec: `openspec validate` | `openspec archive <name>`

No build, test, or lint commands — this is a pure-Markdown toolkit.

## Conventions

- All commands and agents use YAML front-matter (`description:`, `allowed-tools:`, `model:`, etc.)
- Skills follow the Superpowers SKILL.md format with `<HARD-GATE>` blocks
- One-question-at-a-time pattern enforced across interactive commands
- Model routing: opus for reasoning/review, sonnet for build/debug/explore, haiku for docs/ops

## Do NOT

- Do not modify files in `openspec/` directly — managed by the `openspec` CLI
- Do not modify `.claude-plugin/plugin.json` without asking — plugin manifest for marketplace
- Do not modify untracked working files (`medium-post*.md`, `craft-gap-analysis.md`) — personal drafts, not part of the toolkit
