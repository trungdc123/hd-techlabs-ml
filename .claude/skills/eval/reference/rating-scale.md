# V3 Rating Scale

## Scale (Numeric 0-7)

| Score | Old Label | Meaning |
|-------|-----------|---------|
| 0 | A1 | Response A clearly superior |
| 1 | A2 | Response A significantly better |
| 2 | A3 | Response A better overall |
| 3 | A4 | Effectively equivalent (lean A) |
| 4 | B4 | Effectively equivalent (lean B) |
| 5 | B3 | Response B better overall |
| 6 | B2 | Response B significantly better |
| 7 | B1 | Response B clearly superior |

**Output format:** Always output the numeric score (0-7). The old A1-B1 labels are for internal reference only.

## Language Guide Per Score

### 0 / 7 (clearly superior)
- "fails", "incorrect", "broken", "useless", "made no changes"
- One model is fundamentally wrong or non-functional

### 1 / 6 (significantly better)
- "substantially better", "missing key coverage", "clearly better"
- One model tried but is wrong, incomplete, or overly complex

### 2 / 5 (better overall)
- "better structured", "tighter scope", "follows requirements more closely", "more consistent"
- Both work but one is noticeably better

### 3 / 4 (equivalent)
- "minor differences only", "functionally equivalent"
- Nearly identical quality, marginal differences

## Correct vs Incorrect Language-Rating Alignment

### WRONG
- Score 2 but writing "clearly better" (too strong for 2)
- Score 0 but hedging with "slightly" (too weak for 0)
- Score 3/4 but writing "B handles this better" (contradicts equivalent)

### CORRECT
- Score 2: "A is better structured and follows conventions more closely"
- Score 0: "A is fundamentally correct while B fails to implement the core requirement"
- Score 6: "B substantially outperforms A in test coverage and error handling"
- Score 3/4: "Both produce functionally equivalent results with minor stylistic differences"

## Key-Axis Field

Required for: 0, 1, 2, 5, 6, 7 (non-equivalent scores)
Not required for: 3, 4 (equivalent only)

State which dimension drives the preference. Examples:
- correctness
- test coverage
- scope control
- root cause handling
- accuracy of self-reporting
- error handling
- code organization

**Calibration note:** Do not default to correctness. Choose the dimension that actually decided the preference. If the deciding signal was tighter scope control, better testing discipline, or more accurate self-reporting/honesty, select that axis directly.
