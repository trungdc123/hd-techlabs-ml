---
name: checkpoint-prompt
description: Generate next-turn prompt based on evaluation gaps. Ensures novelty, avoids redundancy, stays in scope.
user-invocable: true
disable-model-invocation: false
argument-hint: <workspace_path> <turn_number>
requires:
  - workspace/ with turn_{N}/turn_{N}_evaluation.md
  - All prior turn prompts and evaluations
  - accepted_baseline.json
produces:
  - workspace/turn_{N}/turn_{N}_next_prompt.md
calls:
  - validate-output (internal)
---

# Checkpoint Prompt - Next-Turn Prompt Generator

Generate the prompt for the next turn based on gaps identified in the current evaluation.

## Input

Workspace path + current turn number (the turn whose evaluation was just completed).

## Output

Write `turn_{N}/turn_{N}_next_prompt.md` - a flowing prose prompt that addresses the winner's remaining gaps.

## Output Format

The prompt should be flowing prose, 3-6 paragraphs. NO headers, NO bullet lists, NO numbered steps. Write it as natural instructions a senior engineer would give a colleague.

Focus the prompt on:
1. What specific gaps remain in the winner's implementation
2. What NEW aspects to address (not repeating prior turns)
3. What tests to add or verify
4. Any edge cases that emerged during review

## Steps

### Phase 1: Read Context

1. Read `accepted_baseline.json` - which model won and why
2. Read `turn_{N}/turn_{N}_evaluation.md` - the evaluation just completed
3. Read ALL prior prompts: `turn_1/prompt.md` through `turn_{N}/prompt.md`
4. Read ALL prior evaluations for trajectory understanding
5. Read `step1_spec.md` for original acceptance criteria

### Phase 2: Identify Gaps

From the current evaluation, extract:
- Winner's weaknesses (Section 4 or 6 depending on winner)
- Any axis rated neutral (4) that could be improved
- Missing test coverage
- Edge cases not yet handled
- Any acceptance criteria not yet met

### Phase 3: Draft Prompt

Write the next-turn prompt as flowing prose:
- Address the WINNER's code specifically (P2: after Turn 1, both models get winner's code)
- Each paragraph should address a different gap or aspect
- Be specific about WHAT to change and WHERE (file:function)
- Don't repeat requirements from prior prompts

### Phase 4: Self-Review Gates

**GATE 1 - Novelty Check (21.9% of rejects - #1 reason):**
Compare your draft against ALL prior prompts.
For each prior prompt, check:
- Are you repeating any requirement that was already addressed?
- Are you re-stating the same thing in different words?
- Is the similarity too high? (should be clearly different)

If you find redundancy: REMOVE the redundant parts. If nothing new remains, the task may be complete - say so.

**GATE 2 - Scope Check (7.6% of rejects):**
Compare your draft against the original issue in step1_spec.md.
- Does every requirement in the prompt relate to the original issue?
- Are you introducing scope creep (features, refactors, or concerns outside the original PR)?

If scope creep found: REMOVE it. Keep the prompt within the original issue scope.

**GATE 3 - Winner-Only Check (P2: 13.1%):**
After Turn 1:
- Prompt should address the WINNER's code, not the loser's
- NEVER reference the original PR or GitHub
- NEVER mention "PR", "#1234", "pull request"
- Both models will receive this prompt and start from the winner's codebase

**GATE 4 - Completeness:**
The prompt should result in real code changes, not just:
- Running tests (that's not a new turn)
- Adding comments (that's not meaningful)
- Reformatting (that's not a real improvement)

Each turn must introduce NEW aspects: implementation, tests, edge cases, error handling, docs, refactoring.

### Phase 5: Auto Quality Gate (REQUIRED before output)

Run auto_quality.md pipeline:
1. Auto-Validate: Blocked words, em dashes, PR references -> auto-fix
2. Auto-Rewrite: 8-pass humanization -> rewrite AI-patterned sentences
3. Final Check: Verify prompt still self-contained and accurate

Output only written AFTER passing. CTV does not need to call /validate-output separately.

### Phase 6: Write Output

Write the final prompt to `turn_{N}/turn_{N}_next_prompt.md`.

## Reasoning Protocol (REACT)

Before drafting, think step-by-step:
1. IDENTIFY: What gaps exist in the winner's code?
2. ANALYZE: Which gaps are NEW (not addressed in prior turns)?
3. SYNTHESIZE: What's the most impactful set of improvements for this turn?
4. PLAN: How to structure the prompt as flowing prose?

## Turn Progression Pattern (V3)

**Turn 1 prompt** (from step1_spec.md): Core logic - full scope NOT required (V3 change from V2)
**Turn 2 prompt**: Add edge cases, tests, or secondary features
**Turn 3 prompt**: Polish, remaining gaps, documentation

V3 allows phased implementation: each turn adds new functionality, as long as it advances concretely.

## V3 Phased Implementation Rules

- V3 ALLOWS adding edge cases, tests, secondary features in later turns
- BUT each turn MUST advance implementation concretely (not just "add comments")
- Pure repetition still REJECTED - each turn must have NEW content
- Prompt scope must be coherent - like 1 hypothetical PR, everything plausibly in 1 PR
- Prompt addresses WINNER's code (both models receive winner's code after Turn 1)
- Must NOT request features unrelated to repo/PR scope

## Content Rules

- NO headers, NO bullet lists, NO numbered steps in the prompt
- Write as natural instructions a senior engineer would give
- Mention file paths naturally in sentences
- End with success criteria (what "done" looks like for this turn)
- NO mention of PR, pull request, GitHub, issue number
- NO commit hashes, author names, branch names

## Anti-Redundancy Examples

**BAD** (redundant with Turn 1):
"Implement AST-based extraction for the flow decorator..." (this was Turn 1's job)

**GOOD** (addresses new gap):
"The implementation handles async def flows via AsyncFunctionDef in the AST walkers, but it does not handle keyword-only arguments in _signature_from_ast. If a flow function uses keyword-only parameters (arguments after a bare * in the signature), the current implementation will silently drop them from the generated schema."

**BAD** (scope creep):
"Also add support for remote flow definitions fetched via HTTP..."

**GOOD** (within original scope):
"Review the keyword-only argument handling in _signature_from_ast and verify that the parameter schema includes kwonly parameters."
