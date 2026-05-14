# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@~/.claude/includes/critical-rules.md

@~/.claude/includes/delegation-rules.md

@~/.claude/includes/task-prioritization.md

@~/.claude/includes/task-writing.md

@~/.claude/includes/rmap.md

@~/.claude/includes/workflow-philosophy.md

@~/.claude/includes/web-command.md

@~/.claude/includes/code-style.md

@~/.claude/includes/development-philosophy.md

@~/.claude/includes/agent-economy.md

@~/.claude/includes/elixir-setup.md

@~/.claude/includes/development-commands.md

@~/.claude/includes/ex-unit-json.md

@~/.claude/includes/dialyzer-json.md

## Repository Purpose

This is a **Claude Code plugin marketplace** for Elixir and BEAM ecosystem development. It provides automated development workflows through hooks that trigger on file edits and git operations.

**Naming:** GitHub repo is `claude-marketplace-elixir` (describes scope), Claude Code marketplace namespace is `deltahedge` (org identity — also covers language-agnostic plugins: `cloud-delegation`, `staged-review`, `task-driver`, `portfolio-strategy`). Plugins are referenced as `<plugin>@deltahedge`.

### Includes → Skills Sync

**`~/.claude/includes/*.md` files are canonical.** Skill SKILL.md files are auto-synced from includes — never edit skill bodies directly. After editing an include, run:

```bash
./scripts/sync-skills-from-includes.sh          # sync all 30 mapped skills
./scripts/sync-skills-from-includes.sh --dry-run # preview changes
```

The script preserves SKILL.md frontmatter (name, description, allowed-tools) and replaces the body with include content. See `scripts/sync-skills-from-includes.sh` for the full mapping.

### Setup Guide Sync Check

Verify `~/.claude/setup-guide.md` is in sync with actual includes on disk:

```bash
./scripts/check-setup-guide.sh          # report drift
./scripts/check-setup-guide.sh --quiet  # exit code only (0=ok, 1=drift)
```

Reports undocumented includes (files on disk not in setup-guide) and missing includes (referenced but not on disk). Run after adding or removing includes.

**Note:** A separate **SessionStart prompt hook** in `~/.claude/settings.json` handles per-project CLAUDE.md checks — it detects the project stack (Elixir, Phoenix, etc.) and flags missing includes against the setup-guide templates. That hook is user-level config, not part of this repo.

### Codex Plugin Sync

Generate a Codex-friendly subset of this marketplace (writes to `~/plugins/` and `~/.agents/plugins/marketplace.json`):

```bash
./scripts/sync-codex-plugins.py                  # dry-run (default)
./scripts/sync-codex-plugins.py --apply          # write files
./scripts/sync-codex-plugins.py --plugin elixir  # sync one plugin
./scripts/sync-codex-plugins.py --marketplace-only  # regenerate marketplace.json only
```

Transforms Claude-Code-specific tool names and frontmatter (`allowed-tools:`, `AskUserQuestion`, `TodoWrite`, `SlashCommand`) to Codex equivalents. The elixir subset is narrowed via explicit allow-lists for skills and scripts. Delegates include→skill sync to `~/.codex/skills/sync-claude-includes/scripts/sync_claude_includes.py` unless `--skip-core-sync` is passed. Tests live at `test/test-sync-codex-plugins.sh`.

For the current verified Codex integration status, active hook model, and
upstream tracking, see `codex_hooks_state.md`.

## Architecture

### Plugin Marketplace Structure

```
.claude-plugin/
└── marketplace.json          # Marketplace metadata and plugin registry

plugins/
├── elixir/                   # Main Elixir development plugin (was: core)
│   ├── .claude-plugin/
│   │   └── plugin.json       # Plugin metadata
│   ├── hooks/
│   │   └── hooks.json        # Hook definitions
│   ├── scripts/              # Consolidated hook scripts
│   └── README.md             # Plugin documentation
├── phoenix/                  # Phoenix-specific skills
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/               # Phoenix patterns, scope, JS, daisyUI, nexus
├── elixir-workflows/         # Workflow commands (was: elixir-meta)
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── commands/             # Workflow slash commands
│   └── skills/               # Workflow generator skill
├── git-commit/               # Commit workflow (was: git)
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── commands/
├── code-quality/             # Language-agnostic LLM code quality gate
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── hooks/                # PreToolUse prompt hook (TODO/workaround enforcement)
├── staged-review/            # Universal code review workflow
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/               # code-review skill
├── task-driver/              # Roadmap-driven task execution
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/               # task-driver, rmap (roadmap substrate)
└── cloud-delegation/         # Linear-as-queue + cloud-agent (Codex/Cursor) delegation
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/               # linear-queue, agent-dispatch, agent-pr-review, flow-review, linear-workflow hub, cloud-agent-environments, sprite-claude-code
```

