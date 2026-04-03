# Prompt Category

{category1}, {category2}.

# Repo Definition

{Paragraph 1: What the repo/project does overall. 2-3 sentences about the project's purpose and architecture.}

{Paragraph 2: Which specific areas - files, modules, directories - are relevant to this task. Name actual file paths and modules. 700-900 chars total for both paragraphs.}

# PR Definition

{Paragraph 1: The problem. What was wrong, slow, broken, or missing before this PR. Be specific about the behavior and its impact.}

{Paragraph 2: The solution. What the PR does to fix it - the approach, the key changes, the net effect. Don't list every file changed, describe the strategy. 700-900 chars total.}

# Edge Cases

{Specific edge cases visible in the diff. Reference file:function where applicable. Focus on things that could go wrong, be missed, or need special handling. 300-400 chars.}

# Acceptance Criteria

{Write as testable gates: "A correct implementation should..." / "A reviewer would know it's correct if..." / "It would be incomplete if..." / "It would be incorrect if..." 200-400 chars.}

# Initial Prompt

{Flowing prose, 1000-1500 chars. NO headers, NO bullets. Self-contained instructions for a coding agent. Specify WHERE (files/functions), HOW (approach), and WHAT to test. A model reading only this section should be able to implement the full change without seeing anything else.}
