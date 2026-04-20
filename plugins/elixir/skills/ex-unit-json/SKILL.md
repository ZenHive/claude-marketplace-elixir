---
name: ex-unit-json
description: AI-friendly test output with `mix test.json`. This skill should be used when running tests, iterating on failures with --failed, checking coverage with --cover, analyzing failure patterns with --group-by-error, or setting up ex_unit_json. Provides flags, workflows, output schema, and jq patterns. Use instead of `mix test`.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/ex-unit-json.md — do not edit manually -->

## ExUnitJSON — `mix test.json`

AI-friendly JSON test output. Use instead of `mix test`. Default (v0.3.0+) shows only failures.

### Install

```elixir
defp deps do
  [{:ex_unit_json, "~> 0.4", only: [:dev, :test], runtime: false}]
end
```

`cli/0` for `preferred_envs` is required — see `elixir-setup.md`.

### Quick Reference

```bash
mix test.json --quiet                              # first run — failures only (default)
mix test.json --quiet --failed --first-failure     # iterate on failures (fast)
mix test.json --quiet --failed --summary-only      # verify failures fixed
mix test.json --quiet --all                        # include passing tests
mix test.json --quiet --group-by-error --summary-only  # cluster failures
mix test.json --quiet --filter-out "credentials"   # exclude known-noise patterns (repeatable)
mix test.json --quiet --cover --cover-threshold 80 # coverage gate
```

Auto-reminder: if you forget `--failed` when previous failures exist, output includes a TIP suggesting `--failed`. Skipped when already focused (file/dir target or tag filter).

**When NOT to use `--failed`:** after editing fixtures/shared setup, after adding new test files (not in `.mix_test_failures`), or when verifying a full green suite.

### Key Flags

| Flag | Purpose |
|------|---------|
| `--quiet` | **Default.** Suppresses Logger/warnings for clean JSON. Omit when debugging to see runtime output. |
| `--failed` | Re-run only previously failed tests |
| `--summary-only` | Counts only, no test details |
| `--all` | Include passing tests (default shows failures only) |
| `--failures-only` | Failed tests only (default in v0.3.0+) |
| `--first-failure` | Stop at first failure |
| `--group-by-error` | Cluster failures by error message |
| `--filter-out "X"` | Exclude failures matching pattern (repeatable) |
| `--output FILE` | Write to file instead of stdout |
| `--compact` | JSONL output, one line per test |
| `--cover` / `--cover-threshold N` | Coverage collection / fail under N% |

ExUnit flags compose: `mix test.json --only integration --quiet`, `mix test.json test/foo_test.exs --quiet`, `--seed 12345`.

### Output Schema (v1)

```json
{
  "version": 1,
  "seed": 12345,
  "summary": {"total": 100, "passed": 80, "failed": 20, "skipped": 0, "filtered": 15, "duration_us": 123456, "result": "failed"},
  "coverage": {"total_percentage": 92.5, "threshold": 80, "threshold_met": true, "modules": [{"module": "MyApp.Users", "percentage": 95.0, "uncovered_lines": [45, 67]}]},
  "error_groups": [{"pattern": "Connection refused", "count": 10, "example": {"file": "...", "line": 42}}],
  "module_failures": [...],
  "tests": [...]
}
```

Conditional fields: `coverage` only with `--cover`; `coverage.threshold_met` only with `--cover-threshold`; `filtered` only with `--filter-out`; `error_groups` only with `--group-by-error`; `module_failures` only on `setup_all` failure; `tests` omitted with `--summary-only`.

### Using jq

Piping requires `MIX_QUIET=1` to suppress compilation output that would corrupt the JSON stream. For full output, prefer `--output FILE` over piping.

```bash
MIX_QUIET=1 mix test.json --quiet --summary-only | jq '.summary'
MIX_QUIET=1 mix test.json --quiet --group-by-error --summary-only | jq '.error_groups | map({pattern, count})'

mix test.json --quiet --output /tmp/results.json
jq '.tests[] | select(.state == "failed")' /tmp/results.json
jq '.tests | group_by(.file) | map({file: .[0].file, count: length})' /tmp/results.json
```

For large suites that exceed context: `--summary-only`, or `--output FILE` + selective jq.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed (and coverage threshold met if set) |
| 2 | Failures OR coverage below threshold — JSON still valid, check `summary.result` / `coverage.threshold_met` |

Exit 2 may trigger shell error display; use `2>&1` to capture both streams.

### Strict Enforcement (optional)

```elixir
# config/test.exs
config :ex_unit_json, enforce_failed: true
```

Blocks full test runs when failures exist unless `--failed` or a focused filter is used.
