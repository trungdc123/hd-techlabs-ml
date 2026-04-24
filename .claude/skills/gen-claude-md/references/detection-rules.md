# Detection Rules

Quick reference for detecting tech stacks from file patterns.

## Language Detection

| Language | Extensions | Key Files |
|----------|------------|-----------|
| Python | .py | pyproject.toml, setup.py, requirements.txt |
| TypeScript | .ts, .tsx | tsconfig.json |
| JavaScript | .js, .jsx, .mjs | package.json |
| Go | .go | go.mod, go.sum |
| Rust | .rs | Cargo.toml |
| Java | .java | pom.xml, build.gradle |
| C# | .cs | *.csproj, *.sln |
| Ruby | .rb | Gemfile |
| PHP | .php | composer.json |

## Framework Detection

| Framework | Key Files/Patterns |
|-----------|-------------------|
| Next.js | next.config.* |
| Nuxt | nuxt.config.* |
| Vite | vite.config.* |
| React | react in package.json deps |
| Vue | vue in package.json deps |
| Django | manage.py, django in requirements |
| FastAPI | fastapi in requirements |
| Flask | flask in requirements |
| Express | express in package.json |
| NestJS | @nestjs in package.json |
| Gin | gin-gonic in go.mod |
| Actix | actix-web in Cargo.toml |
| Spring | spring in pom.xml/build.gradle |

## Build Tool Detection

| Tool | Key Files |
|------|-----------|
| npm | package-lock.json |
| yarn | yarn.lock |
| pnpm | pnpm-lock.yaml |
| bun | bun.lockb |
| Poetry | poetry.lock |
| pip | requirements.txt |
| uv | uv.lock |
| Cargo | Cargo.lock |
| Go modules | go.sum |
| Maven | pom.xml |
| Gradle | build.gradle* |
| Make | Makefile |

## Test Framework Detection

| Framework | Key Files/Patterns |
|-----------|-------------------|
| pytest | pytest.ini, conftest.py, pyproject.toml [tool.pytest] |
| Jest | jest.config.*, jest in package.json |
| Vitest | vitest.config.* |
| Mocha | .mocharc.*, mocha in package.json |
| Playwright | playwright.config.* |
| Cypress | cypress.config.* |
| Go test | *_test.go files |
| Rust test | #[test] in src |
| JUnit | junit in pom.xml |

## Lint/Format Detection

| Tool | Key Files |
|------|-----------|
| ESLint | .eslintrc*, eslint.config.* |
| Prettier | .prettierrc*, prettier.config.* |
| Biome | biome.json |
| Ruff | ruff.toml, [tool.ruff] in pyproject |
| Black | [tool.black] in pyproject |
| Flake8 | .flake8, [flake8] in setup.cfg |
| mypy | mypy.ini, [tool.mypy] in pyproject |
| golangci-lint | .golangci.yml |
| rustfmt | rustfmt.toml |
| clippy | .clippy.toml |

## Version Extraction

```bash
# Node version
node -v 2>/dev/null || cat .nvmrc 2>/dev/null || cat .node-version 2>/dev/null

# Python version
python3 --version 2>/dev/null || cat .python-version 2>/dev/null

# Go version
go version 2>/dev/null || grep "^go " go.mod 2>/dev/null

# Rust version
rustc --version 2>/dev/null || cat rust-toolchain.toml 2>/dev/null
```

## Directory Structure Patterns

| Pattern | Indicates |
|---------|-----------|
| src/, lib/ | Source code |
| tests/, test/, __tests__/ | Test files |
| docs/ | Documentation |
| scripts/, tools/ | Utility scripts |
| config/, .config/ | Configuration |
| public/, static/, assets/ | Static files |
| components/ | UI components |
| pages/, routes/, views/ | Page/route handlers |
| api/, services/ | API/service layer |
| models/, entities/ | Data models |
| utils/, helpers/, lib/ | Utilities |
