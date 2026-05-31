# SKILLS.md — Agent Guide to the `deltahedge` Marketplace

> **Audience: AI agents** (Claude Code, Codex, Cursor) consuming this marketplace.
> Humans setting up the marketplace: see [README.md](README.md).

This is the agent-facing catalog of every skill: **what it gives you** and **when to invoke it**.
45 skills across 8 plugins.

## How skills work

- A skill is **model-invoked guidance + workflows** — read-only knowledge that doesn't do anything until you invoke it.
- Each skill has a `description` field. Match it against the task in front of you; when it matches, invoke the skill **before** acting.
- In Claude Code: `Skill(<name>)`, or let it auto-trigger on description match. Codex/Cursor get an equivalent subset via `scripts/sync-codex-plugins.py`.
- Skills compose. Single-purpose by design — chain them (`hex-docs-search` + `usage-rules`, `linear-queue` → `agent-dispatch` → `agent-pr-review`).
- Skills only ship the knowledge the base model lacks: niche Hex packages, custom tooling, methodology rules. Don't expect a skill for stock Phoenix/Ecto/OTP — the model already has that.

## Quick routing — task → skill

| If you're… | Invoke |
|---|---|
| Starting a new Elixir project | `elixir-setup` → then `phoenix-setup` if Phoenix |
| Looking up a Hex package's **API** (signatures, typespecs) | `hex-docs-search` |
| Looking up how to **use** a package correctly (conventions, gotchas) | `usage-rules` |
| Exploring a running app at runtime before coding | `tidewave-guide` |
| Running tests | `ex-unit-json` (`mix test.json`) |
| Running Dialyzer | `dialyzer-json` (`mix dialyzer.json`) |
| Looking up a mix command or quality-check flag | `development-commands` |
| Adding CI to a repo that's a cloud-agent delegation target | `elixir-ci-harness` |
| Structuring a module/function or judging whether code is too complex | `code-style` |
| Writing @doc/@spec, hiding internals, choosing doctests vs tests, tagging TODOs | `development-philosophy` |
| Planning a multi-task backlog | `roadmap-planning` |
| Working with the roadmap substrate — picking work, scoring, status changes, rendering `ROADMAP.md`, migrating a hand-edited roadmap | `rmap` |
| Authoring a roadmap task (`rmap new`) or justifying its score | `task-writing` |
| Picking up + implementing a roadmap task | `task-driver` |
| Structuring multi-session / multi-phase work (handoffs, evaluator separation, batches) | `workflow-philosophy` |
| Orienting around the dev lifecycle ("which phase am I in?") | `dev-lifecycle` |
| Reviewing staged changes before commit | `code-review` |
| Gating a PR before merge | GitHub-native `gh pr merge <N> --auto --squash --delete-branch` + `[BLOCK-MERGE]` label (no skill — see `plugins/staged-review/templates/auto-merge.md`) |
| Auditing committed code post-merge | `audit-review` |
| Delegating a task to Codex/Cursor | `agent-dispatch` (start at `linear-workflow` if unsure) |
| Reviewing a cloud-agent's open PR | `agent-pr-review` |
| Managing 2+ open cloud-agent PRs as a merge train | `flow-review` |
| Recalling the hard rules of cloud-agent delegation (don't-steal, auto-merge, push-back) | `delegation-rules` |
| Running parallel Claude sessions on one repo | `git-worktrees` |
| Contributing a PR to a forked upstream library | `upstream-pr-workflow` |
| Working with JS/TS on the BEAM (choosing a tool) | `elixir-volt` (decision map) |
| Designing an API that AI agents will call | `agent-economy` |
| Deciding which repo deserves your next week of attention | `portfolio-strategy` |

## Catalog by concern

### Project setup & quality tooling

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`elixir-setup`](plugins/elixir/skills/elixir-setup/SKILL.md) | Standard deps (Styler, Credo, Dialyxir, Doctor, Tidewave, ex_unit_json, dialyzer_json), `.formatter.exs`, quality gates | `mix new`, starting a project, adding dev deps |
| [`phoenix-setup`](plugins/phoenix/skills/phoenix-setup/SKILL.md) | `phx.gen.auth` (the critical `--live` flag), Sobelow, LiveDebugger, HTMLFormatter, Tidewave endpoint plug | Creating a Phoenix project — after `elixir-setup` |
| [`development-commands`](plugins/elixir/skills/development-commands/SKILL.md) | Mix command reference — AI-friendly test/dialyzer/credo output flags, production builds | Looking up a mix command or quality-check invocation |
| [`ex-unit-json`](plugins/elixir/skills/ex-unit-json/SKILL.md) | `mix test.json` — AI-friendly test output, `--failed` iteration, `--cover` gate, `--group-by-error`, jq patterns | Running tests, iterating on failures |
| [`dialyzer-json`](plugins/elixir/skills/dialyzer-json/SKILL.md) | `mix dialyzer.json` — AI-friendly type warnings, `fix_hint` prioritization (code/spec/pattern) | Running Dialyzer, triaging type warnings |
| [`elixir-ci-harness`](plugins/elixir/skills/elixir-ci-harness/SKILL.md) | Copy-ready `harness.yml` GitHub Actions workflow — format/compile/credo/doctor/sobelow/test+cover/dialyzer gate, drift-free version sourcing | Adding deterministic CI, esp. for repos that are Codex/Cursor delegation targets |
| [`code-style`](plugins/elixir/skills/code-style/SKILL.md) | Complexity-based code-quality KPIs — per-tier budgets (functions/module, lines/function, call depth, pattern-match depth for simple/standard/complex) + universal standards (Dialyzer 0, Credo 8.0+, 80/95% coverage, 100% public-API docs) | Structuring a module/function, judging whether code is too complex |
| [`development-philosophy`](plugins/elixir/skills/development-philosophy/SKILL.md) | Elixir doc + internal-API conventions — no-IO-in-@doc, defp/@doc-false/@moduledoc-false/underscore decision tree, mandatory @spec, doctests-vs-ExUnit, TODO tagging, tightening-validators, cite-precedents/check-hex-before-crying-complexity | Writing @doc/@spec, hiding internals, choosing doctests vs tests, tagging deferred work, before objecting a macro is "complex" |

