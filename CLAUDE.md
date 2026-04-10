# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Modular Agent Skills system for Marlin HFI V3. 10 independent skills (each a SKILL.md file) for A/B model comparison across multiple turns. Runs on Claude Code, Antigravity, Codex, Cursor, or any custom agent. Written in Vietnamese (README, TUTORIAL) with English skill content.

## Common Commands

### Shell Scripts
```bash
# Initialize workspace for a task
bash scripts/init_task.sh <task_id> <pr_url>
# Example: bash scripts/init_task.sh 329 https://github.com/PrefectHQ/prefect/pull/13620

# Fetch PR diff from GitHub API
bash scripts/fetch_pr_diff.sh <task_id> <pr_url>

# Collect A/B diffs from worktrees into turn directory
bash scripts/collect_diffs.sh <workspace_path> <turn_number> <worktree_a_path> <worktree_b_path>
```

### Skill Invocation (Claude Code)
```
/task-select <pr_url>                    # Evaluate PR suitability (TAKE/SKIP/CAUTION)
/task-submit <workspace_path>            # Generate Step 1 spec
/checkpoint-review <workspace_path> <N>  # A/B evaluation (20 sections, 11 axes)
/checkpoint-qa <workspace_path> <N>      # Brainstorm Q&A + Overall Justification
/checkpoint-qa --preset                  # Use 7 standard Marlin questions
/checkpoint-qa --overall                 # Generate Overall Preference Justification
/checkpoint-prompt <workspace_path> <N>  # Generate next-turn prompt
/eval-finalize <workspace_path>          # Step 3 finalization
/rewrite-human [text]                    # Rewrite text to avoid AI detection
/validate-output [file_or_text]          # 38-check validation
/get-logs <model_a> [model_b]           # Capture tmux session logs
/gen-claude-md                           # Auto-generate CLAUDE.md for target repo
```

## Architecture

### Skill System
- Each skill is a self-contained SKILL.md in `skills/<skill-name>/SKILL.md`
- Shared resources in `skills/_shared/`: blocked_words.md, rating_scale.md, rejection_rules.md, style_guide.md, auto_quality.md
- ALL skills auto-run the quality gate pipeline (validate -> rewrite -> final check) before output - defined in `skills/_shared/auto_quality.md`
- Templates in `templates/` provide output structure for step1_spec, turn_evaluation, step3_finalization

### Workspace as State Store
File system IS the checkpoint store - no database. Each task creates `workspace/{task_id}_{owner}_{repo}_{pr}/` with:
- `meta.json` - task metadata and state
- `pr.diff` - original PR diff
- `step1_spec.md` - Step 1 output
- `accepted_baseline.json` - winner tracking across turns
- `turn_{N}/` - per-turn artifacts (prompts, diffs, evidence, evaluation, QA)
- `step3_finalization.md` - final output

Skills read all prior turn artifacts for context accumulation.

### Three-Phase Workflow
1. **Task Setup**: task-select → init_task.sh → fetch_pr_diff.sh → task-submit
2. **Turn Loop** (3+ turns): Models run → get-logs → collect_diffs.sh → checkpoint-review → checkpoint-qa → checkpoint-prompt → repeat
3. **Finalization**: eval-finalize → validate-output

## V3 Key Changes

- 11 evaluation axes (6.1-6.11), NO 6.12 - using N/A for any axis is instant rejection
- Rating scale A1-B1 (no 0-7 numeric), key-axis field required for A1/A2/B1/B2
- 14 prompt categories required
- Phased implementation: Turn 1 does not need full scope
- Evaluative strengths (explain WHY with file:function refs, not just descriptive)
- Multi-language support: Python, JS/TS, Go, Rust, Java, C++

## Critical Rules

1. **Blocked words**: 25 EN + 14 VI words cause instant reject - see `skills/_shared/blocked_words.md`
2. **No em dashes** - use hyphens or commas
3. **Every pro/con MUST reference file:function AND explain WHY** (evaluative, not descriptive)
4. **Rating direction MUST match winner**; justification language must match rating level
5. **After Turn 1, prompts only address WINNER's code**
6. **Each turn MUST have NEW content** - phased OK, repeat NOT OK
7. **Both models MUST have cons**
8. **Dev voice** - direct, casual, specific. No role-based prompting
9. **Do NOT reference the PR in prompts**
10. **Do NOT git commit between turns** - claude-hfi manages git automatically
11. **MUST have CLAUDE.md in target repo** before running CLI (use /gen-claude-md)
12. **MUST setup dev environment** (deps, venv, baseline tests) before Turn 1

## Auto Quality Gate

All skills run a 3-step pipeline before output:
1. **Auto-Validate**: P0 checks (blocked words, em dashes, curly quotes, missing code refs, rating consistency) - auto-fix without asking
2. **Auto-Rewrite**: 8-pass humanization scan targeting AI patterns
3. **Final Check**: Verify technical accuracy preserved after rewrites

Max 2 validate-rewrite loops (circuit breaker). CTV does NOT need to call /validate-output separately.
