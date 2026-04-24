---
name: gen-claude-md
description: Generate CLAUDE.md files for any codebase. Use when initializing a new repo for AI agents, when /init is unavailable (Cursor, Codex, custom agents), or when enhancing an existing CLAUDE.md.
user-invocable: true
disable-model-invocation: false
argument-hint: "[path] [--minimal|--enhance]"
produces:
  - CLAUDE.md
---

# Gen Claude MD - CLAUDE.md Generator

Generate CLAUDE.md files following Claude Code best practices. For AI agents without `/init` command.

## Input

- `$ARGUMENTS` - optional path and flags
- Default: current working directory
- Flags: `--minimal` (bare minimum), `--enhance` (improve existing)

## Output

Write `CLAUDE.md` to target directory root.

## Workflow

### Step 1: Detect Target

```
path = $ARGUMENTS or CWD
mode = "generate" (default) | "minimal" | "enhance"
```

If `--enhance` and existing CLAUDE.md found, read it first.

### Step 2: Scan Codebase

Run these detection passes:

**Language Detection**
```bash
# Check file extensions
find . -maxdepth 3 -type f \( -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) | head -20
```

**Config File Detection**
```bash
# Package managers & build tools
ls -la package.json pyproject.toml setup.py Cargo.toml go.mod pom.xml build.gradle Makefile 2>/dev/null
```

**Framework Detection**
- `next.config.*` → Next.js
- `nuxt.config.*` → Nuxt
- `vite.config.*` → Vite
- `django/settings.py` or `manage.py` → Django
- `app.py` + Flask imports → Flask
- `main.py` + FastAPI imports → FastAPI
- `Cargo.toml` → Rust
- `go.mod` → Go

**Test Framework Detection**
```bash
# Look for test configs
ls -la pytest.ini setup.cfg jest.config.* vitest.config.* .mocharc.* 2>/dev/null
# Check package.json scripts
cat package.json 2>/dev/null | grep -E '"test"|"jest"|"vitest"|"mocha"'
```

**Lint/Format Detection**
```bash
ls -la .eslintrc* .prettierrc* .flake8 pyproject.toml .golangci.yml rustfmt.toml 2>/dev/null
```

### Step 3: Extract Commands

From `package.json`:
```bash
cat package.json | jq -r '.scripts | to_entries[] | "- `npm run \(.key)` - \(.value)"' 2>/dev/null
```

From `Makefile`:
```bash
grep -E "^[a-zA-Z_-]+:" Makefile 2>/dev/null | head -10
```

From `pyproject.toml`:
```bash
grep -A5 "\[tool.poetry.scripts\]" pyproject.toml 2>/dev/null
```

### Step 4: Detect Conventions

Read existing style configs:
- `.editorconfig` → indentation, line endings
- `tsconfig.json` → TypeScript strictness
- `pyproject.toml [tool.black]` → Python formatting
- `.eslintrc` → JS/TS rules

Check for patterns:
- kebab-case vs camelCase in filenames
- Test file patterns (`*.test.ts`, `*_test.go`, `test_*.py`)
- Import style (relative vs absolute)

### Step 5: Generate CLAUDE.md

Use this template. Omit empty sections.

```markdown
# {Project Name}

{One sentence describing what this project does.}

## Stack

- {Language}: {version if detectable}
- {Framework}: {version if detectable}
- {Build tool}: {version}

## Commands

- `{command}` — {what it does}
- `{command}` — {what it does}

## Conventions

- {Non-obvious convention 1}
- {Non-obvious convention 2}

## Architecture

{Brief directory overview - only include if structure is non-standard}

## Rules

- {Hard constraint that Claude can't infer from code}
```

### Step 6: Quality Gates

**GATE 1: Length Check**
- Target: 50-100 lines
- Max: 300 lines
- If over 100 lines: prune ruthlessly

**GATE 2: Content Validation**
Ask for each line: "Would Claude make mistakes without this?"
- YES → keep
- NO → remove

**GATE 3: Exclude List**
Remove if present:
- Standard language conventions Claude knows
- Info Claude can figure out by reading code
- Detailed API documentation (link instead)
- Frequently changing information
- File-by-file codebase descriptions
- Self-evident practices ("write clean code")

### Step 7: Write Output

Write CLAUDE.md to target directory root.

If `--enhance` mode:
- Preserve user's custom sections
- Add missing detected sections
- Don't duplicate existing content

## Mode Variants

### --minimal

Only generate:
```markdown
# {Project Name}

{One sentence.}

## Commands

- `{build command}`
- `{test command}`
- `{lint command}`
```

### --enhance

1. Read existing CLAUDE.md
2. Parse sections
3. Detect missing info from codebase
4. Merge without duplicating
5. Output enhanced version

## Examples

**Python/FastAPI project:**
```markdown
# My API

REST API for user management built with FastAPI.

## Stack

- Python: 3.11
- FastAPI: 0.100+
- PostgreSQL: 15

## Commands

- `make dev` — Start development server with hot reload
- `make test` — Run pytest with coverage
- `make lint` — Run ruff + mypy

## Conventions

- Use Pydantic models for all request/response schemas
- Async functions for all database operations
- Tests in `tests/` mirror `src/` structure

## Rules

- All endpoints require authentication except `/health`
- Database migrations must be backwards compatible
```

**Next.js project:**
```markdown
# My App

E-commerce storefront with Next.js App Router.

## Stack

- TypeScript: 5.x
- Next.js: 14 (App Router)
- Tailwind CSS

## Commands

- `npm run dev` — Development server on :3000
- `npm run build` — Production build
- `npm test` — Jest unit tests
- `npm run e2e` — Playwright end-to-end tests

## Conventions

- Server Components by default, 'use client' only when needed
- Colocation: components live next to pages that use them
- Use `@/` alias for src imports

## Rules

- No inline styles - use Tailwind classes
- All data fetching in Server Components
```

## Anti-Patterns

**DON'T include:**
- "Use meaningful variable names" (obvious)
- "Follow PEP 8" (Claude knows Python conventions)
- Entire API documentation
- Version numbers that change frequently
- "This project uses React" (Claude can see that)

**DO include:**
- Non-standard build commands
- Project-specific architectural decisions
- Constraints Claude can't infer from code
- Test commands with specific flags