### Research before coding

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`hex-docs-search`](plugins/elixir/skills/hex-docs-search/SKILL.md) | Hex package **API docs** — function signatures, module docs, typespecs, examples | You need to look up how a package's API works |
| [`usage-rules`](plugins/elixir/skills/usage-rules/SKILL.md) | Package-specific **conventions** — good/bad examples, common mistakes, recommended patterns | Before writing code against Ash, Phoenix, Ecto, LiveView, any Hex package |
| [`tidewave-guide`](plugins/elixir/skills/tidewave-guide/SKILL.md) | Tidewave MCP tools for a running app — `project_eval`, runtime evaluation, DB queries, logs | Exploring APIs/data at runtime before implementing against them |
| [`web-command`](plugins/elixir/skills/web-command/SKILL.md) | The `web` command vs `WebFetch` — form submission, JS execution, LiveView testing, screenshots, auth sessions | Fetching pages, submitting forms, testing LiveView, screenshots |

> `hex-docs-search` (what's available) and `usage-rules` (how to use it correctly) are complements — invoke both for full coverage.

### Planning, tasks & lifecycle

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`roadmap-planning`](plugins/elixir/skills/roadmap-planning/SKILL.md) | D/B/U (Difficulty/Benefit/Usefulness) scoring, ROI-based ordering, phase organization, status/marker vocabulary — the framework `rmap` executes | Planning features, organizing refactors, structuring multi-task work |
| [`rmap`](plugins/task-driver/skills/rmap/SKILL.md) | The roadmap substrate — `roadmap/tasks.toml` is canonical, `ROADMAP.md` + `roadmap/data.json` are rendered. Command surface by intent, D/B/U → `scores` mapping, status/marker vocabulary, migration procedure for hand-edited roadmaps | Picking work (`rmap next`), scoring, changing status/markers, creating tasks (`rmap new`), rendering, or migrating a legacy `ROADMAP.md` |
| [`task-writing`](plugins/task-driver/skills/task-writing/SKILL.md) | How to write a task's `body` as a prompt (not a spec) — the 5-question pre-creation gate (anchor, baseline-first, one-session=one-task, milestone-fit, no-hedging), over-specified-vs-prompt examples, `rmap new --from-stdin` field set | Authoring a `roadmap/tasks.toml` task, writing a cross-instance handoff doc, justifying a score |
| [`task-driver`](plugins/task-driver/skills/task-driver/SKILL.md) | Reads roadmap state via `rmap` (`list` / `next` / `show`), selects by efficiency, implements with TodoWrite tracking, updates all project docs. Two modes: Pickup and Plan-and-File | Starting a work session, picking/implementing roadmap items |
| [`workflow-philosophy`](plugins/dev-lifecycle/skills/workflow-philosophy/SKILL.md) | Language-agnostic multi-session workflow principles — session-per-phase, evaluator separation, the staged-but-uncommitted implementer/reviewer handoff, batched execution with `/compact` STOP checkpoints, acceptance-criteria writing, verification-before-completion | Structuring multi-phase work, deciding handoff shape, writing acceptance criteria |
| [`dev-lifecycle`](plugins/dev-lifecycle/skills/dev-lifecycle/SKILL.md) | Canonical five-phase chain reference (task-driver → worktree → bots → merge → audit-review) — answers "which phase?", "which skill owns this?" | Orienting around the lifecycle, explaining phase handoffs |
| [`portfolio-strategy`](plugins/portfolio-strategy/skills/portfolio-strategy/SKILL.md) | Power-law portfolio rule for **cross-repo** decisions — start/continue/kill a project, where to spend attention | Evaluating portfolio health, deciding the next bet. NOT for within-project prioritization (use `roadmap-planning`) |
| [`workflow-generator`](plugins/elixir-workflows/skills/workflow-generator/SKILL.md) | Generates customized workflow slash commands (research, plan, implement, qa) for an Elixir project | Setting up a new project's development workflow |

