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

# =============================================================================
# Suggest Test Include Tests
# =============================================================================

echo ""
echo "## Suggest Test Include Hook"
echo ""

# Test 31: Suggest test include standalone tests
echo "Running suggest-test-include standalone tests..."
if "$SCRIPT_DIR/suggest-test-include-test/test.sh"; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# =============================================================================
# Prefer test.json Tests (prefer-test-json.sh)
# =============================================================================
# Silently rewrites `mix test` → `mix test.json` via PreToolUse updatedInput.

echo ""
echo "## Prefer test.json Hook"
echo ""

# Test 32: Plain `mix test` is rewritten to `mix test.json`
test_hook_json \
  "prefer-test-json: Rewrites 'mix test' to allow with updatedInput.command containing mix test.json" \
  "plugins/elixir/scripts/prefer-test-json.sh" \
  "{\"tool_input\":{\"command\":\"mix test\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "allow" and (.hookSpecificOutput.updatedInput.command | contains("mix test.json"))'

# Test 33: Args after `mix test` are preserved
test_hook_json \
  "prefer-test-json: Preserves args (mix test --failed → mix test.json --failed)" \
  "plugins/elixir/scripts/prefer-test-json.sh" \
  "{\"tool_input\":{\"command\":\"mix test --failed\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\"}" \
  0 \
  '.hookSpecificOutput.updatedInput.command == "mix test.json --failed"'

# Test 34: Already `mix test.json` — exclusion guard suppresses
test_hook_json \
  "prefer-test-json: Suppresses when command is already mix test.json" \
  "plugins/elixir/scripts/prefer-test-json.sh" \
  "{\"tool_input\":{\"command\":\"mix test.json --quiet\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\"}" \
  0 \
  ".suppressOutput == true"

# Test 35: Outside an Elixir project — suppresses
test_hook_json \
  "prefer-test-json: Suppresses when cwd is not in an Elixir project" \
  "plugins/elixir/scripts/prefer-test-json.sh" \
  "{\"tool_input\":{\"command\":\"mix test\"},\"cwd\":\"/tmp\"}" \
  0 \
  ".suppressOutput == true"

# =============================================================================
# Prefer dialyzer.json Tests (prefer-dialyzer-json.sh)
# =============================================================================
# Silently rewrites `mix dialyzer` → `mix dialyzer.json` via PreToolUse updatedInput.

echo ""
echo "## Prefer dialyzer.json Hook"
echo ""

# Test 36: Plain `mix dialyzer` is rewritten to `mix dialyzer.json`
test_hook_json \
  "prefer-dialyzer-json: Rewrites 'mix dialyzer' to allow with updatedInput.command containing mix dialyzer.json" \
  "plugins/elixir/scripts/prefer-dialyzer-json.sh" \
  "{\"tool_input\":{\"command\":\"mix dialyzer\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "allow" and (.hookSpecificOutput.updatedInput.command | contains("mix dialyzer.json"))'

# Test 37: Args after `mix dialyzer` are preserved
test_hook_json \
  "prefer-dialyzer-json: Preserves args (mix dialyzer --quiet → mix dialyzer.json --quiet)" \
  "plugins/elixir/scripts/prefer-dialyzer-json.sh" \
  "{\"tool_input\":{\"command\":\"mix dialyzer --quiet\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\"}" \
  0 \
  '.hookSpecificOutput.updatedInput.command == "mix dialyzer.json --quiet"'

# Test 38: Already `mix dialyzer.json` — exclusion guard suppresses
test_hook_json \
  "prefer-dialyzer-json: Suppresses when command is already mix dialyzer.json" \
  "plugins/elixir/scripts/prefer-dialyzer-json.sh" \
  "{\"tool_input\":{\"command\":\"mix dialyzer.json\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/compile-test\"}" \
  0 \
  ".suppressOutput == true"

# Test 39: Outside an Elixir project — suppresses
test_hook_json \
  "prefer-dialyzer-json: Suppresses when cwd is not in an Elixir project" \
  "plugins/elixir/scripts/prefer-dialyzer-json.sh" \
  "{\"tool_input\":{\"command\":\"mix dialyzer\"},\"cwd\":\"/tmp\"}" \
  0 \
  ".suppressOutput == true"

