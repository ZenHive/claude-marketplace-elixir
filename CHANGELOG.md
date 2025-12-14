# Changelog

All notable changes to the DeltaHedge Claude Code Plugin Marketplace.

## [Unreleased]

### Changed

**Metadata Standardization (Task 6)**
- Standardized author fields across all 13 plugin.json files
- Unified author name to "DeltaHedge" (was "Bradley Golden" in most plugins)
- Unified author URL to "https://github.com/ZenHive" (was personal GitHub or email)
- Removed `email` field from git plugin in favor of `url`
- Added missing `url` field to claude-md-includes plugin

**Documentation Cleanup (Task 9)**
- Replaced verbose TodoWrite structure examples with references to CLAUDE.md best practices
- Updated elixir-interview.md, elixir-research.md, elixir-plan.md, elixir-implement.md, elixir-oneshot.md
- Reduced TodoWrite documentation duplication from ~200 lines to ~30 lines

**Naming Consistency & Cleanup**
- Renamed test directories from underscores to hyphens (`postedit_test` → `postedit-test`)
- Renamed `hooks-handlers/` to `scripts/` in claude-md-includes plugin
- Renamed `pre-commit-test.sh` to `pre-commit-check.sh` in ex_unit plugin
- Removed unused `keywords` arrays from marketplace.json (-80 lines)
- Added composable @include directives to project CLAUDE.md
- Fixed command names in CLAUDE.md to match actual file names (`/interview` → `/elixir-interview`, etc.)
- Documented naming convention: `elixir-` prefix for Elixir-specific commands, `/create-plugin` intentionally unprefixed

### Added

**Refactoring Roadmap**
- Added REFACTOR.md tracking 12 technical debt cleanup tasks across 5 phases
- Estimated 85% reduction in script duplication after completion

- Tasks 12-13: Documentation Updates (pending)

### Plugins

**Task 9: Meta Plugin Rename & Template Updates** [D:6/B:8]
- Renamed `meta` plugin to `elixir-meta`
- Updated marketplace.json and plugin.json references
- Prefixed workflow commands with `elixir-` (elixir-research, elixir-plan, elixir-implement, elixir-qa, elixir-oneshot, elixir-interview)
- Added D/B scoring format to plan and QA templates
- Replaced WebFetch with `web` command in popcorn skill
- Documented workflow evaluation decision in elixir-meta README
- Decision: Keep workflow commands as complementary tools to roadmap-based development

### Skills

**Task 14: Popcorn (Browser Elixir) Skill** [D:4/B:6]
- Client-side Elixir guide for browser WebAssembly apps via Popcorn library
- Architecture overview: Elixir → AtomVM → WASM → Browser
- When to use: offline-first tools, calculators, privacy-preserving analytics
- When NOT to use: real-time trading, streaming data, persistent state
- Project setup with OTP 26.0.2 / Elixir 1.17.3 requirements
- JS interop: `Popcorn.Wasm.run_js/3`, event listeners, data type mapping
- Limitations and workarounds (no direct API calls, localStorage for persistence)
- Example patterns: calculator, data filter, form validation
- Location: `plugins/core/skills/popcorn/`

### Hooks

**Task 7: Strict Pre-commit Mode** [D:3/B:8]
- Enhanced precommit plugin to run comprehensive quality gates when no `mix precommit` alias exists
- Checks: `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix doctor`
- All checks always required (no conditional dependency detection)
- Clear error messages indicating which check failed
- Bypassable with `--no-verify`
- Location: `plugins/precommit/scripts/pre-commit-check.sh`

**Task 8: Test Failure Pattern Detection** [D:4/B:10]
- PostToolUse hook detects test patterns that silently pass on errors
- Detects: `{:error, _} -> assert true`, `{:error, _} -> :ok`
- Non-blocking warning via `additionalContext` with correct alternatives
- Only scans `_test.exs` files
- Location: `plugins/core/scripts/detect-hidden-failures.sh`

### Skills

