# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@include ~/.claude/includes/across-instances.md

@include ~/.claude/includes/critical-rules.md

@include ~/.claude/includes/task-prioritization.md

@include ~/.claude/includes/web-command.md

@include ~/.claude/includes/code-style.md

@include ~/.claude/includes/development-philosophy.md

@include ~/.claude/includes/elixir-patterns.md

@include ~/.claude/includes/api-integration.md

@include ~/.claude/includes/library-design.md

## Repository Purpose

This is a **Claude Code plugin marketplace** for Elixir and BEAM ecosystem development. It provides automated development workflows through hooks that trigger on file edits and git operations.

## Architecture

### Plugin Marketplace Structure

```
.claude-plugin/
└── marketplace.json          # Marketplace metadata and plugin registry

plugins/
├── core/                     # Core Elixir development plugin
│   ├── .claude-plugin/
│   │   └── plugin.json       # Plugin metadata
│   ├── hooks/
│   │   └── hooks.json        # Hook definitions
│   └── README.md             # Plugin documentation
├── credo/                    # Credo static analysis plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── hooks/
│   │   └── hooks.json
│   ├── scripts/
│   │   ├── post-edit-check.sh
│   │   └── pre-commit-check.sh
│   └── README.md
├── ash/                      # Ash Framework codegen plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── hooks/
│   │   └── hooks.json
│   ├── scripts/
│   │   ├── post-edit-check.sh
│   │   └── pre-commit-check.sh
│   └── README.md
└── dialyzer/                 # Dialyzer type analysis plugin
    ├── .claude-plugin/
    │   └── plugin.json
    ├── hooks/
    │   └── hooks.json
    ├── scripts/
    │   └── pre-commit-check.sh
    └── README.md

test/plugins/
├── core/                     # Core plugin tests
│   ├── README.md
│   ├── autoformat-test/
│   ├── compile-test/
│   └── precommit-test/
├── credo/                    # Credo plugin tests
│   ├── README.md
│   ├── postedit-test/
│   └── precommit-test/
├── ash/                      # Ash plugin tests
│   ├── README.md
│   ├── postedit-test/
│   ├── precommit-test/
│   └── test-ash-hooks.sh
└── dialyzer/                 # Dialyzer plugin tests
    ├── README.md
    ├── precommit-test/
    └── test-dialyzer-hooks.sh
```

### Key Concepts

**Marketplace (`marketplace.json`)**: Top-level descriptor that defines the marketplace namespace ("deltahedge"), version, and lists available plugins.

**Plugin (`plugin.json`)**: Each plugin has metadata (name, version, description, author). The `hooks/hooks.json` file is loaded automatically by convention - do NOT add a `hooks` field to plugin.json unless referencing additional hook files.

**Hooks (`hooks.json`)**: Define automated commands that execute in response to Claude Code events:
- `PostToolUse`: Runs after Edit/Write tools (e.g., auto-format, compile check)
- `PreToolUse`: Runs before tools execute (e.g., pre-commit validation before git commands)

### Hook Implementation Details

Each plugin implements workflows through hooks:

**Core plugin** - Universal Elixir development:
1. **Auto-format** (non-blocking, PostToolUse): After editing `.ex`/`.exs` files, runs `mix format {{file_path}}`
2. **Compile check** (informational, PostToolUse): After editing, runs `mix compile --warnings-as-errors` and provides compilation errors as context to Claude via `additionalContext`
3. **Pre-commit validation** (blocking, PreToolUse): Before `git commit`, validates formatting, compilation, and unused deps, blocking commits on failures

**Credo plugin** - Static code analysis:
1. **Post-edit check** (non-blocking, PostToolUse): Runs `mix credo suggest --format=json` on edited files
2. **Pre-commit check** (blocking, PreToolUse): Runs `mix credo --strict` before commits, blocks if issues found

**Ash plugin** - Ash Framework code generation:
1. **Post-edit check** (non-blocking, PostToolUse): Runs `mix ash.codegen --check` to detect when generated code is out of sync
2. **Pre-commit validation** (blocking, PreToolUse): Blocks commits if `mix ash.codegen --check` fails

