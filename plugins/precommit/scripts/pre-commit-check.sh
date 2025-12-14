#!/usr/bin/env bash

# Pre-commit validation for Elixir projects
# Strict mode: runs comprehensive quality gates before commits
#
# If `mix precommit` alias exists: runs it
# Otherwise: runs all quality checks directly:
#   - mix format --check-formatted
#   - mix compile --warnings-as-errors
#   - mix credo --strict
#   - mix doctor

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ "$COMMAND" == "null" ]] || [[ -z "$COMMAND" ]]; then
  exit 0
fi

if [[ "$CWD" == "null" ]] || [[ -z "$CWD" ]]; then
  exit 0
fi

if ! echo "$COMMAND" | grep -qE 'git\b.*\bcommit\b'; then
  exit 0
fi

# Extract directory from git -C flag if present, otherwise use CWD
GIT_DIR="$CWD"
if echo "$COMMAND" | grep -qE 'git\s+-C\s+'; then
  GIT_DIR=$(echo "$COMMAND" | sed -n 's/.*git[[:space:]]*-C[[:space:]]*\([^[:space:]]*\).*/\1/p')
  if [[ -z "$GIT_DIR" ]] || [[ ! -d "$GIT_DIR" ]]; then
    GIT_DIR="$CWD"
  fi
fi

# Find Mix project root by traversing upward from current working directory
find_mix_project_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_mix_project_root "$GIT_DIR")

if [[ -z "$PROJECT_ROOT" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

cd "$PROJECT_ROOT"

# Check if precommit alias exists using Mix (authoritative detection)
if mix help precommit >/dev/null 2>&1; then
  # Run mix precommit
  PRECOMMIT_OUTPUT=$(mix precommit 2>&1)
  PRECOMMIT_EXIT=$?

  # Success case - suppress output
  if [ $PRECOMMIT_EXIT -eq 0 ]; then
    jq -n '{"suppressOutput": true}'
    exit 0
  fi

  # Failure case - truncate output and block commit
  TOTAL_LINES=$(echo "$PRECOMMIT_OUTPUT" | wc -l)
  MAX_LINES=50

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$PRECOMMIT_OUTPUT" | head -n $MAX_LINES)
    FINAL_OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines. Run 'mix precommit' in $PROJECT_ROOT to see full output]"
  else
    FINAL_OUTPUT="$PRECOMMIT_OUTPUT"
  fi

  ERROR_MSG="Precommit validation failed:\n\n${FINAL_OUTPUT}\n\nFix these issues before committing."

  jq -n \
    --arg reason "$ERROR_MSG" \
    --arg msg "Commit blocked: mix precommit validation failed" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      },
      "systemMessage": $msg
    }'
  exit 0
fi

# No precommit alias - run strict quality checks directly
ERROR_MSG=""
HAS_ERRORS=0

# Check 1: Format
FORMAT_OUTPUT=$(mix format --check-formatted 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Format check failed:\n${FORMAT_OUTPUT}\n\n"
  HAS_ERRORS=1
fi

# Check 2: Compile with warnings as errors
COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Compilation failed (warnings as errors):\n${COMPILE_OUTPUT}\n\n"
  HAS_ERRORS=1
fi

# Check 3: Credo strict (always required)
CREDO_OUTPUT=$(mix credo --strict 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Credo strict check failed:\n${CREDO_OUTPUT}\n\n"
  HAS_ERRORS=1
fi

# Check 4: Doctor (always required)
DOCTOR_OUTPUT=$(mix doctor 2>&1)
if [ $? -ne 0 ]; then
  ERROR_MSG="${ERROR_MSG}[ERROR] Doctor check failed:\n${DOCTOR_OUTPUT}\n\n"
  HAS_ERRORS=1
fi

# If any check failed, block the commit
if [ $HAS_ERRORS -eq 1 ]; then
  ERROR_MSG="${ERROR_MSG}Fix these issues before committing.\n\nTip: Add a precommit alias to mix.exs for customized checks."

  jq -n \
    --arg reason "$ERROR_MSG" \
    --arg msg "Commit blocked: strict precommit validation failed" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      },
      "systemMessage": $msg
    }'
  exit 0
fi

jq -n '{"suppressOutput": true}'
exit 0
