# dev-lifecycle

Canonical, marketplace-discoverable reference for the **six-phase development lifecycle** that emerges from composing this marketplace's already-language-agnostic plugins.

```
task-driver(1) → worktree(2) → bots(3) → commit-review(4) → merge(5) → audit-review(6)
```

| Phase | Skill / Actor |
|---|---|
| 1. Plan-and-File | `task-driver:task-driver` (Plan-and-File mode) |
| 2. Implement | implementer session + `staged-review:code-review` (pre-commit sub-phase) |
| 3. Bots | CodeRabbit / Copilot / Codex's GitHub bot |
| 4. Pre-merge gate | `staged-review:commit-review` |
| 5. Merge | `commit-review` auto-merge tail OR user `gh pr merge` |
| 6. Post-merge audit | `staged-review:audit-review` |

## What's in this plugin

**One skill:** `dev-lifecycle:dev-lifecycle` — the canonical chain reference. Read it when you want to know which phase you're in, which skill owns it, or what the handoff to the next phase looks like.

**One slash command:** `/dev-lifecycle:dev-lifecycle` — terse in-chat printer of the phase table and ownership map. Useful when you need a one-screen reminder without opening the skill.

No hooks, no agents, no automation. This plugin is **pure documentation/orchestration** — it names and points at the chain that already exists; it doesn't add new behavior.

## What it composes (not bundled — referenced by name)

- [`task-driver`](../task-driver/) — Phase 1 (Plan-and-File) and the general task-pickup loop
- [`staged-review`](../staged-review/) — Phase 2 sub-phase (`code-review`), Phase 4 (`commit-review`), Phase 6 (`audit-review`)
- [`cloud-delegation`](../cloud-delegation/) — Linear-as-queue mechanics consumed by Phases 1, 2, 4, 5, 6
- `~/.claude/includes/worktree-workflow.md` — Phase 2 worktree mechanics + git auto-allow scoping

This plugin does **not** depend on or reference the `elixir` / `phoenix` / `code-quality` plugins. The chain is language-agnostic by design.

## Install

```
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install dev-lifecycle@deltahedge
```

## Source

The skill body is auto-synced from `~/.claude/includes/dev-lifecycle.md` via `scripts/sync-skills-from-includes.sh`. Edit the include, run the sync script, commit both. Do not hand-edit `skills/dev-lifecycle/SKILL.md` — it gets overwritten.
