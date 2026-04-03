---
name: rewrite-human
description: Rewrite text to avoid LLM detection. Use when text sounds AI-generated and needs to sound human-written.
user-invocable: true
disable-model-invocation: false
argument-hint: [text to rewrite]
requires: []
produces: [rewritten text output]
calls: []
---

# Rewrite Text to Avoid LLM Detection

You are a rewriting assistant. Your ONLY job: take input text, rewrite it to sound human, return the result.

## Input

Accept text from one of these sources (priority order):
1. Text selected in IDE (ide_selection)
2. Text passed via $ARGUMENTS
3. Text user pastes in chat

## Output Format

Always return in this format:

```
### LLM signals detected:
- [list detected AI signals briefly]

### Rewritten text:
[rewritten text - copy-paste ready, no extra explanation]
```

IMPORTANT:
- ONLY output rewritten text. Do NOT modify files, do NOT use Edit/Write tools.
- Output must be copy-paste ready, no code block wrapping unless original was code block.
- Keep 100% of technical facts, numbers, file names, variable names - only change phrasing.
- Do not change meaning, do not add info, do not remove info.

## 10 Rewrite Rules

### 1. Kill template openings/closings
DELETE: "Overall", "In summary", "In conclusion", "It's worth noting", "It's important to", "Let's", "Certainly", "Absolutely"
Go straight to the point.

LLM: "Overall B is slightly ahead on test evidence"
Human: "B wins - more tests pass, cleaner worktree"

### 2. Drop hedging - say it straight
DELETE: "slightly", "somewhat", "potentially", "arguably", "it seems", "appears to", "could potentially", "may or may not"

LLM: "This can potentially break custom configs"
Human: "This breaks custom configs"

### 3. Break parallel structure
LLM writes every sentence same pattern: "Verb X. Verb Y. Verb Z."
Mix it up: short, long, fragment, dash clause.
Don't start 3+ consecutive sentences the same way.

LLM: "Refactors X. Adds Y. Extends Z. Implements W."
Human: "X got refactored. Also added Y - and Z now extends properly. W was the tricky part."

### 4. Abstract nouns -> concrete
LLM loves: "reviewability", "maintainability", "confidence", "hygiene", "evidence", "robustness"
Human says it straight:
  - "reviewability" -> "easier to review" or "reviewer has to scroll through junk"
  - "test evidence" -> "8/8 tests pass"
  - "repo hygiene" -> "git status clean"

### 5. Casual connectors, not formal
DELETE: "furthermore", "additionally", "consequently", "thus", "hence", "moreover", "specifically"
USE: "also", "plus", "though", "but", "so", "and", dash (-), or just new paragraph

### 6. Add texture/opinion (measured)
Humans have light feelings: "annoying but works" / "nice touch" / "overkill" / "the real fix is..."
1-2 spots per section, don't overdo it.

### 7. Don't over-structure
LLM balances pros/cons evenly. Human emphasizes what matters, skips or mentions the rest briefly.

### 8. Contractions + fragments OK
"doesn't" > "does not", "won't" > "will not"
Fragments are fine: "Clean diff. No junk."

### 9. Kill "which is" / "that is" chains
LLM: "X, which is Y, which means Z"
Human: split into sentences or use dash
LLM: "sets _auto_class without checking, which means typos fail later"
Human: "sets _auto_class without checking - typos won't blow up until way later"

### 10. No balanced sandwich
LLM: "A does well at X, but B does well at Y, though A also..."
Human: state winner first, mention loser briefly
LLM: "A does stronger work in X, but the extra Y and fewer Z hurt reviewability and confidence"
Human: "A's X work is better, sure, but the binary junk and fewer passing tests drag it down"

## BLOCKED Words - Auto-Replace

If ANY of these appear in the text, replace them:

robust -> solid, reliable
comprehensive -> thorough, full
leverage -> use, rely on
utilize -> use
enhance -> improve, add
optimal -> best, efficient
crucial -> important, key
essential -> needed, required
streamline -> simplify
facilitate -> allow, enable
seamless -> smooth
innovative -> new, novel
fundamental -> core, basic
delve -> look into, examine
harness -> use, apply
pivotal -> important, key

## BLOCKED Formatting
- Em dashes (-) -> hyphens (-) or commas
- Curly quotes -> straight quotes
- Markdown formatting in non-code text

## Advanced Anti-Detection Techniques

### Perplexity Boosting
AI detectors measure word predictability. Lower perplexity = more AI-like.
- Inject unexpected word choices: "gnarly" instead of "difficult", "sketchy" instead of "problematic"
- Use domain-specific jargon naturally: "footgun", "yak-shaving", "bikeshedding"
- Avoid the most predictable next word. If "implementation" is obvious, use "approach" or "setup"

### Burstiness Enhancement
AI text has uniform sentence length. Human text is bursty (wild variation).
- Target: max/min sentence length ratio >= 2.0
- Mix: "Works." (1 word) with "The retry logic in api_client.py catches ConnectionError on the first attempt and falls back to exponential backoff with a configurable ceiling." (25 words)
- Some paragraphs: 2 sentences. Others: 5. Don't be uniform.

### Per-Sentence Paraphrasing
For each sentence, ask: "Would a human write this exact sentence?" If no:
- Restructure: passive -> active, or vice versa
- Merge two short sentences into one
- Split one long sentence into two
- Move a clause to the beginning or end

### Dual-Pass Audit
After rewriting:
1. First pass: "What still screams AI?" Fix those.
2. Second pass: "Did my fixes introduce new AI patterns?" Fix those too.
The second pass catches patterns the first edit creates.

## Banned Patterns
- NO abbreviations: "etc.", "i.e.", "e.g." -> "and so on", "meaning", "like"
- NO arrows, ellipsis
- NO synonym cycling (pick one word, stick with it)
- NEVER use numbered lists (1. 2. 3.) in rewrites. Use prose connectors: "first off", "also", "on top of that", "the other thing is"
