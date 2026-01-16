#!/usr/bin/env bash
set -eo pipefail

# =============================================================================
# Unified Pre-Commit Check
# =============================================================================
# Consolidates 10 pre-commit hooks into 1 (90% reduction in hook invocations)
#
# Merged from: core, credo, dialyzer, sobelow, ex_doc, mix_audit, ex_unit,
#              precommit, doctor, ash
#
# Logic:
# 1. If `mix precommit` alias exists → defer to it
# 2. Otherwise run all checks in sequence:
#    - Always: format, compile, deps.unlock, credo
#    - If test/ exists: test --stale
#    - If deps exist: doctor, sobelow, dialyzer, mix_audit, ash, ex_doc

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

# =============================================================================
# Setup - Don't use precommit_setup (we ARE the precommit runner now)
# =============================================================================

read_hook_input
parse_precommit_input || exit 0
is_git_commit_command "$HOOK_COMMAND" || exit 0

GIT_DIR=$(extract_git_dir "$HOOK_COMMAND" "$HOOK_CWD")
PROJECT_ROOT=$(find_mix_project_root_from_dir "$GIT_DIR") || { emit_suppress_json; exit 0; }

cd "$PROJECT_ROOT"

# =============================================================================
# Defer to mix precommit if it exists
# =============================================================================

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
set -e

# =============================================================================
# Run all quality checks (no mix precommit alias)
# =============================================================================

ERRORS=""
WARNINGS=""

# -----------------------------------------------------------------------------
# Always Required: Format + Compile + Unused Deps
# -----------------------------------------------------------------------------

set +e

FORMAT_OUTPUT=$(mix format --check-formatted 2>&1)
if [ $? -ne 0 ]; then
  ERRORS="${ERRORS}## Format Check Failed\n${FORMAT_OUTPUT}\n\n"
fi

COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
if [ $? -ne 0 ]; then
  ERRORS="${ERRORS}## Compilation Failed\n${COMPILE_OUTPUT}\n\n"
fi

DEPS_OUTPUT=$(mix deps.unlock --check-unused 2>&1)
if [ $? -ne 0 ]; then
  ERRORS="${ERRORS}## Unused Dependencies\n${DEPS_OUTPUT}\n\n"
fi

# -----------------------------------------------------------------------------
# Always Required: Credo (fail if missing - this is a required dep)
# -----------------------------------------------------------------------------

if ! has_mix_dependency "credo" "$PROJECT_ROOT"; then
  ERRORS="${ERRORS}## Missing Required Dependency: credo\nAdd {:credo, \"~> 1.7\", only: [:dev, :test], runtime: false} to mix.exs\n\n"
else
  # Exclude TODO/FIXME checks - these are intentional documentation
  CREDO_OUTPUT=$(mix credo --strict --ignore-checks Credo.Check.Design.TagTODO,Credo.Check.Design.TagFIXME 2>&1)
  if [ $? -ne 0 ]; then
    CREDO_OUTPUT=$(truncate_output "$CREDO_OUTPUT" 30 "mix credo --strict")
    ERRORS="${ERRORS}## Credo Issues\n${CREDO_OUTPUT}\n\n"
  fi
fi

# -----------------------------------------------------------------------------
# Tests: Run if test/ directory exists
# -----------------------------------------------------------------------------

if [ -d "$PROJECT_ROOT/test" ]; then
  TEST_OUTPUT=$(mix test --stale 2>&1)
  if [ $? -ne 0 ]; then
    TEST_OUTPUT=$(truncate_output "$TEST_OUTPUT" 30 "mix test --stale")
    ERRORS="${ERRORS}## Test Failures\n${TEST_OUTPUT}\n\n"
  fi
fi

# -----------------------------------------------------------------------------
# Optional: Doctor (moduledoc/spec coverage)
# -----------------------------------------------------------------------------

if has_mix_dependency "doctor" "$PROJECT_ROOT"; then
  DOCTOR_OUTPUT=$(mix doctor 2>&1)
  if [ $? -ne 0 ]; then
    DOCTOR_OUTPUT=$(truncate_output "$DOCTOR_OUTPUT" 20 "mix doctor")
    ERRORS="${ERRORS}## Doctor Issues\n${DOCTOR_OUTPUT}\n\n"
  fi
fi

# -----------------------------------------------------------------------------
# Optional: Sobelow (security scanning)
# -----------------------------------------------------------------------------

