---
description: Prepare for conversation handoff by persisting important context to memories
---

# Prepare for Conversation Handoff

When ending a conversation or preparing for a new Claude instance to continue work, use this command to persist important context to Serena memories.

## Tasks

1. **Review conversation**
   Look back at what was discussed and accomplished in this conversation:
   - Key decisions made
   - Important discoveries about the codebase
   - Patterns identified
   - Unfinished work or next steps
   - Issues encountered and solutions found

2. **Check existing memories**
   Call `mcp__plugin_serena_serena__list_memories` to see what's already documented.

3. **Identify gaps**
   Determine what important information from this conversation should be persisted but isn't in existing memories.

4. **Propose memory updates**
   Present to the user:
   - New memories to create
   - Existing memories to update
   - Suggested content for each

5. **Write memories with approval**
   After user approval, use `mcp__plugin_serena_serena__write_memory` or `mcp__plugin_serena_serena__edit_memory` to persist the information.

6. **Call prepare_for_new_conversation**
   Finally, call `mcp__plugin_serena_serena__prepare_for_new_conversation` to get any additional instructions for preparing the handoff.

## Memory Naming Conventions

Use descriptive, kebab-case names:
- `architecture-overview` - High-level system design
- `api-patterns` - How APIs are structured
- `testing-strategy` - How to run and write tests
- `current-work` - What's being worked on
- `known-issues` - Bugs and workarounds
- `suggested-commands` - Useful shell commands

## Example Output

```
Conversation Summary
====================
- Implemented WebSocket reconnection logic
- Discovered rate limiting issue with API
- Decided to use exponential backoff pattern

Proposed Memory Updates
=======================
1. NEW: websocket-patterns
   Content: "WebSocket connections use exponential backoff for reconnection..."

2. UPDATE: known-issues
   Add: "API rate limits to 100 req/min, implement backoff..."

Proceed with memory updates? [y/n]
```
