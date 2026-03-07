---
name: development-commands
description: Elixir and Phoenix development commands reference. This skill should be used when looking up mix commands, needing AI-friendly test/dialyzer/credo output flags, creating Phoenix projects with --binary-id, or running quality checks. Covers mix test.json, mix dialyzer.json, mix credo --strict --format json, and production builds.
allowed-tools: Read, Bash
---

# Elixir Development Commands

Quick reference for common Elixir and Phoenix development commands with AI-friendly output.

## When to use this skill

- Looking up mix commands for development
- Needing AI-friendly output flags for tests, dialyzer, or credo
- Creating a new Phoenix project
- Running quality checks

## Elixir Documentation Standards

- **NO IO Operations in @doc Examples**: NEVER use IO.puts, IO.inspect, etc. in @doc heredocs
  - BAD: `IO.puts("User: #{user[:name]}")`
  - GOOD: `{:ok, user} = MyApp.get_user("id")`
  - @doc examples should demonstrate API usage, not console output

## Standard Development Commands

```bash
mix deps.get              # Install dependencies
mix test.json --quiet     # Run tests (AI-friendly JSON output)
mix test.json --quiet --cover  # Run tests with coverage
mix dialyzer.json --quiet # Run type checking (AI-friendly JSON output)
mix credo --strict --format json  # Run static analysis (AI-friendly JSON output)
mix sobelow               # Run security analysis
mix doctor                # Check documentation quality
mix format                # Format code
mix docs                  # Generate documentation
```

## Test Output (mix test.json)

**Always use `mix test.json` instead of `mix test`:**

```bash
# First run - see failures directly (v0.3.0+ default)
mix test.json --quiet

# Iterate on failures (fast - only runs previously failed tests)
mix test.json --quiet --failed --first-failure

# Verify fix
mix test.json --quiet --failed --summary-only

# All tests (when you need passing tests too)
mix test.json --quiet --all

# Coverage
mix test.json --quiet --cover

# Coverage gate (fail if below threshold)
mix test.json --quiet --cover --cover-threshold 80
```

**Guidelines:**
- **Default shows only failures** (v0.3.0+) - no extra flags needed
- **Use `--failed`** for iteration (only runs previously failed tests - fast)
- **Use `--first-failure`** when fixing one test at a time
- **Use `--cover`** when you need coverage data (off by default for speed)

## Dialyzer Output (mix dialyzer.json)

**Always use `mix dialyzer.json` instead of `mix dialyzer`:**

```bash
# JSON output for clean piping
mix dialyzer.json --quiet

# Summary only (quick health check)
mix dialyzer.json --quiet --summary-only

# By file (see which files need work)
mix dialyzer.json --quiet --group-by-file

# Filter to specific warning types
mix dialyzer.json --quiet --filter-type no_return
```

**Guidelines:**
- **Check `fix_hint` first** - "code" hints are likely real bugs, "spec" hints need typespec fixes
- **Use `--group-by-file`** to see which files need the most attention

## Credo Output

**Always use `mix credo --strict --format json`:**

```bash
# Strict mode + JSON output
mix credo --strict --format json
```

Credo's built-in `--format json` requires no extra dependencies. JSON output includes issue category, priority, file, line, column, and message.

## Phoenix Project Creation

```bash
# ALWAYS use --binary-id flag when creating new Phoenix projects
mix phx.new my_app --binary-id

# NEVER create Phoenix projects without --binary-id
# mix phx.new my_app  # WRONG - uses integer IDs
```

**Why binary_id:**
- Uses UUIDs instead of sequential integer IDs (more secure)
- Better for distributed systems and API design
- Prevents ID enumeration attacks

## Phoenix Development

```bash
mix ecto.setup            # Create and migrate database
mix phx.server            # Start Phoenix server (dev)
iex -S mix phx.server    # Start with interactive shell
```

## Production

```bash
MIX_ENV=prod mix compile  # Compile for production
MIX_ENV=prod mix release  # Build production release
```
