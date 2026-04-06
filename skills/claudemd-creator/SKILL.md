---
name: claudemd-creator
description: Create or enhance CLAUDE.md for any project. Analyzes repo structure, conventions, test commands. Outputs to claudemd/ folder. If CLAUDE.md exists, audits against V3 rules and supplements missing sections.
user-invocable: true
disable-model-invocation: false
argument-hint: <project_path>
requires:
  - Project path provided or current directory
  - Repo already cloned/accessible
produces:
  - CLAUDE.md in claudemd/{owner}_{repo}/ directory
calls: []
---

# CLAUDE.md Creator

Create or enhance CLAUDE.md for any project repo. Ensures compliance with Marlin V3 evaluation axis 6.3 (following repo instructions).

## Why CLAUDE.md Matters

A CLAUDE.md file provides Claude Code with persistent context about the repository - conventions, testing commands, architectural constraints, and task-specific guidance. Models are expected to follow its instructions, and **evaluation question 6.3 explicitly checks for this**.

## When to Use

- **No CLAUDE.md** in target repo -> generate one from scratch
- **Existing CLAUDE.md** in target repo -> audit against rules below, supplement if gaps found

## Input

Project path via `$ARGUMENTS`. Example: `/path/to/project`

## Output

CLAUDE.md saved to: `claudemd/{owner}_{repo}/CLAUDE.md`

- `{owner}` and `{repo}` extracted from git remote origin URL
- If no git remote, use folder name as `{repo}` and `local` as `{owner}`
- Also outputs an audit log: `claudemd/{owner}_{repo}/audit.md`

## Steps

### Step 1: Resolve project info

```
PROJECT_PATH = $ARGUMENTS or CWD
```

1. `cd $PROJECT_PATH`
2. Extract `{owner}` and `{repo}` from `git remote get-url origin`
   - GitHub: `git@github.com:owner/repo.git` -> owner=owner, repo=repo
   - HTTPS: `https://github.com/owner/repo.git` -> owner=owner, repo=repo
   - No remote: owner=local, repo=folder_name
3. Create output dir: `claudemd/{owner}_{repo}/`

### Step 2: Check for existing CLAUDE.md

Look for CLAUDE.md at these paths (in order):
1. `$PROJECT_PATH/CLAUDE.md`
2. `$PROJECT_PATH/.claude/CLAUDE.md`

If found -> go to **Step 6** (Audit Mode)
If not found -> continue to **Step 3** (Generate Mode)

---

## Generate Mode (No existing CLAUDE.md)

### Step 3: Analyze repo structure

Read and analyze:

1. **README.md** - project description, install guide, usage
2. **Package/dependency files** by language:
   - Python: `requirements.txt`, `setup.py`, `pyproject.toml`, `Pipfile`, `poetry.lock`
   - JS/TS: `package.json`, `tsconfig.json`, `pnpm-workspace.yaml`
   - Go: `go.mod`, `go.sum`
   - Rust: `Cargo.toml`, `Cargo.lock`
   - Java/Kotlin: `pom.xml`, `build.gradle`, `build.gradle.kts`
   - C/C++: `CMakeLists.txt`, `Makefile`, `meson.build`
   - Ruby: `Gemfile`, `Rakefile`
   - PHP: `composer.json`
   - Swift: `Package.swift`
   - C#/.NET: `*.csproj`, `*.sln`
3. **Config files** - `.editorconfig`, `.prettierrc`, `ruff.toml`, `eslint.config.*`, `biome.json`
4. **CI/CD** - `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `Makefile`
5. **Test directories** - `tests/`, `test/`, `__tests__/`, `spec/`, `*_test.go`
6. **Source structure** - `src/`, `lib/`, `cmd/`, `pkg/`, `app/`, `internal/`
7. **Docker** - `Dockerfile`, `docker-compose.yml`
8. **Monorepo markers** - `packages/`, `apps/`, workspace configs

### Step 3.5: Python repo - Setup venv with uv (IMPORTANT)

If primary language is **Python**, MUST setup environment using `uv`:

#### Pre-check: Verify uv is installed

```bash
uv --version
```

- If `uv` **not found** -> attempt install:
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```
- After install, verify again: `uv --version`
- If **still not available** -> **STOP and RAISE ERROR**:
  ```
  ERROR: uv is required for Python repo setup but could not be installed.
  Please install uv manually: https://docs.astral.sh/uv/getting-started/installation/
  Aborting CLAUDE.md generation.
  ```
  Do NOT fall back to pip/venv. Do NOT continue without uv. Report failure in audit.md and exit.

