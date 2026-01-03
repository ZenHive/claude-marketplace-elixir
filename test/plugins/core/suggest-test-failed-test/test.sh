#!/bin/bash
# Test suggest-test-failed hook

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../../../plugins/core" && pwd)"

# Clean up any existing tracker
PROJECT_HASH=$(echo "$PWD" | md5sum 2>/dev/null | cut -c1-8 || echo "$PWD" | md5 | cut -c1-8)
rm -f "/tmp/mix_test_tracker_${PROJECT_HASH}" 2>/dev/null || true

echo "Testing suggest-test-failed hook..."

# Test 1: First call should suppress
OUTPUT=$(echo '{"tool_input": {"command": "mix test"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh")
if echo "$OUTPUT" | grep -q '"suppressOutput": true'; then
  echo "✓ First call suppresses output"
else
  echo "✗ First call should suppress output"
  exit 1
fi

# Test 2: Second call should suggest --failed
OUTPUT=$(echo '{"tool_input": {"command": "mix test"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh")
if echo "$OUTPUT" | grep -q '"additionalContext"' && echo "$OUTPUT" | grep -q 'mix test --failed'; then
  echo "✓ Second call suggests --failed"
else
  echo "✗ Second call should suggest --failed"
  exit 1
fi

# Test 4: --failed resets counter
echo '{"tool_input": {"command": "mix test --failed"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh" > /dev/null
OUTPUT=$(echo '{"tool_input": {"command": "mix test"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh")
if echo "$OUTPUT" | grep -q '"suppressOutput": true'; then
  echo "✓ --failed resets counter"
else
  echo "✗ --failed should reset counter"
  exit 1
fi

# Test 5: Non-mix-test commands are ignored
OUTPUT=$(echo '{"tool_input": {"command": "ls -la"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh")
if echo "$OUTPUT" | grep -q '"suppressOutput": true'; then
  echo "✓ Non-mix-test commands ignored"
else
  echo "✗ Non-mix-test commands should be ignored"
  exit 1
fi

# Test 6: Passing tests reset counter (PostToolUse)
# Build up count to 2 (triggers suggestion)
echo '{"tool_input": {"command": "mix test"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh" > /dev/null
echo '{"tool_input": {"command": "mix test"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh" > /dev/null
# Simulate passing tests
echo '{"tool_input": {"command": "mix test"}, "tool_output": {"stdout": "10 tests, 0 failures"}}' | "$PLUGIN_ROOT/scripts/reset-test-tracker.sh" > /dev/null
OUTPUT=$(echo '{"tool_input": {"command": "mix test"}}' | "$PLUGIN_ROOT/scripts/suggest-test-failed.sh")
if echo "$OUTPUT" | grep -q '"suppressOutput": true'; then
  echo "✓ Passing tests reset counter"
else
  echo "✗ Passing tests should reset counter"
  exit 1
fi

# Clean up
rm -f "/tmp/mix_test_tracker_${PROJECT_HASH}" 2>/dev/null || true

echo ""
echo "All suggest-test-failed tests passed!"
