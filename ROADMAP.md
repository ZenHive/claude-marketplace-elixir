# Marketplace Personalization Roadmap

Remaining tasks to personalize the Claude Code plugin marketplace. **This file is rendered** — `roadmap/tasks.toml` is the canonical source; `rmap render` rewrites only the bytes between the marker pairs below. Author tasks with `rmap new --from-stdin`, change status with `rmap status <id> <state>`. See [CHANGELOG.md](CHANGELOG.md) for shipped work.

## Current Focus

<!-- FOCUS:BEGIN -->
**Focus phase:** 8 — Hook Scripts (4 of 4 done · 0 in progress)

**Last shipped:** no recent shipments

**Up next:** Task 49 — Propagate the rmap mandate across repos [D:4/B:8/U:8 → Eff:2.0] 🎯
<!-- FOCUS:END -->

## Official Documentation References

| Topic | URL |
|-------|-----|
| Plugins Guide | https://docs.anthropic.com/en/docs/claude-code/plugins |
| Plugins Reference | https://docs.anthropic.com/en/docs/claude-code/plugins-reference |
| Plugin Marketplaces | https://docs.anthropic.com/en/docs/claude-code/plugin-marketplaces |
| Agent Skills | https://docs.anthropic.com/en/docs/claude-code/skills |
| Hooks Guide | https://docs.anthropic.com/en/docs/claude-code/hooks-guide |
| Slash Commands | https://docs.anthropic.com/en/docs/claude-code/slash-commands |

---

## Phase 5 — Documentation (done)

