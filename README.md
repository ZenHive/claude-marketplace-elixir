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

1. **Plan** → implementation plan with acceptance criteria (`task-driver`)
2. **Implement** → code + ROADMAP updates (`task-driver`)
3. **Code Review** → `staged-review:code-review` (pre-commit, any language) → commit
4. **Pre-merge gate** → `staged-review:commit-review` (cloud-agent PRs only — Cursor / Codex)
5. **Post-merge audit** → `staged-review:audit-review` (auto-fires after `gh pr create` and after every cloud-agent merge)

### Three-Tier Code Review Chain

The `staged-review` plugin covers the full pre-commit → pre-merge → post-merge axis with three sibling skills. Same 5+1 categories across all three; layers differ in **scope**, **reviewer count**, and **autonomy**:

| Layer | Skill | When | Scope | Reviewer |
|---|---|---|---|---|
| Pre-commit | `code-review` | `git diff --staged` | All 5+1 categories | Single (Claude) — fast triage with auto-apply |
| Pre-merge | `commit-review` | Cloud-agent PR before merge | Cat 1 + thin slice of Cat 6 | Single (Claude) — narrow correctness gate, auto-merges on ✅ + green CI + 5 preconditions |
| Post-merge | `audit-review` | After `gh pr create` / every cloud-agent merge | All 5+1 categories | **Dual (Claude + mandatory parallel Codex)**, with Claude+Codex dialogue on `discuss-design` — fully autonomous |

The expensive dual-reviewer work (parallel Codex dispatch + Claude+Codex dialogue) lives only in `audit-review`. Pre-commit and pre-merge stay fast and single-reviewer. Since `audit-review` auto-fires after `gh pr create` and after every cloud-agent merge, every commit reaches the dual-reviewer pass either way — duplicating it pre-commit would be redundant work on the same code.

Implementer / reviewer separation is preserved across the chain: each layer is a different session, no agent grades its own work.

## Available Plugins (10)

**Universal plugins** (language-agnostic):

| Plugin | Description |
|--------|-------------|
| [code-quality](./plugins/code-quality) | LLM-based PreToolUse gate — blocks untracked TODOs, unmarked deferred work, stub functions, silent workarounds |
| [staged-review](./plugins/staged-review/README.md) | Universal code review workflow — bugs, extractions, TODOs, abstractions |
| [task-driver](./plugins/task-driver/README.md) | Roadmap-driven task execution — select by efficiency, implement, update docs |
| [git-commit](./plugins/git-commit/README.md) | Intelligent git commit workflow with AI-powered file grouping |
| [portfolio-strategy](./plugins/portfolio-strategy) | Power-law portfolio rule — cross-repo decision framework |
| [cloud-delegation](./plugins/cloud-delegation/README.md) | Linear-as-queue + cloud-agent (Codex, Cursor) delegation workflow |
| [dev-lifecycle](./plugins/dev-lifecycle/README.md) | Canonical reference for the six-phase development lifecycle |

**Elixir/Phoenix plugins**:

| Plugin | Description |
|--------|-------------|
| [elixir](./plugins/elixir/README.md) | Main Elixir development - consolidated hooks (format, compile, credo, sobelow, dialyzer, etc.) + 24 skills |
| [phoenix](./plugins/phoenix/README.md) | Phoenix framework patterns — setup and Nexus template |
| [elixir-workflows](./plugins/elixir-workflows/README.md) | Workflow-command generator for other Elixir projects |

## Skills (41)

41 skills across 8 plugins. For the full **agent-facing catalog** — what each skill does and when to invoke it — see **[SKILLS.md](SKILLS.md)**.

| Plugin | Skills | Focus |
|--------|--------|-------|
| [elixir](./plugins/elixir/README.md) | 24 | Setup & tooling, research, testing, JS-on-BEAM, static analysis, API design |
| [cloud-delegation](./plugins/cloud-delegation/README.md) | 7 | Linear-as-queue + cloud-agent (Codex/Cursor) delegation chain |
| [staged-review](./plugins/staged-review/README.md) | 3 | Pre-commit → pre-merge → post-merge review chain |
| [phoenix](./plugins/phoenix/README.md) | 2 | Phoenix setup + Nexus admin template |
| [task-driver](./plugins/task-driver/README.md) | 2 | Roadmap-driven task execution + the `rmap` roadmap substrate |
| [dev-lifecycle](./plugins/dev-lifecycle/README.md) | 1 | Six-phase development lifecycle reference |
| [elixir-workflows](./plugins/elixir-workflows/README.md) | 1 | Workflow-command generator |
| [portfolio-strategy](./plugins/portfolio-strategy) | 1 | Cross-repo power-law portfolio rule |

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/ZenHive/claude-marketplace-elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ZenHive/claude-marketplace-elixir/discussions)

## Attribution

This project is a fork of [claude-marketplace-elixir](https://github.com/bradleygolden/claude-marketplace-elixir), originally created by [Bradley Golden](https://github.com/bradleygolden).

---

**Made with care for the Elixir community**
