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
- `plugins/core/skills/hex-docs-search/SKILL.md` (existing)
- `plugins/core/skills/usage-rules/SKILL.md` (existing)
- `plugins/meta/skills/workflow-generator/SKILL.md` (existing)

**Acceptance criteria:**
- [ ] No WebFetch references remain (except "never use WebFetch" warnings)
- [ ] All web browsing examples use `web` command
- [ ] Consistent messaging: "`web` is the default, WebFetch is forbidden"

---

### Task 0d: Create Git Worktrees Skill
- [ ] **Pending** [D:2/B:9 → Priority:4.5] 🎯

**Goal:** Create an on-demand skill for running parallel Claude Code sessions with git worktrees.

**Sources:**
- https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees
- https://www.anthropic.com/engineering/claude-code-best-practices
- https://code.claude.com/docs/en/common-workflows

**Skill location:** `plugins/core/skills/git-worktrees/`

**Content sections:**
1. What are git worktrees (isolated directories, same repo)
2. Why use with Claude Code (parallel sessions, no conflicts)
3. Basic commands (`git worktree add/list/remove`)
4. Workflow patterns (feature branches, parallel phases, task isolation)
5. Cleanup after merge (`git worktree remove`)
6. When to use vs single session
7. Example: parallel refactor phases

**SKILL.md frontmatter:**
```yaml
---
name: git-worktrees
description: Run multiple Claude Code sessions in parallel using git worktrees. Use when working on multiple features/tasks simultaneously, running parallel refactors, or isolating experimental work. Prevents Claude sessions from conflicting.
allowed-tools: Bash, Read
---
```

**Files to create:**
- `plugins/core/skills/git-worktrees/SKILL.md`

**Acceptance criteria:**
- [ ] All git worktree commands documented
- [ ] Claude Code parallel workflow patterns explained
- [ ] Cleanup instructions included
- [ ] SKILL.md has proper frontmatter with `allowed-tools`

---

### Task 0e: Install Marketplace Locally for Testing
- [x] **Complete** [D:1/B:10 → Priority:10.0] ✅

**Goal:** Add this marketplace to the current Claude Code session so we can test plugins as we develop them.

**Command to run:**
```bash
# From Claude Code
/plugin marketplace add /Users/efries/_DATA/code/claude-marketplace-elixir
```

**Why first:**
- Enables testing skills/hooks immediately after creation
- Catches issues early in development
- Validates plugin structure before committing

**Acceptance criteria:**
- [x] Marketplace added successfully
- [ ] Can install plugins: `/plugin install core@deltahedge` (after namespace change)
- [ ] Skills are discoverable and invocable
- [ ] Hooks trigger on file edits

**Note:** Run this task BEFORE starting other tasks to enable continuous testing.

---

### Task 0f: Create API Consumer Macro Skill
- [ ] **Pending** [D:3/B:9 → Priority:3.0] 🎯

**Goal:** Create an on-demand skill for macro-based API client generation with tooling.

**Sources:**
- `crypto_bridge` - Declarative macro pattern (primary)
- `zen_cex` - OpenAPI generation pattern (optional enhancement)

**Pattern Decision: Declarative Macro (Primary)**

| Aspect | Declarative Macro | OpenAPI Generation |
|--------|-------------------|-------------------|
| Control | Full - you define methods | Partial - spec defines methods |
| Dependencies | None | YAML parser, network fetch |
| API requirement | Any API | Must have OpenAPI spec |
| Maintenance | Manual but predictable | Auto but brittle |
| Stability | Your code, your control | Breaks when spec changes |
| Complexity | 1 file | 4+ files |

**Recommendation:** Declarative macro as primary (works for any API), OpenAPI as optional discovery tool.

**Skill location:** `plugins/core/skills/api-consumer/`

**Content sections:**

**Part 0: Layered Abstraction Pattern**
0. When NOT to build your own API client
   - If a battle-tested library exists (CCXT, Stripe SDK, etc.), wrap it declaratively
   - Let specialized libraries handle the chaos (auth schemes, rate limits, error codes)
   - Your code stays clean and declarative
   - Example: crypto_bridge architecture
     ```
     Your App (Elixir)
         ↓ calls
     @ccxt_methods (declarative Elixir macros)
         ↓ generates calls to
     Node.js Bridge (TS macros)
         ↓ calls
     CCXT Library (handles 100+ exchange quirks)
         ↓ calls
     Exchange APIs
     ```
   - Key insight: Macros work at every layer (TS bridge has macros too)
   - Only build raw API client when no library exists

