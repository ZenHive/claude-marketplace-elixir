---
name: npm-dep-analysis
description: npm_ex dependency graph analysis, size optimization, and package quality scoring. Use when node_modules is too large, investigating why a package was pulled in, deduplicating dependencies, understanding the dependency graph shape (fan-in/fan-out/cycles), evaluating package quality, or optimizing install size. Covers mix npm.stats, npm.size, npm.tree, npm.why, npm.dedupe, npm.deps, and the programmatic NPM.DepGraph/NPM.Size/NPM.Why/NPM.Dedupe/NPM.PackageQuality/NPM.Health APIs with correct argument types and two-step patterns.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/npm-dep-analysis.md — do not edit manually -->

## npm_ex Dependency Graph Analysis & Size Optimization

Tools for understanding why your dependency tree looks the way it does, finding the heaviest packages, and reducing bloat.

### Investigation Workflow

```bash
# 1. Overview — how many packages, direct vs transitive
mix npm.stats

# 2. Size — where's the disk space going?
mix npm.size

# 3. Trace — why is a specific package installed?
mix npm.why <package>

# 4. Visualize — full dependency tree
mix npm.tree

# 5. Optimize — flatten duplicate versions
mix npm.dedupe
```

### Dependency Graph (`NPM.DepGraph`)

Build and query the graph from the lockfile. The key pattern: `adjacency_list/1` takes the lockfile, but all other functions take the adjacency list output.

```elixir
{:ok, lockfile} = NPM.Lockfile.read()

# Step 1: Build adjacency list FROM LOCKFILE
adj = NPM.DepGraph.adjacency_list(lockfile)
# => %{"ccxt" => ["ws"], "piscina" => ["eventemitter-asyncresource", ...], ...}

# Step 2: All remaining functions take THE ADJACENCY LIST, not lockfile
fan_out = NPM.DepGraph.fan_out(adj)
# => %{"piscina" => 4, "ast-transpiler" => 3, "ccxt" => 1, "ws" => 0, ...}

fan_in = NPM.DepGraph.fan_in(adj)
# => %{"ws" => 1, "typescript" => 1, "ccxt" => 0, "ast-transpiler" => 0, ...}

leaves = NPM.DepGraph.leaves(adj)
# => ["@assemblyscript/loader", "base64-js", "colorette", "node-addon-api", ...]

roots = NPM.DepGraph.roots(adj)
# => ["ast-transpiler", "ccxt"]  (packages nothing else depends on)

cycles = NPM.DepGraph.cycles(adj)
# => []  (list of cycle paths, empty = healthy)
```

**Interpreting the graph:**
- **fan_out** = how many deps a package pulls in (high = bloat risk)
- **fan_in** = how many packages depend on this one (high = critical)
- **roots** = your direct dependencies (nothing else requires them)
- **leaves** = terminal packages with no sub-dependencies
- **cycles** = circular dependencies (rare but problematic)

### Size Analysis (`NPM.Size`)

```elixir
# analyze/1 takes a PATH STRING, returns sorted list (largest first)
sizes = NPM.Size.analyze("node_modules")
# => [%{name: "typescript", size: 66_849_652, version: "4.9.5", file_count: 108}, ...]

# Top N largest — also takes a PATH STRING (re-analyzes), not a list
top5 = NPM.Size.top("node_modules", 5)

# Aggregates from the analyzed list
NPM.Size.total_size(sizes)   # => 183_690_883 (bytes)
NPM.Size.total_files(sizes)  # => 3847
NPM.Size.format_size(66_849_652)  # => "63.8 MB"
```

### Dependency Tracing (`NPM.Why`)

```elixir
{:ok, lockfile} = NPM.Lockfile.read()
{:ok, pkg_json} = NPM.PackageJSON.read()

# explain/3 takes (package_name, lockfile, pkg_json)
reasons = NPM.Why.explain("ws", lockfile, pkg_json)
# => [%{path: ["ccxt", "ws"], range: "^8.8.1", direct: false}]

NPM.Why.dependents("ws", lockfile)
NPM.Why.format_reasons(reasons)
```

**Note:** `NPM.Why.direct?/2` checks lockfile presence, not package.json. Use `Map.has_key?(pkg_json, name)` for a true direct-dependency check.

### Deduplication (`NPM.Dedupe`)

```elixir
{:ok, lockfile} = NPM.Lockfile.read()

dupes = NPM.Dedupe.find_duplicates(lockfile)
summary = NPM.Dedupe.summary(lockfile)
# => %{total_packages: 15, duplicate_groups: 0, saveable: 0, unique_packages: 15}

NPM.Dedupe.savings_estimate(lockfile)
```

### Package Quality (`NPM.PackageQuality`)

Scores individual packages on metadata completeness. Takes a **single lockfile entry**.

```elixir
{:ok, lockfile} = NPM.Lockfile.read()
entry = lockfile["ccxt"]

NPM.PackageQuality.score(entry)           # => 5
NPM.PackageQuality.grade(entry)           # => "A"
NPM.PackageQuality.missing_fields(entry)  # => ["description", "license", ...]
NPM.PackageQuality.rank(lockfile)         # rank all packages
```

**Note:** Scores are based on lockfile metadata which is deliberately sparse. Low absolute scores are expected.

### Project Health (`NPM.Health`)

```elixir
health = NPM.Health.score(%{
  lockfile: lockfile,
  pkg_json: pkg_json,
  node_modules: "node_modules"
})
# => %{score: 25, details: %{has_lockfile: 0, ...}}

NPM.Health.grade(health)
NPM.Health.recommendations(health)
```

### Gotchas

- **`NPM.DepGraph` two-step pattern**: `adjacency_list/1` takes lockfile. Everything else takes the adjacency list. Passing lockfile to `fan_out` crashes.
- **`NPM.Size.analyze/1` and `top/2` take path strings**, not lists.
- **`NPM.PackageQuality.score/1` takes a single entry** (`lockfile["name"]`), not the whole lockfile.
- **`NPM.Why.direct?/2` is misleading** — checks lockfile key presence, not package.json.
- **`NPM.Health.score/1` takes a checks map** with `:lockfile`, `:pkg_json`, `:node_modules` keys.

### Optimization Playbook

1. `mix npm.stats` — if transitive >> direct, investigate heavy fan-out packages
2. `mix npm.size` — find the top 10 largest packages
3. For each heavy package: `mix npm.why <pkg>` — is the dependency chain necessary?
4. `mix npm.dedupe` — reduce duplicate versions where semver allows
5. Re-run `mix npm.stats` to measure improvement
