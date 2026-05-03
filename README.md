# Claude Code Plugins for Elixir

Unofficial Claude Code plugin marketplace for Elixir and BEAM ecosystem development.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## What is this?

This is a [**Claude Code plugin marketplace**](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces) that provides Elixir and BEAM ecosystem development tools for Claude Code.

## Quick Start

### Install the Marketplace

```bash
claude
/plugin marketplace add ZenHive/claude-marketplace-elixir
```

### Install Plugins

```bash
/plugin install elixir@deltahedge           # Main Elixir hooks + skills
/plugin install phoenix@deltahedge          # Phoenix-specific skills
/plugin install elixir-workflows@deltahedge # Workflow commands (research, plan, implement, qa)
/plugin install git-commit@deltahedge       # Commit workflow
/plugin install serena@deltahedge           # Serena MCP integration
/plugin install notifications@deltahedge    # OS notifications
/plugin install code-quality@deltahedge     # Language-agnostic LLM code quality gate
/plugin install staged-review@deltahedge    # Universal code review workflow
/plugin install task-driver@deltahedge     # Roadmap-driven task execution
```

## Architecture

This marketplace uses a **layered architecture** inspired by Anthropic's [harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps). The key insight: separate the agent doing the work from the agent judging it.

```
Global Includes (workflow-philosophy.md, task-prioritization.md, etc.)
    → loaded by all projects — language-agnostic principles
Universal Plugins (staged-review, task-driver)
    → language-agnostic foundations — work for any project
Elixir-Specific Plugins (elixir, phoenix, elixir-workflows)
    → domain concerns: mix format, hooks.json, Elixir patterns
Automated Hooks (post-edit-check.sh, pre-commit-unified.sh)
    → real-time quality enforcement on every edit and commit
```

### Workflow Model

Each phase runs in a **fresh session** with file-based handoffs (`.thoughts/` directory):

1. **Interview/Brainstorm** → context docs
2. **Plan** → implementation plan with acceptance criteria
3. **Implement** → code + ROADMAP updates
4. **Code Review** → `staged-review:code-review` (pre-commit, any language)
5. **QA** → `/elixir-qa` (post-implementation, Elixir-specific)

For small-medium features, `/elixir-oneshot` runs all phases in one session. See [WORKFLOWS.md](.claude/WORKFLOWS.md) for details.

## Available Plugins (9)

**Universal plugins** (language-agnostic):

| Plugin | Description |
|--------|-------------|
| [code-quality](./plugins/code-quality) | LLM-based PreToolUse gate — blocks untracked TODOs, unmarked deferred work, stub functions, silent workarounds |
| [staged-review](./plugins/staged-review/README.md) | Universal code review workflow — bugs, extractions, TODOs, abstractions |
| [task-driver](./plugins/task-driver/README.md) | Roadmap-driven task execution — select by efficiency, implement, update docs |
| [git-commit](./plugins/git-commit/README.md) | Intelligent git commit workflow with AI-powered file grouping |
| [notifications](./plugins/notifications/README.md) | Native OS notifications when Claude Code needs attention |

**Elixir/Phoenix plugins**:

| Plugin | Description |
|--------|-------------|
| [elixir](./plugins/elixir/README.md) | Main Elixir development - consolidated hooks (format, compile, credo, sobelow, dialyzer, etc.) + 23 skills |
| [phoenix](./plugins/phoenix/README.md) | Phoenix framework patterns — setup and Nexus template |
| [elixir-workflows](./plugins/elixir-workflows/README.md) | Development workflow commands (research, plan, implement, QA, oneshot) |
| [serena](./plugins/serena/README.md) | Serena MCP integration - auto-activation and workflow helpers |

## Available Skills (31)

**Elixir plugin** (23 skills):

| Skill | Description |
|-------|-------------|
| hex-docs-search | Research Hex package API docs — function signatures, module docs, typespecs |
| usage-rules | Package-specific coding conventions, patterns, and best practices |
| development-commands | Mix commands reference — test.json, dialyzer.json, credo JSON, builds |
| dialyzer-json | AI-friendly Dialyzer output with `mix dialyzer.json` |
| ex-unit-json | AI-friendly test output with `mix test.json` |
| elixir-setup | Standard project setup — Styler, Credo, Dialyxir, Doctor, Tidewave |
| tidewave-guide | Tidewave MCP tools for runtime Elixir app interaction |
| web-command | When to use `web` command vs `WebFetch` tool |
| integration-testing | Integration testing patterns — credential handling, external APIs |
| popcorn | Run Elixir in the browser via WebAssembly |
| git-worktrees | Run multiple Claude Code sessions in parallel |
| zen-websocket | ZenWebsocket library for WebSocket connections |
| roadmap-planning | Prioritized roadmaps with D/B scoring |
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

**Phoenix plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| nexus-template | Nexus Phoenix admin dashboard template |
| phoenix-setup | Phoenix project setup — phx.gen.auth, Sobelow, LiveDebugger |

**Elixir-workflows plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| workflow-generator | Generate customized workflow commands for your project |

**Staged-review plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| code-review | Universal staged-file review — bugs, extractions, TODO markers, abstractions |
| commit-review | Cloud-agent PR review (Codex) — Linear `In Review` poll, harness fixes, verdict-only (user merges) |

**Task-driver plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| task-driver | Roadmap-driven task execution — select by efficiency, implement, update all docs |

**Cloud-delegation plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| linear-workflow | Linear-as-queue + cloud-agent (Codex, Cursor) delegation — flows, polling, push-back-vs-fix matrix, comment fetch (PR + Linear), cross-repo coordination |
| cloud-agent-environments | Cloud-agent env reference — what each can/can't reach (hex.pm, mix, Tidewave, HTTP), runtime gotchas, AGENTS.md generation workflow |

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/ZenHive/claude-marketplace-elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ZenHive/claude-marketplace-elixir/discussions)

## Attribution

This project is a fork of [claude-marketplace-elixir](https://github.com/bradleygolden/claude-marketplace-elixir), originally created by [Bradley Golden](https://github.com/bradleygolden).

---

**Made with care for the Elixir community**