### Key Concepts

**Marketplace (`marketplace.json`)**: Top-level descriptor that defines the marketplace namespace ("deltahedge"), version, and lists available plugins.

**Plugin (`plugin.json`)**: Each plugin has metadata (name, version, description, author). The `hooks/hooks.json` file is loaded automatically by convention - do NOT add a `hooks` field to plugin.json unless referencing additional hook files.

**Hooks (`hooks.json`)**: Define automated commands that execute in response to Claude Code events:
- `PostToolUse`: Runs after Edit/Write tools (e.g., auto-format, compile check)
- `PreToolUse`: Runs before tools execute (e.g., pre-commit validation before git commands)

### Hook Implementation Details

The marketplace uses consolidated hooks for efficiency (12 post-edit hooks → 2, 10 pre-commit hooks → 1):

**Elixir plugin** - Elixir-specific command hooks:
1. **post-edit-check.sh** (non-blocking, PostToolUse): After editing `.ex`/`.exs` files, runs format, compile, credo, sobelow, doctor, struct hints, hidden failure detection
2. **ash-codegen-check.sh** (non-blocking, PostToolUse): Runs `mix ash.codegen --check` if Ash dependency exists
3. **pre-commit-unified.sh** (blocking, PreToolUse): Before `git commit`, runs all quality checks (format, compile, credo, test, doctor, sobelow, dialyzer, mix_audit, ash.codegen, ex_doc). Defers to `mix precommit` if alias exists. Uses 180s timeout.
4. **suggest-test-include.sh** (non-blocking, PreToolUse): When `mix test.json` runs without `--include` flags, parses excluded tags from `test/test_helper.exs` and injects them into Claude's context. Prevents false "suite passes" claims when only the offline subset ran. Stays silent on focused runs (`--include`/`--only`/`--failed`/explicit test-file arg) and projects with no `exclude:` list.

**Code-quality plugin** - Language-agnostic LLM gate (separate from Elixir plugin so it installs cleanly on Rust/Go/Python projects):
1. **Code quality gate** (blocking, PreToolUse, `type: prompt`): Before Edit/Write/MultiEdit on source files (`.ex`, `.exs`, `.go`, `.rs`, `.js`, `.ts`, `.py`, `.rb`, `.java`, `.c`, `.cpp`, `.h`), the LLM itself evaluates the diff and denies untracked TODO/FIXME markers, unmarked deferred-work comments ("for now", "temporarily", …), stub functions, and silent workarounds. Markdown/config files bypass the check.

**Cloud-delegation plugin** - Cross-cutting AGENTS.md sync:
1. **agents-md-sync.sh** (non-blocking, PostToolUse): After editing `~/.claude/CLAUDE.md`, any direct child of `~/.claude/includes/`, or any `~/_DATA/code/<repo>/CLAUDE.md`, regenerates `AGENTS.md` via `scripts/sync-agents-md.sh` in every affected repo that has an existing `AGENTS.md` (never auto-creates). Idempotent; never stages or commits. Closes the staleness window between edit and the next SessionStart drift check.

**Staged-review plugin** - Audit-tail detection:
1. **check-unaudited-commits.sh** (non-blocking, SessionStart): Walks `git log --grep '^audit('` to find the last audit ancestor; emits `additionalContext` recommending `/staged-review:audit-status` or `Skill(audit-review)` when ≥3 commits sit past it. Silent below threshold or outside any git repo. Shares `unaudited-commits.sh` helper with the `/audit-status` slash command (Tasks 38 + 39).

