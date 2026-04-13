#!/usr/bin/env bash
# Fix known plugin cache issues that recur after plugin updates
# Run after /reload-plugins shows errors, or after plugin updates
#
# Known issues fixed:
# 1. go-specialist@sylvain-marketplace: duplicate hooks field in plugin.json
# 2. ralph-loop@claude-plugins-official: stop hook missing execute permission

set -e

CACHE_DIR="$HOME/.claude/plugins/cache"
FIXED=0

# --- go-specialist: remove "hooks" field from plugin.json ---
for dir in "$CACHE_DIR"/sylvain-marketplace/go-specialist/*/; do
  [ -d "$dir" ] || continue
  PJSON="$dir.claude-plugin/plugin.json"
  [ -f "$PJSON" ] || continue

  if jq -e '.hooks' "$PJSON" > /dev/null 2>&1; then
    jq 'del(.hooks)' "$PJSON" > /tmp/fix-plugin.json && mv /tmp/fix-plugin.json "$PJSON"
    echo "Fixed: go-specialist $(basename "$dir") — removed duplicate hooks field"
    FIXED=$((FIXED + 1))
  fi
done

# --- ralph-loop: chmod +x stop hook ---
for dir in "$CACHE_DIR"/claude-plugins-official/ralph-loop/*/; do
  [ -d "$dir" ] || continue
  HOOK="$dir/hooks/stop-hook.sh"
  [ -f "$HOOK" ] || continue

  if [ ! -x "$HOOK" ]; then
    chmod +x "$HOOK"
    echo "Fixed: ralph-loop $(basename "$dir") — added execute permission to stop-hook.sh"
    FIXED=$((FIXED + 1))
  fi
done

if [ "$FIXED" -eq 0 ]; then
  echo "No issues found — all clean."
else
  echo ""
  echo "Fixed $FIXED issue(s). Run /reload-plugins to verify."
fi
