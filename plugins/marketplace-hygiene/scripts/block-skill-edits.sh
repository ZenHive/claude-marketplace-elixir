#!/usr/bin/env bash
# PreToolUse hook: deny direct Edit|Write|MultiEdit on any plugin SKILL.md
# that is listed in scripts/skill-include-map.sh — those bodies are
# auto-synced from ~/.claude/includes/ and would be overwritten on the next
# `./scripts/sync-skills-from-includes.sh` run.
#
# Unmapped SKILL.md files (legitimate hand-edited skills) pass through.

set -eo pipefail

emit_suppress() { jq -n '{"suppressOutput": true}'; exit 0; }

emit_deny() {
  local reason="$1"
  local msg="$2"
  jq -n --arg reason "$reason" --arg msg "$msg" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    },
    systemMessage: $msg
  }'
  exit 0
}

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE" || "$FILE" == "null" ]] && emit_suppress

# Locate the marketplace repo this hook ships from (this script lives at
# plugins/marketplace-hygiene/scripts/block-skill-edits.sh, so two levels up
# from SCRIPT_DIR is the plugin root; one more is the marketplace repo root).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")"
MAP_FILE="$REPO_ROOT/scripts/skill-include-map.sh"

# Without a mapping file we cannot enforce the rule precisely — pass through.
[[ -z "$REPO_ROOT" || ! -f "$MAP_FILE" ]] && emit_suppress

# Normalize FILE to a path relative to REPO_ROOT when possible (the mapping
# entries are stored repo-relative).
FILE_ABS=$(realpath "$FILE" 2>/dev/null || echo "$FILE")
REL="$FILE_ABS"
case "$FILE_ABS" in
  "$REPO_ROOT"/*) REL="${FILE_ABS#"$REPO_ROOT"/}" ;;
esac

# Source the mapping (defines MAPPINGS array).
# shellcheck source=/dev/null
source "$MAP_FILE"

for entry in "${MAPPINGS[@]}"; do
  skill_path="${entry%%:*}"
  include="${entry##*:}"
  if [[ "$REL" == "$skill_path" ]]; then
    emit_deny \
      "This SKILL.md is auto-synced from ~/.claude/includes/$include — direct edits will be overwritten by ./scripts/sync-skills-from-includes.sh on the next run.

Edit the canonical include instead:
  ~/.claude/includes/$include

Then run the sync script to regenerate the SKILL.md body:
  ./scripts/sync-skills-from-includes.sh" \
      "marketplace-hygiene: SKILL.md is auto-synced from ~/.claude/includes/$include"
  fi
done

emit_suppress
