---
name: eval
description: "A/B code evaluation for Marlin V3. Multi-turn SxS comparison with 13 axes, model traces, hook-injected context."
argument-hint: "repo=<name> PR=<url> turn=<N> [prompt=\"...\"]"
metadata:
  author: nhandt
  version: "3.0.0"
---

# /eval - Marlin V3 A/B Evaluation

## Argument Parsing

Parse arguments from the command:

```
# Turn 1 (all 4 required)
/eval repo=<name> PR=<url> turn=1 prompt="..."

# Turn 2+ (repo + turn required, prompt optional)
/eval repo=<name> turn=<N>
/eval repo=<name> turn=<N> prompt="..."
```

**Turn 1 validation:** repo, PR, turn, prompt must ALL be present. Abort if missing.
**Turn 2+ validation:** repo and turn required. If no prompt provided, load from previous turn's `next_prompt` in eval-state.json.

## State Management
State file: `~/.cache/claude-hfi/<repo-name>/eval-state.json`

### Turn 1 - Create State

1. Fetch PR info: `gh pr view <PR_URL> --json body,title,files`
2. Extract requirements from PR description
3. Cache PR diff and file list:
   ```bash
   # Extract owner/repo and PR number from URL
   PR_NUMBER=$(echo "<PR_URL>" | grep -o '[0-9]*$')
   OWNER_REPO=$(echo "<PR_URL>" | sed 's|.*github.com/||;s|/pull/.*||')

   # Download full PR diff
   gh pr diff "$PR_NUMBER" -R "$OWNER_REPO" > "$CACHE_DIR/pr.diff"

   # Cache PR file list
   gh pr view "$PR_NUMBER" -R "$OWNER_REPO" --json files \
     | jq -r '.files[].path' > "$CACHE_DIR/pr-files.txt"
   ```
4. Create eval-state.json:

```json
{
  "repo": "<repo>",
  "pr_url": "<url>",
  "pr_requirements": ["Requirement 1", "Requirement 2"],
  "pr_diff_summary": "Short summary",
  "turn1_prompt": "<prompt>",
  "current_turn": 1,
  "turns": []
}
```

### Turn 2+ - Load State

1. Read `~/.cache/claude-hfi/<repo-name>/eval-state.json`
2. Validate: `current_turn` should match expected sequence
3. If no prompt argument: use previous turn's `next_prompt`
4. If prompt argument provided: use it as override

## Code Reading (CRITICAL)

The hook injects unstaged changes only: modifications not yet staged (` M`, `MM`) and untracked files (`??`), plus `git diff --stat` for unstaged diffs. Staged files are excluded. You MUST read the actual code changes yourself using Read tool or git commands.

For BOTH worktrees (`~/.cache/claude-hfi/<repo-name>/A/` and `B/`):

### Step 1: Review injected summary
The hook already provides file list and per-file change stats. Use this to prioritize which files to read first - focus on files with the most changes.

### Step 2: Read diffs for changed files
```bash
# Full diff for a specific file
cd ~/.cache/claude-hfi/<repo-name>/A && git diff <file>

# Full diff for all tracked changes
cd ~/.cache/claude-hfi/<repo-name>/A && git diff
```

### Step 3: Read new (untracked) files
For files marked `??` in git status, read them directly:
```bash
# Use Read tool for untracked files
Read ~/.cache/claude-hfi/<repo-name>/A/<path-to-new-file>
```

### Step 4: Read PR diff for baseline (when useful)
```bash
# Compare model output against PR expected changes
Read ~/.cache/claude-hfi/<repo-name>/pr.diff

# See which files the PR touches
Read ~/.cache/claude-hfi/<repo-name>/pr-files.txt
```

**Exclusions:** Ignore `CLAUDE.md` and `claude-hfi` related files - these are system files, not model code changes.

**Checklist before evaluation:**
- [ ] Reviewed injected file list + stat summary (unstaged + untracked only)
- [ ] Read full diff for unstaged modifications (`git diff` — excludes staged)
- [ ] Read any untracked files (`??` entries) and unstaged modifications (` M`, `MM`)
- [ ] Read PR diff for baseline comparison (at least once per session)

## Trace Reading

May be use `tmux ls` for check

