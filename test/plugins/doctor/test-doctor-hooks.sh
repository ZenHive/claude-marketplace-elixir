#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Doctor Plugin Hooks"
echo "================================"
echo ""

# Test 1: Pre-commit check blocks on Doctor violations with structured JSON
test_hook_json \
  "Pre-commit check: Blocks on Doctor violations with structured JSON" \
  "plugins/doctor/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/doctor/precommit-test-fail\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Doctor")) and .systemMessage != null'

# Test 2: Pre-commit check passes on well-documented code
test_hook_json \
  "Pre-commit check: Passes on well-documented code" \
  "plugins/doctor/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/doctor/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 3: Pre-commit check skips when precommit alias exists
test_hook_json \
  "Pre-commit check: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/doctor/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 4: Pre-commit check ignores non-commit commands
test_hook \
  "Pre-commit check: Ignores non-commit git commands" \
  "plugins/doctor/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 5: Pre-commit check ignores non-git commands
test_hook \
  "Pre-commit check: Ignores non-git commands" \
  "plugins/doctor/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 6: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit check: Uses git -C directory instead of CWD" \
  "plugins/doctor/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/doctor/precommit-test-fail commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Doctor"))'

# Test 7: Pre-commit skips projects without doctor dependency
test_hook_json \
  "Pre-commit check: Skips projects without doctor dependency" \
  "plugins/doctor/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/credo/precommit-test\"}" \
  0 \
  ".suppressOutput == true"

print_summary
