#!/usr/bin/env bash
set -euo pipefail

# Collects diffs and evidence from Model A/B worktrees into turn directory
# Usage: collect_diffs.sh <workspace_path> <turn_number> <worktree_a_path> <worktree_b_path>

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <workspace_path> <turn_number> <worktree_a_path> <worktree_b_path>"
  echo "Example: $0 workspace/329_PrefectHQ_prefect_13620 1 /tmp/worktree_a /tmp/worktree_b"
  exit 1
fi

WORKSPACE="$1"
TURN="$2"
WORKTREE_A="$3"
WORKTREE_B="$4"

TURN_DIR="${WORKSPACE}/turn_${TURN}"
mkdir -p "$TURN_DIR"

echo "Collecting diffs for turn ${TURN}..."

# Collect staged diff from worktree A
if [[ -d "$WORKTREE_A/.git" ]] || [[ -f "$WORKTREE_A/.git" ]]; then
  (cd "$WORKTREE_A" && git diff HEAD) > "${TURN_DIR}/staged_diff_a.patch" 2>/dev/null || true
  (cd "$WORKTREE_A" && git diff --stat HEAD) > "${TURN_DIR}/staged_diff_a_stat.txt" 2>/dev/null || true
  (cd "$WORKTREE_A" && git status --short) > "${TURN_DIR}/changed_files_a.txt" 2>/dev/null || true
  echo "  Model A: $(wc -l < "${TURN_DIR}/staged_diff_a.patch" | tr -d ' ') lines"
else
  echo "  Warning: $WORKTREE_A is not a git repository. Skipping git diff."
  echo "  You can manually place staged_diff_a.patch in ${TURN_DIR}/"
fi

# Collect staged diff from worktree B
if [[ -d "$WORKTREE_B/.git" ]] || [[ -f "$WORKTREE_B/.git" ]]; then
  (cd "$WORKTREE_B" && git diff HEAD) > "${TURN_DIR}/staged_diff_b.patch" 2>/dev/null || true
  (cd "$WORKTREE_B" && git diff --stat HEAD) > "${TURN_DIR}/staged_diff_b_stat.txt" 2>/dev/null || true
  (cd "$WORKTREE_B" && git status --short) > "${TURN_DIR}/changed_files_b.txt" 2>/dev/null || true
  echo "  Model B: $(wc -l < "${TURN_DIR}/staged_diff_b.patch" | tr -d ' ') lines"
else
  echo "  Warning: $WORKTREE_B is not a git repository. Skipping git diff."
  echo "  You can manually place staged_diff_b.patch in ${TURN_DIR}/"
fi

# Generate delta patches (turn 2+)
if [[ "$TURN" -gt 1 ]]; then
  PREV_TURN=$((TURN - 1))
  if [[ -f "${WORKSPACE}/turn_${PREV_TURN}/staged_diff_a.patch" ]]; then
    echo "  Generating delta patches vs turn ${PREV_TURN}..."
  fi
fi

# Create placeholder for prompt if not exists
if [[ ! -f "${TURN_DIR}/prompt.md" ]]; then
  if [[ "$TURN" -eq 1 ]]; then
    # Copy initial prompt from step1_spec if available
    if [[ -f "${WORKSPACE}/step1_spec.md" ]]; then
      # Extract Initial Prompt section
      sed -n '/^# Initial Prompt/,/^#[^#]/p' "${WORKSPACE}/step1_spec.md" | head -n -1 > "${TURN_DIR}/prompt.md" 2>/dev/null || true
    fi
  else
    # Copy next prompt from previous turn
    PREV_PROMPT="${WORKSPACE}/turn_${PREV_TURN}/turn_${PREV_TURN}_next_prompt.md"
    if [[ -f "$PREV_PROMPT" ]]; then
      cp "$PREV_PROMPT" "${TURN_DIR}/prompt.md"
    fi
  fi
fi

# Create placeholder for execution evidence
for SIDE in a b; do
  EVIDENCE="${TURN_DIR}/execution_evidence_${SIDE}.md"
  if [[ ! -f "$EVIDENCE" ]]; then
    cat > "$EVIDENCE" <<EOF
# Execution Evidence - Model $(echo "$SIDE" | tr '[:lower:]' '[:upper:]')

## Test Results
[Paste test output here]

## Build Output
[Paste build output here]

## Runtime
[Record execution time]
EOF
  fi
done

echo "Turn ${TURN} artifacts ready in ${TURN_DIR}/"
echo "Next: Fill in execution_evidence_a.md and execution_evidence_b.md, then run checkpoint-review"
