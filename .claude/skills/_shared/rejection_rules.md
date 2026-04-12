# Rejection Prevention Rules

Source: 288-row Marlin Dashboard Feedback dataset. These are the top reasons tasks get rejected, ordered by frequency.

## Top 10 Rejection Reasons

| # | Category | % | Root Cause | Prevention |
|---|----------|---|------------|------------|
| 1 | Redundant Prompts | 21.9% | Repeating Turn 1 in Turn 2, drip-feeding requirements | Each prompt must introduce NEW aspects. Check novelty vs prior prompts |
| 2 | Inaccurate Evaluation | 14.2% | Wrong code refs, fabricated claims | Read BOTH worktrees. Every claim must reference actual file:function |
| 3 | AI/LLM Detected | 10.1% | Blocked words, AI patterns, sycophantic tone | Run blocked words check. Use dev-to-dev casual tone |
| 4 | Incomplete Work | 9.7% | Missing cons, insufficient turns, skipped dimensions | Min 3 turns. Both models have cons. Cover 3+ dimensions |
| 5 | Rating Inconsistency | 9.4% | Axis ratings != winner direction | Count axis direction. Majority must match winner |
| 6 | Scope Creep | 7.6% | Prompt evolved beyond original issue | Keep prompts within original issue scope |
| 7 | Fabricated Evaluation | 6.9% | Symmetric/copied A vs B, identical pros/cons | Pros/cons must be different for A and B (SequenceMatcher < 0.8) |
| 8 | Low Quality Task | 5.2% | Trivial PR, difficulty 1-2 | Pick PRs with difficulty >= 3, real code changes |
| 9 | Process Violation | 4.2% | Diff files missing, PR refs, format violations | Never mention PR/pull request. Check all required files exist |
| 10 | Technical Error | 2.4% | Platform/API issues | N/A |

## Priority Rules (P0-P5)

### P0: Read Actual Code (43.2% of rejects)
- MUST open files in BOTH worktrees A and B
- Each pro/con MUST reference specific file name + function/class
- If identical between A and B: all code ratings = neutral
- NEVER fabricate differences
- NEVER confuse A vs B

### P1: Rating Consistency (13.7%)
- Scale A1-B1 (V3): A1-A3 favor A, B3-B1 favor B, A4/B4 = equivalent
- Winner MUST match majority of axis written comparisons
- Justification language MUST match rating level (A1 = "fails, broken", A3 = "better structured")
- Key-axis field REQUIRED for A1/A2/B1/B2

### P2: Worktree Sync (13.1%)
- After Turn 1: BOTH models get winner's code
- Turn 2+ prompts address winner's issues only
- NEVER reference original PR
- Scope stays within original issue

### P3: Anti-AI Detection (10.9%)
- No blocked words (see blocked_words.md)
- No em dashes
- No markdown in evaluation
- Dev-to-dev casual tone
- Varied sentence structure

### P4: Completeness (8.2%)
- Minimum 3 turns with real code changes
- Each turn introduces NEW aspect
- Tests MANDATORY
- Justification 3-5 sentences with code refs
- Both models MUST have cons

### P5: Quality (5.5%)
- No generic evaluations
- Name specific file, function, code pattern
- Explain reasoning, not just conclusion

## V3 Rejection Reasons (NEW)

### Over-Prescriptive Prompts
- Prompts must NOT micromanage every implementation step
- Target: task requiring 6-8 hours of engineer effort
- Describe PROBLEM + success criteria, let model figure out HOW
- BAD: "In api/search.py, on line 47, change decode('ascii') to decode('utf-8')"
- GOOD: "Requests to /api/search return 500 with non-ASCII queries. Fix encoding path and add regression tests."

### Role-Based Prompting
- Do NOT use "You are a senior software engineer...", "Act as an expert developer..."
- Write direct, clear instructions

### PR Reference in Prompt
- Do NOT reference PR number, branch, or PR content in prompt
- Write as if you are the original developer planning the work from scratch

### Category Mismatch
- Every V3 submission must have at least 1 prompt matching the selected category
- Turn 1 MUST use one of the 10 Turn 1 categories. Turn 2+ may use any category including the 4 removed ones
- Turn 1 in one category, Turn 2+ in a different category = valid multi-category pattern, NOT drip-feeding

