#!/usr/bin/env bash
# Test suite for claude-md-includes plugin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

PYTHON_SCRIPT="$REPO_ROOT/plugins/claude-md-includes/scripts/process-includes.py"

# Helper to run the processor with a specific project directory
run_processor() {
    local project_dir="$1"
    CLAUDE_PROJECT_DIR="$project_dir" python3 "$PYTHON_SCRIPT" < /dev/null 2>&1
}

# Test runner
test_includes() {
    local test_name="$1"
    local project_dir="$2"
    local expected_pattern="$3"
    local should_contain="$4"  # "true" or "false"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}[TEST]${NC} $test_name"

    local output
    output=$(run_processor "$project_dir")
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo -e "  ${RED}❌ FAIL${NC}: Script exited with code $exit_code"
        echo -e "  ${YELLOW}Output:${NC}"
        echo "$output" | sed 's/^/    /'
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    # Extract additionalContext from JSON
    local context
    context=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext // empty')

    if [ -z "$context" ] && [ "$should_contain" = "true" ]; then
        echo -e "  ${RED}❌ FAIL${NC}: No additionalContext in output"
        echo -e "  ${YELLOW}Output:${NC}"
        echo "$output" | sed 's/^/    /'
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    if [ "$should_contain" = "true" ]; then
        if echo "$context" | grep -q "$expected_pattern"; then
            echo -e "  ${GREEN}✅ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "  ${RED}❌ FAIL${NC}: Expected pattern '$expected_pattern' not found"
            echo -e "  ${YELLOW}Context:${NC}"
            echo "$context" | sed 's/^/    /'
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        if echo "$context" | grep -q "$expected_pattern"; then
            echo -e "  ${RED}❌ FAIL${NC}: Pattern '$expected_pattern' should NOT appear"
            echo -e "  ${YELLOW}Context:${NC}"
            echo "$context" | sed 's/^/    /'
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        else
            echo -e "  ${GREEN}✅ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi
}

# Test for warning in stderr
test_includes_warning() {
    local test_name="$1"
    local project_dir="$2"
    local expected_warning="$3"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}[TEST]${NC} $test_name"

    local output
    local stderr_output
    output=$(CLAUDE_PROJECT_DIR="$project_dir" python3 "$PYTHON_SCRIPT" < /dev/null 2>&1)

    if echo "$output" | grep -q "$expected_warning"; then
        echo -e "  ${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}❌ FAIL${NC}: Expected warning '$expected_warning' not found"
        echo -e "  ${YELLOW}Output:${NC}"
        echo "$output" | sed 's/^/    /'
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

print_summary() {
    echo ""
    echo "================================"
    echo "Test Summary"
    echo "================================"
    echo "Total:  $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "================================"

    if [ "$TESTS_FAILED" -gt 0 ]; then
        exit 1
    fi
}

echo "Testing claude-md-includes Plugin"
echo "================================"
echo ""

# Test 1: Basic include works
test_includes \
    "Basic include: Expands @include directive" \
    "$SCRIPT_DIR/basic-test" \
    "Included Section" \
    "true"

# Test 2: Basic include contains project content
test_includes \
    "Basic include: Preserves project content" \
    "$SCRIPT_DIR/basic-test" \
    "Project Content" \
    "true"

# Test 3: Recursive includes work
test_includes \
    "Recursive include: Expands nested @include" \
    "$SCRIPT_DIR/recursive-test" \
    "Level 2" \
    "true"

# Test 4: Recursive includes preserve structure
test_includes \
    "Recursive include: Contains all levels" \
    "$SCRIPT_DIR/recursive-test" \
    "Level 1" \
    "true"

# Test 5: Circular includes detected
test_includes_warning \
    "Circular include: Detects circular dependency" \
    "$SCRIPT_DIR/circular-test" \
    "Circular include detected"

# Test 6: Code block @include not processed
test_includes \
    "Code block: Processes @include outside code block" \
    "$SCRIPT_DIR/codeblock-test" \
    "REAL_INCLUDE_MARKER" \
    "true"

# Test 7: Code block @include preserved
test_includes \
    "Code block: Does NOT process @include inside code block" \
    "$SCRIPT_DIR/codeblock-test" \
    "SHOULD_NOT_APPEAR" \
    "false"

# Test 8: Security - blocks /etc/passwd
test_includes_warning \
    "Security: Blocks /etc/passwd include" \
    "$SCRIPT_DIR/security-test" \
    "Path not allowed"

# Test 9: No CLAUDE.md returns empty context
test_includes \
    "No CLAUDE.md: Returns empty context" \
    "/tmp" \
    "additionalContext" \
    "false"

print_summary
