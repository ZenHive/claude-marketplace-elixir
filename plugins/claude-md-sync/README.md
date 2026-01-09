# claude-md-sync

Syncs project CLAUDE.md with global includes at session start.

## What it does

At the start of each Claude Code session, this plugin prompts Claude to:

1. Read your global `~/.claude/CLAUDE.md` to see the current `@include` directives
2. Read the project's `./CLAUDE.md` (if it exists)
3. Update the project CLAUDE.md if it's missing includes from the global file
4. Consider project type (Elixir projects need `elixir-*.md` includes, Phoenix needs `phoenix-*.md`, etc.)

## Why

When you update your global CLAUDE.md (add new includes, remove old ones, rename files), your project CLAUDE.md files can get out of sync. This plugin ensures Claude checks and updates them automatically.

## Installation

```bash
/plugin install claude-md-sync@deltahedge
```

## Behavior

- **Silent when in sync**: If the project CLAUDE.md already has all the right includes, Claude says nothing
- **Reports changes**: If updates are needed, Claude will report what it changed
- **Project-type aware**: Claude considers whether the project is Elixir, Phoenix, etc. when deciding which includes are relevant

## Hook Type

This is a **prompt-based** SessionStart hook. No external scripts - Claude does the reading and updating itself using its built-in tools.
