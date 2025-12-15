#!/usr/bin/env bash
set -eo pipefail

# Post-edit validation for Ash code generation
# Runs after editing .ex/.exs files to detect when ash.codegen is needed
# Provides informational context to Claude (non-blocking)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../_shared/lib.sh"
source "$SCRIPT_DIR/../../_shared/postedit-utils.sh"

postedit_setup_with_dep "ash" || { emit_suppress_json; exit 0; }
cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
CODEGEN_OUTPUT=$(mix ash.codegen --check 2>&1)
CODEGEN_EXIT=$?
set -e

if [ $CODEGEN_EXIT -ne 0 ]; then
  OUTPUT=$(truncate_output "$CODEGEN_OUTPUT" 50 "mix ash.codegen --check")
  emit_context_json "$OUTPUT"
else
  emit_suppress_json
fi

exit 0
