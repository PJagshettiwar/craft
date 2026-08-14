---
description: Create a pull request using the project PR template, then collect a Claude Code experience survey. Use after craft-archive completes successfully.
argument-hint: "[ticket-id]"
allowed-tools: Read, Grep, Glob, Bash, Write, AskUserQuestion
---

# /craft-pr — create PR + experience survey

## Context (auto-loaded)
- Current branch: !`git rev-parse --abbrev-ref HEAD`
- Recent commits: !`git log --oneline -10`
- Files changed vs main: !`git diff main --name-only 2>/dev/null || git diff origin/main --name-only 2>/dev/null`
- Commit summary: !`git log main..HEAD --oneline 2>/dev/null || git log origin/main..HEAD --oneline 2>/dev/null`

---

<HARD-GATE>
Do NOT create a PR until:
1. /craft-archive has completed — the change is archived, all tasks checked off.
2. The branch is clean — run `git status` and show output before proceeding.
If either is false, send the user back to /craft-archive.
</HARD-GATE>

---

## Part 1 — Create the Pull Request

**Step 1** — Extract a ticket ID from the current branch name, or use `$ARGUMENTS` if provided.

Look for a ticket pattern in this order:
1. `## PR Config` in CLAUDE.md → `ticket-pattern:` regex (e.g. `ticket-pattern: FEVNT-\d+`)
2. Common patterns: `[A-Z]+-\d+` (Jira-style), `#\d+` (GitHub Issues), `\d+` (plain number)
3. If no match found, skip ticket linking — do not fail.

**Step 2** — Read `.github/PULL_REQUEST_TEMPLATE.md` if it exists. If absent, use a minimal
template: Summary, What Changed, and Reviewer Notes sections.

**Step 3** — Fill in the template from the git context above:

- **Title:** `<ticket-ID> <short description inferred from commits>` (omit ticket prefix if none found)
- **Risk and Impact Analysis:** assess based on what changed:
  - New features = medium risk
  - Config/infra changes = higher risk
  - Tests/docs only = low risk
- **Overview:** summarise changes from commit messages and files changed
- **What's Changed checkboxes:** check all that apply
- **Features / Bug Fixes:** list from commit messages
- **Reviewer Notes:** call out anything complex or non-obvious
- Keep the **Release Agreement** section intact and unmodified

**Step 4** — Push if needed:
```bash
git push -u origin HEAD
```

**Step 5** — Create the PR:
```bash
gh pr create --title "<title>" --body "<filled template>"
```

**Step 6** — Report the PR URL to the user.

---

## Part 2 — Claude Code Experience Survey

After the PR is created, tell the user:
> "PR created! Now let me collect a quick Claude Code experience survey. I'll ask you 6 questions in 3 groups."

Use **AskUserQuestion** to ask questions in groups (minimise interruptions):

**Group A — ask together:**
1. "What manual coding or non-coding steps did you need to take (outside of prompting Claude Code)?"
   Options: None / Minor (a few small tweaks) / Moderate (significant manual rework) / Let me describe it
2. "What percentage of the code was written by Claude Code?"
   Options: 100% / ~90% / ~75% / Less than 75%

**Group B — ask together:**
3. "If it required manual steps, what did you do to train Claude to be more effective next time? (e.g. added a skill, updated CLAUDE.md, added memory)"
   Options: Nothing needed / Added/updated a skill or memory / Updated CLAUDE.md or project docs / Let me describe it
4. "If Claude did not write 100% of the code, why not?"
   Options: N/A — Claude wrote it all / Needed domain expertise CC lacked / CC made errors I had to fix / Let me describe it

**Group C — ask together:**
5. "How long would this ticket have taken with NO AI involved (end-to-end)?"
   Options: Less than 1 day / 1–2 days / 3–5 days / 1–2 weeks / More than 2 weeks
6. "How long did it actually take with Claude Code (end to end)?"
   Options: Under 1 hour / 1–4 hours / ~half a day / 1–2 days / More than 2 days

**After all answers**, post the survey results:

1. **If** `mcp__mcp-atlassian__jira_add_comment` is available AND a Jira-style ticket ID was
   extracted: post as a Jira comment on the ticket.
2. **Otherwise:** write the survey to `survey-<branch-name>.md` in the project root and tell
   the user where it is.

In either case, display the formatted survey in the conversation:

```
Ticket AI debrief:

**1. What manual coding or non-coding steps did you need to take (outside of prompting Claude Code)?**
<answer>

**2. If it required manual steps, what did you do to train Claude to be more effective next time?**
<answer>

**3. What percentage of the code was written by CC?**
<answer>

**4. If Claude did not write 100% of the code, why not?**
<answer>

**5. How long would this ticket have taken with NO AI involved (end-to-end)?**
<answer>

**6. How long did it take with Claude Code (end to end)?**
<answer>
```

**Log the survey locally** — append a JSON line to `.craft/survey-log.jsonl` (create if absent):

```json
{"date":"<ISO-8601>","branch":"<branch>","ticket":"<id>","manual_steps":"<answer1>","ai_pct":"<answer2>","training":"<answer3>","why_not_100":"<answer4>","time_without_ai":"<answer5>","time_with_ai":"<answer6>"}
```

This log accumulates across changes and enables aggregation without querying Jira.

Confirm to the user that the survey has been posted (or saved) and logged locally.

---

## Related skills
- **Before this:** `/craft-archive`
- **Full pipeline:** `craft-sdlc`
