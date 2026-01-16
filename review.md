# Claude Code Marketplace Review

**Reviewer**: Claude (Opus 4.5)
**Date**: 2026-01-16
**Perspective**: As the primary user/consumer of this marketplace

---

## Executive Summary

This marketplace has **excellent infrastructure** (shared libraries, well-documented skills) but suffers from **severe plugin fragmentation** that directly impacts my efficiency as Claude Code. Each git commit triggers 10+ separate hook invocations, and the 16-plugin structure creates cognitive overhead without proportional benefit.

**Bottom Line**: Consolidate aggressively. Quality over quantity.

**#1 Priority**: Post-edit hooks (12 per edit) - this runs on EVERY file change and is the biggest efficiency drain.

---

## Current State Analysis

### Plugin Inventory (16 Plugins)

| Plugin | Hooks | Skills | Commands | Primary Purpose |
|--------|-------|--------|----------|-----------------|
| **core** | 8 PostToolUse, 4 PreToolUse, 1 UserPromptSubmit | 17 | 0 | Elixir development essentials |
| **credo** | 1 PostToolUse, 1 PreToolUse | 0 | 0 | Static analysis |
| **ash** | 1 PostToolUse, 1 PreToolUse | 0 | 0 | Ash codegen validation |
| **dialyzer** | 1 PreToolUse | 0 | 0 | Type checking |
| **sobelow** | 1 PostToolUse, 1 PreToolUse | 0 | 0 | Security scanning |
| **ex_doc** | 1 PreToolUse | 0 | 0 | Docs validation |
| **mix_audit** | 1 PreToolUse | 0 | 0 | Dependency audit |
| **ex_unit** | 1 PreToolUse | 0 | 0 | Test validation |
| **precommit** | 1 PreToolUse | 0 | 0 | Phoenix alias runner |
| **doctor** | 1 PreToolUse | 0 | 0 | Moduledoc coverage |
| **elixir-meta** | 0 | 1 | 1 | Workflow generation |
| **git** | 0 | 0 | 1 | Commit workflow |
| **claude-md-includes** | 1 SessionStart | 0 | 0 | Include processing |
| **serena** | 3 (mixed) | 0 | 4 | MCP integration |
| **notifications** | 1 Notification | 0 | 0 | OS notifications |
| **struct-reminder** | 1 PostToolUse | 0 | 0 | Suggest defstruct |

---

## Critical Issues

### Issue 1: Post-Edit Hook Overload (Severity: CRITICAL) [D:4/B:10 → Priority:2.5] 🎯

**Problem**: Every `.ex`/`.exs` file edit triggers **12 separate PostToolUse hooks**:

**From core plugin** (8 hooks):
1. auto-format.sh
2. compile-check.sh
3. detect-hidden-failures.sh
4. roadmap-changelog-reminder.sh
5. private-function-docs-check.sh
6. typespec-check.sh
7. typedoc-check.sh
8. mixexs-check.sh

**From other plugins** (4 hooks):
9. credo/post-edit-check.sh
10. sobelow/post-edit-check.sh
11. ash/post-edit-check.sh
12. struct-reminder/struct-check.sh

**Impact on Claude Code**:
- File edits happen **10-50x more often** than commits
- 12 tool calls per edit = massive token overhead
- Most hooks suppress output (wrong file type) but still execute
- Sequential execution adds latency to every edit operation
- This is the **single biggest efficiency drain** in the marketplace

**Recommendation**: Consolidate into 2-3 focused post-edit hooks:
1. **format-and-compile.sh** - Format + compile (essential, always run)
2. **quality-hints.sh** - Credo, typespecs, private docs, struct suggestions (advisory)
3. **framework-check.sh** - Ash codegen, Sobelow (only if deps present)

**Priority**: 🎯 **Do this first** - Highest frequency = highest impact.

---

### Issue 2: Pre-Commit Hook Fragmentation (Severity: HIGH) [D:5/B:9 → Priority:1.8] 🚀

**Problem**: Every `git commit` triggers **10 separate pre-commit hook scripts** across 10 plugins:
- core, credo, dialyzer, sobelow, ex_doc, mix_audit, ex_unit, precommit, doctor, ash

