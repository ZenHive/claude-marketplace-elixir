#!/usr/bin/env bash
# Clear the deltahedge plugin cache
# Run this when plugins aren't updating properly or after major changes

set -e

CACHE_DIR="$HOME/.claude/plugins/cache/deltahedge"

if [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR"
  echo "Cleared plugin cache: $CACHE_DIR"
else
  echo "Cache directory not found (already clean): $CACHE_DIR"
fi

echo ""
echo "Next steps:"
echo "  1. Restart Claude Code"
echo "  2. Run: /plugin marketplace remove deltahedge"
echo "  3. Run: /plugin marketplace add /path/to/claude-marketplace-elixir"
