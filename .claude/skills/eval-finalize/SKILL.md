---
name: eval-finalize
description: Generate Step 3 finalization with final ratings, trajectory, justification, and submission readiness. Run after all turns are complete.
user-invocable: true
disable-model-invocation: false
argument-hint: <workspace_path>
requires:
  - workspace/ with all turns complete (3+ turns with evaluations)
  - step1_spec.md
  - accepted_baseline.json
produces:
  - workspace/step3_finalization.md
calls:
  - rewrite-human (internal)
  - validate-output (internal)
---

# Eval Finalize - Step 3 Finalization Generator

Generate the final submission document after all turns are complete.

## Input

Workspace path via $ARGUMENTS or chat. All turns must be complete with evaluations.

## Output

Write `step3_finalization.md` to the workspace with 10 sections.

## Steps

### Phase 1: Aggregate All Data

1. Read `meta.json` for task metadata
2. Read `step1_spec.md` for categories and acceptance criteria
3. Read ALL turn evaluations: `turn_1/turn_1_evaluation.md` through `turn_N/turn_N_evaluation.md` (each has 22 sections: 3 evaluation dimensions per model + 11 axes + rating/justification)
4. Read ALL turn prompts
5. Read `accepted_baseline.json` for the trajectory of accepted sides

### Phase 2: Compute Trajectory

For each turn, extract:
- Which model was preferred
- Preference strength (strong/moderate/small)
- Key reasons for preference

Build the trajectory narrative: "Turn 1: B (moderate). Turn 2: A (small). Turn 3: B (small)."

Determine the final accepted baseline - which side's code represents the best composite.

### Phase 3: Compute Final Ratings

Use the label format (A1-A4/B4-B1) for final ratings.
- A1: Strong A preference
- A2: Moderate A preference
- A3: Small A preference
- A4/B4: Neutral
- B3: Small B preference
- B2: Moderate B preference
- B1: Strong B preference

Base final ratings on the OVERALL trajectory, not just the last turn. If B won turns 1 and 3 but A won turn 2, the final ratings should reflect B's overall advantage while acknowledging A's contribution.

### Phase 4: Draft 10 Sections

```markdown
# Step 3 Finalization - Task {task_id}

## 1. PR URL

{full GitHub PR URL}

## 2. Categories Represented Across the Conversation

{category1}, {category2}.

## 3. Final Preferred Trajectory

Turn 1: {side} ({strength} preference). Turn 2: {side} ({strength} preference). Turn 3: {side} ({strength} preference).

{1-2 paragraphs describing the composite trajectory. Which side provided the foundation? Which side filled gaps? What's the net result? Reference specific contributions from each turn.}

## 4. Final Multi-Axis Ratings (V3: 11 axes, A1-B1)

- 6.1 Right answer and verification: {A1-B1 label}
- 6.2 Well-structured, consistent with codebase: {label}
- 6.3 Followed directions and CLAUDE.md: {label}
- 6.4 Right-sized solution: {label}
- 6.5 Confirmed before destructive actions: {label}
- 6.6 Accurate self-reporting: {label}
- 6.7 Professional judgment: {label}
- 6.8 Actually checked work: {label}
- 6.9 Asked only when genuinely ambiguous: {label}
- 6.10 Senior SWE approach: {label}
- 6.11 Clear communication: {label}

**Key-axis** (REQUIRED for all ratings except A4/B4 tie): List up to 3 axes that held the most weight in overall preference.

## 5. Average Model Runtime

- Average Model A runtime: {Xm Ys} (from {t1}, {t2}, {t3})
- Average Model B runtime: {Xm Ys} (from {t1}, {t2}, {t3})
- Overall average model runtime: {Xm Ys}

## 6. Overall Justification

{4-6 sentences. Explain the trajectory across all turns across 3 dimensions: solution quality, agent operation, and communication. Reference specific code contributions and agent behavior evidence from each model. Explain why the winner won and what the loser contributed. Use specific file:function references and transcript evidence.}

## 7. Submission Readiness

{Is the task ready to submit? What's complete? 2-3 sentences.}

## 8. Missing Evidence or Blockers

{Any gaps in evidence? Tests not run? Missing coverage? If none: "No blockers exist."}

## 9. Turn Summary

{For each turn, 2-3 sentences: what changed, who won, why. Include runtime.}

**Turn 1** - {summary}. A: {time}, B: {time}.
**Turn 2** - {summary}. A: {time}, B: {time}.
**Turn 3** - {summary}. A: {time}, B: {time}.

## 10. Notes for Platform Submission

{Any formatting inconsistencies across turns, caveats about the evaluation, or other notes the reviewer should know.}
```

### Phase 5: Reflection (Generate-Critique-Refine)

Before gates, re-read your draft:
1. Does the trajectory narrative in Section 3 actually match the per-turn winners?
2. Is Section 6 justification supported by specific evidence, or is it vague?
3. Does Section 9 turn summary capture the KEY difference in each turn?
4. Run 8-Pass Humanization Audit on the full text (see style_guide.md)
5. Circuit breaker: max 2 reflection loops

### Phase 6: Self-Review Gates

**GATE 1 - Trajectory Consistency:**
Check that Section 3 (trajectory) is consistent with Section 4 (final ratings).
If the trajectory shows B won 2 of 3 turns, the final ratings should mostly favor B.

**GATE 2 - Code References in Justification:**
Section 6 (justification) must contain at least 3 specific file:function references.
If fewer: go back and add references from the turn evaluations.

**GATE 3 - Completeness:**
- Section 5 must have actual runtime numbers (not placeholders)
- Section 8 must honestly report any gaps
- Section 9 must cover ALL turns (not skip any)

**GATE 4 - Anti-AI:**
Run blocked words scan on the entire document.
No em dashes, no blocked words, no template language.

**GATE 5 - Rating Label Format:**
All ratings in Section 4 must use label format (A1/A2/A3/A4/B4/B3/B2/B1), not numeric.

**GATE 6 - Key-axis Required:**
Key-axis field must be present for all non-tie ratings (everything except A4/B4). Must list up to 3 axes.

### Phase 7: Auto Quality Gate (REQUIRED before output)

Run auto_quality.md pipeline:
1. Auto-Validate: Blocked words, em dashes, rating format -> auto-fix
2. Auto-Rewrite: 8-pass humanization -> rewrite AI-patterned sentences
3. Final Check: Verify ratings, trajectory, code refs still accurate

Output only written AFTER passing. CTV does not need to call /validate-output separately.

### Phase 8: Write Output

Write the final `step3_finalization.md` to the workspace directory.

## Rejection Prevention

- Rating inconsistency (9.4%): GATE 1 ensures trajectory matches ratings
- AI detection (10.1%): GATE 4 scans for blocked words
- Incomplete work (9.7%): GATE 3 checks all sections are filled
- Inaccurate evaluation (14.2%): GATE 2 requires code references