**Impact on Claude Code**:
- Each hook is a separate tool call that costs tokens and time
- All hooks run sequentially, not in parallel
- Shared library is already well-designed (`precommit_setup()` handles detection)
- The infrastructure exists for consolidation but isn't being used

**Current Flow** (10 tool calls):
```
git commit → core/pre-commit-check.sh
          → credo/pre-commit-check.sh
          → dialyzer/pre-commit-check.sh
          → sobelow/pre-commit-check.sh
          → ex_doc/pre-commit-check.sh
          → mix_audit/pre-commit-check.sh
          → ex_unit/pre-commit-check.sh
          → precommit/pre-commit-check.sh
          → doctor/pre-commit-check.sh
          → ash/pre-commit-check.sh
```

**Recommendation**: Single unified pre-commit hook that runs all enabled checks:
```
git commit → quality-gates/pre-commit-check.sh
             ├── compile check
             ├── format check
             ├── credo (if {:credo exists})
             ├── dialyzer (if {:dialyxir exists})
             ├── sobelow (if {:sobelow exists})
             ├── ex_doc (if {:ex_doc exists})
             ├── mix_audit (if {:mix_audit exists})
             ├── ex_unit tests
             ├── doctor (if {:doctor exists})
             └── ash codegen (if {:ash exists})
```

**Priority**: 🎯 **Do this first** - Single biggest efficiency gain.

---

### Issue 3: Single-Purpose Plugin Proliferation (Severity: MEDIUM) [D:3/B:6 → Priority:2.0] 🎯

**Problem**: 9 plugins exist solely to run one Mix command:

| Plugin | The One Command | Lines of Code |
|--------|-----------------|---------------|
| dialyzer | `mix dialyzer` | ~30 |
| doctor | `mix doctor` | ~30 |
| ex_doc | `mix docs` | ~30 |
| mix_audit | `mix deps.audit` | ~30 |
| ex_unit | `mix test` | ~30 |
| precommit | `mix precommit` | ~30 |
| struct-reminder | pattern grep | ~30 |
| credo | `mix credo` | ~50 |
| sobelow | `mix sobelow` | ~50 |

**Impact on Claude Code**:
- More plugins to consider when something fails
- Fragmented mental model (which plugin handles what?)
- No benefit from separation - these aren't user-selectable features

**Recommendation**: Merge all quality tools into **quality-gates** plugin:
- Single plugin, 9 commands
- Each command can be enabled/disabled via config
- One place to understand quality checking

---

### Issue 4: Skill Organization in Core (Severity: LOW) [D:2/B:4 → Priority:2.0] 🎯

**Problem**: 17 skills in `core` plugin with varying specificity:

**Broadly Useful** (high value):
- hex-docs-search
- usage-rules
- phoenix-patterns
- elixir-setup
- integration-testing
- roadmap-planning
- git-worktrees

**Domain-Specific** (narrow audience):
- daisyui - Only if using daisyUI
- nexus-template - Only if using Nexus template
- phoenix-scope - Phoenix 1.8+ specific
- phoenix-js - Phoenix + JS specific
- zen-websocket - ZenWebsocket library specific
- popcorn - Popcorn WASM specific
- api-consumer - Macro API pattern specific

**Recommendation**: Tier the skills:
1. **core** - Essential skills (hex-docs, usage-rules, elixir-setup)
2. **phoenix** - Phoenix-specific skills
3. **specialized** - daisyui, nexus-template, zen-websocket, popcorn (keep separate or make optional)

---

## Ratings Summary

### What Works Well ✅

| Aspect | Rating | Notes |
|--------|--------|-------|
| Shared library infrastructure | 9/10 | `lib.sh`, `precommit-utils.sh` are excellent |
| Skill documentation quality | 8/10 | Skills are thorough with examples |
| Hook JSON output patterns | 8/10 | Consistent, well-documented |
| Dependency detection | 9/10 | `has_mix_dependency()` pattern is smart |
| Workflow system (elixir-meta) | 8/10 | Template-based generation is clever |

### What Needs Work ⚠️

