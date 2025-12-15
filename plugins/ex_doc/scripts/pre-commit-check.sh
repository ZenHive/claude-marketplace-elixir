#!/usr/bin/env bash
set -eo pipefail

# ExDoc Pre-Commit Check

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../_shared/lib.sh"
source "$SCRIPT_DIR/../../_shared/precommit-utils.sh"

precommit_setup_with_dep "ex_doc" || exit 0
cd "$PROJECT_ROOT"

# Acquire lock to prevent concurrent mix docs processes from racing
# This prevents file conflicts when multiple hooks run in parallel
# Use /tmp for lock directory to avoid cluttering project directory
# Use mkdir for cross-platform atomic locking (works on both macOS and Linux)
LOCK_DIR="/tmp/mix_docs_$(echo "$PROJECT_ROOT" | shasum -a 256 | cut -d' ' -f1).lock"

# Try to acquire lock, wait up to 60 seconds if another process holds it
LOCK_TIMEOUT=60
LOCK_WAIT=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  if [ $LOCK_WAIT -ge $LOCK_TIMEOUT ]; then
    echo "ERROR: Timeout waiting for documentation generation lock" >&2
    exit 1
  fi
  sleep 1
  LOCK_WAIT=$((LOCK_WAIT + 1))
done

trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# Disable errexit to capture exit code
set +e
DOCS_OUTPUT=$(mix docs --warnings-as-errors 2>&1)
DOCS_EXIT_CODE=$?
set -e

if [ $DOCS_EXIT_CODE -ne 0 ]; then
  OUTPUT=$(truncate_output "$DOCS_OUTPUT" 30 "mix docs --warnings-as-errors")
  REASON="ExDoc plugin found documentation warnings:\n\n${OUTPUT}"
  emit_deny_json "$REASON" "Commit blocked: ExDoc found documentation warnings"
  exit 0
fi

emit_suppress_json
exit 0
