#!/usr/bin/env bash

# Check that private functions have @doc false and explanatory comments
# Non-blocking warning - provides context to Claude

# Read and validate stdin
INPUT=$(cat) || exit 1

# Extract file_path with error handling
FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path' 2>/dev/null) || exit 1

# Validate extracted value is not null
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" == "null" ]]; then
  exit 0
fi

# Only process .ex files (not test files .exs)
if ! echo "$FILE_PATH" | grep -qE '\.ex$'; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Skip test directories
if echo "$FILE_PATH" | grep -qE '(/test/|_test\.ex$)'; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Find private functions missing @doc false or comments
# Strategy: Find all defp lines, then check what's above them

WARNINGS=""
LINE_NUM=0
PREV_LINE=""
PREV_PREV_LINE=""
PREV_PREV_PREV_LINE=""
SEEN_FUNCS=""  # Track seen functions to skip multi-clause definitions

while IFS= read -r line || [[ -n "$line" ]]; do
  ((LINE_NUM++))

  # Check if this line starts a defp (not inside a string or comment)
  # Matches: defp foo(, defp foo?(, defp foo!(
  if echo "$line" | grep -qE '^\s*defp\s+[a-z_][a-z0-9_?!]*[(]'; then

    # Check if it's a one-liner (has ", do:" on same line)
    IS_ONE_LINER=false
    if echo "$line" | grep -qE ',\s*do:'; then
      IS_ONE_LINER=true
    fi

    # Check for @doc false in previous lines (up to 3 lines back)
    HAS_DOC_FALSE=false
    if echo "$PREV_LINE" | grep -qE '^\s*@doc\s+false'; then
      HAS_DOC_FALSE=true
    elif echo "$PREV_PREV_LINE" | grep -qE '^\s*@doc\s+false'; then
      HAS_DOC_FALSE=true
    elif echo "$PREV_PREV_PREV_LINE" | grep -qE '^\s*@doc\s+false'; then
      HAS_DOC_FALSE=true
    fi

    # Check for comment above @doc false or above defp
    HAS_COMMENT=false
    if echo "$PREV_LINE" | grep -qE '^\s*#'; then
      HAS_COMMENT=true
    elif echo "$PREV_PREV_LINE" | grep -qE '^\s*#'; then
      HAS_COMMENT=true
    elif echo "$PREV_PREV_PREV_LINE" | grep -qE '^\s*#'; then
      HAS_COMMENT=true
    fi

    # Extract function name for clearer warning
    FUNC_NAME=$(echo "$line" | grep -oE 'defp[[:space:]]+[a-z_][a-z0-9_?!]*' | sed 's/defp[[:space:]]*//')

    # Skip if we already processed this function (multi-clause definitions)
    # Only the first clause needs @doc false and comment
    if echo "$SEEN_FUNCS" | grep -qF "|${FUNC_NAME}|"; then
      continue
    fi
    SEEN_FUNCS="${SEEN_FUNCS}|${FUNC_NAME}|"

    # Build warning message
    if [[ "$HAS_DOC_FALSE" == "false" ]]; then
      WARNINGS="${WARNINGS}Line ${LINE_NUM}: defp ${FUNC_NAME} is missing @doc false\n"
    fi

    # Only warn about missing comment for non-one-liners
    if [[ "$IS_ONE_LINER" == "false" ]] && [[ "$HAS_COMMENT" == "false" ]]; then
      WARNINGS="${WARNINGS}Line ${LINE_NUM}: defp ${FUNC_NAME} is missing explanatory comment\n"
    fi
  fi

  # Shift previous lines
  PREV_PREV_PREV_LINE="$PREV_PREV_LINE"
  PREV_PREV_LINE="$PREV_LINE"
  PREV_LINE="$line"

done < "$FILE_PATH"

# If no warnings, suppress output
if [[ -z "$WARNINGS" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Format output for Claude
BASENAME=$(basename "$FILE_PATH")
OUTPUT="Private function documentation check for ${BASENAME}:

$(echo -e "$WARNINGS")
Convention: Private functions should have @doc false and an explanatory comment above.
Exception: Trivial one-liners don't need comments."

# Output JSON with additionalContext (non-blocking warning)
jq -n --arg ctx "$OUTPUT" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $ctx
  }
}'

exit 0
