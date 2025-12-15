#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

precommit_setup || exit 0
cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
CREDO_OUTPUT=$(mix credo --strict 2>&1)
CREDO_EXIT_CODE=$?
set -e

if [ $CREDO_EXIT_CODE -ne 0 ]; then
  OUTPUT=$(truncate_output "$CREDO_OUTPUT" 30 "mix credo --strict")
  REASON="Credo plugin found code quality issues:\n\n${OUTPUT}"
  emit_deny_json "$REASON" "Commit blocked: Credo found code quality issues"
  exit 0
fi

emit_suppress_json
exit 0
