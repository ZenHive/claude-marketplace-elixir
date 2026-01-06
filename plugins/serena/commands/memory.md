---
description: Manage Serena project memories
arguments:
  - name: action
    description: "Action: list, read, write, delete, or search"
    required: true
  - name: name
    description: "Memory name (for read/write/delete)"
    required: false
  - name: content
    description: "Content to write (for write action)"
    required: false
---

# Serena Memory Management

Manage memories for the active Serena project. Memories persist information across conversations.

## Actions

Based on the action argument "$ARGUMENTS.action":

### `list` - List all memories
Call `mcp__plugin_serena_serena__list_memories` to show all available memories for the current project.

### `read` - Read a memory
If "$ARGUMENTS.name" is provided, call `mcp__plugin_serena_serena__read_memory` with that memory name.

If no name provided, first list memories, then ask the user which one to read.

### `write` - Write/update a memory
Write content to a memory. If "$ARGUMENTS.name" and "$ARGUMENTS.content" are provided, call `mcp__plugin_serena_serena__write_memory`.

If content not provided, ask the user what to write. The memory name should be descriptive and meaningful (e.g., "api-patterns", "architecture-decisions", "common-issues").

### `delete` - Delete a memory
If "$ARGUMENTS.name" is provided, call `mcp__plugin_serena_serena__delete_memory` with that memory name.

Confirm with user before deleting. This action is irreversible.

### `search` - Search memory contents
List memories and show which ones might be relevant based on "$ARGUMENTS.name" as a search term. Read and summarize relevant memories.

## Memory Best Practices

Good candidates for memories:
- **Architecture decisions** - Key design choices and rationale
- **Common patterns** - Recurring code patterns in the project
- **API conventions** - How APIs are structured and consumed
- **Testing strategies** - How tests are organized and run
- **Known issues** - Gotchas and workarounds
- **Suggested commands** - Useful shell commands for the project

## Examples

- `/serena:memory list` - Show all memories
- `/serena:memory read architecture` - Read the "architecture" memory
- `/serena:memory write api-patterns "REST API uses..."` - Write API patterns
- `/serena:memory delete old-notes` - Delete a memory
- `/serena:memory search testing` - Find memories related to testing
