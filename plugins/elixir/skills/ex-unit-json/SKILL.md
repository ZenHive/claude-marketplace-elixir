---
name: ex-unit-json
description: AI-friendly test output with `mix test.json`. This skill should be used when running tests, iterating on failures with --failed, checking coverage with --cover, analyzing failure patterns with --group-by-error, or setting up ex_unit_json. Provides flags, workflows, output schema, and jq patterns. Use instead of `mix test`.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/ex-unit-json.md — do not edit manually -->

## ExUnitJSON - AI-Friendly Test Output

Use `mix test.json` instead of `mix test` for structured JSON output that's easy to parse and process.

### Start Here (Default Workflow)

**v0.3.0+: Default shows only failures (AI-optimized)**

```bash
# First run - see failures directly (default behavior)
mix test.json --quiet

# Iterate on failures (ALWAYS use --failed for speed)
mix test.json --quiet --failed --first-failure

# See all tests when needed
mix test.json --quiet --all
```

When all tests pass, you get an empty tests array:
```json
{"version":1,"summary":{"total":50,"passed":50,"failed":0},"tests":[]}
```

**Automatic reminders:** If you forget `--failed` when failures exist, you'll see:
```
TIP: 3 previous failure(s) exist. Consider:
  mix test.json --failed
  mix test.json test/unit/ --failed
  mix test.json --only integration --failed
```
This warning is automatic - no flag needed. Skipped when already focused (using `--failed`, targeting files/dirs, or using tag filters).

