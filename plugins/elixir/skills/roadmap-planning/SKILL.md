---
name: roadmap-planning
description: Create prioritized roadmaps and task lists with D/B (Difficulty/Benefit) scoring. Use when planning features, organizing refactors, prioritizing backlogs, or structuring any multi-task work. Provides ROI-based ordering, phase organization, dependency tracking, and status markers.
allowed-tools: Read, Write
---

<!-- Auto-synced from ~/.claude/includes/task-prioritization.md — do not edit manually -->

## Task Prioritization Framework

### Scope: Roadmaps and Task Lists

D/B scoring, status markers, and parallel work markers apply to **ROADMAP.md and multi-task planning documents** — anywhere you're prioritizing across tasks for cross-instance coordination.

**Not for plan mode files:** Claude Code plan files (`/plan`) are single-task session blueprints. They don't need D/B scores, status markers, or the task-as-prompt format. See `task-writing.md` for the full distinction.

---

When creating any task list or TODO document, always include difficulty and benefit scores:

### Scoring Format
- **Format**: `[D:X/B:Y/U:Z → Eff:W]` where Eff = (B + U) / (2 × D)
- **Quick Scale**: Use 1-10 for Difficulty, Benefit, and Usefulness
- **Effective Priority Interpretation**:
  - Eff > 2.0: 🎯 Exceptional ROI - do immediately
  - Eff 1.5-2.0: 🚀 High ROI - do soon
  - Eff 1.0-1.5: 📋 Good ROI - plan carefully
  - Eff < 1.0: ⚠️ Poor ROI - reconsider or defer

### Benefit Scoring Guidelines (1-10)
- **10**: Transforms entire system/workflow
- **8-9**: Major improvement to core functionality
- **6-7**: Significant quality of life improvement
- **4-5**: Moderate improvement, nice to have
- **2-3**: Minor improvement, cosmetic
- **1**: Minimal impact

### Usefulness Scoring Guidelines (U: 1-10)

What U captures that B (Benefit) doesn't:
- **Unlock leverage** — how many downstream tasks does completing this unblock?
- **Query frequency** — how often do operators/agents ask the question this answers?
- **Gap visibility** — does this fill a known limitation that blocks daily workflows?

- **9-10**: Answers a daily question AND unblocks 3+ tasks
- **7-8**: Answers a common question OR unblocks 2+ tasks
- **5-6**: Useful but not frequently needed; moderate unlock
- **3-4**: Infrastructure/prerequisite with no direct user-facing value
- **1-2**: Pure hygiene; invisible to users

### Difficulty Scoring Guidelines (1-10)
- **10**: Requires architectural changes, multiple weeks
- **8-9**: Complex implementation, 1-2 weeks
- **6-7**: Significant work, 2-5 days
- **4-5**: Moderate complexity, 1-2 days
- **2-3**: Simple changes, few hours
- **1**: Trivial, under 1 hour

### Exclusions (Don't Score These)
- 🐛 Critical bugs - always highest priority
- 🔒 Security issues - always highest priority
- 📝 Documentation of completed work - just do it
- ✅ Tasks already in progress - finish them first

### Status Markers
- ⬜ Pending - not started
- 🔄 In progress - include branch name for parallel coordination (e.g., `🔄 fix/auth`)
- 🔶 Blocked/Paused - waiting on dependency
- ✅ Complete

### Parallel Work Markers
Mark independent tasks with `[P]` to indicate they can be worked on simultaneously:
```
| Task 79 `[P]` | ⬜ | Independent - can parallelize |
| Task 80 `[P]` | ⬜ | Independent - can parallelize |
| Task 81 | ⬜ | Depends on 79 - must wait |
```

**Before starting a `[P]` task:** Update status to 🔄 with branch name, commit to main, then create worktree.

### Task Descriptions as Prompts

Task descriptions should be **prompts for Claude Code to implement**, not implementation details:
- Describe WHAT to accomplish, not HOW to implement
- Let Claude Code research the codebase to determine specifics
- Avoid code examples in task lists (they become outdated)
- Include success criteria for verification

