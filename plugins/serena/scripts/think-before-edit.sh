#!/bin/bash
# Remind Claude to use think_about_task_adherence before editing

jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Before making code edits, consider calling mcp__plugin_serena_serena__think_about_task_adherence to verify you are still on track with the original task, especially if the conversation has been long."
  }
}'
