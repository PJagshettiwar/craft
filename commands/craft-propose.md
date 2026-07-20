---
description: Propose a new change with all artifacts generated in one step — proposal, design, specs, and tasks. Use after craft-explore or when the problem is clear. Requires problem clarity before running.
argument-hint: "<change name or description>"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion, Agent
---

# /craft-propose — propose a change

Read `PROJECT.md` for stack, conventions, and commands.

<HARD-GATE>
Do NOT create any OpenSpec artifact until:
1. You have a clear problem statement (not just a solution description).
2. You know the constraints and success criteria.
If these are missing, use AskUserQuestion — ONE question at a time — before proceeding.
</HARD-GATE>

---

## Step 1 — Clarify if needed

If `$ARGUMENTS` is empty or vague, use **AskUserQuestion** (open-ended, no preset options):
> "What change do you want to work on? Describe what you want to build or fix."

From the description, derive a kebab-case name (e.g. "add user authentication" → `add-user-auth`).

**Do NOT proceed without understanding what the user wants to build.**

---

## Step 2 — Create the change directory

```bash
openspec new change "<name>"
```

This creates a scaffolded change under the planning home resolved by `.openspec.yaml`.

---

## Step 3 — Get artifact build order

```bash
openspec status --change "<name>" --json
```

Parse the JSON to get:
- `applyRequires` — artifacts needed before implementation
- `artifacts` — full list with status and dependencies
- `planningHome`, `changeRoot`, `artifactPaths`, `actionContext` — use these for all paths; never assume repo-local paths

Use **TodoWrite** to track progress through the artifacts.

---

## Step 4 — Create artifacts in dependency order

Loop through artifacts where dependencies are satisfied (`ready` status):

**For each ready artifact:**

a. Get instructions:
```bash
openspec instructions <artifact-id> --change "<name>" --json
```
The JSON includes:
- `context` — constraints for you; do NOT copy into the file
- `rules` — constraints for you; do NOT copy into the file
- `template` — structure to use for the output file
- `instruction` — schema-specific guidance
- `resolvedOutputPath` — where to write the artifact
- `dependencies` — completed artifact paths to read for context

b. Read all dependency artifacts before writing.

c. **For `specs/` artifacts — enforce EARS notation:**
Every scenario must follow EARS form:
```
WHEN <trigger>, THE SYSTEM SHALL <response>
```
Six forms: Ubiquitous / Event / State / Optional / Unwanted / Complex.
No vague language ("should", "might", "handle errors").

d. **For `design.md` — dispatch `codebase-explorer` agent** for any low-confidence decision.
Quote evidence (file:line) before writing. No guessing.

e. Write the artifact to `resolvedOutputPath`. Show: `Created <artifact-id>`.

f. If context is critically unclear, use **AskUserQuestion** — ONE question at a time — then continue.

g. After each artifact, re-run `openspec status --change "<name>" --json` and check whether
   all `applyRequires` artifact IDs have `status: "done"`. Stop when they do.

---

## Step 5 — Gate before handing off

Run:
```bash
openspec status --change "<name>"
```

Show the full task list. **Do NOT suggest implementation until the user has seen and approved it.**

---

## Output

```
## Proposal Ready

Change: <name>
Location: <changeRoot>

Artifacts created:
- proposal.md — what & why
- specs/<capability>/spec.md — EARS scenarios
- design.md — how
- tasks.md — implementation steps

All artifacts created. Ready for implementation.
Next: /craft-apply <name>
```

---

## Guardrails

- Create ALL artifacts required by `applyRequires` before finishing
- Always read dependency artifacts before creating a new one
- The schema defines what each artifact should contain — follow it; do not invent your own structure
- `context` and `rules` from instructions are YOUR constraints — never copy them into output files
- If a change with that name already exists, use **AskUserQuestion**: continue it or create a new one?
- Verify each artifact file exists after writing before proceeding

## Related skills
- **Before this:** `/craft-explore` (if problem is fuzzy)
- **After this:** `/craft-apply`
- **Task validation:** `planning-tasks`
- **Full pipeline:** `spec-driven-sdlc`
