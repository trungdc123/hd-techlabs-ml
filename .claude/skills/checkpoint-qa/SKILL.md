---
name: checkpoint-qa
description: Brainstorm questions, suggest answers, evaluate CTV answers, and generate Overall Preference Justification. Supports preset questions, custom questions, multi-input.
user-invocable: true
disable-model-invocation: false
argument-hint: <workspace_path> <turn_number> [--preset] [--overall] [--evaluate q_id] [question_text]
requires:
  - workspace/ with turn_{N}/turn_{N}_evaluation.md already present
  - Diffs and evidence for the current turn
produces:
  - workspace/turn_{N}/qa/questions.json
  - workspace/turn_{N}/qa/q_{id}_suggestion.md
  - workspace/turn_{N}/qa/q_{id}_answer.md (CTV writes)
  - workspace/turn_{N}/qa/q_{id}_review.md
  - workspace/turn_{N}/qa/overall_justification.md
calls:
  - rewrite-human (auto on every output)
  - validate-output (auto on every output)
---

# Checkpoint Q&A - Brainstorm, Answer, and Justification

After checkpoint-review creates the evaluation, this skill:
1. Generates A/B comparison questions (auto or from preset list)
2. Suggests answers with specific code refs
3. Evaluates CTV-written answers (anti copy-paste)
4. Generates Overall Preference Justification for submission

## Input - 6 Modes

### Mode 1: AUTO-GENERATE questions (default)
```
/checkpoint-qa workspace/329_... 1
```
Tool AUTOMATICALLY reads evaluation and generates 3-8 comparison questions. CTV does not need to write questions.
This skill SHOULD BE CALLED AUTOMATICALLY after checkpoint-review.

### Mode 2: Use PRESET QUESTIONS (7 standard questions)
```
/checkpoint-qa workspace/329_... 1 --preset
```
Uses 7 standard questions from Marlin evaluation framework, auto-suggests answers for each.

### Mode 3: Suggest answer for 1 custom question
```
/checkpoint-qa workspace/329_... 1 "How does Model B handle async def compared to A?"
```

### Mode 4: Suggest answers for MULTIPLE questions at once
```
/checkpoint-qa workspace/329_... 1 --questions "Question 1?" "Question 2?" "Question 3?"
```
Or pass a file:
```
/checkpoint-qa workspace/329_... 1 --questions-file my_questions.txt
```

### Mode 5: Evaluate CTV answers
```
/checkpoint-qa workspace/329_... 1 --evaluate q_1
```
Or evaluate multiple:
```
/checkpoint-qa workspace/329_... 1 --evaluate q_1 q_2 q_3
```
Or evaluate all:
```
/checkpoint-qa workspace/329_... 1 --evaluate all
```

### Mode 6: Overall Preference Justification
```
/checkpoint-qa workspace/329_... 1 --overall
```
Synthesizes all Q&A + evaluation into Overall Preference Justification for submission.

## Output Structure

```
turn_{N}/qa/
  questions.json              # [{id, text, category, status}]
  q_1_suggestion.md           # Suggested answer
  q_1_answer.md               # CTV writes their own
  q_1_review.md               # CTV answer review
  q_2_suggestion.md
  ...
  overall_justification.md    # Overall Preference Justification
```

## 9 Preset Questions (Marlin Evaluation Framework)

When using `--preset`, auto-generates and answers these 9 questions across 3 dimensions:

### Solution Quality (Q1-Q5)

| # | Question | Evaluation Focus |
|---|----------|-----------------|
| 1 | **Which code has better logic and correctness?** | Bugs, edge cases, test results, functional correctness |
| 2 | **Which code has better naming and clarity?** | Variable/function names, readability, self-documenting |
| 3 | **Which code has better organization and modularity?** | File structure, separation of concerns, helpers, DRY |
| 4 | **Which code has better interface design?** | API surface, parameter design, return types, usability |
| 5 | **Which code has better error handling and robustness?** | Try/catch, fallbacks, edge cases, graceful degradation |

### Agent Operation (Q6-Q7)

