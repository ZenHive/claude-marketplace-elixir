---
name: npm-security-audit
description: npm_ex security auditing and supply chain assessment. Use when evaluating dependency security, checking for CVEs, scanning licenses for compliance (GPL contamination, AGPL, unlicensed), finding deprecated packages, or assessing supply chain risk. Covers mix npm.audit, npm.licenses, npm.deprecations, and the programmatic NPM.Audit/NPM.License/NPM.Deprecation/NPM.SupplyChain APIs with correct argument orders and input types.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/npm-security-audit.md — do not edit manually -->

## npm_ex Security Auditing & Supply Chain Assessment

Multi-layered security analysis for npm dependencies managed by npm_ex. Combines CVE scanning, license compliance, deprecation detection, and supply chain risk scoring.

### Quick Security Check

```bash
mix npm.audit          # CVE vulnerabilities
mix npm.licenses       # License compliance
mix npm.deprecations   # Stale/deprecated packages
```

### CVE / Vulnerability Audit

`mix npm.audit` queries the npm registry's audit endpoint for known vulnerabilities.

**Programmatic API:**
```elixir
{:ok, lockfile} = NPM.Lockfile.read()

# check/2 takes (lockfile, advisories_list)
# advisories is a list of advisory maps, not a map
findings = NPM.Audit.check(lockfile, advisories)

# Filter by severity threshold
critical = NPM.Audit.filter_by_severity(findings, :critical)
high_plus = NPM.Audit.filter_by_severity(findings, :high)

# Check if a finding has a patch available
NPM.Audit.fixable?(finding)  # => true/false

# Aggregate stats
summary = NPM.Audit.summary(findings)
# => %{total: 3, critical: 1, high: 1, moderate: 1, low: 0, fixable: 2}

# Severity comparison for sorting
NPM.Audit.compare_severity(:critical, :high)  # => :gt
```

**Severity levels** (highest to lowest): `:critical`, `:high`, `:moderate`, `:low`, `:info`

### License Compliance

`mix npm.licenses` scans node_modules package.json files for license declarations.

```elixir
# scan/1 takes a PATH STRING, not a lockfile
licenses = NPM.License.scan("node_modules")
# => [%{package: "ccxt", version: "4.5.45", license: "MIT"}, ...]

# Aggregate by license type
summary = NPM.License.summary(licenses)
# => %{total: 16, permissive: 14, non_permissive: 2, unknown: 0,
#       unique_licenses: ["MIT", "Apache-2.0", "BSD", "(MIT AND Zlib)"]}

# Find problematic licenses (GPL, AGPL, SSPL, BSD, compound)
NPM.License.non_permissive(licenses)
# => [%{package: "hdr-histogram-js", license: "BSD"}, ...]

# Check individual license
NPM.License.permissive?("MIT")     # => true
NPM.License.permissive?("GPL-3.0") # => false

# Group for reporting
NPM.License.group_by_license(licenses)
# => %{"MIT" => [...], "Apache-2.0" => [...]}
```

### Deprecation Scanning

`mix npm.deprecations` checks which installed packages are deprecated.

```elixir
# scan/1 takes a PATH STRING
deprecated = NPM.Deprecation.scan("node_modules")
# => [%{package: "...", version: "...", message: "Use xyz instead"}, ...]

# Check a single package entry
NPM.Deprecation.deprecated?(entry)
```

### Supply Chain Risk Assessment

Combines multiple signals into a risk score. The argument order is non-obvious — package.json data first, lockfile second:

```elixir
{:ok, lockfile} = NPM.Lockfile.read()
{:ok, pkg_json} = NPM.PackageJSON.read()

# assess/2 args: (pkg_json_data, lockfile) — NOT (lockfile, advisories)
assessment = NPM.SupplyChain.assess(pkg_json, lockfile)
# => %{
#   total_packages: 15,
#   phantom_deps: 15,
#   integrity_coverage: 100.0,
#   risk_level: :high
# }

# Numeric risk score (0-100, lower is better)
NPM.SupplyChain.risk_score(assessment)  # => 30

# Formatted report
NPM.SupplyChain.format(assessment)
```

**Risk level thresholds:**
- `:low` — integrity >= 90% AND zero phantom deps
- `:medium` — integrity >= 50% AND phantom deps < 5
- `:high` — everything else

**Note on phantom deps:** `phantom_deps` counts packages in the lockfile not in package.json's direct deps. Transitive dependencies far outnumber direct ones in most projects, so a high count is normal — it becomes meaningful when combined with low integrity coverage.

### Gotchas

- **`NPM.License.scan/1` and `NPM.Deprecation.scan/1` take path strings** (`"node_modules"`), not lockfile maps. Passing a lockfile map causes `IO.chardata_to_string` errors.
- **`NPM.SupplyChain.assess/2` argument order is `(pkg_json, lockfile)`** — pass the full package.json deps map (from `NPM.PackageJSON.read()`) as first arg. Passing a single package entry makes `PhantomDep.count` treat everything as phantom.
- **`NPM.Audit.check/2` takes `(lockfile, advisories)`** where advisories is a list of maps. Each advisory **must** include `:patched_versions` or `summary/1` raises `KeyError`.
- **`NPM.Audit.format_finding/1` requires atom severity** (`:high`, `:critical`) not strings. Passing `"high"` raises `ArgumentError`.
- **`NPM.License.permissive?/1` expects a license string** like `"MIT"`, not an entry map. Use `NPM.License.permissive?(entry.license)`.
- **`NPM.Health.grade/1` vs `NPM.Health.format_report/1`** may disagree on the letter grade for the same data — trust `grade/1` for programmatic use.
- **BSD is flagged as non-permissive** by `NPM.License.non_permissive/1`. This is conservative — review flagged BSD packages manually.
- **`NPM.Lockfile.get_package/1`** reads from the lockfile file. If you already have the map in memory, use `Map.get(lockfile, "name")` instead.

### Decision Framework

| Risk Score | Action |
|-----------|--------|
| 0-19 (low) | Safe to proceed |
| 20-49 (medium) | Review phantom deps and integrity gaps |
| 50+ (high) | Investigate before deploying to production |
