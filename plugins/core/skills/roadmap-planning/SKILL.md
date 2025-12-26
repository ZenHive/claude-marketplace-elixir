---
name: roadmap-planning
description: Create prioritized task lists and roadmaps with D/B (Difficulty/Benefit) scoring. Use when planning features, refactors, or any multi-task work. Provides ROI-based prioritization, phase organization, and dependency tracking.
allowed-tools: Read, Write
---

# Roadmap Planning with D/B Scoring

Create prioritized task lists and roadmaps using Difficulty/Benefit scoring. This framework helps prioritize work by ROI (Return on Investment), ensuring high-impact, low-effort tasks are done first.

## When to use this skill

Use this skill when:
- Planning a feature implementation with multiple tasks
- Creating a refactor roadmap
- Organizing a backlog of work items
- Prioritizing bug fixes or improvements
- Breaking down large projects into phases
- Helping users decide what to work on first

## D/B Scoring Format

Every task should include a D/B score in this format:

```
[D:X/B:Y → Priority:Z]
```

Where:
- **D** = Difficulty (1-10)
- **B** = Benefit (1-10)
- **Priority** = B / D (higher is better ROI)

### Example tasks with scores

```markdown
- [ ] Add WebSocket reconnection logic [D:3/B:9 → Priority:3.0]
- [ ] Refactor parser modules [D:7/B:7 → Priority:1.0]
- [ ] Update color scheme [D:2/B:3 → Priority:1.5]
- [ ] Rewrite entire auth system [D:9/B:8 → Priority:0.89]
```

## Priority Indicators

Add visual indicators based on Priority score:

| Priority Range | Indicator | Meaning |
|----------------|-----------|---------|
| > 2.0 | 🎯 | Exceptional ROI - do immediately |
| 1.5 - 2.0 | 🚀 | High ROI - do soon |
| 1.0 - 1.5 | 📋 | Good ROI - plan carefully |
| < 1.0 | ⚠️ | Poor ROI - reconsider or defer |

### Example with indicators

```markdown
## Development Tasks

- [ ] Add caching layer [D:2/B:8 → Priority:4.0] 🎯
- [ ] Implement retry logic [D:3/B:7 → Priority:2.33] 🎯
- [ ] Add dark mode [D:4/B:6 → Priority:1.5] 🚀
- [ ] Refactor database layer [D:8/B:9 → Priority:1.13] 📋
- [ ] Complete rewrite [D:10/B:7 → Priority:0.7] ⚠️
```

## Difficulty Scoring Guidelines (1-10)

| Score | Description | Time Estimate |
|-------|-------------|---------------|
| 1 | Trivial - config change, typo fix | < 1 hour |
| 2-3 | Simple - single file, clear path | Few hours |
| 4-5 | Moderate - multiple files, some complexity | 1-2 days |
| 6-7 | Significant - cross-cutting, requires research | 2-5 days |
| 8-9 | Complex - architectural changes, unknowns | 1-2 weeks |
| 10 | Major - full rewrites, fundamental changes | Multiple weeks |

### Factors that increase difficulty

- Multiple file changes
- Cross-cutting concerns
- External dependencies
- Testing complexity
- Documentation needs
- Migration requirements
- Unknown territory
- Coordination with others

## Benefit Scoring Guidelines (1-10)

| Score | Description | Impact |
|-------|-------------|--------|
| 1 | Minimal - cosmetic, personal preference | Barely noticeable |
| 2-3 | Minor - small improvement, edge case | Nice to have |
| 4-5 | Moderate - quality of life, cleanup | Noticeable improvement |
| 6-7 | Significant - user-facing improvement | Clear value |
| 8-9 | Major - core functionality, big impact | Substantial value |
| 10 | Transformative - enables new capabilities | Game changer |

### Factors that increase benefit

- User-facing improvement
- Performance gains
- Developer experience
- Security enhancement
- Reliability improvement
- Enables other work
- Reduces technical debt
- Addresses user feedback

## What NOT to Score

Some items bypass the scoring system entirely:

| Category | Reason | Action |
|----------|--------|--------|
| Critical bugs | Always highest priority | Fix immediately |
| Security issues | Always highest priority | Fix immediately |
| Documentation of completed work | Minimal effort, required | Just do it |
| Tasks already in progress | Sunk cost, need completion | Finish them first |
| Blocked tasks | Can't start anyway | Mark as blocked |

### Example exclusions

```markdown
## Critical (No Scoring)

- [x] Fix SQL injection in login form (SECURITY)
- [ ] Fix data loss on concurrent saves (CRITICAL BUG)

## In Progress (Finish First)

- [ ] Complete authentication refactor (80% done)

## Blocked

- [ ] Integrate payment API (waiting on vendor credentials)

## Scored Tasks

- [ ] Add search feature [D:5/B:8 → Priority:1.6] 🚀
```

## Task Structure Patterns

### Phase-based organization

Group related tasks into phases with clear dependencies:

