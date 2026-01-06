# Serena Plugin

Serena MCP integration for Claude Code - automatic project activation and workflow helpers.

## Features

### SessionStart Auto-Activation

When Claude Code starts, this plugin automatically prompts Claude to:

1. **Activate the Serena project** for the current working directory
2. **Check onboarding status** to ensure the project is properly set up

This eliminates the manual step of activating Serena at the start of each session.

## Installation

```bash
/plugin install serena@deltahedge
```

## Requirements

- Serena MCP server must be configured and running
- Projects should be registered in Serena (via `activate_project` with a path, or pre-configured)

## How It Works

The SessionStart hook:

1. Captures the current working directory
2. Outputs context instructing Claude to call `mcp__plugin_serena_serena__activate_project`
3. Also prompts Claude to verify onboarding with `mcp__plugin_serena_serena__check_onboarding_performed`

Serena's `activate_project` accepts either:
- A registered project name (e.g., `ccxt_ex`)
- A directory path (Serena will auto-detect if it's a known project)

## Project Registration

If your directory isn't recognized, you can register it in Serena by:

1. Running `activate_project` with the full path once
2. Completing onboarding if prompted
3. The project will be remembered for future sessions

## Future Enhancements

Planned features for this plugin:

- **Project mapping config** - Map directory paths to project names for non-standard layouts
- **Think tool reminders** - Prompt Claude to use Serena's think tools after research sequences
- **Memory management helpers** - Commands for managing Serena memories

## Hooks

| Hook | Event | Description |
|------|-------|-------------|
| Session Start | `SessionStart` | Auto-activates Serena project for current directory |