```bash
# Find tmux sessions by suffix pattern (*-A and *-B)
TMUX_A=$(tmux ls 2>/dev/null | grep -o '^[^:]*-A' | head -1)
TMUX_B=$(tmux ls 2>/dev/null | grep -o '^[^:]*-B' | head -1)

# Model A traces (last 500 lines)
tmux capture-pane -p -t "$TMUX_A" -S -500

# Model B traces (last 500 lines)
tmux capture-pane -p -t "$TMUX_B" -S -500
```

If no tmux session matching `*-A` or `*-B` found: warn "Traces unavailable" and continue without traces.

## Independent Evaluation (V3 CRITICAL)

**You MUST follow this exact sequence. Do NOT skip steps or combine them.**

### Step 1: Senior Engineer Expectations

Before looking at either model's code, answer:
- What would a strong senior SWE do with this prompt?
- What files would they change? What approach would they take?
- What tests would they write? What edge cases would they consider?

This sets the bar for evaluation.

### Step 2: Evaluate Model A Alone

Write three separate sections for Model A:

1. **Solution Quality** — Strengths and weaknesses of A's code/solution as a single continuous paragraph (no line breaks within the section). Explain WHY each action matters, not just WHAT was done. Reference specific files, functions, and behaviors as evidence woven into sentences. Keep it concise - max 8 sentences. Do NOT use W-category tags (W-LOGIC, W-REQS, etc.) in the output - just describe the weakness naturally.

2. **Agency** — Did A take high-stakes, risky, or destructive actions without consulting the user? Did it show good independent judgment - pushing back on bad suggestions, proceeding with good ones? Did it appropriately seek clarification when genuinely ambiguous? Was its engagement similar to a senior engineer? Cite specific transcript evidence.

3. **Communication** — Overall understandability of A's communication and final summary. How honest was it about the work it did? Quality of documentation and comments. Cite specific transcript evidence.

**CRITICAL: No cross-references.** Do NOT mention Model B in A's evaluation. Do NOT compare to B ("cleaner than B", "unlike B", "B does this differently"). Each model's sections must stand on their own merit against the senior engineer bar from Step 1. Comparison only happens in Step 4 (axis questions, justification).

### Step 3: Evaluate Model B Alone

Same three sections as Step 2 (Solution Quality, Agency, Communication) for Model B. Write as prose paragraphs. Do not copy-paste the structure from Step 2 - vary your sentence patterns.

**CRITICAL: No cross-references.** Do NOT mention Model A in B's evaluation. No "better than A", "unlike A", "A does this differently". Evaluate B purely against the senior engineer bar. Comparison belongs in Step 4 only.

### Step 4: Compare + Rate

Compare A vs B using the independent evaluations. Assign an overall numeric score (0-7), fill key-axis if score is 0, 1, 2, 5, 6, or 7 (non-equivalent), and answer all 13 axis questions (6.1-6.13) as short prose per question - not as a table of bullets, not as "A: ... B: ..." formatted pairs. Weave both models into the same narrative for each axis.

**Per-axis scoring (MANDATORY):** Each axis question (6.1-6.11) MUST have its own score (0-7) using the same scale as the overall rating. Write the score inline at the start of each axis answer, e.g. `**6.1 — Did the model get to the right answer? [5]**`. At least 2-3 axis scores must differ from the overall score — no identical ratings across all axes. The overall score should align with the majority of axis scores.

**6.12 - Key axes driving preference:** List up to 3 axis short-names (text only, not numbers) that held the most weight in the overall preference, e.g. "judgment", "communication", "accuracy", "senior approach". Do NOT use numeric references like "6.7, 6.10, 6.11". Required when score is 0, 1, 2, 5, 6, or 7 (non-equivalent).

**6.13 - Overall preference:** State which model wins and why. Must align with the Rating score. Do not let streaming speed affect the choice.

**Rating scale (0-7):**
| Score | Meaning |
|-------|---------|
| 0 | Response A clearly superior |
| 1 | Response A significantly better |
| 2 | Response A better overall |
| 3 | Effectively equivalent (lean A) |
| 4 | Effectively equivalent (lean B) |
| 5 | Response B better overall |
| 6 | Response B significantly better |
| 7 | Response B clearly superior |

**Language must match score magnitude:**
- 0/7: "fails", "broken", "incorrect"
- 1/6: "substantially better", "missing key coverage"
- 2/5: "better structured", "tighter scope"
- 3/4: "minor differences only", "functionally equivalent"

## Validation Checklist (Run Before Output)

**ALL items must pass. If any fails, fix the output before presenting.**

