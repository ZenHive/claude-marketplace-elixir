---
name: task-driver
description: Use when starting a work session, picking tasks from a roadmap, or implementing roadmap items. Reads ROADMAP.md, selects tasks by D/B efficiency, implements with TodoWrite tracking, adds TODO(Task N) markers for discovered work, and updates all project docs (ROADMAP, CHANGELOG, CLAUDE.md, README). Language-agnostic.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, MultiEdit, TaskCreate, TaskUpdate, EnterPlanMode, ExitPlanMode
---

# Task Driver — Roadmap-Driven Implementation

Read the roadmap. Pick the best tasks. Implement. Update all docs. Leave no gaps.

## Scope

WHAT THIS SKILL DOES:
  - Select tasks from ROADMAP.md by efficiency score (lightweight shortlist, no plan mode)
  - Enter plan mode AFTER a task is selected, to design the implementation
  - Implement approved tasks with TodoWrite progress tracking
  - Add `TODO(Task N):` markers in code for discovered work
  - Update ALL affected *.md files after implementation
  - Add newly discovered tasks to ROADMAP.md with D/B scores

WHAT THIS SKILL DOES NOT DO:
  - Create roadmaps from scratch (use roadmap-planning skill for format guidance)
  - Code review (use staged-review:code-review)
  - Language-specific checks (use project linters and hooks)

## Workflow

```dot
digraph task_driver {
  rankdir=TB;
  node [shape=box];

  read     [label="1. Read ROADMAP.md\n+ linked docs"];
  shortlist[label="2. Present scored shortlist\n(plain text — NOT plan mode)"];
  select   [label="3. User picks task(s)"];
  plan     [label="4. Enter plan mode\nDesign the implementation"];
  exit     [label="5. ExitPlanMode\nMark 🔄 + TodoWrite"];
  implement[label="6. Implement"];
  todos    [label="7. Add TODO(Task N) markers\nfor discovered work"];
  docs     [label="8. Update all *.md files"];
  discover [label="9. Add new tasks\nto ROADMAP.md"];

  read -> shortlist -> select -> plan -> exit -> implement -> todos -> docs -> discover;
}
```

**Why two stages:** selection is a scored-table menu — cheap, plain text. Plan mode is where design decisions earn approval (files to touch, schema shape, trade-offs). Fusing them forces plan-mode ceremony just to read a sorted list.

### Step 1: Read the Roadmap

Read `ROADMAP.md` and any linked planning docs (e.g., `GO-INTEGRATION.md`, `DEX_ROADMAP.md`).

Identify:
- All pending tasks (⬜) with their D/B/U scores
- Blocked tasks (🔶) and what blocks them
- In-progress tasks (🔄) and their branches
- Parallel-safe tasks marked with `[P]`
- Current phase and focus area

### Step 2: Present Scored Shortlist (no plan mode)

Output the top candidates as plain text — this is a menu, not a design review. Do **not** call `EnterPlanMode` here.

```
## Recommended Tasks

| # | Task | Eff  | D/B/U       | Status | Notes                    |
|---|------|------|-------------|--------|--------------------------|
| 1 | 274  | 3.00 | D:3/B:9/U:9 | ⬜     | Independent, high ROI    |
| 2 | 290  | 1.75 | D:2/B:4/U:3 | ⬜     | Quick win, low effort    |
| 3 | 285  | 1.50 | D:4/B:6/U:6 | 🔶     | Blocked by Task 274      |

## Parallel Opportunities
Tasks 274 and 290 are independent — can run in parallel worktrees.

## Blocked Tasks
Task 285 depends on 274 completing first.
```

End with a one-line recommendation: "I suggest Task 274 (highest efficiency, unblocked). Which do you want?"

### Step 3: User Picks Task(s)

Wait for the user to pick. Do NOT proceed without approval.

### Step 4: Enter Plan Mode — Design the Implementation

**Now** call `EnterPlanMode`, scoped to the selected task. Inside plan mode:

- Read the task description and any linked docs (SCHEMA.md, CONSUMER_CONTRACT.md, etc.)
- Explore the codebase (existing patterns, modules to touch, tests that cover the area)
- Identify reuse opportunities — don't propose new code when a helper exists
- Produce a concrete plan: files to modify, new modules, schema/contract changes, verification steps