| Aspect | Rating | Issue |
|--------|--------|-------|
| **Post-edit hook count** | 2/10 | **12 hooks per file edit is crippling** - highest priority fix |
| Pre-commit hook count | 3/10 | 10 hooks per commit is excessive |
| Plugin granularity | 4/10 | Too many single-purpose plugins |
| User configurability | 5/10 | Can't easily enable/disable individual checks |
| Skill organization | 6/10 | Mix of essential and niche in one place |

---

## Consolidation Recommendations

### Recommended Plugin Structure (6 plugins instead of 16)

```
plugins/
├── core/                    # Essential Elixir development
│   ├── hooks/
│   │   ├── post-edit.sh     # Format + compile + basic lint
│   │   └── pre-commit.sh    # Unified quality gate (defers to mix precommit if exists)
│   └── skills/
│       ├── hex-docs-search/
│       ├── usage-rules/
│       ├── elixir-setup/
│       ├── integration-testing/
│       └── roadmap-planning/
│
├── quality-gates/           # All quality tools in one place
│   ├── hooks/
│   │   └── pre-commit.sh    # Runs: credo, dialyzer, sobelow, doctor, mix_audit
│   └── config/
│       └── enabled.json     # User toggles which checks are active
│
├── phoenix/                 # Phoenix-specific features
│   └── skills/
│       ├── phoenix-patterns/
│       ├── phoenix-scope/
│       ├── phoenix-js/
│       └── daisyui/         # Move here since it's Phoenix-adjacent
│
├── elixir-meta/             # Keep as-is (workflow generation)
│
├── git/                     # Keep as-is (commit workflow)
│
└── utilities/               # Misc utilities
    ├── claude-md-includes/
    ├── notifications/
    └── serena/
```

### Migration Priority

| Task | Priority | Effort | Impact |
|------|----------|--------|--------|
| **Consolidate post-edit hooks (12→2)** | 🎯 2.5 | D:4 | B:10 - Runs on EVERY edit, highest frequency |
| Unify pre-commit hooks into quality-gates | 🚀 1.8 | D:5 | B:9 - Runs on every commit |
| Merge single-command plugins | 🎯 2.0 | D:3 | B:6 - Cleaner mental model |
| Reorganize core skills | 📋 1.3 | D:5 | B:6 - Better discoverability |
| Add enable/disable config | 📋 1.0 | D:7 | B:7 - User control |

---

## Specific Consolidation Tasks

### Task 1: Consolidate Post-Edit Hooks ✅ COMPLETED

**Result**: 12 hooks → 2 hooks (83% reduction)

**Implemented**:

| New Hook | Runs | Location |
|----------|------|----------|
| **post-edit-check.sh** | format, compile, credo, sobelow, doctor, struct-hint, hidden-failures, mixexs-check | `plugins/core/scripts/` |
| **ash-codegen-check.sh** | ash codegen (only if Ash dep exists) | `plugins/core/scripts/` |

**Key decisions**:
- Doctor replaces typespec/typedoc/private-docs grep checks (authoritative source)
- Fails loud if credo/sobelow/doctor deps missing (required, not optional)
- Roadmap reminder dropped (not a post-edit concern)
- Dialyzer kept at pre-commit only (too slow for post-edit)

**Files changed**:
- Created: `plugins/core/scripts/post-edit-check.sh`, `plugins/core/scripts/ash-codegen-check.sh`
- Updated: `plugins/core/hooks/hooks.json` (8 hooks → 2)
- Updated: `plugins/{credo,sobelow,ash}/hooks/hooks.json` (removed PostToolUse)
- Updated: `plugins/struct-reminder/hooks/hooks.json` (emptied - moved to core)
- Archived: 8 old scripts to `plugins/core/scripts/_deprecated/`

---

### Task 2: Create quality-gates Plugin [D:5/B:9 → Priority:1.8] 🚀

Merge: credo, dialyzer, sobelow, ex_doc, mix_audit, ex_unit, precommit, doctor

**Single pre-commit-check.sh that**:
1. Checks for `mix precommit` alias first (defer if exists)
2. Runs each tool based on `has_mix_dependency()`
3. Aggregates all failures into one report
4. Respects user config for which checks are enabled

**Benefits**:
- 1 hook call instead of 9
- Single source of truth for quality configuration
- Users can disable checks they don't want

