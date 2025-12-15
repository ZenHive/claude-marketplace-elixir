#!/usr/bin/env bash
set -eo pipefail

# Pre-commit validation for Elixir projects
# Strict mode: runs comprehensive quality gates before commits
#
# If `mix precommit` alias exists: runs it
# Otherwise: runs all quality checks directly:
#   - mix format --check-formatted
#   - mix compile --warnings-as-errors
#   - mix credo --strict
#   - mix doctor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

# Don't use precommit_setup here - this IS the precommit runner
read_hook_input
parse_precommit_input || exit 0
is_git_commit_command "$HOOK_COMMAND" || exit 0

GIT_DIR=$(extract_git_dir "$HOOK_COMMAND" "$HOOK_CWD")
PROJECT_ROOT=$(find_mix_project_root_from_dir "$GIT_DIR") || { emit_suppress_json; exit 0; }

cd "$PROJECT_ROOT"

# Check if precommit alias exists using Mix (authoritative detection)
# Disable errexit for this check
set +e
if mix help precommit >/dev/null 2>&1; then
  PRECOMMIT_OUTPUT=$(mix precommit 2>&1)
  PRECOMMIT_EXIT=$?
  set -e

  if [ $PRECOMMIT_EXIT -eq 0 ]; then
    emit_suppress_json
    exit 0
  fi

  OUTPUT=$(truncate_output "$PRECOMMIT_OUTPUT" 50 "mix precommit")
  ERROR_MSG="Precommit validation failed:\n\n${OUTPUT}\n\nFix these issues before committing."
  emit_deny_json "$ERROR_MSG" "Commit blocked: mix precommit validation failed"
  exit 0
fi

# No precommit alias - run strict quality checks directly
ERROR_MSG=""
HAS_ERRORS=0

FORMAT_OUTPUT=$(mix format --check-formatted 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Format check failed:\n${FORMAT_OUTPUT}\n\n"
  HAS_ERRORS=1
fi

COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Compilation failed (warnings as errors):\n${COMPILE_OUTPUT}\n\n"
  HAS_ERRORS=1
fi

CREDO_OUTPUT=$(mix credo --strict 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Credo strict check failed:\n${CREDO_OUTPUT}\n\n"
  HAS_ERRORS=1
fi

DOCTOR_OUTPUT=$(mix doctor 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Doctor check failed:\n${DOCTOR_OUTPUT}\n\n"
  HAS_ERRORS=1
fi
set -e

if [ $HAS_ERRORS -eq 1 ]; then
  ERROR_MSG="${ERROR_MSG}Fix these issues before committing.\n\nTip: Add a precommit alias to mix.exs for customized checks."
  emit_deny_json "$ERROR_MSG" "Commit blocked: strict precommit validation failed"
  exit 0
fi

emit_suppress_json
exit 0