**Dialyzer plugin** - Static type analysis:
1. **Pre-commit check** (blocking, PreToolUse): Runs `mix dialyzer` before commits, blocks if type errors found. Uses 120s timeout due to potential analysis time.

Hooks use `jq` to extract tool parameters and bash conditionals to match file patterns or commands. Output is sent to Claude (the LLM) via JSON with either `additionalContext` (non-blocking) or `permissionDecision: "deny"` (blocking).

### Skills

Skills provide specialized capabilities for Claude to use on demand, complementing automated hooks with user-invoked research and guidance.

**Core plugin** - Research and best practices skills:
1. **hex-docs-search** (core@deltahedge): Searches Hex package documentation with progressive fetch strategy
   - Searches local deps → fetched cache → fetches if needed → HexDocs API → web search
   - Stores fetched docs in `.hex-docs/` and source in `.hex-packages/`
   - Provides API documentation, function signatures, and usage examples
   - See `plugins/core/skills/hex-docs-search/SKILL.md`

2. **usage-rules** (core@deltahedge): Searches package-specific usage rules and best practices
   - Searches local deps → fetched cache → fetches if needed
   - Stores fetched rules in `.usage-rules/<package>-<version>/`
   - Provides coding conventions, patterns, and good/bad examples
   - Context-aware section extraction based on coding context
   - See `plugins/core/skills/usage-rules/SKILL.md`

**Elixir-meta plugin** - Workflow generation skill:
1. **workflow-generator** (elixir-meta@deltahedge): Generates project-specific workflow commands
   - Creates customized research, plan, implement, and QA commands
   - Asks questions about project structure and preferences
   - Outputs slash commands tailored to project needs
   - See `plugins/elixir-meta/skills/workflow-generator/SKILL.md`

