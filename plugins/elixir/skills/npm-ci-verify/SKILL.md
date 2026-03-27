---
name: npm-ci-verify
description: npm_ex CI/CD and installation verification workflows. Use when setting up CI pipelines with npm_ex, debugging lockfile sync issues, ensuring reproducible builds, diagnosing "works locally but fails in CI" problems, or integrating npm_ex into Mix compilers. Covers mix npm.ci, npm.check, npm.verify, npm.doctor, npm.shrinkwrap, the --frozen flag, and the programmatic NPM.CI/NPM.Verify/NPM.Lockfile APIs with correct argument orders.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/npm-ci-verify.md — do not edit manually -->

## npm_ex CI/CD & Installation Verification

Reproducible builds with npm_ex require understanding which verification tool to use when. The tools form a pipeline — each checks a different layer.

### The Verification Stack

| Symptom | Tool | What it checks |
|---------|------|----------------|
| "Is my install healthy?" | `mix npm.doctor` | Overall installation sanity |
| "Does node_modules match lockfile?" | `mix npm.verify` | File presence + version match |
| "Does lockfile match package.json?" | `mix npm.check` | Lockfile freshness |
| "Frozen install for CI" | `mix npm.ci` | Clean install from lockfile only |
| "Lock versions for publishing" | `mix npm.shrinkwrap` | Freeze exact versions |

### CI Pipeline Recipe

```bash
# 1. Verify lockfile is in sync with package.json
mix npm.check

# 2. Clean frozen install (fails if lockfile stale)
mix npm.ci

# 3. Verify node_modules matches what was just installed
mix npm.verify
```

For simpler setups, `mix npm.install --frozen` achieves the same as step 1+2 in one command.

### Programmatic API

The real value is calling these from Elixir code (build scripts, CI tasks, Mix compilers).

**CI validation:**
```elixir
# Preflight check — ensures lockfile + package.json exist
:ok = NPM.CI.preflight()

# Full CI validation
:ok = NPM.CI.validate()

# Check if node_modules needs rebuilding
true = NPM.CI.needs_clean?()
```

**Verify installed packages:**

The argument order matters — `node_modules_dir` comes first, lockfile second:
```elixir
{:ok, lockfile} = NPM.Lockfile.read()

# Returns list of issues (empty = clean)
[] = NPM.Verify.check("node_modules", lockfile)

# Boolean shorthand
true = NPM.Verify.clean?("node_modules", lockfile)
```

**Lockfile operations:**
```elixir
# Read returns {:ok, map} — always unwrap when passing to Verify, DepGraph, etc.
{:ok, lockfile} = NPM.Lockfile.read()

# Convenience helpers are path-based (read the lockfile internally):
NPM.Lockfile.has_package?("ccxt")             # => true (reads npm.lock)
{:ok, names} = NPM.Lockfile.package_names()   # => ["ccxt", "ws", ...]
{:ok, entry} = NPM.Lockfile.get_package("ccxt") # => %{version: ..., ...}

# Optional second arg overrides the lockfile path:
NPM.Lockfile.has_package?("ccxt", "path/to/npm.lock")
```

### Gotchas

- **`NPM.Lockfile.read/0` returns `{:ok, map}`** — forgetting to unwrap is the #1 mistake. Every downstream function expects the bare map.
- **`NPM.Verify.check/2` arg order is `(path, lockfile)`** — the string path comes first, lockfile map second. The typespec confirms: `@spec check(String.t(), map())`.
- **`NPM.CI.needs_clean?/0`** returns `true` when node_modules is stale or missing — it does NOT mean something is broken, just that a reinstall is needed.
- **`mix npm.install --frozen`** vs **`mix npm.ci`**: Both fail on stale lockfiles. `npm.ci` additionally wipes node_modules first for a guaranteed clean slate.

### npm.lock vs npm-shrinkwrap.json

- **`npm.lock`** — Standard lockfile. Checked into version control. Used by `mix npm.install` and `mix npm.ci`.
- **`npm-shrinkwrap.json`** — Created by `mix npm.shrinkwrap`. Intended for published packages where you want consumers to get your exact dependency tree. Rarely needed for applications.

### Mix Compiler Integration

npm_ex includes a Mix compiler that auto-installs on `mix compile`:

```elixir
# mix.exs
def project do
  [
    compilers: [:npm | Mix.compilers()],
    # ...
  ]
end
```

This runs `NPM.install()` as part of the compile step — useful for projects that need npm packages available at compile time (like loading CCXT's browser bundle via QuickBEAM).
