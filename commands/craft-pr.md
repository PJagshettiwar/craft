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

**Step 2** — Find and read the template. Check these paths in order:

```bash
ls .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md \
   docs/PULL_REQUEST_TEMPLATE.md PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

<HARD-GATE>
If a template exists, the PR body **is** that file with its sections filled in. You may not
substitute a body of your own design. Specifically forbidden: inventing `## Summary`,
`## Test plan`, `## Changes`, or any heading the template does not contain.

Compliance bots (Autodesk GitOps, and similar) parse the body for the template's exact
headings. A well-written body with the wrong headings fails the check just as hard as an empty
one, and the failure names the *template* rather than the missing heading — so it reads as a
tooling bug and costs real time to diagnose.
</HARD-GATE>

If no template exists, use: Summary, What Changed, and Reviewer Notes.

**Step 3** — Fill it in, obeying these rules:

**Copy every `##` and `###` heading from the template, in the template's order.** Delete none,
add none, reorder none. Then fill the bodies from the git context above:

- **Title:** `<ticket-ID> <short description inferred from commits>` (omit ticket prefix if none found)
- **Risk / Impact / Security sections:** assess based on what changed:
  - New features = medium risk
  - Config/infra changes = higher risk
  - Tests/docs only = low risk
  - Say explicitly whether the change touches a published artifact, a schema, or a service's
    runtime path — that is what the reader actually needs.
- **Overview:** summarise changes from commit messages and files changed
- **Features / Bug Fixes:** list from commit messages. If a section does not apply, write
  "None — <reason>" rather than deleting the heading or leaving it blank.
- **Reviewer Notes:** call out anything complex or non-obvious. Include the verification you
  actually ran, with real command output — not a claim that tests pass.
- **Release Agreement / legal boilerplate:** reproduce byte-for-byte, comments included.

Two rules that cause silent failures if broken:

1. **Any section the template marks as mandatory must be non-empty.** Look for `MUST`,
   `REQUIRED`, `DO NOT DELETE`, or bold/asterisk emphasis in the template's own prose. These
   are usually the exact sections a bot checks for.
2. **Checkbox lines are copied verbatim** — the full label text, not a shortened paraphrase.
   Change only `[ ]` → `[x]`, and append your explanation after a trailing `:` where the
   template invites one (`- [ ] Other, explain here:`). Tick at least one if the template says
   "at least one".

**Step 4** — Push if needed:
```bash
git push -u origin HEAD
```

**Step 5** — Write the body to a file, then create the PR from it:

```bash
cat > /tmp/pr-body-$$.md <<'ENDBODY'
<filled template>
ENDBODY
gh pr create --title "<title>" --body-file /tmp/pr-body-$$.md
```

`--body-file` with a quoted heredoc, never inline `--body`: PR bodies contain backticks, `$`,
and newlines, and inline passing lets the shell mangle or execute them.

**Step 6** — Verify before reporting. Two checks, both cheap:

```bash
# a) Every template heading survived into the body
diff <(grep -E '^#{2,3} ' .github/PULL_REQUEST_TEMPLATE.md) \
     <(gh pr view <N> --json body --jq .body | grep -E '^#{2,3} ')

# b) Compliance checks went green
gh pr checks <N> | awk -F'\t' '$2!="pass"'
```

If (a) shows a missing heading, or (b) shows a failing template/risk/compliance check, fix the
body and re-apply with `gh pr edit <N> --body-file <file>`, then re-run both. Checks may need a
few seconds to re-run after an edit — wait for them rather than reporting the stale state. Do
not hand the user a PR with a red compliance check and let them discover it.

**Step 7** — Report the PR URL to the user.

> **Enterprise GitHub:** `gh` subcommands taking `--repo <owner>/<repo>` resolve against
> github.com by default and fail with "Could not resolve to a Repository" on an enterprise
> host. Either run them from inside the repo without `--repo`, or prefix with the host:
> `GH_HOST=git.autodesk.com gh pr view <N> --repo <owner>/<repo>`.

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