**Skill Composition**:
Skills are designed to be **single-purpose** and **composed by agents/commands**:
- `usage-rules` provides conventions and patterns (how to use correctly)
- `hex-docs-search` provides API documentation (what's available)
- Agents can invoke both for comprehensive guidance ("best practices + API")
- Skills remain independent, composition happens through higher-level constructs

## Development Commands

### Installing from GitHub (Recommended)

```bash
# From Claude Code
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install core@deltahedge
```

**Note**: Local directory marketplace loading (`/plugin marketplace add /path/to/dir`) has known bugs with cache/registry sync. Always use the GitHub format for reliable installation.

### Validation

After making changes to marketplace or plugin JSON files, validate structure:
```bash
# Check marketplace.json is valid JSON
cat .claude-plugin/marketplace.json | jq .

# Check plugin.json is valid JSON
cat plugins/core/.claude-plugin/plugin.json | jq .

# Check hooks.json is valid JSON
cat plugins/core/hooks/hooks.json | jq .
```

### Testing Plugin Hooks

The repository includes an automated test suite for plugin hooks:

```bash
# Run all plugin tests
./test/run-all-tests.sh

# Run tests for a specific plugin
./test/plugins/core/test-core-hooks.sh
./test/plugins/credo/test-credo-hooks.sh
./test/plugins/ash/test-ash-hooks.sh
./test/plugins/dialyzer/test-dialyzer-hooks.sh

# Via Claude Code slash command
/qa test                   # All plugins
/qa test core              # Specific plugin
/qa test ash               # Specific plugin
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
      "name": "core",
      "source": "./plugins/core"  // Correct: relative to repo root
    }
  ]
}
```

**Common mistakes**:
- `"source": "./core"` - Wrong: looks for `/repo-root/core` instead of `/repo-root/plugins/core`
- `"source": "../plugins/core"` - Wrong: must start with `./`
- Adding `"hooks": "./hooks/hooks.json"` to plugin.json - Wrong: causes duplicate hook error (hooks.json is loaded automatically)

### Troubleshooting Plugin Errors

**"Plugin 'X' not found in marketplace 'Y'"**
1. Check that `source` paths in marketplace.json start with `./` and include the full path (e.g., `./plugins/core`)
2. Run the cleanup script and re-add from GitHub:
   ```bash
   ./scripts/clear-cache.sh
   # Restart Claude Code, then:
   /plugin marketplace add ZenHive/claude-marketplace-elixir
   /plugin install core@deltahedge
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
- Correct: `"source": "./plugins/core"`
- Wrong: `"source": "../plugins/core"` or `"source": "/abs/path"`

**Stale plugin references in settings**
- Check `~/.claude/settings.json` for orphaned `enabledPlugins` entries
- Remove entries referencing non-existent marketplaces
- Restart Claude Code after editing settings

**Changes not taking effect**
1. Run cleanup script: `./scripts/clear-cache.sh`
2. Restart Claude Code completely (close and reopen)
3. Re-add marketplace: `/plugin marketplace add ZenHive/claude-marketplace-elixir`
4. Install plugins: `/plugin install core@deltahedge`

### Marketplace Namespace

The marketplace uses the namespace `deltahedge` (defined in `marketplace.json`). Plugins are referenced as `<plugin-name>@deltahedge` (e.g., `core@deltahedge`).

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

## Agent Pattern for Token Efficiency

The marketplace uses specialized agents for token-efficient workflows:

**Finder Agent** (`.claude/agents/finder.md`):
- **Role**: Fast file location without reading (uses haiku model)
- **Tools**: Grep, Glob, Bash, Skill (NO Read tool)
- **Purpose**: Creates maps of WHERE files are, organized by purpose
- **Output**: File paths and locations, no code analysis

**Analyzer Agent** (`.claude/agents/analyzer.md`):
- **Role**: Deep code analysis with file reading (uses sonnet model)
- **Tools**: Read, Grep, Glob, Bash, Skill
- **Purpose**: Explains HOW things work by reading specific files
- **Output**: Execution flows, technical analysis with file:line references

**Token-Efficient Workflow Pattern**:
```
Step 1: Spawn finder → Locates relevant files (cheap, fast)
Step 2: Spawn analyzer → Reads files found by finder (expensive but targeted)
```

This pattern reduces token usage by 30-50% compared to having analyzer explore and read everything.

**When to Use**:
- Use **parallel** when researching independent aspects (no dependency)
- Use **sequential** (finder first, then analyzer) when analyzer needs file paths from finder

See `.claude/commands/elixir-qa.md` (lines 807-844) and `.claude/commands/elixir-research.md` (lines 56-73) for examples.

## Workflow System

The marketplace includes a comprehensive workflow system for development:

**Commands**:
- `/elixir-interview` - Gather context through interactive questioning
- `/elixir-research` - Research codebase with parallel agents
- `/elixir-plan` - Create detailed implementation plans
- `/elixir-implement` - Execute plans with verification
- `/elixir-qa` - Validate implementation quality
- `/elixir-oneshot` - Complete workflow (research → plan → implement → qa)
- `/create-plugin` - Scaffold new plugin structure (no prefix - not Elixir-specific)

**Naming Convention**: Commands use `elixir-` prefix for Elixir/BEAM-specific workflows. The `/create-plugin` command intentionally has no prefix because it creates Claude Code plugins for any language or purpose.

**Documentation Location**: All workflow artifacts saved to `.thoughts/`
```
.thoughts/
├── interview/          # Interview context documents
├── research/           # Research documents
├── plans/              # Implementation plans
└── [date]-*.md        # QA and oneshot reports
```

See `.claude/WORKFLOWS.md` for complete workflow documentation.

**Elixir-meta Plugin**: The `elixir-meta` plugin can generate customized workflow commands for other Elixir projects via `/elixir-meta:workflow-generator`. Templates use `{{DOCS_LOCATION}}` variable (default: `.thoughts`) for configurability.

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

## Quality Gates

Before pushing changes, run:
```bash
/elixir-qa
```

This validates:
- JSON structure and validity
- Hook script correctness (exit codes, output patterns)
- Version management (marketplace and plugin versions)
- Documentation completeness
- Test coverage
- Comment quality (removes unnecessary, keeps critical)

## Git Commit Configuration

**Configured**: 2025-10-28

### Commit Message Format

**Format**: imperative-mood

#### Imperative Mood Template
```
<description>
```
Start with imperative verb: Add, Update, Fix, Remove, etc.


