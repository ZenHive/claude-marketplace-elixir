---
name: git-worktrees
description: Run multiple Claude Code sessions in parallel using git worktrees. Use when working on multiple features/tasks simultaneously, running parallel refactors, or isolating experimental work. Prevents Claude sessions from conflicting.
allowed-tools: Bash, Read
---

# Git Worktrees for Parallel Claude Code Sessions

Git worktrees allow you to check out multiple branches of the same repository simultaneously, each in its own directory. This is essential for running multiple Claude Code sessions in parallel without conflicts.

## When to use this skill

Use this skill when you need to:
- Run multiple Claude Code sessions on different features
- Work on parallel refactor phases
- Isolate experimental changes from stable work
- Have multiple ongoing conversations without conflicts
- Speed up development by parallelizing independent tasks

## What are git worktrees?

Git worktrees let you check out multiple branches of the same repository simultaneously, each in its own directory.

**Key benefits:**
- **Shared repository database** - Unlike cloning multiple times, worktrees share a single `.git` directory (saves disk space)
- **Complete isolation** - Each worktree has its own working directory, so changes don't conflict
- **Branch protection** - Git prevents you from checking out the same branch in multiple worktrees
- **Single source of truth** - All worktrees point to the same repository

```
main repo (~/projects/myapp)
    ├── .git/                    # Shared git database
    ├── worktrees/
    │   ├── feature-a/           # Worktree 1: feature-a branch
    │   ├── feature-b/           # Worktree 2: feature-b branch
    │   └── bugfix-c/            # Worktree 3: bugfix-c branch
    └── (main branch files)
```

## Basic commands

### Create a worktree

```bash
# Create worktree with new branch
git worktree add ../feature-branch -b feature-branch

# Create worktree from existing branch
git worktree add ../existing-branch existing-branch

# Create worktree in specific location
git worktree add ~/projects/worktrees/my-feature -b my-feature
```

### List all worktrees

```bash
git worktree list
```

Output:
```
/Users/me/projects/myapp       abc1234 [main]
/Users/me/projects/feature-a   def5678 [feature-a]
/Users/me/projects/feature-b   ghi9012 [feature-b]
```

### Remove a worktree

```bash
# Remove worktree (keeps branch)
git worktree remove ../feature-branch

# Force remove (if worktree has uncommitted changes)
git worktree remove --force ../feature-branch

# Clean up stale worktree references
git worktree prune
```

### Navigate to a worktree

```bash
cd ../feature-branch
```

## Why use with Claude Code?

Claude Code runs in your terminal and can execute bash commands, edit files, and commit code. Running multiple Claude sessions in the same directory causes:

- **File conflicts** - Multiple Claudes editing the same files
- **Git conflicts** - Commits stepping on each other
- **Context confusion** - Claude seeing changes from other sessions
- **Lost work** - Overwrites from parallel edits

**Git worktrees solve this** by giving each Claude session its own isolated directory with its own branch.

## Parallel Claude Code workflow

### Step 1: Create worktrees for parallel work

```bash
# From your main repo directory
cd ~/projects/myapp

# Create worktrees for parallel tasks
git worktree add ../myapp-feature-a -b feature-a
git worktree add ../myapp-feature-b -b feature-b
git worktree add ../myapp-bugfix -b bugfix-123
```

### Step 2: Launch Claude Code in each worktree

Open separate terminal windows/tabs:

```bash
# Terminal 1: Work on feature A
cd ~/projects/myapp-feature-a
claude

# Terminal 2: Work on feature B
cd ~/projects/myapp-feature-b
claude

# Terminal 3: Fix the bug
cd ~/projects/myapp-bugfix
claude
```

### Step 3: Each Claude works independently

- Claude in feature-a worktree can edit files, run tests, commit
- Claude in feature-b worktree does the same, independently
- No conflicts, no overwrites, complete isolation

### Step 4: Merge when complete

```bash
# From main repo
cd ~/projects/myapp
git checkout main

# Merge completed features
git merge feature-a
git merge feature-b
git merge bugfix-123
```

### Step 5: Cleanup worktrees

```bash
git worktree remove ../myapp-feature-a
git worktree remove ../myapp-feature-b
git worktree remove ../myapp-bugfix

# Optionally delete branches if merged
git branch -d feature-a feature-b bugfix-123
```

## Workflow patterns

### Pattern 1: Parallel feature development

Run multiple Claude sessions on independent features:

```bash
# Create worktrees
git worktree add ../app-auth -b feature/authentication
git worktree add ../app-api -b feature/api-endpoints
git worktree add ../app-ui -b feature/dashboard-ui

# Launch Claude in each (separate terminals)
cd ../app-auth && claude   # "Implement user authentication"
cd ../app-api && claude    # "Build REST API endpoints"
cd ../app-ui && claude     # "Create dashboard components"
```

### Pattern 2: Parallel refactor phases

Split a large refactor into parallel tracks:

