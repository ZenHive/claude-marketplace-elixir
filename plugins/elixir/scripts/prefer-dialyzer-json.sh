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

# Check if this is a `mix dialyzer` command but NOT `mix dialyzer.json` or `mix dialyzer.something_else`
# Pattern: "mix dialyzer" optionally followed by space and args, but NOT followed by a dot
if ! echo "$COMMAND" | grep -qE 'mix\s+dialyzer(\s|$)'; then
  # Not a mix dialyzer command at all
  emit_suppress_json
  exit 0
fi

# Allow mix dialyzer.json and other mix dialyzer.* variants
if echo "$COMMAND" | grep -qE 'mix\s+dialyzer\.[a-z]'; then
  emit_suppress_json
  exit 0
fi

# Find Mix project root to confirm this is an Elixir project
PROJECT_ROOT=$(find_mix_project_root_from_dir "$HOOK_CWD") || {
  # Not in an Elixir project, allow the command
  emit_suppress_json
  exit 0
}

# Block mix dialyzer in Elixir projects - require mix dialyzer.json
jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Use `mix dialyzer.json` instead of `mix dialyzer`!\n\nThe dialyzer_json library provides AI-friendly JSON output that is much easier to parse and analyze.\n\n**Quick commands:**\n- `mix dialyzer.json --quiet` - JSON output only (no progress)\n- `mix dialyzer.json --quiet --fix-hint code` - Only real bugs (not spec issues)\n- `mix dialyzer.json --quiet --group-by file` - Group warnings by file\n\n**If dialyzer_json is not installed**, add to mix.exs:\n  {:dialyzer_json, \"~> 0.1.0\", only: [:dev, :test], runtime: false}\n\nAnd add cli/0 function:\n  def cli do\n    [preferred_envs: [\"dialyzer.json\": :dev]]\n  end\n\nSee: dialyzer-json.md include for full documentation."
  }
}'
exit 0