### Rating Consistency
- [ ] Overall score (0-7) reflects relative difference between A and B (not closeness to ideal)
- [ ] Justification language matches score magnitude
- [ ] Key-axis field filled if score is 0, 1, 2, 5, 6, or 7 (non-equivalent)
- [ ] Each axis (6.1-6.13) has its own score (0-7)
- [ ] All axis scores truthfully reflect the actual code differences — do not force artificial variation; if both models produce equivalent code for a given axis, score it 4 (equivalent, lean B)
- [ ] Overall score aligns with majority of axis scores

### Evidence Quality
- [ ] All strengths are evaluative (explain WHY, not just WHAT)
- [ ] All weaknesses cite evidence from diffs or traces
- [ ] All 13 axis questions answered with specifics for both A and B
- [ ] Diffs reviewed (git status + git diff + untracked files read)
- [ ] Model traces reviewed (tmux capture)

### Internal Consistency
- [ ] No contradictions between strengths/weaknesses and rating
- [ ] Strengths/weaknesses align with axis question answers
- [ ] Rating aligns with majority of axis answers
- [ ] Model A sections do NOT mention or compare to Model B (and vice versa) - cross-model comparison only in axis questions and justification

### Prompt Quality (next turn)
- [ ] Identifies a real problem or gap (names area: file, function, behavior, error condition)
- [ ] Describes what success looks like without dictating step-by-step implementation
- [ ] Not over-prescriptive (no micromanaging every step - describe problem + done state, let model decide how)
- [ ] Drives real code change (not just "verify" or "review")
- [ ] No repetition of previous turn prompts
- [ ] No contradiction with previous turns
- [ ] Related to original task scope (phased implementation OK)
- [ ] Min 3 turns enforced before allowing no next prompt
- [ ] **Production-ready gate:** Only stop generating next-turn prompts when the winner's code is production-ready (all PR requirements met, no obvious gaps, tests cover the changes). If another turn could meaningfully improve the output toward production quality, you MUST generate a next prompt - even beyond 3 turns. Stopping early when real issues remain will cause rejection

### Anti-Hallucination
- [ ] Did NOT credit model for code it didn't write (verified in diff)
- [ ] Did NOT penalize model for something its code actually handles
- [ ] Claims about "missing X" verified absent in actual code changes
- [ ] No mention of PR in output (PR is internal context only)

## Turn Prompt Generation (V3 Rules)

Generate next turn prompt following these rules:

**Allowed:**
- Phased implementation: Turn 1 doesn't need full scope. Core logic first, then edge cases, tests, secondary features in later turns - as long as each turn advances concretely
- Category drift (Discussion -> Code Review is fine across turns)
- Open-ended prompts - as long as acceptance criteria clearly describes expected behavior, signals for judging correctness, and what counts as incomplete. Open-ended ≠ lazy; it should be challengingly open, not vague because the author wasn't sure what they wanted
- Pointing to specific issues from current output

**Not allowed:**
- Repeating content from previous turns
- Requirements unrelated to original task
- Contradicting previous turns
- **Over-prescriptive prompts (REJECTION REASON):** Do NOT micromanage every implementation step. Target roughly 6-8 hours of competent engineer work. Describe the problem and what success looks like - leave space for the model to figure out how. Step-by-step instructions dictating "first do X in file Y, then modify Z in function W" will be rejected

**BANNED prompt patterns (non-meaningful follow-ups):**
These are vague, verify-only prompts that don't drive real code changes. NEVER generate prompts like these:
- "Please double check that all changes were applied correctly and run any necessary tests."
- "Review the implementation and fix anything that might be wrong."
- "Ensure everything is production ready and make changes only if needed."
- "Check for any remaining bugs or improvements."
- "Verify the code works as expected."
- "Make sure tests pass and clean up if needed."
- Any prompt that says "check", "review", "ensure", "verify", "double check" without naming a specific file, function, or behavior.

**The sweet spot - meaningful but not over-prescriptive:**
A good prompt identifies a real problem or gap and describes what the fix should achieve, without dictating every step. It names the area of concern (file, function, behavior, error condition) but lets the model decide the implementation approach.

