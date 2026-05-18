#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Marketplace-Hygiene Plugin Hooks"
echo "================================"
echo ""

# =============================================================================
# block-skill-edits.sh — PreToolUse on Edit|Write|MultiEdit
# =============================================================================

echo "## block-skill-edits.sh"
echo ""

# Test 1: Deny on mapped SKILL.md (elixir-setup)
test_hook_json \
  "block: Deny edit to mapped SKILL.md (elixir-setup)" \
  "plugins/marketplace-hygiene/scripts/block-skill-edits.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/elixir/skills/elixir-setup/SKILL.md\"}}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("elixir-setup.md"))'

# Test 2: Deny on mapped SKILL.md (cross-plugin: cloud-delegation/linear-queue)
test_hook_json \
  "block: Deny edit to mapped SKILL.md (linear-queue)" \
  "plugins/marketplace-hygiene/scripts/block-skill-edits.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/cloud-delegation/skills/linear-queue/SKILL.md\"}}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("linear-queue.md"))'

# Test 3: Deny on mapped SKILL.md where include name differs from path (roadmap-planning → task-prioritization.md)
test_hook_json \
  "block: Deny includes name when it differs from the skill dirname (roadmap-planning → task-prioritization.md)" \
  "plugins/marketplace-hygiene/scripts/block-skill-edits.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/elixir/skills/roadmap-planning/SKILL.md\"}}" \
  0 \
  '.hookSpecificOutput.permissionDecisionReason | contains("task-prioritization.md")'

# Test 4: Pass-through for UNmapped SKILL.md (workflow-generator is hand-edited)
test_hook_json \
  "block: Pass-through for unmapped SKILL.md (workflow-generator)" \
  "plugins/marketplace-hygiene/scripts/block-skill-edits.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/elixir-workflows/skills/workflow-generator/SKILL.md\"}}" \
  0 \
  '.suppressOutput == true'

# Test 5: Pass-through for non-SKILL.md edit (script file)
test_hook_json \
  "block: Pass-through for non-SKILL.md (.sh)" \
  "plugins/marketplace-hygiene/scripts/block-skill-edits.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/elixir/scripts/post-edit-check.sh\"}}" \
  0 \
  '.suppressOutput == true'

# Test 6: Pass-through for top-level repo file (README.md)
test_hook_json \
  "block: Pass-through for README.md" \
  "plugins/marketplace-hygiene/scripts/block-skill-edits.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"}}" \
  0 \
  '.suppressOutput == true'

# Test 7: Pass-through when file_path is missing/empty
test_hook_json \
  "block: Pass-through on missing file_path" \
  "plugins/marketplace-hygiene/scripts/block-skill-edits.sh" \
  '{"tool_input":{}}' \
  0 \
  '.suppressOutput == true'

# Test 7b: Regression — script copied OUTSIDE the repo (simulates the
# installed-plugin location at ~/.claude/plugins/cache/...) must still deny
# correctly because REPO_ROOT is now derived from the edited file's directory,
# not from SCRIPT_DIR. Without this case the v0.1.0 bug (script suppresses
# whenever it runs from outside any git repo) would re-regress unnoticed.
# Inlined because test_hook_json prefixes $REPO_ROOT to hook paths.
TESTS_RUN=$((TESTS_RUN + 1))
echo -e "${YELLOW}[TEST]${NC} block: Regression — script outside repo still denies via edited-file path"
SCRIPT_COPY=$(mktemp "/tmp/block-skill-edits.XXXXXX.sh")
cp "$REPO_ROOT/plugins/marketplace-hygiene/scripts/block-skill-edits.sh" "$SCRIPT_COPY"
chmod +x "$SCRIPT_COPY"
regression_out=$(echo "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/elixir/skills/elixir-setup/SKILL.md\"}}" | bash "$SCRIPT_COPY" 2>&1)
if echo "$regression_out" | jq -e '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("elixir-setup.md"))' >/dev/null 2>&1; then
  echo -e "  ${GREEN}✅ PASS${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}❌ FAIL${NC}: external-script case did not deny correctly"
  echo "$regression_out" | sed 's/^/    /'
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$SCRIPT_COPY"

# =============================================================================
# validate-marketplace-json.sh — PostToolUse on Edit|Write|MultiEdit
# =============================================================================

echo ""
echo "## validate-marketplace-json.sh"
echo ""

# Test 8: Pass-through on valid marketplace.json
test_hook_json \
  "validate: Pass-through on valid marketplace.json" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/.claude-plugin/marketplace.json\"}}" \
  0 \
  '.suppressOutput == true'

# Test 9: Pass-through on valid plugin.json
test_hook_json \
  "validate: Pass-through on valid plugin.json" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/elixir/.claude-plugin/plugin.json\"}}" \
  0 \
  '.suppressOutput == true'

# Test 10: Pass-through on valid hooks.json
test_hook_json \
  "validate: Pass-through on valid hooks.json" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/plugins/elixir/hooks/hooks.json\"}}" \
  0 \
  '.suppressOutput == true'

# Test 11: Pass-through on CLAUDE.md (not a tracked JSON manifest)
test_hook_json \
  "validate: Pass-through on CLAUDE.md (non-JSON)" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/CLAUDE.md\"}}" \
  0 \
  '.suppressOutput == true'

# Test 12: Pass-through when basenamed marketplace.json doesn't exist
test_hook_json \
  "validate: Pass-through on missing marketplace.json" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  '{"tool_input":{"file_path":"/nonexistent/path/to/marketplace.json"}}' \
  0 \
  '.suppressOutput == true'

# Test 13: Surface parse error on broken marketplace.json (planted fixture)
BROKEN_DIR=$(mktemp -d "/tmp/marketplace-hygiene-test.XXXXXX")
cat "$REPO_ROOT/.claude-plugin/marketplace.json" > "$BROKEN_DIR/marketplace.json"
echo '}' >> "$BROKEN_DIR/marketplace.json"
test_hook_json \
  "validate: Surface jq parse error on broken marketplace.json" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  "{\"tool_input\":{\"file_path\":\"$BROKEN_DIR/marketplace.json\"}}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PostToolUse" and (.hookSpecificOutput.additionalContext | contains("Invalid JSON in marketplace.json")) and (.hookSpecificOutput.additionalContext | contains("parse error"))'
rm -rf "$BROKEN_DIR"

# Test 14: Surface parse error on broken plugin.json (planted fixture, different basename)
BROKEN_DIR=$(mktemp -d "/tmp/marketplace-hygiene-test.XXXXXX")
mkdir -p "$BROKEN_DIR/.claude-plugin"
echo '{"name": "broken",' > "$BROKEN_DIR/.claude-plugin/plugin.json"  # truncated, invalid
test_hook_json \
  "validate: Surface jq parse error on broken plugin.json" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  "{\"tool_input\":{\"file_path\":\"$BROKEN_DIR/.claude-plugin/plugin.json\"}}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("Invalid JSON in plugin.json")'
rm -rf "$BROKEN_DIR"

# Test 15: Pass-through when file_path is missing/empty
test_hook_json \
  "validate: Pass-through on missing file_path" \
  "plugins/marketplace-hygiene/scripts/validate-marketplace-json.sh" \
  '{"tool_input":{}}' \
  0 \
  '.suppressOutput == true'

print_summary
