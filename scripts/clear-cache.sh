#!/usr/bin/env bash
# Clear the deltahedge plugin cache and registry entries
# Run this when plugins aren't updating properly or after major changes

set -e

CACHE_DIR="$HOME/.claude/plugins/cache/deltahedge"
INSTALLED_PLUGINS="$HOME/.claude/plugins/installed_plugins.json"

# Clear cache directory
if [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR"
  echo "Cleared plugin cache: $CACHE_DIR"
else
  echo "Cache directory not found (already clean): $CACHE_DIR"
fi

# Remove deltahedge from known_marketplaces.json
KNOWN_MARKETPLACES="$HOME/.claude/plugins/known_marketplaces.json"
if [ -f "$KNOWN_MARKETPLACES" ] && command -v jq &> /dev/null; then
  if jq -e '.deltahedge' "$KNOWN_MARKETPLACES" > /dev/null 2>&1; then
    jq 'del(.deltahedge)' "$KNOWN_MARKETPLACES" > /tmp/known_marketplaces_clean.json && \
      mv /tmp/known_marketplaces_clean.json "$KNOWN_MARKETPLACES"
    echo "Removed deltahedge from known_marketplaces.json"
  else
    echo "No deltahedge in known_marketplaces.json"
  fi
fi

# Remove deltahedge entries from installed_plugins.json
# This prevents "already installed" errors with stale project paths
if [ -f "$INSTALLED_PLUGINS" ] && command -v jq &> /dev/null; then
  # Check if there are any deltahedge entries
  COUNT=$(jq '[.plugins | keys[] | select(contains("deltahedge"))] | length' "$INSTALLED_PLUGINS" 2>/dev/null)

  if [ "$COUNT" -gt 0 ]; then
    # Filter out all deltahedge plugins in one jq call
    jq '.plugins = (.plugins | with_entries(select(.key | contains("deltahedge") | not)))' \
      "$INSTALLED_PLUGINS" > /tmp/installed_plugins_clean.json && \
      mv /tmp/installed_plugins_clean.json "$INSTALLED_PLUGINS"
    echo "Removed $COUNT deltahedge entries from installed_plugins.json"
  else
    echo "No deltahedge entries in installed_plugins.json"
  fi
else
  if [ ! -f "$INSTALLED_PLUGINS" ]; then
    echo "installed_plugins.json not found (nothing to clean)"
  elif ! command -v jq &> /dev/null; then
    echo "Warning: jq not installed, skipping installed_plugins.json cleanup"
  fi
fi

echo ""
echo "Next steps:"
echo "  1. Restart Claude Code"
echo "  2. Run: /plugin marketplace add ZenHive/claude-marketplace-elixir"
echo "  3. Run: /plugin install core@deltahedge"
echo ""
echo "Note: Always use GitHub format (owner/repo) instead of local paths for reliable installation."
