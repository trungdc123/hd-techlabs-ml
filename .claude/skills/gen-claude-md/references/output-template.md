# CLAUDE.md Output Template

## Standard Template

```markdown
# {Project Name}

{One sentence describing what this project does - be specific.}

## Stack

- {Primary Language}: {version}
- {Framework}: {version}
- {Database/Key dependency}: {version if relevant}

## Commands

- `{build/dev command}` — {what it does}
- `{test command}` — {what it does}
- `{lint command}` — {what it does}
- `{deploy command}` — {what it does, if applicable}

## Conventions

- {Non-obvious code style rule}
- {Project-specific naming convention}
- {Testing pattern}

## Architecture

{Only if non-standard - brief 2-3 line description of structure}

## Rules

- {Hard constraint Claude can't infer}
- {Security/compliance requirement}
```

## Minimal Template (--minimal flag)

```markdown
# {Project Name}

{One sentence.}

## Commands

- `{dev}` — Start dev server
- `{test}` — Run tests
- `{build}` — Build for production
```

## Section Guidelines

### Project Name
- Use actual project name from package.json, Cargo.toml, pyproject.toml
- Or directory name if no config found

### Description
- One sentence max
- Be specific: "REST API for user authentication" not "A backend service"
- Mention primary function, not implementation details

### Stack
- Only list what matters for coding context
- Include versions only if version-specific behavior exists
- Skip obvious dependencies Claude can see in configs

### Commands
- Focus on commands Claude would actually run
- Include any non-obvious flags
- Skip commands Claude can infer from standard configs

### Conventions
- Only non-obvious rules
- Skip language defaults (PEP 8, Prettier defaults)
- Include project-specific patterns

### Architecture
- Skip if standard framework structure
- Include only if layout is unique
- Max 3 lines

### Rules
- Hard constraints: "Never commit to main directly"
- Security requirements: "All endpoints require auth"
- Business logic constraints Claude can't see in code

## Length Targets

| Mode | Target | Max |
|------|--------|-----|
| Standard | 50-80 lines | 150 lines |
| Minimal | 15-25 lines | 40 lines |
| Enhanced | 60-100 lines | 200 lines |

## What NOT to Include

- Standard language conventions
- Info extractable from package.json/configs
- Detailed API documentation
- Changelog or version history
- Tutorial content
- "Write clean code" type statements
