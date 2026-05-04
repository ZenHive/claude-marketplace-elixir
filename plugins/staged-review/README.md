# Code Review Plugin

Universal code review workflow. Language-agnostic — works with Elixir, Rust, Go, or any language.

Two sibling skills:

- **`code-review`** — local pre-commit review of `git diff --staged`
- **`commit-review`** — cloud-agent PR review (Codex), polls Linear `In Review` issues, runs full local harness, verdict-only (user merges)

## `code-review` — Staged Files

Reviews `git diff --staged` against 5 categories:

1. **Bugs & Logic Errors** — runtime crashes, type confusion, silent failures
2. **Missing Extractions** — code AND data that should be separated out
3. **Missing TODO Markers** — temporary code without `TODO:` for static analysis
4. **Abstraction Opportunities** — 3+ similar patterns that could be unified
5. **Actionable TODOs** — TODOs resolvable now, fixed directly

Plus **Category 6: Documentation Gaps** (ROADMAP, CHANGELOG, CLAUDE.md, README, in-code `@doc`/`@spec` drift). Mandatory Codex second-opinion via `codex:codex-rescue`.

Each finding is rated 1-10 priority. Actionable items are fixed directly, not just flagged.

## `commit-review` — Codex PR Review

For the Codex delegation workflow (`[CX]` task marker → Linear → Codex PR → `commit-review`):

1. Polls Linear for `In Review` issues delegated to Codex
2. **Spins up a sibling worktree** (`../<repo>-review-pr-<n>`) so the host session's branch is never touched and parallel sessions can review different PRs concurrently — see the `git-worktrees` skill for the convention
3. `gh pr checkout <number>` inside the worktree — fetches the PR branch
4. Runs the full local harness Codex's environment lacks: `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix dialyzer.json`, `mix test.json --cover`, `mix doctor`, `mix sobelow`
5. Stages mechanical fixes (format, credo nits, doc gaps) — does **not** commit
6. Applies `code-review`'s 5-category audit + Codex second-opinion against `gh pr diff`
7. Cross-references findings against the Linear issue's acceptance criteria
8. Presents verdict: ✅ ready to merge / ⚠️ blockers / 💬 discussion items
9. Offers to post the verdict as a Linear comment (user decides)
10. Cleans up the worktree — auto-removes when clean; surfaces manual cleanup when staged local fixes are present

Per `critical-rules.md` § "DON'T AUTO-MERGE PRS", the skill **does not run `gh pr merge`** — the user merges. Expects this repo's `AGENTS.md` to be current (generate via `claude-marketplace-elixir/scripts/sync-agents-md.sh`) so Codex follows the same rules our local hooks would enforce.

## Usage

```
/staged-review:code-review     # local pre-commit review
/staged-review:commit-review   # Codex PR review
```

## Relationship to Language Commands

This skill provides the **workflow** (what to check, in what order, with what output). For deep-dive language-specific checklists, use:

- `/elixir-code-review` — comprehensive Elixir/Phoenix checklist
- `/rust-code-review` — comprehensive Rust checklist

## Installation

```bash
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install staged-review@deltahedge
```
