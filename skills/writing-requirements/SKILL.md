---
name: writing-requirements
description: Use in phase 2 of the SDLC after brainstorming is complete and you need to capture approved intent as OpenSpec artifacts — running openspec-propose to create proposal.md, design.md, and tasks.md with EARS acceptance criteria.
---

# Writing Requirements

## Overview
Convert an approved brainstorming design into OpenSpec artifacts. This skill delegates to
`openspec-propose` for the actual artifact creation — do not hand-write proposal/design/tasks
files; let the CLI generate the correct structure.

**REQUIRED BACKGROUND:** You MUST have completed `superpowers:brainstorming` and have a
user-approved design before invoking this skill.

<HARD-GATE>
Do NOT invoke openspec-propose or create any OpenSpec change until superpowers:brainstorming
has produced a written design doc that the user has approved.
</HARD-GATE>

## Step 1 — Clarify before creating (if anything is still ambiguous)
Use **AskUserQuestion** for any remaining gap. One question per message. Ask the most
important unknown first. Typical questions:
- "What's the exact name for this change? (kebab-case, e.g. `add-rate-limiting`)"
- "Are there any constraints I should know about (performance, backwards compatibility, etc.)?"
- "What does success look like — how would we test this manually?"

Do NOT create the change until you have enough to write a solid proposal.

## Step 2 — Run openspec-propose
Invoke the `openspec-propose` skill. It will:
1. Run `openspec new change "<name>"`
2. Run `openspec status --change "<name>" --json` to get artifact order + paths
3. For each artifact, run `openspec instructions <artifact-id> --change "<name>" --json`
   and write the file following the template and instruction fields
4. Show progress: "Created proposal.md", "Created design.md", "Created tasks.md"
5. Run `openspec status` to confirm all `applyRequires` artifacts are done

Use the design doc from brainstorming as the primary input for each artifact. The brainstorming
output maps to OpenSpec artifacts:
- Intent + scope → `proposal.md` (Intent / Scope / Approach)
- Architecture decisions → `design.md` (Technical Approach / Decisions / Data Flow / File Changes)
- Implementation steps → `tasks.md` (numbered `- [ ]` checklist)

## EARS acceptance criteria (in delta specs)
Each requirement in `openspec/changes/<name>/specs/<cap>/spec.md` uses EARS form:
```markdown
### Requirement: <title>
WHEN <trigger>, the system SHALL <response>.

#### Scenario: <name>
- GIVEN <precondition>
- WHEN <trigger>
- THEN <expected result>
```
Every scenario must be testable — a reviewer must be able to write a failing test from it alone.

## Quality bar
- Every requirement traces to an approved brainstorming item (no invented scope).
- Every scenario is concrete and falsifiable (no "should be fast").
- Design decisions note at least one alternative and the reason it was rejected.
- Tasks are small enough to implement and verify in a single focused step.

## Gate
Run `openspec validate`. Show the status output. If validation passes, present the artifacts
to the user for a quick review. Ask: "Does the task list look right before we start implementing?"
Wait for confirmation.

## Related skills
- **REQUIRED before this skill:** `superpowers:brainstorming`
- **Artifact creation:** `openspec-propose`
- **After this skill:** `openspec-apply-change` + `implementing-with-tdd`
