#!/bin/bash
# Remind Claude to use think_about_collected_information after research

jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "After a sequence of search/find operations, consider calling mcp__plugin_serena_serena__think_about_collected_information to evaluate whether the gathered information is sufficient and relevant for the task."
  }
}'