Hooks use `jq` to extract tool parameters and bash conditionals to match file patterns or commands. Output is sent to Claude (the LLM) via JSON with either `additionalContext` (non-blocking) or `permissionDecision: "deny"` (blocking).

### Skills (41 total)

Skills provide specialized capabilities for Claude to use on demand, complementing automated hooks with user-invoked research and guidance. The agent-facing catalog (what each does, when to invoke) lives in `SKILLS.md` at the repo root — keep it in sync when adding or removing skills.

**Elixir plugin** (24 skills):

| Skill | Description |
|-------|-------------|
| hex-docs-search | Research Hex package API docs — function signatures, module docs, typespecs |
| usage-rules | Package-specific coding conventions, patterns, and best practices |
| development-commands | Mix commands reference — test.json, dialyzer.json, credo JSON, builds |
| dialyzer-json | AI-friendly Dialyzer output with `mix dialyzer.json` — fix hints, grouping |
| ex-unit-json | AI-friendly test output with `mix test.json` — flags, workflows, jq patterns |
| elixir-setup | Standard project setup — deps (Styler, Credo, Dialyxir, Doctor, Tidewave) |
| tidewave-guide | Tidewave MCP tools for runtime Elixir app interaction |
| web-command | When to use `web` command vs `WebFetch` tool for browsing |
| integration-testing | Integration testing patterns — credential handling, external APIs |
| popcorn | Popcorn: run Elixir in the browser via WebAssembly |
| git-worktrees | Run multiple Claude Code sessions in parallel using git worktrees |
| zen-websocket | ZenWebsocket library for WebSocket connections with reconnection |
| roadmap-planning | Prioritized roadmaps with D/B scoring for task lists |
| oxc | OXC Rust NIF — parse/transform/bundle/minify JS and TS via ESTree AST |
| quickbeam | QuickBEAM JS runtime on the BEAM — eval/call, pools, handler bridge |
| npm-ci-verify | npm_ex CI/install verification — lockfile sync, frozen installs |
| npm-security-audit | npm_ex security — CVE audit, license compliance, supply-chain risk |
| npm-dep-analysis | npm_ex graph analysis — size, fan-in/out, dedup, package quality |
| reach | Reach PDG/SDG — slicing, taint, dead-code, OTP state machines, codebase-level analysis |
| elixir-volt | JavaScript on the BEAM ecosystem map — OXC, QuickBEAM, npm_ex, Phoenix frontend stack |
| agent-economy | Designing APIs for AI agents — Descripex, manifests, MCP tools, EIP-8004 verification |
| api-toolkit | ApiToolkit — InboundLimiter, RateLimiter, Cache, Metrics, Provider DSL, Discovery |
| upstream-pr-workflow | Contributing PRs to forked libraries without leaking personal tooling into the diff |
| elixir-ci-harness | Copy-ready `harness.yml` GitHub Actions workflow — drift-free version sourcing from `.tool-versions`, format/compile/credo/doctor/sobelow/test+cover/dialyzer gate; default 85% coverage; closes the Codex-Cloud-no-hex.pm gap by making harness output a PR check |

**Phoenix plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| nexus-template | Nexus Phoenix admin dashboard template with Iconify icons |
| phoenix-setup | Phoenix project setup — phx.gen.auth, Sobelow, LiveDebugger, formatter |

**Elixir-workflows plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| workflow-generator | Generate customized workflow commands (research, plan, implement, qa) |

**Staged-review plugin** (3 skills):