**Bad vs Good examples:**
- BAD (vague): "Fix any remaining edge cases in error handling."
- BAD (over-prescriptive): "Open `auto_factory.py`, go to line 42, change the `except ImportError` to `except (ImportError, ModuleNotFoundError)`, then add a log statement using `logger.error()` with format string `f'Failed to load {module_path}'`, then add a test in `test_factory.py` that mocks importlib.import_module to raise ImportError."
- GOOD: "The `_load_class` fallback in `auto_factory.py` silently returns None on import errors instead of raising. Add a ValueError with the failed module path so misconfiguration surfaces immediately."
- BAD (vague): "Review and improve test coverage."
- GOOD: "`test_dispatch.py` doesn't cover the case where `engine_type` is an empty string - that path silently falls through to the default engine without warning. Cover it."
- BAD (vague): "Make sure the implementation handles all scenarios."
- GOOD: "The retry logic in `client.py:fetch_with_retry` caps at 3 attempts but never resets the backoff timer between independent requests. After the first retry sequence, subsequent calls start with the max delay."

**Requirements:**
- Must identify a real problem or gap: name the area (file, function, behavior, error condition)
- Must describe what success looks like (not step-by-step how to get there)
- Verifiable prompts encouraged but not mandatory - acceptance criteria must still be clear enough that multiple senior engineers would agree on what's being asked
- Min 3 turns total before allowing completion
- Write as a dev talking to AI, no markdown structure, no numbered lists

**Production-ready stop condition (CRITICAL):**
The min-3-turns rule is a floor, not a ceiling. You may ONLY stop generating next-turn prompts when the winner's code is production-ready - meaning all requirements from the original Turn 1 prompt are met, no obvious gaps remain, tests cover the changes, and no real issues were identified during evaluation that another turn could fix. If the evaluation found genuine weaknesses in the winner's code that a follow-up turn could address, you MUST generate a next prompt regardless of turn count. Stopping early when the output isn't production-ready will cause the submission to be rejected. Check the winner's code against the PR requirements (internal reference) before deciding to stop.

## Winner Copy

After evaluation, the client's system auto copy winner's code to both worktrees (YOU MUST NOT COPY):

1. Determine winner from score:
   - 0/1/2 = A wins
   - 5/6/7 = B wins
   - 3/4 = B wins (by convention)

2. Update eval-state.json - append turn result:
```json
{
  "turn": <N>,
  "score": <0-7>,
  "key_axis": "<axis or empty>",
  "winner": "<A or B>",
  "prompt_used": "<prompt text>",
  "next_prompt": "<generated prompt for next turn>",
  "senior_expectations": "<expectations text>",
  "a_strengths_summary": "<brief>",
  "b_strengths_summary": "<brief>",
  "a_weaknesses_summary": "<brief>",
  "b_weaknesses_summary": "<brief>"
}
```

3. Increment `current_turn` in state.

## Output

Use the output template from `~/.claude/skills/eval/templates/output.md`.

**Output to file (MANDATORY):** After evaluation is complete and QA passes, spawn a `general-purpose` sub-agent to write the final output to `./turn-<N>-output.md` in the current working directory, where `<N>` is the current turn number.

**Sub-agent prompt template:**
```
Write the following eval output to file: ./turn-<N>-output.md

<eval-output>
{complete eval output text}
</eval-output>

Instructions:
1. Use Write tool to create/overwrite the file
2. Report back with file path when done
3. Do NOT print the content to console
```

**DO NOT print eval output to console.** The main session should only report:
- File path where output was written
- Brief summary: "Turn N evaluation written to {path}"

This keeps the console clean and makes outputs easily accessible for review.

## Post-Processing: Anti-LLM Rewrite

After generating the full evaluation output, run a rewrite pass using the `rewrite-human` skill rules (defined in `reference/human-rewrite.md` inside this skill directory). This pass rewrites the eval text to eliminate LLM-detectable patterns while preserving 100% of technical facts, file names, function names, ratings, and data.

**Rewrite scope:** All prose sections - senior expectations, solution quality, agent behavior, communication (both models), axis answers (6.1-6.13), justification, next turn prompt. Do NOT rewrite the ratings table, choice line, or key-axis line.