```markdown
## Phase 1: Foundation

Prerequisites: None

- [ ] Set up project structure [D:2/B:7 → Priority:3.5] 🎯
- [ ] Configure CI/CD pipeline [D:3/B:8 → Priority:2.67] 🎯
- [ ] Add core dependencies [D:1/B:6 → Priority:6.0] 🎯

## Phase 2: Core Features

Prerequisites: Phase 1 complete

- [ ] Implement user authentication [D:5/B:9 → Priority:1.8] 🚀
- [ ] Build API endpoints [D:6/B:8 → Priority:1.33] 📋
- [ ] Add database migrations [D:4/B:7 → Priority:1.75] 🚀

## Phase 3: Polish

Prerequisites: Phase 2 complete

- [ ] Add error handling [D:3/B:6 → Priority:2.0] 🚀
- [ ] Improve logging [D:2/B:5 → Priority:2.5] 🎯
- [ ] Write documentation [D:4/B:6 → Priority:1.5] 🚀
```

### Task descriptions as prompts

**Critical**: Task descriptions should be **prompts for Claude Code to implement**, not implementation details themselves.

**Why prompts, not details:**
- Claude Code will research the codebase and determine implementation specifics
- Over-specified tasks become outdated as code evolves
- Prompts allow Claude Code to adapt to current patterns
- Details in plans often conflict with actual codebase state

**Bad** - Too much implementation detail:
```
Task: Add user authentication [D:5/B:9 → Priority:1.8]

Files: lib/myapp/accounts.ex, lib/myapp_web/controllers/session_controller.ex
Implementation: [code showing exact module structure, function bodies, etc.]
```

**Good** - Prompt for Claude Code:
```
Task: Add user authentication [D:5/B:9 → Priority:1.8]

Add email/password authentication with session tokens. Users should be able to register, log in, and access protected routes. Hash passwords with bcrypt. Include tests for registration, login success, and login failure cases.
```

The task description IS the prompt that Claude Code will execute. It should describe WHAT to accomplish, not HOW to implement it.

### Avoid unverified claims

**Never include specific numbers or statistics that haven't been verified at execution time.**

**Why:**
- Specific numbers (86/110, "all 109") become outdated immediately
- Claims may be fabricated or miscounted
- Claude Code should verify current state at execution time
- Prompts remain valid even as codebase evolves

**Bad** - Makes specific claims that may not be verified:
```
Task: Add semantic endpoints [D:5/B:8]

86/110 exchanges have semantic endpoints. Update remaining 24.
Impact: "2/110 → 86/110"
```

**Good** - Describes what to accomplish, lets Claude verify:
```
Task: Add semantic endpoints [D:5/B:8]

Identify exchanges missing semantic endpoints and add them.
Prioritize high-volume exchanges first.
```

If you need to track progress, use success criteria with checkboxes rather than claiming specific numbers in the task description.

### Success criteria

Include verifiable completion criteria when needed:

```
Task: Add user authentication [D:5/B:9 → Priority:1.8]

Add email/password authentication with session tokens. Users should be able to register, log in, and access protected routes. Hash passwords with bcrypt.

Success criteria:
- [ ] User can register with email/password
- [ ] User can log in and receive session token
- [ ] Protected routes require valid session
- [ ] Tests cover happy path and error cases
```

### Dependency tracking

Show task dependencies explicitly:

```markdown
## Task Dependencies

```
Task A (no deps)
    |
    v
Task B (depends on A)
    |
    +---> Task C (depends on B)
    |
    +---> Task D (depends on B)
              |
              v
          Task E (depends on D)
```

## Execution Order by ROI

Sort tasks by Priority score (descending) within each phase:

```markdown
## Execution Order

| Priority | Task | Phase |
|----------|------|-------|
| 🎯 6.0 | Add core dependencies | 1 |
| 🎯 3.5 | Set up project structure | 1 |
| 🎯 2.67 | Configure CI/CD | 1 |
| 🎯 2.5 | Improve logging | 3 |
| 🚀 2.0 | Add error handling | 3 |
| 🚀 1.8 | User authentication | 2 |
| 🚀 1.75 | Database migrations | 2 |
| 🚀 1.5 | Write documentation | 3 |
| 📋 1.33 | Build API endpoints | 2 |

**Critical path:** Phase 1 → Phase 2 (auth → API) → Phase 3
```

### Tiebreaker rules

When priorities are equal:
1. **Enables other work** - Do tasks that unblock others first
2. **Lower difficulty** - Prefer easier tasks (quicker wins)
3. **Earlier phase** - Complete prerequisites first
4. **User-facing** - Prefer visible improvements

## Roadmap Template

Use this template for new roadmaps:

```markdown
# [Project Name] Roadmap

## Summary

| Phase | Tasks | Status | Focus |
|-------|-------|--------|-------|
| 1. Foundation | 3 | 0/3 | Setup and configuration |
| 2. Core | 4 | 0/4 | Main functionality |
| 3. Polish | 3 | 0/3 | Quality and docs |

**Total: X tasks (Y complete, Z remaining)**

---

## Critical (No Scoring)

- [ ] [Any critical bugs or security issues]

---

## Phase 1: Foundation

Prerequisites: None