**Delegate the codebase survey to an Explore subagent** when the task needs more than ~3 searches across the repo. Keep design synthesis in the main session; push raw Grep/Glob work to Explore so it returns a compact report (file:line pairs, brief findings) instead of dumping 100+ raw matches into main context. Common trigger: a schema/contract bump that touches dozens of filename or version-string references — let Explore enumerate the call-sites, then build the plan from its summary.

Exit plan mode with `ExitPlanMode` when the plan is ready for user approval.

**Trivial task exception:** if the selected task is a one-line fix, a pure doc update, or otherwise has zero design decisions, skip plan mode and go straight to Step 5. When in doubt, plan.

### Step 5: Create TodoWrite Items + Mark 🔄

After the plan is approved, create TodoWrite items:

```
- [ ] Implement core changes
- [ ] Add tests
- [ ] Run quality checks
- [ ] Update ROADMAP.md, CHANGELOG.md
- [ ] Update CLAUDE.md/README.md if needed
```

Mark the task as 🔄 in ROADMAP.md with your branch name before the first code change.

### Step 6: Implement

Implement the task. Follow project conventions from CLAUDE.md.

Use the task description as a prompt — it describes WHAT to accomplish, not HOW. Research the codebase to determine specifics.

### Step 7: Add TODO Markers for Discovered Work

During implementation you WILL discover things that aren't the current task:
- Edge cases the current fix doesn't address
- Missing test coverage spotted during implementation
- Upstream issues from external dependencies
- Architectural improvements noticed along the way

**Every discovery gets a tracked marker:**

```elixir
# TODO(Task 295): Handle rate limiting for batch requests — discovered during Task 274
```

- Use `TODO(Task N):` format where N is a new task number
- If it's an upstream issue, use `FIXME(upstream):` instead (see staged-review skill)
- Include which task you were working on when you found it

### Step 8: Update All Documentation

**This is not optional. A task without updated docs is an incomplete task.**

Check and update whichever of these are affected:

**ROADMAP.md:**
- Mark completed task: ⬜ → ✅
- Update phase summary if phase completed
- Update "Current Focus" section
- No counts or stats (they go stale)

**CHANGELOG.md:**
- Add entry under `## [Unreleased]`
- Describe what was done and key decisions
- No test counts, function counts, or line counts

**CLAUDE.md:**
- Update if repo structure, architecture, or conventions changed
- Update skill/plugin tables if applicable

**README.md:**
- Update if user-facing features or setup instructions changed

### Step 9: Add Discovered Tasks to Roadmap

All `TODO(Task N)` markers you added in Step 7 need corresponding entries in ROADMAP.md:

```markdown
- [ ] Task 295: Handle rate limiting for batch requests [D:3/B:6/U:5 → Eff:1.83] 🚀
      Add rate limiting awareness to batch endpoint calls. Discovered during Task 274 — batch requests can hit exchange rate limits without backoff.
```

- Score every new task with D/B/U
- Write task descriptions as prompts (WHAT, not HOW)
- Mark parallel-safe tasks with `[P]`
- Flag dependencies on other tasks

## Task Selection Criteria

When choosing which tasks to recommend:

1. **Highest efficiency first** — Eff > 2.0 before Eff < 1.0
2. **Unblocked only** — skip tasks with unmet dependencies
3. **Respect current phase** — prefer tasks in the active phase
4. **Parallel opportunities** — flag independent `[P]` tasks that could run in worktrees
5. **Critical bugs always first** — regardless of D/B score

**Skip these in scoring:**
- Critical bugs (always highest priority)
- Security issues (always highest priority)
- Documentation of completed work (just do it)
- Tasks already in progress by another session

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Entering plan mode just to show the shortlist | Step 2 is plain text; plan mode is Step 4, after selection |
| Implementing without plan-mode approval for the selected task | Non-trivial tasks get plan mode in Step 4 before any code change |
| Skipping doc updates | Every task updates ROADMAP + CHANGELOG at minimum |
| Discovering work without tracking it | Every discovery gets TODO(Task N) + ROADMAP entry |
| Writing implementation details in task descriptions | Tasks are prompts: WHAT not HOW |
| Adding counts/stats to CHANGELOG | Describe what was built, not numeric inventories |
| Starting blocked tasks | Check dependencies before recommending |
| Forgetting to mark task as 🔄 before starting | Update ROADMAP status before first code change |