```bash
# Phase 0 stays in main (testing/validation)
# Phase 1: Foundation changes
git worktree add ../refactor-phase-1 -b refactor/phase-1

# Phase 2: Plugin updates (independent)
git worktree add ../refactor-phase-2 -b refactor/phase-2

# Phase 3: Documentation (independent)
git worktree add ../refactor-phase-3 -b refactor/phase-3
```

### Pattern 3: Task isolation with Plan Mode

Use Plan Mode in each worktree for controlled parallel exploration:

```bash
# Worktree 1: Research approach A
cd ../approach-a && claude  # Use /plan or shift+tab for plan mode

# Worktree 2: Research approach B
cd ../approach-b && claude  # Different approach, same problem

# Compare results, pick best approach
```

### Pattern 4: CI/testing in separate worktree

Keep a clean worktree for running tests while developing in another:

```bash
# Development worktree (messy, work in progress)
git worktree add ../app-dev -b feature/new-thing

# Clean worktree for testing (stays on main or PR branch)
git worktree add ../app-test main

# Run tests in clean environment
cd ../app-test && mix test
```

## Best practices

### Naming conventions

Use consistent naming for easy identification:

```bash
# Pattern: <project>-<purpose>
git worktree add ../myapp-feature-auth -b feature/auth
git worktree add ../myapp-bugfix-123 -b bugfix/issue-123
git worktree add ../myapp-refactor-db -b refactor/database
```

### Organize worktrees

Keep worktrees organized in a predictable location:

```bash
# Option 1: Sibling directories (recommended)
~/projects/myapp/           # Main repo
~/projects/myapp-feature-a/ # Worktrees as siblings
~/projects/myapp-feature-b/

# Option 2: Dedicated worktrees folder
~/projects/worktrees/myapp-feature-a/
~/projects/worktrees/myapp-feature-b/
```

### Claude Code in worktrees

1. **One Claude per worktree** - Never run multiple Claude sessions in the same directory
2. **Use Plan Mode** - When exploring, use plan mode to prevent premature changes
3. **Commit frequently** - Small commits make merging easier
4. **Keep branches focused** - Each worktree/branch should have a single purpose

### When NOT to use worktrees

- **Simple, quick changes** - Single-branch workflow is fine
- **Tightly coupled changes** - If tasks depend on each other, work sequentially
- **Limited disk space** - Each worktree duplicates working files (not .git)
- **Single-focus sessions** - If you're only doing one thing, no need for worktrees

## Example: Parallel refactor phases

From the refactor.md in this repository:

```bash
# Main session stays in original directory for testing
cd /Users/me/projects/marketplace

# Worktree for Phase 0 tasks (foundation)
git worktree add ../marketplace-phase-0 -b refactor/phase-0-foundation

# Worktree for Phase 1 tasks (ownership)
git worktree add ../marketplace-phase-1 -b refactor/phase-1-ownership

# Launch parallel Claude sessions
# Terminal 1:
cd ../marketplace-phase-0 && claude
# "Complete Task 0d: Create git worktrees skill"

# Terminal 2:
cd ../marketplace-phase-1 && claude
# "Complete Task 1: Update marketplace ownership"

# After completion, merge back to main
cd /Users/me/projects/marketplace
git merge refactor/phase-0-foundation
git merge refactor/phase-1-ownership

# Cleanup
git worktree remove ../marketplace-phase-0
git worktree remove ../marketplace-phase-1
git branch -d refactor/phase-0-foundation refactor/phase-1-ownership
```

## Parallel execution map

Visual representation of parallel work:

```
Session 1 (main)         Session 2              Session 3
────────────────────     ────────────────────   ────────────────────
Testing/validation       Feature A              Feature B
     ↓                        ↓                      ↓
Run tests                Implement              Implement
Verify builds            Edit files             Edit files
                         Commit                 Commit
     ↓                        ↓                      ↓
─────────────────────── MERGE ALL TO MAIN ───────────────────────
     ↓
Cleanup worktrees
Delete merged branches
```

## Troubleshooting

### "fatal: 'branch' is already checked out"

Git prevents checking out the same branch in multiple worktrees:

```bash
# Solution: Use a different branch name
git worktree add ../new-worktree -b different-branch-name
```

### Worktree directory already exists

```bash
# Remove the directory first, or use a different path
rm -rf ../existing-directory
git worktree add ../existing-directory -b my-branch
```

### Stale worktree references

After manually deleting a worktree directory:

```bash
# Clean up stale references
git worktree prune
```

### Worktree has uncommitted changes

```bash
# Option 1: Commit or stash changes first
cd ../worktree && git stash

# Option 2: Force remove (loses changes!)
git worktree remove --force ../worktree
```

## Quick reference

| Command | Description |
|---------|-------------|
| `git worktree add <path> -b <branch>` | Create worktree with new branch |
| `git worktree add <path> <branch>` | Create worktree from existing branch |
| `git worktree list` | List all worktrees |
| `git worktree remove <path>` | Remove a worktree |
| `git worktree prune` | Clean up stale references |

## Sources

- [incident.io: Shipping faster with Claude Code and Git Worktrees](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)
- [Anthropic: Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Git Documentation: git-worktree](https://git-scm.com/docs/git-worktree)