<!-- TASKS:BEGIN phase=5 -->
> 2 tasks. See [CHANGELOG.md](CHANGELOG.md#phase-5-documentation).
<!-- TASKS:END -->

## Phase 7 — Skill Quality (done)

> **Methodology:** Informed by Anthropic's `document-skills:skill-creator` patterns — progressive disclosure, pushy descriptions, AI-coder-docs scope boundaries.

<!-- TASKS:BEGIN phase=7 -->
> 6 tasks. See [CHANGELOG.md](CHANGELOG.md#phase-7-skill-quality).
<!-- TASKS:END -->

## Phase 8 — Hook Scripts

> **Methodology:** New scripts in `plugins/elixir/scripts/`, wired into `plugins/elixir/hooks/hooks.json`. Use `prefer-test-json.sh` / `prefer-dialyzer-json.sh` as the `PreToolUse:Bash` template (warn vs. deny JSON shapes); use `post-edit-check.sh`'s hidden-failures section as the `PostToolUse:Edit|Write|MultiEdit` template. Canonical rules live in `~/.claude/includes/critical-rules.md`, `development-commands.md`, `development-philosophy.md` — link to those, don't duplicate the prose.

<!-- TASKS:BEGIN phase=8 -->
| Task | Status | Notes |
|------|--------|-------|
| Task 29 | ✅ | 🎁 **hook_scripts** · Block destructive Bash patterns [D:3/B:8/U:7 → Eff:2.5] 🎯 |
| Task 30 | ✅ | 🎁 **hook_scripts** · Warn on tooling-flag omissions [D:2/B:6/U:6 → Eff:3.0] 🎯 |
| Task 31 | ✅ | 🎁 **hook_scripts** · Warn on doctest IO and untagged temporary code [D:4/B:6/U:4 → Eff:1.25] 📋 |
| Task 32 | ✅ | 🎁 **hook_scripts** · Warn on shell-eval Elixir, prefer Tidewave [D:2/B:7/U:7 → Eff:3.5] 🎯 |
<!-- TASKS:END -->

## Phase 9 — Codex Delegation Workflow (done)

> **Methodology:** Linear MCP as shared task tracker; Codex (registered Linear user) executes `[CX]` tasks; PR opens with GH-native auto-merge wired (`gh pr merge <N> --auto --squash --delete-branch`); GitHub gates the merge against branch protection (required CI checks + no `requested-changes` + no `[BLOCK-MERGE]` label). Bot findings get triaged post-merge in `audit-review` Step 5d. Pre-merge phase is zero Claude tokens.

<!-- TASKS:BEGIN phase=9 -->
> 5 tasks. See [CHANGELOG.md](CHANGELOG.md#phase-9-codex-delegation-workflow).
<!-- TASKS:END -->

## Phase 10 — Audit-Review Follow-Ups

> **Methodology:** Quality-of-life and edge-case extensions to the `audit-review` workflow shipped in v1.16 of `staged-review`. v2.0 collapses the six-phase chain to five (worktree → bots → GH-native auto-merge → audit) by deleting `commit-review`; bot-comment triage + Linear close-out + acceptance-criteria verification absorb into `audit-review`. These follow-ups extend coverage and observability without blocking the core flow.

<!-- TASKS:BEGIN phase=10 -->
| Task | Status | Notes |
|------|--------|-------|
| Task 38 | ✅ | 🎁 **audit_followups** · SessionStart hook for audit detection [D:3/B:5/U:6 → Eff:1.83] 🚀 |
| Task 39 | ✅ | 🎁 **audit_followups** · /audit-status roll-up command [D:2/B:4/U:5 → Eff:2.25] 🎯 |
| Task 40 | ⬜ | 🎁 **audit_followups** · Cross-repo audit corpus aggregation [D:7/B:6/U:3 → Eff:0.64] ⚠️ |
| Task 41 | ⛔ | 🎁 **audit_followups** · Auto-merge for self-authored worktree PRs [D:4/B:6/U:5 → Eff:1.38] 📋 |
| Task 42 | ⬜ | 🎁 **audit_followups** · Audit re-run on amend / rebase [D:5/B:3/U:3 → Eff:0.6] ⚠️ |
| Task 43 | ⬜ | 🎁 **audit_followups** · Codex code-mutation re-enablement check [D:2/B:3/U:4 → Eff:1.75] 🚀 |
| Task 44 | ⛔ | 🎁 **audit_followups** · Replace zsh-incompatible classification script in audit-review SKILL.md [D:2/B:5/U:6 → Eff:2.75] 🎯 |
| Task 45 | ⛔ | 🎁 **audit_followups** · Worktree + clean-tree preconditions in audit-review [D:3/B:6/U:7 → Eff:2.17] 🎯 |
| Task 46 | ⛔ | 🎁 **audit_followups** · Audit-corpus-only mode (report without apply) [D:3/B:5/U:5 → Eff:1.67] 🚀 |
| Task 47 | ⛔ | 🎁 **audit_followups** · Per-commit Codex output capture in .audit/ [D:2/B:4/U:4 → Eff:2.0] 🎯 |
| Task 54 | ⛔ | 🎁 **audit_followups** · Align audit-review/flow-review checkpoint vocabulary with canonical ⏸ CHECKPOINT [D:2/B:4/U:4 → Eff:2.0] 🎯 |
| Task 57 | ✅ | 🎁 **audit_followups** · Decouple audit-review from commit-review; default to deferred/batched [D:3/B:7/U:8 → Eff:2.5] 🎯 |
| Task 58 | ⬜ | 🎁 **audit_followups** · Harden audit-review SKILL.md (preconditions, report-only, codex capture, classification, checkpoint vocab) [D:4/B:7/U:7 → Eff:1.75] 🚀 |
| Task 59 | ✅ | 🎁 **audit_followups** · Merge commit-review into audit-review; pre-merge becomes GitHub-native auto-merge [D:5/B:9/U:9 → Eff:1.8] 🚀 |
<!-- TASKS:END -->

---

## Completed Phases (0-4, 6)

Phases 0-4 and 6 of the original personalization roadmap completed before this repo migrated to `rmap`. Their per-task detail was never enumerated in `ROADMAP.md` (only aggregate counts), so they were not carried into `roadmap/tasks.toml` as individual tasks — the record lives in git history and `CHANGELOG.md`.

| Phase | Scope |
|-------|-------|
| 0. Foundation | Marketplace + plugin scaffolding |
| 1. Ownership | Namespace, author, attribution |
| 2. New Plugins | Plugin set buildout (incl. meta → elixir-workflows rename) |
| 3. Pre-commit | Consolidated pre-commit hooks |
| 4. Workflows | Workflow-command generator |
| 6. New Skills | First skill additions |

---

## Non-Goals (Out of Scope)

| Item | Reason |
|------|--------|
| CI/CD automation | Manual testing sufficient |
| Plugin versioning automation | Semantic versioning is manual |
| Removing existing plugins | Working and useful |
| New workflow commands | Enhance existing only |

## Future Scope (Post-Roadmap)

| Item | Description |
|------|-------------|
| TypeScript/JS plugin | Phoenix frontends, LiveView hooks, Node services |
| Go plugin | Services, CLI tools, protocol implementations |
| Rust plugin | NIFs (Rustler), performance-critical modules |
| Skill eval infrastructure | evals.json with test prompts and assertions for objective skills (hex-docs-search, usage-rules, elixir-setup, web-command) |
| Description optimization loop | Automated triggering tests using skill-creator's `run_loop.py` methodology |
| Blind comparison framework | A/B testing between skill versions using skill-creator's comparator pattern |
| `/elixir:sync-agents-md` slash command | Wrap Task 35's bash script as a slash command for one-step invocation |
| `/staged-review:delegate-to-codex` slash command | One-shot: gather spec, create Linear issue with `delegate: "Codex"`, label `cx-eligible`, transition to Backlog/Todo |
| AGENTS.md noise filter via `<!-- agents-md: skip -->` marker | Per-repo opt-out for imports that bloat AGENTS.md |
| SessionStart Linear `In Review` count announcement | Manual invocation only for now; revisit if missed in practice |
| `cx-eligible` label automation in `sync-agents-md.sh` | Script could verify the Linear label exists per workspace; out-of-scope for v1 |

---

## Decisions Made

| Question | Decision |
|----------|----------|
| Namespace | `deltahedge` |
| Owner name | DeltaHedge |
| Attribution | Keep Bradley Golden as original author |
| Repository URL | `https://github.com/ZenHive/claude-marketplace-elixir` |