| # | Question | Evaluation Focus |
|---|----------|-----------------|
| 6 | **Which model showed better independent judgment and boundary respect?** | Risky/destructive actions without asking, pushing back on bad suggestions, seeking clarification when ambiguous, senior-engineer-like engagement |
| 7 | **Which model better verified its own work?** | Tests actually run, edge cases checked, assumptions validated, failures fixed vs suppressed |

### Communication (Q8-Q9)

| # | Question | Evaluation Focus |
|---|----------|-----------------|
| 8 | **Which model communicated more clearly and honestly?** | Understandability of messages and summary, accuracy of self-reporting (claims vs actual changes), documentation/comment quality |
| 9 | **Which code is more ready for review/merge?** | Production readiness, test coverage, no leftover TODOs, clean commit history |

Each question is answered with specific code refs (Q1-Q5, Q9) or transcript evidence citations (Q6-Q8), then auto-validated + auto-rewritten.

## Auto-Generate Questions (Mode 1)

### Steps

1. Read `turn_{N}/turn_{N}_evaluation.md`
2. Read diffs (staged_diff_a.patch, staged_diff_b.patch)
3. Read all Q&A from prior turns (if any) to avoid repetition

### Question Generation

Generate 3-8 A/B comparison questions. Each question must:
- **Self-contained** - answerable independently without reading the evaluation
- **Specific** - reference file/function, not generic
- **Comparative** - always ask about differences between A and B
- **Non-duplicate** - not repeat questions from prior turns or preset questions

**GOOD examples:**
- "Model A uses ast.FunctionDef while B also handles AsyncFunctionDef in _read_flow_decorator_kwargs. Which approach handles async flows correctly and why?"
- "B uses importlib.util.find_spec for module resolution, A uses path splitting. In which cases does find_spec produce correct results where path splitting fails?"

**BAD examples:**
- "Which model is better?" (too generic)
- "What do you think about the code?" (no specific comparison)

### Output questions.json

```json
[
  {"id": "q_1", "text": "question...", "category": "custom", "status": "pending"},
  {"id": "q_2", "text": "question...", "category": "custom", "status": "pending"}
]
```

With preset:
```json
[
  {"id": "q_1", "text": "Which code has better logic and correctness?", "category": "preset_logic", "status": "pending"},
  {"id": "q_2", "text": "Which code has better naming and clarity?", "category": "preset_naming", "status": "pending"},
  ...
]
```

## Suggesting Answers

### Answer Format

```markdown
## Question
{original question}

## Answer

{2-3 sentences directly answering. Compare both models. Code refs inline. State which side is better and WHY.}

## Evidence

{Integrated side-by-side comparison - DO NOT separate "Model A" / "Model B":
"A does X (file:func:L##), while B does Y (file:func:L##) - this matters because..."}

## Conclusion

{1-2 sentences: which approach is better. Must have clear opinion.}

---

{Draft 2-3 paragraphs of prose. CTV reads and rewrites in their own style.}
```

### CRITICAL: Integrated Comparison

DO NOT separate into "Model A Analysis" / "Model B Analysis".
MUST compare side-by-side: "A does X... B does Y... this matters because..."

### Answers for Preset Questions

Each preset question has a specific focus and evidence type:

**Solution Quality (code refs required):**
**Q1 Logic & Correctness**: Focus test results, bug counts, edge case handling. Cite: test names passed/failed, specific bugs.
**Q2 Naming & Clarity**: Focus variable/function names, readability. Cite: specific rename, confusing name vs clear name.
**Q3 Organization & Modularity**: Focus file structure, helper extraction, DRY. Cite: duplicated code vs shared helper.
**Q4 Interface Design**: Focus API surface, parameter design. Cite: function signatures, return types.
**Q5 Error Handling**: Focus try/catch, fallbacks, edge cases. Cite: specific error paths, missing catches.

**Agent Operation (transcript evidence required):**
**Q6 Independent Judgment**: Focus risky actions, boundary respect, pushback on bad ideas, clarification seeking. Cite: specific transcript moments where model did/didn't ask before destructive actions, pushed back or blindly followed.
**Q7 Work Verification**: Focus tests actually executed, edge cases tested, failures addressed vs suppressed. Cite: specific test runs, error handling attempts, validation steps from execution logs.