**Task 0f: API Consumer Macro Skill** [D:3/B:9]
- Macro-based API client generation for Elixir REST APIs
- Part 0: Layered abstraction pattern (wrap existing libraries, don't reimplement)
- Part 1: Declarative macro pattern with compile-time code generation
- Part 2: API sync checking mix task and fixture generation
- Part 3: OpenAPI enhancement (optional code generation from specs)
- Decision tree: Build vs Wrap for API client architecture
- Location: `plugins/core/skills/api-consumer/`

**Task 5: Phoenix 1.8 Patterns Skill** [D:3/B:9]
- Quick reference for Phoenix 1.8+ framework patterns
- Covers: project setup, template wrapper, form handling, LiveView streams
- Authentication routing, HEEx syntax, verified routes, Tailwind v4
- Common pitfalls and runtime error patterns
- Location: `plugins/core/skills/phoenix-patterns/`

---

## [1.0.0] - 2025-12-13

### Fork & Rebrand

**Task 1: Update Marketplace Ownership** [D:1/B:8]
- Changed owner from "Bradley Golden" to "DeltaHedge"
- Updated all repository URLs to `https://github.com/ZenHive/claude-marketplace-elixir`
- Updated LICENSE with fork attribution
- Updated README with attribution section

**Task 2: Update Namespace** [D:1/B:6]
- Changed namespace from `elixir` to `deltahedge`
- Plugins now referenced as `core@deltahedge`, `credo@deltahedge`, etc.
- Updated all documentation and command files

### New Plugins

**Task 3: claude-md-includes Plugin** [D:1/B:9]
- SessionStart hook processes `@include <path>` directives in CLAUDE.md
- Enables composable instruction files from reusable components
- Recursive includes with circular detection (max depth: 10)
- Path resolution: `~/` (home), `./` (relative), absolute paths
- Security: Path traversal validation, code block detection
- Location: `plugins/claude-md-includes/`

**Task 4: Doctor Plugin** [D:2/B:9]
- Pre-commit hook for `mix doctor` documentation validation
- Blocks commits if documentation issues found
- 7 tests pass
- Location: `plugins/doctor/`

### New Skills

**Task 0b: Web Command Skill** [D:2/B:9]
- Documents `web` command for browsing in Claude Code
- Covers LiveView forms, screenshots, JavaScript execution, session persistence
- Replaces WebFetch usage guidance
- Location: `plugins/core/skills/web-command/`

**Task 0d: Git Worktrees Skill** [D:2/B:9]
- Guides parallel Claude Code sessions with git worktrees
- Covers setup, workflow patterns, cleanup
- Location: `plugins/core/skills/git-worktrees/`

**Task 0g: Roadmap Planning Skill** [D:2/B:8]
- D/B scoring framework for task prioritization
- Priority indicators, phase organization, dependency tracking
- Location: `plugins/core/skills/roadmap-planning/`

**Task 6: Tidewave Guide Skill** [D:2/B:8]
- MCP tools usage guide for Elixir development
- Setup instructions, "explore before coding" workflow
- Location: `plugins/core/skills/tidewave-guide/`

### Infrastructure

**Task 0a: D/B Scoring Documentation** [D:1/B:7]
- Already implemented in `~/.claude/includes/task-prioritization.md`
- Projects include via `@include` directive

**Task 0c: WebFetch Cleanup** [D:1/B:8]
- Audited all files for WebFetch references
- Codebase clean - uses WebSearch and curl appropriately

**Task 0e: Local Marketplace Testing** [D:1/B:10]
- Marketplace added to Claude Code session for development testing
- Enables immediate validation of plugins during development

**Task 0h: Plugin Structure Validation** [D:1/B:7]
- Validated 12/12 plugins exist and have valid JSON
- Validated 3/3 skills have proper frontmatter
- Validated 17/17 hook scripts are executable
- Baseline: 86 tests pass

**Task 3b: Split Global CLAUDE.md** [D:2/B:8]
- Created 12 modular include files in `~/.claude/includes/`
- Universal includes: critical-rules, task-prioritization, web-command, code-style, development-philosophy, documentation-guidelines
- Elixir/Phoenix includes: development-commands, slash-commands, phoenix-setup, phoenix-patterns, elixir-patterns, library-design

**Task 14: Full Test Suite Validation** [D:2/B:9]
- All 93/93 plugin tests pass
- All 13/13 plugins validated
- Fixed missing plugin entries in settings
- Fixed outdated agent documentation

---

## Summary

| Category | Count |
|----------|-------|
| Plugins Added | 2 (claude-md-includes, doctor) |
| Skills Added | 7 (web-command, git-worktrees, roadmap-planning, tidewave-guide, api-consumer, phoenix-patterns, popcorn) |
| Hooks Added | 2 (strict precommit, test failure detection) |
| Tasks Completed | 19/22 (86%) |
| Tests Passing | 93/93 |

## Attribution

This marketplace is forked from [Bradley Golden's claude-marketplace-elixir](https://github.com/bradleygolden/claude-marketplace-elixir) under MIT license.
