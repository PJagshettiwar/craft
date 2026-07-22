---
description: Review any pull request — spec compliance (when OpenSpec exists), code quality, security, and change coherence. Posts findings as inline GitHub PR comments after approval. Does not touch your current branch.
argument-hint: "<PR number, GitHub PR URL, or branch name>"
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion, Agent
---

# /craft-pr-review — review a pull request

Review any PR (your own or a teammate's) with structured, defense-in-depth analysis.

The command creates an ephemeral worktree of the **correct repo** at the PR's HEAD commit,
then dispatches the `pr-reviewer` agent pointing at that worktree. The agent has the full
project to explore (read files, trace call chains, check callers) and runs `git diff` itself
using the provided SHAs. Your current branch and working directory are never touched.

The `pr-reviewer` agent uses superpowers skills internally (`superpowers:systematic-debugging`,
`superpowers:verification-before-completion`) with hard-gated review stages — the same
review methodology as `/superpowers:requesting-code-review`.

---

## Step 0 — Pre-checks

**Check `gh` authentication:**
```bash
gh auth status
```
If not authenticated, stop and tell the user:
> "`gh` CLI is not authenticated. Run `gh auth login` first."

---

## Step 1 — Parse input and resolve PR

`$ARGUMENTS` can be a PR number, a GitHub URL, or a branch name. Detect the format:

**If it looks like a number** (all digits):
```bash
gh pr view $ARGUMENTS --json number,title,body,url,headRefName,baseRefName,additions,deletions,changedFiles --jq '.'
```

**If it looks like a GitHub URL** (contains `github.com` or a GHE hostname and `/pull/`):
Parse the org, repo, and PR number from the URL pattern `https://<host>/<owner>/<repo>/pull/<number>`.
```bash
gh pr view <number> --repo <owner>/<repo> --json number,title,body,url,headRefName,baseRefName,additions,deletions,changedFiles --jq '.'
```

**If it looks like a URL but NOT a GitHub PR URL** (contains `://` or `http` but doesn't match
a `/pull/` pattern):
Report "Not a valid GitHub PR URL" and stop.

**If it looks like a branch name** (anything else):
```bash
gh pr list --head "$ARGUMENTS" --json number,title,headRefName,baseRefName,url --jq '.'
```
- If exactly 1 PR found -> use it, then fetch full metadata with `gh pr view`.
- If 0 found -> report "No open PR found for branch `$ARGUMENTS`" and stop.
- If 2+ found -> list them and use **AskUserQuestion** to let the user pick.

**If `$ARGUMENTS` is empty:**
Use **AskUserQuestion**:
> "Which PR do you want to review? Provide a PR number, GitHub URL, or branch name."

**Store from the resolved PR:**
- `PR_NUMBER`, `PR_TITLE`, `PR_BODY`, `PR_URL`
- `HEAD_BRANCH`, `BASE_BRANCH` (read from GitHub — never assume main/master)
- `ADDITIONS`, `DELETIONS`, `CHANGED_FILES_COUNT`
- `OWNER`, `REPO` (parsed from URL or current repo)

**Large PR warning:**
If `ADDITIONS + DELETIONS > 1500`, warn the user:
> "This is a large PR (N+ lines changed). The review will focus on the most critical files.
> Continue? (yes / no)"

---

## Step 2 — Verify repo match, fetch branches, resolve SHAs

Verify that the **current working directory** is the repo the PR belongs to. Compare
`OWNER/REPO` from the PR metadata against the current repo's remote:

```bash
git remote get-url origin
```

**If the current repo does NOT match the PR's repo:** Stop and tell the user:
> "This PR belongs to `OWNER/REPO`, but you're in a different repo.
> Please `cd` to the correct repo and re-run:
> ```
> cd /path/to/REPO
> /craft-pr-review $ARGUMENTS
> ```"

Do not attempt to create worktrees in a different repo.

**If the current repo matches:** Proceed.

```bash
# Fetch both branches
git fetch origin $HEAD_BRANCH $BASE_BRANCH 2>/dev/null \
  || git fetch origin $HEAD_BRANCH

# Resolve SHAs
BASE_SHA=$(git rev-parse origin/$BASE_BRANCH)
HEAD_SHA=$(git rev-parse origin/$HEAD_BRANCH)
```

Store `BASE_SHA`, `HEAD_SHA`.

---

## Step 3 — Create ephemeral worktree at PR HEAD

Create a detached worktree from the **correct repo** at the PR's HEAD commit. This gives
the reviewer agent a full copy of the project at exactly the PR's state.

```bash
WORKTREE_DIR=".worktrees"
WORKTREE_PATH="$WORKTREE_DIR/pr-$PR_NUMBER"

# Ensure worktree dir exists and is gitignored
mkdir -p "$WORKTREE_DIR"
grep -qxF '.worktrees/' .gitignore 2>/dev/null \
  || echo '.worktrees/' >> .gitignore

# Remove stale worktree if it exists from a previous run
git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true

# Create worktree at HEAD_SHA (detached — no local branch created)
git worktree add "$WORKTREE_PATH" $HEAD_SHA --detach

# Verify
ls "$WORKTREE_PATH" > /dev/null
```

Store `WORKTREE_PATH`.

---

## Step 4 — Get changed files

```bash
gh pr diff $PR_NUMBER --repo $OWNER/$REPO --name-only
```

Store the list of changed file paths.

---

## Step 5 — Build requirements context

Summarize what the PR is supposed to accomplish. Combine:
- The PR title and body
- Any Jira ticket ID from the branch name (e.g. `FEVNT-1234`)
- If the worktree has `openspec/changes/` with a directory matching the branch/ticket, note the path

Write:
- `WHAT_WAS_IMPLEMENTED` — concise 2-3 sentence summary
- `PLAN_OR_REQUIREMENTS` — bullet list of expected deliverables

---

## Step 6 — Dispatch the pr-reviewer agent

Dispatch the `pr-reviewer` agent. The agent has Read/Grep/Glob/Bash tools and the
worktree path — it can explore the full project freely. It uses superpowers skills
(`superpowers:systematic-debugging`, `superpowers:verification-before-completion`)
internally.

**Do NOT paste the diff.** The agent runs `git diff` itself using the SHAs.

**Do NOT use `isolation: "worktree"`** — the worktree is already created at the correct
repo and commit. Just pass `WORKTREE_PATH` so the agent knows where to read files.

> Review PR #{PR_NUMBER}: "{PR_TITLE}"
>
> ## What Was Implemented
>
> {WHAT_WAS_IMPLEMENTED}
>
> ## Requirements/Plan
>
> {PLAN_OR_REQUIREMENTS}
>
> ## PR Metadata
> - Branch: {HEAD_BRANCH} -> {BASE_BRANCH}
> - URL: {PR_URL}
> - Changed files: {list}
> - PR description: {PR_BODY}
>
> ## Worktree and Git Range
>
> The worktree at `{WORKTREE_PATH}` is a full checkout of the repo at the PR's
> HEAD commit. Read files from this path. All git commands should use
> `git -C "{WORKTREE_PATH}"`.
>
> **Base:** {BASE_SHA}
> **Head:** {HEAD_SHA}
>
> ```bash
> git -C "{WORKTREE_PATH}" diff --stat {BASE_SHA}..{HEAD_SHA}
> git -C "{WORKTREE_PATH}" diff {BASE_SHA}..{HEAD_SHA}
> ```
>
> Use the diff to identify what changed, then read surrounding code in the worktree
> to verify correctness, resource lifecycle, caller/callee contracts, and edge cases.
> You have the full project — explore freely.
>
> Review all four stages. Return structured findings.

Wait for the agent's response.

---

## Step 7 — Show terminal report

Display the agent's response **verbatim**. The pr-reviewer agent returns render-ready
Markdown with tables, structured sections, and formatted findings.

**Do not reformat, restructure, or re-summarize the agent's output.** Pass it through exactly
as returned. The agent's output format is the terminal report.

---

## Step 8 — Ask about posting to GitHub

Use **AskUserQuestion**:
> "Post these findings as PR review comments?"
>
> 1. Yes -- post all findings
> 2. No -- done, terminal report only
> 3. Select -- choose which findings to post

**If "Select":** Show a numbered list of all findings. Let the user enter the numbers
to post (e.g., "1, 3, 5"). Confirm the selection before posting.

**If "Yes" or after selection:**

Map the verdict to a GitHub review event:
- APPROVE / APPROVE WITH NITS -> `APPROVE`
- REQUEST CHANGES -> `REQUEST_CHANGES`
- BLOCK -> `REQUEST_CHANGES` (GitHub has no BLOCK event; note in summary)

Build the review payload as a **JSON file** (the `gh api` CLI cannot reliably pass
inline JSON arrays via `-f`):

```bash
cat > /tmp/pr-review-payload.json << 'ENDJSON'
{
  "body": "<summary text>",
  "event": "<APPROVE | REQUEST_CHANGES>",
  "comments": [
    {"path": "<file>", "line": <line>, "body": "<finding body>"},
    ...
  ]
}
ENDJSON

gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews \
  --method POST \
  --input /tmp/pr-review-payload.json
```

**Line numbers must reference the NEW file's line numbers** (the `line` field in the
GitHub review API refers to the line in the file at HEAD, not the diff position).
For new files, use the file line number directly. For modified files, use the
right-side (new) line number from the diff hunk headers.

Each finding becomes a separate inline comment, creating individual threads for
GitHub's native resolution tracking.

**Report result:**
> "Posted N findings as PR review comments. [PR URL]"

**If "No":** Skip posting.

---

## Step 9 — Clean up worktree

Always run cleanup, even if earlier steps failed:

```bash
git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
```

If cleanup fails, warn but don't block:
> "Warning: Could not remove worktree at `<path>`. Clean up manually with
> `git worktree remove <path> --force`."

---

## Guardrails

- **Never touch the current branch** — the worktree is detached at the PR's HEAD commit
- **Never assume base branch** — always read it from GitHub PR metadata
- **Never post comments without asking** — terminal report first, then explicit approval
- **Never paste the diff into the agent prompt** — pass SHAs and let the agent explore
- **Always clean up** — worktree removal runs unconditionally in Step 9
- **Correct repo** — match the PR's OWNER/REPO against local repos; don't assume current dir
- **One question at a time** — use AskUserQuestion for all clarifications

## Related skills
- **Review agent:** `pr-reviewer` (uses `superpowers:systematic-debugging` and `superpowers:verification-before-completion` internally)
- **Standalone** — not part of the main craft pipeline
- **Complementary to:** `/craft-review` (reviews your own OpenSpec changes)
