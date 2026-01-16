#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Elixir Plugin Hooks"
echo "================================"
echo ""

# =============================================================================
# Post-Edit Check Tests (post-edit-check.sh)
# =============================================================================
# The consolidated hook runs: format, compile, credo, sobelow, doctor, struct
# hints, hidden failures, mixexs-check. Requires credo, sobelow, doctor deps.

echo "## Post-Edit Check Hook"
echo ""

# Test 1: Post-edit check ignores non-Elixir files
test_hook_json \
  "Post-edit: Ignores non-Elixir files (suppressOutput)" \
  "plugins/elixir/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ".suppressOutput == true"

# Test 2: Post-edit check errors when required deps missing
test_hook_json \
  "Post-edit: Errors when required deps (credo, sobelow, doctor) missing" \
  "plugins/elixir/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/precommit-test/lib/unformatted.ex\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("Missing required deps")'

# Test 3: Post-edit check suppresses when no project found
test_hook_json \
  "Post-edit: Suppresses when not in an Elixir project" \
  "plugins/elixir/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"/tmp/random.ex\"},\"cwd\":\"/tmp\"}" \
  0 \
  ".suppressOutput == true"

# =============================================================================
# Pre-Commit Unified Tests (pre-commit-unified.sh)
# =============================================================================
# The unified pre-commit hook runs: format, compile, deps.unlock, credo, test,
# doctor, sobelow, dialyzer, mix_audit, ash.codegen, ex_doc (if deps exist).

echo ""
echo "## Pre-Commit Unified Hook"
echo ""

# Test 4: Pre-commit ignores non-commit git commands
test_hook_json \
  "Pre-commit: Ignores non-commit git commands (git status)" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ".suppressOutput == true"

# Test 5: Pre-commit ignores non-git commands
test_hook_json \
  "Pre-commit: Ignores non-git commands (ls -la)" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"ls -la\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ".suppressOutput == true"

# Test 6: Pre-commit blocks on format issues (no credo installed)
test_hook_json \
  "Pre-commit: Blocks on format issues" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny"'

# Test 7: Pre-commit shows format issues in reason
test_hook_json \
  "Pre-commit: Shows format issues in permissionDecisionReason" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecisionReason | contains("Format Check Failed")'

# Test 8: Pre-commit requires credo dep
test_hook_json \
  "Pre-commit: Requires credo dependency" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecisionReason | contains("Missing Required Dependency: credo")'

# Test 9: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit: Uses git -C directory instead of CWD" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/elixir/precommit-test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 10: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit: Falls back to CWD when -C path is invalid" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 11: Pre-commit suppresses when not in Elixir project
test_hook_json \
  "Pre-commit: Suppresses when not in Elixir project" \
  "plugins/elixir/scripts/pre-commit-unified.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"/tmp\"}" \
  0 \
  ".suppressOutput == true"

# =============================================================================
# Docs Recommendation Tests (recommend-docs-lookup.sh)
# =============================================================================
# UserPromptSubmit hook that detects dependency mentions in user prompts

echo ""
echo "## Docs Recommendation Hook (UserPromptSubmit)"
echo ""

# Test 12: Docs recommendation detects dependency mentions (capitalized)
test_hook_json \
  "Docs recommendation: Detects 'Ecto' in prompt" \
  "plugins/elixir/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Help me write an Ecto query\",\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "UserPromptSubmit" and (.hookSpecificOutput.additionalContext | contains("ecto"))'

# Test 13: Docs recommendation detects lowercase dependency names
test_hook_json \
  "Docs recommendation: Detects 'jason' (lowercase) in prompt" \
  "plugins/elixir/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"I need to parse json with jason\",\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("jason")'

# Test 14: Docs recommendation detects multiple dependencies
test_hook_json \
  "Docs recommendation: Detects multiple dependencies" \
  "plugins/elixir/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Use Ecto and Jason together\",\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("ecto")) and (.hookSpecificOutput.additionalContext | contains("jason"))'

# Test 15: Docs recommendation returns empty when no dependencies mentioned
test_hook_json \
  "Docs recommendation: Returns empty JSON when no dependencies mentioned" \
  "plugins/elixir/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Help me refactor this code\",\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '. == {}'

# Test 16: Docs recommendation works in non-Elixir projects (exits cleanly)
test_hook_json \
  "Docs recommendation: Handles non-Elixir projects gracefully" \
  "plugins/elixir/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Some prompt\",\"cwd\":\"$REPO_ROOT\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '. == {}'

# Test 17: Docs recommendation recommends skills in output
test_hook_json \
  "Docs recommendation: Recommends using hex-docs-search skill" \
  "plugins/elixir/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"How do I use Ecto?\",\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("hex-docs-search")'

# =============================================================================
# Read Hook Tests (recommend-docs-on-read.sh)
# =============================================================================
# PostToolUse hook that detects module usage in read files

echo ""
echo "## Read Hook (PostToolUse after Read)"
echo ""

# Test 18: Read hook detects dependencies from direct module usage
test_hook_json \
  "Read hook: Detects dependencies from direct module usage (Jason.decode)" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/test_file.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("jason")) and (.hookSpecificOutput.additionalContext | contains("ecto"))'

# Test 19: Read hook ignores non-Elixir files
test_hook_json \
  "Read hook: Ignores non-Elixir files" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '. == {}'

# Test 20: Read hook returns empty when file has no dependency references
test_hook_json \
  "Read hook: Returns empty when no dependency references found" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/broken_code.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '. == {}'

# Test 21: File using Jason.decode() matches jason dependency
test_hook_json \
  "Read hook: Matches jason when file uses Jason.decode()" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("jason")'

# Test 22: File using Jason does not match unrelated ecto dependency
test_hook_json \
  "Read hook: Excludes ecto when file only uses Jason" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("ecto")) | not'

# Test 23: File using Jason does not match unrelated decimal dependency
test_hook_json \
  "Read hook: Excludes decimal when file only uses Jason" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("decimal")) | not'

# Test 24: File using Jason does not match unrelated telemetry dependency
test_hook_json \
  "Read hook: Excludes telemetry when file only uses Jason" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("telemetry")) | not'

# Test 25: File importing Phoenix.LiveView matches both phoenix and phoenix_live_view
test_hook_json \
  "Read hook: Matches phoenix_live_view when file imports Phoenix.LiveView" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("phoenix_live_view")'

# Test 26: File importing Phoenix.LiveView also matches base phoenix dependency
test_hook_json \
  "Read hook: Matches phoenix when file imports Phoenix.LiveView" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | test("\\bphoenix[,.]")'

# Test 27: File importing Phoenix.LiveView does not match unrelated phoenix_html
test_hook_json \
  "Read hook: Excludes phoenix_html when file imports Phoenix.LiveView" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("phoenix_html")) | not'

# Test 28: File importing Phoenix.LiveView does not match unrelated phoenix_pubsub
test_hook_json \
  "Read hook: Excludes phoenix_pubsub when file imports Phoenix.LiveView" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("phoenix_pubsub")) | not'

# Test 29: File importing Phoenix.LiveView does not match unrelated phoenix_template
test_hook_json \
  "Read hook: Excludes phoenix_template when file imports Phoenix.LiveView" \
  "plugins/elixir/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("phoenix_template")) | not'

# =============================================================================
# Suggest Test Failed Tests
# =============================================================================

echo ""
echo "## Suggest Test Failed Hook"
echo ""

# Test 30: Suggest test failed hook standalone tests
echo "Running suggest-test-failed standalone tests..."
if "$SCRIPT_DIR/suggest-test-failed-test/test.sh"; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
fi

print_summary
