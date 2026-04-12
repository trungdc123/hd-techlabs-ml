---
name: task-submit
description: Generate Step 1 specification from PR diff. Produces repo definition, PR definition, edge cases, acceptance criteria, and initial prompt.
user-invocable: true
disable-model-invocation: false
argument-hint: <workspace_path>
requires:
  - workspace/ with pr.diff and meta.json
produces:
  - workspace/step1_spec.md
calls:
  - rewrite-human (internal, on all text fields)
  - validate-output (internal, on final output)
---

# Task Submit - Step 1 Specification Generator

Generate all 6 fields for Step 1 submission from a PR diff.

## Input

Workspace path via $ARGUMENTS or chat. The workspace must contain:
- `meta.json` (task metadata)
- `pr.diff` (PR diff from GitHub)

## Output

Write `step1_spec.md` to the workspace with these 6 sections:

```markdown
# Prompt Category

{category1}, {category2}.

# Repo Definition

{2 paragraphs, 700-900 chars. Describe what the repo does and which areas are relevant to this task. Repo ONLY - not the PR changes.}

# PR Definition

{2 paragraphs, 700-900 chars. Problem statement: what the PR changes, the before/after behavior. Focus on WHAT changes and WHY.}

# Edge Cases

{300-400 chars. Specific edge cases visible in the diff. Reference file:function where applicable. These are things a reviewer should watch for.}

# Acceptance Criteria

{200-400 chars. YES/NO testable gates. A reviewer would know the implementation is correct if X. It would be incomplete if Y. It would be incorrect if Z.}

# Initial Prompt

{1000-1500 chars. Flowing prose, no headers/bullets. Self-contained instructions for a coding agent to implement the changes. Must specify WHERE (which files/functions) and HOW (what approach). A model reading only this prompt should be able to implement without seeing the PR.}
```

## Steps

### Phase 1: Analyze the Diff
1. Read `meta.json` for PR URL, owner, repo
2. Read `pr.diff` completely
3. Identify:
   - Changed files and their purposes
   - Changed functions/classes
   - The pattern of changes (refactor, bug fix, new feature, etc.)
   - Test files and what they cover
   - Dependencies between changes

### Phase 2: Draft Each Field

**Prompt Category** (V3 - 10 Turn 1 categories + 4 Turn 2+ only):

**Turn 1 categories (MUST select from these for Turn 1):**

| Category | Description |
|----------|-------------|
| Git | Tasks involving git actions. Can span all turns or just one, but should be complex enough that both models take meaningfully different approaches. Avoid prompts that could cause race conditions (e.g., creating a branch by name). If possible, set up a private remote repository and interact with remote as part of prompting. |
| Ambiguous | Tasks where the ideal model response is to ask for clarification rather than immediately produce code. Ask yourself: would a senior engineer stop and get clarification first? If yes, the prompt fits this category. Generally works best as the first turn. |
| Discussion | One or more prompts use Claude Code to answer questions without producing code. Should be challenging questions where model response quality has significant variance. Ideally requires knowledge of the repo to answer well. Can be standalone or Turn 1 of a code-change conversation. |
| Explaining | One or more prompts ask the model to explain how specific code works, walk through a codebase, or make changes and clearly narrate what was done and why. Preferences reflect both the correctness of the explanation and how clear, useful, and understandable it was. Distinct from Discussion - Discussion is about reasoning through problems or tradeoffs; Explaining is about asking how existing code or a change works. |
| Code Review | One or more prompts ask for a code review. Use your judgement on scope - reviewing a feature suite is typically the right level. A review of trivial code with no issues is not a useful prompt. |
| Greenfield | Task starts from an empty repository. Use your own creativity or draw inspiration from an existing PR to prompt Claude Code to build something from scratch. You do not need to select a PR if using your own creativity. |
| Chore | Maintenance work that does not change external behavior - dependency updates, configuration changes, build system fixes, or similar housekeeping. Should still be complex enough that there is a meaningful difference in how the two models approach it. |
| Documentation | One or more prompts ask the model to write, update, or improve documentation - inline comments, docstrings, README files, API docs, or similar. Should be challenging enough that model quality varies. |
| Performance | One or more prompts ask the model to improve performance of existing code - reducing latency, memory usage, or computational cost. Should have a clear success condition. |
| Other | Use only when task genuinely does not fit any above |

**Turn 2+ only categories (NOT allowed for Turn 1):**

| Category | Description |
|----------|-------------|
| Refactor | One or more prompts relate to refactoring a portion of the codebase. Good fits: cleanup and dead code removal, performance-motivated restructuring, consolidating duplicated logic, improving naming and readability without changing behavior. |
| Bug Fix | One or more prompts ask the model to identify and fix a specific bug or class of bugs. The bug should be concrete and reproducible - avoid prompts too vague to evaluate whether the fix is correct. |
| New Feature | One or more prompts ask the model to add entirely new functionality to an existing repository. Distinct from Greenfield (empty repo) and Feature Extension (expanding existing functionality). |
| Testing and QA | One or more prompts ask the model to write, improve, or extend tests for existing code. Distinct from Code Review - this involves actually implementing test changes, not recommending them. |

