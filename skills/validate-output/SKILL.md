---
name: validate-output
description: Run 38-check validation against HFI output text. Use before submitting any evaluation, prompt, or finalization.
user-invocable: true
disable-model-invocation: false
argument-hint: <file_path_or_text>
requires:
  - text to validate (file path or pasted text)
produces:
  - validation report with pass/fail per check
calls: []
---

# Validate Output - 38-Check Anti-Rejection System

Run quality checks against HFI output text. Reports violations by severity.

## Input

Accept from one of (priority order):
1. File path via $ARGUMENTS (reads the file)
2. Text selected in IDE
3. Text pasted in chat

Also accept optional context: what produced this text (evaluation, prompt, finalization).

## Output Format

```
### Validation Report

**Result**: PASS / FAIL (N blocking issues)

#### P0 - BLOCKING (must fix before submit)
- [x] Check 1: Em dashes - PASS
- [ ] Check 2: AI buzzwords EN - FAIL: found "robust" in line 14, "comprehensive" in line 27
...

#### P1 - WARNING (should fix)
...

#### P2 - INFO (consider fixing)
...

### Fix Suggestions
- Line 14: "robust error handling" -> "solid error handling"
- Line 27: "comprehensive test suite" -> "thorough test suite"
```

## Checks by Severity

### P0 - BLOCKING (instant reject if failed)

1. **Em dashes**: Scan for "-" (U+2014). BLOCK if found. Fix: replace with hyphen or comma.

2. **AI buzzwords EN** (25 words): robust, comprehensive, leverage, streamline, utilize, facilitate, enhance, optimal, seamless, cutting-edge, holistic, paradigm, innovative, transformative, pivotal, delve, commendable, noteworthy, meticulous, intricate, crucial, essential, fundamental, harness, underscore. BLOCK if any found.

3. **AI buzzwords VI** (14 words): vuot xa, toan dien, tuyet doi, toi uu, trong yeu, noi bat, dac sac, xuat sac, an tuong, vuot troi, quan trong hang dau, dang chu y, dang ghi nhan, bat buoc. BLOCK if any found.

4. **Rating <-> winner consistency** (evaluations only): Count axes favoring A (0-3) vs B (5-7). Majority MUST match stated winner in Section 1. BLOCK if mismatch.

5. **Justification length**: Must be 3-20 sentences. BLOCK if outside range.

6. **Code references**: Must contain >= 2 specific file:function references (e.g., "retry_handler() in api_client.py"). BLOCK if fewer.

7. **No PR references**: Must NOT mention "PR", "#1234", "pull request", or link to GitHub PR. BLOCK if found.

8. **Both models have cons** (evaluations only): Section 4 (A weaknesses) and Section 6 (B weaknesses) must both be non-empty. BLOCK if either empty.

9. **Pros/cons different A vs B** (evaluations only): Sections 3-4 and 5-6 must not be copy-pasted. Check similarity < 0.8. BLOCK if too similar.

10. **Turn count >= 3** (finalization only): Must reference at least 3 turns. BLOCK if fewer.

11. **Prompt not redundant** (prompts only): Compare against all prior turn prompts. Similarity < 0.6 with each. BLOCK if too similar to any prior prompt.

12. **Prompt items not already done**: Each requirement in the prompt must address something NOT already completed in prior turns. BLOCK if repeating done work.

13. **Rating-justification alignment**: Justification text must reference the same direction as the ratings. BLOCK if contradictory.

14. **Curly quotes**: Scan for curly/"smart" quotes. BLOCK if found.

15. **Sycophantic tone** (11 patterns): "You're absolutely right!", "That's an excellent point!", "Great question!", "Certainly!", "Absolutely!", "I'd be happy to", "That's a great observation", "You make an excellent point", "I couldn't agree more", "What a thoughtful", "I appreciate your". BLOCK if found.

### P1 - WARNING (should fix, may trigger rejection)

16. **Markdown in evaluation**: No **bold**, `code`, ## headers in evaluation text body. WARN.

17. **Extreme ratings**: Ratings 0-1 or 6-7 without bug evidence. WARN.

18. **Non-symmetric structure**: If A has exactly same number of pros/cons as B, that's suspicious. WARN.

19. **Scope within issue**: Check prompt keywords against original issue keywords. Overlap should be >= 0.3. WARN if low.

