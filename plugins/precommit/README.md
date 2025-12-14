# precommit

Strict pre-commit validation for Elixir projects. Runs comprehensive quality gates before commits.

## Overview

This plugin enforces quality gates before every commit. It works in two modes:

**With `precommit` alias** (Phoenix 1.8+ projects): Runs your custom `mix precommit` alias.

**Without alias** (strict mode): Runs all quality checks directly:
- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix credo --strict`
- `mix doctor`

## Installation

```bash
/plugin marketplace add github:ZenHive/claude-marketplace-elixir
/plugin install precommit@deltahedge
```

## How It Works

1. Detects if `precommit` alias exists via `mix help precommit`
2. **If exists**: runs `mix precommit`, blocks commit on failure
3. **If not exists**: runs strict quality checks directly, blocks on any failure

**Coordination**: When this plugin runs with strict mode, other plugins (core, credo, etc.) should suppress their precommit checks to avoid duplicate validation.

## Customizing

Add a `precommit` alias to your `mix.exs` for custom checks:

```elixir
defp aliases do
  [
    precommit: [
      "compile --warnings-as-errors",
      "deps.unlock --unused",
      "format",
      "credo --strict",
      "doctor",
      "test --stale"
    ]
  ]
end
```

## Quality Checks in Strict Mode

| Check | Description |
|-------|-------------|
| `mix format --check-formatted` | Code formatting |
| `mix compile --warnings-as-errors` | No compiler warnings |
| `mix credo --strict` | Static code analysis |
| `mix doctor` | Documentation coverage |

## Bypassing

Use `--no-verify` to bypass pre-commit hooks:

```bash
git commit --no-verify -m "WIP: work in progress"
```

## License

MIT
