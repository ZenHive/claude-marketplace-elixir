---
name: flow-review
description: Merge-train mode for 2+ open cloud-agent PRs. Use when multiple delegated PRs are queued and per-PR rebase round-trips exceed review time — polls open cloud-agent PRs, classifies by tier and mergeability, dependency-sorts by file-overlap, runs the rebase cascade between merges. Invoked by 'run flow-review'. Composes `agent-pr-review` for per-PR Tier-2 handoff.
allowed-tools: Read, Grep, Glob, Bash
---

<!-- Auto-synced from ~/.claude/includes/flow-review.md — do not edit manually -->

## flow-review — Merge-Train Mode

`flow-review` is **merge-train mode** — batch orchestration for 2+ open cloud-agent PRs.

It composes `agent-pr-review.md` (per-PR Tier-2 handoff, the polling shape, the tier matrix) on top of `linear-queue.md` (the substrate) and `agent-dispatch.md` (how the PRs in the train got delegated).

### Invocation

Workflow-only — no CLI, no skill wrapper beyond this one. Triggered by user request ("run flow-review") or in-session decision once 2+ cloud-agent PRs are open in the current repo. The bottleneck it solves: each merge advances the default branch and invalidates every other PR's base SHA, so per-PR rebase round-trips surface phantom conflicts in untouched files. With 3+ PRs queued, rebase tax exceeds review time.

### What `flow-review` does

1. **Polls** all open cloud-agent PRs in the current repo (filter from `agent-pr-review.md` § "Polling for 'Ready for Review'", scoped to current repo + extended to include `mergeStateStatus`).
2. **Classifies** each PR by tier (per `agent-pr-review.md` § "Review Tiering: When Full Tier 2 Earns Its Cost") and mergeability (CI green | red | conflicting | bot-flagged).
3. **Dependency-sorts** the queue from a directed graph built on file-overlap (parsed from `## Files to modify` of each PR's source issue) + Linear `blockedBy` / `relatedTo`. PRs touching only their own files merge first; coordination-file PRs last. Sort by PR age within each layer.
4. **Surfaces** the ordered queue with per-PR action recommendations.
5. **Executes** the rebase cascade between merges. User owns merges; reviewer owns rebases.

### Tier-based action matrix

| Tier | CI | Bots | Conflicts | Action |
|---|---|---|---|---|
| Ceremony | green | clean | none | Auto-merge if preconditions hold (cloud-agent PR), then chain `audit-review`; otherwise surface as "ready, awaiting `gh pr merge`" |
| Standard | green | clean | none | Same as ceremony, plus 5-min skim if any bot finding |
| Critical | green | clean | none | Hand off to `staged-review:commit-review` (single-PR Tier 2), back to queue |
| Any | red | — | — | Surface for human triage; skip in current pass |
| Any | — | — | conflicting/behind | Trigger rebase cascade (below) |
| Any | — | flagged | — | Surface bot finding for triage (push-back vs. defer) |

### Rebase cascade

After the user runs `gh pr merge` on PR #N:

```
for each remaining PR in dependency order:
  if PR.mergeStateStatus ∈ { BEHIND, DIRTY }:
    git fetch && git checkout <agent-branch>
    git rebase origin/<default-branch>
    if conflicts:
      attempt mechanical resolution (see invariants)
      if mechanical resolution succeeds:
        git push --force-with-lease
      else:
        git rebase --abort
        post Linear @cursor / @codex comment with conflict context
        skip this PR (agent picks up the rebase)
    else:
      git push --force-with-lease
    wait for CI re-run; loop
```

**Rebase-only carve-out invariants.** This carve-out is one of the two authorized exceptions to `delegation-rules.md` § "NEVER PUSH TO A CLOUD-AGENT'S BRANCH"; the invariants below are the canonical statement of it. Strict; do not relax.

- **Allowed:** `git rebase origin/<default>` + `git push --force-with-lease` to the cloud-agent branch.
- **Mechanical-resolution test:** post-rebase diff vs. pre-rebase diff (against the new merge base) MUST be byte-identical except inside conflict regions. Verify with `git diff <pre-rebase-tip>..HEAD -- <files-not-in-conflict>` returning empty.
- **Mechanical resolutions allowed:** alphabetical/sorted re-merge of registry append-only edits (`@descripex_modules`, plug-pipeline lists, supervisor children), test-file additions with no overlap, doc append-only blocks. Deterministic from source.
- **Forbidden:** semantic conflict resolution, any logic edit, function-body changes during rebase, any push without `--force-with-lease`, any push to a non-cloud-agent branch under this carve-out.
- **Abort path:** if mechanical resolution doesn't apply cleanly, `git rebase --abort` and post a Linear `@cursor` / `@codex` comment with conflict context. Agent picks up the rebase.

**Auto-merge per PR (preconditions hold).** `delegation-rules.md` § "DON'T AUTO-MERGE PRS" loosens for cloud-agent PRs that meet all 5 preconditions — merge-train auto-merges each PR in dependency order, chains `audit-review` against each merge SHA, then rebases the next PR onto the new tip. PRs failing preconditions surface with the `gh pr merge` command for the user.

### When to use

| Situation | Use |
|---|---|
| 1 PR, critical tier | `staged-review:commit-review` |
| 1 PR, standard or ceremony | Either; merge-train is overhead-equivalent at N=1 |
| 2+ PRs, mixed tiers | **Merge-train.** Cascades, sorts, hands critical-tier off to `commit-review` inline |
| 2+ PRs, all ceremony/standard | **Merge-train.** Maximum gain — no per-PR Tier 2 cost, just cascade + user-confirm |

### Bookkeeping commits

Post-merge ROADMAP/CHANGELOG/README updates land in the chained `audit-review` `audit(<sha>): ...` commit on the repo's default branch (`main` / `master` / `development`) per merge. Reviewer rebases each remaining PR onto the new default tip in parallel, force-with-leases, CI re-runs. The audit commit IS the bookkeeping; no separate `Update docs for PR #N` commit.

### Cross-References

- `agent-pr-review.md` — the per-PR review layer this composes; § "Polling for 'Ready for Review'", § "Review Tiering: When Full Tier 2 Earns Its Cost"
- `agent-dispatch.md` — how the PRs in the train got delegated
- `linear-queue.md` — the Linear-as-queue substrate
- `delegation-rules.md` § "NEVER PUSH TO A CLOUD-AGENT'S BRANCH" — the base rule this carve-out is an authorized exception to; § "DON'T AUTO-MERGE PRS" — the 5-precondition auto-merge gate
- `staged-review:commit-review` skill — single-PR Tier-2 handoff target for critical-tier PRs
- `staged-review:audit-review` skill — chained against each merge SHA
