#!/usr/bin/env bash
set -eo pipefail

# Pre-commit validation for Dialyzer static type analysis
# Blocks commits if type issues are found (JSON permissionDecision: deny)
# Uses 120s timeout due to Dialyzer's analysis time

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../_shared/lib.sh"
source "$SCRIPT_DIR/../../_shared/precommit-utils.sh"

precommit_setup_with_dep "dialyxir" || exit 0
cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
DIALYZER_OUTPUT=$(mix dialyzer 2>&1)
DIALYZER_EXIT_CODE=$?
set -e

if [ $DIALYZER_EXIT_CODE -ne 0 ]; then
  OUTPUT=$(truncate_output "$DIALYZER_OUTPUT" 30 "mix dialyzer")
  REASON="Dialyzer plugin found type errors:\n\n${OUTPUT}"
  emit_deny_json "$REASON" "Commit blocked: Dialyzer found type errors"
  exit 0
fi

emit_suppress_json
exit 0
