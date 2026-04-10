#!/usr/bin/env bash
set -euo pipefail

# Fetches PR diff from GitHub API and saves to workspace
# Usage: fetch_pr_diff.sh <task_id> <pr_url>

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

if [[ ! -d "$WORKSPACE" ]]; then
  echo "Workspace not found: $WORKSPACE"
  echo "Run init_task.sh first."
  exit 1
fi

AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

echo "Fetching PR diff: ${OWNER}/${REPO}#${PR}..."

curl -fsSL -L \
  -H "Accept: application/vnd.github.v3.diff" \
  ${AUTH_HEADER[@]+"${AUTH_HEADER[@]}"} \
  "https://api.github.com/repos/${OWNER}/${REPO}/pulls/${PR}" \
  -o "${WORKSPACE}/pr.diff"

LINES=$(wc -l < "${WORKSPACE}/pr.diff" | tr -d ' ')
echo "Saved ${LINES} lines to ${WORKSPACE}/pr.diff"
