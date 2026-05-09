---
name: git-worktrees
description: Run multiple Claude Code sessions in parallel using git worktrees. Use when working on multiple features simultaneously, running parallel refactors, or isolating experimental branches. Prevents Claude sessions from conflicting by giving each its own working directory.
allowed-tools: Bash, Read
---

<!-- Auto-synced from ~/.claude/includes/worktree-workflow.md — do not edit manually -->

# Worktree-Per-Branch Workflow

Run multiple Claude Code sessions in parallel without files landing on the wrong branch. The mechanic: every new branch gets its own worktree under a centralized location, named after a tracking ID, cleaned up when the work merges.

**Scope:** local laptop only — Claude Code on `~/_DATA/code/<repo>/`. Cloud-delegation worktrees (Codex `codex/...`, Cursor `cursor/...`) are governed separately by `delegation-rules.md` and `linear-workflow.md`.

## When to Create a Worktree

**Trigger: any branch-worthy work.** Whenever Claude would otherwise run `git checkout -b <new-branch>`, create a worktree instead.

✅ Worktree warranted:
- Starting a new feature, fix, refactor, or experiment that will become its own PR
- Working on a `[P]` parallel ROADMAP task while another session is on a different branch
- Picking up a Linear issue, ROADMAP task, or scoped fix

❌ No worktree needed:
- Tiny in-place fix on the currently checked-out branch (typo, doc tweak)
- Read-only exploration / investigation / answering questions
- Running tests, builds, or quality checks against the current state

## Naming — Use a Tracking ID

Pick the worktree ID in this preference order:

1. **Linear issue** — `MW-247`, `INE-5` (when the work is tracked in Linear)
2. **ROADMAP task number** — `task-42` (local-only work tracked in `ROADMAP.md`)
3. **Branch name** — `fix-auth-redirect`, `experiment-cache-layer` (ad-hoc work)

The ID becomes both the worktree directory name AND the branch name (or a sensible derivation — branch can be `feat/<id>-<slug>` if convention dictates).

## Location — Centralized

```
~/_DATA/worktrees/<repo>/<id>/
```

- `<repo>` = repo basename (matches `~/_DATA/code/<repo>/` directory name)
- `<id>` = the tracking ID from above

**Why centralized:** sibling-of-repo (`~/_DATA/code/<repo>-<id>/`) clutters `~/_DATA/code/`; in-repo (`<repo>/.worktrees/<id>/`) gets traversed by `ripgrep` / `mix deps` / file watchers. A dedicated top-level dir is easy to grep for orphans (`ls ~/_DATA/worktrees/<repo>/`) and stays out of every other tool's path.

## Commands

```bash
# Create — branch + worktree in one step
git worktree add ~/_DATA/worktrees/<repo>/<id> -b <branch>

# Existing branch (e.g., picking up someone else's WIP)
git worktree add ~/_DATA/worktrees/<repo>/<id> <branch>

# List active worktrees in the repo
git worktree list

# Remove (after PR merge / branch deletion on remote)
git worktree remove ~/_DATA/worktrees/<repo>/<id>
git worktree prune
```

To start working in a new worktree, open a fresh Claude Code session in that directory: `claude` from `~/_DATA/worktrees/<repo>/<id>/`.

## After PR Merge — Run `audit-review`

After the PR merges to the default branch, `staged-review:audit-review` runs against the merge SHA. Catches hygiene drift (extractions, doc gaps, missing TODO markers, ROADMAP/CHANGELOG drift) that pre-commit `code-review` may have skipped under time pressure. The skill writes `.audit/<merge-sha>.md` reports + lands one `audit(...)` commit on the default branch.

**Auto-invoked post-merge.** Two invocation paths:

1. **Auto-merge path** — `commit-review` Step 15 already chains `Skill(audit-review) <merge-sha>^..<merge-sha>` immediately after `gh pr merge`. Nothing extra to do.
2. **User-merge path** — when the user merges manually (any PR, cloud-agent or self-authored), the same session runs `audit-review` against the merge SHA in the next step.

```
# After `gh pr merge` lands (auto or manual):
git checkout <default-branch> && git pull
Skill(audit-review)  # arguments: <merge-sha>^..<merge-sha>
```