### Code review chain

Two sibling skills covering pre-commit and post-merge. Pre-merge is GitHub-native (`gh pr merge --auto` + `[BLOCK-MERGE]` label gate — see `plugins/staged-review/templates/auto-merge.md`). Same review categories across both skills; layers differ in scope, reviewer count, and autonomy. Implementer/reviewer separation is preserved — no agent grades its own work.

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`code-review`](plugins/staged-review/skills/code-review/SKILL.md) | Single-reviewer **pre-commit** triage of `git diff --staged` — bugs, missing extractions, TODO markers, abstraction opportunities, doc gaps. Auto-applies rated fixes | Reviewing staged files before committing |
| [`audit-review`](plugins/staged-review/skills/audit-review/SKILL.md) | **Post-merge** full audit on committed code — mandatory parallel Codex second opinion, 3-reasoner merge (Claude / Codex / bots), absorbs bot-comment triage + Linear close-out + acceptance-criteria verification, auto-applies hygiene fixes, writes `.audit/<sha>.md`, commits as `audit(...)`. Fully autonomous. **Deferred** — SessionStart hook surfaces unaudited tail (≥3); user invokes `/staged-review:audit-status` or `Skill(audit-review) <range>` | Running post-commit/post-merge review against a commit range |

### Cloud-agent delegation

