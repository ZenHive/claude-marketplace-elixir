#!/usr/bin/env bash
set -eo pipefail

# Pre-commit validation for Ash code generation
# Blocks git commits if ash.codegen is out of sync with resource definitions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../_shared/lib.sh"
source "$SCRIPT_DIR/../../_shared/precommit-utils.sh"

precommit_setup_with_dep "ash" || exit 0
cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
CODEGEN_OUTPUT=$(mix ash.codegen --check 2>&1)
CODEGEN_EXIT=$?
set -e

if [ $CODEGEN_EXIT -ne 0 ]; then
  REASON="Ash plugin detected code generation is out of sync:\n\n${CODEGEN_OUTPUT}\n\nRun 'mix ash.codegen' to update generated code."
  emit_deny_json "$REASON" "Commit blocked: Ash code generation required"
  exit 0
fi

emit_suppress_json
exit 0