20. **Production-ready coverage**: Should cover >= 3 of 5 dimensions (functionality, security, performance, maintainability, testing). WARN if fewer.

21. **No artificial turn splitting**: Each turn should have real code changes, not just splitting one change across turns. WARN.

### P2 - INFO (AI pattern signals, fix if clustered)

22. **AI transition phrases**: Moreover, Furthermore, Additionally, In conclusion, Consequently, Nevertheless, etc. INFO.

23. **AI hedging phrases**: "It's worth noting", "It should be noted", "As such", etc. INFO.

24. **Sentence uniformity**: If all sentences roughly same length (low stdev), that's AI-like. INFO.

25. **Repetitive starters**: 3+ sentences starting with same word. INFO.

26. **Significance inflation**: "landscape", "journey", "testament to", "game-changer", etc. INFO.

27. **-ing tacking**: "highlighting...", "underscoring...", "emphasizing...", etc. INFO.

28. **Copula avoidance**: Clustering of "serves as", "stands as", "represents". INFO.

29. **Negative parallelisms**: "Not only... but..." patterns. INFO.

30. **Rule-of-three overuse**: Always exactly 3 items. INFO.

31. **Filler phrases**: "In order to achieve this goal", "Due to the fact that", etc. INFO.

32. **Generic conclusions**: "The future looks bright", "Exciting times lie ahead", "Only time will tell". INFO.

33. **Weasel words**: "some experts say", "it has been suggested", "people believe". INFO.

34. **Vocabulary diversity**: TTR (type-token ratio) < 0.45 suggests AI repetition. INFO.

35. **Burstiness**: If max/min sentence length ratio < 2.0, text is too uniform. INFO.

36. **Diff file integrity** (multi-turn): Files present in turn N should still exist in turn N+1 unless explicitly removed. INFO.

37. **Tier 1 red flags**: delve, landscape (metaphorical), tapestry, paradigm shift, leverage (verb), harness, navigate (metaphorical), realm, embark, myriad, plethora, multifaceted, groundbreaking, revolutionize, synergy, ecosystem (non-tech), resonate, streamline. INFO.

38. **Tier 2 clustering**: 3+ Tier 2 words in one section: robust, seamless, cutting-edge, innovative, comprehensive, pivotal, nuanced, compelling, transformative, bolster, underscore, evolving, fostering, imperative, intricate, overarching, unprecedented. INFO.

## How to Run

### Layer 1: Deterministic Checks (38 checks above)
1. Read the input text
2. Run ALL P0 checks first. Report any blockers.
3. Run P1 checks. Report warnings.
4. Run P2 checks. Report info items.

### Layer 2: 8-Pass Humanization Audit
After deterministic checks, run the style audit (see style_guide.md):
- Pass 1: Structure tells (formulaic sections?)
- Pass 2: Significance inflation
- Pass 3: AI vocabulary (Tier 1 + Tier 2 clusters)
- Pass 4: Grammar patterns (-ing tacking, rule-of-three, synonym cycling, copula avoidance)
- Pass 5: Rhythm/style (sentence length variation, burstiness)
- Pass 6: Hedging/filler count (5+ = AI fingerprint)
- Pass 7: Connective tissue (overused transitions)
- Pass 8: Human texture (opinions, voice, varied rhythm)

Score: 0-100 humanness score. Below 40 = WARN. Below 20 = BLOCK.

### Layer 3: Originality Check
If the text is from a CTV who received AI suggestions:
- Compare against AI suggestion. If > 80% similar (copy-paste), BLOCK.
- Penalize tone score heavily if text is a lightly edited AI draft.

### Output
For each failure, provide a specific fix suggestion with line reference.

If all P0 checks pass AND humanness >= 40: output "PASS".
If any P0 check fails OR humanness < 20: output "FAIL" with violations and fixes.
Otherwise: output "PASS WITH WARNINGS".

### Verification Principle
NO completion claims without fresh evidence. If you say "all checks pass", you must have actually scanned the text. Don't skip checks because the text "looks fine."

### V3: Marlin-Submission-Checker-V3 (Additional)
In addition to this validate-output skill, V3 has Marlin-Submission-Checker-V3 on Snorkel platform:
- Scratchpad project - nothing is submitted through it
- Checks: justification vs SxS mismatch, ratings missing explanation, PR reference in prompt, redundant follow-up prompts
- Optional but recommended before final submission
- After output passes validate-output skill, copy into Submission Checker to double-check
