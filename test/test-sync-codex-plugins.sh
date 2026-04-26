#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SYNC_SCRIPT="$REPO_ROOT/scripts/sync-codex-plugins.py"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-sync-test.XXXXXX")"
trap 'python3 -c "from pathlib import Path; import shutil, sys; shutil.rmtree(Path(sys.argv[1]), ignore_errors=True)" "$TMP_ROOT"' EXIT

assert_file_exists() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Expected file to exist: $path"
    return 1
  fi
}

assert_dir_missing() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "Expected path to be absent: $path"
    return 1
  fi
}

run_test() {
  local name="$1"
  shift

  TESTS_RUN=$((TESTS_RUN + 1))
  echo -e "${YELLOW}[TEST]${NC} $name"

  if "$@"; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

make_stub_core_sync() {
  local stub_path="$1"
  local record_path="$2"
  cat >"$stub_path" <<EOF
#!/usr/bin/env python3
from pathlib import Path
import sys

record = Path(${record_path@Q})
record.parent.mkdir(parents=True, exist_ok=True)
record.write_text(" ".join(sys.argv[1:]) + "\\n", encoding="utf-8")
EOF
  chmod +x "$stub_path"
}

test_dry_run_does_not_write() {
  local root="$TMP_ROOT/dry-run"
  local plugins_root="$root/plugins"
  local marketplace="$root/.agents/plugins/marketplace.json"
  local hooks_path="$root/.codex/hooks.json"
  local record="$root/core-sync.txt"
  local stub="$root/stub-core-sync.py"

  mkdir -p "$root"
  make_stub_core_sync "$stub" "$record"

  python3 "$SYNC_SCRIPT" \
    --dry-run \
    --plugin staged-review \
    --repo-root "$REPO_ROOT" \
    --plugins-root "$plugins_root" \
    --marketplace-path "$marketplace" \
    --hooks-path "$hooks_path" \
    --core-sync-script "$stub" \
    >/dev/null

  assert_file_exists "$record" || return 1
  grep -q -- "--dry-run" "$record" || return 1
  assert_dir_missing "$plugins_root/staged-review" || return 1
  assert_dir_missing "$marketplace" || return 1
  assert_dir_missing "$hooks_path" || return 1
}

test_core_sync_and_apply() {
  local root="$TMP_ROOT/apply"
  local plugins_root="$root/plugins"
  local plugins_root_resolved
  local marketplace="$root/.agents/plugins/marketplace.json"
  local hooks_path="$root/.codex/hooks.json"
  local record="$root/core-sync.txt"
  local stub="$root/stub-core-sync.py"

  mkdir -p "$root"
  make_stub_core_sync "$stub" "$record"
  plugins_root_resolved="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$plugins_root")"

  python3 "$SYNC_SCRIPT" \
    --apply \
    --repo-root "$REPO_ROOT" \
    --plugins-root "$plugins_root" \
    --marketplace-path "$marketplace" \
    --hooks-path "$hooks_path" \
    --core-sync-script "$stub" \
    >/dev/null

  assert_file_exists "$record" || return 1
  grep -q -- "--apply" "$record" || return 1

  assert_file_exists "$plugins_root/elixir/.codex-plugin/plugin.json" || return 1
  assert_file_exists "$plugins_root/staged-review/.codex-plugin/plugin.json" || return 1
  assert_file_exists "$plugins_root/task-driver/.codex-plugin/plugin.json" || return 1
  assert_file_exists "$plugins_root/staged-review/skills/code-review/SKILL.md" || return 1
  assert_file_exists "$plugins_root/task-driver/skills/task-driver/SKILL.md" || return 1
  assert_file_exists "$plugins_root/elixir/skills/hex-docs-search/SKILL.md" || return 1
  assert_file_exists "$hooks_path" || return 1
  assert_dir_missing "$plugins_root/task-driver/commands" || return 1
  assert_dir_missing "$plugins_root/elixir/skills/development-commands" || return 1
  assert_dir_missing "$plugins_root/serena" || return 1

  jq -e '.hooks.PreToolUse[0].matcher == "Bash"' \
    "$hooks_path" >/dev/null || return 1
  jq -e '.hooks.PostToolUse[0].matcher == "Bash"' \
    "$hooks_path" >/dev/null || return 1
  jq -e '.hooks.UserPromptSubmit[0].matcher == ".*"' \
    "$hooks_path" >/dev/null || return 1
  jq -e '
    all(.hooks.PreToolUse[0].hooks[]; .command | startswith("'"$plugins_root_resolved"'/elixir/scripts/")) and
    all(.hooks.PostToolUse[0].hooks[]; .command | startswith("'"$plugins_root_resolved"'/elixir/scripts/"))
  ' "$hooks_path" >/dev/null || return 1

  jq -e '(has("hooks") | not) and (.skills == "./skills/")' \
    "$plugins_root/elixir/.codex-plugin/plugin.json" >/dev/null || return 1
  jq -e '(has("hooks") | not) and (.skills == "./skills/")' \
    "$plugins_root/staged-review/.codex-plugin/plugin.json" >/dev/null || return 1

  jq -e '(.plugins | length) == 5' "$marketplace" >/dev/null || return 1
  jq -e '.plugins[0].name == "elixir"' "$marketplace" >/dev/null || return 1
  jq -e '.plugins[2].name == "staged-review"' "$marketplace" >/dev/null || return 1
  jq -e '.plugins[3].name == "task-driver"' "$marketplace" >/dev/null || return 1
  jq -e 'all(.plugins[]; .source.path | startswith("./plugins/"))' "$marketplace" >/dev/null || return 1
}