#### Setup venv

1. **Create venv** in the project directory:
   ```bash
   cd $PROJECT_PATH
   uv venv .venv
   ```
   If `uv venv` fails -> **STOP and RAISE ERROR**:
   ```
   ERROR: uv venv creation failed. Check Python installation and uv compatibility.
   Exit code: {exit_code}
   Output: {stderr}
   ```
   Report failure in audit.md and exit.

2. **Install dependencies** into the venv:
   ```bash
   # If pyproject.toml exists (preferred)
   uv pip install -e ".[dev,test]" 2>/dev/null || uv pip install -e "." 2>/dev/null

   # If requirements.txt exists
   uv pip install -r requirements.txt
   # Also install dev/test requirements if present
   uv pip install -r requirements-dev.txt 2>/dev/null
   uv pip install -r requirements-test.txt 2>/dev/null
   uv pip install -r dev-requirements.txt 2>/dev/null
   uv pip install -r test-requirements.txt 2>/dev/null

   # If setup.py only
   uv pip install -e ".[dev,test]" 2>/dev/null || uv pip install -e "."
   ```

3. **Install common test tools** if not already in deps:
   ```bash
   uv pip install pytest pytest-cov 2>/dev/null
   ```

4. **Verify** venv and deps work:
   ```bash
   .venv/bin/python --version
   .venv/bin/pytest --version 2>/dev/null
   ```
   If `.venv/bin/python` doesn't exist or fails -> **STOP and RAISE ERROR**:
   ```
   ERROR: venv verification failed. .venv/bin/python is not functional.
   uv venv may have succeeded but the environment is broken.
   ```
   Report failure in audit.md and exit.

5. **Record in CLAUDE.md** - all Python commands must use `.venv/bin/` prefix or `source .venv/bin/activate` first. The Build & Run and Testing sections MUST reflect this.

**Why uv?** Faster than pip/venv, consistent across environments, handles Python version resolution.

### Step 4: Determine conventions

From analysis, extract:
- **Primary language** and version constraints
- **Build system** (npm, pip/uv, cargo, make, gradle, etc.)
- **Test framework** and commands (pytest, jest, go test, cargo test, etc.)
- **Linting/formatting** tools and commands
- **Code style** conventions (naming, imports, patterns)
- **Architecture patterns** (module structure, API patterns, state management)
- **Environment setup** (env vars, config files, required services)

### Step 5: Generate CLAUDE.md

Use this template - include ALL sections, skip subsections only if truly not applicable:

