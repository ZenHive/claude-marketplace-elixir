# Serena Plugin

Serena MCP integration for Claude Code - automatic project activation, workflow helpers, and memory management.

## Features

### 1. SessionStart Auto-Activation

When Claude Code starts, this plugin automatically prompts Claude to:

1. **Activate the Serena project** for the current working directory
2. **Check onboarding status** to ensure the project is properly set up

This eliminates the manual step of activating Serena at the start of each session.

### 2. Project Directory Mapping

Map directory paths to Serena project names in `~/.claude/serena-projects.json`:

```json
{
  "/Users/you/code/my-project": "my_serena_project",
  "/Users/you/work/another": "another_project"
}
```

The hook uses longest-prefix matching, so a mapping for `/Users/you/code` matches `/Users/you/code/subdir`.

Manage mappings with: `/serena:project-map`

### 3. Think Tool Reminders

Automatic reminders to use Serena's reflective tools:

- **After research** (`find_symbol`, `search_for_pattern`, etc.) - Reminds to call `think_about_collected_information`
- **Before edits** (`replace_symbol_body`, `replace_content`, etc.) - Reminds to call `think_about_task_adherence`

### 4. Memory Management

Commands for managing Serena project memories:

- `/serena:memory list` - Show all memories
- `/serena:memory read <name>` - Read a specific memory
- `/serena:memory write <name> <content>` - Write/update a memory
- `/serena:memory delete <name>` - Delete a memory
- `/serena:memory search <term>` - Find relevant memories

### 5. Project Status

Quick overview of Serena configuration:

- `/serena:status` - Shows active project, onboarding status, modes, and memories

### 6. Conversation Handoff

Prepare for ending a conversation or handing off to a new Claude instance:

- `/serena:prep-handoff` - Reviews conversation, proposes memory updates, persists important context

## Installation

```bash
/plugin install serena@deltahedge
```

## Requirements

- Serena MCP server must be configured and running
- Projects should be registered in Serena

## Commands

| Command | Description |
|---------|-------------|
| `/serena:project-map` | Manage directory → project name mappings |
| `/serena:memory` | Manage project memories (list, read, write, delete) |
| `/serena:status` | Show Serena configuration and project status |
| `/serena:prep-handoff` | Prepare for conversation handoff with memory persistence |

## Hooks

| Hook | Event | Trigger | Description |
|------|-------|---------|-------------|
| Session Start | `SessionStart` | Session begins | Auto-activates Serena project |
| Think After Research | `PostToolUse` | find_symbol, search_for_pattern, etc. | Reminds to reflect on collected info |
| Think Before Edit | `PreToolUse` | replace_symbol_body, replace_content, etc. | Reminds to verify task adherence |

## Configuration

### Project Mappings

Create `~/.claude/serena-projects.json` to map directories to project names:

```json
{
  "/path/to/project": "serena_project_name"
}
```

Or use the command:
```
/serena:project-map add /path/to/project my_project_name
```

## How It Works

### Auto-Activation Flow

1. SessionStart hook captures current working directory
2. Checks `~/.claude/serena-projects.json` for a mapping (longest prefix match)
3. Falls back to directory path if no mapping found
4. Outputs context telling Claude to call `activate_project` and `check_onboarding_performed`

### Think Tool Integration

Serena provides three "think" tools for reflection:
- `think_about_collected_information` - After research, evaluate if info is sufficient
- `think_about_task_adherence` - Before edits, verify you're on track
- `think_about_whether_you_are_done` - At completion, confirm task is finished

This plugin surfaces reminders at the right moments to encourage their use.