| Skill | Description |
|-------|-------------|
| code-review | Pre-commit single-reviewer triage of `git diff --staged` — 5+1 categories, plan-mode-with-auto-apply (one user gate: exit-plan-to-apply). No Codex dispatch and no Claude+Codex dialogue at this layer — both moved to `audit-review` post-PR-create / post-merge to avoid duplicate dual-reviewer cost (every commit reaches audit-review either way via worktree-workflow auto-invoke). `discuss-design` items escalate to user, who can defer to audit-review's dialogue pass |
| commit-review | Pre-merge cloud-agent PR gate (Cursor / Codex when re-enabled) — narrowed Cat-1-only correctness audit, CI-as-gate via `gh pr checks`, asymmetric push-back channels (PR=line-level / Linear=scope), **auto-merges on ✅ + green CI + cloud-agent branch + no `requested-changes` + no `[BLOCK-MERGE]` label** then chains audit-review against the merge SHA |
| audit-review | Post-commit / post-merge audit on committed code — full 5+1 categories, mandatory parallel Codex dispatch, auto-applies hygiene fixes (ROADMAP/CHANGELOG/CLAUDE.md/README + in-code `@doc`/`@spec`), auto-resolves `discuss-design` via Claude+Codex dialogue (convergence applies, divergence drops to ROADMAP candidate), writes `.audit/<sha>.md` reports + commits as `audit(...)`. **Fully autonomous — zero user gates.** Auto-invoked by `worktree-workflow` (post-`gh pr create`), `commit-review` (auto-merge tail), and `linear-queue` (self-authored worktree flow, post-merge for non-auto-merge cases) |

**Task-driver plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| task-driver | Roadmap-driven task execution — select by efficiency, implement, update all docs |
| rmap | The `rmap` roadmap substrate — `roadmap/tasks.toml` is canonical, `ROADMAP.md` is rendered output; command surface by intent, D/B/U mapping, status/marker vocabulary, migration procedure for hand-edited roadmaps |

**Cloud-delegation plugin** (7 skills):

The Linear-as-queue + cloud-agent delegation workflow is split into four composable skills along a substrate/layer axis, plus a thin hub index. `linear-queue` is standalone — usable without cloud agents at all.

| Skill | Description |
|-------|-------------|
| linear-queue | Substrate — Linear MCP setup, workspace shape, issue-body-as-prompt template, status transitions, self-authored worktree flow, cross-repo coordination, ROADMAP-fallback. **Standalone** — usable without cloud agents |
| agent-dispatch | Dispatch layer — push self-contained tasks to cloud agents (Codex, Cursor): delegation flows, per-agent eligibility, plan-shaped issue specs, batch sizing, pre-flight conflict detection |
| agent-pr-review | Review layer — review and land cloud-agent PRs: polling, comment-fetch, review tiering, push-back-vs-fix-locally matrix, wake-mention discipline |
| flow-review | Merge-train mode for 2+ open cloud-agent PRs — dependency-sort, rebase cascade, per-PR auto-merge |
| linear-workflow | Hub index — points to the four skills above; use it to find which skill owns a concern |
| cloud-agent-environments | Cloud-agent env reference — what each cloud agent can/can't reach (hex.pm, mix tasks, Tidewave, HTTP), runtime gotchas, AGENTS.md generation workflow |
| sprite-claude-code | Operational reference for Fly Sprite-hosted Claude Code as a third cloud-delegation target |

**Dev-lifecycle plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| dev-lifecycle | Canonical six-phase chain reference — answers "which phase am I in?", "which skill owns this?", "what's the handoff?". Pure documentation |

**Portfolio-strategy plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| portfolio-strategy | Power-law portfolio rule for cross-repo decisions — start/continue/kill a project, where to spend attention. NOT for within-project prioritization (use roadmap-planning) |

