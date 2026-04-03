# Marlin HFI Agent Skills (V3)

## Project Overview

Modular Agent Skills system for Marlin HFI V3. 10 independent skills, each a SKILL.md file, runnable on Claude Code, Antigravity, Codex, Cursor, or any custom agent.

## V3 Key Changes

- 11 evaluation axes (6.1-6.11), NO 6.12
- Rating A1-B1 (no 0-7 numeric)
- 14 prompt categories required
- Phased implementation: Turn 1 does not need full scope
- No over-prescriptive: describe problem, not step-by-step
- Evaluative strengths (explain WHY, not just descriptive)
- Key-axis field required for A1/A2/B1/B2
- Review model traces beyond diffs
- Multi-language: Python, JS/TS, Go, Rust, Java, C++

## Workspace Convention

Each task creates a workspace: `workspace/{task_id}_{owner}_{repo}_{pr}/`

```
workspace/{task_id}_{owner}_{repo}_{pr}/
  meta.json              # Task metadata
  pr.diff                # Original PR diff
  step1_spec.md          # Step 1 output
  accepted_baseline.json # Winner tracking
  turn_{N}/              # Per-turn artifacts
    prompt.md
    staged_diff_a.patch
    staged_diff_b.patch
    execution_evidence_a.md
    execution_evidence_b.md
    logs_a.txt
    logs_b.txt
    qa/                  # Q&A after checkpoint
      questions.json
      q_{id}_suggestion.md
      q_{id}_answer.md
      q_{id}_review.md
      overall_justification.md
    turn_{N}_evaluation.md
    turn_{N}_next_prompt.md
  step3_finalization.md  # Final output
```

## Skill Invocation

10 skills in Claude Code:

| Skill | Usage |
|-------|-------|
| `/task-select` | Evaluate PR suitability |
| `/task-submit` | Generate Step 1 spec |
| `/checkpoint-review` | A/B evaluation (20 sections, 11 axes) |
| `/checkpoint-qa` | Brainstorm Q&A + Overall Justification |
| `/checkpoint-qa --preset` | Use 7 standard Marlin questions |
| `/checkpoint-qa --overall` | Generate Overall Preference Justification |
| `/checkpoint-prompt` | Generate next-turn prompt |
| `/eval-finalize` | Step 3 finalization |
| `/rewrite-human` | Rewrite text to avoid AI detection |
| `/validate-output` | 38-check validation |
| `/get-logs` | Capture tmux session logs |
| `/gen-claude-md` | Auto-generate CLAUDE.md for repo |

## Auto Quality Gate

ALL skills auto-run validate + rewrite before output (see skills/_shared/auto_quality.md).
CTV does NOT need to call /validate-output separately - output is pre-checked.

## Critical Rules

1. Do NOT use blocked words (see skills/_shared/blocked_words.md)
2. Do NOT use em dashes. Use hyphens or commas
3. Every pro/con MUST reference file:function AND explain WHY (evaluative)
4. Rating MUST be consistent with winner; language MUST match rating level
5. Key-axis field REQUIRED for A1/A2/B1/B2
6. After Turn 1, prompts only address WINNER's code
7. Each turn MUST have NEW content (phased OK, repeat NOT OK)
8. Both models MUST have cons
9. Write in dev voice - direct, casual, specific
10. Do NOT use role-based prompting ("You are a senior engineer...")
11. Do NOT reference PR in prompts
12. V3: 11 axes (6.1-6.11), NO 6.12
13. Do NOT use N/A for any axis (instant rejection)
14. Do NOT git commit between turns (claude-hfi manages git automatically)
15. MUST have CLAUDE.md in repo before running CLI (use /gen-claude-md if missing)
16. MUST setup dev environment (deps, venv, baseline tests) before Turn 1
