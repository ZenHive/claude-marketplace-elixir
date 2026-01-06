---
description: Manage Serena project directory mappings
arguments:
  - name: action
    description: "Action: add, remove, list, or show"
    required: true
  - name: path
    description: "Directory path (for add/remove)"
    required: false
  - name: project
    description: "Serena project name (for add)"
    required: false
---

# Serena Project Mapping Management

Manage the `~/.claude/serena-projects.json` config that maps directories to Serena project names.

## Actions

Based on the action argument "$ARGUMENTS.action":

### `list` - Show all mappings
Read and display the contents of `~/.claude/serena-projects.json`. If the file doesn't exist, say "No project mappings configured."

### `show` - Show mapping for current directory
Check if the current working directory has a mapping in the config file. Show the mapped project name or "No mapping found for this directory."

### `add` - Add a new mapping
Add a mapping from "$ARGUMENTS.path" (or current directory if not provided) to "$ARGUMENTS.project".

1. Read existing config from `~/.claude/serena-projects.json` (create empty object if doesn't exist)
2. Add the new mapping: `{ "path": "project_name" }`
3. Write back to the config file
4. Confirm the mapping was added

If project name not provided, ask the user what Serena project name to map to.

### `remove` - Remove a mapping
Remove the mapping for "$ARGUMENTS.path" (or current directory if not provided).

1. Read existing config
2. Remove the key matching the path
3. Write back to the config file
4. Confirm the mapping was removed

## Config File Format

```json
{
  "/Users/user/code/my-project": "my_serena_project",
  "/Users/user/work/another": "another_project"
}
```

The SessionStart hook uses longest-prefix matching, so a mapping for `/Users/user/code` would match `/Users/user/code/subdir`.

## Examples

- `/serena:project-map list` - Show all mappings
- `/serena:project-map show` - Show mapping for current directory
- `/serena:project-map add . ccxt_ex` - Map current directory to "ccxt_ex"
- `/serena:project-map add /path/to/dir polydash` - Map specific path to "polydash"
- `/serena:project-map remove` - Remove mapping for current directory