**Manual override:** `/audit-review [<sha>|<range>]` for catch-up audits, batch passes, or compliance asks.

**Tiny-commit fast path.** For commits ≤100 LOC AND no `lib/` (or language equivalent) touched, the skill skips Codex dispatch and writes a `verdict: clean — fast-path` report. No separate skip flag needed; if every commit in the range is fast-path-eligible, the audit is cosmetic and ends in seconds.

**Why post-merge, not post-pr-create.** Three reasons. (a) Bots (CodeRabbit, Copilot, Codex's GitHub bot) run between PR-open and merge — auditing pre-bot means re-auditing if bots flag substantive findings. (b) The audit commit lands on the default branch where it's durable; running pre-merge would land it on a soon-to-be-deleted feature branch. (c) `.audit/<merge-sha>.md` becomes the canonical inspection artifact for the merged change set, indexed off the SHA that's actually in `main` history.

## Lifecycle — Cleanup Is Part of Completion

**The work isn't done until the worktree is gone.**

Cleanup trigger: PR merged to base, or feature branch deleted from remote.

```bash
# Same session that completes the PR merge:
git worktree remove ~/_DATA/worktrees/<repo>/<id>
git worktree prune
git branch -d <branch>  # if local branch still around
```

If you forget and later notice an orphan (worktree exists, but `git branch -vv` shows the branch as merged or `[gone]`), run the same removal commands. Orphan accumulation is what motivated the original worktree ban — keeping the directory tidy is the price of admission.

## Auto-Allowed Inside a Tracked Worktree

The act of creating a worktree under `~/_DATA/worktrees/<repo>/<id>/` is itself the scope authorization for git operations on that branch:

✅ **Auto-allowed without asking:**
- `git commit` to the worktree's own branch
- `git push -u origin <branch>` to publish the feature branch
- `gh pr create` against the repo's default base branch

❌ **Still requires explicit user request:**
- Commit/push on the main checkout (`~/_DATA/code/<repo>/`) directly to a shared branch (`main`, `master`, `development`)
- Commits in dependency repos / sibling repos checked out for inspection
- `gh pr merge` (governed by `delegation-rules.md` § "DON'T AUTO-MERGE PRS")
- Force-push, amend published commits, rebase shared history
- `git push` to a cloud-agent's branch (governed by `delegation-rules.md` § "NEVER PUSH TO A CLOUD-AGENT'S BRANCH")

**Mental model:** worktree creation = scope authorization. Merge = user authorization. Three rules stay strict (merge, force-push, cloud-agent branches); commit/push/PR-create in a tracked worktree loosens.

## What NOT to Do in a Worktree

- **Don't open IEx / Tidewave from a worktree.** Use the host project (`~/_DATA/code/<repo>/`) for runtime exploration. IEx in the worktree creates a parallel `_build` and recompile churn that races with the host session. Mirrors the existing `linear-workflow.md` § "Tidewave-in-worktree" constraint.
- **Don't create a worktree for read-only exploration.** Read files in-place from the main checkout. Worktrees are for branch-worthy work that will produce commits.
- **Don't commit from a non-worktree path** (the main checkout) when the work belongs to a feature branch. If you find yourself about to `git checkout -b` from the main checkout, stop and create a worktree.

## Per-Repo Override

A project can opt out of the worktree workflow by pinning a memory file under `~/.claude/projects/<project>/memory/feedback_no_worktrees.md`. Local memory always wins over global rules. Use this only when the project genuinely requires direct work on a single shared branch (e.g. a thin extraction tool with one active line of development).

## Cross-References

- `~/.claude/CLAUDE.md` § "Worktree-Per-Branch Workflow" — the rule pointer
- `~/.claude/includes/critical-rules.md` § "NEVER COMMIT WITHOUT EXPLICIT REQUEST" — the relaxed rule for tracked worktrees
- `~/.claude/includes/delegation-rules.md` — strict rules that stay strict (cloud-agent branches); auto-merge loosened for cloud-agent PRs
- `~/.claude/includes/task-prioritization.md` § "Parallel Work (`[P]`)" — when ROADMAP-tracked work uses worktrees
- `staged-review:audit-review` skill — the post-merge hygiene pass
