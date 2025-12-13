# claude-md-includes Plugin Tests

This directory contains tests for the claude-md-includes plugin.

## Running Tests

```bash
./test-includes-hooks.sh
```

Or from the repository root:
```bash
./test/plugins/claude-md-includes/test-includes-hooks.sh
```

## Test Fixtures

### basic-test/
Tests basic `@include` functionality:
- CLAUDE.md includes `./includes/section1.md`
- Verifies content is merged correctly

### recursive-test/
Tests nested includes:
- CLAUDE.md → level1.md → level2.md
- Verifies multi-level recursion works

### circular-test/
Tests circular dependency detection:
- file_a.md includes file_b.md
- file_b.md includes file_a.md
- Verifies warning is produced

### codeblock-test/
Tests code block awareness:
- @include outside code block is processed
- @include inside ``` block is preserved as-is

### security-test/
Tests path security validation:
- @include /etc/passwd should be blocked
- Verifies security warnings are produced

## What the Tests Verify

1. **Basic inclusion** - @include directives expand correctly
2. **Recursive inclusion** - Nested includes work
3. **Circular detection** - Circular dependencies produce warnings
4. **Code block awareness** - @include in code blocks is preserved
5. **Security validation** - Sensitive paths are blocked
6. **Empty project** - Missing CLAUDE.md returns empty context
