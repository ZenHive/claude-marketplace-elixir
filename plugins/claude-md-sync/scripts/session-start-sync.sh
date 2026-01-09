#!/usr/bin/env bash
set -euo pipefail

# Output a directive prompt for Claude to sync project CLAUDE.md with global includes
jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "IMMEDIATE ACTION REQUIRED: Sync project CLAUDE.md with global includes.\n\nDO THIS NOW before responding to the user:\n1. Read ~/.claude/CLAUDE.md - extract all @include directives\n2. Read ./CLAUDE.md - extract its @include directives\n3. Compare: find includes in global that are missing from project\n4. If missing includes exist AND match project type (Elixir/Phoenix/etc.), add them to project CLAUDE.md using Edit tool\n5. If no changes needed, proceed silently\n\nOnly report to user if you made changes. Do not ask permission - just sync."
  }
}'