- [ ] Task 1 [D:X/B:Y → Priority:Z] Indicator
- [ ] Task 2 [D:X/B:Y → Priority:Z] Indicator

---

## Phase 2: Core

Prerequisites: Phase 1 complete

- [ ] Task 3 [D:X/B:Y → Priority:Z] Indicator
- [ ] Task 4 [D:X/B:Y → Priority:Z] Indicator

---

## Phase 3: Polish

Prerequisites: Phase 2 complete

- [ ] Task 5 [D:X/B:Y → Priority:Z] Indicator

---

## Execution Order (by ROI)

| Priority | Task | Phase |
|----------|------|-------|
| ... | ... | ... |

---

## Dependency Graph

```
Phase 1 → Phase 2 → Phase 3
```

---

## Non-Goals (Out of Scope)

- [Items explicitly not included]

---

## Decisions Made

| Question | Decision |
|----------|----------|
| ... | ... |
```

## Roadmap Maintenance

When completing a task, follow these steps to keep the roadmap clean and maintainable:

### Step 1: Move full task details to CHANGELOG.md

Move the complete task description, implementation notes, and any learnings to `CHANGELOG.md`:

```markdown
## [Unreleased]

### Added
- User authentication with email/password [D:5/B:9 → Priority:1.8]
  - Created User schema with hashed passwords
  - Added Accounts context with register/authenticate functions
  - Guardian integration for JWT tokens
```

### Step 2: Update the Summary table

Change the task status indicator from incomplete to complete:

```markdown
| Phase | Tasks | Status | Focus |
|-------|-------|--------|-------|
| 1. Foundation | 3 | ⬜⬜⬜ → ✅✅✅ | Setup |
| 2. Core | 4 | ⬜⬜⬜⬜ → ✅⬜⬜⬜ | Features |
```

### Step 3: Update the Priority Order section

Strike through completed tasks in the execution order:

```markdown
## Execution Order (by ROI)

| Priority | Task | Phase |
|----------|------|-------|
| ~~🎯 6.0~~ | ~~Add core dependencies~~ | ~~1~~ |
| 🎯 3.5 | Set up project structure | 1 |
| ~~🎯 2.67~~ | ~~Configure CI/CD~~ | ~~1~~ |
```

### Step 4: Keep one-line reference in phase section

Replace the detailed task description with a brief completion note:

**Before:**
```markdown
### Phase 1: Foundation

- [ ] Set up project structure [D:2/B:7 → Priority:3.5] 🎯
      Create standard Elixir project layout with mix.exs, config/, lib/,
      and test/ directories. Configure umbrella if multi-app architecture.
```

**After:**
```markdown
### Phase 1: Foundation

- [x] Set up project structure [D:2/B:7 → Priority:3.5] 🎯 — Done, see CHANGELOG
- [ ] Configure CI/CD pipeline [D:3/B:8 → Priority:2.67] 🎯
```

### Avoid stale metrics in completion notes

When documenting completed work (in CHANGELOG or roadmap notes), avoid specific counts or percentages that become stale:

**Bad** - Specific numbers become outdated:
```markdown
- [x] Extract API specs — Done: 110 specs, 100% success rate
- [x] Add semantic endpoints — Impact: 2/110 → 86/110
```

**Good** - Generic or verifiable:
```markdown
- [x] Extract API specs — Done, see CHANGELOG
- [x] Add semantic endpoints — Run `mix count_endpoints` to verify
```

Completion reports are accurate when written, but if they stay in the roadmap they become misleading. Either move details to CHANGELOG (where staleness is expected for historical records) or use commands that verify current state.

### Why this pattern?

- **CHANGELOG becomes the source of truth** for completed work
- **Roadmap stays scannable** without completed task clutter
- **Priority Order shows progress** at a glance
- **Summary table provides quick status** overview
- **Cross-referencing** connects roadmap to historical record

## Best practices

### Keep scores honest

- Don't inflate benefits to justify pet projects
- Don't deflate difficulty to make tasks seem easier
- Re-evaluate scores as you learn more
- Get team input on scoring if possible

### Review and adjust

- Update scores as context changes
- Mark completed tasks immediately
- Remove irrelevant tasks entirely
- Add new tasks as discovered

### Communicate clearly

- Use consistent formatting
- Include acceptance criteria
- Show dependencies explicitly
- Keep summary tables updated

### Focus on ROI

- Start with highest priority tasks
- Don't get distracted by low-ROI work
- Question tasks with Priority < 1.0
- Celebrate high-ROI completions

## Quick reference

| Concept | Format |
|---------|--------|
| Score format | `[D:X/B:Y → Priority:Z]` |
| Priority calculation | Priority = Benefit / Difficulty |
| Exceptional ROI | Priority > 2.0 (🎯) |
| High ROI | Priority 1.5-2.0 (🚀) |
| Good ROI | Priority 1.0-1.5 (📋) |
| Poor ROI | Priority < 1.0 (⚠️) |
| Difficulty scale | 1 (trivial) to 10 (major) |
| Benefit scale | 1 (minimal) to 10 (transformative) |
| Task completion | Move to CHANGELOG → Update Summary ✅ → Strike Priority Order → One-line in phase |
