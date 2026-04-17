---
name: development-commands
description: Elixir and Phoenix development commands reference. This skill should be used when looking up mix commands, needing AI-friendly test/dialyzer/credo output flags, creating Phoenix projects with --binary-id, or running quality checks. Covers mix test.json, mix dialyzer.json, mix credo --strict --format json, and production builds.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/development-commands.md — do not edit manually -->

## Development Commands

### Compilation

**Always use `time` when compiling** — this tracks compilation duration for performance awareness:

```bash
time mix compile              # Always prefix with time
time MIX_ENV=prod mix compile # Production compilation too
```

This applies to any `mix compile` invocation. Never run bare `mix compile` without `time`.

For test/dialyzer/credo command details, see `ex-unit-json.md`, `dialyzer-json.md`, and use `mix credo --strict --format json` (always strict + JSON).

### Code Duplication Detection (ExDNA)

**Use `mix ex_dna` to find duplicated code via AST analysis:**

```bash
mix ex_dna                          # Scan for exact duplicates
mix ex_dna --literal-mode abstract  # Also catch renamed variables/literals
mix ex_dna --format json            # Machine-readable output
mix ex_dna --ignore "lib/generated/*.ex"  # Skip generated/intentional duplication
mix ex_dna.explain 3                # Detailed analysis of a specific clone
```

**Guidelines:**
- Use `--format json` when parsing output programmatically
- Use `--literal-mode abstract` for comprehensive analysis (catches renamed vars)
- Configure `.ex_dna.exs` in project root for persistent settings
- Add `@no_clone true` above intentionally duplicated functions

### AST Code Search & Replace (ExAST)

**Use `mix ex_ast.search` / `mix ex_ast.replace` for structural code search:**

```bash
mix ex_ast.search 'IO.inspect(_)'          # Find debug leftovers
mix ex_ast.search 'dbg(_)'
mix ex_ast.replace 'dbg(expr)' 'expr'      # Cleanup, keep expressions
mix ex_ast.replace 'IO.inspect(expr, _)' 'expr'
mix ex_ast.replace --dry-run 'use Mix.Config' 'import Config'  # Migrations
mix ex_ast.search --count 'Logger.debug(_)'
```

**Guidelines:**
- **Always prefer `ex_ast.search` over `grep`** for Elixir code patterns — it understands AST structure
- Use `--dry-run` with replace to preview changes before applying
- Named captures (`expr`, `x`) in search carry through to replacement
- Structs/maps match partially — only specified keys need to be present
- Run `mix format` after replacements to normalize style
