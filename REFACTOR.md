# Marketplace Personalization Refactor

This document outlines tasks to personalize the Claude Code plugin marketplace fork to match personal development preferences from `~/.claude/CLAUDE.md`.

## Summary of Changes

| Area | Current State | Target State |
|------|---------------|--------------|
| Ownership | Bradley Golden | DeltaHedge |
| Namespace | `elixir` | `deltahedge` |
| Global CLAUDE.md | Monolithic 1000+ lines | Modular with @include |
| Web command | Undocumented | Skill + no WebFetch refs |
| D/B scoring docs | Undocumented | In global CLAUDE.md |
| Doctor plugin | Missing | Pre-commit hook for `mix doctor` |
| Pre-commit strictness | Basic | Strict (Doctor, Credo strict, test patterns) |
| Phoenix 1.8 skill | Missing | On-demand patterns reference |
| Tidewave skill | Missing | MCP tools usage guide |
| Workflow D/B scoring | Missing | Built into `/plan`, `/qa` |
| Test philosophy | Basic | "Never hide failures" emphasis |

---

## Official Documentation References

| Topic | URL |
|-------|-----|
| Plugins Guide | https://docs.anthropic.com/en/docs/claude-code/plugins |
| Plugins Reference | https://docs.anthropic.com/en/docs/claude-code/plugins-reference |
| Plugin Marketplaces | https://docs.anthropic.com/en/docs/claude-code/plugin-marketplaces |
| Agent Skills | https://docs.anthropic.com/en/docs/claude-code/skills |
| Skills Best Practices | https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices |
| Hooks Guide | https://docs.anthropic.com/en/docs/claude-code/hooks-guide |
| Hooks Reference | https://docs.anthropic.com/en/docs/claude-code/hooks |
| Slash Commands | https://docs.anthropic.com/en/docs/claude-code/slash-commands |
| Subagents | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| MCP Integration | https://docs.anthropic.com/en/docs/claude-code/mcp |
| Official Skills Repo | https://github.com/anthropics/skills |
| Web Command | https://github.com/chrismccord/web.git |

---

## Phase 0: Foundation

### Task 0a: Add D/B Scoring to Global CLAUDE.md
- [ ] **Pending** [D:1/B:7 → Priority:7.0] 🎯

**Goal:** Document that all task lists should use D/B scoring format in global CLAUDE.md.

**Files to modify:**
- `~/.claude/CLAUDE.md` - Add note in Task Prioritization Framework section

**Content to add:**
```markdown
**Usage Requirement:**
All task lists, roadmaps, and planning documents created by Claude should use this D/B scoring format consistently.
```

**Acceptance criteria:**
- [ ] D/B scoring requirement documented in global CLAUDE.md
- [ ] REFACTOR.md serves as example of proper usage

---

### Task 0b: Create Web Command Skill
- [ ] **Pending** [D:2/B:9 → Priority:4.5] 🎯

**Goal:** Create an on-demand skill for the `web` command usage patterns.

**Source:** https://github.com/chrismccord/web.git (by Chris McCord)

**Skill location:** `plugins/core/skills/web-command/`

**Content sections:**
1. Installation (`git clone https://github.com/chrismccord/web.git && cd web && ./install.sh`)
2. What is `web` command (shell-based browser for Claude Code)
3. Basic usage (markdown conversion, truncation)
4. Phoenix LiveView form submission (auto-waits for `.phx-connected`)
5. Session persistence with profiles
6. Screenshot capture
7. JavaScript execution
8. Options reference table
9. When to use `web` vs WebFetch (never WebFetch)

**SKILL.md frontmatter:**
```yaml
---
name: web-command
description: Use the `web` command for web browsing in Claude Code. Handles JavaScript, LiveView, forms, screenshots. Use when fetching web pages, submitting forms, or taking screenshots. NEVER use WebFetch.
allowed-tools: Bash, Read
---
```

**Files to create:**
- `plugins/core/skills/web-command/SKILL.md`

**Note:** Skills don't need separate JSON files - SKILL.md with frontmatter is sufficient per official docs.

**Acceptance criteria:**
- [ ] All `web` command patterns documented
- [ ] Examples for Phoenix LiveView workflows
- [ ] SKILL.md has proper frontmatter with `allowed-tools`

---