**Part 1: Declarative Macro Pattern (Primary)**
1. When to use macros for API clients (10+ similar endpoints, no existing library)
2. Declarative method definition format
   ```elixir
   @api_methods [
     {:fetch_ticker, :get, "/ticker/:symbol", [:symbol], [], :ticker},
     {:create_order, :post, "/orders", [], [:symbol, :type, :side, :amount], :order},
   ]
   ```
3. Generated function features (typespecs, docs, path interpolation)
4. HTTP client patterns with Req
5. Explicit credentials (no env fallback in library code)
6. Source: `crypto_bridge/lib/crypto_bridge/bridge/ccxt.ex`

**Part 2: Sync Checking & Fixtures**
6. Mix task for API sync checking
   - Compare defined methods vs actual API
   - Identify missing/extra/deprecated methods
   - Cross-language script coordination (Node.js for JS APIs)
   - Source: `crypto_bridge/lib/mix/tasks/ccxt.check_methods.ex`
7. Fixture generation from real API responses
   - Fetch real data for correct structure
   - Fixed timestamps for reproducibility
   - Auto-generate Elixir test module
   - Source: `crypto_bridge/bridge/scripts/generate-fixtures.cjs`

**Part 3: OpenAPI Enhancement (Optional)**
8. When to use OpenAPI generation
   - Exchange publishes reliable OpenAPI spec
   - 100+ endpoints with good schema definitions
   - Want auto-generated typespecs
9. OpenAPI → Elixir generation mix task
   - Source: `zen_cex/lib/mix/tasks/zen_cex.generate_endpoints.ex`
10. Compile-time endpoint loading macro
    - Source: `zen_cex/lib/zen_cex/adapters/base_endpoint_loader.ex`
11. TypeGenerator for OpenAPI → Elixir typespecs
    - Source: `zen_cex/lib/mix/tasks/helpers/type_generator.ex`
12. Parser macros for safe response handling
    - `safe_decimal_field`, `extract_field`, `normalize_keys`
    - Source: `zen_cex/lib/zen_cex/parser_macros.ex`

**Part 4: Extensions**
13. WebSocket extension pattern (same macro approach)
14. Hybrid approach: OpenAPI as discovery, macro as source of truth

**SKILL.md frontmatter:**
```yaml
---
name: api-consumer
description: Macro-based API client generation for Elixir. Use when building clients for REST APIs with 10+ similar endpoints. Primary pattern: declarative method definitions with auto-generated functions. Optional: OpenAPI spec generation for discovery. Covers mix tasks for API sync checking and test fixture generation.
allowed-tools: Read, Bash
---
```

**Files to create:**
- `plugins/core/skills/api-consumer/SKILL.md`

**Acceptance criteria:**
- [ ] Layered abstraction pattern: wrap existing libraries, don't reimplement
- [ ] Declarative macro pattern documented as primary approach
- [ ] OpenAPI generation documented as optional enhancement
- [ ] Comparison table: when to use which pattern
- [ ] Mix task pattern for API sync checking
- [ ] Fixture generation workflow documented
- [ ] Explicit credentials pattern emphasized
- [ ] crypto_bridge examples for primary pattern (including TS bridge macros)
- [ ] zen_cex examples for OpenAPI pattern
- [ ] SKILL.md has proper frontmatter

---

### Task 0g: Create Roadmap/Planning Skill
- [ ] **Pending** [D:2/B:8 → Priority:4.0] 🎯

**Goal:** Create an on-demand skill for creating prioritized task lists and roadmaps with D/B scoring.

**Skill location:** `plugins/core/skills/roadmap-planning/`

**Content sections:**
1. D/B Scoring Format
   - Format: `[D:X/B:Y → Priority:Z]` where Priority = B/D
   - Difficulty scale (1-10): effort, complexity, risk
   - Benefit scale (1-10): impact, value, urgency
2. Priority Indicators
   - Priority > 2.0: 🎯 Exceptional ROI - do immediately
   - Priority 1.5-2.0: 🚀 High ROI - do soon
   - Priority 1.0-1.5: 📋 Good ROI - plan carefully
   - Priority < 1.0: ⚠️ Poor ROI - reconsider or defer
3. Task Structure Patterns
   - Phases for logical grouping
   - Dependency graphs
   - Acceptance criteria
   - Files to create/modify lists