Linear-as-queue + cloud-agent (Codex, Cursor) delegation, split along a substrate/layer axis. `linear-queue` is standalone — usable with no cloud agents at all.

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`linear-workflow`](plugins/cloud-delegation/skills/linear-workflow/SKILL.md) | **Hub index** — points to the four skills below; finds which one owns a concern | Unsure which delegation skill you need — start here |
| [`linear-queue`](plugins/cloud-delegation/skills/linear-queue/SKILL.md) | **Substrate** — Linear MCP setup, workspace shape, issue-body-as-prompt template, status transitions, self-authored worktree flow, cross-repo coordination, ROADMAP-fallback | Setting up Linear-as-queue, tracking your own work in Linear, running the workflow without cloud agents |
| [`agent-dispatch`](plugins/cloud-delegation/skills/agent-dispatch/SKILL.md) | **Dispatch layer** — Codex/Cursor delegation flows, per-agent eligibility filtering, plan-shaped issue specs, batch sizing, pre-flight conflict detection | Delegating a ROADMAP task to a cloud agent |
| [`agent-pr-review`](plugins/cloud-delegation/skills/agent-pr-review/SKILL.md) | **Review layer** — review tiering, push-back-vs-fix-locally matrix, fetch-comments-first, polling, wake-mention discipline | A delegated PR is open and needs review |
| [`flow-review`](plugins/cloud-delegation/skills/flow-review/SKILL.md) | **Merge-train mode** — dependency-sort by file overlap, rebase cascade between merges, per-PR auto-merge | 2+ delegated PRs queued and per-PR rebase round-trips exceed review time |
| [`cloud-agent-environments`](plugins/cloud-delegation/skills/cloud-agent-environments/SKILL.md) | Operational reference — what each cloud agent can/can't reach (hex.pm, mix, Tidewave, HTTP), runtime gotchas, the AGENTS.md generation workflow | Deciding `[CX]` vs `[CSR]` eligibility, debugging a cloud-agent env failure |
| [`sprite-claude-code`](plugins/cloud-delegation/skills/sprite-claude-code/SKILL.md) | Operational reference for Fly Sprite-hosted Claude Code as a third delegation target — CLI surface, auth threading, reachability, cost ceiling | Using Sprite-hosted Claude Code for delegation |
| [`delegation-rules`](plugins/cloud-delegation/skills/delegation-rules/SKILL.md) | The five hard rules of delegation flows — don't-steal-`[CX]`/`[CSR]`-tasks, GH-native auto-merge (never synchronous `gh pr merge`), default-DO Linear/PR comments, never-push-to-`codex/*`, one-shot `cursor/*` force-push scope | Delegating to or reviewing cloud-agent work and need the guardrails (in repos that don't eager-import the include) |

### Git & contribution workflows

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`git-worktrees`](plugins/elixir/skills/git-worktrees/SKILL.md) | Run multiple Claude sessions in parallel via git worktrees — each gets its own working directory, no conflicts | Working on multiple features simultaneously, parallel refactors, isolating experiments |
| [`upstream-pr-workflow`](plugins/elixir/skills/upstream-pr-workflow/SKILL.md) | Contributing PRs to forked libraries without leaking personal tooling into the diff or letting project hooks enforce your standards on their code | Preparing a PR against an upstream fork |

