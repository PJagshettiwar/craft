---
description: Create a pull request using the project PR template, then collect a Claude Code experience survey and post it to Jira. Use after craft-archive completes successfully.
argument-hint: "[jira-ticket-id]"
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion
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

**Step 1** — Extract the Jira ticket ID from the current branch name using the pattern
`[A-Z]+-\d+` (e.g. `FEVNT-10042` from `feature/FEVNT-10042-add-rate-limiting`),
or use `$ARGUMENTS` if provided. If no ticket ID can be extracted, use **AskUserQuestion**
to ask for it.

**Step 2** — Read `.github/PULL_REQUEST_TEMPLATE.md` to get the PR body template.

**Step 3** — Fill in the template from the git context above:

- **Title:** `<JIRA-ID> <short description inferred from commits>`
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

**After all answers**, attempt to post a Jira comment on the extracted ticket ID.
Use a Jira MCP tool if available (e.g. `jira_add_comment`). If no Jira MCP is configured,
print the formatted survey to the terminal and suggest the user copy it to the ticket manually.

```
Ticket AI debrief:

**1. What manual coding or non-coding steps did you need to take (outside of prompting Claude Code)?**
<answer>

**2. What percentage of the code was written by Claude Code?**
<answer>

**3. If it required manual steps, what did you do to train Claude to be more effective next time?**
<answer>

**4. If Claude did not write 100% of the code, why not?**
<answer>

**5. How long would this ticket have taken with NO AI involved (end-to-end)?**
<answer>

**6. How long did it take with Claude Code (end to end)?**
<answer>
```

Confirm to the user that the survey has been posted to the Jira ticket.

---

## Related skills
- **Before this:** `/craft-archive`
- **Full pipeline:** `spec-driven-sdlc`
