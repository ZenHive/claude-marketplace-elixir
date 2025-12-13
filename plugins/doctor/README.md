# doctor

Mix Doctor documentation quality validation plugin for Claude Code.

## Installation

```bash
claude
/plugin install doctor@deltahedge
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- doctor installed in your project (add `{:doctor, "~> 0.22", only: :dev}` to mix.exs)
- Run from an Elixir project directory (with mix.exs)

## Features

### Automatic Hooks

**PreToolUse - Before git commits:**
- Runs `mix doctor` before any `git commit` command
- **Blocks commits** when documentation issues are found
- Sends issues to Claude via JSON permissionDecision for review

## Hooks Behavior

### Pre-commit Check (Blocking)
```bash
mix doctor
```
- Runs before any `git commit` command
- **Blocks commits** when Mix Doctor finds documentation issues
- Sends violations to Claude via JSON permissionDecision for review
- Output truncated to 30 lines if needed
- Exits silently for non-Elixir projects or projects without doctor
- **Pattern**: Uses JSON permissionDecision with deny status to block commits
- **Context Detection**: Automatically finds Mix project root by traversing upward from current directory
- **Note**: Skips if project has a `precommit` alias (defers to precommit plugin)

## What Mix Doctor Checks

Mix Doctor validates documentation quality including:
- Missing module documentation
- Missing function documentation
- Documentation format issues
- Spec coverage

## Integration with Other Plugins

The doctor plugin integrates well with:
- **precommit** - Doctor defers to precommit alias if it exists
- **credo** - Combine for comprehensive code quality checks
- **ex_doc** - Ensure documentation builds correctly
