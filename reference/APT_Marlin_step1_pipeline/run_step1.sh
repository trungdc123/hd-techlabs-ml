#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <task_id> <pr_url>"
  echo "Example: $0 312 https://github.com/sympy/sympy/pull/366"
  exit 1
fi

TASK_ID="$1"
PR_URL="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/fetch_pr_diff.sh" "$TASK_ID" "$PR_URL" >/dev/null
python3 "${SCRIPT_DIR}/build_step1_bundle.py" "$TASK_ID" "$PR_URL" >/dev/null

if [[ ! "$PR_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)/?$ ]]; then
  echo "Invalid PR URL: $PR_URL"
  exit 1
fi

OWNER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"
PR="${BASH_REMATCH[3]}"

OUT="output/${TASK_ID}_${OWNER}_${REPO}_${PR}/step1_input.md"

echo "Generated:"
echo "  ${OUT}"
echo

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$OUT"
  echo "Copied step1_input.md to clipboard with pbcopy."
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$OUT"
  echo "Copied step1_input.md to clipboard with xclip."
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$OUT"
  echo "Copied step1_input.md to clipboard with wl-copy."
else
  echo "No clipboard tool found. Open the file and copy it manually."
fi