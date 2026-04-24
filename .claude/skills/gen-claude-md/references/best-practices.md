# CLAUDE.md Best Practices

From Claude Code documentation and real-world usage.

## Golden Rule

For each line, ask: "Would Claude make mistakes without this?"
- YES → keep
- NO → remove

## Include

| Category | Examples |
|----------|----------|
| **Commands Claude can't guess** | Custom build scripts, non-standard test flags, deploy commands |
| **Non-default code style** | "Use tabs not spaces", "Single quotes only", "No semicolons" |
| **Test instructions** | "Run single test files, not full suite", "Use -x to stop on first failure" |
| **Repo etiquette** | Branch naming, PR conventions, commit message format |
| **Architectural decisions** | "Server Components by default", "No ORM, raw SQL only" |
| **Environment quirks** | Required env vars, local setup steps |
| **Non-obvious behaviors** | "Hot reload breaks if you edit X", "Must restart after Y" |

## Exclude

| Category | Why |
|----------|-----|
| **Standard conventions** | Claude knows PEP 8, Prettier defaults, Go formatting |
| **Info from code** | Claude can read imports, configs, types |
| **Detailed API docs** | Link to docs instead |
| **Frequently changing info** | Version numbers that update often |
| **File-by-file descriptions** | Claude can read the files |
| **Obvious practices** | "Write tests", "Handle errors", "Use types" |

## Structure Tips

### Use Headers
```markdown
## Commands    ← Major sections with ##
## Conventions
## Rules
```

### Use Lists
```markdown
- `npm run dev` — Start dev server
- `npm test` — Run Jest
```

### Keep It Flat
Don't nest deeply. One level of bullets max.

### Be Specific
```markdown
# Bad
- Use good naming

# Good  
- Use snake_case for Python files, camelCase for JS
```

## Emphasis

Use emphasis sparingly for critical rules:
```markdown
**IMPORTANT**: Never commit .env files
```

Don't overuse - if everything is emphasized, nothing is.

## File Imports

Reference other files with `@`:
```markdown
See @README.md for setup instructions.
Git workflow: @docs/CONTRIBUTING.md
```

## Multiple CLAUDE.md Files

| Location | Purpose |
|----------|---------|
| `./CLAUDE.md` | Project-specific, commit to git |
| `./CLAUDE.local.md` | Personal overrides, gitignore it |
| `~/.claude/CLAUDE.md` | Global defaults for all projects |
| `.claude/CLAUDE.md` | Alternative project location |
| `parent/CLAUDE.md` | Monorepo root instructions |

## Iteration

1. Start minimal - 20-30 lines
2. Use Claude, note when it makes mistakes
3. Add rules only for actual mistakes
4. Prune rules that don't change behavior
5. Review monthly, remove stale content

## Anti-Patterns

**Bloat**
```markdown
# Bad - 500 lines of everything
## File: src/index.ts
This file does X...

## File: src/utils.ts  
This file does Y...
```

**Vague**
```markdown
# Bad
- Follow best practices
- Write good code
- Be careful with security
```

**Duplicating configs**
```markdown
# Bad - this is in tsconfig.json
- Use strict TypeScript
- Target ES2020
```

**Tutorial content**
```markdown
# Bad
To get started, first install Node.js...
Then clone the repo...
```
