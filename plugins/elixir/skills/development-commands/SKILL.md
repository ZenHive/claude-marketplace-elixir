---
name: development-commands
description: Elixir and Phoenix development commands reference. This skill should be used when looking up mix commands, needing AI-friendly test/dialyzer/credo output flags, creating Phoenix projects with --binary-id, or running quality checks. Covers mix test.json, mix dialyzer.json, mix credo --strict --format json, and production builds.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/development-commands.md — do not edit manually -->

## Elixir Documentation Standards

- **NO IO Operations in @doc Examples**: NEVER use IO.puts, IO.inspect, etc. in @doc heredocs
  - BAD: `IO.puts("User: #{user[:name]}")`
  - BAD: `IO.inspect(user)`
  - GOOD: Just show the pattern matching and data structures
  - GOOD: `{:ok, user} = MyApp.get_user("id")`
  - GOOD: `users = MyApp.list_users()`
  - @doc examples should demonstrate API usage, not console output

## Development Commands

### Compilation

**Always use `time` when compiling** — this tracks compilation duration for performance awareness:

```bash
time mix compile              # Always prefix with time
time MIX_ENV=prod mix compile # Production compilation too
```

This applies to any `mix compile` invocation. Never run bare `mix compile` without `time`.

### Standard Elixir Development
```bash
mix deps.get              # Install dependencies
mix test.json --quiet     # Run tests (AI-friendly JSON output)
mix test.json --quiet --cover  # Run tests with coverage
mix dialyzer.json --quiet # Run type checking (AI-friendly JSON output)
mix credo --strict --format json  # Run static analysis (AI-friendly JSON output)
mix sobelow               # Run security analysis
mix sobelow --mark-skip-all  # Mark all low-confidence findings as false positives
mix doctor                # Check documentation quality
mix format                # Format code
mix docs                  # Generate documentation
mix ex_dna                # Code duplication detection (AST-based)
mix ex_dna --format json  # Machine-readable duplication report
mix ex_ast.search 'pattern' # AST-based code search
mix ex_ast.replace 'old' 'new' # AST-based code replace
```

### Test Output Efficiency

**Use `mix test.json` for AI-friendly output (see `ex-unit-json.md` for full workflows):**

```bash
# ✅ PREFERRED: First run - see failures directly (v0.3.0+ default)
mix test.json --quiet

# ✅ ITERATE: Only re-run previously failed tests
mix test.json --quiet --failed --first-failure

# ✅ VERIFY: Quick check after fixes
mix test.json --quiet --failed --summary-only

# ✅ ALL TESTS: When you need passing tests too
mix test.json --quiet --all

# ✅ COVERAGE: Include code coverage data
mix test.json --quiet --cover

# ✅ COVERAGE GATE: Fail if coverage below threshold
mix test.json --quiet --cover --cover-threshold 80
```

**Guidelines:**
- **Always use `mix test.json`** instead of `mix test` for structured output
- **Default shows only failures** (v0.3.0+) - no extra flags needed
- **Use `--quiet` by default** to save context tokens. Omit when debugging to see Logger output and warnings
- **Use `--all`** when you need to see passing tests
- **Use `--failed`** for iteration (only runs previously failed tests - fast)
- **Use `--first-failure`** when fixing one test at a time
- **Use `--cover`** when you need coverage data (off by default for speed)

### Dialyzer Output Efficiency

**Use `mix dialyzer.json` for AI-friendly output (see `dialyzer-json.md` for full workflows):**

```bash
# ✅ PREFERRED: JSON output for clean piping
mix dialyzer.json --quiet

# ✅ QUICK CHECK: Summary only
mix dialyzer.json --quiet --summary-only

# ✅ BY FILE: See which files need work
mix dialyzer.json --quiet --group-by-file

# ✅ FILTER: Focus on specific warning types
mix dialyzer.json --quiet --filter-type no_return
```

**Guidelines:**
- **Always use `mix dialyzer.json`** instead of `mix dialyzer` for structured output
- **Check `fix_hint` first** - "code" hints are likely real bugs, "spec" hints need typespec fixes
- **Use `--group-by-file`** to see which files need the most attention
- **Use `--filter-type`** to focus on specific warning types

### Credo Output

**Always use `mix credo --strict --format json`:**

```bash
# ✅ ALWAYS: strict mode + JSON output
mix credo --strict --format json
```

**Guidelines:**
- **Always use `--strict --format json`** instead of plain `mix credo`
- Credo's built-in `--format json` requires no extra dependencies
- JSON output includes issue category, priority, file, line, column, and message

### Code Duplication Detection (ExDNA)

**Use `mix ex_dna` to find duplicated code via AST analysis:**

```bash
# ✅ BASIC: Scan for exact duplicates
mix ex_dna

# ✅ TYPE II: Also catch renamed variables/literals
mix ex_dna --literal-mode abstract

# ✅ JSON: Machine-readable output
mix ex_dna --format json

# ✅ IGNORE: Skip generated/intentional duplication
mix ex_dna --ignore "lib/generated/*.ex"

# ✅ DEEP-DIVE: Detailed analysis of a specific clone
mix ex_dna.explain 3
```

**Guidelines:**
- Use `--format json` when parsing output programmatically
- Use `--literal-mode abstract` for comprehensive analysis (catches renamed vars)
- Configure `.ex_dna.exs` in project root for persistent settings
- Add `@no_clone true` above intentionally duplicated functions

### AST Code Search & Replace (ExAST)

**Use `mix ex_ast.search` / `mix ex_ast.replace` for structural code search:**

```bash
# ✅ FIND: Debug leftovers
mix ex_ast.search 'IO.inspect(_)'
mix ex_ast.search 'dbg(_)'

# ✅ CLEANUP: Remove debug calls, keep expressions
mix ex_ast.replace 'dbg(expr)' 'expr'
mix ex_ast.replace 'IO.inspect(expr, _)' 'expr'

# ✅ MIGRATE: Structural code changes
mix ex_ast.replace --dry-run 'use Mix.Config' 'import Config'

# ✅ COUNT: How many occurrences
mix ex_ast.search --count 'Logger.debug(_)'
```

**Guidelines:**
- **Always prefer `ex_ast.search` over `grep`** for Elixir code patterns — it understands AST structure
- Use `--dry-run` with replace to preview changes before applying
- Named captures (`expr`, `x`) in search carry through to replacement
- Structs/maps match partially — only specified keys need to be present
- Run `mix format` after replacements to normalize style

### Phoenix Development (if applicable)

**IMPORTANT: Phoenix Project Creation**
```bash
# ✅ ALWAYS use --binary-id flag when creating new Phoenix projects
mix phx.new my_app --binary-id

# ❌ NEVER create Phoenix projects without --binary-id
mix phx.new my_app  # WRONG - uses integer IDs
```

**Why binary_id:**
- Uses UUIDs instead of sequential integer IDs (more secure)
- Better for distributed systems and API design
- Prevents ID enumeration attacks
- More scalable for multi-tenant applications

```bash
mix ecto.setup            # Create and migrate database
mix phx.server            # Start Phoenix server (dev)
iex -S mix phx.server    # Start with interactive shell
```

### Production
```bash
time MIX_ENV=prod mix compile  # Compile for production (always use time)
MIX_ENV=prod mix release  # Build production release
```
