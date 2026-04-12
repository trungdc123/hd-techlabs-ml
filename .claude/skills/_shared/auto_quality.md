# Auto Quality Gate - Validate + Rewrite Before Output

REQUIRED rule for ALL skills that produce text output:

## Pipeline

Before writing the final output file, you MUST run these 3 steps in order:

### Step 1: Auto-Validate (P0 checks)

Scan output for P0 violations:
- Blocked words (25 EN + 14 VI)? -> Auto-replace using word replacement table
- Em dashes? -> Auto-replace with hyphen or comma
- Curly quotes? -> Auto-replace with straight quotes
- Missing code refs (< 2)? -> Add from diffs
- Rating inconsistency? -> Fix or flag

If P0 violation found: FIX IMMEDIATELY, do not ask CTV.

### Step 2: Auto-Rewrite (anti-AI)

Scan output through 8-pass humanization:
1. Structure tells -> break formulaic patterns
2. Significance inflation -> replace with specific facts
3. AI vocabulary -> replace with common words
4. Grammar patterns -> break -ing tacking, rule-of-three
5. Rhythm -> mix short/long sentences
6. Hedging/filler -> cut (keep max 1 hedge)
7. Connective tissue -> remove AI transitions
8. Human texture -> add 1-2 opinions/asides

If AI pattern detected: REWRITE that sentence only, not the entire text.

### Step 3: Final Check

Re-read output after fixes:
- Still technically accurate? (rewrite must not change meaning)
- All code refs still correct?
- No info added or removed?

### Circuit Breaker

Max 2 validate-rewrite loops. If still P0 violations after 2 rounds, output with warning:
```
[AUTO-QUALITY WARNING: N violations remain unfixed. Run /validate-output for details.]
```

## When NOT to auto-rewrite

- Code blocks, file paths, function names: NEVER rewrite
- Numbers, statistics: keep as-is
- Model names (Model A, Model B): keep as-is
- Rating values: keep as-is