### Task 0c: Replace WebFetch References with Web Command
- [ ] **Pending** [D:1/B:8 → Priority:8.0] 🎯

**Goal:** Audit and replace all "WebFetch" or "fetch" web browsing references with `web` command.

**Search patterns:**
- `WebFetch` - tool references
- `web.*fetch` - any fetch-related web patterns
- Review skills that mention web browsing

**Files to audit:**
- All skill SKILL.md files
- All command .md files
- README.md files

**Acceptance criteria:**
- [ ] No WebFetch references remain (except "never use WebFetch" warnings)
- [ ] All web browsing examples use `web` command
- [ ] Consistent messaging: "`web` is the default, WebFetch is forbidden"

---

## Phase 1: Ownership & Identity

### Task 1: Update Marketplace Ownership
- [ ] **Pending** [D:1/B:8 → Priority:8.0] 🎯

**Goal:** Update all ownership references to your fork.

**Files to modify:**
- `.claude-plugin/marketplace.json` - Change owner name to "DeltaHedge", update repository URLs
- `LICENSE` - Update copyright to "DeltaHedge" (keep Bradley Golden as original)
- `README.md` - Add attribution section for Bradley Golden, update ownership
- All `plugins/*/plugin.json` - Update repository/homepage URLs to your fork

**Attribution approach:**
- LICENSE: "Copyright (c) 2025 DeltaHedge (forked from Bradley Golden)"
- README: Add "Originally created by Bradley Golden" in credits/attribution section

**Acceptance criteria:**
- [ ] marketplace.json owner updated to "DeltaHedge"
- [ ] All repository URLs point to `https://github.com/ZenHive/claude-marketplace-elixir`
- [ ] LICENSE copyright updated with attribution
- [ ] README has attribution to original author
- [ ] All plugin.json files updated with ZenHive URLs

---

### Task 2: Update Namespace to DeltaHedge
- [ ] **Pending** [D:1/B:6 → Priority:6.0] 🎯

**Goal:** Change namespace from `elixir` to `deltahedge`.

**Decision:** Namespace will be `deltahedge`
- Plugins become: `core@deltahedge`, `credo@deltahedge`, etc.

**Files to modify:**
- `.claude-plugin/marketplace.json` - Change `name` from `elixir` to `deltahedge`
- `CLAUDE.md` - Update all `@elixir` references to `@deltahedge`
- `README.md` - Update plugin installation examples
- `.claude/WORKFLOWS.md` - Update any namespace references

**Acceptance criteria:**
- [ ] Namespace changed to `deltahedge`
- [ ] All documentation updated
- [ ] Plugin install commands work: `/plugin install core@deltahedge`

---

## Phase 2: New Plugins

### Task 3: Integrate claude-md-includes Plugin
- [ ] **Pending** [D:1/B:9 → Priority:9.0] 🎯

**Goal:** Port the production-ready claude-md-includes plugin from PR #13621 to this marketplace.

**Source:** https://github.com/anthropics/claude-code/pull/13621

