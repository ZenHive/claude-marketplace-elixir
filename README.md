# Claude Code Plugins for Elixir

Unofficial Claude Code plugin marketplace for Elixir and BEAM ecosystem development.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## What is this?

This is a [**Claude Code plugin marketplace**](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces) that provides Elixir and BEAM ecosystem development tools for Claude Code.

> **Naming:** the GitHub repo is `claude-marketplace-elixir` (describes scope — Elixir/BEAM-focused), the marketplace namespace inside Claude Code is `deltahedge` (org identity, also used by language-agnostic plugins like `cloud-delegation`, `staged-review`, `task-driver`, `portfolio-strategy`). Plugins are referenced as `<plugin>@deltahedge`.

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
3. **Implement** → code + ROADMAP updates (`task-driver`)
4. **Code Review** → `staged-review:code-review` (pre-commit, any language) → commit
5. **Pre-merge gate** → `staged-review:commit-review` (cloud-agent PRs only — Cursor / Codex)
6. **Post-merge audit** → `staged-review:audit-review` (auto-fires after `gh pr create` and after every cloud-agent merge)
7. **QA** → `/elixir-qa` (post-implementation, Elixir-specific)

For small-medium features, `/elixir-oneshot` runs the implementation phases in one session. See [WORKFLOWS.md](.claude/WORKFLOWS.md) for details.

### Three-Tier Code Review Chain

The `staged-review` plugin covers the full pre-commit → pre-merge → post-merge axis with three sibling skills. Same 5+1 categories across all three; layers differ in **scope**, **reviewer count**, and **autonomy**:

| Layer | Skill | When | Scope | Reviewer |
|---|---|---|---|---|
| Pre-commit | `code-review` | `git diff --staged` | All 5+1 categories | Single (Claude) — fast triage with auto-apply |
| Pre-merge | `commit-review` | Cloud-agent PR before merge | Cat 1 + thin slice of Cat 6 | Single (Claude) — narrow correctness gate, auto-merges on ✅ + green CI + 5 preconditions |
| Post-merge | `audit-review` | After `gh pr create` / every cloud-agent merge | All 5+1 categories | **Dual (Claude + mandatory parallel Codex)**, with Claude+Codex dialogue on `discuss-design` — fully autonomous |

The expensive dual-reviewer work (parallel Codex dispatch + Claude+Codex dialogue) lives only in `audit-review`. Pre-commit and pre-merge stay fast and single-reviewer. Since `audit-review` auto-fires after `gh pr create` and after every cloud-agent merge, every commit reaches the dual-reviewer pass either way — duplicating it pre-commit would be redundant work on the same code.

Implementer / reviewer separation is preserved across the chain: each layer is a different session, no agent grades its own work.

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
| [elixir](./plugins/elixir/README.md) | Main Elixir development - consolidated hooks (format, compile, credo, sobelow, dialyzer, etc.) + 24 skills |
| [phoenix](./plugins/phoenix/README.md) | Phoenix framework patterns — setup and Nexus template |
| [elixir-workflows](./plugins/elixir-workflows/README.md) | Development workflow commands (research, plan, implement, QA, oneshot) |
| [serena](./plugins/serena/README.md) | Serena MCP integration - auto-activation and workflow helpers |

## Available Skills (33)

**Elixir plugin** (24 skills):

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
| elixir-ci-harness | Copy-ready `harness.yml` GitHub Actions workflow — drift-free version sourcing from `.tool-versions`, format/compile/credo/doctor/sobelow/test+cover/dialyzer gate; closes the Codex-Cloud-no-hex.pm gap |

**Phoenix plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| nexus-template | Nexus Phoenix admin dashboard template |
| phoenix-setup | Phoenix project setup — phx.gen.auth, Sobelow, LiveDebugger |

**Elixir-workflows plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| workflow-generator | Generate customized workflow commands for your project |

**Staged-review plugin** (3 skills):

| Skill | Description |
|-------|-------------|
| code-review | Pre-commit single-reviewer triage of `git diff --staged` — 5+1 categories, plan-mode-with-auto-apply, escalates `discuss-design` to user (defer-to-audit option available) |
| commit-review | Pre-merge cloud-agent PR gate (Cursor / Codex) — narrow Cat 1 + Cat 6 slice, CI-as-gate, asymmetric push-back (PR=line-level / Linear=scope), auto-merges on ✅ + green CI + 5 preconditions, chains audit-review |
| audit-review | Post-commit / post-merge audit on committed code — full 5+1, mandatory parallel Codex, Claude+Codex dialogue on `discuss-design`, auto-applies hygiene fixes, writes `.audit/<sha>.md` + `audit(...)` commit. **Fully autonomous.** Auto-invoked by worktree-workflow, commit-review, linear-workflow |

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
