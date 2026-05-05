#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing cloud-delegation Plugin Hooks"
echo "================================"
echo ""

# =============================================================================
# Fixture setup
# =============================================================================
# Layout:
#   $FIXTURE/portfolio/repoA/CLAUDE.md   + AGENTS.md  ← regen target
#   $FIXTURE/portfolio/repoB/CLAUDE.md               ← skipped (no AGENTS.md)
#   $FIXTURE/user-claude/CLAUDE.md
#   $FIXTURE/user-claude/includes/foo.md
#   $FIXTURE/user-claude/includes/nested/bar.md      ← excluded (subdir)

FIXTURE=$(mktemp -d)
# canonicalize (macOS /tmp is a symlink to /private/tmp)
FIXTURE=$(cd "$FIXTURE" && pwd -P)
trap 'rm -rf "$FIXTURE"' EXIT

PORT="$FIXTURE/portfolio"
UC="$FIXTURE/user-claude"

mkdir -p "$PORT/repoA" "$PORT/repoB" "$UC/includes/nested"

cat > "$PORT/repoA/CLAUDE.md" <<'EOF'
# repoA project instructions

Some project notes.
EOF
cp "$PORT/repoA/CLAUDE.md" "$PORT/repoA/AGENTS.md"

cat > "$PORT/repoB/CLAUDE.md" <<'EOF'
# repoB project instructions

repoB has no AGENTS.md — opt-out.
EOF

cat > "$UC/CLAUDE.md" <<'EOF'
# Global user instructions

@includes/foo.md
EOF

cat > "$UC/includes/foo.md" <<'EOF'
# Foo include

Some content.
EOF

cat > "$UC/includes/nested/bar.md" <<'EOF'
# Nested include — should NOT trigger
EOF

export AGENTS_SYNC_PORTFOLIO_ROOT="$PORT"
export AGENTS_SYNC_USER_CLAUDE_ROOT="$UC"
export AGENTS_SYNC_SCRIPT="$REPO_ROOT/scripts/sync-agents-md.sh"

HOOK="plugins/cloud-delegation/scripts/agents-md-sync.sh"

# =============================================================================
# Cases
# =============================================================================

# 1: user-scope global → walks portfolio, mentions repoA, not repoB
test_hook_json \
  "User-scope CLAUDE.md edit triggers portfolio walk (repoA only)" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$UC/CLAUDE.md\"},\"cwd\":\"$UC\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("repoA") and (contains("repoB") | not)'

# 2: user-scope include (direct child of includes/)
test_hook_json \
  "User-scope include edit triggers portfolio walk" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$UC/includes/foo.md\"},\"cwd\":\"$UC\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("repoA")'

# 3: nested include subdir → suppressed (only direct children of includes/ count)
test_hook_json \
  "Nested include subdir does NOT trigger (suppressOutput)" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$UC/includes/nested/bar.md\"},\"cwd\":\"$UC\"}" \
  0 \
  '.suppressOutput == true'

# 4: project-scope CLAUDE.md → single-repo sync
test_hook_json \
  "Project-scope CLAUDE.md edit syncs only that repo" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$PORT/repoA/CLAUDE.md\"},\"cwd\":\"$PORT/repoA\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("repoA")'

# 5: project-scope CLAUDE.md but repo has no AGENTS.md → suppress
test_hook_json \
  "Project-scope CLAUDE.md without AGENTS.md is skipped (suppressOutput)" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$PORT/repoB/CLAUDE.md\"},\"cwd\":\"$PORT/repoB\"}" \
  0 \
  '.suppressOutput == true'

# 6: non-trigger file (.ex) inside a portfolio repo → suppress
mkdir -p "$PORT/repoA/lib"
echo "defmodule Foo do end" > "$PORT/repoA/lib/foo.ex"
test_hook_json \
  "Non-trigger file (.ex) does NOT invoke sync (suppressOutput)" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$PORT/repoA/lib/foo.ex\"},\"cwd\":\"$PORT/repoA\"}" \
  0 \
  '.suppressOutput == true'

# 7: CLAUDE.md outside portfolio root → suppress
OUTSIDE=$(mktemp -d)
OUTSIDE=$(cd "$OUTSIDE" && pwd -P)
echo "# random" > "$OUTSIDE/CLAUDE.md"
test_hook_json \
  "CLAUDE.md outside portfolio root is ignored (suppressOutput)" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$OUTSIDE/CLAUDE.md\"},\"cwd\":\"$OUTSIDE\"}" \
  0 \
  '.suppressOutput == true'
rm -rf "$OUTSIDE"

# 8: empty portfolio + user-scope edit → suppress (no-op)
EMPTY_PORT=$(mktemp -d)
EMPTY_PORT=$(cd "$EMPTY_PORT" && pwd -P)
AGENTS_SYNC_PORTFOLIO_ROOT="$EMPTY_PORT" \
test_hook_json \
  "Empty portfolio with user-scope edit produces no output (suppressOutput)" \
  "$HOOK" \
  "{\"tool_input\":{\"file_path\":\"$UC/CLAUDE.md\"},\"cwd\":\"$UC\"}" \
  0 \
  '.suppressOutput == true'
rm -rf "$EMPTY_PORT"

print_summary
