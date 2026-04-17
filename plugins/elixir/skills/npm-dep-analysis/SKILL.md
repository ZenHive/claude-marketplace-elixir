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
- **fan_in** = how many packages depend on this one (high = critical, breaking it breaks many things)
- **roots** = your direct dependencies (nothing else requires them)
- **leaves** = terminal packages with no sub-dependencies
- **cycles** = circular dependencies (rare but problematic)

### Size Analysis (`NPM.Size`)

```elixir
# analyze/1 takes a PATH STRING, returns sorted list (largest first)
sizes = NPM.Size.analyze("node_modules")
# => [%{name: "typescript", size: 66_849_652, version: "4.9.5", file_count: 108},
#     %{name: "ccxt", size: 54_662_004, version: "4.5.45", file_count: 1659}, ...]

# Top N largest — also takes a PATH STRING (re-analyzes), not a list
top5 = NPM.Size.top("node_modules", 5)

# Aggregates from the analyzed list
NPM.Size.total_size(sizes)   # => 183_690_883 (bytes)
NPM.Size.total_files(sizes)  # => 3847

# Format for display
NPM.Size.format_size(66_849_652)  # => "63.8 MB"
NPM.Size.summary(sizes)           # => formatted string
```

### Dependency Tracing (`NPM.Why`)

Explains why a package appears in your dependency tree.

```elixir
{:ok, lockfile} = NPM.Lockfile.read()
{:ok, pkg_json} = NPM.PackageJSON.read()

# explain/3 takes (package_name, lockfile, pkg_json)
reasons = NPM.Why.explain("ws", lockfile, pkg_json)
# => [%{path: ["ccxt", "ws"], range: "^8.8.1", direct: false}]

# Trace multiple hops
NPM.Why.explain("@assemblyscript/loader", lockfile, pkg_json)
# => [%{path: ["piscina", "hdr-histogram-js", "@assemblyscript/loader"], ...}]

# dependents/2 — who depends on this package?
NPM.Why.dependents("ws", lockfile)

# Format for display
NPM.Why.format_reasons(reasons)
```

**Note:** `NPM.Why.direct?/2` checks lockfile presence, not package.json. Transitive deps that appear as top-level lockfile entries will report `true`. Use `Map.has_key?(pkg_json, name)` for a true direct-dependency check.

### Deduplication (`NPM.Dedupe`)

Finds packages installed at multiple versions and estimates savings.

```elixir
{:ok, lockfile} = NPM.Lockfile.read()

dupes = NPM.Dedupe.find_duplicates(lockfile)
# => [%{name: "lodash", versions: ["4.17.20", "4.17.21"], ...}]

summary = NPM.Dedupe.summary(lockfile)
# => %{total_packages: 15, duplicate_groups: 0, saveable: 0, unique_packages: 15}

# For a specific duplicate, find the best shared version
NPM.Dedupe.best_shared_version("lodash", lockfile)

# Estimate disk savings from deduplication
NPM.Dedupe.savings_estimate(lockfile)
```

### Package Quality (`NPM.PackageQuality`)

Scores individual packages on metadata completeness. Takes a **single lockfile entry**, not the whole lockfile.

```elixir
{:ok, lockfile} = NPM.Lockfile.read()

# Score one package at a time
entry = lockfile["ccxt"]
NPM.PackageQuality.score(entry)           # => 5 (0-100)
NPM.PackageQuality.grade(entry)           # => "A" (A-F)
NPM.PackageQuality.missing_fields(entry)  # => ["description", "license", ...]

# Rank all packages by quality
NPM.PackageQuality.rank(lockfile)

# Average quality across all deps
NPM.PackageQuality.average(lockfile)
```

**Note:** Quality scores are based on lockfile entry metadata, which is sparse (version, dependencies, tarball, integrity). Scores will be low because the lockfile deliberately omits fields like description, keywords, engines. This is expected — the score is more useful when comparing packages against each other than as an absolute measure.

### Project Health (`NPM.Health`)

Aggregates multiple checks into an overall health score.

```elixir
health = NPM.Health.score(%{
  lockfile: lockfile,
  pkg_json: pkg_json,
  node_modules: "node_modules"
})
# => %{score: 25, details: %{
#   has_lockfile: 0, has_package_json: 0, has_license: 0,
#   integrity_coverage: 0, no_deprecated: 0,
#   up_to_date: 10, no_vulnerabilities: 15
# }}

NPM.Health.grade(health)            # => "D"
NPM.Health.recommendations(health)  # => ["Add a lockfile", ...]
```

### Gotchas

- **`NPM.DepGraph` two-step pattern**: `adjacency_list/1` takes the lockfile map. `fan_in/fan_out/leaves/roots/cycles` take the adjacency list (output of `adjacency_list/1`). Passing the lockfile directly to `fan_out` crashes with `(ArgumentError) not a list`.
- **`NPM.Size.analyze/1` and `NPM.Size.top/2` take path strings**, not lists. `top/2` re-analyzes the directory — it's not a "take N from list" function.
- **`NPM.PackageQuality.score/1` takes a single entry**, not the whole lockfile. The entry is `lockfile["package-name"]`.
- **`NPM.Why.direct?/2` is misleading** — it checks lockfile key presence, so transitive deps at the top level of the lockfile appear "direct". Check `pkg_json` instead.
- **`NPM.Health.score/1` takes a checks map** with `:lockfile`, `:pkg_json`, and `:node_modules` keys — not just a lockfile.

### Optimization Playbook

1. `mix npm.stats` — if transitive >> direct, investigate the heavy fan-out packages
2. `mix npm.size` — find the top 10 largest packages
3. For each heavy package: `mix npm.why <pkg>` — is the dependency chain necessary?
4. `mix npm.dedupe` — reduce duplicate versions where semver allows
5. Re-run `mix npm.stats` to measure improvement
6. Consider `mix npm.remove` for packages that are only used transitively by optional features
