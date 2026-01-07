#!/bin/bash
# struct-check.sh - Detects map patterns that could benefit from defstruct
# Non-blocking PostToolUse hook for .ex files

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# If no file path, suppress output
if [[ -z "$FILE_PATH" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Only process .ex files (not .exs - scripts/tests/configs)
if [[ ! "$FILE_PATH" =~ \.ex$ ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Read file content
CONTENT=$(cat "$FILE_PATH")

# Check if module already has defstruct - if so, no reminder needed
if echo "$CONTENT" | grep -qE '^\s*defstruct\b'; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Check if this is a module file (has defmodule)
if ! echo "$CONTENT" | grep -qE '^\s*defmodule\b'; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Detection heuristics
SUGGEST_STRUCT=false
REASONS=""

# Heuristic 1: Map literals with 3+ keys on same logical unit
# Pattern: %{key1: _, key2: _, key3: _} (3+ comma-separated key-value pairs)
if echo "$CONTENT" | grep -qE '%\{[^}]*:[^,}]+,[^}]*:[^,}]+,[^}]*:[^,}]+'; then
  SUGGEST_STRUCT=true
  REASONS="${REASONS}- Found map literals with 3+ keys\n"
fi

# Heuristic 2: Constructor-like functions returning maps
# Pattern: def new(...) do %{...} or def build(...) do %{...}
if echo "$CONTENT" | grep -qE 'def\s+(new|build|create|init)\s*\([^)]*\)\s*(do|,)'; then
  if echo "$CONTENT" | grep -qE 'def\s+(new|build|create|init).*%\{'; then
    SUGGEST_STRUCT=true
    REASONS="${REASONS}- Found constructor function (new/build/create/init) returning a map\n"
  fi
fi

# Heuristic 3: Multiple functions with same map key patterns (repeated shapes)
# Count unique map key patterns - if same keys appear multiple times, suggest struct
MAP_KEYS=$(echo "$CONTENT" | grep -oE '%\{[^}]+\}' | sed 's/:[^,}]*//g' | sort | uniq -d)
if [[ -n "$MAP_KEYS" ]]; then
  SUGGEST_STRUCT=true
  REASONS="${REASONS}- Found repeated map patterns with same keys\n"
fi

# Heuristic 4: Functions that update maps with Map.put/Map.merge on same keys
if echo "$CONTENT" | grep -qE 'Map\.(put|merge)\s*\(' | head -3 | wc -l | grep -qE '[2-9]'; then
  SUGGEST_STRUCT=true
  REASONS="${REASONS}- Found multiple Map.put/merge operations (struct would provide better validation)\n"
fi

# If no patterns detected, suppress output
if [[ "$SUGGEST_STRUCT" != "true" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Build suggestion message
SUGGESTION="📦 **Struct Opportunity Detected**

This module uses map patterns that could benefit from \`defstruct\`:

$(echo -e "$REASONS")
**Benefits of using defstruct:**
- Compile-time key validation (typos caught at compile time)
- \`@enforce_keys\` for required fields
- Pattern matching with \`%MyStruct{}\`
- Default values for optional fields
- Better documentation via \`@type t\`

**Example:**
\`\`\`elixir
defmodule MyModule do
  @enforce_keys [:required_field]
  defstruct [:required_field, optional_field: nil]

  @type t :: %__MODULE__{
    required_field: String.t(),
    optional_field: integer() | nil
  }
end
\`\`\`

Consider if a struct would improve type safety for this module."

# Output as additionalContext (non-blocking)
jq -n \
  --arg context "$SUGGESTION" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $context
    }
  }'

exit 0
