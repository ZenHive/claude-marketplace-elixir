# elixir

Essential Elixir development support plugin for Claude Code.

## Installation

```bash
claude
/plugin install elixir@deltahedge
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- Run from an Elixir project directory (with mix.exs)
- curl and jq (for hex-docs-search skill)

## Features

### Automatic Hooks

Each hook is tagged as **convention** (permanent quality gate) or **model-limitation** (compensates for current model weaknesses — review when models improve). See [workflow philosophy](https://www.anthropic.com/engineering/harness-design-long-running-apps) for rationale.

**PostToolUse - After file edits:**
- ✅ **Auto-format** `[convention]` - Automatically runs `mix format` on edited .ex/.exs files
- ✅ **Compile check** `[convention]` - Runs `mix compile --warnings-as-errors` to catch errors immediately
- ✅ **Hidden test failure detection** `[convention]` - Warns when test files contain patterns that silently pass on errors
- ✅ **Private function docs check** `[convention]` - Warns when `defp` functions are missing `@doc false` or comments
- ✅ **Typespec check** `[convention]` - Warns when public `def` functions are missing `@spec`
- ✅ **Typedoc check** `[convention]` - Warns when type definitions are missing `@typedoc`

**PostToolUse - After reading files:**
- ✅ **Documentation recommendation on read** `[model-limitation]` - Detects dependency usage in files and suggests documentation lookup

**PreToolUse - Before git commits:**
- ✅ **Pre-commit validation** `[convention]` - Ensures code is formatted, compiles, and has no unused deps before committing

**PreToolUse - Before running tests:**
- ✅ **Suggest --failed** `[model-limitation]` - On 2nd consecutive `mix test`, suggests `--failed --trace` to speed up test-fix cycles
- ✅ **Prefer test.json** `[convention]` - Blocks `mix test` and redirects to `mix test.json` for AI-friendly output
- ✅ **Prefer dialyzer.json** `[convention]` - Blocks `mix dialyzer` and redirects to `mix dialyzer.json` for AI-friendly output
- ✅ **Suggest --include on test.json** `[model-limitation]` - When `mix test.json` runs without `--include`, reads `test/test_helper.exs` and injects the excluded tags into context so Claude can't falsely claim a full-suite pass. Non-blocking (doesn't force slow integration runs on every iteration).

**UserPromptSubmit - On user input:**
- ✅ **Documentation recommendation** `[model-limitation]` - Suggests using documentation skills when prompt mentions project dependencies

**SessionStart - On session start:**
- ✅ **Branch behind origin/main** `[convention]` - `git fetch origin main` and warns if the working branch is behind. Pairs with the `[CX]` Codex delegation flow (`task-driver` Step 3.5) so Claude rebases before reviewing a PR or claiming a roadmap task that Codex may have advanced. Fails open on no-repo / fetch errors.

### Skills

**hex-docs-search** - Intelligent Hex package documentation search with progressive fetching:
- 🔍 **Local deps search** - Searches installed packages in `deps/` directory for code and docs
- 💾 **Fetched cache** - Checks previously fetched documentation and source in `.hex-docs/` and `.hex-packages/`
- ⬇️ **Progressive fetch** - Automatically fetches missing documentation or source code locally (with version prompting)
- 📚 **Codebase usage** - Finds real-world usage examples from your project
- 🌐 **HexDocs API** - Queries hex.pm API for official documentation
- 🔎 **Web fallback** - Uses web search when other methods don't provide enough information
- 🚀 **Offline-capable** - Once fetched, documentation and source available without network access

See [skills/hex-docs-search/SKILL.md](skills/hex-docs-search/SKILL.md) for details.

**usage-rules** - Package best practices and coding conventions search:
- 🔍 **Local deps search** - Searches installed packages in `deps/` for usage-rules.md files
- 💾 **Fetched cache** - Checks previously fetched rules in `.usage-rules/`
- ⬇️ **Progressive fetch** - Automatically fetches missing usage rules when needed
- 🎯 **Context-aware** - Extracts relevant sections based on coding context (querying, errors, etc.)
- 📝 **Pattern examples** - Shows good/bad code examples from package maintainers
- 🤝 **Integrates with hex-docs-search** - Combine for comprehensive "best practices + API" guidance
- 🚀 **Offline-capable** - Once fetched, usage rules available without network access

See [skills/usage-rules/SKILL.md](skills/usage-rules/SKILL.md) for details.

## Hook Timeouts

| Hook | Timeout | Rationale |
|------|---------|-----------|
| auto-format | 15s | Single file formatting is fast |
| compile-check | 20s | Incremental compilation after edit |
| detect-hidden-failures | 10s | Pattern matching in test files |
| private-function-docs-check | 10s | Line-by-line pattern matching |
| typespec-check | 10s | Line-by-line pattern matching |
| typedoc-check | 10s | Line-by-line pattern matching |
| recommend-docs-on-read | 10s | Dependency detection in file |
| pre-commit-check | 45s | Format check + compile + unused deps |
| suggest-test-failed | 5s | Counter check and JSON output |
| reset-test-tracker | 5s | Check output for "0 failures" |
| recommend-docs-lookup | 10s | Dependency matching in user prompt |
| prefer-test-json | 5s | Command pattern matching |
| prefer-dialyzer-json | 5s | Command pattern matching |

## Hooks Behavior

### Auto-format (Non-blocking)
```bash
mix format {{file_path}}
```
- Runs automatically after editing .ex or .exs files
- Non-blocking - just formats and continues
- Fast - only formats the changed file

### Compile Check (Blocking on errors)
```bash
mix compile --warnings-as-errors
```
- Runs after editing .ex or .exs files
- Blocks on compilation errors - Claude must fix before continuing
- Output truncated to 50 lines to avoid overwhelming context

### Hidden Test Failure Detection (Non-blocking)
- Runs after editing `_test.exs` files
- Detects patterns that silently pass on errors:
  - `{:error, _} -> assert true` (makes ALL failures pass)
  - `{:error, _reason} -> :ok` (silent pass on any error)
- Provides warning via `additionalContext` with correct alternatives
- Non-blocking - warns but doesn't prevent edits
- **Why this matters:** Tests should FAIL on unexpected errors. Silent passes hide bugs.

### Private Function Docs Check (Non-blocking)
- Runs after editing `.ex` files (skips test files)
- Warns when `defp` functions are missing:
  - `@doc false` - explicitly marks function as private
  - Explanatory comment - describes what the function does
- Handles multi-clause functions (only checks first clause)
- Exempts one-liner functions from comment requirement
- Non-blocking - provides context via `additionalContext`
- **Why this matters:** `@doc false` signals intent; comments help future readers.

### Typespec Check (Non-blocking)
- Runs after editing `.ex` files (skips test files)
- Warns when public `def` functions are missing `@spec`
- Checks up to 5 lines above for matching `@spec function_name`
- Exempts callback implementations (functions with `@impl true`)
- Handles multi-clause functions (only checks first clause)
- Non-blocking - provides context via `additionalContext`
- **Why this matters:** Specs enable Dialyzer, improve documentation, and clarify types.

### Typedoc Check (Non-blocking)
- Runs after editing `.ex` files (skips test files)
- Warns when type definitions are missing `@typedoc`:
  - `@type` - public types
  - `@typep` - private types
  - `@opaque` - opaque types
- Checks up to 3 lines above for `@typedoc`
- Non-blocking - provides context via `additionalContext`
- **Why this matters:** Typedocs explain what types represent and their structure.

### Pre-commit Validation (Blocking)
```bash
mix format --check-formatted &&
mix compile --warnings-as-errors &&
mix deps.unlock --check-unused
```
- Runs before any `git commit` command (including `git add && git commit`)
- Blocks commit if any check fails
- Three checks:
  1. All files are formatted
  2. Code compiles without warnings
  3. No unused dependencies
- **Note**: Skips if project has a `precommit` alias (defers to precommit plugin)

### Suggest --failed for Repeated Tests (Non-blocking)
- Runs before `mix test` commands (without `--failed`)
- On 2nd consecutive run, suggests optimization flags:
  - `mix test --failed` - only runs previously failed tests
  - `mix test --failed --trace` - adds detailed output
  - `mix test --failed --seed 0` - deterministic order for debugging
- Counter resets when:
  - User runs `mix test --failed`
  - Tests pass (0 failures in output)
  - 10 minutes elapse between test runs
- **Why this matters**: Running full test suite repeatedly while fixing failures wastes time

### Prefer test.json (Blocking)
- Intercepts `mix test` commands and blocks them
- Allows `mix test.json` variants to pass through
- Provides installation instructions for `ex_unit_json` if not installed
- **Why this matters**: JSON output is easier for AI to parse and analyze

### Prefer dialyzer.json (Blocking)
- Intercepts `mix dialyzer` commands and blocks them
- Allows `mix dialyzer.json` variants to pass through
- Provides installation instructions for `dialyzer_json` if not installed
- **Why this matters**: JSON output is easier for AI to parse and analyze

### Documentation Recommendation (Non-blocking)
- Runs when user submits a prompt
- Detects when prompt mentions project dependencies (e.g., "Ash", "Ecto", "Phoenix")
- Recommends using hex-docs-search or usage-rules skills for documentation lookup
- Uses fuzzy matching to handle case variations and naming conventions
- Caches dependency list in `.hex-docs/deps-cache.txt` for performance
- Cache invalidates when `mix.lock` changes

### Documentation Recommendation on Read (Non-blocking)
- Runs when reading .ex or .exs files
- Detects dependency module references in the file (e.g., `Jason.decode()`, `Ecto.Query.from()`)
- Extracts modules from both aliased (`alias Ecto.Query`) and direct usage (`Jason.decode()`)
- Smart matching: Reports both base and specific dependencies (e.g., `Phoenix.LiveView` → `phoenix, phoenix_live_view`)
- Excludes unrelated dependencies with similar names (e.g., won't report `phoenix_html` when only `Phoenix.LiveView` is used)
- Recommends using hex-docs-search or usage-rules skills for matched dependencies
- Shares dependency cache with UserPromptSubmit hook for efficiency
