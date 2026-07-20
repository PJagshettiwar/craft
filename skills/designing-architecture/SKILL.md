---
name: designing-architecture
description: Use when the brainstorming design doc needs technical depth before OpenSpec artifacts are created — verifying architecture decisions, catching design gaps, and grounding the design in the real codebase. Use before or during openspec-propose.
---

# Designing Architecture

## Overview
Validate and deepen the brainstorming design into a technically sound, codebase-grounded
architecture before committing it to OpenSpec artifacts. This is the bridge between the
"what" (brainstorming) and the "how" (design.md).

**REQUIRED BACKGROUND:** `superpowers:brainstorming` must have produced an approved design.
Ground every decision in the actual codebase — dispatch `codebase-explorer` rather than
assuming what exists.

## Step 1 — Understand the existing system first
Use **AskUserQuestion** if the scope is unclear. Then dispatch `codebase-explorer` to answer:
- What modules/components are affected?
- What existing patterns should this follow?
- What are the dependencies and interfaces involved?

Never propose a design that contradicts real codebase structure. Quote the evidence.

## Step 2 — Validate design decisions
For each architectural decision in the brainstorming design:
1. Restate which approved requirement it satisfies (traceability).
2. Confirm it matches the existing patterns in this codebase (from `PROJECT.md` and explorer).
3. State confidence: high / medium / low.
4. For medium/low-confidence decisions, use **AskUserQuestion** before committing:
   > "I'm considering [option A] because [reason], but [option B] is also possible.
   > Which fits better with your goals?"

## Step 3 — The design.md structure (for openspec-propose)
The `openspec instructions design --change "<name>" --json` will provide the exact template.
Typically:
```markdown
## Technical Approach
<component interactions; keep to essentials>

## Architecture Decisions
### Decision: <title>
- Choice: <what>   Why: <grounded rationale>
- Alternatives: <options + why rejected>   Confidence: high | medium | low

## Data Flow
<how information moves; a small diagram if it genuinely aids understanding>

## File Changes
- `path/to/file` — new | modified | deleted: <what and why>
```

## Key design principles (from PROJECT.md conventions)
- **Reuse first.** Prefer existing patterns before introducing new abstractions.
- **Simplest design that meets requirements.** Complexity only when a requirement forces it.
- **Every decision traces to a requirement.** No gold-plating; no speculative abstractions.
- **Flag uncertainty.** A low-confidence decision surface to the user > a wrong decision shipped.

## Gate
Every requirement from the brainstorming design maps to a design decision. Every decision
has a rationale. No orphaned decisions. Confirm with the user on anything low-confidence
before openspec-propose runs.

## Related skills
- **REQUIRED before this skill:** `superpowers:brainstorming`
- **Plan structure guidance:** `superpowers:writing-plans` (grounding architectural decisions in structured plans)
- **Codebase exploration:** dispatch `codebase-explorer` agent
- **After this skill:** `writing-requirements` (openspec-propose)
