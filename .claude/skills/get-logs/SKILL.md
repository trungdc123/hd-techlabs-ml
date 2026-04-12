---
name: get-logs
description: Capture and analyze logs from tmux sessions when Model A/B is running or completed. Monitor progress, check errors, extract test results.
user-invocable: true
disable-model-invocation: false
argument-hint: <session_name> [--lines N] [--save path] [--grep pattern] [--compare session2]
requires:
  - tmux running with sessions for Model A and/or Model B
produces:
  - Model status analysis (running/done/error)
  - Extracted test results, errors, warnings
  - Optional: save logs to file in workspace
calls: []
---

# Get Logs - Tmux Session Monitor

Capture logs from tmux session, analyze running state, extract important information.

## Input

Tmux session name via $ARGUMENTS. Default: `model_a` or `model_b`.

Options:
- `--lines N`: Number of lines to capture (default: 100)
- `--save path`: Save logs to file
- `--grep pattern`: Filter logs by pattern
- `--compare session2`: Compare 2 sessions

## Output Format

```
### Status: [RUNNING / COMPLETED / ERROR / NOT_FOUND]

### Summary
- Runtime: Xm Ys (estimated)
- Last line: [last output line]
- Test results: [if detected]
- Errors: [if any]

### Recent Logs (last N lines)
[logs content]

### Analysis
[Status assessment, issues detected, next steps]
```

## Steps

### Step 1: Check tmux session exists

Run:
```bash
tmux has-session -t <session_name> 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
```

If NOT_FOUND:
- List all sessions: `tmux list-sessions`
- Suggest closest session name
- Report clear error

### Step 2: Capture logs from tmux

```bash
# Capture last N lines from buffer
tmux capture-pane -t <session_name> -p -S -<N>
```

If more than default buffer needed:
```bash
# Capture entire scrollback buffer
tmux capture-pane -t <session_name> -p -S -
```

If `--grep` specified:
```bash
tmux capture-pane -t <session_name> -p -S - | grep -E "<pattern>"
```

### Step 3: Analyze status

Determine model status from logs:

**RUNNING:**
- Active cursor (new output appearing)
- Signs of processing: "Running...", "Building...", "Testing..."
- No completion indicators

**COMPLETED:**
- Completion indicators: "Done", "Finished", "Complete", exit code 0
- Test summary present: "X passed, Y failed"
- Shell prompt returned ($, %, >, #)

**ERROR:**
- Error messages: "Error:", "FAIL", "Exception", "Traceback"
- Non-zero exit code
- Process killed or timed out
- Segfault, OOM, or crash signals

**IDLE:**
- Session exists but no process running
- Shell is idle

### Step 4: Extract key information

Auto-detect and extract:

**Test Results:**
- Pattern: `X passed`, `X failed`, `X errors`
- Pattern: `PASS`, `FAIL`, `ERROR` with test names
- Pattern: `pytest`, `jest`, `go test`, `cargo test` output
- Summary: total tests, passed, failed

**Errors and Warnings:**
- Lines containing: `Error`, `error`, `ERROR`, `Exception`, `Warning`, `WARN`
- Traceback blocks (Python)
- Compile errors
- Runtime errors

**Runtime:**
- Time from first to last line (if timestamps present)
- Or estimate from tmux session creation time

**Files Changed:**
- Pattern: `git diff --stat`, `modified:`, `new file:`
- List of files model changed

### Step 5: Save logs (if --save)

```bash
tmux capture-pane -t <session_name> -p -S - > <save_path>
```

Add metadata header:
```
# Logs captured from tmux session: <session_name>
# Captured at: <timestamp>
# Lines: <count>
# Status: <RUNNING/DONE/ERROR>
---
<logs content>
```

### Step 6: Compare (if --compare)

When comparing 2 sessions:

```
### Comparison: Model A vs Model B

| Criteria | Model A | Model B |
|----------|---------|---------|
| Status | COMPLETED | RUNNING |
| Runtime | 5m 23s | 3m 10s (running) |
| Tests passed | 25/25 | 18/20 (2 failed) |
| Errors | 0 | 2 |
| Files changed | 5 | 7 |

### Key Differences
- Model A completed first with 0 errors
- Model B has 2 test failures: [test names]
- Model B changed more files (7 vs 5)
```

## Common Patterns

### Quick check if model is running
```
/get-logs model_a
```

### Continuous monitoring (check every few minutes)
```
/get-logs model_a --lines 20
# ... wait a few minutes ...
/get-logs model_a --lines 20
```

### Get only test results
```
/get-logs model_a --grep "PASS\|FAIL\|passed\|failed\|error"
```

### Save full logs for evidence
```
/get-logs model_a --save workspace/329_.../turn_1/logs_a.txt
/get-logs model_b --save workspace/329_.../turn_1/logs_b.txt
```

### Quick compare 2 models
```
/get-logs model_a model_b --compare
```

### Check specific errors
```
/get-logs model_b --grep "Traceback\|Exception\|Error"
```

## Workflow Integration

In the checkpoint review flow:

1. **Before collecting diffs**: Check both models finished
   ```
   /get-logs model_a
   /get-logs model_b
   ```

2. **Save logs as evidence**: Logs serve as execution_evidence
   ```
   /get-logs model_a --save workspace/.../turn_N/logs_a.txt
   ```

3. **Extract runtime**: Get execution time for evaluation
   ```
   /get-logs model_a --grep "real\|user\|sys\|elapsed"
   ```

4. **Debug model failures**: Check why a model failed
   ```
   /get-logs model_b --grep "error\|fail" --lines 50
   ```

## Notes

- Tmux buffer is limited (default 2000 lines). If model produces lots of output, old buffer is lost.
- To increase buffer: `tmux set-option -g history-limit 50000`
- For full logs, redirect output when running model: `command 2>&1 | tee logs.txt`
- This skill only READS logs, it does not interfere with running processes.