**10 Turn 1 categories:**

| Category | Description |
|----------|-------------|
| Git | Tasks involving git actions. Complex enough that both models take meaningfully different approaches. Avoid race-condition prompts. |
| Ambiguous | Tasks where ideal response is to ask for clarification rather than immediately produce code. |
| Discussion | Answer questions without producing code. Challenging questions with significant model response variance. Ideally requires repo knowledge. |
| Explaining | Explain how specific code works, walk through codebase, or narrate changes and reasoning. Distinct from Discussion (reasoning/tradeoffs vs how code works). |
| Code Review | Ask for code review at meaningful scope (feature suite level). Trivial code with no issues is not useful. |
| Greenfield | Task starts from empty repository. Build from scratch. No PR required if using own creativity. |
| Chore | Maintenance that does not change external behavior - dependency updates, config, build system. Must be complex enough for meaningful model difference. |
| Documentation | Write, update, or improve documentation - comments, docstrings, README, API docs. Challenging enough that model quality varies. |
| Performance | Improve performance - reducing latency, memory usage, or computational cost. Must have clear success condition. |
| Other | Use only when task genuinely does not fit any above. |

**4 Turn 2+ only categories:**

| Category | Description |
|----------|-------------|
| Refactor | Cleanup, dead code removal, consolidating duplicated logic, improving naming/readability without changing behavior. |
| Bug Fix | Identify and fix a specific, concrete, reproducible bug. Avoid prompts too vague to evaluate. |
| New Feature | Add entirely new functionality to existing repo. Distinct from Greenfield (empty repo). |
| Testing and QA | Write, improve, or extend tests for existing code. Distinct from Code Review - involves implementing changes, not recommending. |

### Descriptive (not Evaluative) Strengths
- Strengths field must explain WHY something matters, not just describe
- BAD: "Model A added tests"
- GOOD: "Model A added regression coverage in test_search.py::test_non_ascii_query - without this, refactor could reintroduce the bug"

### Justification-Rating Language Mismatch
- Written language must match rating level
- A1/B1 requires "fails, incorrect, broken" - cannot use soft language
- A3/B3 requires "better structured, tighter scope" - cannot use "clearly superior"

### V3 Phased Implementation
- V3 ALLOWS adding edge cases, tests, secondary features in later turns
- BUT each turn must advance implementation concretely
- CANNOT repeat content already covered in prior turns
- Pure repetition is still rejected, phased advancement is OK
- Turn 1 in one category, Turn 2+ in a different category = valid pattern, NOT drip-feeding

### N/A Rating = Rejection
- Every axis (6.1-6.11) MUST have a rating. CANNOT use N/A
- N/A triggers immediate rejection

### Git Workflow with claude-hfi
- claude-hfi manages git state AUTOMATICALLY. Do NOT run git commit between turns
- Manual commits between turns will corrupt trajectory tracking and produce wrong diffs
- Only git commit ONCE at the START to initialize repo (`git init && git add . && git commit -m "Initial commit"`)
- claude-hfi creates 2 separate trajectories (A and B), each with its own workspace
- Between turns: Ctrl+C to exit CLI -> `./claude-hfi --vscode --continue` to resume
- Diffs are computed automatically from trajectory state, not manual git diff

### CLAUDE.md Required (V3)
- All tasks with a repo MUST have CLAUDE.md before running CLI
- If repo already has one: use as-is, may add targeted additions
- If repo doesn't have one: MUST create beforehand (manually or using separate Claude Code, NOT claude-hfi)
- Launch HFI BEFORE creating CLAUDE.md, then copy into HFI cache

### Dev Environment Setup (V3)
- MUST install deps, setup venv, verify tests pass BEFORE Turn 1
- Do NOT penalize model for failed env setup if env was not configured
- That is a setup issue, not a model deficiency
- When reviewing (checkpoint-review), check:
  - Did model fail because of env issue or code issue?
  - If env issue: note in evaluation but do NOT deduct points
  - If code issue: evaluate normally
