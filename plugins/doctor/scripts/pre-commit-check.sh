#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

precommit_setup_with_dep "doctor" || exit 0
cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
DOCTOR_OUTPUT=$(mix doctor 2>&1)
DOCTOR_EXIT_CODE=$?
set -e

if [ $DOCTOR_EXIT_CODE -ne 0 ]; then
  OUTPUT=$(truncate_output "$DOCTOR_OUTPUT" 30 "mix doctor")
  REASON="Mix Doctor found documentation issues:\n\n${OUTPUT}"
  emit_deny_json "$REASON" "Commit blocked: Mix Doctor found documentation issues"
  exit 0
fi

emit_suppress_json
exit 0
