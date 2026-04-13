---
name: pr-base-commit
description: "Get the commit ID just before a PR was merged (the buggy state). Input: PR URL or number. Output: parent of first PR commit."
argument-hint: "<pr-url|pr-number> [--repo owner/repo]"
metadata:
  author: nhandt
  version: "1.2.0"
---

# PR Base Commit

Get the commit ID of main branch **right before** a PR was merged - the state where the bug still exists.

**Use case:** Checkout to buggy state for AI agent evaluation/fix testing.

## Usage

```
/pr-base-commit <pr-url|pr-number> [--repo owner/repo]
```

## Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `pr-url` | Full GitHub PR URL (e.g., `https://github.com/owner/repo/pull/123`) | Yes (or number) |
| `pr-number` | PR number (e.g., `123`) | Yes (or URL) |
| `--repo` | Repository in `owner/repo` format. Required if using PR number outside a git repo | No |

## Output

Returns the **parent of first PR commit** - the last commit on main before the PR fix was merged.

**Format:**
```
Pre-merge commit: <40-char SHA>
```

## How It Works

```
main:    A---B---C---[PR commits]---M
              ↑
          BUG STATE

PR commits: D---E---F (D's parent = C)

Output: C (commit with bug, before fix merged)
```

1. Parse input (URL or number)
2. Get first commit SHA from PR commits list
3. Get parent of first PR commit via GitHub API
4. Return that commit SHA

**Why not merge commit's parent?** Many repos use rebase/squash merge (1 parent), not true merge commits (2 parents). Getting parent of first PR commit works for all merge strategies.

## Implementation

### Step 1: Parse Input

**If URL provided:**
```bash
# Extract from: https://github.com/owner/repo/pull/123
REPO=$(echo "$URL" | sed -E 's|https://github.com/([^/]+/[^/]+)/pull/[0-9]+|\1|')
PR_NUM=$(echo "$URL" | sed -E 's|.*/pull/([0-9]+).*|\1|')
```

**If number provided:**
```bash
PR_NUM="$1"
REPO="${2:-}" # from --repo flag or auto-detect from git remote
```

### Step 2: Get First PR Commit

```bash
FIRST_COMMIT=$(gh pr view "$PR_NUM" --repo "$REPO" --json commits -q '.commits[0].oid')
```

### Step 3: Get Parent of First PR Commit (Pre-merge State)

```bash
# Use GitHub API - works without local clone
PRE_MERGE_COMMIT=$(gh api repos/$REPO/commits/$FIRST_COMMIT --jq '.parents[0].sha')
```

### Step 4: Output

```bash
echo "Pre-merge commit: $PRE_MERGE_COMMIT"
```

## Error Handling

| Error | Action |
|-------|--------|
| Invalid URL format | Show usage, exit 1 |
| PR not found | Show "PR #N not found in $REPO" |
| PR not merged | Show "PR #N is not merged yet" |
| No repo context | Prompt for `--repo` flag |
| API rate limit | Wait or use authenticated `gh` |

## Examples

```bash
# Using PR URL
/pr-base-commit https://github.com/anthropics/claude-code/pull/100

# Using PR number (inside repo)
/pr-base-commit 100

# Using PR number with explicit repo
/pr-base-commit 100 --repo anthropics/claude-code

# Then checkout to buggy state
git checkout <pre-merge-commit>
```

## Workflow for AI Agent Evaluation

```bash
# 1. Get pre-merge commit (buggy state)
/pr-base-commit https://github.com/owner/repo/pull/123
# Output: Pre-merge commit: abc123...

# 2. Checkout to buggy state
git checkout abc123

# 3. Let AI agent fix the bug
# ... AI agent works ...

# 4. Compare AI fix vs original PR fix
```