# =============================================================================
# Warn Shell-Eval Elixir (warn-shell-eval-elixir.sh) — Task #32
# =============================================================================
# PreToolUse:Bash warn-only. Fires on `mix run -e`, `elixir -e`, `iex -e`,
# `mix run X.exs`. Silent on `mix test`, `iex -S mix`, `iex -S mix tidewave`,
# `mix phx.server`, `mix compile`.

echo ""
echo "## Warn Shell-Eval Elixir Hook (task #32)"
echo ""

# Test 40: mix run -e fires the warning
test_hook_json \
  "warn-shell-eval-elixir: 'mix run -e \"...\"' fires Tidewave warning" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"mix run -e \"1+1\""},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and (.hookSpecificOutput.additionalContext | contains("mcp__tidewave__project_eval"))'

# Test 41: elixir -e fires the warning
test_hook_json \
  "warn-shell-eval-elixir: 'elixir -e \"...\"' fires Tidewave warning" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"elixir -e \"IO.puts(:hi)\""},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.additionalContext | contains("mcp__tidewave__get_logs")'

# Test 42: iex -e fires the warning
test_hook_json \
  "warn-shell-eval-elixir: 'iex -e \"...\"' fires Tidewave warning" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"iex -e \"Foo.bar()\""},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse"'

# Test 43: mix run path.exs fires the warning
test_hook_json \
  "warn-shell-eval-elixir: 'mix run priv/explore.exs' fires Tidewave warning" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"mix run priv/explore.exs"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse"'

# Test 44: mix test does NOT fire (structural — alternates are narrow)
test_hook_json \
  "warn-shell-eval-elixir: 'mix test' is silent" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"mix test"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 45: iex -S mix does NOT fire
test_hook_json \
  "warn-shell-eval-elixir: 'iex -S mix' is silent" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"iex -S mix"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 46: iex -S mix tidewave does NOT fire
test_hook_json \
  "warn-shell-eval-elixir: 'iex -S mix tidewave' is silent" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"iex -S mix tidewave"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 47: mix phx.server does NOT fire (handled by block-destructive instead)
test_hook_json \
  "warn-shell-eval-elixir: 'mix phx.server' is silent (separate hook handles it)" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"mix phx.server"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 48: mix compile does NOT fire
test_hook_json \
  "warn-shell-eval-elixir: 'mix compile' is silent" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"mix compile"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 49: mix run priv/repo/seeds.exs FIRES (accepted false positive per task body)
test_hook_json \
  "warn-shell-eval-elixir: 'mix run priv/repo/seeds.exs' fires (accepted false positive — footer names seeds as legit exception)" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"mix run priv/repo/seeds.exs"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.additionalContext | contains("priv/repo/seeds.exs")'

# Test 50: warning footer names seeds and one-shot CI as exceptions
test_hook_json \
  "warn-shell-eval-elixir: warning footer lists legitimate exceptions" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":"mix run -e \"x\""},"cwd":"/tmp"}' \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("priv/repo/seeds.exs")) and (.hookSpecificOutput.additionalContext | contains("CI"))'

# Test 51: empty command suppresses cleanly
test_hook_json \
  "warn-shell-eval-elixir: null/empty command suppresses" \
  "plugins/elixir/scripts/warn-shell-eval-elixir.sh" \
  '{"tool_input":{"command":""},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# =============================================================================
# Warn Missing Tool Flags (warn-missing-tool-flags.sh) — Task #30
# =============================================================================
# PreToolUse:Bash warn-only. Nudges on `mix credo` without --strict --format json
# and `mix compile` without `time` prefix.

echo ""
echo "## Warn Missing Tool Flags Hook (task #30)"
echo ""

# Test 52: mix credo with no flags fires
test_hook_json \
  "warn-missing-tool-flags: 'mix credo' (no flags) fires" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"mix credo"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.additionalContext | contains("--strict --format json")'

# Test 53: mix credo --strict only fires (missing --format json)
test_hook_json \
  "warn-missing-tool-flags: 'mix credo --strict' fires (missing --format json)" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"mix credo --strict"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.additionalContext | contains("--strict --format json")'

# Test 54: mix credo --strict --format json does NOT fire
test_hook_json \
  "warn-missing-tool-flags: 'mix credo --strict --format json' is silent" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"mix credo --strict --format json"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 54a: --format=json (equal-sign form) is also accepted
test_hook_json \
  "warn-missing-tool-flags: 'mix credo --strict --format=json' is silent (equal-sign form)" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"mix credo --strict --format=json"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 55: mix compile without time fires
