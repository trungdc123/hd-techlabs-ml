# Step 1 Pipeline

## Purpose

Step 1 is used to prepare a clean, reviewable task specification before local model evaluation.

At this stage, we only use the PR-level information already available for the task, then generate a Step 1 bundle for ChatGPT Project.

The expected output of Step 1 is:
- Repo Definition
- Problem Definition
- Edge Cases
- Acceptance Criteria
- Initial Prompt

This output is then used as the contract for Step 2.

---

## Inputs

The pipeline takes:
- `task_id`
- `pr_url`

Where:
- `task_id` is the internal task number of the task
- `pr_url` is the GitHub pull request URL

Example:
```bash
./run_step1.sh 312 https://github.com/sympy/sympy/pull/366
```

In this example:
- `312` is the task ID
- `https://github.com/sympy/sympy/pull/366` is the PR URL

If the task is labeled as **Task 312**, then the `task_id` is simply:
```text
312
```

---

## Output

Running the pipeline will generate:
- `pr.diff`
- `step1_input.md`

Example output folder:
```text
output/312_sympy_sympy_366/
```

---

## How to use

1. Find the internal task number and the PR URL for the task

Example:
- Task ID: `312`
- PR URL: `https://github.com/sympy/sympy/pull/366`

2. Run the Step 1 pipeline

```bash
./run_step1.sh 312 https://github.com/sympy/sympy/pull/366
```

3. Open the generated `step1_input.md`

Example:
```text
output/312_sympy_sympy_366/step1_input.md
```

4. Copy the full content of `step1_input.md` into ChatGPT Project

5. Ask ChatGPT to perform Step 1

6. Save the response as `step1_spec.md`

That `step1_spec.md` file is the final Step 1 result and will be used in Step 2.

---

## Files

- `run_step1.sh` — runs the Step 1 pipeline
- `fetch_pr_diff.sh` — fetches the PR diff
- `build_step1_bundle.py` — builds the Step 1 input bundle

---

## Notes

- Step 1 is for specification drafting only
- It should stay grounded in the task inputs
- The Step 1 result must be self-contained and ready for downstream evaluation
- Do not move to Step 2 until the Step 1 spec is clear enough to act as the task contract

---

## CRLF fix

If you see this error:

```text
/usr/bin/env: ‘bash\r’: No such file or directory
```

convert the scripts to Unix line endings:

```bash
sed -i 's/\r$//' fetch_pr_diff.sh
sed -i 's/\r$//' run_step1.sh
sed -i 's/\r$//' build_step1_bundle.py
```

or:

```bash
dos2unix fetch_pr_diff.sh run_step1.sh build_step1_bundle.py
```