**When NOT to use --failed:**
- After changing test infrastructure, fixtures, or shared setup code
- After adding new test files (new tests won't be in .mix_test_failures)
- When you want to verify a full green suite

### Installation

Add to `mix.exs`:

```elixir
defp deps do
  [
    {:ex_unit_json, "~> 0.4", only: [:dev, :test], runtime: false}
  ]
end
```

**Required** - Add `cli/0` function (Mix doesn't inherit preferred_envs from dependencies):

```elixir
def cli do
  [preferred_envs: ["test.json": :test]]
end
```

Without this, you'll get: `"mix test" is running in the "dev" environment`

### Quick Reference

```bash
# First run - see failures directly (DEFAULT in v0.3.0+)
mix test.json --quiet

# Iterate on failures (fast - only runs previously failed tests)
mix test.json --quiet --failed --first-failure

# Verify all failures fixed
mix test.json --quiet --failed --summary-only

# See all tests (when needed)
mix test.json --quiet --all

# Analyze failure patterns (large suites)
mix test.json --quiet --group-by-error --summary-only

# Filter known issues
mix test.json --quiet --filter-out "credentials" --filter-out "rate limit"

# Full suite health check (when you need total counts)
mix test.json --quiet --summary-only

# Compact JSONL output (one line per test)
mix test.json --quiet --compact

# Code coverage
mix test.json --quiet --cover

# Coverage with threshold (fails if below 80%)
mix test.json --quiet --cover --cover-threshold 80
```

### Key Flags

| Flag | Purpose |
|------|---------|
| `--quiet` | **Default.** Suppresses Logger/warnings for clean JSON. Omit when debugging to see Logger output. |
| `--failed` | Only re-run previously failed tests. Fast iteration. |
| `--summary-only` | Just counts, no test details. Quick health check. |
| `--all` | Include ALL tests (default shows only failures). |
| `--failures-only` | Only include failed tests in output. (DEFAULT in v0.3.0+) |
| `--first-failure` | Stop at first failure. Fastest iteration. |
| `--group-by-error` | Cluster failures by error message. Pattern detection. |
| `--filter-out "X"` | Exclude failures matching pattern. Can repeat. |
| `--output FILE` | Write to file instead of stdout. |
| `--compact` | JSONL output with minimal fields (one line per test). |
| `--no-warn` | Suppress the "use --failed" warning. |
| `--cover` | Enable code coverage collection. |
| `--cover-threshold N` | Fail if overall coverage < N% (requires `--cover`). |

### Recommended Workflows

**1. First run - see failures directly (default)**
```bash
mix test.json --quiet
```
Runs all tests, shows only failures (v0.3.0+ default). No extra flags needed.

**2. Filter noise, see real issues**
```bash
mix test.json --quiet --filter-out "credentials" --filter-out "rate limit"
```
Remove expected failures (missing credentials, rate limits, etc.)

**3. Analyze failure patterns (large suites)**
```bash
mix test.json --quiet --group-by-error --summary-only
```
Groups failures by error message. Use when you have many failures.

**4. Fix one at a time**
```bash
mix test.json --quiet --failed --first-failure
```
Get the first failure, fix it, repeat until green.

**5. Verify fix**
```bash
mix test.json --quiet --failed --summary-only
```
Quick check if failure count decreased.

**6. See all tests (when needed)**
```bash
mix test.json --quiet --all
```
Show all tests including passing. Use when investigating test coverage or structure.

**7. Check code coverage**
```bash
mix test.json --quiet --cover
```
Includes `coverage` object with per-module coverage and uncovered line numbers.

**8. Enforce coverage threshold**
```bash
mix test.json --quiet --cover --cover-threshold 80
```
Fails (exit 2) if overall coverage drops below 80%.

**9. Debug with Logger/warnings visible**
```bash
mix test.json
mix test.json --failed --first-failure
```
Omit `--quiet` when you need to see Logger output, warnings, or IO.inspect debug prints. Uses more context tokens but essential for diagnosing runtime behavior.

### Output Structure (Schema v1)

```json
{
  "version": 1,
  "seed": 12345,
  "summary": {
    "total": 100,
    "passed": 80,
    "failed": 20,
    "skipped": 0,
    "excluded": 0,
    "invalid": 0,
    "filtered": 15,
    "duration_us": 123456,
    "result": "failed"
  },
  "coverage": {
    "total_percentage": 92.5,
    "total_lines": 400,
    "covered_lines": 370,
    "threshold": 80,
    "threshold_met": true,
    "modules": [
      {
        "module": "MyApp.Users",
        "file": "lib/my_app/users.ex",
        "percentage": 95.0,
        "covered_lines": 38,
        "uncovered_lines": [45, 67]
      }
    ]
  },
  "error_groups": [
    {
      "pattern": "Connection refused",
      "count": 10,
      "example": {"file": "...", "line": 42, "name": "...", "module": "..."}
    }
  ],
  "module_failures": [...],
  "tests": [...]
}
```

Notes:
- `version` - Schema version (currently 1)
- `seed` - Random seed used for test ordering
- `coverage` only appears with `--cover`
- `coverage.threshold` and `threshold_met` only appear with `--cover-threshold`
- `filtered` in summary only appears with `--filter-out`
- `error_groups` only appears with `--group-by-error`
- `module_failures` only appears when setup_all failures occur
- `tests` is omitted with `--summary-only`

### Combining with ExUnit Flags

ExUnit flags work alongside ex_unit_json flags:

```bash
# Run only integration tests
mix test.json --only integration --quiet --failures-only

# Run specific file
mix test.json test/my_test.exs --quiet --summary-only

# Seed for reproducibility
mix test.json --seed 12345 --quiet --failures-only
```

### Using jq

For piping to jq, use `MIX_QUIET=1` to suppress compilation messages that would corrupt the JSON stream:

```bash
# Summary - pipes fine (MIX_QUIET=1 prevents compile output from breaking jq)
MIX_QUIET=1 mix test.json --quiet --summary-only | jq '.summary'
MIX_QUIET=1 mix test.json --quiet --group-by-error --summary-only | jq '.error_groups | map({pattern, count})'
MIX_QUIET=1 mix test.json --quiet --group-by-error --summary-only | jq '.error_groups[:5]'

# Full test details - use file (avoids piping issues entirely)
mix test.json --quiet --output /tmp/results.json
jq '.tests[] | select(.state == "failed")' /tmp/results.json
jq '.tests[].file' /tmp/results.json | sort -u
jq '.tests | group_by(.file) | map({file: .[0].file, count: length})' /tmp/results.json
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed (and coverage threshold met, if specified) |
| 2 | Test failures OR coverage below threshold (JSON still valid, check `summary.result` and `coverage.threshold_met`) |

Note: Exit code 2 may trigger shell error display. Use `2>&1` to capture both streams.

### Tips

- **Use `--quiet` by default** - Saves context tokens. Omit when you need to see Logger warnings or debug output
- **Use `--failed` for iteration** - Much faster than running all tests
- **`--group-by-error` reveals patterns** - 50 "connection refused" errors = 1 root cause
- **`--filter-out` is repeatable** - Add multiple patterns to exclude

### Strict Enforcement

For projects where forgetting `--failed` is particularly costly:

```elixir
# config/test.exs
config :ex_unit_json, enforce_failed: true
```

This blocks full test runs when failures exist, requiring `--failed` or focused runs.

### Handling Large Output

For large test suites, output may exceed context limits:

1. **Quick health check**: Use `--summary-only`
2. **Write to file**: Use `--output /tmp/results.json` and read selectively with jq
3. **Reduce noise first**: Use `--filter-out` patterns before requesting full output

```bash
# Example: selective reading from file
mix test.json --quiet --output /tmp/results.json
jq '.error_groups[:5]' /tmp/results.json  # First 5 groups
jq '.tests | length' /tmp/results.json    # Just count
```

### Troubleshooting

**jq parse errors**: If you get `jq: parse error`, compilation output may be mixing with JSON. Use `MIX_QUIET=1` when piping, or use `--output FILE` which avoids piping issues entirely.

**Capturing both streams**:
```bash
mix test.json --quiet --summary-only 2>&1
```