**Communication (transcript evidence required):**
**Q8 Clarity & Honesty**: Focus message understandability, accuracy of self-reporting, documentation quality. Cite: specific model messages, compare claims vs actual diff changes, quote documentation added.
**Q9 Review/Merge Readiness**: Focus production readiness, test coverage, cleanup. Cite: TODOs, lint issues, missing tests.

## Evaluating CTV Answers

### 5 Criteria (X/5 each)

| Criterion | 5/5 | 1/5 |
|-----------|-----|-----|
| Depth | Root cause analysis, trade-offs | "A is better than B" |
| Accuracy | Every claim has correct code ref | Wrong or fabricated claims |
| Completeness | Answers all aspects of question | Skips important parts |
| Specificity | file:func:L## refs | Generic statements |
| Originality | Own phrasing, new insights | Copy-paste of AI suggestion |

### Verdict: STRONG / ADEQUATE / NEEDS WORK

### Copy-Paste Detection
Similarity > 80% vs AI suggestion = Originality 1/5 = NEEDS WORK

### CP-SCOPE Check
All code refs must be from the CURRENT turn's diffs.

### Review Output

```markdown
### Verdict: [STRONG / ADEQUATE / NEEDS WORK]

| Criterion | Score | Comment |
|-----------|-------|---------|
| Depth | X/5 | ... |
| Accuracy | X/5 | ... |
| Completeness | X/5 | ... |
| Specificity | X/5 | ... |
| Originality | X/5 | ... |

### What's Good
{Quote specific parts and explain WHY.}

### What to Improve
{Use pattern: wrong -> correct -> tip}

### Example Rewrite
{REQUIRED if verdict is not STRONG.}
```

## Overall Preference Justification (Mode 6)

This is the most important part for submission. Synthesizes all analysis into one clear justification.

### Input

- All Q&A results (questions + answers + reviews)
- turn_{N}_evaluation.md
- Diffs + evidence

### Steps

1. Read all Q&A answers (both CTV answers and AI suggestions)
2. Read evaluation (Section 1: Preferred Answer, Section 18: SxS Rating)
3. Synthesize evidence from 7 preset questions or custom questions

### Output Format

```markdown
# Overall Preference Justification - Turn {N}

## Preferred Model: {A/B}
## Rating: {A1-B1}
## Key-axis: {main dimension}

## Justification

{4-6 sentences. Explain EXACTLY why the selected model won.

Structure:
- Sentences 1-2: Summarize verdict and key differentiator
- Sentences 3-4: Specific evidence with file:func refs from Q&A answers
- Sentences 5-6: Acknowledge losing model's strengths, explain why insufficient

Language MUST match rating level:
- A1/B1: "fails", "incorrect", "broken"
- A2/B2: "substantially better", "missing key coverage"
- A3/B3: "better structured", "tighter scope"
- A4/B4: "minor differences only"}

## Evidence Summary

### Solution Quality
{Summary from Q1-Q5: logic, naming, organization, interface, error handling}

### Agent Operation
{Summary from Q6-Q7: independent judgment, boundary respect, work verification}

### Communication
{Summary from Q8: clarity, honesty, documentation quality}

### Production Readiness
{Summary from Q9: review/merge readiness}
```

### Auto Quality Gate

Overall Justification also goes through:
1. Auto-Validate: blocked words, em dashes, code refs >= 3
2. Auto-Rewrite: 8-pass humanization
3. Rating-language match check
4. Key-axis field present (if A1/A2/B1/B2)

## Context Accumulation

Within 1 turn, questions chain:
- Q2 suggestion reads Q1 answer
- Q3 suggestion reads Q1 + Q2 answers
- Overall Justification reads all Q&A

Across turns:
- Turn 2 Q&A reads digest from Turn 1 Q&A
- Does not repeat questions already asked

## Workflow Integration

```
checkpoint-review (creates evaluation)
    |
checkpoint-qa (auto-generate questions or --preset)
    |
checkpoint-qa (suggest answers for each question)
    |
CTV writes own answers (or edits suggestions)
    |
checkpoint-qa --evaluate (evaluate CTV answers)
    |
checkpoint-qa --overall (generate Overall Preference Justification)
    |
checkpoint-prompt (uses Q&A + justification as context for next prompt)
```