test_hook_json \
  "warn-missing-tool-flags: 'mix compile' (no time prefix) fires" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"mix compile"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.additionalContext | contains("time mix compile")'

# Test 56: time mix compile does NOT fire
test_hook_json \
  "warn-missing-tool-flags: 'time mix compile' is silent" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"time mix compile"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 57: time MIX_ENV=prod mix compile does NOT fire
test_hook_json \
  "warn-missing-tool-flags: 'time MIX_ENV=prod mix compile' is silent" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"time MIX_ENV=prod mix compile"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 58: mix credo --version does NOT fire (non-analysis subcommand)
test_hook_json \
  "warn-missing-tool-flags: 'mix credo --version' is silent" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"mix credo --version"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 59: mix test does NOT fire (unrelated command)
test_hook_json \
  "warn-missing-tool-flags: 'mix test' is silent (unrelated)" \
  "plugins/elixir/scripts/warn-missing-tool-flags.sh" \
  '{"tool_input":{"command":"mix test"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# =============================================================================
# Block Destructive Bash (block-destructive-bash.sh) — Task #29
# =============================================================================
# PreToolUse:Bash blocker. Denies mix phx.server / destructive deps/build / bare rm.

echo ""
echo "## Block Destructive Bash Hook (task #29)"
echo ""

# Test 60: mix phx.server blocked
test_hook_json \
  "block-destructive-bash: 'mix phx.server' blocked with reason" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix phx.server"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Phoenix server"))'

# Test 61: mix deps.clean blocked
test_hook_json \
  "block-destructive-bash: 'mix deps.clean' blocked" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix deps.clean"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("destructive"))'

# Test 62: mix clean blocked
test_hook_json \
  "block-destructive-bash: 'mix clean' blocked" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix clean"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 63: mix deps.unlock --all blocked
test_hook_json \
  "block-destructive-bash: 'mix deps.unlock --all' blocked" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix deps.unlock --all"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 64: rm -rf _build blocked
test_hook_json \
  "block-destructive-bash: 'rm -rf _build' blocked" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"rm -rf _build"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 65: rm -rf deps blocked
test_hook_json \
  "block-destructive-bash: 'rm -rf deps' blocked" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"rm -rf deps"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 66: bare rm blocked
test_hook_json \
  "block-destructive-bash: bare 'rm foo.txt' blocked with git rm suggestion" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"rm foo.txt"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("git rm"))'

# Test 67: git rm allowed (suppressOutput)
test_hook_json \
  "block-destructive-bash: 'git rm tracked.ex' is allowed (suppressOutput)" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"git rm tracked.ex"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 68: mix deps.unlock --check-unused allowed (used by pre-commit)
test_hook_json \
  "block-destructive-bash: 'mix deps.unlock --check-unused' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix deps.unlock --check-unused"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 69: mix deps.compile <dep> --force allowed
test_hook_json \
  "block-destructive-bash: 'mix deps.compile foo --force' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix deps.compile foo --force"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 70: mix deps.get allowed
test_hook_json \
  "block-destructive-bash: 'mix deps.get' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix deps.get"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71: mix test allowed (unrelated)
test_hook_json \
  "block-destructive-bash: 'mix test' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"mix test"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71a: compound `git rm a && rm b` denies the second segment
test_hook_json \
  "block-destructive-bash: 'git rm tracked.ex && rm scratch.txt' blocked (compound bypass)" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"git rm tracked.ex && rm scratch.txt"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("git rm"))'

# Test 71b: compound with `;` separator also denies the bare rm
test_hook_json \
  "block-destructive-bash: 'git rm a.ex; rm b.txt' blocked (semicolon compound)" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"git rm a.ex; rm b.txt"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 71c: sudo rm is also blocked
test_hook_json \
  "block-destructive-bash: 'sudo rm foo.txt' blocked" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"sudo rm foo.txt"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 71d: npm rm allowed (package-manager wrapper)
test_hook_json \
  "block-destructive-bash: 'npm rm lodash' is allowed (package-manager wrapper)" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"npm rm lodash"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71e: pnpm rm allowed
test_hook_json \
  "block-destructive-bash: 'pnpm rm react' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"pnpm rm react"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71f: yarn rm allowed
test_hook_json \
  "block-destructive-bash: 'yarn rm webpack' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"yarn rm webpack"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71g: bundle rm allowed
