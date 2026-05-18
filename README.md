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
4. **Merge** → GitHub-native `gh pr merge <N> --auto --squash --delete-branch` wired at PR-open; GitHub holds until required checks + no `requested-changes` + no `[BLOCK-MERGE]` label. See `plugins/staged-review/templates/auto-merge.md`
5. **Post-merge audit** → `staged-review:audit-review` (deferred — SessionStart hook surfaces unaudited tail at ≥3 threshold; user invokes `/staged-review:audit-status` or `Skill(audit-review) <range>`)

### Two-Tier Code Review Chain

The `staged-review` plugin covers pre-commit and post-merge with two sibling skills. Pre-merge is GitHub-native (`gh pr merge <N> --auto --squash --delete-branch` wired at PR-open; branch protection + `[BLOCK-MERGE]` label gate the merge — zero Claude/cloud-agent tokens). Same 5+1 categories across both skills; layers differ in **scope**, **reviewer count**, and **autonomy**:

| Layer | Skill | When | Scope | Reviewer |
|---|---|---|---|---|
| Pre-commit | `code-review` | `git diff --staged` | All 5+1 categories | Single (Claude) — fast triage with auto-apply |
| Pre-merge | _none — GH-native_ | PR open → CI + bots + branch protection | n/a — CI status checks + `[BLOCK-MERGE]` label gate | n/a — humans + bots via `[BLOCK-MERGE]` hold |
| Post-merge | `audit-review` | Deferred — SessionStart hook surfaces unaudited tail (≥3) / manual `Skill(audit-review) <range>` | All 5+1 categories + bot-finding triage + Linear close-out + acceptance-criteria verification | **Dual (Claude + mandatory parallel Codex) + bots as 3rd reasoner**, with Claude+Codex dialogue on `discuss-design` — fully autonomous |

The expensive dual-reviewer work (parallel Codex dispatch + Claude+Codex dialogue) lives only in `audit-review`. Pre-commit stays fast and single-reviewer. Every commit reaches the dual-reviewer pass eventually — the SessionStart hook flags accumulated tails, batched audit passes cover the range.

Implementer / reviewer separation is preserved across the chain: each layer is a different session, no agent grades its own work. See `plugins/staged-review/templates/auto-merge.md` for branch-protection + `[BLOCK-MERGE]` setup.

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
| [dev-lifecycle](./plugins/dev-lifecycle/README.md) | Canonical reference for the five-phase development lifecycle |

**Elixir/Phoenix plugins**:

| Plugin | Description |
|--------|-------------|
| [elixir](./plugins/elixir/README.md) | Main Elixir development - consolidated hooks (format, compile, credo, sobelow, dialyzer, etc.) + 24 skills |
| [phoenix](./plugins/phoenix/README.md) | Phoenix framework patterns — setup and Nexus template |
| [elixir-workflows](./plugins/elixir-workflows/README.md) | Workflow-command generator for other Elixir projects |

## Skills (40)

40 skills across 8 plugins. For the full **agent-facing catalog** — what each skill does and when to invoke it — see **[SKILLS.md](SKILLS.md)**.

| Plugin | Skills | Focus |
|--------|--------|-------|
| [elixir](./plugins/elixir/README.md) | 24 | Setup & tooling, research, testing, JS-on-BEAM, static analysis, API design |
| [cloud-delegation](./plugins/cloud-delegation/README.md) | 7 | Linear-as-queue + cloud-agent (Codex/Cursor) delegation chain |
| [staged-review](./plugins/staged-review/README.md) | 2 | Pre-commit + post-merge review chain (pre-merge is GH-native) |
| [phoenix](./plugins/phoenix/README.md) | 2 | Phoenix setup + Nexus admin template |
| [task-driver](./plugins/task-driver/README.md) | 2 | Roadmap-driven task execution + the `rmap` roadmap substrate |
| [dev-lifecycle](./plugins/dev-lifecycle/README.md) | 1 | Five-phase development lifecycle reference |
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
