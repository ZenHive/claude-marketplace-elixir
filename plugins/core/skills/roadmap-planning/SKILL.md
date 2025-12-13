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

### Acceptance criteria

Include clear completion criteria for each task:

```markdown
### Task: Add user authentication [D:5/B:9 → Priority:1.8] 🚀

**Goal:** Implement secure user login and session management

**Acceptance criteria:**
- [ ] User can register with email/password
- [ ] User can log in and receive session token
- [ ] Protected routes require valid session
- [ ] Passwords hashed with bcrypt
- [ ] Tests cover happy path and error cases

**Files to create/modify:**
- `lib/myapp/accounts.ex` - Account context
- `lib/myapp_web/controllers/session_controller.ex` - Login/logout
- `test/myapp/accounts_test.exs` - Unit tests
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
