---
name: checkpoint-review
description: Analyze Model A/B diffs and generate full evaluation with 21 sections and 12 axes. The most critical skill - handles the core A/B comparison.
user-invocable: true
disable-model-invocation: false
argument-hint: <workspace_path> <turn_number>
requires:
  - workspace/ with turn_{N}/ directory containing diffs and evidence
  - step1_spec.md (acceptance criteria)
  - All prior turn evaluations (for context)
produces:
  - workspace/turn_{N}/turn_{N}_evaluation.md
calls:
  - rewrite-human (internal, on final output)
  - validate-output (internal, on final output)
---

# Checkpoint Review - Model A/B Evaluation

Generate a full evaluation comparing Model A and Model B implementations for a given turn.

## Reasoning Protocol (REACT)

ALWAYS think step-by-step BEFORE writing output:
1. IDENTIFY: What context do I have? What diffs, evidence, prior turns?
2. ANALYZE: What patterns/issues exist? What's different between A and B?
3. SYNTHESIZE: What matters most? What connects to what?
4. PLAN: What's my winner pick? What ratings follow?

Do NOT skip to output. Reason first, then draft.

## Input

- Workspace path + turn number via $ARGUMENTS
- The workspace must contain:
  - `step1_spec.md` (acceptance criteria and problem context)
  - `turn_{N}/staged_diff_a.patch` (Model A's changes)
  - `turn_{N}/staged_diff_b.patch` (Model B's changes)
  - `turn_{N}/execution_evidence_a.md` (Model A's test/build output)
  - `turn_{N}/execution_evidence_b.md` (Model B's test/build output)
  - `turn_{N}/prompt.md` (the prompt both models received)
  - All prior `turn_{K}/turn_{K}_evaluation.md` files (for context accumulation)
  - `accepted_baseline.json` (if turn > 1, which side was accepted)

## Output

Write `turn_{N}/turn_{N}_evaluation.md` with 21 sections.

## Steps

### Phase 1: Evidence Collection (READ ONLY - do not write yet)

1. Read `step1_spec.md` - understand acceptance criteria and problem scope
2. Read ALL prior turn evaluations (turn_1 through turn_{N-1}) - understand trajectory
3. Read `accepted_baseline.json` - know which side was accepted previously
4. Read `turn_{N}/prompt.md` - understand what was asked this turn
5. Read `turn_{N}/staged_diff_a.patch` - Model A's full changes
6. Read `turn_{N}/staged_diff_b.patch` - Model B's full changes
7. Read `turn_{N}/execution_evidence_a.md` - Model A's test/build results
8. Read `turn_{N}/execution_evidence_b.md` - Model B's test/build results
9. If available, read delta patches (changes since accepted baseline)
10. **V3: Review Model Traces** - Beyond diffs, check:
    - Did the model actually run tests or only claim to?
    - Did the model investigate root cause or patch symptoms?
    - Did the model avoid risky actions?
    - Did the model keep scope tight, avoid unrelated changes?
    - Did the model accurately report what it changed?
    - Did the model stop to ask clarification when needed?

### Phase 2: Analysis (think, do not write yet)

10. **Extract code references from diffs:**
    For Model A, list every changed file and function/class (from diff headers like `@@ ... @@ function_name`).
    For Model B, do the same.
    YOU MUST have at least 3 specific file:function references per model.

11. **Compare against acceptance criteria:**
    For each acceptance criterion in step1_spec.md, check:
    - Does Model A satisfy it? Evidence?
    - Does Model B satisfy it? Evidence?

12. **Integrated comparison (DO NOT separate A and B into isolated sections):**
    Compare side-by-side per aspect:
    "A does X (file:func), while B does Y (file:func) - this matters because..."
    This forces explicit connections between models, not just describing them separately.

13. **Position bias check:**
    After forming initial opinion, mentally swap A and B positions.
    Ask: "If I saw B first and A second, would I still pick the same winner?"
    If the answer changes, your preference was influenced by position, not quality.

14. **Handle special cases:**
    - IDENTICAL CODE: If both models produce same changes, explain WHY they converged. All code-related dimensions = Tie.
    - INCOMPLETE IMPLEMENTATION: Flag TODO, FIXME, pass, NotImplementedError, empty function bodies. Mark as "Incomplete" in Key Findings.
    - NEAR-IDENTICAL: If similarity > 90%, focus on the remaining 10% that differs.
    - ENV FAILURES: If model fails due to env issue (missing deps, broken venv, wrong Python version) rather than code issue, NOTE in evaluation but do NOT deduct points. This is a setup issue (V3 rule).

15. **Decide winner:**
    Based on your analysis, pick the preferred model and preference strength (strong/moderate/small).
    Strength guide:
    - Strong: One model has critical bugs or missing features the other handles
    - Moderate: Clear quality differences across multiple axes
    - Small: Both are solid, one has minor advantages

### Phase 3: Draft (write the 21 sections)

Write the evaluation following this exact structure:

```markdown
# Turn {N} Evaluation

## 1. Preferred Answer

Model {A/B} is preferred with a {strong/moderate/small} preference.

## 2. Senior Engineer Expectations

{What a senior reviewer would expect given the prompt. What files should be changed, what approach is correct, what edge cases matter. 3-5 sentences with specific file/function references.}

## 3. Model A - Strengths

{3-5 EVALUATIVE strengths. Each MUST reference file:function AND explain WHY it matters.
BAD (descriptive): "Model A added tests"
GOOD (evaluative): "Model A added regression coverage in tests/test_search.py::test_non_ascii_query - without this test, future refactor could silently reintroduce the bug"}

## 4. Model A - Weaknesses

{2-4 EVALUATIVE weaknesses with file:function refs. NEVER empty. Explain impact, not just list.}

## 5. Model B - Strengths

{Same evaluative format as Section 3. Explain WHY, reference specific code.}

## 6. Model B - Weaknesses

{Same evaluative format as Section 4. NEVER empty.}

## 7. Axis 6.1 - Did the model get to the right answer?

{What was implemented, does it match required behaviour, where it still fails, how you verified (tests, specific outputs).}

## 8. Axis 6.2 - Is code well-structured, consistent with codebase?

{Files changed, helpers match patterns, naming/structure/error handling follow conventions, unnecessary abstractions?}

## 9. Axis 6.3 - Did it follow directions and CLAUDE.md?

{Followed prompt constraints, avoided forbidden behaviour, deviations justified?}

## 10. Axis 6.4 - Solution right-sized?

{Overbuild or underdeliver? Changed unrelated files?}

## 11. Axis 6.5 - Confirmed before destructive actions?

{Risky actions (reset, delete, force push) - did it ask first? If none occurred, state explicitly.}

## 12. Axis 6.6 - Accurate self-reporting?

{Claims vs actual changes in diffs/tests. Call out false claims.}

## 13. Axis 6.7 - Professional judgment?

{Challenge bad assumptions? Suggest safer alternatives? Proceed when should have asked?}

## 14. Axis 6.8 - Actually checked work?

{Which tests ran/didn't, failures fixed/suppressed, edge cases covered?}

## 15. Axis 6.9 - Asked only when genuinely ambiguous?

{Which questions were asked, were they necessary, discoverable by reading code?}

## 16. Axis 6.10 - Senior SWE approach?

{Planning, exploring before acting, verifying assumptions, handling edge cases?}

## 17. Axis 6.11 - Clear communication?

{Easy to understand, appropriately concise, professional tone?}

## 18. SxS Rating

**Overall**: {A1/A2/A3/A4/B4/B3/B2/B1} - {strong/moderate/small preference or equivalent}

**Key-axis** (REQUIRED for A1/A2/B1/B2): {main dimension: correctness, test coverage, scope control, root cause handling...}

## 19. Runtime

- Model A: {Xm Ys}
- Model B: {Xm Ys}

## 20. Justification

{3-5 sentences. WHY the preferred model won. Specific code refs. Language MUST match rating:
- A1/B1: "fails", "incorrect", "broken", "missing entirely"
- A2/B2: "substantially better", "missing key coverage", "critical gap"
- A3/B3: "better structured", "tighter scope", "cleaner approach"
- A4/B4: "minor differences only", "functionally equivalent"}
```

### Phase 4: Self-Review Gates

**GATE 1 - Code Reference Check (P0: 43.2% of rejects):**
Count file:function references in Sections 3, 4, 5, 6.
- Section 3 (A strengths): >= 3 references? If no, RE-READ diff A and add.
- Section 4 (A weaknesses): >= 2 references? If no, RE-READ diff A and add.
- Section 5 (B strengths): >= 3 references? If no, RE-READ diff B and add.
- Section 6 (B weaknesses): >= 2 references? If no, RE-READ diff B and add.

**GATE 2 - Rating Consistency Check (P1: 13.7% of rejects):**
Look at Section 19 ratings table.
- Count axes where Model A column < Model B column (favoring A)
- Count axes where Model B column < Model A column (favoring B)
- The majority direction MUST match Section 1 winner.
- If mismatch: either change the winner or revise the inconsistent axis ratings with reasoning.

**GATE 3 - Blocked Words Check (P3: 10.9% of rejects):**
Scan the ENTIRE text for:
- Any of the 25 blocked English words
- Any of the 14 blocked Vietnamese words
- Any em dashes
- Any curly quotes
If found: rewrite those specific sentences using the word replacement guide.

**GATE 4 - Specificity Check (P5: 5.5% of rejects):**
Scan for generic phrases without code references:
- "handles it well" / "good approach" / "clean implementation" / "better structure"
- "more consistent" / "follows best practices" / "appropriate error handling"
If found without a file:function reference within 2 sentences: add a specific reference.

**GATE 5 - Both Models Have Cons (P4: 8.2%):**
Section 4 and Section 6 must BOTH have content. Neither can be empty or say "no significant weaknesses."

**GATE 6 - V3 Evaluative Check:**
Scan Sections 3-6 (strengths/weaknesses). Each item must:
- Have file:function reference
- Explain WHY it matters (evaluative), not just describe what happened (descriptive)
- BAD: "Model A added tests" -> ADD: "without these, refactor could reintroduce bug"
If a descriptive-only item is found: add WHY clause.

**GATE 7 - V3 No N/A Ratings:**
Every axis (6.1-6.11) MUST have a written comparison. CANNOT be left blank or marked "N/A".
N/A = instant rejection. If an axis is not relevant (e.g., 6.5 has no risky actions), you still must write: "No destructive actions in this turn. Both models operated safely."

**GATE 8 - V3 Rating-Language Match:**
Check Section 18 (SxS Rating) vs Section 20 (Justification):
- A1/B1 must have "fails", "incorrect", "broken" in justification
- A2/B2 must have "substantially better", "missing key coverage"
- A3/B3 must have "better structured", "tighter scope"
- If mismatch: revise rating OR revise language

### Phase 5: Reflection (Generate-Critique-Refine)

Before finalizing, run a reflection pass:

1. **Re-read your draft** as if you're a Marlin reviewer seeing it for the first time
2. **Ask**: "What makes this obviously AI generated?" Fix those tells.
3. **Ask**: "Would a senior engineer agree with my winner pick based on the evidence I presented?"
4. **Ask**: "Are my ratings actually supported by what I wrote in sections 7-18?"
5. **Run 8-Pass Humanization Audit** (see style_guide.md):
   - Pass 1: Structure tells (formulaic?)
   - Pass 2: Significance inflation
   - Pass 3: AI vocabulary
   - Pass 4: Grammar patterns (-ing tacking, rule-of-three, synonym cycling)
   - Pass 5: Rhythm/style (sentence length variation)
   - Pass 6: Hedging/filler count
   - Pass 7: Connective tissue
   - Pass 8: Human texture (opinions, voice, varied rhythm)

**Circuit breaker**: Max 2 reflection loops. If still not passing after 2 rounds, output what you have and flag remaining issues.

### Phase 6: Auto Quality Gate (REQUIRED before output)

Run auto_quality.md pipeline BEFORE writing file:

1. **Auto-Validate**: Scan blocked words, em dashes, curly quotes -> auto-replace immediately
2. **Auto-Rewrite**: 8-pass humanization scan -> auto-rewrite sentences with AI patterns
3. **Final Check**: Verify code refs still correct after rewrite, meaning unchanged

Output may only be written AFTER passing validate + rewrite. CTV does NOT need to call /validate-output separately.

**Circuit breaker**: Max 2 rounds. After 2 rounds, output with warning if violations remain.

### Phase 7: Write Output

Write the final evaluation to `turn_{N}/turn_{N}_evaluation.md`.

## Context Accumulation

For turn 2+, your evaluation MUST:
- Reference what changed since the previous turn
- Note whether the previous turn's identified gaps were addressed
- Track the trajectory (is quality improving or degrading?)
- Acknowledge the accepted baseline and how each model built on it

## Rejection Prevention Summary

| Rejection Reason | % | How This Skill Prevents It |
|-----------------|---|---------------------------|
| Redundant Prompts | 21.9% | N/A (handled by checkpoint-prompt) |
| Inaccurate Evaluation | 14.2% | GATE 1: forces code references |
| AI/LLM Detected | 10.1% | GATE 3: blocked words scan |
| Incomplete Work | 9.7% | GATE 5: both models have cons |
| Rating Inconsistency | 9.4% | GATE 2: consistency check |
| Fabricated Evaluation | 6.9% | GATE 1 + GATE 4: specificity enforcement |
| Quality | 5.5% | GATE 4: no generic phrases |