test_filtered_plugin_sync() {
  local root="$TMP_ROOT/filter"
  local plugins_root="$root/plugins"
  local marketplace="$root/.agents/plugins/marketplace.json"
  local hooks_path="$root/.codex/hooks.json"

  mkdir -p "$root"

  python3 "$SYNC_SCRIPT" \
    --apply \
    --skip-core-sync \
    --plugin staged-review \
    --repo-root "$REPO_ROOT" \
    --plugins-root "$plugins_root" \
    --marketplace-path "$marketplace" \
    --hooks-path "$hooks_path" \
    >/dev/null

  assert_file_exists "$plugins_root/staged-review/skills/code-review/SKILL.md" || return 1
  assert_dir_missing "$plugins_root/task-driver" || return 1
  assert_dir_missing "$hooks_path" || return 1
  jq -e '(.plugins | length) == 1 and (.plugins[0].name == "staged-review")' \
    "$marketplace" >/dev/null || return 1
}

test_marketplace_only() {
  local root="$TMP_ROOT/marketplace-only"
  local plugins_root="$root/plugins"
  local marketplace="$root/.agents/plugins/marketplace.json"
  local hooks_path="$root/.codex/hooks.json"

  mkdir -p "$root"

  python3 "$SYNC_SCRIPT" \
    --apply \
    --skip-core-sync \
    --marketplace-only \
    --plugin task-driver \
    --repo-root "$REPO_ROOT" \
    --plugins-root "$plugins_root" \
    --marketplace-path "$marketplace" \
    --hooks-path "$hooks_path" \
    >/dev/null

  assert_dir_missing "$plugins_root/task-driver" || return 1
  assert_dir_missing "$hooks_path" || return 1
  jq -e '(.plugins | length) == 1 and (.plugins[0].name == "task-driver")' \
    "$marketplace" >/dev/null || return 1
}

test_hook_merge_preserves_unmanaged_entries() {
  local root="$TMP_ROOT/hooks-merge"
  local plugins_root="$root/plugins"
  local marketplace="$root/.agents/plugins/marketplace.json"
  local hooks_path="$root/.codex/hooks.json"

  mkdir -p "$(dirname "$hooks_path")"
  cat >"$hooks_path" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "/usr/bin/printf session-start"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/usr/bin/printf keep-me"
          },
          {
            "type": "command",
            "command": "/tmp/old/pre-commit-unified.sh"
          }
        ]
      }
    ]
  }
}
EOF

  python3 "$SYNC_SCRIPT" \
    --apply \
    --skip-core-sync \
    --plugin elixir \
    --repo-root "$REPO_ROOT" \
    --plugins-root "$plugins_root" \
    --marketplace-path "$marketplace" \
    --hooks-path "$hooks_path" \
    >/dev/null

  jq -e '.hooks.SessionStart[0].hooks[0].command == "/usr/bin/printf session-start"' \
    "$hooks_path" >/dev/null || return 1
  jq -e '
    any(.hooks.PreToolUse[]?.hooks[]?; .command == "/usr/bin/printf keep-me") and
    (all(.hooks.PreToolUse[]?.hooks[]?; .command != "/tmp/old/pre-commit-unified.sh"))
  ' "$hooks_path" >/dev/null || return 1
}

run_test "Dry-run previews without writing plugin files" test_dry_run_does_not_write
run_test "Apply sync writes supported plugins and marketplace" test_core_sync_and_apply
run_test "Filtered sync only writes requested plugin" test_filtered_plugin_sync
run_test "Marketplace-only skips plugin directory writes" test_marketplace_only
run_test "Hook sync preserves unrelated existing hook entries" test_hook_merge_preserves_unmanaged_entries

echo ""
echo "================================"
echo "Test Summary"
echo "================================"
echo "Total:  $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "================================"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
