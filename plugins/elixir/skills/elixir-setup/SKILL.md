---
name: elixir-setup
description: Standard Elixir project setup and dev tooling. ALWAYS invoke when running `mix new`, starting a new Elixir project, or adding dev dependencies. Configures Styler, Credo, Dialyxir, Doctor, Tidewave, ex_unit_json, dialyzer_json, .formatter.exs, and quality gates. For Phoenix projects, use this as base then add phoenix-setup.
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/elixir-setup.md — do not edit manually -->

## Elixir Project Setup

Standard dependencies and tooling for all Elixir projects (libraries, CLI tools, escripts).

### Recommended Dependencies

| Dep | Purpose | When |
|-----|---------|------|
| ex_unit_json | AI-friendly JSON test output (`mix test.json`) | Always |
| dialyzer_json | AI-friendly JSON dialyzer output (`mix dialyzer.json`) | Always |
| styler | Opinionated auto-formatter extending `mix format` | Always |
| credo | Static analysis for code quality, consistency, readability | Always |
| dialyxir | Type analysis wrapper for Dialyzer | Always |
| ex_doc | Documentation generation for HexDocs + **llms.txt for AI** | Always |
| doctor | Documentation quality gates (@moduledoc, @doc, typespecs) | Always |
| tidewave | Dev tools + Claude Code MCP integration | Always |
| bandit | HTTP server for Tidewave | Non-Phoenix only |
| descripex | Self-describing APIs: `api()` macro + `Discoverable` progressive disclosure (`describe/0-2`) | Always (any project with ≥3 public modules) |
| ex_dna | AST-based code duplication detector (Type I/II/III clones) | Always |
| ex_ast | AST-based code search and replace using Elixir patterns | Always |

### mix.exs deps block (libraries/non-Phoenix)

```elixir
defp deps do
  [
    # Dev/test tooling
    {:ex_unit_json, "~> 0.4", only: [:dev, :test], runtime: false},
    {:dialyzer_json, "~> 0.1", only: [:dev, :test], runtime: false},
    {:styler, "~> 1.4", only: [:dev, :test], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.39", only: :dev, runtime: false},
    {:doctor, "~> 0.22", only: [:dev, :test], runtime: false},

    # Tidewave for Claude Code MCP integration (non-Phoenix needs bandit)
    {:tidewave, "~> 0.5", only: :dev},
    {:bandit, "~> 1.10", only: :dev}

    # Code analysis tools
    {:ex_dna, "~> 1.1", only: [:dev, :test], runtime: false},
    {:ex_ast, "~> 0.2", only: [:dev, :test], runtime: false},

    # Self-describing APIs — full dep (not dev/test only), macros expand at compile time
    {:descripex, "~> 0.4"}
  ]
end
```

### mix.exs cli configuration (required for ex_unit_json and dialyzer_json)

```elixir
def cli do
  [preferred_envs: ["test.json": :test, "dialyzer.json": :dev]]
end
```

Mix doesn't inherit `preferred_envs` from dependencies, so this is required.

### .formatter.exs (with Styler)

```elixir
[
  plugins: [Styler],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
```

### Tidewave Setup (Non-Phoenix)

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

### Global Tidewave Registration

One-time setup for all projects:

```bash
claude mcp add --transport http tidewave http://localhost:4001/tidewave/mcp
```

### Tidewave MCP Tools

Available in Claude Code after registration:
- `mcp__tidewave__get_docs` - Get module/function documentation
- `mcp__tidewave__get_source_location` - Find source file location
- `mcp__tidewave__project_eval` - Evaluate Elixir code in project context
- `mcp__tidewave__execute_sql_query` - Run SQL queries (if Ecto present)
- `mcp__tidewave__get_ecto_schemas` - List all Ecto schemas
- `mcp__tidewave__search_package_docs` - Search Hex docs across all packages

### Tidewave Recompile After Code Changes

Tidewave runs in the same BEAM VM as the IEx session. After editing source files, the BEAM still has the old compiled code loaded. Run `recompile()` via `project_eval` to pick up changes:

```elixir
# Via mcp__tidewave__project_eval
recompile()       # Full recompile — picks up all changed files
r(SomeModule)     # Single module reload
```

### Quality Gates

- **Dialyzer**: 0 warnings (mandatory)
- **Credo**: 0 issues in strict mode
- **Doctor**: All public modules documented with @moduledoc and @doc
- **Tests**: 80%+ coverage (95% for critical business logic)

### ex_doc llms.txt (AI-Friendly Docs)

As of v0.40.0, ex_doc automatically generates `llms.txt` - a Markdown document optimized for LLM consumption. This is generated alongside HTML docs when you run `mix docs`.

**What it provides:**
- Complete API documentation in Markdown format
- Structured for easy LLM context loading
- "Copy Markdown" button on every HexDocs page

**Usage for AI coders:**
- After `mix docs`, find `doc/llms.txt` in your project
- Published packages on HexDocs have llms.txt at `https://hexdocs.pm/<package>/llms.txt`
- Use this for loading library context into AI conversations

**Example:** `https://hexdocs.pm/phoenix/llms.txt` provides Phoenix docs in LLM-friendly format.

### ExDNA — Code Duplication Detection

AST-based duplication detector. Finds exact (Type I), renamed-variable (Type II), and near-miss (Type III) clones.

```bash
mix ex_dna                                    # Scan lib/ for duplicates
mix ex_dna --literal-mode abstract            # Type II: catch renamed variables
mix ex_dna --min-similarity 0.85              # Type III: near-miss clones
mix ex_dna --format json                      # Machine-readable output
mix ex_dna --ignore "lib/generated/**"        # Skip generated code
mix ex_dna.explain 3                          # Deep-dive a specific clone
```

**Configuration** (`.ex_dna.exs` in project root):
```elixir
%{
  min_mass: 30,
  ignore: ["lib/generated/**"],
  excluded_macros: [:@, :schema],
  normalize_pipes: true
}
```

**Suppress intentional duplication:** Add `@no_clone true` above the function.

**Credo integration:** Add `{ExDNA.Credo, []}` to `.credo.exs` to replace built-in duplicate check.

### ExAST — AST-Based Code Search & Replace

Search and replace Elixir code using AST pattern matching — like grep/sed but understands code structure.

```bash
mix ex_ast.search 'IO.inspect(_)'                         # Find all IO.inspect calls
mix ex_ast.search '%Step{id: "subject"}' lib/documents/   # Find struct usage
mix ex_ast.search --count 'dbg(_)'                         # Count occurrences
mix ex_ast.replace 'dbg(expr)' 'expr'                      # Remove dbg, keep expression
mix ex_ast.replace --dry-run 'use Mix.Config' 'import Config'  # Preview migration
```

**Pattern syntax:**
- `_` or `_name` — wildcard (matches anything, doesn't capture)
- Named variables (`expr`, `x`) — match and capture for use in replacement
- Structs/maps match partially — only specified keys need to be present

**Programmatic API:**
```elixir
ExAST.search("lib/", "IO.inspect(_)")
ExAST.replace("lib/", "dbg(expr)", "expr")
```

### Running Quality Checks

```bash
mix deps.get                      # Fetch dependencies
mix format                        # Auto-format (Styler integrates automatically)
mix credo --strict --format json  # Run static analysis (AI-friendly JSON output)
mix dialyzer.json --quiet         # Run type analysis with JSON output (first run builds PLT)
mix doctor                        # Check documentation quality
mix test.json --quiet --cover     # Run tests with JSON output (always use instead of mix test)
mix ex_dna                        # Code duplication analysis
mix ex_ast.search 'IO.inspect(_)' # Find debug leftovers
```

**Note**: Always use `mix test.json` instead of `mix test`, `mix dialyzer.json` instead of `mix dialyzer`, and `mix credo --strict --format json` instead of `mix credo` for AI-friendly output. See `ex-unit-json.md` and `dialyzer-json.md` for workflows.
