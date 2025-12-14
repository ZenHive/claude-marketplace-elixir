# Changelog

All notable changes to the DeltaHedge Claude Code Plugin Marketplace.

## [Unreleased]

### Added
- Task 0f: API Consumer Macro Skill (pending)
- Task 7: Strict Pre-commit Mode (pending)
- Task 8: Test Failure Pattern Detection (pending)
- Tasks 9-11: Meta Plugin Template Updates (pending)
- Tasks 12-13: Documentation Updates (pending)

### Skills

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
| Skills Added | 4 (web-command, git-worktrees, roadmap-planning, tidewave-guide) |
| Tasks Completed | 14/23 (61%) |
| Tests Passing | 93/93 |

## Attribution

This marketplace is forked from [Bradley Golden's claude-marketplace-elixir](https://github.com/bradleygolden/claude-marketplace-elixir) under MIT license.
