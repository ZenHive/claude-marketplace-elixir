#!/usr/bin/env bash
set -eo pipefail

# Pre-commit validation for mix_audit dependency security scanner

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

precommit_setup_with_dep "mix_audit" || exit 0
cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
AUDIT_OUTPUT=$(mix deps.audit 2>&1)
AUDIT_EXIT_CODE=$?
set -e

if [ $AUDIT_EXIT_CODE -ne 0 ]; then
  OUTPUT=$(truncate_output "$AUDIT_OUTPUT" 30 "mix deps.audit")
  REASON="MixAudit plugin found vulnerable dependencies:\n\n${OUTPUT}"
  emit_deny_json "$REASON" "Commit blocked: MixAudit found vulnerable dependencies"
  exit 0
fi

emit_suppress_json
exit 0
