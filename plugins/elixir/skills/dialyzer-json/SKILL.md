---
name: dialyzer-json
description: AI-friendly Dialyzer output with `mix dialyzer.json`. This skill should be used when running Dialyzer, analyzing type warnings, prioritizing fixes using fix_hint (code/spec/pattern), grouping warnings by file or type, or setting up dialyzer_json. Use instead of `mix dialyzer`.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/dialyzer-json.md — do not edit manually -->

## DialyzerJSON - AI-Friendly Dialyzer Output

Use `mix dialyzer.json` instead of `mix dialyzer` for structured JSON output that's easy to parse and prioritize.

### Quick Start

```bash
# Basic JSON output (clean for piping)
mix dialyzer.json --quiet

# Summary only (quick health check)
mix dialyzer.json --quiet --summary-only

# Group by file (see which files need work)
mix dialyzer.json --quiet --group-by-file

# Filter to specific warning types
mix dialyzer.json --quiet --filter-type no_return --filter-type call
```

### Installation

Add to `mix.exs`:

```elixir
defp deps do
  [
    {:dialyzer_json, "~> 0.1", only: [:dev, :test], runtime: false}
  ]
end
```

**Required** - Add `cli/0` function (Mix doesn't inherit preferred_envs from dependencies):

```elixir
def cli do
  [preferred_envs: ["dialyzer.json": :dev]]
end
```

### Key Flags

| Flag | Purpose |
|------|---------|
| `--quiet` | **Always use.** Suppresses compilation noise for clean JSON. |
| `--summary-only` | Just counts by type. Quick health check. |
| `--group-by-warning` | Cluster warnings by type. Pattern detection. |
| `--group-by-file` | Cluster warnings by file. See which files need work. |
| `--filter-type TYPE` | Only include warnings of TYPE. Can repeat. |
| `--compact` | JSONL output (one warning per line). |
| `--output FILE` | Write to file instead of stdout. |
| `--ignore-exit-status` | Don't fail on warnings (exit 0). |

### Fix Hints (Prioritization)

Each warning includes a `fix_hint` to help prioritize:

| Hint | Meaning | Action |
|------|---------|--------|
| `"code"` | Likely a real bug | Fix immediately - unreachable code, invalid calls |
| `"spec"` | Typespec mismatch | Fix the `@spec` - code is probably correct |
| `"pattern"` | Common safe-to-ignore | Often intentional - third-party behaviours |
| `"unknown"` | Unrecognized warning | Investigate manually |

### Recommended Workflows

**1. Quick health check**
```bash
mix dialyzer.json --quiet --summary-only | jq '.summary'
```

**2. Find real bugs first**
```bash
mix dialyzer.json --quiet | jq '.warnings[] | select(.fix_hint == "code")'
```

**3. See warnings by file**
```bash
mix dialyzer.json --quiet --group-by-file
```

**4. Focus on specific warning types**
```bash
mix dialyzer.json --quiet --filter-type no_return
```

**5. Most common warning types**
```bash
mix dialyzer.json --quiet | jq '.summary.by_type | to_entries | sort_by(-.value)'
```

### Output Structure

```json
{
  "metadata": {
    "schema_version": "1.0",
    "dialyzer_version": "5.4",
    "elixir_version": "1.19.4",
    "otp_version": "28",
    "run_at": "2026-02-02T07:00:03.768447Z"
  },
  "warnings": [
    {
      "file": "lib/foo.ex",
      "line": 42,
      "column": 5,
      "function": "bar/2",
      "module": "Foo",
      "warning_type": "no_return",
      "message": "Function has no local return",
      "raw_message": "Function bar/2 has no local return.",
      "fix_hint": "code"
    }
  ],
  "summary": {
    "total": 5,
    "skipped": 0,
    "by_type": {"no_return": 2, "call": 3},
    "by_fix_hint": {"code": 4, "spec": 1}
  }
}
```

**Notes:**
- `module` and `function` fields extracted when available (contract/callback warnings)
- `message` uses dialyxir's friendly formatting when available
- `raw_message` is dialyzer's original message

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No warnings found |
| 2 | Warnings found (JSON still valid) |

### Using with jq

For piping to jq, use `MIX_QUIET=1` to suppress compilation messages:

```bash
# Summary
MIX_QUIET=1 mix dialyzer.json --quiet --summary-only | jq '.summary'

# Full output - use file (avoids piping issues)
mix dialyzer.json --quiet --output /tmp/dialyzer.json
jq '.warnings[] | select(.fix_hint == "code")' /tmp/dialyzer.json
```

### Tips

- **Always use `--quiet`** - Compilation output pollutes JSON
- **Check `fix_hint` first** - "code" hints are likely real bugs
- **Use `--group-by-file`** - See which files need the most attention
- **`--filter-type` is repeatable** - Combine multiple types with OR logic