```markdown
# CLAUDE.md

## Project Overview
{1-3 sentences from README. What the project does, who it's for.}

## Language & Stack
- Primary: {language} {version}
- Dependencies: {package manager} ({lock file})
- Framework: {if applicable}
- Runtime: {Node version, Python version, etc.}

## Build & Run
```bash
{exact commands to install dependencies}
{exact commands to build}
{exact commands to run/start}
```
{For Python repos, MUST include uv venv setup:}
{```bash}
{uv venv .venv}
{uv pip install -e ".[dev,test]"  # or uv pip install -r requirements.txt}
{source .venv/bin/activate}
{```}

## Testing
```bash
{exact command to run all tests}
{exact command to run single test file}
{exact command to run tests with coverage}
```
{For Python repos, commands must use venv:}
{```bash}
{.venv/bin/pytest tests/ -v}
{.venv/bin/pytest tests/test_specific.py -v}
{.venv/bin/pytest tests/ --cov=src --cov-report=term}
{```}
- Framework: {test framework}
- Test location: {test directory}
- Convention: {test file naming pattern, e.g., *_test.go, *.spec.ts}

## Linting & Formatting
```bash
{exact lint command}
{exact format command}
{exact typecheck command if applicable}
```

## Project Structure
```
{key directories and their purpose, max 15 lines}
```

## Code Conventions
- {naming convention: camelCase, snake_case, etc.}
- {import ordering convention}
- {error handling pattern}
- {logging convention}
- {other detected conventions}

## Architecture Notes
- {key architectural decisions}
- {important patterns to follow}
- {areas requiring special care}

## Environment Setup
- {required env vars}
- {required services: DB, Redis, etc.}
- {setup steps beyond install}

## Important Notes
- {gotchas, known issues}
- {things that break easily}
- {backward compat requirements}
```

Then go to **Step 7** (Save & Audit).

---

## Audit Mode (Existing CLAUDE.md found)

### Step 6: Audit existing CLAUDE.md

Read existing CLAUDE.md and check each requirement:

#### Required Sections Checklist

| # | Section | Required | Check |
|---|---------|----------|-------|
| 1 | Project Overview | YES | Brief description present? |
| 2 | Language & Stack | YES | Language, version, deps listed? |
| 3 | Build & Run | YES | Exact runnable commands? |
| 4 | Testing | YES | Test commands that actually work? |
| 5 | Linting & Formatting | YES | Lint/format commands? |
| 6 | Project Structure | YES | Key dirs explained? |
| 7 | Code Conventions | YES | Naming, style documented? |
| 8 | Architecture Notes | RECOMMENDED | Patterns, constraints? |
| 9 | Environment Setup | IF NEEDED | Env vars, services? |
| 10 | Important Notes | RECOMMENDED | Gotchas, known issues? |

#### Quality Checks

- [ ] Commands are exact and runnable (not placeholder)
- [ ] Language version specified
- [ ] Test commands include single-file run example
- [ ] Structure reflects actual repo layout
- [ ] No stale/outdated info (check against actual files)
- [ ] Conventions match actual code patterns
- [ ] No blocked words (check _shared/blocked_words.md)
- [ ] **Python repos**: Uses `uv venv` for venv setup (not plain `python -m venv`)
- [ ] **Python repos**: Test commands use `.venv/bin/pytest` or activate venv first
- [ ] **Python repos**: Dependencies installed via `uv pip install`

#### Audit Result

- **PASS** - All required sections present and accurate -> copy as-is
- **SUPPLEMENT** - Missing sections or stale info -> add/update missing parts, preserve existing good content
- **REWRITE** - Fundamentally insufficient (< 3 sections, mostly wrong) -> generate fresh

For SUPPLEMENT: merge new content into existing CLAUDE.md. Do NOT remove existing valid content. Add sections with comment `<!-- Added by claudemd-creator -->` for traceability.

---

### Step 7: Save & Generate Audit Log

1. Save CLAUDE.md to `claudemd/{owner}_{repo}/CLAUDE.md`
2. Generate audit log at `claudemd/{owner}_{repo}/audit.md`:

```markdown
# CLAUDE.md Audit - {owner}/{repo}

**Date:** {date}
**Mode:** Generate | Audit (PASS/SUPPLEMENT/REWRITE)
**Source:** {path to original CLAUDE.md or "generated"}

## Sections Status
| Section | Status | Notes |
|---------|--------|-------|
| Project Overview | OK/ADDED/UPDATED | ... |
| Language & Stack | OK/ADDED/UPDATED | ... |
| ... | ... | ... |

## Quality Checks
- [ ] Commands verified runnable
- [ ] Structure matches repo
- [ ] Conventions match code

## Changes Made
{list of additions/modifications, or "Generated from scratch"}
```

### Step 8: Verify (IMPORTANT)

Before finalizing, verify:

1. **Commands work** - Try running at least `--version` or `--help` for build tools
2. **Structure accurate** - Compare listed dirs against actual `ls`
3. **Conventions match** - Spot-check 2-3 source files for naming/style
4. **No blocked words** - Cross-reference with `skills/_shared/blocked_words.md`

Report verification results in audit.md.

## Rules

1. **Never remove valid existing content** - only add or update
2. **Commands must be exact** - no "run your test command here" placeholders
3. **Verify before save** - at minimum check structure matches reality
4. **Output to claudemd/ folder** - never modify the original repo's CLAUDE.md directly
5. **Include audit log** - always generate audit.md alongside CLAUDE.md
6. **Language-agnostic** - support Python, JS/TS, Go, Rust, Java, C++, Ruby, PHP, Swift, C#, and more
7. **Monorepo aware** - if monorepo detected, document workspace structure and per-package commands
8. **Python repos use uv** - always use `uv venv` + `uv pip install` for Python projects, never plain `pip` or `python -m venv`. Create `.venv` in project root, install deps, and run tests through `.venv/bin/`

## Example: Audit Output for Insufficient CLAUDE.md

Input CLAUDE.md:
```markdown
# My Project
This is a Python project.
```

Audit result: **SUPPLEMENT** - missing 8/10 required sections.

Output CLAUDE.md adds: Language & Stack, Build & Run, Testing, Linting, Structure, Conventions, Architecture, Important Notes - all derived from repo analysis.
