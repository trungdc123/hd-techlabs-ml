#!/bin/bash
# eval-inject.sh - Context injection hook for /eval skill
# Injects: V3 rules, PR requirements, PR cache paths, A/B file list + stat, previous turns, turn1 prompt
# Code diffs NOT injected — Claude reads on-demand via Read tool / git diff commands

# Read stdin (tool call JSON from Claude Code)
INPUT=$(cat)

# Parse JSON using jq if available, fallback to grep
if command -v jq &>/dev/null; then
  SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // .skill // empty' 2>/dev/null)
  ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // .args // empty' 2>/dev/null)
else
  SKILL_NAME=$(echo "$INPUT" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  ARGS=$(echo "$INPUT" | grep -o '"args"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi

# Exit early if not eval skill
if [ "$SKILL_NAME" != "eval" ]; then
  exit 0
fi

# Extract repo from args
REPO=$(echo "$ARGS" | grep -o 'repo=[^ ]*' | head -1 | sed 's/repo=//')

# Validate repo name
if [ -z "$REPO" ]; then
  echo "## Eval Context Injection"
  echo ""
  echo "**ERROR:** repo argument missing. Usage: /eval repo=<name> ..."
  exit 0
fi

if [[ "$REPO" =~ [^a-zA-Z0-9._-] ]]; then
  echo "## Eval Context Injection"
  echo ""
  echo "**ERROR:** Invalid repo name. Use alphanumeric, dots, hyphens, underscores only."
  exit 0
fi

CACHE_DIR="$HOME/.cache/claude-hfi/$REPO"
STATE_FILE="$CACHE_DIR/eval-state.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "## Eval Context Injection"
echo ""

# Block 0: V3 Rules Reference
echo "### V3 Rules"
echo ""
if [ -f "$SKILL_DIR/reference/v3-rules.md" ]; then
  cat "$SKILL_DIR/reference/v3-rules.md"
else
  echo "(v3-rules.md not found)"
fi
echo ""

# Helper: dump code changes for a worktree (file list + stat only, no content)
dump_worktree_changes() {
  local WORKTREE_DIR="$1"
  local LABEL="$2"

  if [ ! -d "$WORKTREE_DIR" ]; then
    echo "### $LABEL - Code Changes"
    echo "(worktree not found: $WORKTREE_DIR)"
    echo ""
    return
  fi

  echo "### $LABEL - Code Changes"
  echo ""

  # File list - unstaged modifications + untracked only (exclude staged, system files)
  echo '```'
  echo "$ git status --short (unstaged + untracked only)"
  (cd "$WORKTREE_DIR" && git status --short 2>/dev/null) \
    | grep -E '^( M|MM|\?\?)' \
    | grep -v 'CLAUDE.md' | grep -v 'claude-hfi'
  echo '```'
  echo ""

  # Per-file change summary (exclude system files)
  local STAT_OUTPUT
  STAT_OUTPUT=$( (cd "$WORKTREE_DIR" && git diff --stat -- ':!CLAUDE.md' ':!*claude-hfi*' 2>/dev/null) )
  if [ -n "$STAT_OUTPUT" ]; then
    echo "**Diff stat:**"
    echo '```'
    echo "$STAT_OUTPUT"
    echo '```'
    echo ""
  fi

  # Untracked files with line counts (metadata only, no content)
  local UNTRACKED
  UNTRACKED=$( (cd "$WORKTREE_DIR" && git status --short 2>/dev/null) \
    | grep '^??' | sed 's/^?? //' \
    | grep -v 'CLAUDE.md' | grep -v 'claude-hfi')
  if [ -n "$UNTRACKED" ]; then
    echo "**New files (untracked):**"
    echo '```'
    echo "$UNTRACKED" | while read -r f; do
      f="${f%/}"  # strip trailing slash from untracked dirs
      local FULL_PATH="$WORKTREE_DIR/$f"
      if [ -f "$FULL_PATH" ]; then
        local LINES
        LINES=$(wc -l < "$FULL_PATH" 2>/dev/null | tr -d ' ')
        echo "  $f ($LINES lines)"
      fi
    done
    echo '```'
    echo ""
  fi

  # Hint for lazy reading
  echo "> To view full diff: \`cd $WORKTREE_DIR && git diff\`"
  echo "> To view specific file: \`cd $WORKTREE_DIR && git diff <file>\`"
  echo "> To read new file: \`Read $WORKTREE_DIR/<path>\`"
  echo ""
}

# Block 1: Turn 1 prompt + PR requirements (from state)
if [ -f "$STATE_FILE" ] && command -v jq &>/dev/null; then
  # Turn 1 prompt - scope reference for all turns
  TURN1_PROMPT=$(jq -r '.turn1_prompt // empty' "$STATE_FILE" 2>/dev/null)
  if [ -n "$TURN1_PROMPT" ]; then
    echo "### Turn 1 Prompt (scope reference)"
    echo ""
    echo "$TURN1_PROMPT"
    echo ""
  fi

  # PR requirements
  REQ_COUNT=$(jq '.pr_requirements // [] | length' "$STATE_FILE" 2>/dev/null)
  if [ "$REQ_COUNT" -gt 0 ] 2>/dev/null; then
    echo "### PR Requirements (cached)"
    echo ""
    jq -r '.pr_requirements // [] | .[]' "$STATE_FILE" 2>/dev/null | while read -r req; do
      echo "- $req"
    done
    echo ""
  fi
fi

# Block 1b: PR diff cache paths
if [ -d "$CACHE_DIR" ]; then
  PR_DIFF_EXISTS=false
  PR_FILES_EXISTS=false
  [ -f "$CACHE_DIR/pr.diff" ] && PR_DIFF_EXISTS=true
  [ -f "$CACHE_DIR/pr-files.txt" ] && PR_FILES_EXISTS=true

  if $PR_DIFF_EXISTS || $PR_FILES_EXISTS; then
    echo "### PR Reference Files"
    echo ""
    $PR_DIFF_EXISTS && echo "- **PR diff:** \`$CACHE_DIR/pr.diff\`"
    $PR_FILES_EXISTS && echo "- **PR file list:** \`$CACHE_DIR/pr-files.txt\`"
    echo ""
    echo "> Read pr.diff for baseline comparison and scope reference."
    echo ""
  fi
fi

# Block 2: A/B Code Changes (file list + stat only, lazy read)
dump_worktree_changes "$CACHE_DIR/A" "Model A"
dump_worktree_changes "$CACHE_DIR/B" "Model B"

# Block 3: Previous turns (full prompt text, no truncation)
if [ -f "$STATE_FILE" ] && command -v jq &>/dev/null; then
  TURN_COUNT=$(jq '.turns | length' "$STATE_FILE" 2>/dev/null)
  if [ "$TURN_COUNT" -gt 0 ] 2>/dev/null; then
    echo "### Previous Turns"
    echo ""
    jq -r '.turns[] | "**Turn \(.turn)** — score: \(.score), winner: \(.winner), key_axis: \(.key_axis // "n/a")\nPrompt used: \(.prompt_used)\nNext prompt: \(.next_prompt)\n"' "$STATE_FILE" 2>/dev/null
    echo ""
  fi
fi
