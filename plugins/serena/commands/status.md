---
description: Show Serena project status and configuration
---

# Serena Status

Show the current Serena configuration and project status.

## Tasks

1. **Get current config**
   Call `mcp__plugin_serena_serena__get_current_config` to show:
   - Active project
   - Available projects
   - Active tools
   - Current modes

2. **Check onboarding**
   Call `mcp__plugin_serena_serena__check_onboarding_performed` to verify the project is properly set up.

3. **Show project mapping**
   Check if the current directory has a mapping in `~/.claude/serena-projects.json`.

4. **List memories**
   Call `mcp__plugin_serena_serena__list_memories` to show available project memories.

## Output Format

Present a clear summary:

```
Serena Status
=============
Project: <active project name>
Directory: <current working directory>
Mapping: <mapped project name or "using directory path">
Onboarding: <complete/needed>
Modes: <active modes>

Available Memories:
- memory1
- memory2
...
```
