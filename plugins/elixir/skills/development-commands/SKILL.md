---
name: development-commands
description: Elixir and Phoenix development commands reference. This skill should be used when looking up mix commands, needing AI-friendly test/dialyzer/credo output flags, creating Phoenix projects with --binary-id, or running quality checks. Covers mix test.json, mix dialyzer.json, mix credo --strict --format json, and production builds.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/development-commands.md — do not edit manually -->

## Development Commands

### Compilation

**Always prefix `mix compile` with `time`** — tracks compilation duration:

```bash
time mix compile
time MIX_ENV=prod mix compile
```

For tests/dialyzer/credo, see `ex-unit-json.md`, `dialyzer-json.md`. Credo: always `mix credo --strict --format json`.

### ExDNA — Duplication Detection

```bash
mix ex_dna                                # scan for duplicates
mix ex_dna --literal-mode abstract        # also catch renamed vars (Type II)
mix ex_dna --format json                  # machine-readable
mix ex_dna --ignore "lib/generated/*.ex"  # skip generated code
mix ex_dna.explain 3                      # detailed analysis of one clone
```

Config: `.ex_dna.exs`. Suppress intentional dupes with `@no_clone true`.

### ExAST — AST Search & Replace

**Prefer `ex_ast.search` over `grep` for Elixir patterns** — understands AST structure. Min version: `{:ex_ast, "~> 0.3"}`.

```bash
mix ex_ast.search 'IO.inspect(_)'                              # find debug leftovers
mix ex_ast.search --count 'Logger.debug(_)'
mix ex_ast.replace 'dbg(expr)' 'expr'                          # cleanup, preserve expression
mix ex_ast.replace --dry-run 'use Mix.Config' 'import Config'  # preview migrations

# 0.3.0: pipe awareness — matches both forms bidirectionally
mix ex_ast.search 'Enum.map(_, _)'                             # matches `data |> Enum.map(f)` too
mix ex_ast.search 'data |> Enum.map(f)'                        # matches `Enum.map(data, f)` too

# 0.3.0: ancestor-context filters
mix ex_ast.search 'Repo.get!(_, _)' --inside 'def _(_)'        # only inside function defs
mix ex_ast.search 'IO.inspect(_)' --not-inside 'test _, do: _' # skip inside tests

# 0.3.0: multi-node patterns (sequential statements)
mix ex_ast.search 'a = Repo.get!(_, _); Repo.delete(a)'        # N+1-ish load-then-delete pairs
```

Named captures (`expr`, `x`) in search carry to replacement. Structs/maps match partially. Run `mix format` after replacements.
