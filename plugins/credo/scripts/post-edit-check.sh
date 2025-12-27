#!/usr/bin/env bash
set -eo pipefail

# Post-edit validation for Credo static analysis
# Runs after editing .ex/.exs files to detect code quality issues
# Provides informational context to Claude (non-blocking)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/postedit-utils.sh"

postedit_setup_with_dep "credo" || { emit_suppress_json; exit 0; }
cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
# Exclude TODO/FIXME checks - these are intentional documentation, not code quality issues
CREDO_OUTPUT=$(mix credo "$HOOK_FILE_PATH" --ignore-checks Credo.Check.Design.TagTODO,Credo.Check.Design.TagFIXME 2>&1)
CREDO_EXIT_CODE=$?
set -e

if [ $CREDO_EXIT_CODE -ne 0 ] || echo "$CREDO_OUTPUT" | grep -qE '(issues|warnings|errors)'; then
  OUTPUT=$(truncate_output "$CREDO_OUTPUT" 30 "mix credo \"$HOOK_FILE_PATH\"")
  CONTEXT="Credo analysis for $HOOK_FILE_PATH:

$OUTPUT"
  emit_context_json "$CONTEXT"
else
  emit_suppress_json
fi

exit 0
