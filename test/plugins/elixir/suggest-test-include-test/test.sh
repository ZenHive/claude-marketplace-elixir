#!/usr/bin/env bash
# Standalone test suite for suggest-test-include.sh
#
# Builds throwaway Mix project fixtures with various test_helper.exs shapes
# and verifies the hook's exemption logic and parsing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../../../plugins/elixir" && pwd)"
HOOK="$PLUGIN_ROOT/scripts/suggest-test-include.sh"

PASS=0
FAIL=0

expect_suppress() {
  local label="$1"
  local command="$2"
  local cwd="$3"

  local out
  out=$(echo "{\"tool_input\":{\"command\":\"$command\"},\"cwd\":\"$cwd\"}" | bash "$HOOK")
  if echo "$out" | jq -e '.suppressOutput == true' >/dev/null 2>&1; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label"
    echo "    expected suppressOutput, got: $out"
    FAIL=$((FAIL + 1))
  fi
}

expect_fires_with() {
  local label="$1"
  local command="$2"
  local cwd="$3"
  local expected_substring="$4"

  local out ctx
  out=$(echo "{\"tool_input\":{\"command\":\"$command\"},\"cwd\":\"$cwd\"}" | bash "$HOOK")
  ctx=$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext // empty')

  if [[ -z "$ctx" ]]; then
    echo "  ✗ $label"
    echo "    expected fire, got: $out"
    FAIL=$((FAIL + 1))
    return
  fi

  if echo "$ctx" | grep -qF -- "$expected_substring"; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label (substring not found: $expected_substring)"
    echo "    ctx: $ctx"
    FAIL=$((FAIL + 1))
  fi
}

echo "Testing suggest-test-include hook..."
echo ""

# Build the fixture tree.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

make_project() {
  local name="$1"
  local helper_content="$2"

  local proj="$TMP/$name"
  mkdir -p "$proj/test"
  echo "defmodule ${name^}.MixProject do; use Mix.Project; end" > "$proj/mix.exs"
  if [[ -n "$helper_content" ]]; then
    printf '%s' "$helper_content" > "$proj/test/test_helper.exs"
  fi
  echo "$proj"
}

# --- Fixtures ---

P_MULTI=$(make_project "multi" 'ExUnit.start(exclude: [:integration, :dangerous, :fixture_replay, :network, :invalid_creds])
')

P_SINGLE=$(make_project "single" 'ExUnit.start(exclude: [:integration])
')

P_CONFIGURE=$(make_project "configure" 'ExUnit.start()
ExUnit.configure(exclude: [:integration, :slow])
')

P_MULTILINE=$(make_project "multiline" 'ExUnit.start(
  exclude: [
    :integration,
    :network,
    :dangerous
  ]
)
')

P_PLAIN=$(make_project "plain" 'ExUnit.start()
')

P_NO_HELPER=$(make_project "no_helper" "")

# --- Tests ---

echo "## Firing cases"

expect_fires_with "multi-tag exclude lists all atoms" \
  "mix test.json --quiet" "$P_MULTI" \
  ":integration, :dangerous, :fixture_replay, :network, :invalid_creds"

expect_fires_with "suggested --include command covers all atoms" \
  "mix test.json --quiet" "$P_MULTI" \
  "--include integration --include dangerous --include fixture_replay --include network --include invalid_creds"

expect_fires_with "single-tag exclude fires" \
  "mix test.json" "$P_SINGLE" \
  ":integration"

expect_fires_with "ExUnit.configure(exclude:) form is recognized" \
  "mix test.json" "$P_CONFIGURE" \
  ":integration, :slow"

expect_fires_with "multi-line exclude list is recognized" \
  "mix test.json" "$P_MULTILINE" \
  ":integration, :network, :dangerous"

expect_fires_with "MIX_QUIET=1 prefix still fires" \
  "MIX_QUIET=1 mix test.json" "$P_SINGLE" \
  ":integration"

echo ""
echo "## Suppression cases"

expect_suppress "non-mix-test-json command" \
  "ls -la" "$P_MULTI"

expect_suppress "plain mix test (prefer-test-json handles this)" \
  "mix test" "$P_MULTI"

expect_suppress "mix test.json --include integration already focused" \
  "mix test.json --include integration" "$P_MULTI"

expect_suppress "mix test.json --only unit already focused" \
  "mix test.json --only unit" "$P_MULTI"

expect_suppress "mix test.json --failed already focused" \
  "mix test.json --failed" "$P_MULTI"

expect_suppress "mix test.json test/foo_test.exs (file path arg)" \
  "mix test.json test/foo_test.exs" "$P_MULTI"

expect_suppress "mix test.json test/foo_test.exs:42 (file path with line)" \
  "mix test.json test/foo_test.exs:42" "$P_MULTI"

expect_suppress "mix test.json apps/myapp/test/foo_test.exs (umbrella path)" \
  "mix test.json apps/myapp/test/foo_test.exs" "$P_MULTI"

expect_suppress "plain ExUnit.start() with no exclude list" \
  "mix test.json" "$P_PLAIN"

expect_suppress "project without test_helper.exs" \
  "mix test.json" "$P_NO_HELPER"

expect_suppress "not in a Mix project" \
  "mix test.json" "/tmp"

# --- Summary ---

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo "All suggest-test-include tests passed ($PASS/$((PASS + FAIL)))"
  exit 0
else
  echo "Some suggest-test-include tests failed ($FAIL failed, $PASS passed)"
  exit 1
fi