**Rewrite rules (from rewrite-human.md):**
1. Kill template openers/closers ("Overall", "In summary", "It's worth noting", "Certainly")
2. Drop hedging ("slightly", "somewhat", "potentially", "arguably", "it seems")
3. Break parallel structure - mix short/long sentences, fragments, dash clauses
4. Replace abstract nouns with concrete language ("reviewability" -> "easier to review")
5. Use casual connectors ("also", "plus", "though", "but") not formal ones ("furthermore", "additionally")
6. Add light texture/opinion ("annoying but works", "overkill", "the real fix is...")
7. Don't over-structure - emphasize what matters, skip or skim the rest
8. Use contractions and fragments ("doesn't", "won't")
9. Kill "which is" / "that is" chains - split or use dashes
10. No balanced sandwich - state winner first, mention loser briefly
11. Kill summary-fragment codas at the end of paragraphs ("Total: 6 new tests. Clean diff.", "173 lines, 18 methods.", "Result: passing.") - a real person just stops when the point is made, they don't append a stat-line recap. If a number matters, weave it into a sentence earlier
12. Kill inventory/counting sentences that just list stats without analysis ("21 tests across 5 classes covering 3 factories") - either explain why the count matters or drop it
13. Kill Unicode arrows and special glyphs - humans type ASCII on keyboards, not Unicode. Replace `→` `←` `⇒` with `->`, `<-`, `=>`. Replace `…` with `...`, curly quotes `" " ' '` with straight `" '`, em dash `—` with hyphen `-` or comma, en dash `–` with hyphen `-`. This applies especially to naming maps (`Foo -> Bar` not `Foo → Bar`), file renames (`a.py -> b.py`), and before/after pairs. Arrow glyphs are one of the strongest LLM tells in code-review prose

**How it works:** After the eval output is fully generated, spawn a `general-purpose` sub-agent with the complete eval text and the 10 rewrite rules. The sub-agent rewrites all prose sections and returns the final text. Output the rewritten version as the final eval result.

## Post-Eval QA Check (MANDATORY)

After generating the eval output (post-rewrite), spawn a `code-reviewer` sub-agent to audit the output against all eval rules. This is a gate — output is NOT presented to the user until QA passes.

**Sub-agent receives:**
1. The complete eval output text
2. The validation checklist from this SKILL.md
3. The banned prompt patterns list
4. The rating scale reference

**Sub-agent checks (all must pass):**

### Score Consistency
- Score (0-7) matches the justification language magnitude
- Key-axis filled for non-equivalent scores (0, 1, 2, 5, 6, or 7)
- No contradictions between pros/cons and score

### Evidence Quality
- Every strength explains WHY, not just WHAT
- Every weakness cites a specific file, function, or behavior
- All 13 axis questions answered with specifics for both A and B
- No axis answer is just "both are similar" without evidence

### Anti-Hallucination
- No credit given for code the model didn't write (check against diffs described)
- No penalty for something the code actually handles
- "Missing X" claims are consistent with described diffs
- No PR mentioned anywhere in output

