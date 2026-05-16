---
name: dev-lifecycle
description: Use when explaining or orienting around the development lifecycle — answers "which phase am I in?", "which skill owns this?", "what's the handoff between phases?". Canonical reference for the six-phase chain (task-driver → worktree → bots → commit-review → merge → audit-review) that composes the task-driver, staged-review, and cloud-delegation plugins. Pure documentation — no actions taken.
allowed-tools: Read, Grep, Glob, Bash
---

<!-- Auto-synced from ~/.claude/includes/dev-lifecycle.md — do not edit manually -->

# Six-Phase Development Lifecycle

The `task-driver` + `staged-review` + `cloud-delegation` plugins compose into a six-phase lifecycle from task plan to merged-and-audited code. Same 5+1 category catalog across the three review layers; each phase has a single owning skill / actor:

```
task-driver(1) → worktree(2) → bots(3) → commit-review(4) → merge(5) → audit-review(6)
```

| Phase | Skill / Actor | When | Linear status on exit |
|---|---|---|---|
| 1. Plan-and-File | `task-driver` (Plan-and-File mode — plan → `ExitPlanMode` → `save_issue`) | User asks to plan new work | `Todo` |
| 2. Implement | implementer session in a worktree (per `worktree-workflow.md`) — pre-commit triage by `code-review` (sub-phase, `git diff --staged`) | Fresh session picks up the issue / task | `In Progress` (pickup) → `In Review` (PR open) |
| 3. Bots | external (CodeRabbit, Copilot, Codex's GitHub bot) | Async on PR open | (no transition) |
| 4. Pre-merge gate | `commit-review` — narrow Cat 1 + thin slice of Cat 6 (`@doc`/`@spec` drift) | After bots have run | `In Review` (verdict surfaced) |
| 5. Merge | `commit-review` auto-merge tail (when 5 preconditions hold) OR user manual `gh pr merge` | On ✅ verdict + green CI + feature branch + no requested-changes + no `[BLOCK-MERGE]` label | `Done` if Linear's native GH workflow rule is configured and fires; otherwise audit-review (Phase 6) confirms via `get_issue` and transitions explicitly |
| 6. Post-merge audit | `audit-review` — full 5+1 categories, mandatory parallel Codex, Claude+Codex dialogue on `discuss-design`, auto-applies hygiene fixes, writes `.audit/<sha>.md`, commits as `audit(...)` | Deferred — `staged-review` SessionStart hook surfaces unaudited tails (≥3 commits); user invokes `/staged-review:audit-status` or `Skill(audit-review) <range>` to batch-clear | `Done` (confirmed) |

**Reviewer cost-shape: dual-reviewer at the audit layer only.** The expensive parts of the review (parallel Codex dispatch with full tool-inventory payload, Claude+Codex dialogue resolution on judgment-call items) live exclusively in Phase 6 (`audit-review`). Phase 2 sub-phase (`code-review`) and Phase 4 (`commit-review`) stay fast and single-reviewer. Every merged commit reaches the dual-reviewer pass via Phase 6 when the user invokes it — batched over a range, the dual-reviewer cost amortizes across N merges instead of paying it N times.

**Linear is optional.** Projects without Linear use the ROADMAP-fallback flow: Phase 1 files an `rmap` task (`rmap new --from-stdin` into `roadmap/tasks.toml`) + `.thoughts/plans/<id>.md`; Phase 2–6 carry on identically; Linear-status columns above are skipped. The roadmap is rmap-backed in both modes — `roadmap/tasks.toml` canonical, `ROADMAP.md` rendered (see `rmap.md`). See `linear-queue.md` § "ROADMAP-Fallback Flow".

**Language-agnostic by design.** Every phase composes skills from the three already-language-agnostic plugins (`task-driver`, `staged-review`, `cloud-delegation`) plus the `worktree-workflow.md` include. No mix/cargo/npm-specific commands appear in the chain. Elixir-specific gates (`mix test.json`, `mix dialyzer.json`, pre-commit hooks) live in the `elixir` plugin and run alongside but are not part of the lifecycle itself.

## End-to-end flow for a typical feature task

1. **Phase 1** — User asks to plan something. `task-driver` enters Plan-and-File mode: research → draft plan → `EnterPlanMode` → on `ExitPlanMode` approval, `save_issue(status: Todo)` (or `rmap new` task if no Linear). Returns issue URL / rmap task id. **Stops.**
2. **Phase 2** — Fresh implementer session picks up the issue. Creates worktree under `~/_DATA/worktrees/<repo>/<id>/`. Implements. Stages with `git add`. **Pre-commit triage** (sub-phase): `code-review` reviews `git diff --staged` against all 5+1 categories — single-reviewer triage. On approval, commits. Pushes. Opens PR with `gh pr create`. (All git ops auto-allowed inside the tracked worktree per `worktree-workflow.md`.)
3. **Phase 3** — Bots (CodeRabbit, Copilot, Codex's GitHub bot) run async on PR open. No skill action; their findings are read by Phase 4.
4. **Phase 4** — `commit-review` runs the pre-merge correctness gate. Narrow scope (Cat 1 bugs + `@doc`/`@spec` drift). Two pickup modes: Linear-aware when MCP available, gh-only otherwise. Cite-and-skips bot findings. Auto-posts asymmetric push-back if blockers (line-level → PR; scope/intent → Linear).
5. **Phase 5** — On ✅ verdict + 5 preconditions (green CI, feature branch — not the repo's default, no requested-changes, no `[BLOCK-MERGE]` label), auto-merges via `gh pr merge --squash --delete-branch`. On any precondition fail, surfaces the verdict and stops; user merges manually. **Auto-merge applies to all feature-branch PRs** — worktree branches, `cursor/*`, `codex/*` all qualify.
6. **Phase 6** — `audit-review` runs deferred. The `staged-review` SessionStart hook surfaces unaudited tails (≥3 commits past the last `audit(...)` ancestor); user invokes `/staged-review:audit-status` for the snapshot or `Skill(audit-review) <range>` to batch-audit the range. Full 5+1, mandatory Codex, auto-resolves `discuss-design` via Claude+Codex dialogue. Writes one `.audit/<sha>.md` per commit. Commits as `audit(...)` on the default branch. Linear status confirms `Done`.

**Implementer / reviewer separation** is preserved across the chain: `task-driver` files plans but doesn't implement (handoff to fresh-session implementer), the implementer stages but `code-review` commits (handoff to fresh-session reviewer), `code-review` commits but `commit-review` merges (handoff to pre-merge gate), `commit-review` merges but `audit-review` bookkeeps post-merge in a separate user-invoked pass. Each phase is a different session — no agent grades its own work.

## Where each phase lives

| Phase | Skill |
|---|---|
| 1 — Plan-and-File | `task-driver:task-driver` (Plan-and-File mode) |
| 2 — Implement | implementer session + `staged-review:code-review` (pre-commit sub-phase) |
| 3 — Bots | external (CodeRabbit, Copilot, Codex's GitHub bot) |
| 4 — Pre-merge gate | `staged-review:commit-review` |
| 5 — Merge | `staged-review:commit-review` auto-merge tail OR user manual `gh pr merge` |
| 6 — Post-merge audit | `staged-review:audit-review` |

Worktree mechanics + git auto-allow scoping: `worktree-workflow.md`. Push-back posting matrix: `agent-pr-review.md` § "Push-Back-vs-Fix-Locally Matrix by Agent". Linear-status transitions: `linear-queue.md` § "Status Transitions". Auto-merge precondition rules: `delegation-rules.md` § "DON'T AUTO-MERGE PRS".
