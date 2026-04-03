#!/usr/bin/env python3
from pathlib import Path
import re
import sys

if len(sys.argv) != 3:
    print("Usage: build_step1_bundle.py <task_id> <pr_url>")
    sys.exit(1)

task_id, pr_url = sys.argv[1:]

m = re.match(r"^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)/?$", pr_url)
if not m:
    print(f"Invalid PR URL: {pr_url}")
    sys.exit(1)

owner, repo, pr = m.groups()
task_dir = Path("output") / f"{task_id}_{owner}_{repo}_{pr}"
diff_file = task_dir / "pr.diff"
out_file = task_dir / "step1_input.md"

if not diff_file.exists():
    print(f"Missing diff file: {diff_file}")
    sys.exit(1)

diff_text = diff_file.read_text(encoding="utf-8", errors="replace")

MAX_CHARS = 180000
truncated = False
if len(diff_text) > MAX_CHARS:
    diff_text = diff_text[:MAX_CHARS]
    truncated = True

content = f"""Task ID: {task_id}

Git Repo: https://github.com/{owner}/{repo}
Git PR: {pr_url}
PR URL with diff: {pr_url}.diff

Context:
The diff below was fetched locally from the GitHub API using:
Accept: application/vnd.github.v3.diff

This is intended to avoid truncation issues from the browser-facing .diff URL.

Instructions:
Please perform STEP 1 only, following the project master prompt.

Important:
- Base your reasoning strictly on the diff below.
- Do not assume access to the full repository source.
- If the diff is insufficient to determine WHERE or HOW clearly, explicitly say what is still unclear instead of guessing.
- The Turn-1 prompt must be self-contained and must not defer core implementation details to later turns.

Goal:
Produce:
- Repo Definition
- Problem Definition
- Edge Cases
- Acceptance Criteria
- Initial Prompt (Turn 1, fully self-contained)

Self-check before finalizing:
- Can the task be implemented using only this prompt?
- Are WHERE (files/functions) and HOW (strategy) clearly defined?
- Are any requirements implicitly deferred to later turns?

Diff changes:
~~~diff
{diff_text}
~~~
"""

if truncated:
    content += "\n\nNote: The local diff text was truncated to fit the Step 1 input size cap.\n"

out_file.write_text(content, encoding="utf-8")
print(out_file)