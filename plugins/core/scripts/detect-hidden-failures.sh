#!/usr/bin/env bash

# Detect test patterns that hide failures
# Warns (non-blocking) when test files contain patterns that silently pass on errors
#
# BAD patterns detected:
#   {:error, _} -> assert true    # Makes ALL failures pass
#   {:error, _reason} -> :ok      # Silent pass on any error
#   {:error, _} -> :ok            # Silent pass variant
#
# This hook only scans _test.exs files edited via Edit/Write tools

INPUT=$(cat) || exit 1

FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null) || exit 1

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" == "null" ]]; then
  exit 0
fi

# Only check test files
if ! echo "$FILE_PATH" | grep -qE '_test\.exs$'; then
  exit 0
fi

# Verify file exists
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Patterns that hide test failures (multiline-safe grep patterns)
WARNINGS=""

# Pattern 1: {:error, _} -> assert true (any variant with underscore)
if grep -E '\{:error,\s*_[^}]*\}\s*->' "$FILE_PATH" | grep -qE 'assert\s+true'; then
  WARNINGS="${WARNINGS}⚠️ Found '{:error, _} -> assert true' pattern - this makes ALL failures pass silently\n"
fi

# Pattern 2: {:error, _} -> :ok (silent pass)
if grep -E '\{:error,\s*_[^}]*\}\s*->\s*:ok' "$FILE_PATH" >/dev/null 2>&1; then
  WARNINGS="${WARNINGS}⚠️ Found '{:error, _} -> :ok' pattern - this silently passes on ANY error\n"
fi

# Pattern 3: {:error, _} -> assert true inside case blocks (more specific)
if grep -E '\{:error,\s*_\w*\}\s*->\s*$' "$FILE_PATH" | head -1 >/dev/null 2>&1; then
  # Check if next non-empty line contains assert true or :ok
  MULTI_LINE_CHECK=$(awk '
    /{:error,\s*_[^}]*}\s*->\s*$/ { found=1; next }
    found && /^\s*(assert\s+true|:ok)\s*$/ { print "HIDDEN_FAILURE"; exit }
    found && /^\s*$/ { next }
    found { found=0 }
  ' "$FILE_PATH")

  if [[ "$MULTI_LINE_CHECK" == "HIDDEN_FAILURE" ]]; then
    WARNINGS="${WARNINGS}⚠️ Found multi-line hidden failure pattern\n"
  fi
fi

# No issues found
if [[ -z "$WARNINGS" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Build warning message with correct alternatives
CONTEXT="🔍 **Hidden Test Failure Patterns Detected** in \`${FILE_PATH}\`

${WARNINGS}
**Why this matters:** Tests should FAIL when unexpected errors occur. Silently passing on errors hides bugs.

**Correct patterns:**
\`\`\`elixir
# ✅ Fail loudly on unexpected errors
case result do
  {:ok, data} -> assert is_map(data)
  {:error, :specific_expected_error} -> :ok
  {:error, other} -> flunk(\"Unexpected error: \#{inspect(other)}\")
end

# ✅ Test specific behavior
test \"returns not_found when account doesn't exist\" do
  assert {:error, :not_found} = get_account(\"invalid_id\")
end
\`\`\`

**The rule:** If you don't know what error to expect, DON'T write the test yet. Explore the API first, understand the real error cases, THEN write proper assertions."

jq -n --arg context "$CONTEXT" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $context
  }
}'
exit 0
