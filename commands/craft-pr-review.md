---
description: Review any pull request in an isolated worktree — spec compliance (when OpenSpec exists), code quality, security, and change coherence. Posts findings as inline GitHub PR comments after approval. Does not touch your current branch.
argument-hint: "<PR number, GitHub PR URL, or branch name>"
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion, Agent
---

# /craft-pr-review — review a pull request

Review any PR (your own or a teammate's) with structured, defense-in-depth analysis. Runs in
an ephemeral worktree — your current branch and working directory are never touched.

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

**If it looks like a GitHub URL** (contains `github.com` and `/pull/`):
Parse the org, repo, and PR number from the URL pattern `https://github.com/<owner>/<repo>/pull/<number>`.
```bash
gh pr view <number> --repo <owner>/<repo> --json number,title,body,url,headRefName,baseRefName,additions,deletions,changedFiles --jq '.'
```

**If it looks like a URL but NOT a GitHub PR URL** (contains `://` or `http` but doesn't match
`github.com/.../pull/`):
Report "Not a valid GitHub PR URL" and stop.

**If it looks like a branch name** (anything else):
```bash
gh pr list --head "$ARGUMENTS" --json number,title,headRefName,baseRefName,url --jq '.'
```
- If exactly 1 PR found → use it, then fetch full metadata with `gh pr view`.
- If 0 found → report "No open PR found for branch `$ARGUMENTS`" and stop.
- If 2+ found → list them and use **AskUserQuestion** to let the user pick.

**If `$ARGUMENTS` is empty:**
Use **AskUserQuestion**:
> "Which PR do you want to review? Provide a PR number, GitHub URL, or branch name."

**Store from the resolved PR:**
- `PR_NUMBER`, `PR_TITLE`, `PR_BODY`, `PR_URL`
- `HEAD_BRANCH`, `BASE_BRANCH` (read from GitHub — never assume main/master)
- `ADDITIONS`, `DELETIONS`, `CHANGED_FILES_COUNT`

**Large PR warning:**
If `ADDITIONS + DELETIONS > 1000`, warn the user:
> "This is a large PR (N+ lines changed). The review will focus on the most critical files.
> Continue? (yes / no)"

---

## Step 2 — Get changed files

```bash
gh pr diff $PR_NUMBER --name-only
```

Store the list of changed file paths.

---

## Step 3 — Create ephemeral worktree

Follow the `superpowers:using-git-worktrees` skill:

1. **Check for existing worktree directory** (`.worktrees/` or `worktrees/`).
2. **Verify it's gitignored** — if not, add to `.gitignore`.
3. **Fetch the PR's head branch** (it may not exist locally):
   ```bash
   git fetch origin $HEAD_BRANCH
   ```
4. **Create the worktree** checking out the existing PR branch (NOT a new branch):
   ```bash
   git worktree add <worktree-path>/pr-$PR_NUMBER origin/$HEAD_BRANCH --detach
   ```
   Use `--detach` to avoid creating a local branch tracking the remote.
5. **Verify the checkout** — confirm the worktree exists and has the expected HEAD.

**Store** `WORKTREE_PATH` for later cleanup.

---

## Step 4 — Detect OpenSpec and convention files

**In the worktree**, check for project convention files:
```bash
ls "$WORKTREE_PATH/CLAUDE.md" 2>/dev/null
ls "$WORKTREE_PATH/AGENTS.md" 2>/dev/null
```
Store paths to any that exist.

**Check for OpenSpec artifacts:**
```bash
ls "$WORKTREE_PATH/openspec/changes/" 2>/dev/null
```
If an OpenSpec change directory exists whose name or content relates to the PR's branch,
store `OPENSPEC_CHANGE_PATH`. If multiple changes exist, check which one has files touched
by the PR's diff. If none match, set `OPENSPEC_CHANGE_PATH` to empty.

---

## Step 5 — Get the diff

```bash
git -C "$WORKTREE_PATH" diff "origin/$BASE_BRANCH"..."origin/$HEAD_BRANCH"
```

Store as `PR_DIFF`.

---

## Step 6 — Dispatch the pr-reviewer agent

Dispatch the `pr-reviewer` agent with all collected context:

> Review PR #`PR_NUMBER`: "`PR_TITLE`"
> Branch: `HEAD_BRANCH` → `BASE_BRANCH`
> PR description: `PR_BODY`
> URL: `PR_URL`
>
> Changed files: `<list>`
>
> Convention files (read these for project rules):
> - `<paths to CLAUDE.md, AGENTS.md if they exist>`
>
> OpenSpec change path: `<OPENSPEC_CHANGE_PATH or "none">`
>
> Diff:
> ```
> <PR_DIFF>
> ```
>
> Review all four stages. Return structured findings.

Wait for the agent's response.

---

## Step 7 — Show terminal report

Format the agent's findings as a terminal report:

```
╔══════════════════════════════════════════════════╗
║  PR Review: #<number> — <title>                  ║
║  Branch: <head> → <base>                         ║
║  Verdict: <VERDICT>                              ║
╚══════════════════════════════════════════════════╝

── Spec Compliance ──────────────────────────────────
<findings or "No OpenSpec artifacts found. Skipped.">

── Code Quality (<N> findings) ──────────────────────
[<severity>] <file>:<line>
  <body>

── Security (<N> findings) ──────────────────────────
[<severity>] <file>:<line>
  <body>

── Change Assessment (<N> findings) ─────────────────
[<severity>] <file>:<line>
  <body>

── Summary ──────────────────────────────────────────
<agent's summary>

Critical: <N>  Important: <N>  Nit: <N>
```

---

## Step 8 — Ask about posting to GitHub

Use **AskUserQuestion**:
> "Post these findings as PR review comments?"
>
> 1. Yes — post all findings
> 2. No — done, terminal report only
> 3. Select — choose which findings to post

**If "Select":** Show a numbered list of all findings. Let the user enter the numbers
to post (e.g., "1, 3, 5"). Confirm the selection before posting.

**If "Yes" or after selection:**

Map the verdict to a GitHub review event:
- APPROVE / APPROVE WITH NITS → `APPROVE`
- REQUEST CHANGES → `REQUEST_CHANGES`
- BLOCK → `REQUEST_CHANGES` (GitHub has no BLOCK event; note in summary)

Build the review payload:
```bash
gh api repos/{owner}/{repo}/pulls/$PR_NUMBER/reviews \
  --method POST \
  -f body="<summary text>" \
  -f event="<event>" \
  -f 'comments=[{"path":"<file>","line":<line>,"body":"<finding body>"},...]'
```

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

- **Never touch the current branch** — all work happens in the ephemeral worktree
- **Never assume base branch** — always read it from GitHub PR metadata
- **Never post comments without asking** — terminal report first, then explicit approval
- **Always clean up** — worktree removal runs unconditionally
- **Focus on the diff** — review changed code, not the entire repository
- **One question at a time** — use AskUserQuestion for all clarifications

## Related skills
- **Worktree management:** `superpowers:using-git-worktrees`
- **Review agent:** dispatch `pr-reviewer` agent
- **Standalone** — not part of the main craft pipeline
- **Complementary to:** `/craft-review` (reviews your own OpenSpec changes)