4. What NOT to Score
   - 🐛 Critical bugs - always highest priority
   - 🔒 Security issues - always highest priority
   - 📝 Documentation of completed work - just do it
   - ✅ Tasks already in progress - finish them first
5. Example Roadmap Template

**SKILL.md frontmatter:**
```yaml
---
name: roadmap-planning
description: Create prioritized task lists and roadmaps with D/B (Difficulty/Benefit) scoring. Use when planning features, refactors, or any multi-task work. Provides ROI-based prioritization, phase organization, and dependency tracking.
allowed-tools: Read, Write
---
```

**Files to create:**
- `plugins/core/skills/roadmap-planning/SKILL.md`

**Acceptance criteria:**
- [ ] D/B scoring format fully documented
- [ ] Priority indicators explained with examples
- [ ] Task structure patterns included
- [ ] Example roadmap template provided
- [ ] SKILL.md has proper frontmatter

---

### Task 0h: Validate Existing Plugin Structure
- [ ] **Pending** [D:1/B:7 → Priority:7.0] 🎯

**Goal:** Before modifying plugins, verify current state matches CLAUDE.md assumptions.

**Validation checks:**
1. Verify all plugins listed in `marketplace.json` exist in `plugins/`
2. Verify all plugin directories have valid `plugin.json`
3. Verify existing skills have proper SKILL.md frontmatter
4. Verify hook scripts exist and are executable
5. Run existing test suite to establish baseline

**Commands:**
```bash
# List all plugins
ls plugins/

# Validate marketplace.json
cat .claude-plugin/marketplace.json | jq '.plugins[]'

# Check each plugin has plugin.json
for dir in plugins/*/; do
  [ -f "$dir/.claude-plugin/plugin.json" ] && echo "✓ $dir" || echo "✗ $dir missing plugin.json"
done

# Run existing tests
./test/run-all-tests.sh
```

**Files to verify:**
- `.claude-plugin/marketplace.json`
- `plugins/*/.claude-plugin/plugin.json`
- `plugins/*/skills/*/SKILL.md`
- `plugins/*/hooks/hooks.json`

**Acceptance criteria:**
- [ ] All plugins listed in marketplace exist
- [ ] All plugin.json files are valid JSON
- [ ] All existing skills have valid frontmatter
- [ ] All hook scripts are executable
- [ ] Existing test suite passes (baseline established)

**Note:** Run this AFTER Task 0e (marketplace install) to validate structure before modifications.

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
- [x] **Complete** [D:1/B:9 → Priority:9.0] ✅

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
- [x] Plugin copied from PR (all files)
- [x] Test suite created: `test/plugins/claude-md-includes/test-includes-hooks.sh`
- [x] Added to marketplace.json
- [x] Repository URLs updated to ZenHive

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

**Relationship to `/phoenix-patterns` command:** The global slash command `/phoenix-patterns` in `~/.claude/commands/` provides a quick reference. This skill provides the same content in a model-invoked format for automatic discovery when working with Phoenix projects.

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
| 0. Foundation | 0a-0h | D/B scoring, web command, WebFetch cleanup, git worktrees, local testing, API consumer macro, roadmap planning, plugin validation |
| 1. Ownership | 1-2 | Identity updates |
| 2. New Plugins | 3-6, 3b | claude-md-includes, @include split, Doctor, Phoenix skill, Tidewave skill |
| 3. Pre-commit | 7-8 | Strict mode, test pattern detection |
| 4. Workflows | 9-11 | D/B scoring, Tidewave integration |
| 5. Documentation | 12-14 | CLAUDE.md, README, testing |

**Total: 23 tasks**

**Future:** After Task 3 (claude-md-includes), consider splitting this file into `.thoughts/refactor/phase-*.md` using `@include` directives.

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

## Parallel Execution with Git Worktrees

**Setup:** Create worktrees for parallel Claude Code sessions.

### Phase 0 + Phase 1 (Independent - run in parallel)
```bash
# Main session stays in original directory for Task 0e (marketplace install)
cd /Users/efries/_DATA/code/claude-marketplace-elixir

# Worktree for Phase 0 tasks (0a-0d, 0f)
git worktree add ../marketplace-phase-0 -b refactor/phase-0-foundation

# Worktree for Phase 1 tasks (1-2)
git worktree add ../marketplace-phase-1 -b refactor/phase-1-ownership
```

