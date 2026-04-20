---
name: npm-security-audit
description: npm_ex security auditing and supply chain assessment. Use when evaluating dependency security, checking for CVEs, scanning licenses for compliance (GPL contamination, AGPL, unlicensed), finding deprecated packages, or assessing supply chain risk. Covers mix npm.audit, npm.licenses, npm.deprecations, and the programmatic NPM.Audit/NPM.License/NPM.Deprecation/NPM.SupplyChain APIs with correct argument orders and input types.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/npm-security-audit.md — do not edit manually -->

## npm_ex Security Auditing & Supply Chain Assessment

CVE scanning, license compliance, deprecation detection, supply chain risk scoring.

### Quick Check

```bash
mix npm.audit          # CVEs
mix npm.licenses       # license compliance
mix npm.deprecations   # stale/deprecated packages
```

### CVE Audit (`NPM.Audit`)

```elixir
{:ok, lockfile} = NPM.Lockfile.read()

findings = NPM.Audit.check(lockfile, advisories)       # advisories = list of maps
NPM.Audit.filter_by_severity(findings, :critical)
NPM.Audit.fixable?(finding)
NPM.Audit.summary(findings)                            # %{total:, critical:, high:, moderate:, low:, fixable:}
NPM.Audit.compare_severity(:critical, :high)           # :gt
```

Severity levels (high → low): `:critical`, `:high`, `:moderate`, `:low`, `:info`.

### License Compliance (`NPM.License`)

```elixir
licenses = NPM.License.scan("node_modules")            # PATH string, not lockfile
# => [%{package:, version:, license:}, ...]

NPM.License.summary(licenses)                          # %{total:, permissive:, non_permissive:, unknown:, unique_licenses:}
NPM.License.non_permissive(licenses)                   # GPL, AGPL, SSPL, BSD, compound
NPM.License.permissive?("MIT")                         # true
NPM.License.group_by_license(licenses)
NPM.License.extract(%{"license" => "MIT"})
```

### Deprecation (`NPM.Deprecation`)

```elixir
NPM.Deprecation.scan("node_modules")                   # PATH string
NPM.Deprecation.deprecated?(entry)
NPM.Deprecation.extract(pkg_json_map)
```

### Supply Chain Risk (`NPM.SupplyChain`)

Non-obvious argument order — **pkg_json first, lockfile second**:

```elixir
{:ok, lockfile} = NPM.Lockfile.read()
{:ok, pkg_json} = NPM.PackageJSON.read()

assessment = NPM.SupplyChain.assess(pkg_json, lockfile)
# %{total_packages:, phantom_deps:, integrity_coverage:, risk_level: :low | :medium | :high}

NPM.SupplyChain.risk_score(assessment)                 # 0-100, lower is better
NPM.SupplyChain.format(assessment)
```

**Risk thresholds:** `:low` = integrity ≥ 90% + zero phantom · `:medium` = integrity ≥ 50% + phantom < 5 · `:high` = everything else.

**Phantom deps** count packages in lockfile but not in `package.json` deps — transitive deps are normal, so high phantom count alone isn't alarming. Becomes meaningful combined with low integrity coverage.

### Gotchas

- `License.scan/1`, `Deprecation.scan/1`: path strings, not lockfile maps. Passing a map causes `IO.chardata_to_string` errors.
- `SupplyChain.assess/2`: `(pkg_json, lockfile)`. Passing a single entry makes everything count as phantom.
- `Audit.check/2`: `(lockfile, advisories)`. Each advisory **must** include `:patched_versions` or `summary/1` raises `KeyError`.
- `Audit.format_finding/1`: atom severity (`:high`), not strings.
- `License.permissive?/1`: license string (`"MIT"`), not entry map. Use `permissive?(entry.license)`.
- `Health.grade/1` vs `Health.format_report/1`: may disagree — trust `grade/1`.
- BSD is flagged non-permissive (conservative) — review manually.
- `Lockfile.get_package/1`: reads file. If already in memory, use `Map.get(lockfile, "name")`.

### Decision Framework

| Risk Score | Action |
|---|---|
| 0-19 (low) | Safe to proceed |
| 20-49 (medium) | Review phantom deps + integrity gaps |
| 50+ (high) | Investigate before production |
