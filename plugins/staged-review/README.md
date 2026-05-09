# Code Review Plugin

Universal code review workflow. Language-agnostic — works with Elixir, Rust, Go, or any language.

Three sibling skills covering the pre-commit / pre-merge / post-merge axis:

- **`code-review`** — pre-commit review of `git diff --staged`
- **`commit-review`** — pre-merge cloud-agent PR gate (Cursor / Codex when re-enabled), narrowed correctness gate, auto-merges on ✅ + green CI for cloud-agent PRs
- **`audit-review`** — post-commit / post-merge audit on committed code, fully autonomous, writes `.audit/<sha>.md` reports + `audit(...)` commit

## Three-Tier Review Chain

| Skill | When | Categories | Auto-mode? |
|---|---|---|---|
| `code-review` | Pre-commit (`git diff --staged`) | 5 + Cat 6 (full doc hygiene) | Plan-mode-with-auto-apply (one user gate: exit-plan-to-apply) |
| `commit-review` | Pre-merge cloud-agent PR | Cat 1 (Bugs) + narrowed Cat 6 (`@doc`/`@spec` correctness drift only) | Auto-merge on ✅ + green CI + cloud-agent branch + no `requested-changes` + no `[BLOCK-MERGE]` label |
| `audit-review` | Post-commit / post-merge | 5 + Cat 6 (full doc hygiene) | Fully autonomous — zero user gates |

Same 5+1 category catalog across all three. Categories shift between layers: pre-commit is judgment-tier with auto-apply; pre-merge is correctness-only (hygiene moves post-merge); post-merge is full audit with mandatory Codex second-opinion.

## `code-review` — Staged Files

Reviews `git diff --staged` against 5 categories:

1. **Bugs & Logic Errors** — runtime crashes, type confusion, silent failures
2. **Missing Extractions** — code AND data that should be separated out
3. **Missing TODO Markers** — temporary code without `TODO:` for static analysis
4. **Abstraction Opportunities** — 3+ similar patterns that could be unified
5. **Actionable TODOs** — TODOs resolvable now, fixed directly

Plus **Category 6: Documentation Gaps** (ROADMAP, CHANGELOG, CLAUDE.md, README, in-code `@doc`/`@spec` drift). Mandatory Codex second-opinion via `codex:codex-rescue`.

Each finding is rated 1-10 priority. Actionable items are fixed directly, not just flagged.

## `commit-review` — Pre-Merge Cloud-Agent PR Gate

For the Cursor / Codex delegation workflow (`[CSR]` / `[CX]` task marker → Linear → cloud-agent PR → `commit-review`):

1. Polls Linear for `In Review` issues delegated to a cloud agent
2. Reads the PR via `gh` (no local checkout — review-only by default)
3. CI gate (`gh pr checks`), bot ensemble triage (CodeRabbit / Copilot / Codex bot), draft handling, scope/acceptance-criteria match
4. **Narrowed audit**: Category 1 (Bugs) only + a thin slice of Category 6 (in-code `@doc`/`@spec` correctness drift). Hygiene categories (extractions, abstractions, TODO markers, ROADMAP/CHANGELOG drift) are **not** raised pre-merge — they're audit-review's job
5. Auto-posts push-back as Linear `@cursor` comment + GitHub PR review per `delegation-rules.md` § "POST LINEAR/PR COMMENTS WITHOUT ASKING"
6. Verdict: ✅ ready / ⚠️ blockers / 💬 discussion
7. **On ✅ + 5 preconditions hold**: auto-runs `gh pr merge --squash --delete-branch`, captures merge SHA, then chains `Skill(audit-review)` against `<merge-sha>^..<merge-sha>` for post-merge hygiene
8. **On any precondition fail**: surface verdict and stop — user merges manually

Auto-merge preconditions: ✅ verdict, green CI, cloud-agent branch (`cursor/*` or `codex/*`), no `requested-changes` review, no `[BLOCK-MERGE]` label. See `delegation-rules.md` § "DON'T AUTO-MERGE PRS".

## `audit-review` — Post-Commit / Post-Merge Audit

Fully autonomous post-commit pass. Triggered:

1. Auto-invoked by `worktree-workflow` after `gh pr create` (audits self-authored worktree commits)
2. Auto-invoked by `commit-review`'s auto-merge tail (audits the merge SHA on `main`)
3. Auto-invoked by `linear-workflow` after a user-confirmed merge for non-auto-merge cases
4. Manually via `/audit-review [<sha>|<range>]`

Workflow:

1. Resolve commit range (default: tail since last `audit(...)` commit)
2. Tiny-commit fast path (≤100 LOC + no `lib/`) — skip Codex dispatch, write `verdict: clean — fast-path` report
3. Apply 5 + Cat 6 categories per non-tiny commit
4. Mandatory parallel Codex dispatch via `codex:codex-rescue`
5. Auto-apply rated 3-10 + actionable + `discuss-trivial`
6. Auto-resolve `discuss-design` via Claude+Codex dialogue with ROADMAP scope: convergence applies, divergence drops to ROADMAP candidate (no user escalation)
7. Write `.audit/<sha>.md` per audited commit
8. Auto-commit one `audit(...)` covering the batch

The `audit(...)` commit is auto-allowed on `main` (per `critical-rules.md` § "GIT COMMIT / PUSH / PR-CREATE — SCOPED BY WORKTREE") — it IS the post-merge bookkeeping commit, replacing the old `commit-review` Step 15 doc-only commit.

## Usage

```
/staged-review:code-review              # pre-commit review
/staged-review:commit-review            # pre-merge cloud-agent PR review
/staged-review:audit-review             # post-commit / post-merge audit (manual)
/staged-review:audit-review HEAD~3..HEAD  # explicit range
/staged-review:audit-review --full <sha>  # suppress tiny-commit fast-path
```

## Relationship to Language Commands

This plugin provides the **workflow** (what to check, in what order, with what output). For deep-dive language-specific checklists, use:

- `/elixir-code-review` — comprehensive Elixir/Phoenix checklist
- `/rust-code-review` — comprehensive Rust checklist

## Installation

```bash
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install staged-review@deltahedge
```
