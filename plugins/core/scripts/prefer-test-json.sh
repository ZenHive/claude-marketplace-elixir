#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"

# Read hook input from stdin
read_hook_input

COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command')
HOOK_CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd')

# Skip if command is null or empty
is_null_or_empty "$COMMAND" && { emit_suppress_json; exit 0; }

# Check if this is a `mix test` command but NOT `mix test.json` or `mix test.something_else`
# Pattern: "mix test" optionally followed by space and args, but NOT followed by a dot
if ! echo "$COMMAND" | grep -qE 'mix\s+test(\s|$)'; then
  # Not a mix test command at all
  emit_suppress_json
  exit 0
fi

# Allow mix test.json and other mix test.* variants
if echo "$COMMAND" | grep -qE 'mix\s+test\.[a-z]'; then
  emit_suppress_json
  exit 0
fi

# Find Mix project root to confirm this is an Elixir project
PROJECT_ROOT=$(find_mix_project_root_from_dir "$HOOK_CWD") || {
  # Not in an Elixir project, allow the command
  emit_suppress_json
  exit 0
}

# Block mix test in Elixir projects - require mix test.json
jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Use `mix test.json` instead of `mix test`!\n\nThe ex_unit_json library provides AI-friendly JSON output that is much easier to parse and analyze.\n\n**Quick commands:**\n- `mix test.json --quiet --summary-only` - Quick health check\n- `mix test.json --failed --quiet --first-failure` - Fast iteration\n- `mix test.json --quiet --failures-only` - All failure details\n\n**If ex_unit_json is not installed**, add to mix.exs:\n  {:ex_unit_json, \"~> 0.1.0\", only: [:dev, :test], runtime: false}\n\nAnd add cli/0 function:\n  def cli do\n    [preferred_envs: [\"test.json\": :test]]\n  end\n\nSee: ex-unit-json.md include for full documentation."
  }
}'
exit 0