if has_mix_dependency "sobelow" "$PROJECT_ROOT"; then
  CMD="mix sobelow --format json"
  [[ -f .sobelow-skips ]] && CMD="$CMD --skip"

  SOBELOW_OUTPUT=$($CMD 2>&1)
  JSON_OUTPUT=$(echo "$SOBELOW_OUTPUT" | sed -n '/{/,$ p')

  if echo "$JSON_OUTPUT" | jq -e '.findings | (.high_confidence + .medium_confidence + .low_confidence) | length > 0' > /dev/null 2>&1; then
    SOBELOW_OUTPUT=$(truncate_output "$SOBELOW_OUTPUT" 20 "mix sobelow")
    ERRORS="${ERRORS}## Security Issues (Sobelow)\n${SOBELOW_OUTPUT}\n\nOptions:\n  1. Fix the issues (recommended)\n  2. Mark false positives: mix sobelow --mark-skip-all\n\n"
  fi
fi

# -----------------------------------------------------------------------------
# Optional: Dialyzer (static type analysis) - SLOW but thorough
# -----------------------------------------------------------------------------

if has_mix_dependency "dialyxir" "$PROJECT_ROOT"; then
  DIALYZER_OUTPUT=$(mix dialyzer 2>&1)
  if [ $? -ne 0 ]; then
    DIALYZER_OUTPUT=$(truncate_output "$DIALYZER_OUTPUT" 20 "mix dialyzer")
    ERRORS="${ERRORS}## Type Errors (Dialyzer)\n${DIALYZER_OUTPUT}\n\n"
  fi
fi

# -----------------------------------------------------------------------------
# Optional: MixAudit (dependency vulnerability scanning)
# -----------------------------------------------------------------------------

if has_mix_dependency "mix_audit" "$PROJECT_ROOT"; then
  AUDIT_OUTPUT=$(mix deps.audit 2>&1)
  if [ $? -ne 0 ]; then
    AUDIT_OUTPUT=$(truncate_output "$AUDIT_OUTPUT" 20 "mix deps.audit")
    ERRORS="${ERRORS}## Vulnerable Dependencies\n${AUDIT_OUTPUT}\n\n"
  fi
fi

# -----------------------------------------------------------------------------
# Optional: Ash codegen (Ash Framework)
# -----------------------------------------------------------------------------

if has_mix_dependency "ash" "$PROJECT_ROOT"; then
  CODEGEN_OUTPUT=$(mix ash.codegen --check 2>&1)
  if [ $? -ne 0 ]; then
    ERRORS="${ERRORS}## Ash Codegen Out of Sync\n${CODEGEN_OUTPUT}\n\nRun 'mix ash.codegen' to update.\n\n"
  fi
fi

# -----------------------------------------------------------------------------
# Optional: ExDoc (documentation warnings)
# -----------------------------------------------------------------------------

if has_mix_dependency "ex_doc" "$PROJECT_ROOT"; then
  # Lock to prevent race conditions with parallel processes
  LOCK_DIR="/tmp/mix_docs_$(echo "$PROJECT_ROOT" | shasum -a 256 | cut -d' ' -f1).lock"
  LOCK_TIMEOUT=60
  LOCK_WAIT=0

  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [ $LOCK_WAIT -ge $LOCK_TIMEOUT ]; then
      WARNINGS="${WARNINGS}## ExDoc: Skipped (lock timeout)\n\n"
      break
    fi
    sleep 1
    LOCK_WAIT=$((LOCK_WAIT + 1))
  done

  if [ -d "$LOCK_DIR" ]; then
    trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

    DOCS_OUTPUT=$(mix docs --warnings-as-errors 2>&1)
    if [ $? -ne 0 ]; then
      DOCS_OUTPUT=$(truncate_output "$DOCS_OUTPUT" 20 "mix docs --warnings-as-errors")
      ERRORS="${ERRORS}## Documentation Warnings\n${DOCS_OUTPUT}\n\n"
    fi
  fi
fi

set -e

# =============================================================================
# Report Results
# =============================================================================

if [ -n "$ERRORS" ]; then
  ERROR_MSG="Pre-commit validation failed:\n\n${ERRORS}"

  if [ -n "$WARNINGS" ]; then
    ERROR_MSG="${ERROR_MSG}Warnings:\n${WARNINGS}"
  fi

  ERROR_MSG="${ERROR_MSG}Fix these issues before committing.\n\nTip: Add a precommit alias to mix.exs for customized checks."
  emit_deny_json "$ERROR_MSG" "Commit blocked: pre-commit validation failed"
  exit 0
fi

emit_suppress_json
exit 0