---

### Task 3: Create phoenix Plugin [D:3/B:5 → Priority:1.67] 🚀

Extract from core:
- phoenix-patterns
- phoenix-scope
- phoenix-js
- daisyui (Phoenix-adjacent)
- nexus-template (Phoenix admin template)

**Benefits**:
- Non-Phoenix projects don't see irrelevant skills
- Clearer skill discoverability

---

### Task 4: Keep as Separate (No Change Needed)

| Plugin | Reason |
|--------|--------|
| **elixir-meta** | Unique purpose (workflow generation), well-contained |
| **git** | Commit workflow is distinct from quality checking |
| **serena** | MCP integration has its own lifecycle |
| **notifications** | Different hook type (Notification), distinct purpose |
| **claude-md-includes** | SessionStart hook, distinct purpose |

---

## Configuration System Recommendation

Add a `quality-gates.config.json` file:

```json
{
  "pre_commit": {
    "format_check": true,
    "compile_check": true,
    "credo": true,
    "dialyzer": false,  // Slow, user can enable
    "sobelow": true,
    "doctor": false,    // Optional
    "mix_audit": true,
    "ex_unit": true,
    "ash_codegen": true
  },
  "post_edit": {
    "auto_format": true,
    "compile_feedback": true,
    "credo_suggestions": true,
    "typespec_hints": true,
    "struct_suggestions": false
  }
}
```

**Benefits**:
- Users control what runs
- Hooks read config and skip disabled checks
- Single file to understand quality configuration

---

## Implementation Roadmap

### Phase 1: Post-Edit Consolidation (Immediate - Highest Impact)
- [ ] Consolidate core's 8 post-edit hooks into 2 (format-compile, quality-hints)
- [ ] Merge struct-reminder/post-edit into quality-hints
- [ ] Merge credo/post-edit, sobelow/post-edit, ash/post-edit into framework-check
- [ ] Add early-exit for non-Elixir files in consolidated hooks

### Phase 2: Pre-Commit Unification (Soon)
- [ ] Create `quality-gates` plugin with unified pre-commit hook
- [ ] Deprecate individual tool plugins (credo, dialyzer, etc.)
- [ ] Add configuration system for enabling/disabling checks

### Phase 3: Organization (Later)
- [ ] Create `phoenix` plugin with Phoenix-specific skills
- [ ] Document skill tiers in core README
- [ ] Update CLAUDE.md with new structure

---

## Conclusion

This marketplace has solid foundations - the shared library design is excellent, skills are well-documented, and the workflow system is clever. The primary issue is **fragmentation without benefit**.

**Key insight**: From Claude Code's perspective, I don't care which plugin runs `mix credo`. I care about getting a unified quality report efficiently. The current architecture optimizes for developer organization at the expense of runtime efficiency.

**Recommended action**: Consolidate aggressively. 6 plugins can do everything 16 plugins do today, with fewer tool calls and a clearer mental model.

---

## Appendix: Hook Call Count Analysis

### Current State (per file edit) - HIGHEST FREQUENCY

| Hook Type | Count | Plugins Involved |
|-----------|-------|-----------------|
| PostToolUse (Edit/Write) | 12 | core (8), credo, sobelow, ash, struct-reminder |

**In a typical session editing 30 files**: 360 hook invocations

### After Consolidation (per file edit)

| Hook Type | Count | Plugins Involved |
|-----------|-------|-----------------|
| PostToolUse (Edit/Write) | 2-3 | core (format-compile, quality-hints, framework-check) |

**In a typical session editing 30 files**: 60-90 hook invocations

**75-83% reduction in hook calls per edit. This is the biggest win.**

---

### Current State (per git commit)

| Hook Type | Count | Plugins Involved |
|-----------|-------|-----------------|
| PreToolUse (Bash) | 10 | core, credo, dialyzer, sobelow, ex_doc, mix_audit, ex_unit, precommit, doctor, ash |

### After Consolidation (per git commit)

| Hook Type | Count | Plugins Involved |
|-----------|-------|-----------------|
| PreToolUse (Bash) | 1 | quality-gates |

**90% reduction in hook calls per commit.**