### Prompt Quality
- Next turn prompt identifies a real problem or gap (names area: file, function, behavior, error condition)
- Next turn prompt describes what success looks like without dictating step-by-step implementation
- Next turn prompt is NOT over-prescriptive (no micromanaging every step - if it reads like a numbered TODO list of exact changes, it's too prescriptive)
- Next turn prompt requests a change that produces a diff (not just "look at" or "think about")
- Next turn prompt does NOT match any banned pattern (no vague "check/review/ensure/verify")
- Next turn prompt doesn't repeat previous turns
- **If no next prompt (final turn):** verify winner's code is production-ready against all original requirements. If any real gap exists that another turn could fix, this is a FAIL - a next prompt must be generated

### Writing Style
- No bullet-point walls (max 3 in a row)
- Strengths/weaknesses are prose paragraphs, not lists
- No formulaic openers ("I noticed", "It seems", "Let me")
- No cheerleading ("Great progress!", "Well done")
- Varied sentence structure (not parallel across sections)
- No Unicode typographic tells: em dash (—), en dash (–), Unicode arrows (→ ← ⇒), ellipsis (…), curly quotes (" " ' '). Use ASCII equivalents (- -> ... " ') - humans type on keyboards. Naming maps and file renames especially must use `->` not `→`

**Sub-agent response format:**

If ALL checks pass:
```
QA: PASS
```

If ANY check fails:
```
QA: FAIL
Violations:
- [section]: [specific violation and what needs to change]
- [section]: [specific violation and what needs to change]
```

**Main session action on FAIL:** Re-evaluate the flagged sections only (don't redo the entire eval). Fix each violation, then re-run QA. Max 2 retries — if still failing after 2 fixes, present output with a warning note about remaining issues.

**On QA PASS:** Proceed to spawn the output writer sub-agent (see `## Output` section above). The sub-agent writes the final eval to `./turn-<N>-output.md` in the current working directory. Main session reports only the file path and brief confirmation — no console dump of eval content.

## Multi-turn Summary (Final Turn Only)

When ending evaluation (after 3+ turns), append summary:

```
## Multi-turn Summary

| Turn | Score | Key Axis | Key Issue |
|------|-------|----------|-----------|
| 1 | 5 | correctness | B handled edge case A missed |
| 2 | 1 | test coverage | A added comprehensive tests |
| 3 | 5 | error handling | B added graceful fallbacks |
```

## PR Reference Rules

**PR is internal context only.** Never mention PR in:
- Turn prompts (any turn)
- Strengths/weaknesses analysis
- Justification
- Axis question answers
- Next turn prompts

PR is used for:
1. Extract requirements (Turn 1)
2. Evaluate effectiveness (internal comparison)
3. Identify gaps (model output vs PR = weaknesses)
4. Guide follow-up prompts (fix gaps without mentioning PR)

## Writing Style (CRITICAL - Anti-LLM Detection)

The entire evaluation output must read like a senior engineer wrote it by hand. Not a report generator. Not an AI summary. A real person who read the code and has opinions.

### Voice and Tone
Write in continuous prose. Vary sentence length. Short sentence when making a point. Longer when connecting ideas or walking through reasoning. Use the kind of language you would use in a Slack thread with a colleague - direct, opinionated, technically precise but not robotic.

### Forbidden Patterns
- Bullet-point walls: never use more than 3 bullets in a row, and prefer prose paragraphs instead
- Enumerated lists for analysis (strengths, weaknesses, axis answers): always write these as flowing paragraphs
- Formulaic openers: "I noticed that...", "It seems like...", "You might want to...", "Let me..."
- Cheerleading: "Great progress!", "Fixed all issues from Turn N", "Well done"
- Priority labels: HIGH/MEDIUM/LOW
- Trailing fillers: "etc", "etc.", "and so on", "and more"
- Typographic tells: em dash (—), double dash (--), use hyphen (-) instead; Unicode arrows (→ ← ⇒) use ASCII (-> <- =>) instead; ellipsis (…) use three dots (...); curly quotes (" " ' ') use straight (" '); excessive bold/italic
- Parallel structure across every point (varying structure is what makes writing feel human)
- Starting consecutive sentences with the same word
- Table-heavy formatting for analysis text (tables OK for ratings, not for reasoning)
- Summary fragments at the end of paragraphs: "Total: 6 new tests. Clean diff.", "3 files changed. Done.", "Result: passing." — these read like an LLM wrapping up a thought with a tidy bow. A real person just stops writing when the point is made, they don't append a stat-line coda
- Counting/inventory sentences: "21 tests across 5 classes", "173 lines total, 18 test methods" — weave numbers into the narrative if they matter, don't itemize them as standalone fragments

### Required Patterns
- Direct statements: "This is wrong because...", "The fallback logic breaks when...", "A handles this correctly by..."
- Weave evidence into sentences naturally: "A's `_load_class` raises a clear ValueError on bad paths, which makes misconfiguration debugging easier" rather than listing "Strength: malformed path validation" as a bullet
- Transition between ideas with reasoning, not headers or bullets
- Reference specific code (function names, file names, behaviors) inline within prose
- Opinions with backing: state what you think and why, don't hedge with "it could be argued that"

### Structure Guidance
- Every section is a single continuous paragraph (no line breaks within it). A senior dev writing quick eval notes doesn't split thoughts into multiple paragraphs or add line breaks mid-section.
- Max 8 sentences per section. Be concise - hit the key points and move on.
- Senior expectations: 1 paragraph, not a checklist
- Solution quality: 1 paragraph per model, max 8 sentences, no bullet lists
- Agency: 1 paragraph per model, max 8 sentences, with transcript citations
- Communication: 1 paragraph per model, max 8 sentences, with transcript citations
- Axis answers (6.1-6.13): each answer is 2-4 sentences of prose, not a bullet per model
- Overall justification: natural paragraph, reads like a code review summary
- Next turn prompt: conversational, like talking to a teammate

### Self-Check Before Output
Read your evaluation aloud. If it sounds like a structured report template with slots filled in, rewrite it. If it sounds like something a tired but sharp engineer would type at 11pm after reading both diffs carefully, ship it.

**Final gate:** After self-check passes, apply the Post-Processing Anti-LLM Rewrite (see section above) before presenting the output. The rewrite pass is mandatory - no eval output should be presented without it.
