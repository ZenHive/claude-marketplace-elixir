---
description: Print the six-phase development lifecycle reference — chain, phase ownership table, and handoff shape. Read-only — no mutations.
argument-hint: ""
allowed-tools: Read
---

Print the six-phase lifecycle reference for in-chat orientation. No branch-state introspection; this is a static reference, not a diagnostic.

**Output (terse, one screen):**

```
Six-Phase Development Lifecycle:
  task-driver(1) → worktree(2) → bots(3) → commit-review(4) → merge(5) → audit-review(6)
```

Then a phase ownership table:

| Phase | Skill / Actor | Trigger |
|---|---|---|
| 1. Plan-and-File | `task-driver:task-driver` (Plan-and-File mode) | User asks to plan new work |
| 2. Implement | implementer session + `staged-review:code-review` (pre-commit sub-phase) | Fresh session picks up the issue |
| 3. Bots | CodeRabbit / Copilot / Codex's GitHub bot | Async on PR open |
| 4. Pre-merge gate | `staged-review:commit-review` | After bots have run |
| 5. Merge | `commit-review` auto-merge tail OR user `gh pr merge` | ✅ verdict + 5 preconditions hold |
| 6. Post-merge audit | `staged-review:audit-review` | Auto-chains off merge |

Then a closing pointer:

> Full reference: `Skill(dev-lifecycle)`. Auto-merge preconditions: `delegation-rules.md`. Worktree scoping: `worktree-workflow.md`.

**Constraints:**
- Read-only. No `git`, no `gh`, no file writes.
- No branch detection, no "you're in phase N because..." — that's deferred to a future revision.
- Don't invoke any other skill or print phase deep-dives — point at `Skill(dev-lifecycle)` instead.
