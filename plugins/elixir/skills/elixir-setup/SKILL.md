---
name: elixir-setup
description: Standard Elixir project setup and dev tooling. ALWAYS invoke when running `mix new`, starting a new Elixir project, or adding dev dependencies. Configures Styler, Credo, Dialyxir, Doctor, Tidewave, ex_unit_json, dialyzer_json, .formatter.exs, and quality gates. For Phoenix projects, use this as base then add phoenix-setup.
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/elixir-setup.md — do not edit manually -->

## Elixir Project Setup

Standard dependencies and tooling for Elixir projects (libraries, CLI tools, escripts).

### Recommended Dependencies

| Dep | Purpose | When |
|-----|---------|------|
| ex_unit_json | `mix test.json` — AI-friendly test output | Always |
| dialyzer_json | `mix dialyzer.json` — AI-friendly dialyzer output | Always |
| styler | Auto-formatter extending `mix format` | Always |
| credo | Static analysis | Always |
| dialyxir | Dialyzer wrapper | Always |
| ex_doc | HexDocs + `llms.txt` for AI | Always |
| doctor | Doc quality gates (@moduledoc, @doc, typespecs) | Always |
| tidewave | Dev tools + Claude Code MCP | Always |
| bandit | HTTP server for Tidewave | Non-Phoenix only |
| descripex | `api()` macro, JSON Schema, MCP tools, progressive disclosure | Any project with ≥3 public modules |
| api_toolkit | InboundLimiter, RateLimiter, Metrics, Cache, Provider DSL (see `api-toolkit.md`) | API services |
| ex_dna | AST-based duplication detector | Always |
| ex_ast | AST-based code search/replace | Always |

### Version Pinning

Pinned versions below are starting points. Before adding a dep, check hex for current:
```bash
curl -s https://hex.pm/api/packages/<pkg> | jq -r .latest_stable_version
```
Hex `~>` operator (per `Version.match?/2`):
- `~> X.Y` allows everything up to (not including) the next major: `~> 2.0` = `>= 2.0.0 and < 3.0.0`; `~> 0.3` = `>= 0.3.0 and < 1.0.0`.
- `~> X.Y.Z` allows everything up to (not including) the next minor: `~> 2.0.0` = `>= 2.0.0 and < 2.1.0`; `~> 0.3.1` = `>= 0.3.1 and < 0.4.0`.

For 0.x packages, every minor bump can be breaking under hex semver — so prefer the three-segment form (`~> 0.3.1`) when you want to lock to a single 0.x minor and opt into bumps deliberately.

### mix.exs deps (libraries/non-Phoenix)

```elixir
defp deps do
  [
    {:ex_unit_json, "~> 0.4", only: [:dev, :test], runtime: false},
    {:dialyzer_json, "~> 0.2", only: [:dev, :test], runtime: false},
    {:styler, "~> 1.4", only: [:dev, :test], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.40", only: :dev, runtime: false},
    {:doctor, "~> 0.22", only: [:dev, :test], runtime: false},
    {:tidewave, "~> 0.5", only: :dev},
    {:bandit, "~> 1.10", only: :dev},      # non-Phoenix only
    {:ex_dna, "~> 1.1", only: [:dev, :test], runtime: false},
    {:ex_ast, "~> 0.3", only: [:dev, :test], runtime: false},
    {:descripex, "~> 0.6"},                # full dep — macros expand at compile time
    {:api_toolkit, "~> 0.1"}               # API services only
  ]
end
```

### Required: cli/0 for preferred_envs

Mix doesn't inherit `preferred_envs` from deps. Without this, `mix test.json`/`mix dialyzer.json` run in `:dev`:

```elixir
def cli do
  [preferred_envs: ["test.json": :test, "dialyzer.json": :dev]]
end
```

### Formatter

Add `Styler` to `.formatter.exs` plugins: `plugins: [Styler]`.

### Tidewave (Non-Phoenix)

Three files must agree on PORT. Registry: `~/.claude/tidewave-ports.md`. MCP registration is **project-scope** only (`.mcp.json`) — never user-scope; local/user scope collides across projects.

1. `~/.claude/tidewave-ports.md` — registry row
2. `mix.exs` alias:
   ```elixir
   tidewave: ["run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: PORT) end)'"]
   ```
3. `.mcp.json` (project root):
   ```json
   {"mcpServers":{"tidewave":{"type":"http","url":"http://localhost:PORT/tidewave/mcp"}}}
   ```

Run with `iex -S mix tidewave`. Restart Claude Code after creating/changing `.mcp.json`. Check scope with `claude mcp get tidewave`; remove user/local if present.

### Tidewave Recompile Gotcha

Tidewave runs in the same BEAM as the IEx session. After editing source, the old bytecode stays loaded — call `recompile()` via `project_eval` (or `r(SomeModule)` for one module). For the full MCP tool list, see the `tidewave-guide` skill.

### ex_doc llms.txt

`mix docs` generates `doc/llms.txt` alongside HTML — Markdown optimized for LLMs. Published packages have it at `https://hexdocs.pm/<package>/llms.txt`. Use for loading library context.

### ExDNA — Duplication Detection

```bash
mix ex_dna                            # scan for duplicates
mix ex_dna --literal-mode abstract    # catch renamed variables (Type II)
mix ex_dna --format json              # machine-readable
```

Config: `.ex_dna.exs` in project root. Suppress intentional dupes with `@no_clone true`. Credo integration: add `{ExDNA.Credo, []}` to `.credo.exs`.

### ExAST — AST Search & Replace

```bash
mix ex_ast.search 'IO.inspect(_)'           # find debug leftovers
mix ex_ast.replace 'dbg(expr)' 'expr'       # remove dbg, keep expression
mix ex_ast.replace --dry-run old new        # preview
```

Patterns: `_` = wildcard, named vars (`expr`) capture and carry to replacement. Structs/maps match partially.

### Quality Gates

- Dialyzer: 0 warnings (mandatory)
- Credo: 0 issues in `--strict`
- Doctor: all public modules documented
- Tests: 80%+ coverage (95% for critical business logic)
