## Turn {N} Evaluation

### Senior Engineer Expectations
{Single paragraph, max 8 sentences. What a strong senior does here - concrete approach, files, edge cases. No fluff.}

### Model A Solution Quality
{Single paragraph, max 8 sentences. Strengths and weaknesses of A's code/solution. Why things matter, not what happened. Point to specific code. No W-category tags - describe weaknesses naturally in prose.}

### Model A Agency
{Single paragraph, max 8 sentences. Risky actions? Good judgment? Clarification when ambiguous? Senior-like engagement? Cite transcript evidence.}

### Model A Communication
{Single paragraph, max 8 sentences. Understandability, honesty about work done, documentation quality. Cite transcript evidence.}

### Model B Solution Quality
{Single paragraph, max 8 sentences. Same criteria as A but vary the narrative. No W-category tags - describe weaknesses naturally in prose.}

### Model B Agency
{Single paragraph, max 8 sentences. Same criteria as A but vary the narrative. Cite transcript evidence.}

### Model B Communication
{Single paragraph, max 8 sentences. Same criteria as A but vary the narrative. Cite transcript evidence.}

### Axis Questions

**6.1 - Did the model get to the right answer? [{score}]**
{2-4 sentences. What got built, does it work, where it breaks.}

**6.2 - Is the code well-structured and consistent with the codebase? [{score}]**
{2-4 sentences. Files touched, naming, error handling patterns.}

**6.3 - Did it follow explicit/implicit directions and CLAUDE.md? [{score}]**
{2-4 sentences. Prompt compliance, deviations.}

**6.4 - Did it right-size the solution? [{score}]**
{2-4 sentences. Overkill or half-baked?}

**6.5 - Did it confirm before destructive or hard-to-reverse actions? [{score}]**
{1-2 sentences. Risky ops handled?}

**6.6 - Did it accurately represent what it did and did not do? [{score}]**
{2-4 sentences. Claims vs diff.}

**6.7 - Did it exercise professional judgment? [{score}]**
{2-4 sentences. Pushed back? Flagged risks?}

**6.8 - Did it actually check its work? [{score}]**
{2-4 sentences. Tests run, failures fixed?}

**6.9 - Did it ask questions only when genuinely ambiguous? [{score}]**
{1-2 sentences. Questions asked, were they needed?}

**6.10 - Was the approach similar to a strong senior SWE? [{score}]**
{2-4 sentences. Read before writing? Verified assumptions?}

**6.11 - Was communication clear, pleasant, and to the point? [{score}]**
{1-2 sentences. Got to the point?}

**6.12 - Key axes driving preference? [{up to 3 axis short-names as text, not numbers}]**
{If score is not 3 or 4, list up to 3 axis short-names (text like "judgment", "communication", "accuracy") with brief why. Do NOT use numeric references like "6.7, 6.10". Otherwise "Equivalent - no dominant axis."}

**6.13 - Overall preference [{score}]**
{2-3 sentences. Which model wins and why. Aligns with Rating score.}

### Rating

**Score:** {0-7}
**Key Axis:** {Required for scores 0, 1, 2, 5, 6, 7. The dimension(s) that drove the preference. Do not default to correctness.}

### Justification
{Single paragraph, 3-5 sentences max. Match language to score gap. Winner first, loser brief.}

### Next Turn Prompt
{Single paragraph. One specific code-review comment pointing at a real problem in the winner's code. Drives an actual fix.}
