---
name: task-select
description: Evaluate GitHub PR suitability for Marlin HFI annotation. Returns TAKE/SKIP/CAUTION with reasoning.
user-invocable: true
disable-model-invocation: false
argument-hint: <pr_url> [pr_url2] [pr_url3]
requires:
  - GitHub PR URL(s)
produces:
  - Verdict table (TAKE/SKIP/CAUTION per PR)
calls: []
---

# Task Select - PR Suitability Evaluation

Evaluate whether a GitHub PR is suitable for Marlin HFI annotation. Supports batch evaluation of multiple PRs.

## Input

One or more GitHub PR URLs via $ARGUMENTS or chat message.

## Output Format

For each PR, output:

```
## PR Evaluation: {owner}/{repo}#{pr_number}

**Title**: {PR title}
**Verdict**: TAKE / SKIP / CAUTION
**Difficulty**: {1-5}
**Categories**: {e.g., Refactor, Bug Fix, Feature}

### Why
{2-3 sentences explaining the verdict}

### Risk Flags
- {Any concerns, or "None"}
```

For batch evaluation, add a comparison table at the end:

```
## Comparison

| PR | Verdict | Difficulty | Categories | Key Factor |
|----|---------|-----------|------------|------------|
| owner/repo#123 | TAKE | 4 | Refactor | Good scope, testable |
| owner/repo#456 | SKIP | 1 | Docs | Too trivial |
```

## Steps

### Step 1: Fetch PR Information
For each PR URL:
1. Fetch PR metadata (title, description, labels, file count, line count)
2. Fetch PR diff (use `Accept: application/vnd.github.v3.diff` header)
3. Note the language, changed files, and scope

### Step 2: Evaluate Suitability
Check each criterion:

**TAKE signals (need most of these):**
- Difficulty >= 3 (real code changes, not trivial)
- Has testable behavior (not just docs, CI, typos)
- Scope is reviewable (not 1000+ lines of generated code)
- Multiple files changed with logic changes
- Clear problem statement in PR description
- Code changes involve functions/classes (not just config)

**SKIP signals (any one is enough):**
- Pure documentation or README changes
- Only CI/CD config changes
- Trivial one-line fixes (typo, import order)
- Generated code (migrations, lock files, vendored deps)
- PR is > 500 lines of real code changes (too large to review in time)
- No testable behavior
- Language/framework you can't evaluate (e.g., COBOL)

**CAUTION signals:**
- PR touches many files but changes are mechanical (rename, move)
- PR has failing CI (might be abandoned)
- PR description is empty or vague
- Changes span multiple unrelated concerns

### Step 3: Estimate Difficulty

| Level | Description | Example |
|-------|------------|---------|
| 1 | Trivial | Typo fix, import reorder |
| 2 | Simple | Single function bug fix with obvious test |
| 3 | Moderate | Multi-file refactor, new utility function |
| 4 | Challenging | Architectural change, AST manipulation, complex logic |
| 5 | Expert | Cross-cutting concerns, performance optimization, security fix |

### Step 4: Output Verdict
- TAKE: PR is suitable. Proceed to task-submit.
- SKIP: PR is not suitable. Pick another.
- CAUTION: PR might work but has risks. Explain what to watch for.

## Key Factors Assessment Table

For each PR, fill this mental table before deciding:

| Factor | Assessment | Evidence |
|--------|-----------|----------|
| File Count and Scope | X files, Y functions | from diff stats |
| Complexity | Low/Medium/High | what makes it complex/simple |
| Code Quality Risk | Low/Medium/High | specific risks |
| Evaluation Feasibility | Easy/Moderate/Hard | can CTV compare A vs B? |
| Domain Knowledge | General/Specialized | what expertise needed |
| Turn Potential | 1-2 / 3+ turns | enough depth for multi-turn? |

## CRITICAL: PR Status is IRRELEVANT

PR/issue status (merged, closed, open) does NOT matter.
HFI uses PRs as reference problems. NEVER recommend SKIP because a PR is merged or closed.
Judge ONLY by problem quality and code changes, not PR lifecycle state.

## Rejection Prevention

Picking a bad task is a 5.2% rejection reason ("Low Quality Task"). Avoid:
- Tasks with difficulty 1-2 (too trivial, can't generate 3 meaningful turns)
- Tasks where A and B will produce identical code (no comparison possible)
- Tasks where tests can't be run (no evidence for evaluation)
- Tasks that are pure config/generated code (no human judgment needed)
- Tasks requiring deep domain expertise CTV doesn't have
- PRs with files changed >= 10 (hard to review within time limit, per Marlin Guideline)