test_hook_json \
  "block-destructive-bash: 'bundle rm rspec' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"bundle rm rspec"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71h: cargo rm allowed
test_hook_json \
  "block-destructive-bash: 'cargo rm serde' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"cargo rm serde"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71i: gem rm allowed
test_hook_json \
  "block-destructive-bash: 'gem rm activerecord' is allowed" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"gem rm activerecord"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

# Test 71j: env-var-prefixed bare rm still denied
test_hook_json \
  "block-destructive-bash: 'MIX_ENV=test rm tmp.txt' blocked (env-prefix stripped)" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"MIX_ENV=test rm tmp.txt"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 71k: npm rm in compound with bare rm — bare rm still denied
test_hook_json \
  "block-destructive-bash: 'npm rm foo && rm scratch.txt' blocked (compound — wrapper allowed, bare denied)" \
  "plugins/elixir/scripts/block-destructive-bash.sh" \
  '{"tool_input":{"command":"npm rm foo && rm scratch.txt"},"cwd":"/tmp"}' \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# =============================================================================
# Warn Doctest IO and Untagged TODOs (warn-doctest-io-and-untagged-todos.sh) — Task #31
# =============================================================================
# PostToolUse:Edit|Write|MultiEdit warn-only. IO inside @doc heredoc and
# untagged deferred-work comments.

echo ""
echo "## Warn Doctest IO and Untagged TODOs Hook (task #31)"
echo ""

# Fixtures live as committed files in test/plugins/elixir/doctest-io-fixtures/
DOCTEST_FIXTURE_DIR="$REPO_ROOT/test/plugins/elixir/doctest-io-fixtures"

# Test 72: IO inside @doc fires
test_hook_json \
  "warn-doctest-io: IO.puts/inspect inside @doc heredoc fires" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  "{\"tool_input\":{\"file_path\":\"$DOCTEST_FIXTURE_DIR/io_in_doc.ex\"},\"cwd\":\"/tmp\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("IO.puts inside @doc heredoc") and contains("IO.inspect inside @doc heredoc")'

# Test 73: IO outside @doc does NOT fire
test_hook_json \
  "warn-doctest-io: IO outside @doc is silent" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  "{\"tool_input\":{\"file_path\":\"$DOCTEST_FIXTURE_DIR/io_outside_doc.ex\"},\"cwd\":\"/tmp\"}" \
  0 \
  '.suppressOutput == true'

# Test 74: Untagged "For now," comment fires
test_hook_json \
  "warn-doctest-io: untagged '# For now,' comment fires" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  "{\"tool_input\":{\"file_path\":\"$DOCTEST_FIXTURE_DIR/untagged.ex\"},\"cwd\":\"/tmp\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("TODO:")'

# Test 75: TODO-prefixed comment does NOT fire
test_hook_json \
  "warn-doctest-io: '# TODO: For now,' comment is silent" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  "{\"tool_input\":{\"file_path\":\"$DOCTEST_FIXTURE_DIR/tagged.ex\"},\"cwd\":\"/tmp\"}" \
  0 \
  '.suppressOutput == true'

# Test 76: String literal containing "For now," does NOT fire (false-positive guard)
test_hook_json \
  "warn-doctest-io: 'For now,' inside string literal is silent (FP guard)" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  "{\"tool_input\":{\"file_path\":\"$DOCTEST_FIXTURE_DIR/in_string.ex\"},\"cwd\":\"/tmp\"}" \
  0 \
  '.suppressOutput == true'

# Test 77: Clean file (no IO in @doc, no untagged comments) is silent
test_hook_json \
  "warn-doctest-io: clean file is silent" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  "{\"tool_input\":{\"file_path\":\"$DOCTEST_FIXTURE_DIR/clean.ex\"},\"cwd\":\"/tmp\"}" \
  0 \
  '.suppressOutput == true'

# Test 78: Non-Elixir file is silent
test_hook_json \
  "warn-doctest-io: non-Elixir file (README.md) is silent" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"/tmp\"}" \
  0 \
  '.suppressOutput == true'

# Test 79: Nonexistent file is silent
test_hook_json \
  "warn-doctest-io: nonexistent file is silent" \
  "plugins/elixir/scripts/warn-doctest-io-and-untagged-todos.sh" \
  '{"tool_input":{"file_path":"/tmp/does-not-exist.ex"},"cwd":"/tmp"}' \
  0 \
  '.suppressOutput == true'

print_summary
