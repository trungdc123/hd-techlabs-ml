#!/usr/bin/env bash
set -euo pipefail

# Creates a workspace directory for a new Marlin HFI task
# Usage: init_task.sh <task_id> <pr_url>
# Example: init_task.sh 329 https://github.com/PrefectHQ/prefect/pull/13620

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <task_id> <pr_url>"
  echo "Example: $0 329 https://github.com/PrefectHQ/prefect/pull/13620"
  exit 1
fi

TASK_ID="$1"
PR_URL="$2"

if [[ ! "$PR_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)/?$ ]]; then
  echo "Invalid PR URL: $PR_URL"
  echo "Expected format: https://github.com/<owner>/<repo>/pull/<number>"
  exit 1
fi

OWNER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"
PR="${BASH_REMATCH[3]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE="${PROJECT_DIR}/workspace/${TASK_ID}_${OWNER}_${REPO}_${PR}"

if [[ -d "$WORKSPACE" ]]; then
  echo "Workspace already exists: $WORKSPACE"
  echo "Delete it first if you want to start fresh."
  exit 1
fi

mkdir -p "$WORKSPACE"

# Create meta.json
cat > "${WORKSPACE}/meta.json" <<EOF
{
  "task_id": ${TASK_ID},
  "pr_url": "${PR_URL}",
  "owner": "${OWNER}",
  "repo": "${REPO}",
  "pr_number": ${PR},
  "difficulty": null,
  "categories": [],
  "current_turn": 0,
  "status": "initialized",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "worktree_a": null,
  "worktree_b": null
}
EOF

echo "Workspace created: $WORKSPACE"
echo "Next steps:"
echo "  1. Run: bash scripts/fetch_pr_diff.sh $TASK_ID $PR_URL"
echo "  2. Run task-submit skill to generate step1_spec.md"
