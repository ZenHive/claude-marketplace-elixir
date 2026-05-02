---
name: roadmap-planning
description: Create prioritized roadmaps and task lists with D/B (Difficulty/Benefit) scoring. Use when planning features, organizing refactors, prioritizing backlogs, or structuring any multi-task work. Provides ROI-based ordering, phase organization, dependency tracking, and status markers.
allowed-tools: Read, Write
---

<!-- Auto-synced from ~/.claude/includes/task-prioritization.md — do not edit manually -->

## Task Prioritization Framework

### Scope

D/B/U scoring, status markers, and `[P]` markers apply to **ROADMAP.md and multi-task planning docs** — cross-instance coordination. **Not for `/plan` files** (single-task session blueprints). See `task-writing.md`.

### Scoring Format

`[D:X/B:Y/U:Z → Eff:W]` where `Eff = (B + U) / (2 × D)`. Scales are 1–10.

| Eff | Tier |
|-----|------|
| > 2.0 | 🎯 Exceptional ROI — do immediately |
| 1.5–2.0 | 🚀 High ROI — do soon |
| 1.0–1.5 | 📋 Good ROI — plan carefully |
| < 1.0 | ⚠️ Poor ROI — reconsider or defer |

### Scale (D / B / U)

| Value | Difficulty | Benefit | Usefulness |
|-------|------------|---------|------------|
| 1 | < 1hr, trivial | Minimal impact | Pure hygiene, invisible |
| 3 | Few hours | Minor/cosmetic | Infrastructure only |
| 5 | 1–2 days | Nice to have | Moderate unlock |
| 7 | 2–5 days | Significant QoL | Common question OR unblocks 2+ tasks |
| 9 | 1–2 weeks | Major improvement | Daily question AND unblocks 3+ tasks |
| 10 | Weeks, architectural | Transforms system | — |

**U vs B:** U captures unlock leverage, query frequency, and gap visibility. B captures impact magnitude. Infrastructure-only tasks score high D/B but low U — U prevents them from crowding out user-facing features.

### Exclusions (don't score)

🐛 bugs, 🔒 security, 📝 docs of completed work, ✅ in-progress tasks — always highest priority.

### Status Markers

- ⬜ Pending
- 🔄 In progress — include branch name (`🔄 fix/auth`)
- 🔶 Blocked/Paused
- ✅ Complete

### Pre-Implementation Gate

Before starting a code-mutating task on an existing module, confirm the module's coverage is at tier:

- ≥80% for standard business logic
- ≥95% for critical business logic (signing, money handling, cryptographic ops, low-level encoders)

If below, raising coverage is **part of this task** — not a follow-up to defer. See `critical-rules.md` § "RAISE COVERAGE BEFORE MUTATING" for scope guards (trivial doc/format/rename mutations are exempt) and the `mix test.json --cover` workflow.

### Parallel Work (`[P]`)

Mark independent tasks with `[P]`. Before starting: update status to 🔄 with branch name, commit to main, create worktree.

```
| Task 79 `[P]` | ⬜ | Independent |
| Task 80 `[P]` | ⬜ | Independent |
| Task 81 | ⬜ | Depends on 79 |
```

### Codex Delegation (`[CX]`)

Mark tasks suitable for delegation to Codex with `[CX]`. **Default: tasks meeting all criteria below are `[CX]` unless there's a stated reason otherwise.** Claude's bias is to grab work; this default is a counterweight.

**Criteria (all must be true):**
- Self-contained — single module or feature, no orchestration with other in-flight work
- No Tidewave / live-data exploration required (Codex has no internet — no Tidewave, no live-app exploration)
- No hex-docs lookup required for niche or version-pinned third-party APIs (Codex has no hex.pm access — it can't verify signatures of `assert_receive/3` vs `assert_received/2`-class macros, version-bumped libraries, or anything outside reliable training coverage)
- No dependency changes (`mix.exs`, lockfile)
- No `.mcp.json`, hooks, or CI changes
- Spec is fully captured in the Linear issue body — no live clarifications mid-flight

**Workflow:**
1. Create Linear issue with `delegate: "Codex"` and label `cx-eligible`. Body is the prompt — full spec, acceptance criteria, file paths.
2. Codex picks it up, opens PR, transitions issue to `In Review`.
3. Local Claude Code session invokes `staged-review:commit-review` to fetch and review the PR.
4. Claude Code surfaces "ready to merge" but the **user** merges (see `critical-rules.md` § "DON'T AUTO-MERGE PRS").

```
| Task 79 `[P]`  | ⬜              | Independent, local       |
| Task 80 `[CX]` | ⬜              | Delegate to Codex        |
| Task 81 `[CX]` | 🔄 in-review   | Codex PR open, awaiting review |
```

### Task Descriptions as Prompts

Task descriptions should be prompts for Claude Code (WHAT to accomplish), not implementation specs (HOW). Let Claude research the codebase. Avoid code examples (they rot). Include success criteria. See `task-writing.md` for detail.

### Example

```
- [ ] Add WebSocket reconnection [D:3/B:9/U:9 → Eff:3.0] 🎯
      Implement automatic reconnection with exponential backoff. Include connection state tracking.

- [ ] Refactor parser modules [D:7/B:7/U:2 → Eff:0.64] ⚠️
      Consolidate duplicate parsing logic into a shared behavior.
```

### Roadmap Maintenance

**When completing a task — update ALL affected docs:**

1. **ROADMAP.md** — Mark ⬜ → ✅, update phase summary, update Current Focus
2. **CHANGELOG.md** — Add entry under `## [Unreleased]` with what + key decisions
3. **CLAUDE.md** — If repo structure/architecture/conventions changed
4. **README.md** — If user-facing features or setup changed
5. **Project-specific tracking docs** — If the task affected tracked work

A task without updated docs is incomplete.

**Archive completed tasks:** move full details to CHANGELOG.md, keep one-line reference in ROADMAP.md phase section, strike through in priority lists.

**ROADMAP structure:**
```markdown
# Project Roadmap
**Vision:** One-sentence.
**Completed work:** See [CHANGELOG.md](CHANGELOG.md).

## 🎯 Current Focus
**Phase 2b: API Integration** — Fixing endpoint issues.

### 📋 Current Tasks
| Task | Status | Notes |
| Task 25 🔄 `fix/auth` | In progress | — |
| Task 26 `[P]` | ⬜ Pending | Available for parallel |

## Phase 1: Foundation ✅
> 5 tasks. See [CHANGELOG.md](CHANGELOG.md#phase-1-foundation).

## Phase 2: Core Features
- [ ] Task 6: Add authentication [D:5/B:9/U:8 → Eff:1.7] 🚀
```

**CHANGELOG structure (anchors match phase headers):**
```markdown
## Phase 1: Foundation
### Task 1: Project Setup
**Completed** | [D:2/B:7/U:8 → Eff:3.75]
**What was done:**
- Summary of implementation
- Key decisions
```

Anchor naming: kebab-case (`#phase-1-foundation`).

**No counts or stats in entries:** no test counts, function counts, lines-changed tallies, or individual test names. Numbers rot and burn tokens. Describe *what* was built and *why*.