Turn 1 MUST use one of the 10 Turn 1 categories. Turn 2+ MAY use any category, including the 4 Turn 2+ only ones. Turn 1 in one category, Turn 2+ in a different category = valid multi-category pattern, NOT drip-feeding.

**Repo Definition**: 
- Paragraph 1: What the repo/project does overall
- Paragraph 2: Which specific areas (files, modules) are relevant to this task
- Do NOT describe the PR changes here - only the repo context
- 700-900 chars

**PR Definition**:
- Paragraph 1: The problem (what was wrong or missing before)
- Paragraph 2: The solution approach (what the PR does to fix it, at a high level)
- 700-900 chars

**Edge Cases**:
- List specific technical edge cases from the diff
- Reference file:function where applicable
- Focus on things that could go wrong or be missed
- 300-400 chars

**Acceptance Criteria**:
- Write as YES/NO testable gates
- "A reviewer would know it's correct if..."
- "It would be incomplete if..."
- "It would be incorrect if..."
- 200-400 chars

**Initial Prompt** (V3 - NOT over-prescriptive):
- Flowing prose, NO headers, NO bullet points, NO role-based prompting
- Do NOT use "You are a senior engineer..." - write direct instructions
- Target: task requiring 6-8 hours of engineer effort
- Describe PROBLEM + success criteria, let model figure out HOW
- Do NOT micromanage every file, line, function - describe desired behaviour
- V3 allows phased: Turn 1 only needs core logic, later turns add edge cases/tests
- 1000-1500 chars
- XẤU: "In api/search.py, on line 47, change decode('ascii') to decode('utf-8')"
- TỐT: "Requests to /api/search return 500 with non-ASCII queries. Fix the encoding path so unicode works and add regression tests."

### CRITICAL: No-Solution-Leakage Rules

CTV evaluators read your output BEFORE seeing any code. If you describe implementation details, you BIAS them.

- Describe the PROBLEM, not the SOLUTION
- SAY: "the bot sends detached messages" NOT "the fix adds reply_to_message_id"
- Mention affected files/modules for SCOPE, but don't describe what the fix does
- Requirements = GOALS ("outbound messages must be threaded"), NOT implementation steps ("pass reply_to_message_id to sendMessage")
- Edge cases = SCENARIOS, not implementation pitfalls
- Variable names, API params, field names from the fix do NOT belong in PR Definition

### CRITICAL: Content Laundering Rule

You see raw PR metadata: commit hashes, SHA values, version numbers, author names, bot names. DO NOT COPY THESE INTO YOUR OUTPUT. Ever. Not in any field.

- Instead of "bumps from 65f9e5c to e4a76dd" -> "the action reference needs updating to pick up recent fixes"
- Instead of "Dependabot automated update" -> "a third-party dependency needs updating"
- Instead of "authored by @username" -> don't mention authors at all
- NEVER mention PR number, commit SHA, branch name, or author name

### Phase 3: Self-Review Gates

**GATE 1 - Self-Containment Check:**
Read the Initial Prompt in isolation. Could a coding agent implement this without seeing the PR diff? If not, add the missing context. Watch for:
- "see above" or implicit references to other sections
- Missing file paths or function names
- Vague instructions like "fix the issue" without specifying what issue

**GATE 2 - V3 Phased Implementation Check:**
V3 allows Turn 1 to only cover core logic. Later turns may add edge cases, tests, secondary features - as long as each turn advances concretely. BUT:
- Turn 1 must be sufficiently challenging (6-8h engineer effort)
- Must not be over-prescriptive (describe problem, not step-by-step)
- Prompt scope must be coherent - like 1 hypothetical PR
- Must not request features entirely unrelated to repo/PR scope
- Turn 1 category MUST be from the 10 Turn 1 categories (not Refactor, Bug Fix, New Feature, Testing and QA)

**GATE 3 - Anti-AI Rewrite:**
Read the entire output through the rewrite-human lens:
- No blocked words (see skills/_shared/blocked_words.md)
- No em dashes
- No template-like language
- Direct, specific, technical tone

**GATE 4 - Auto Quality Gate (REQUIRED):**
Run auto_quality.md pipeline BEFORE writing file:
1. Auto-Validate: Scan blocked words, em dashes -> auto-replace
2. Auto-Rewrite: 8-pass humanization -> auto-rewrite AI sentences
3. Final Check: Verify technical accuracy unchanged after rewrite

Output only written AFTER passing. CTV does not need to call /validate-output separately.

### Phase 4: Write Output
Write the final `step1_spec.md` to the workspace directory.

## Reference

See `templates/step1_spec.md` for a gold-standard example of output quality and format.

## Rejection Prevention

- Redundant prompts (21.9%): Make the initial prompt complete so Turn 2 doesn't repeat it
- Scope creep (7.6%): Keep all fields within the PR's actual scope
- Low quality task (5.2%): If the PR is trivial, flag it - don't try to make it sound complex
