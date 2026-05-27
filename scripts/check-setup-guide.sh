#!/usr/bin/env bash
# Check if ~/.claude/setup-guide.md is in sync with ~/.claude/includes/
# Reports undocumented includes (on disk but not in guide) and
# missing includes (in guide but not on disk).
#
# Usage:
#   ./scripts/check-setup-guide.sh          # check and report
#   ./scripts/check-setup-guide.sh --quiet  # exit code only (0=ok, 1=drift)

set -euo pipefail

SETUP_GUIDE="$HOME/.claude/setup-guide.md"
INCLUDES_DIR="$HOME/.claude/includes"

QUIET=false
if [[ "${1:-}" == "--quiet" ]]; then
  QUIET=true
fi

if [[ ! -f "$SETUP_GUIDE" ]]; then
  echo "ERROR: $SETUP_GUIDE not found"
  exit 1
fi

if [[ ! -d "$INCLUDES_DIR" ]]; then
  echo "ERROR: $INCLUDES_DIR not found"
  exit 1
fi

# List actual files on disk
on_disk=$(ls "$INCLUDES_DIR"/*.md 2>/dev/null | xargs -n1 basename | sort -u)

# Extract include filenames referenced in setup-guide.md
# Two forms count as documented:
#   1. Path form: `includes/foo.md` or includes/foo.md
#   2. Bare backtick form: `foo.md` — but only when foo.md actually exists in
#      includes/ on disk (filters out incidental mentions like `ROADMAP.md`)
# Excludes generic example "filename.md" from prose.
documented_paths=$(grep -oE 'includes/[a-zA-Z0-9_-]+\.md' "$SETUP_GUIDE" \
  | sed 's|includes/||')
documented_bare=$(grep -oE '`[a-zA-Z0-9_-]+\.md`' "$SETUP_GUIDE" \
  | tr -d '`' \
  | sort -u)
documented_bare_valid=$(comm -12 <(echo "$documented_bare") <(echo "$on_disk"))
documented=$(printf '%s\n%s\n' "$documented_paths" "$documented_bare_valid" \
  | grep -v '^filename\.md$' \
  | grep -v '^$' \
  | sort -u)

# Find undocumented (on disk but not in setup-guide)
undocumented=$(comm -23 <(echo "$on_disk") <(echo "$documented"))

# Find missing (in setup-guide but not on disk)
missing=$(comm -13 <(echo "$on_disk") <(echo "$documented"))

if [[ -z "$undocumented" && -z "$missing" ]]; then
  if [[ "$QUIET" == false ]]; then
    echo "OK: setup-guide.md is in sync with includes/"
  fi
  exit 0
fi

if [[ "$QUIET" == true ]]; then
  exit 1
fi

# Report
drift=0

if [[ -n "$undocumented" ]]; then
  echo "Undocumented includes (on disk but NOT in setup-guide.md):"
  while IFS= read -r file; do
    echo "  - $file"
    drift=$((drift + 1))
  done <<< "$undocumented"
  echo ""
fi

if [[ -n "$missing" ]]; then
  echo "Missing includes (in setup-guide.md but NOT on disk):"
  while IFS= read -r file; do
    echo "  - $file"
    drift=$((drift + 1))
  done <<< "$missing"
  echo ""
fi

echo "--- Summary ---"
echo "Drift: $drift file(s) out of sync"
echo "Fix:   Edit ~/.claude/setup-guide.md"
exit 1
