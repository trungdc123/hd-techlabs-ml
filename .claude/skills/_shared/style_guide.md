# Writing Style Guide - Anti-AI Detection

## Core Principle

Write like a developer talking to a colleague. Direct, casual, specific. Not a press release, not a Wikipedia article.

## Allowed Natural Dev Speech

These are OK and make text sound human:
- "basically", "pretty much", "kind of", "stuff like that"
- "probably", "I think", "not 100% sure"
- Contractions: "doesn't", "won't", "they're", "it's"
- Start sentences with "And", "But", "So", "Look"
- Fragments: "Clean diff. No junk."
- One hedge per piece is fine. Five is AI.

## Banned Patterns

- NO abbreviations: "etc.", "i.e.", "e.g." - say "and so on", "meaning", "like"
- NO arrows: ->, <-, special Unicode arrows
- NO ellipsis "..."
- NO synonym cycling: "protagonist... main character... central figure" - pick one, stick with it
- NO em dashes. Use hyphens, commas, or periods
- NO curly/smart quotes. Use straight quotes

## 10 Rules

### 1. Kill template openings/closings
DELETE: "Overall", "In summary", "In conclusion", "It's worth noting", "It's important to", "Let's", "Certainly", "Absolutely"
Go straight to the point.

BAD: "Overall B is slightly ahead on test evidence"
GOOD: "B wins - more tests pass, cleaner worktree"

### 2. Drop hedging - say it straight
DELETE: "slightly", "somewhat", "potentially", "arguably", "it seems", "appears to", "could potentially"

BAD: "This can potentially break custom configs"
GOOD: "This breaks custom configs"

### 3. Break parallel structure
Don't start 3+ sentences the same way. Mix: short, long, fragment, dash clause.

BAD: "Refactors X. Adds Y. Extends Z. Implements W."
GOOD: "X got refactored. Also added Y - and Z now extends properly. W was the tricky part."

### 4. Abstract nouns -> concrete
BAD: "reviewability", "maintainability", "confidence", "evidence", "robustness"
GOOD: "easier to review", "8/8 tests pass", "git status clean"

### 5. Casual connectors, not formal
DELETE: "furthermore", "additionally", "consequently", "thus", "hence", "moreover", "specifically"
USE: "also", "plus", "though", "but", "so", "and", dash (-), or just start a new paragraph

### 6. Add texture/opinion (measured)
Humans have feelings: "annoying but works", "nice touch", "overkill", "the real fix is..."
1-2 per section, don't overdo it.

### 7. Don't over-structure
LLM balances pros/cons perfectly. Humans emphasize what matters and skip the rest.

### 8. Contractions + fragments OK
"doesn't" > "does not". "won't" > "will not"
Fragments work: "Clean diff. No junk."

### 9. Kill "which is" chains
BAD: "X, which is Y, which means Z"
GOOD: Split into sentences or use dash.

### 10. No balanced sandwich
BAD: "A does well at X, but B does well at Y, though A also..."
GOOD: State winner first, mention loser briefly.

## Adding Voice

- Have opinions. "I genuinely don't know how to feel about this" beats neutral pros-and-cons.
- Vary rhythm. Short punchy sentences. Then longer ones that take their time.
- Acknowledge complexity. "This works but it's also kind of unsettling."
- Let some mess in. Perfect structure feels algorithmic.
- Be specific about feelings. Not "this is concerning" but "there's something off about agents working at 3am with nobody watching."

## What NOT to Do

- Don't overdo casual voice. One or two asides per section max.
- Don't add slang or try to be hip.
- Don't insert "I" unless context fits.
- Don't add humor that doesn't serve the point.

## 8-Pass Humanization Audit

After drafting, run these 8 passes in order:

**Pass 1 - Structure tells:**
Formulaic sections? Every section same shape? Identical list lengths? Tidy takeaway on every section? If yes, vary the structure.

**Pass 2 - Significance inflation:**
"pivotal moment", "testament to", "landscape", "journey", "game-changer", "stands as", "setting the stage"? If found, replace with specific facts.

**Pass 3 - AI vocabulary:**
Tier 1 words (instant red flags)? Tier 2 clusters (3+ in one piece)? See blocked_words.md.

**Pass 4 - Grammar patterns:**
- Copula avoidance clustering: "serves as"/"stands as"/"represents" appearing 3+ times? Use "is" instead.
- "-ing tacking": "highlighting...", "underscoring...", "emphasizing..." 3+ times? Delete or expand.
- Negative parallelisms: "Not only... but..." more than once per piece?
- Rule-of-three: always exactly 3 items? Break the pattern. Cut padding items.
- Synonym cycling? Pick one word and stick with it.

**Pass 5 - Rhythm/Style:**
All sentences roughly same length? Mix short (5-8 words) with long (20+ words). Check burstiness - if max/min sentence length ratio < 2.0, text is too uniform.

**Pass 6 - Hedging/Filler:**
Count hedges. 5+ = AI fingerprint. Remove vague attributions ("Experts argue", "Industry reports"). Kill chatbot artifacts ("I hope this helps!", "Great question!"). Kill sycophantic tone.

**Pass 7 - Connective tissue:**
Overused transitions (Moreover, Furthermore, Additionally)? Skip entirely or use "because", "so", "but", "and".

**Pass 8 - Human texture (MOST IMPORTANT):**
Signs of soulless writing:
- Every sentence same length and structure
- No opinions, just neutral reporting
- No acknowledgment of uncertainty
- Reads like Wikipedia or press release

Fix by: having opinions, varying rhythm, acknowledging complexity, letting some mess in, being specific about feelings. One or two casual asides per section max.

## Dual-Pass Audit

After all 8 passes: ask "What makes this obviously AI generated?" Fix those tells.
Then read again. This second pass catches patterns the first edit introduced.

## The "Read It Out Loud" Test

Flag anything that:
- Sounds like a press release
- No human would say in conversation
- Makes you cringe slightly
- Feels like it's trying too hard to sound smart
- Could be about any topic by swapping a few nouns

## Progressive Disclosure

Output ALWAYS in this order:
1. SUMMARY: 2-3 sentence verdict (reader reads this first)
2. CONTEXT: Background needed to understand
3. DETAIL: Specific file:function findings with evidence
4. ACTION: What to do next

Anti-parroting: NEVER reformat input as output. SYNTHESIZE multiple signals into insight. Every sentence must add info not in the input.