### JavaScript on the BEAM

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`elixir-volt`](plugins/elixir/skills/elixir-volt/SKILL.md) | **Ecosystem map** + "when to use what" decision table for JS-on-BEAM (no Node.js) | Choosing between OXC / QuickBEAM / npm_ex / the Phoenix frontend stack — start here |
| [`oxc`](plugins/elixir/skills/oxc/SKILL.md) | OXC Rust NIF — parse/transform/bundle/minify JS/TS, ESTree AST navigation, codegen | JS/TS source analysis, AST work, TS-to-JS transformation |
| [`quickbeam`](plugins/elixir/skills/quickbeam/SKILL.md) | QuickBEAM JS runtime on the BEAM — eval/call, npm browser bundles, Elixir↔JS handler bridge, pools, DOM | Executing JS at runtime, loading npm bundles, bridging Elixir and JS |
| [`popcorn`](plugins/elixir/skills/popcorn/SKILL.md) | Popcorn — run Elixir in the browser via WebAssembly | Client-side Elixir apps, offline-first tools, privacy-preserving browser analytics |
| [`npm-ci-verify`](plugins/elixir/skills/npm-ci-verify/SKILL.md) | npm_ex CI/install verification — lockfile sync, frozen installs, reproducible builds | Setting up CI with npm_ex, debugging "works locally, fails in CI" |
| [`npm-dep-analysis`](plugins/elixir/skills/npm-dep-analysis/SKILL.md) | npm_ex graph analysis — size, fan-in/out, cycles, dedup, package quality scoring | node_modules too large, investigating why a package was pulled in |
| [`npm-security-audit`](plugins/elixir/skills/npm-security-audit/SKILL.md) | npm_ex security — CVE audit, license compliance (GPL/AGPL contamination), deprecations, supply-chain risk | Evaluating dependency security or license compliance |

### Static analysis

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`reach`](plugins/elixir/skills/reach/SKILL.md) | Reach PDG/SDG for Elixir/Erlang/Gleam/BEAM — slicing, taint analysis, dead-code detection, OTP state machines, call-graph visualization, codebase-level coupling/hotspot analysis | Static analysis, impact analysis, cross-language graph stitching |

### Designing APIs for AI agents

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`agent-economy`](plugins/elixir/skills/agent-economy/SKILL.md) | Descripex `api()` macro, `__api__/0` introspection, progressive disclosure (`describe/0..3`), JSON Schema generation, MCP tool surfacing, EIP-8004 trustless verification | Building APIs AI agents will call, annotating modules with `api()`, generating MCP tool lists |
| [`api-toolkit`](plugins/elixir/skills/api-toolkit/SKILL.md) | ApiToolkit — InboundLimiter, RateLimiter, Cache (TTL), Metrics, the `defapi` Provider DSL + auto-generated Discovery | Adding rate limiting, response caching, per-endpoint metrics, or defining API providers |

### Library-specific guides

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`zen-websocket`](plugins/elixir/skills/zen-websocket/SKILL.md) | ZenWebsocket — the 5 core functions, reconnection logic, heartbeats, trading-API patterns (Deribit, Binance) | Implementing WebSocket clients with reconnection |
| [`nexus-template`](plugins/phoenix/skills/nexus-template/SKILL.md) | Nexus Phoenix admin dashboard template — Iconify icons, layout pipelines, partials, Alpine.js | Building admin interfaces with Nexus |

### Also worth knowing

| Skill | What it gives you | Invoke when |
|---|---|---|
| [`integration-testing`](plugins/elixir/skills/integration-testing/SKILL.md) | Integration test patterns — credential handling, environment config, never-skip-silently discipline | Writing tests that call real APIs or need API keys |

## Commands

A few skills also have slash-command entry points (Claude Code only):

| Command | Backed by |
|---|---|
| `/staged-review:audit-review` | `audit-review` skill |
| `/staged-review:audit-status` | `unaudited-commits` helper — reports commits past the last audit ancestor |
| `/dev-lifecycle:dev-lifecycle` | `dev-lifecycle` skill |
| `/elixir-workflows:workflow-generator` | `workflow-generator` skill |
| `/git-commit:commit` | git-commit plugin — AI-powered commit file grouping |

## Installing

```bash
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install elixir@deltahedge          # 26 skills + hooks
/plugin install cloud-delegation@deltahedge # 8 delegation skills
/plugin install staged-review@deltahedge   # 2-skill review chain (pre-commit + post-merge; pre-merge is GH-native)
/plugin install task-driver@deltahedge     # task-driver + rmap + task-writing skills
# …see README.md for the full plugin list
```
