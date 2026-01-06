#!/bin/bash
# Serena auto-activation hook
# Outputs context telling Claude to activate the Serena project for the current directory

# Get current working directory
CWD=$(pwd)

# Config file location for project mappings
CONFIG_FILE="$HOME/.claude/serena-projects.json"

# Try to find a mapped project name for this directory
PROJECT=""
if [[ -f "$CONFIG_FILE" ]]; then
    # Look up the directory in the config (exact match or parent match)
    PROJECT=$(jq -r --arg cwd "$CWD" '
        to_entries |
        map(select($cwd | startswith(.key))) |
        sort_by(.key | length) |
        reverse |
        .[0].value // empty
    ' "$CONFIG_FILE" 2>/dev/null)
fi

# Fall back to directory path if no mapping found
if [[ -z "$PROJECT" ]]; then
    PROJECT="$CWD"
fi

# Output context for Claude to activate Serena
# Serena's activate_project accepts either a project name or a path
jq -n --arg project "$PROJECT" --arg cwd "$CWD" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ("Serena MCP detected. Please activate the Serena project by calling mcp__plugin_serena_serena__activate_project with project: \"" + $project + "\". After activation, call mcp__plugin_serena_serena__check_onboarding_performed to verify onboarding status." + (if $project != $cwd then " (Mapped from directory: " + $cwd + ")" else "" end))
  }
}'
