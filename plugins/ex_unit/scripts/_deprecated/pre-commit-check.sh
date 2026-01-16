#!/usr/bin/env bash
set -eo pipefail

# Pre-commit test validation for ExUnit
# Runs stale tests (tests for changed modules) before git commits

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

precommit_setup || exit 0

if [ ! -d "$PROJECT_ROOT/test" ]; then
  emit_suppress_json
  exit 0
fi

cd "$PROJECT_ROOT"

# Disable errexit to capture exit code
set +e
TEST_OUTPUT=$(mix test --stale 2>&1)
TEST_EXIT=$?
set -e

if [ $TEST_EXIT -eq 0 ]; then
  emit_suppress_json
  exit 0
fi

OUTPUT=$(truncate_output "$TEST_OUTPUT" 30 "mix test --stale")
REASON="ExUnit plugin found test failures:\n\n${OUTPUT}"
emit_deny_json "$REASON" "Commit blocked: ExUnit tests failed"
exit 0
