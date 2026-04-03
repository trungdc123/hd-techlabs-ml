---
name: gen-claude-md
description: Auto-generate CLAUDE.md for a repo if none exists. V3 requires CLAUDE.md before running claude-hfi. Analyzes repo structure, conventions, test commands.
user-invocable: true
disable-model-invocation: false
argument-hint: <repo_path>
requires:
  - Repo already cloned/unpacked
produces:
  - CLAUDE.md at repo root
calls: []
---

# Gen CLAUDE.md - Auto-generate CLAUDE.md for Repo

V3 REQUIRES all repos to have CLAUDE.md before running claude-hfi. This skill auto-generates it if the repo doesn't have one.

## When to Use

- Repo does NOT have CLAUDE.md -> run this skill
- Repo ALREADY has CLAUDE.md -> not needed, use as-is (may add targeted additions)

## Input

Repo path via $ARGUMENTS or current directory.

## Output

Creates `CLAUDE.md` at repo root.

## Steps

### Step 1: Analyze repo structure

Read and analyze:
1. **README.md** - project description, install guide
2. **Package files** - determine language and dependencies:
   - Python: `requirements.txt`, `setup.py`, `pyproject.toml`, `Pipfile`
   - JS/TS: `package.json`, `tsconfig.json`
   - Go: `go.mod`, `go.sum`
   - Rust: `Cargo.toml`
   - Java: `pom.xml`, `build.gradle`
   - C++: `CMakeLists.txt`, `Makefile`
3. **Config files** - `.editorconfig`, `.prettierrc`, `ruff.toml`, `eslint.config.*`
4. **CI/CD** - `.github/workflows/`, `.gitlab-ci.yml`, `Makefile`
5. **Test directories** - `tests/`, `test/`, `__tests__/`, `spec/`
6. **Source structure** - `src/`, `lib/`, `cmd/`, `pkg/`, `app/`

### Step 2: Determine conventions

From code analysis, determine:
- **Primary language** and version
- **Build system** (npm, pip, cargo, make, gradle...)
- **Test framework** (pytest, jest, go test, cargo test...)
- **Linting** (ruff, eslint, clippy, golangci-lint...)
- **Code style** (formatter, clear conventions)
- **Architecture patterns** (module structure, naming conventions)

### Step 3: Determine test commands

Find how to run tests:
- From `Makefile`: targets `test`, `check`, `lint`
- From `package.json`: scripts `test`, `lint`, `build`
- From CI config: commands in test jobs
- Fallback: language convention (`pytest`, `npm test`, `go test ./...`)

### Step 4: Generate CLAUDE.md

```markdown
# CLAUDE.md

## Project Overview
{1-2 sentences describing project, from README}

## Language & Stack
- Primary: {language} {version}
- Dependencies: {package manager} ({file})
- Framework: {if applicable}

## Build & Run
```
{exact commands to build and run}
```

## Testing
```
{exact commands to run tests}
```
{Test framework, test directory, convention}

## Linting & Formatting
```
{exact commands}
```

## Project Structure
```
{key directories and their purpose}
```

## Code Conventions
- {naming convention}
- {import order}
- {error handling pattern}
- {other detected conventions}

## Important Notes
- {architectural constraints}
- {known issues}
- {areas to be careful with}
```

### Step 5: Verify

Check CLAUDE.md:
- Enough info for model to understand the repo?
- Test commands actually work?
- Conventions accurate?

## V3 CLAUDE.md Workflow (IMPORTANT)

Operation order when using with claude-hfi:

1. **Ensure clean main branch** (no pending changes)
2. **Launch HFI tool** (`./claude-hfi --vscode`) - MUST launch FIRST
3. **Create CLAUDE.md** using this skill (in separate terminal, NOT in claude-hfi)
4. **Copy CLAUDE.md to HFI cache** - HFI uses its own internal cache:
   - Path A: original repo (where you created CLAUDE.md)
   - Path B: HFI cache (where HFI actually reads from)
   - Copy: `cp CLAUDE.md <hfi-cache-path>/CLAUDE.md`
5. **After copying**, Claude Code in HFI will see and follow CLAUDE.md

NOTES:
- HFI will NOT push CLAUDE.md to git remote
- If you ask Claude Code to update CLAUDE.md, it will target the correct file
- Only needs to be done once per repo

## Example Output for Python Repo

```markdown
# CLAUDE.md

## Project Overview
Prefect is an open-source workflow orchestration framework for Python.

## Language & Stack
- Primary: Python 3.11+
- Dependencies: pip (requirements.txt, setup.cfg)
- Framework: FastAPI (internal API), Click (CLI)

## Build & Run
```
pip install -e ".[dev]"
prefect server start
```

## Testing
```
pytest tests/ -v --tb=short
pytest tests/test_callables.py -v  # specific file
```
Test framework: pytest. Tests in tests/ directory.

## Linting & Formatting
```
ruff check src/
ruff format src/
```

## Project Structure
```
src/prefect/
  cli/          # CLI commands (Click)
  client/       # API client
  flows.py      # Flow definitions
  utilities/    # Helper modules
    callables.py  # Function introspection
tests/          # pytest tests
```

## Code Conventions
- Type hints on all public functions
- Docstrings in Google style
- Async/await preferred for I/O
- Tests in same directory structure as source

## Important Notes
- pydantic v1 and v2 both supported (check HAS_PYDANTIC_V2)
- AST walkers must handle both FunctionDef and AsyncFunctionDef
- Module resolution uses importlib.util.find_spec
```
