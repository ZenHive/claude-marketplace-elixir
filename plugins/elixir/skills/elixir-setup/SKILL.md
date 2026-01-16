---
name: elixir-setup
description: Standard Elixir project setup - deps (Styler, Credo, Dialyxir, Doctor, Tidewave), .formatter.exs config, quality gates. Use when starting a new Elixir library or non-Phoenix project.
allowed-tools: Read, Bash, Grep, Glob
---

# Elixir Project Setup

Standard dependencies and tooling for all Elixir projects (libraries, CLI tools, escripts).

## When to use this skill

- Starting a new Elixir library
- Adding dev tooling to an existing project
- Need to configure Tidewave for non-Phoenix projects
- Want the recommended deps stack (Styler, Credo, Dialyxir, Doctor)

For **Phoenix projects**, see `phoenix-setup.md` include or use this as a base then add Phoenix-specific deps.

## Recommended Dependencies

| Dep | Purpose | When |
|-----|---------|------|
| styler | Opinionated auto-formatter extending `mix format` | Always |
| credo | Static analysis for code quality, consistency, readability | Always |
| dialyxir | Type analysis wrapper for Dialyzer | Always |
| ex_doc | Documentation generation for HexDocs | Always |
| doctor | Documentation quality gates (@moduledoc, @doc, typespecs) | Always |
| tidewave | Dev tools + Claude Code MCP integration | Always |
| bandit | HTTP server for Tidewave | Non-Phoenix only |

## mix.exs deps block

```elixir
defp deps do
  [
    # Dev/test tooling
    {:styler, "~> 1.9", only: [:dev, :test], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    {:doctor, "~> 0.21", only: [:dev, :test], runtime: false},

    # Tidewave for Claude Code MCP integration (non-Phoenix needs bandit)
    {:tidewave, "~> 0.5", only: :dev},
    {:bandit, "~> 1.6", only: :dev}
  ]
end
```

## .formatter.exs (with Styler)

```elixir
[
  plugins: [Styler],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
```

## Tidewave Setup (Non-Phoenix)

Add alias to `mix.exs`:

```elixir
defp aliases do
  [
    tidewave: [
      "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4001) end)'"
    ]
  ]
end
```

Run with: `iex -S mix tidewave` (starts MCP server on port 4001 with IEx shell)

## Global Tidewave Registration

One-time setup for all projects:

```bash
claude mcp add --transport http tidewave http://localhost:4001/tidewave/mcp
```

## Tidewave MCP Tools

Available in Claude Code after registration:
- `mcp__tidewave__get_docs` - Get module/function documentation
- `mcp__tidewave__get_source_location` - Find source file location
- `mcp__tidewave__project_eval` - Evaluate Elixir code in project context
- `mcp__tidewave__execute_sql_query` - Run SQL queries (if Ecto present)
- `mcp__tidewave__get_ecto_schemas` - List all Ecto schemas
- `mcp__tidewave__search_package_docs` - Search Hex docs across all packages

## Quality Gates

- **Dialyzer**: 0 warnings (mandatory)
- **Credo**: 8.0+ score
- **Doctor**: All public modules documented with @moduledoc and @doc
- **Tests**: 80%+ coverage (95% for critical business logic)

## Quick Reference

```bash
# After adding deps to mix.exs:
mix deps.get        # Fetch dependencies
mix format          # Auto-format (Styler integrates automatically)
mix credo           # Run static analysis
mix dialyzer        # Run type analysis (first run builds PLT, takes time)
mix doctor          # Check documentation quality
mix test --cover    # Run tests with coverage

# Start Tidewave (non-Phoenix):
iex -S mix tidewave
```
