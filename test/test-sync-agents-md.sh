#!/usr/bin/env bash
# Test sync-agents-md.sh — verifies @-import recursion (umbrella case),
# error handling for missing imports, and depth-limit enforcement.

set -eo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SYNC="$REPO_ROOT/scripts/sync-agents-md.sh"

PASSED=0
FAILED=0

assert_contains() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if grep -qF -- "$needle" "$file"; then
    echo -e "  ${GREEN}✓${NC} $label"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✗${NC} $label — expected: $needle"
    FAILED=$((FAILED + 1))
  fi
}

assert_not_contains() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if grep -qF -- "$needle" "$file"; then
    echo -e "  ${RED}✗${NC} $label — should not contain: $needle"
    FAILED=$((FAILED + 1))
  else
    echo -e "  ${GREEN}✓${NC} $label"
    PASSED=$((PASSED + 1))
  fi
}

# Stage a temporary repo so the script (which reads ./CLAUDE.md) can run.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- Test 1: flat @-import (backward compatibility) ----------------------
echo "Test 1: flat @-import"
mkdir -p "$TMP/flat"
cat >"$TMP/flat/leaf.md" <<'MD'
LEAF_CONTENT
MD
cat >"$TMP/flat/CLAUDE.md" <<MD
# Project
@$TMP/flat/leaf.md
MD
( cd "$TMP/flat" && bash "$SYNC" >/dev/null )
assert_contains "$TMP/flat/AGENTS.md" "LEAF_CONTENT" "leaf content inlined"
assert_contains "$TMP/flat/AGENTS.md" "<!-- @-import: $TMP/flat/leaf.md -->" "leaf import marker"

# --- Test 2: umbrella (one level of nesting) -----------------------------
echo "Test 2: umbrella @-import"
mkdir -p "$TMP/umbrella"
cat >"$TMP/umbrella/inner-a.md" <<'MD'
INNER_A
MD
cat >"$TMP/umbrella/inner-b.md" <<'MD'
INNER_B
MD
cat >"$TMP/umbrella/umbrella.md" <<MD
# Umbrella
@$TMP/umbrella/inner-a.md
@$TMP/umbrella/inner-b.md
MD
cat >"$TMP/umbrella/CLAUDE.md" <<MD
# Project
@$TMP/umbrella/umbrella.md
MD
( cd "$TMP/umbrella" && bash "$SYNC" >/dev/null )
assert_contains "$TMP/umbrella/AGENTS.md" "INNER_A" "inner-a content reached via umbrella"
assert_contains "$TMP/umbrella/AGENTS.md" "INNER_B" "inner-b content reached via umbrella"
assert_contains "$TMP/umbrella/AGENTS.md" "<!-- @-import: $TMP/umbrella/umbrella.md -->" "umbrella import marker"
assert_contains "$TMP/umbrella/AGENTS.md" "<!-- @-import: $TMP/umbrella/inner-a.md -->" "nested inner-a marker"
assert_not_contains "$TMP/umbrella/AGENTS.md" "@$TMP/umbrella/inner-a.md" "no dangling raw @-import line"

# --- Test 3: missing import -> error exit 1 ------------------------------
echo "Test 3: missing import errors out"
mkdir -p "$TMP/missing"
cat >"$TMP/missing/CLAUDE.md" <<MD
# Project
@$TMP/missing/does-not-exist.md
MD
set +e
( cd "$TMP/missing" && bash "$SYNC" >/dev/null 2>&1 )
rc=$?
set -e
if [[ "$rc" -ne 0 ]]; then
  echo -e "  ${GREEN}✓${NC} script exits non-zero on missing import"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✗${NC} script returned 0 despite missing import"
  FAILED=$((FAILED + 1))
fi

# --- Test 4: depth limit -------------------------------------------------
echo "Test 4: depth limit enforced"
mkdir -p "$TMP/deep"
# Build a chain CLAUDE.md → l1 → l2 → l3 → l4 → l5 → l6 → l7 (8 deep, limit is 5).
for n in 1 2 3 4 5 6 7; do
  prev=$((n + 1))
  if [[ $n -lt 7 ]]; then
    echo "@$TMP/deep/l${prev}.md" >"$TMP/deep/l${n}.md"
  else
    echo "BOTTOM" >"$TMP/deep/l${n}.md"
  fi
done
cat >"$TMP/deep/CLAUDE.md" <<MD
@$TMP/deep/l1.md
MD
set +e
( cd "$TMP/deep" && bash "$SYNC" >/dev/null 2>&1 )
rc=$?
set -e
if [[ "$rc" -ne 0 ]]; then
  echo -e "  ${GREEN}✓${NC} script exits non-zero past depth limit"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✗${NC} script accepted chain past depth limit"
  FAILED=$((FAILED + 1))
fi

# --- Summary -------------------------------------------------------------
echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo -e "${GREEN}sync-agents-md.sh: $PASSED passed, 0 failed${NC}"
  exit 0
else
  echo -e "${RED}sync-agents-md.sh: $PASSED passed, $FAILED failed${NC}"
  exit 1
fi
