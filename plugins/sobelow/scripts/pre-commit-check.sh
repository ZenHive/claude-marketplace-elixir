#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

precommit_setup_with_dep "sobelow" || exit 0
cd "$PROJECT_ROOT"

# Run Sobelow with --skip flag (respects .sobelow-skips and #sobelow_skip comments)
# Note: We don't use --exit flag - threshold configuration is delegated to .sobelow-conf
# The hook blocks if ANY findings are reported (user controls what's reported via config)
CMD="mix sobelow --format json"
[[ -f .sobelow-skips ]] && CMD="$CMD --skip"

# Disable errexit to capture exit code
set +e
SOBELOW_OUTPUT=$($CMD 2>&1)
set -e

# Check if there are any findings by parsing JSON output
# Extract JSON from output (Sobelow may emit warnings before JSON)
JSON_OUTPUT=$(echo "$SOBELOW_OUTPUT" | sed -n '/{/,$ p')
HAS_FINDINGS=false
if echo "$JSON_OUTPUT" | jq -e '.findings | (.high_confidence + .medium_confidence + .low_confidence) | length > 0' > /dev/null 2>&1; then
  HAS_FINDINGS=true
fi

if [ "$HAS_FINDINGS" = true ]; then
  OUTPUT=$(truncate_output "$SOBELOW_OUTPUT" 30 "mix sobelow")
  OUTPUT="${OUTPUT}

WARNING: Sobelow found security issues. Options:
  1. Fix the issues (recommended)
  2. Mark false positives: mix sobelow --mark-skip-all
  3. Skip specific types: mix sobelow --ignore Type1,Type2 --mark-skip-all
  4. Adjust threshold: Create .sobelow-conf with --threshold flag"

  REASON="Sobelow plugin found security issues:\n\n${OUTPUT}"
  emit_deny_json "$REASON" "Commit blocked: Sobelow found security issues"
  exit 0
fi

emit_suppress_json
exit 0