**What it does:**
- SessionStart hook processes `@include <path>` directives in CLAUDE.md
- Enables composable instruction files from reusable components
- Recursive includes with circular detection and max depth (10)
- Path resolution: `~/` (home), `./` (relative), absolute paths
- Graceful failures (missing files warn but don't fail)

**Already implemented (commit e55f001):**
- Path traversal security validation (blocks /etc/, /var/, etc.)
- Code block detection (skips `@include` in ``` blocks)
- Paths with spaces support (greedy regex)
- Proper error handling in shell wrapper (`set -euo pipefail`)
- Type hints and clear variable naming

**Structure to copy:**
```
plugins/claude-md-includes/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   └── hooks.json
├── hooks-handlers/
│   └── session-start.sh
├── scripts/
│   └── process-includes.py
└── README.md
```

**Files to modify:**
- `.claude-plugin/marketplace.json` - Add plugin entry

**Acceptance criteria:**
- [ ] Plugin copied from PR (all files)
- [ ] Test suite created: `test/plugins/claude-md-includes/test-includes-hooks.sh`
- [ ] Added to marketplace.json
- [ ] Repository URLs updated to ZenHive

---

### Task 3b: Split Global CLAUDE.md with @include
- [ ] **Pending** [D:2/B:8 → Priority:4.0] 🎯

**Goal:** Modularize the 1000+ line global CLAUDE.md into composable includes.

**Depends on:** Task 3 (claude-md-includes plugin)

**Proposed structure:**
```
~/.claude/
├── CLAUDE.md                              # Main file with @include directives
└── includes/
    ├── critical-rules.md                  # Phoenix server, tests, test failures, minimalism
    ├── task-prioritization.md             # D/B scoring framework
    ├── web-command.md                     # `web` command documentation
    ├── phoenix-patterns.md                # Phoenix 1.8 patterns
    ├── elixir-patterns.md                 # Runtime errors, performance patterns
    ├── testing-philosophy.md              # TDD, never hide failures, Tidewave exploration
    ├── code-style.md                      # Style guidelines, KPIs
    ├── library-design.md                  # Library vs application patterns
    └── slash-commands.md                  # Global slash command reference
```

**Files to create:**
- `~/.claude/includes/*.md` - Individual include files
- Update `~/.claude/CLAUDE.md` - Replace content with @include directives

**Benefits:**
- Easier maintenance of individual sections
- Can share specific includes across projects
- Reduces cognitive load when editing
- Each section can be versioned independently

**Acceptance criteria:**
- [ ] All sections extracted to include files
- [ ] Main CLAUDE.md uses @include for all content
- [ ] Circular dependency check passes
- [ ] Claude Code loads successfully with includes

---

### Task 4: Create Doctor Plugin
- [ ] **Pending** [D:2/B:9 → Priority:4.5] 🎯

**Goal:** Add `mix doctor` pre-commit validation to enforce documentation quality.

**Structure:**
```
plugins/doctor/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   └── hooks.json
├── scripts/
│   └── pre-commit-check.sh
└── README.md
```

**Hook behavior:**
- Trigger: `PreToolUse` → `Bash` (git commit)
- Check: `mix doctor` must pass
- Block: Commit blocked if documentation issues found
- Output: JSON with `permissionDecision: "deny"` on failure

**Files to create:**
- `plugins/doctor/.claude-plugin/plugin.json`
- `plugins/doctor/hooks/hooks.json`
- `plugins/doctor/scripts/pre-commit-check.sh`
- `plugins/doctor/README.md`
- `test/plugins/doctor/test-doctor-hooks.sh`
- `test/plugins/doctor/precommit-test/` (test fixtures)

**Files to modify:**
- `.claude-plugin/marketplace.json` - Add doctor plugin entry

**Acceptance criteria:**
- [ ] Plugin structure follows existing patterns
- [ ] Pre-commit blocks on `mix doctor` failures
- [ ] Test suite passes: `./test/plugins/doctor/test-doctor-hooks.sh`
- [ ] Added to marketplace.json

---

### Task 5: Create Phoenix 1.8 Patterns Skill
- [ ] **Pending** [D:3/B:9 → Priority:3.0] 🎯

**Goal:** On-demand skill providing Phoenix 1.8 patterns from your CLAUDE.md.

**Skill location:** `plugins/core/skills/phoenix-patterns/`

**Content sections:**
1. Project setup (`--binary-id --live` flags)
2. Template wrapper requirement (`<Layouts.app>`)
3. Form handling (`to_form/2` pattern)
4. LiveView streams
5. Authentication routing patterns
6. HEEx template syntax
7. Verified routes (`~p` sigil)
8. Tailwind v4 patterns
9. Common pitfalls (runtime errors)

**Files to create:**
- `plugins/core/skills/phoenix-patterns/SKILL.md`

**SKILL.md frontmatter:**
```yaml
---
name: phoenix-patterns
description: Phoenix 1.8 framework patterns reference. Use when working with Phoenix templates, forms, LiveView streams, auth routing, HEEx syntax, or Tailwind v4. Covers to_form/2, Layouts.app wrapper, verified routes, and common pitfalls.
allowed-tools: Read
---
```

**Note:** Skills are auto-discovered from `skills/` directory - no registration in plugin.json needed.

**Acceptance criteria:**
- [ ] Skill provides all Phoenix 1.8 patterns from CLAUDE.md
- [ ] Organized by category for easy lookup
- [ ] Includes good/bad examples
- [ ] SKILL.md has proper frontmatter

---

### Task 6: Create Tidewave Usage Skill
- [ ] **Pending** [D:2/B:8 → Priority:4.0] 🎯

**Goal:** Skill explaining Tidewave MCP tools and "explore before coding" workflow.

**Skill location:** `plugins/core/skills/tidewave-guide/`

**Content sections:**
1. What is Tidewave
2. Setup instructions (Phoenix vs non-Phoenix)
3. Available MCP tools
   - `mcp__tidewave__get_docs`
   - `mcp__tidewave__get_source_location`
   - `mcp__tidewave__project_eval`
   - `mcp__tidewave__execute_sql_query`
   - `mcp__tidewave__get_ecto_schemas`
   - `mcp__tidewave__search_package_docs`
4. "Explore BEFORE coding" workflow
5. Debugging with real data patterns

**Files to create:**
- `plugins/core/skills/tidewave-guide/SKILL.md`

**SKILL.md frontmatter:**
```yaml
---
name: tidewave-guide
description: Tidewave MCP tools usage guide for Elixir development. Use when setting up Tidewave, exploring APIs with project_eval, querying databases, or following "explore before coding" workflow. Covers all mcp__tidewave__* tools.
allowed-tools: Read
---
```

**Note:** Skills are auto-discovered from `skills/` directory - no registration in plugin.json needed.

**Acceptance criteria:**
- [ ] All Tidewave tools documented
- [ ] Setup instructions for both Phoenix and non-Phoenix
- [ ] Explore-first workflow explained
- [ ] SKILL.md has proper frontmatter

---

## Phase 3: Enhanced Pre-commit Strictness

### Task 7: Update Precommit Plugin for Strict Mode
- [ ] **Pending** [D:3/B:8 → Priority:2.67] 🎯

**Goal:** Make pre-commit validation strict by default, matching CLAUDE.md quality gates.

**Current precommit plugin:** Runs `mix precommit` alias if exists

**Enhanced behavior:**
1. Check `mix format --check-formatted`
2. Check `mix compile --warnings-as-errors`
3. Check `mix credo --strict`
4. Check `mix doctor` (new)
5. Check `mix test` (if ex_unit plugin enabled)
6. Block commit if ANY fail

**Files to modify:**
- `plugins/precommit/scripts/pre-commit-check.sh` - Add strict checks
- `plugins/precommit/README.md` - Document strict behavior

**Files to create:**
- `test/plugins/precommit/strict-test/` - Test fixtures for strict mode

**Acceptance criteria:**
- [ ] All quality gates checked before commit
- [ ] Clear error messages indicating which check failed
- [ ] Can be bypassed with `--no-verify` (standard git behavior)
- [ ] Tests pass for all check combinations

---

### Task 8: Add Test Failure Pattern Detection
- [ ] **Pending** [D:4/B:10 → Priority:2.5] 🎯

**Goal:** Detect and warn about tests that hide failures (your "never hide test failures" rule).

**Detection patterns (from CLAUDE.md):**
```elixir
# BAD patterns to detect:
{:error, _} -> assert true           # Makes all failures pass
{:error, _reason} -> :ok             # Silent pass on any error
{:error, reason} -> IO.puts(...); assert true  # Comments don't help
```

**Implementation options:**
1. **PostToolUse hook on Edit** - Scan edited test files for bad patterns
2. **Pre-commit hook** - Scan all changed test files
3. **Separate skill** - On-demand analysis

**Recommended:** PostToolUse hook in core plugin (immediate feedback)

**Files to create:**
- `plugins/core/scripts/detect-hidden-failures.sh`

**Files to modify:**
- `plugins/core/hooks/hooks.json` - Add PostToolUse hook for test file detection
- `plugins/core/README.md` - Document test failure detection patterns

**Acceptance criteria:**
- [ ] Detects `{:error, _} -> assert true` pattern
- [ ] Detects `{:error, _} -> :ok` pattern
- [ ] Warns via `additionalContext` (non-blocking)
- [ ] Provides correct alternative patterns
- [ ] Only scans `_test.exs` files

---

## Phase 4: Workflow Command Updates

### Task 9: Add D/B Scoring to Plan Command
- [ ] **Pending** [D:2/B:8 → Priority:4.0] 🎯

**Goal:** Update `/plan` command to generate tasks with D/B scoring (matching your roadmap.md style).

**Current format:**
```markdown
## Tasks
- [ ] Task description
```

**Target format:**
```markdown
## Tasks
- [ ] Task description [D:3/B:8 → Priority:2.67] 🎯
```

**Priority indicators:**
- Priority > 2.0: 🎯 Exceptional ROI
- Priority 1.5-2.0: 🚀 High ROI
- Priority 1.0-1.5: 📋 Good ROI
- Priority < 1.0: ⚠️ Poor ROI

**Files to modify:**
- `.claude/commands/plan.md` - Add scoring instructions to prompt

**Acceptance criteria:**
- [ ] Generated plans include D/B scoring
- [ ] Priority calculated correctly (B/D)
- [ ] Appropriate emoji indicators
- [ ] Format matches roadmap.md style

---

### Task 10: Add D/B Scoring to QA Command
- [ ] **Pending** [D:2/B:7 → Priority:3.5] 🎯

**Goal:** Update `/qa` command to report issues with prioritized scoring.

**Files to modify:**
- `.claude/commands/qa.md` - Add scoring to issue reports

**Acceptance criteria:**
- [ ] Issues reported with D/B scores for fixing them
- [ ] Sorted by priority (highest ROI first)
- [ ] Matches scoring format from CLAUDE.md

---

### Task 11: Update Research Command for Tidewave Integration
- [ ] **Pending** [D:2/B:7 → Priority:3.5] 🎯

**Goal:** Integrate Tidewave MCP tools into `/research` workflow.

**Enhancement:**
- Suggest `mcp__tidewave__project_eval` for exploring APIs
- Suggest `mcp__tidewave__get_docs` for package documentation
- Add "explore before coding" reminder

**Files to modify:**
- `.claude/commands/research.md` - Add Tidewave tool suggestions

**Acceptance criteria:**
- [ ] Research prompts mention Tidewave when relevant
- [ ] Suggests `project_eval` for API exploration
- [ ] Aligns with "explore before coding" philosophy

---

## Phase 5: Documentation & Polish

### Task 12: Update Project CLAUDE.md
- [ ] **Pending** [D:2/B:7 → Priority:3.5] 🎯

**Goal:** Update the project's CLAUDE.md with new plugins, skills, and your preferences.

**Updates needed:**
1. Add claude-md-includes plugin documentation
2. Add Doctor plugin documentation
3. Add Phoenix 1.8 patterns skill documentation
4. Add Tidewave guide skill documentation
5. Add strict pre-commit behavior documentation
6. Add test failure detection documentation
7. Update ownership references
8. Add D/B scoring explanation

**Files to modify:**
- `CLAUDE.md` - Comprehensive update

**Acceptance criteria:**
- [ ] All new plugins documented
- [ ] All new skills documented
- [ ] Pre-commit strictness documented
- [ ] D/B scoring format explained

---

### Task 13: Update README.md
- [ ] **Pending** [D:2/B:6 → Priority:3.0] 🎯

**Goal:** Update README with new features and fork attribution.

**Updates needed:**
1. Attribution to original project (MIT license)
2. New plugin list (claude-md-includes, Doctor)
3. New skills list (Phoenix 1.8, Tidewave)
4. Strict pre-commit documentation
5. D/B scoring in workflow commands

**Files to modify:**
- `README.md` - Comprehensive update

**Acceptance criteria:**
- [ ] Attribution clear and correct
- [ ] All new features documented
- [ ] Installation instructions current
- [ ] Examples updated

---

### Task 14: Run Full Test Suite & Fix Issues
- [ ] **Pending** [D:2/B:9 → Priority:4.5] 🎯

**Goal:** Verify all changes work together and fix any issues.

**Commands:**
```bash
./test/run-all-tests.sh
/qa
```

**Files potentially modified:**
- Any files with failing tests

**Acceptance criteria:**
- [ ] All plugin tests pass
- [ ] JSON validation passes
- [ ] No broken references
- [ ] `/qa` reports clean

---

## Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| 0. Foundation | 0a-0c | D/B scoring docs, web command skill, WebFetch cleanup |
| 1. Ownership | 1-2 | Identity updates |
| 2. New Plugins | 3-6, 3b | claude-md-includes, @include split, Doctor, Phoenix skill, Tidewave skill |
| 3. Pre-commit | 7-8 | Strict mode, test pattern detection |
| 4. Workflows | 9-11 | D/B scoring, Tidewave integration |
| 5. Documentation | 12-14 | CLAUDE.md, README, testing |

**Total: 18 tasks**

---

## Git Strategy

**Branch approach:** Feature branch per phase
- `refactor/phase-0-foundation`
- `refactor/phase-1-ownership`
- `refactor/phase-2-plugins`
- etc.

**Workflow:**
1. Create branch from `main`
2. Complete all tasks in phase
3. Run `/qa` and test suite
4. PR to `main` with phase summary
5. Squash merge to keep history clean

**Rollback strategy:**
- Each phase is a separate PR → easy to revert entire phase
- Within a phase, commit after each task for granular rollback
- Tag `main` before starting: `git tag pre-refactor`

---

## Dependency Graph

```
Phase 0 (Foundation)
  └── Task 0a: D/B scoring docs
  └── Task 0b: Web command skill
  └── Task 0c: Replace WebFetch refs

Phase 1 (Ownership) - independent of Phase 0
  └── Task 1: Marketplace ownership
  └── Task 2: Namespace update

Phase 2 (Plugins)
  ├── Task 3: claude-md-includes ─────┐
  │                                   │
  └── Task 3b: Split CLAUDE.md ◄──────┘ (depends on Task 3)
  └── Task 4: Doctor plugin
  └── Task 5: Phoenix patterns skill
  └── Task 6: Tidewave guide skill

Phase 3 (Pre-commit)
  └── Task 7: Strict precommit
  └── Task 8: Test failure detection

Phase 4 (Workflows)
  └── Task 9: D/B in /plan
  └── Task 10: D/B in /qa
  └── Task 11: Tidewave in /research

Phase 5 (Documentation)
  └── Task 12: Update CLAUDE.md
  └── Task 13: Update README
  └── Task 14: Test suite validation
```

**Critical path:** Task 3 → Task 3b (all others can run in parallel within phases)

---

## Priority Order (by ROI)

**Tiebreaker logic:** When priorities are equal, prefer:
1. Tasks that enable other tasks (dependencies)
2. Tasks with lower difficulty (faster wins)
3. Tasks earlier in phase order

1. Task 3: Integrate claude-md-includes Plugin [D:1/B:9 → 9.0] 🎯 **HIGHEST - Enables modular CLAUDE.md**
2. Task 0c: Replace WebFetch References with Web [D:1/B:8 → 8.0] 🎯
3. Task 1: Update Marketplace Ownership [D:1/B:8 → 8.0] 🎯
4. Task 0a: Add D/B Scoring to Global CLAUDE.md [D:1/B:7 → 7.0] 🎯
5. Task 2: Update Namespace to DeltaHedge [D:1/B:6 → 6.0] 🎯
6. Task 0b: Create Web Command Skill [D:2/B:9 → 4.5] 🎯
7. Task 4: Create Doctor Plugin [D:2/B:9 → 4.5] 🎯
8. Task 14: Run Full Test Suite [D:2/B:9 → 4.5] 🎯
9. Task 3b: Split Global CLAUDE.md with @include [D:2/B:8 → 4.0] 🎯 **Depends on Task 3**
10. Task 6: Create Tidewave Usage Skill [D:2/B:8 → 4.0] 🎯
11. Task 9: Add D/B Scoring to Plan Command [D:2/B:8 → 4.0] 🎯
12. Task 10: Add D/B Scoring to QA Command [D:2/B:7 → 3.5] 🎯
13. Task 11: Update Research Command [D:2/B:7 → 3.5] 🎯
14. Task 12: Update Project CLAUDE.md [D:2/B:7 → 3.5] 🎯
15. Task 5: Create Phoenix 1.8 Patterns Skill [D:3/B:9 → 3.0] 🎯
16. Task 13: Update README.md [D:2/B:6 → 3.0] 🎯
17. Task 7: Update Precommit Plugin [D:3/B:8 → 2.67] 🎯
18. Task 8: Add Test Failure Pattern Detection [D:4/B:10 → 2.5] 🎯 **Prevents production bugs**

---

## Decisions Made

| Question | Decision |
|----------|----------|
| Namespace | `deltahedge` |
| Owner name | DeltaHedge |
| Attribution | Keep Bradley Golden as original author in LICENSE and README |
| Ash plugin | Keep |

## Repository URL

**Fork URL:** `https://github.com/ZenHive/claude-marketplace-elixir`

All plugin.json, marketplace.json, and README links will use this URL.