**Skill Composition**: Skills are single-purpose and composed by agents/commands. `usage-rules` provides conventions (how to use correctly), `hex-docs-search` provides API docs (what's available). Agents can invoke both for comprehensive guidance.

## Development Commands

### Installing from GitHub (Recommended)

```bash
# From Claude Code
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install elixir@deltahedge
```

**Note**: Local directory marketplace loading (`/plugin marketplace add /path/to/dir`) has known bugs with cache/registry sync. Always use the GitHub format for reliable installation.

### Validation

After making changes to marketplace or plugin JSON files, validate structure:
```bash
# Check marketplace.json is valid JSON
cat .claude-plugin/marketplace.json | jq .

# Check plugin.json is valid JSON
cat plugins/elixir/.claude-plugin/plugin.json | jq .

# Check hooks.json is valid JSON
cat plugins/elixir/hooks/hooks.json | jq .
```

### Testing Plugin Hooks

The repository includes an automated test suite for plugin hooks:

```bash
# Run all plugin tests
./test/run-all-tests.sh

# Run tests for a specific plugin
./test/plugins/elixir/test-elixir-hooks.sh

# Via Claude Code slash command
/qa test                   # All plugins
/qa test elixir            # Specific plugin
```

**Test Framework**:
- `test/test-hook.sh` - Base testing utilities
- `test/run-all-tests.sh` - Main test runner
- `test/plugins/*/test-*-hooks.sh` - Plugin-specific test suites

**What the tests verify**:
- Hook exit codes (0 for success) and JSON permissionDecision for blocking
- Hook output patterns and JSON structure
- File type filtering (.ex, .exs, non-Elixir)
- Command filtering (git commit vs other commands)
- Blocking vs non-blocking behavior

See `test/README.md` for detailed documentation.

## Important Conventions

### Marketplace Path Configuration

**Source paths** in `marketplace.json` must:
- Start with `./` (required by schema validation)
- Be relative to the **marketplace root directory** (where `.claude-plugin/` is located)

```json
{
  "plugins": [
    {
      "name": "elixir",
      "source": "./plugins/elixir"  // Correct: relative to repo root
    }
  ]
}
```

**Common mistakes**:
- `"source": "./elixir"` - Wrong: looks for `/repo-root/elixir` instead of `/repo-root/plugins/elixir`
- `"source": "../plugins/core"` - Wrong: must start with `./`
- Adding `"hooks": "./hooks/hooks.json"` to plugin.json - Wrong: causes duplicate hook error (hooks.json is loaded automatically)

### Troubleshooting Plugin Errors

**"Plugin 'X' not found in marketplace 'Y'"**
1. Check that `source` paths in marketplace.json start with `./` and include the full path (e.g., `./plugins/elixir`)
2. Run the cleanup script and re-add from GitHub:
   ```bash
   ./scripts/clear-cache.sh
   # Restart Claude Code, then:
   /plugin marketplace add ZenHive/claude-marketplace-elixir
   /plugin install elixir@deltahedge
   ```

**"Plugin directory not found at path"**
- The `source` path resolves from the marketplace root (where `.claude-plugin/` is located)
- Verify the path exists: `ls -la /path/to/marketplace/<source-path>`
- `pluginRoot` field is metadata only - it does NOT affect source path resolution

**"Duplicate hooks file detected"**
- Remove the `hooks` field from plugin.json - `hooks/hooks.json` is loaded automatically
- Only use the `hooks` field for additional hook files beyond the standard location

**"Invalid schema: source must start with ./"**
- All source paths must begin with `./` (not `../` or absolute paths)
- Correct: `"source": "./plugins/elixir"`
- Wrong: `"source": "../plugins/elixir"` or `"source": "/abs/path"`

**Stale plugin references in settings**
- Check `~/.claude/settings.json` for orphaned `enabledPlugins` entries
- Remove entries referencing non-existent marketplaces
- Restart Claude Code after editing settings

**Changes not taking effect**
1. Run cleanup script: `./scripts/clear-cache.sh`
2. Restart Claude Code completely (close and reopen)
3. Re-add marketplace: `/plugin marketplace add ZenHive/claude-marketplace-elixir`
4. Install plugins: `/plugin install elixir@deltahedge`

### Marketplace Namespace

The marketplace uses the namespace `deltahedge` (defined in `marketplace.json`). Plugins are referenced as `<plugin-name>@deltahedge` (e.g., `elixir@deltahedge`).

### Hook Matcher Patterns

- `PostToolUse` matcher `"Edit|Write|MultiEdit"` triggers on any file modification tool
- `PreToolUse` matcher `"Bash"` triggers before bash commands execute
- Hook commands extract tool parameters using `jq -r '.tool_input.<field>'`

### Version Management

Plugin and marketplace versions are **independent** and version for different reasons:

**Plugin Version** (`plugins/*/. claude-plugin/plugin.json`):
- Bump when plugin functionality changes (hooks, scripts, commands, agents, bug fixes, docs)
- Use semantic versioning: major.minor.patch
- Each plugin versions independently based on its own changes

**Marketplace Version** (`.claude-plugin/marketplace.json`):
- Bump ONLY when catalog structure changes (add/remove plugins, marketplace metadata, reorganization)
- NOT when individual plugin versions change
- NOT when plugin functionality changes

This follows standard package registry practices (npm, PyPI, Homebrew) where the registry version is independent of package versions. Think of it like a bookstore: book editions (plugin versions) change independently of catalog editions (marketplace version).

## File Modification Guidelines

**After completing any task** — `SKILLS.md`, `README.md`, and `CLAUDE.md` all carry skill/plugin catalogs that drift if not updated together. A task is not complete until all three agree:
1. `SKILLS.md` (repo root) — agent-facing skill catalog. If the task added/removed/renamed a skill or changed its description, update the catalog row, the task→skill quick-routing table, and the skill count.
2. `README.md` — human-facing landing page. Update the plugin summary table, skill count, and install surface if the plugin set or counts changed.
3. `CLAUDE.md` (this file) — update the `### Skills` tables, the dir-tree, and the total count if marketplace structure changed.
4. `CHANGELOG.md` — add a `[Unreleased]` entry.

For a task that touches no skills or plugins this is a no-op — but still verify the three catalogs, don't assume.

**When editing JSON files**: Always maintain valid JSON structure. Use `jq` to validate after changes.

**When adding new plugins**:
1. Create plugin directory under `plugins/`
2. Add `.claude-plugin/plugin.json` with metadata inside the plugin directory
3. Add plugin to `plugins` array in `.claude-plugin/marketplace.json`
4. Create `README.md` documenting plugin features
5. Create test directory under `test/plugins/<plugin-name>/`

**When modifying hooks**:
1. Edit `plugins/<plugin-name>/hooks/hooks.json`
2. Update hook script in `plugins/<plugin-name>/scripts/` if needed
3. Run automated tests: `./test/plugins/<plugin-name>/test-<plugin-name>-hooks.sh`
4. Update plugin README.md to document hook behavior
5. Consider hook execution time and blocking behavior

## Hook Script Best Practices

**Exit Codes**:
- `0` - Success (allows operation to continue or suppresses output)
- `1` - Error (script failure)

**JSON Output Patterns**:
```bash
# Non-blocking with context (PostToolUse)
jq -n --arg context "$OUTPUT" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $context
  }
}'

# Suppress output when not relevant
jq -n '{"suppressOutput": true}'

# Blocking (PreToolUse) - JSON permissionDecision with exit 0
jq -n \
  --arg reason "$ERROR_MSG" \
  --arg msg "Commit blocked: validation failed" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    },
    "systemMessage": $msg
  }'
exit 0
```

**Common Patterns**:
- Project detection: Find Mix project root by traversing upward from file/directory
- Dependency detection: Use `grep -qE '\{:dependency_name' mix.exs` to check for specific dependency
- File filtering: Check file extensions with `grep -qE '\.(ex|exs)$'`
- Command filtering: Check for specific commands like `grep -q 'git commit'`
- Exit code handling: Check if variable is empty with `[[ -z "$VAR" ]]`, not `$?` after command substitution

## TodoWrite Best Practices

When using TodoWrite in slash commands and workflows:

**When to use**:
- Multi-step tasks with 3+ discrete actions
- Complex workflows requiring progress tracking
- User-requested lists of tasks
- Immediately when starting a complex command execution

**Required fields**:
- `content`: Imperative form describing what needs to be done (e.g., "Run tests")
- `activeForm`: Present continuous form shown during execution (e.g., "Running tests")
- `status`: One of `pending`, `in_progress`, `completed`

**Best practices**:
- Create todos at the START of command execution, not after
- Mark ONE task as `in_progress` at a time
- Mark tasks as `completed` IMMEDIATELY after finishing (don't batch)
- Break complex tasks into specific, actionable items
- Use clear, descriptive task names
- Update status in real-time as work progresses

**Example pattern**:
```javascript
[
  {"content": "Parse user input", "status": "completed", "activeForm": "Parsing user input"},
  {"content": "Research existing patterns", "status": "in_progress", "activeForm": "Researching existing patterns"},
  {"content": "Generate implementation plan", "status": "pending", "activeForm": "Generating implementation plan"}
]
```

**Elixir-workflows Plugin**: The `elixir-workflows` plugin can generate customized workflow commands for other Elixir projects via `/elixir-workflows:workflow-generator`. Templates use `{{DOCS_LOCATION}}` variable (default: `.thoughts`) for configurability.

### Six-Phase Development Lifecycle

```
task-driver(1) → worktree(2) → bots(3) → commit-review(4) → merge(5) → audit-review(6)
```

| Phase | Skill / Actor |
|---|---|
| 1 — Plan-and-File | `task-driver:task-driver` (Plan-and-File mode) |
| 2 — Implement | implementer session + `staged-review:code-review` (pre-commit sub-phase) |
| 3 — Bots | external (CodeRabbit, Copilot, Codex's GitHub bot) |
| 4 — Pre-merge gate | `staged-review:commit-review` |
| 5 — Merge | `commit-review` auto-merge tail OR user manual `gh pr merge` |
| 6 — Post-merge audit | `staged-review:audit-review` |

Canonical reference (full phase descriptions, Linear-status transitions, handoff rules, end-to-end narrative): **`Skill(dev-lifecycle)`** or `~/.claude/includes/dev-lifecycle.md` / `plugins/dev-lifecycle/skills/dev-lifecycle/SKILL.md`. The chain is language-agnostic and composes only the already-language-agnostic `task-driver`, `staged-review`, and `cloud-delegation` plugins. Auto-merge preconditions: `delegation-rules.md` § "DON'T AUTO-MERGE PRS". Worktree scoping: `worktree-workflow.md`.

## Plugin Development Tools

When creating or modifying plugins, hooks, skills, or agents in this marketplace, use these tools from the `plugin-dev` and `hookify` plugins:

### plugin-dev Skills (Documentation & Guidance)

| Skill | When to Use |
|-------|-------------|
| `/plugin-dev:plugin-structure` | Plugin directory layout, manifest configuration, component organization |
| `/plugin-dev:hook-development` | Creating hooks (PreToolUse, PostToolUse, Stop, SessionStart, etc.) |
| `/plugin-dev:command-development` | Slash command structure, YAML frontmatter, dynamic arguments |
| `/plugin-dev:skill-development` | Skill structure, progressive disclosure, best practices |
| `/plugin-dev:agent-development` | Agent frontmatter, system prompts, triggering conditions |
| `/plugin-dev:mcp-integration` | MCP server integration, .mcp.json configuration |
| `/plugin-dev:plugin-settings` | Plugin configuration via .local.md files |

### plugin-dev Workflows & Validation

| Tool | Purpose |
|------|---------|
| `/plugin-dev:create-plugin` | Guided end-to-end plugin creation workflow |
| `plugin-dev:plugin-validator` (agent) | Validates plugin structure and plugin.json schema |
| `plugin-dev:skill-reviewer` (agent) | Reviews skill quality and best practices |
| `plugin-dev:agent-creator` (agent) | Creates autonomous agents for plugins |

### hookify Tools (Hook Generation)

| Tool | Purpose |
|------|---------|
| `/hookify:hookify` | Create hooks from conversation analysis or explicit instructions |
| `/hookify:writing-rules` | Guidance on hookify rule syntax and patterns |
| `/hookify:list` | List all configured hookify rules |
| `/hookify:configure` | Enable or disable hookify rules interactively |
| `/hookify:help` | Get help with the hookify plugin |
| `hookify:conversation-analyzer` (agent) | Analyzes conversations to find behaviors worth preventing |

### Recommended Workflow for Plugin Development

1. **Start**: Run `/plugin-dev:create-plugin` for guided scaffolding
2. **Learn patterns**: Use `/plugin-dev:hook-development`, `/plugin-dev:skill-development`, etc. for specific component guidance
3. **Validate**: Use `plugin-dev:plugin-validator` agent to check structure
4. **Review**: Use `plugin-dev:skill-reviewer` agent to review skill quality
5. **Create hooks from behavior**: Use `/hookify:hookify` to generate hooks from unwanted behaviors

## Git Commit Configuration

**Configured**: 2025-10-28

### Commit Message Format

**Format**: imperative-mood

#### Imperative Mood Template
```
<description>
```
Start with imperative verb: Add, Update, Fix, Remove, etc.

