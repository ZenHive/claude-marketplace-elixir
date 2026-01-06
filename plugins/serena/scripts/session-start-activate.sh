#!/bin/bash
# Serena auto-activation hook
# Outputs context telling Claude to activate the Serena project for the current directory

# Get current working directory
CWD=$(pwd)

# Output context for Claude to activate Serena
# Serena's activate_project accepts either a project name or a path
jq -n --arg cwd "$CWD" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ("Serena MCP detected. Please activate the Serena project for this directory by calling mcp__plugin_serena_serena__activate_project with project: \"" + $cwd + "\". After activation, call mcp__plugin_serena_serena__check_onboarding_performed to verify onboarding status.")
  }
}'
