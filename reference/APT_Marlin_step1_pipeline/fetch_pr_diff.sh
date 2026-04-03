#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <task_id> <pr_url>"
  echo "Example: $0 312 https://github.com/sympy/sympy/pull/366"
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

OUT_DIR="output/${TASK_ID}_${OWNER}_${REPO}_${PR}"
mkdir -p "$OUT_DIR"

AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

echo "Fetching PR diff for task ${TASK_ID}: ${OWNER}/${REPO}#${PR}..."

curl -fsSL -L \
  -H "Accept: application/vnd.github.v3.diff" \
  "${AUTH_HEADER[@]}" \
  "https://api.github.com/repos/${OWNER}/${REPO}/pulls/${PR}" \
  -o "${OUT_DIR}/pr.diff"

echo "Saved diff to ${OUT_DIR}/pr.diff"