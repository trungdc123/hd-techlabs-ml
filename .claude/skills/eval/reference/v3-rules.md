# V3 Evaluation Rules

## Core Principle: Relative Comparison

SxS scores reflect relative difference between 2 trajectories, NOT closeness to ideal output. Even when both models perform poorly, evaluate which handles the task better.

Example: Model A correct 60%, Model B correct 30% → rating A3 or A2, NOT A4/B4.

## Justification Language Must Match Rating

| Rating | Language Level |
|--------|---------------|
| A1/B1 | "fails", "incorrect", "broken", "useless" |
| A2/B2 | "substantially better", "missing key coverage", "clearly better" |
| A3/B3 | "better structured", "tighter scope", "better overall" |
| A4/B4 | "minor differences only", "functionally equivalent" |

Writing "clearly better" but rating A3, or hedging language but rating A1 → ambiguity, reviewer will flag.

## Solution Quality, Agency, and Communication Must Be Evaluative

Each of these three fields should explain WHY something matters in context of the rating — not just describe that it happened.

**Wrong:** "Model A added tests."
**Right:** "Model A added regression coverage in tests/test_search.py::test_non_ascii_query — without this test, a future refactor could silently reintroduce the bug."

## Key-Axis Field Required for Non-Equivalent Scores (0, 1, 2, 5, 6, 7)

When rating is 0, 1, 2, 5, 6, or 7: fill key-axis field identifying the dimension(s) that drove the preference. Examples: correctness, test coverage, scope control, root cause handling, accuracy of self-reporting. Can be one dimension or multiple if several axes contributed. One sentence suffices. Not required for scores 3, 4 (equivalent).

**Calibration note:** Do not default to correctness. Choose the axis that best explains the preference signal for that prompt/category. If the deciding factor was tighter scope control, better testing discipline, or more accurate self-reporting/honesty, select that directly as the key axis.

## Diff + Trace Review Mandatory

Must review:
- Code diff line-by-line for each trajectory
- Model traces to evaluate reasoning and actions
- Run code to verify

### 6 Questions When Reviewing Traces

1. Did it actually run tests or just claim it did?
2. Did it investigate root cause or just patch symptoms?
3. Did it avoid risky actions without confirmation?
4. Did it keep scope tight, avoiding unrelated changes?
5. Did it accurately report what changed?
6. Did it stop to ask clarification when needed?

## 7 Required Text Fields

Each model has three fields per turn: Solution Quality, Agency, Communication. Plus senior engineer expectations.

1. **Senior engineer expectations** - what a strong senior SWE would do with this prompt
2. **Model A Solution Quality** - correctness and quality of solution, evaluative with evidence
3. **Model A Agency** - independent agent behavior, risky actions, judgment, clarification-seeking. Cite transcript evidence
4. **Model A Communication** - clarity, honesty about work done, documentation quality. Cite transcript evidence
5. **Model B Solution Quality** - same criteria as A, vary narrative
6. **Model B Agency** - same criteria as A, vary narrative. Cite transcript evidence
7. **Model B Communication** - same criteria as A, vary narrative. Cite transcript evidence

## Writing Style (CRITICAL)

All evaluation text must be written as natural prose. A senior engineer reading this should feel like a colleague wrote it, not a template engine. Strengths, weaknesses, axis answers, and justifications are paragraphs, not bullet lists. Weave evidence (file names, function names, behaviors) into sentences naturally. Vary sentence length and structure. No bullet-point walls, no enumerated lists for analysis, no formulaic openers.

## Common Mistakes

| Mistake | Why It's Wrong |
|---------|---------------|
| Extreme ratings (A1/B1) without supporting diffs | Loses credibility |
| Defaulting equivalent when real difference exists | Avoidance, will be flagged |
| Overuse of N/A | Signal of disengagement |
| Generic justification ("Option A is cleaner") | Must reference specific files, functions, logic |
| Ratings contradict pros/cons | Will be flagged |
| Crediting model for work it didn't do | Serious error - verify claims vs actual diff |
| Descriptive-only strengths | Must be evaluative |
| Empty key-axis for non-equivalent rating | Will be rejected |
| Bullet-point-heavy output | Reads as AI-generated, will be flagged |

## Prompt Rules (Turn 2+)

### Allowed (V3 supersedes V2)
- Phased implementation: Turn 1 no longer requires full scope. Core logic first, remaining functionality (edge cases, tests, secondary features) in later turns - each turn must advance concretely
- Category drift: conversations naturally span multiple prompt types (Discussion -> Code Review is normal)
- Open-ended prompts: OK if acceptance criteria describes expected behavior, correctness signals, and what counts as incomplete. Open-ended should be challengingly open, not vague from lack of thought
- Verifiable prompts encouraged but not strictly required (V3 supersedes V2)

### Not Allowed
- Repeating Turn 1 content (Submission Checker will flag)
- Requirements unrelated to original task, contradicting prior instructions, or belonging to a different scope
- Contradictions between turns
- Meaningless prompts like "double check everything" or "review and fix anything wrong"
- **Over-prescriptive prompts (REJECTION REASON):** Do not micromanage implementation steps. Target 6-8h of competent engineer work. Describe the problem and what done looks like - let the model figure out how. Dictating step-by-step changes to specific lines is over-prescriptive

### Requirements
Minimum 3 meaningful turns with real code changes. Follow-ups must identify a real problem or gap and describe what success looks like (not dictate every step). Preferred output must be production-ready. Each turn must relate to original task, drive real code changes, not contradict or repeat prior turns.

## Anti-Hallucination

Do NOT credit model for code it didn't write (verify in diff). Do NOT penalize model for something its code actually handles. Claims about "missing X" must be verified absent in actual code changes. No mention of PR in output (PR is internal context only).
