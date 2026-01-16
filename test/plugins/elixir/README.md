# Elixir Plugin Tests

This directory contains automated tests for the elixir plugin hooks.

## Running Tests

### Run all elixir plugin tests:
```bash
./test/plugins/elixir/test-elixir-hooks.sh
```

### Run all marketplace tests:
```bash
./test/run-all-tests.sh
```

### Via Claude Code slash command:
```
/qa test elixir
```

## Test Projects

The elixir plugin has three test projects with intentional issues to verify hook behavior:

### 1. autoformat-test/
- **Purpose**: Tests format checking in post-edit hook
- **Contains**: Badly formatted Elixir files
- **Expected behavior**: Format issues detected after editing

### 2. compile-test/
- **Purpose**: Tests compile check and dependency detection
- **Contains**:
  - Elixir code with various module usages (Jason, Ecto, Phoenix)
  - Files for testing dependency detection accuracy
- **Expected behavior**: Compilation errors and module usage detected

### 3. precommit-test/
- **Purpose**: Tests the pre-commit unified validation hook
- **Contains**:
  - `lib/unformatted.ex` - Unformatted code
  - `lib/compilation_error.ex` - Compilation errors
  - No credo/sobelow/doctor deps (tests required dep detection)
- **Expected behavior**: Blocks git commits when validation fails

## Test Coverage

The automated test suite includes 30 tests:

**Post-edit check hook** (`post-edit-check.sh`):
- Ignores non-Elixir files
- Errors when required deps (credo, sobelow, doctor) missing
- Suppresses when not in an Elixir project

**Pre-commit unified hook** (`pre-commit-unified.sh`):
- Ignores non-commit git commands
- Ignores non-git commands
- Blocks on format issues
- Shows format issues in permissionDecisionReason
- Requires credo dependency
- Uses git -C directory instead of CWD
- Falls back to CWD when -C path is invalid
- Suppresses when not in Elixir project

**Documentation recommendation hook** (`recommend-docs-lookup.sh`):
- Detects capitalized dependency names ("Ecto")
- Detects lowercase dependency names ("jason")
- Detects multiple dependencies in one prompt
- Returns empty JSON when no dependencies mentioned
- Handles non-Elixir projects gracefully
- Recommends using hex-docs-search skill

**Documentation recommendation on Read hook** (`recommend-docs-on-read.sh`):
- Detects dependencies from direct module usage (Jason.decode, Ecto.Query.from)
- Ignores non-Elixir files
- Returns empty when file has no dependency references
- Matches exact dependency names (Jason -> jason)
- Excludes unrelated dependencies (Jason used but not ecto, decimal, telemetry)
- Matches both base and specific dependencies (Phoenix.LiveView -> phoenix, phoenix_live_view)
- Excludes unrelated dependencies with similar names (Phoenix.LiveView used but not phoenix_html, phoenix_pubsub, phoenix_template)

**Suggest test failed hook** (`suggest-test-failed.sh`):
- First call suppresses output
- Second call suggests --failed flag
- Using --failed resets counter
- Non-mix-test commands ignored
- Passing tests reset counter

## Hook Implementation

The elixir plugin implements **consolidated hooks** for efficiency:

### PostToolUse Hooks (Edit/Write/MultiEdit)

1. **Post-edit check** (`scripts/post-edit-check.sh`)
   - Trigger: After Edit/Write tools on .ex/.exs files
   - Action: Runs format, compile, credo, sobelow, doctor, struct hints, hidden failure detection, mixexs check
   - Blocking: No (provides context on issues)
   - **Requires**: credo, sobelow, doctor dependencies
   - Timeout: 60s

2. **Ash codegen check** (`scripts/ash-codegen-check.sh`)
   - Trigger: After Edit/Write tools on .ex/.exs files (only if Ash dependency exists)
   - Action: Runs `mix ash.codegen --check`
   - Blocking: No (provides context on out-of-sync codegen)
   - Timeout: 30s

### PostToolUse Hooks (Read)

3. **Documentation recommendation on Read** (`scripts/recommend-docs-on-read.sh`)
   - Trigger: After reading .ex/.exs files
   - Action: Detects dependency module references in file, recommends using hex-docs-search or usage-rules skills
   - Blocking: No (provides helpful context)
   - Caching: Shares dependency cache with UserPromptSubmit hook
   - Timeout: 10s

### PostToolUse Hooks (Bash)

4. **Reset test tracker** (`scripts/reset-test-tracker.sh`)
   - Trigger: After Bash commands complete
   - Action: Resets test failure tracking state after passing tests or --failed flag usage
   - Blocking: No
   - Timeout: 5s

### PreToolUse Hooks (Bash)

5. **Pre-commit unified** (`scripts/pre-commit-unified.sh`)
   - Trigger: Before `git commit` commands
   - Action: Runs format, compile, deps.unlock, credo, test, doctor, sobelow, dialyzer, mix_audit, ash.codegen, ex_doc (if deps exist)
   - Blocking: Yes (JSON permissionDecision: "deny" on failures)
   - **Defers to**: `mix precommit` if alias exists
   - Timeout: 180s

6. **Suggest test failed** (`scripts/suggest-test-failed.sh`)
   - Trigger: Before `mix test` commands
   - Action: Suggests `--failed` flag after repeated test failures
   - Blocking: No (provides helpful suggestion)
   - Timeout: 5s

7. **Phoenix new check** (`scripts/phx-new-check.sh`)
   - Trigger: Before `mix phx.new` commands
   - Action: Detects Phoenix project generation
   - Blocking: No (provides context)
   - Timeout: 5s

8. **Prefer test.json** (`scripts/prefer-test-json.sh`)
   - Trigger: Before `mix test` commands
   - Action: Recommends using `mix test.json` for AI-friendly output
   - Blocking: No (provides helpful suggestion)
   - Timeout: 5s

### UserPromptSubmit Hooks

9. **Documentation recommendation** (`scripts/recommend-docs-lookup.sh`)
   - Trigger: On user prompt submission
   - Action: Detects dependencies mentioned in prompt, recommends using hex-docs-search or usage-rules skills
   - Blocking: No (provides helpful context)
   - Caching: Dependency list cached in `.hex-docs/deps-cache.txt`, invalidates when `mix.lock` changes
   - Timeout: 10s

## Prerequisites

Before running tests, ensure the test projects have dependencies installed:
```bash
cd test/plugins/elixir/autoformat-test && mix deps.get
cd test/plugins/elixir/compile-test && mix deps.get
cd test/plugins/elixir/precommit-test && mix deps.get
```

The elixir plugin must also be installed in Claude Code:
```
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install elixir@deltahedge
```