### Phase 2 Plugin Tasks (Independent - run in parallel)
```bash
# Task 3: claude-md-includes (MUST complete before 3b)
git worktree add ../marketplace-includes -b refactor/claude-md-includes

# Task 4: Doctor plugin
git worktree add ../marketplace-doctor -b refactor/doctor-plugin

# Task 5: Phoenix patterns skill
git worktree add ../marketplace-phoenix -b refactor/phoenix-skill

# Task 6: Tidewave guide skill
git worktree add ../marketplace-tidewave -b refactor/tidewave-skill
```

### Phase 3-4 (Can run in parallel after Phase 2)
```bash
# Phase 3: Pre-commit strictness
git worktree add ../marketplace-precommit -b refactor/phase-3-precommit

# Phase 4: Workflow updates
git worktree add ../marketplace-workflows -b refactor/phase-4-workflows
```

### Cleanup After Merge
```bash
# List all worktrees
git worktree list

# Remove after PR merged
git worktree remove ../marketplace-phase-0
git branch -d refactor/phase-0-foundation
```

### Parallel Execution Map

```
Session 1 (main dir)     Session 2              Session 3              Session 4
──────────────────────   ────────────────────   ────────────────────   ────────────────
Task 0e: Install mkt     Task 0a: D/B docs      Task 1: Ownership
     ↓                   Task 0b: Web skill     Task 2: Namespace
Task 3: includes         Task 0c: WebFetch
     ↓                   Task 0d: Worktrees
Task 3b: Split CLAUDE    Task 0f: Roadmap
                              ↓                      ↓
                         Task 4: Doctor         Task 5: Phoenix        Task 6: Tidewave
                              ↓                      ↓                      ↓
                         ─────────────── MERGE ALL TO MAIN ───────────────
                              ↓
                         Task 7: Precommit      Task 9: D/B /plan
                         Task 8: Test detect    Task 10: D/B /qa
                                                Task 11: Tidewave res
                              ↓                      ↓
                         ─────────────── MERGE ALL TO MAIN ───────────────
                              ↓
                         Task 12: CLAUDE.md     Task 14: Test suite
                         Task 13: README
```

---

## Dependency Graph

```
Phase 0 (Foundation)
  └── Task 0e: Install marketplace locally ◄── DO FIRST (enables testing)
  └── Task 0h: Validate plugin structure ◄── DO AFTER 0e (establishes baseline)
  └── Task 0a: D/B scoring docs
  └── Task 0b: Web command skill
  └── Task 0c: Replace WebFetch refs
  └── Task 0d: Git worktrees skill
  └── Task 0f: API consumer macro skill
  └── Task 0g: Roadmap planning skill

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

**Critical path:** Task 0e (first) → Task 0h (validation) → then Task 3 → Task 3b (all others can run in parallel within phases)

---

## Execution Order (by ROI)

**Tiebreaker logic:** When priorities are equal, prefer tasks that enable others → lower difficulty → earlier phase.

| Priority | Tasks (by ROI descending) |
|----------|---------------------------|
| 🎯 10.0 | **0e** (enables testing) |
| 🎯 9.0 | **3** (enables 3b) |
| 🎯 8.0 | 0c, 1 |
| 🎯 7.0 | 0a, **0h** (after 0e) |
| 🎯 6.0 | 2 |
| 🎯 4.5 | 0b, 0d, 4, 14 |
| 🎯 4.0 | **3b** (after 3), 0g, 6, 9 |
| 🎯 3.5 | 10, 11, 12 |
| 🎯 3.0 | 0f, 5, 13 |
| 🎯 2.67 | 7 |
| 🎯 2.5 | 8 |

**Critical path:** 0e → 0h → 3 → 3b (all others parallelize within phases)

---

## Non-Goals (Out of Scope)

This refactor intentionally does NOT address:

| Item | Reason |
|------|--------|
| CI/CD automation | Manual testing sufficient for marketplace |
| Plugin versioning automation | Semantic versioning is manual per CLAUDE.md |
| Removing existing plugins (Ash, Dialyzer) | Working and useful, keep them |
| Global CLAUDE.md content changes | Only structure (modularization), not rules |
| New workflow commands | Enhance existing `/plan`, `/qa`, `/research` only |

## Future Scope (Post-Refactor)

Elixir projects often include companion code in other languages:

| Plugin | Examples |
|--------|----------|
| TypeScript/JS | Phoenix frontends, LiveView hooks, Node services, API clients |
| Go | Services, CLI tools, protocol implementations |
| Rust | NIFs (Rustler), performance-critical modules |

Real examples: `crypto_bridge` (Elixir + TypeScript), `whatsapp_mcp` (Elixir + Go)

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