See `task-writing.md` for expanded guidance on writing effective task prompts.

### Example Task List
```
## Development Tasks
- [ ] Add WebSocket reconnection logic [D:3/B:9/U:9 → Eff:3.0] 🎯
      Implement automatic reconnection with exponential backoff when WebSocket drops. Include connection state tracking and user notification.

- [ ] Refactor parser modules [D:7/B:7/U:2 → Eff:0.64] ⚠️
      Consolidate duplicate parsing logic across the three parser modules into a shared behavior with module-specific implementations.

- [ ] Update color scheme [D:2/B:3/U:5 → Eff:2.0] 🎯
      Switch to the new brand colors in the design system. Update primary, secondary, and accent colors across all components.
```

This system helps focus on high-impact, low-effort wins first — and the U score ensures infrastructure-only tasks don't outrank features that users actually need.

### Roadmap Maintenance

Keep roadmaps focused on future work by archiving completed tasks:

**When completing a task — update ALL affected docs:**

1. **ROADMAP.md** — Mark status (⬜ → ✅), update phase summary, update "Current Focus" section
2. **CHANGELOG.md** — Add entry under `## [Unreleased]` with what was done and key decisions (create if needed)
3. **CLAUDE.md** — Update if repo structure, architecture, or conventions changed
4. **README.md** — Update if user-facing features or setup instructions changed
5. **Any project-specific tracking docs** (e.g., GO-INTEGRATION.md, DEX_ROADMAP.md) — Update if the task affected tracked work

A task without updated docs is an incomplete task.

**Archiving completed tasks in ROADMAP.md:**
1. Move full task details to CHANGELOG.md
2. Keep only a one-line reference in the roadmap phase section
3. Strike through in priority order lists

**ROADMAP.md structure (with Current Focus and phase summaries):**
```markdown
# Project Roadmap

**Vision:** One-sentence project vision.

**Completed work:** See [CHANGELOG.md](CHANGELOG.md) for finished tasks.

---

## 🎯 Current Focus

**Phase 2b: API Integration** — Currently fixing endpoint issues.

> **Philosophy reminder:** Key principle for consistency.

### ✅ Recently Completed
| Task | Description | Notes |
|------|-------------|-------|
| Task 23 | What was done | Key decisions |

### 📋 Current Tasks
| Task | Status | Notes |
|------|--------|-------|
| Task 25 🔄 `fix/auth` | In progress | Currently working |
| Task 26 `[P]` | ⬜ Pending | Available for parallel work |

### Quick Commands
```bash
mix test --failed --first-failure  # Iterate on failures
mix sync --all                      # Regenerate modules
```

---

## Phase 1: Foundation ✅

> 5 tasks complete. See [CHANGELOG.md](CHANGELOG.md#phase-1-foundation) for details.
> Built: Core infrastructure, signing patterns, HTTP client...

## Phase 2: Core Features

- [ ] Task 6: Add authentication [D:5/B:9/U:8 → Eff:1.7] 🚀
```

**No counts or stats in CHANGELOG/ROADMAP entries:**
- Do NOT include test counts (e.g., "14 tests: 4 unit + 10 integration")
- Do NOT list individual test names or categories
- Do NOT count functions, modules, or lines changed
- These numbers go stale immediately and burn tokens verifying/correcting them
- Describe *what* was built and *why*, not numeric inventories

**CHANGELOG.md structure (phase headers match anchors):**
```markdown
# Changelog

Completed roadmap tasks. For upcoming work, see [ROADMAP.md](ROADMAP.md).

---

## Phase 1: Foundation

### Task 1: Project Setup
**Completed** | [D:2/B:7/U:8 → Eff:3.75]

**What was done:**
- Summary of implementation
- Key decisions made
```

**Anchor naming:** Use kebab-case matching phase header: `#phase-1-foundation`

**Benefits:**
- One click from roadmap → detailed completion notes
- Bidirectional linking maintains context both ways
- Roadmap stays focused and scannable
- History preserved for reference
