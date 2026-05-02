#!/usr/bin/env bash
# Generate AGENTS.md for Codex by inlining @-imports from the project's CLAUDE.md.
#
# Run this from inside a target repo. Reads ./CLAUDE.md, resolves @-imports
# (e.g. @~/.claude/includes/critical-rules.md), inlines their content, and
# writes ./AGENTS.md. Codex doesn't inherit our local hooks, so AGENTS.md
# carries the rules our hooks would have enforced.
#
# Usage:
#   ./sync-agents-md.sh             # write AGENTS.md
#   ./sync-agents-md.sh --dry-run   # print to stdout instead

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

CLAUDE_MD="./CLAUDE.md"
AGENTS_MD="./AGENTS.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "ERROR: $CLAUDE_MD not found in current directory" >&2
  echo "Run this script from inside a repo with a CLAUDE.md at its root." >&2
  exit 1
fi

resolve_path() {
  local raw="$1"
  if [[ "$raw" == "~/"* ]]; then
    printf '%s' "$HOME/${raw:2}"
  else
    printf '%s' "$raw"
  fi
}

errors=0
output=""

output+="<!-- Auto-generated from CLAUDE.md by claude-marketplace-elixir/scripts/sync-agents-md.sh — do not edit manually -->"$'\n'
output+=$'\n'

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" =~ ^@([^[:space:]]+)[[:space:]]*$ ]]; then
    raw_path="${BASH_REMATCH[1]}"
    resolved=$(resolve_path "$raw_path")

    if [[ ! -r "$resolved" ]]; then
      echo "ERROR: cannot read @-import: $raw_path (resolved to $resolved)" >&2
      errors=$((errors + 1))
      continue
    fi

    output+="<!-- @-import: ${raw_path} -->"$'\n'
    output+="$(cat "$resolved")"$'\n'
    output+=$'\n'
  else
    output+="${line}"$'\n'
  fi
done < "$CLAUDE_MD"

if [[ "$errors" -gt 0 ]]; then
  echo "Aborting — $errors @-import(s) unreadable." >&2
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  printf '%s' "$output"
  echo ""
  echo "--- Summary ---" >&2
  echo "Dry run — would write to $AGENTS_MD" >&2
else
  printf '%s' "$output" > "$AGENTS_MD"
  echo "Wrote $AGENTS_MD"
fi
