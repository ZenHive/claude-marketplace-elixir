# Changelog

All notable changes to the DeltaHedge Claude Code Plugin Marketplace.

## [Unreleased]

### Added

**`elixir-ci-harness` skill (new) — elixir plugin v1.22.0**
- New skill in the `elixir` plugin providing copy-ready GitHub Actions workflows for Elixir delegation-target repos. Runs format / compile (warnings-as-errors) / credo --strict --ignore TagTODO,TagFIXME / doctor --raise / sobelow / test.json with coverage gate (default 85%) / dialyzer on every PR push.
- **Drift-free version sourcing** — `setup-beam@v1` with `version-file: .tool-versions, version-type: strict` (no matrix-pin drift). Local + CI guaranteed identical Elixir/OTP versions, closing the `mix format` drift class (e.g. cartouche's current 1.18.4 CI vs 1.20-rc.4 dev).
- **Two template variants** — `harness.yml` (default, single-version, drift-free); `harness-multi-version.yml` (addendum, explicit matrix for forward-compat — catches dep-version issues at PR-open time so cloud agents fix autonomously). Worked example: cartouche's session-discovered insight that adding OTP 29-RC to a matrix would have caught a `meck` pin issue without a human round-trip.
- Documents threshold tuning (80% standard / 85% project default / 95% critical with cartouche's reasoning preserved), per-module 95% ratchet pattern, integration-tag exclusion, branch-trigger customization, required deps (ex_unit_json, dialyxir, doctor, sobelow), and TagTODO/FIXME design (tracked-debt visibility, not regression gating). Inline comments in the templates preserve cartouche's worked-example rationale verbatim.
- Skill count: 31 → 32. Elixir plugin version 1.21.1 → 1.22.0.


- New `cloud-delegation` plugin with two skills, both bodies auto-synced from canonical `~/.claude/includes/` sources:
  - `linear-workflow` — Linear-as-queue + cloud-agent delegation flows (Codex, Cursor), per-agent eligibility, polling for ready-to-review (PR-attachment is the authoritative signal), push-back-vs-fix-locally matrix split by agent capability, fetching existing comments from both the GitHub PR and the Linear issue, cross-repo coordination via `relatedTo` / `blocks`, issue-body-as-prompt template.
  - `cloud-agent-environments` — operational reference for what each cloud agent's harness can/can't reach (hex.pm, mix tasks, Tidewave, external HTTP), runtime gotchas (Cursor's Erlang/Elixir non-asdf paths, asdf shim interception, Credo TODO exit-code-2 expected behavior), self-validation expectations (Cursor SHOULD run the harness pre-PR; Codex can't), AGENTS.md generation workflow.
- Both skills added to `scripts/sync-skills-from-includes.sh` MAPPINGS and `scripts/sync-codex-plugins.py` (`PLUGIN_ORDER` + `PLUGIN_CONFIG`). No `skills:` allow-list — both sync to Codex wholesale (matches `staged-review` / `task-driver` pattern).
- Skill count: 29 → 31. Marketplace version bumped 1.1.0 → 1.2.0 (catalog structure change — adding a plugin is a registry-level change per project convention).

### Changed

**`commit-review` flipped to CI-as-gate + tiered + fast-path + push-back-first — staged-review v1.11.0**
- **Tier 2 framing** — skill description and new § "When to Invoke vs Defer to CodeRabbit" reserve `commit-review` for PRs that touch critical-tier code paths (signing, RPC, ABI, money, crypto, migrations) OR where CodeRabbit/Copilot (Tier 1) flagged ambiguity OR explicit user invocation. Routine PRs defer to CodeRabbit + CI. Stops paying CLI tokens for "everything looks fine" reviews.
- **Tiny-PR fast path (new Step 5.5)** — PRs <100 LOC with no `lib/` changes route to a 3-line verdict (CI check only, no 5-category audit, no Codex second-opinion offer). Reasoning surfaced in verdict so user knows *why* the audit was skipped. Override available for forced full machinery on small PRs.
- **CI-as-gate (Step 6)** — replaces "run full local harness" with `gh pr checks <number>` against the PR head. CI green → proceed; CI red → blocker (push-back default); CI absent → fall back to running the local harness inline AND surface a `TODO(setup-ci)` finding pointing at the new `elixir-ci-harness` skill so the next iteration of the PR has CI. Brief poll (`--watch --interval 30 --fail-fast`, ~5m cap) for in-flight checks.
- **Push-back-first posture (Step 7)** — default action on a blocker is push back to the agent (PR review for line-level findings, Linear comment for scope/intent drift), not local fix. Local fix is the exception, governed by a per-agent push-back-vs-fix-locally matrix that distinguishes Codex Cloud (no hex.pm / no Tidewave / no internet) from Cursor Cloud (hex.pm + mix tasks + internet).
- **Asymmetric push-back channels** — PR review = LINE-LEVEL CODE FEEDBACK (cite file:line, prefix `@codex`/`@cursor`); Linear comment = ONE PARAGRAPH ON SCOPE/INTENT MATCH. Never duplicate content across surfaces. Two channels exist because each has a different audience: PR for the implementing agent (line-level iteration), Linear for the dispatching user (scope verification). Drafts only — user posts; never auto-post.
- **Optional Codex CLI second-opinion (Step 10, default off)** — observed cost ~15m per PR, frequently exceeding implementation savings from delegation. Evaluator separation already comes from cloud-agent + CI + Claude (three parties); adding Codex CLI is a fourth opinion with diminishing returns. Surface as a one-line offer in the verdict for high-stakes PRs (auth, money, migrations, 95% critical tier).
- **`code-review` (pre-commit local) is untouched** — Codex CLI second-opinion stays mandatory there. That skill reviews code Claude itself just wrote — single-judge failure mode is the whole reason it exists. Different evaluator-separation problem.
- Workflow diagram updated with Step 5.5 (classification) routing fast-path PRs directly to verdict. Common Mistakes table extended with rows for Tier 2 misuse, fast-path bypass, channel duplication, auto-posting, per-agent reachability, and auto-dispatching second-opinion.
- Plugin version 1.10.0 → 1.11.0.

**Cross-reference updates in cloud-delegation includes**
- `~/.claude/includes/linear-workflow.md` § "Push-Back-vs-Fix-Locally Matrix by Agent": added "matrix is the exception list, not the default" note above the table — default action on a blocker is push-back; local fix is the exception governed by env constraints. With CI handling mechanical harness gates (via `elixir-ci-harness`), the local-fix surface shrinks further.
- `~/.claude/includes/cloud-agent-environments.md`: added § "CI as the Shared Harness" cross-referencing the `elixir-ci-harness` skill — when target repo has `harness.yml`, every PR push runs the full Elixir harness as a GitHub check. Closes the Codex-Cloud-no-hex.pm gap. Documents the shift this enables (reviewer reads `gh pr checks`; push-back becomes default; local-fix shrinks to env-constraint cases) and the adoption path (`templates/harness.yml` from `elixir-ci-harness` skill).
- Both auto-sync to `cloud-delegation` skill mirrors via `scripts/sync-skills-from-includes.sh`.

**Status-transition responsibility documented (Linear support clarification)**
- New `~/.claude/includes/linear-workflow.md` § "Agent Status-Transition Guidance" — Linear support confirmed that the "open PR → flip status to `In Review`" transition is the cloud agent's responsibility, not a built-in Linear setting. Linear syncs PR state from GitHub but does not auto-flip issue status. The canonical fix is to add an instruction under workspace-level (or team-level) "Additional guidance for agents" telling Cursor / Codex / future agents to perform the flip.
- Codex + Cursor delegation flows Step 2 cross-reference the new section. The broadened polling shape in § "Polling for 'Ready for Review'" is reframed as the **compensation pattern** for agents that don't read workspace guidance reliably; both layers can coexist (set the guidance AND keep the broader polling).
- Includes auto-synced into `cloud-delegation:linear-workflow` SKILL.md and `AGENTS.md`.

**Cloud-agent delegation rule broadened from `[CX]`-only to all cloud-agent markers**
- `~/.claude/includes/critical-rules.md` § "DON'T STEAL `[CX]` TASKS" → renamed "DON'T STEAL CLOUD-AGENT-DELEGATED TASKS." Body broadened to cover `[CX]` (Codex), `[CSR]` (Cursor), and any future cloud-agent delegation marker. New "How to apply" bullet warns against second-guessing per-agent eligibility (e.g. "Cursor could've done this Codex task — let me redirect" — don't, the user chose).
- `task-driver` SKILL.md Step 3.5 ("Cloud-Agent Delegation Router") expanded with parallel `[CX]` / `[CSR]` branches and a fallthrough for future markers. Cross-references in body + Common Mistakes table updated to the new heading.
- AGENTS.md regenerated so the inlined `critical-rules.md` content reflects the broader rule.

**Workspace-specific leak cleanup in global includes**
- Stripped workspace-specific identifiers (issue keys like `INE-7`, PR numbers like `PR #4`, comment hashes, project names) from `~/.claude/includes/linear-workflow.md` and `~/.claude/includes/cloud-agent-environments.md`. Per the includes' own `linear-workflow.md` § "Workspace-Specific Layout" convention, workspace specifics belong in `<workspace>-workspace.md` or per-repo `CLAUDE.md`, not generic global includes. Replacements use empirical-evidence phrasing ("verified in early Cursor round-trip testing", "observed failure mode") that survives without rotting.
- Cross-repo coordination examples in `linear-workflow.md` genericized — "Hieroglyph release → Cartouche bump" → "Library release → downstream-app bump."

**Comment-fetch broadening: GitHub PR comments + Linear issue comments**
- Renamed `linear-workflow.md` § "Fetch Existing PR Review Comments Before Auditing" → "Fetch Existing Comments Before Auditing." Added a Linear-comment-fetch sub-block (`mcp__linear-server__list_comments` / `get_issue`) alongside the existing `gh pr view` / `gh api` block. New triage list covers scope drift (Linear comment usually wins over original issue body), prior-reviewer notes, agent self-summary, and prior `@codex` / `@cursor` push-back rounds. Fixes the prior gap: the rule said "fetch upstream comments" but only covered GitHub PR comments, missing the Linear thread which carries delegating-user clarifications and prior push-back history.
- `staged-review:commit-review` SKILL.md updated to match: Step 5 retitled "Fetch Existing Comments — GitHub PR AND Linear Issue" with both sub-blocks; frontmatter `description:` mentions both streams; "Common Mistakes" row about Step 5 expanded; workflow diagram updated. Plugin version bumped 1.9.0 → 1.10.0 (backward-compatible skill update).

**staged-review v1.9.0: fetch upstream PR review comments + push-back-vs-fix-locally matrix in `commit-review`**
- New Step 5 in `commit-review`: before auditing, fetch existing PR review comments via `gh pr view --json reviews,comments` and `gh api repos/OWNER/REPO/pulls/<n>/comments`. Reviewer was previously running the audit blind to upstream feedback (Copilot, CodeRabbit, humans), duplicating their findings and missing context they had documented. Step 8 (the 5-category audit) now integrates the upstream comments — overlapping findings get attributed instead of re-flagged, disagreements surface in the verdict as `disputed`.
- Step 11 (verdict) now includes an explicit **push-back-vs-fix-locally matrix** for blockers. Codex cloud has no internet — no hex.pm, no Tidewave, no external HTTP — so hex-API correctness bugs (e.g. `assert_receive/3` vs `assert_received/2` in INE-6), live-data diagnosis, and external-spec lookups all fail under push-back. The matrix classifies each blocker by whether Codex *can* realistically fix it given its environment, with hybrid splits (some push-back, some fix-locally) as a first-class option.
- Codex cloud constraints documented canonically in `~/.claude/includes/linear-workflow.md` § "Codex Cloud Constraints" (no hex.pm / no Tidewave / no external HTTP) and § "Fetch Existing PR Review Comments Before Auditing" (the comment-fetch rule applies to all PR reviews, not just `commit-review`).
- `~/.claude/includes/task-prioritization.md` § "Codex Delegation `[CX]`" criteria gained a new bullet: "no hex-docs lookup required for niche or version-pinned third-party APIs." Auto-syncs to `roadmap-planning/SKILL.md`.
- Plugin version 1.8.0 → 1.9.0.

**staged-review v1.8.0: broaden `commit-review` polling to use PR-attachment as authoritative signal**
- `commit-review` Step 2 now polls `delegate = Codex AND status ∈ {In Review, In Progress}`, then filters to issues with at least one open GitHub PR attachment. Codex's status transitions are unreliable across observed round-trips (sometimes stays at `Backlog`, sometimes opens PR but stays at `In Progress`), so the PR attachment is the load-bearing signal — Linear status is just a cached version that Codex isn't writing reliably.
- Results grouped into "`In Review` (canonical)" and "`In Progress` with open PR (non-canonical)" so the reviewer/user knows which issues need a manual status flip post-review.
- Documented the polling shape canonically in `~/.claude/includes/linear-workflow.md` § "Polling for 'Ready for Review'" so future skills/sessions matching this pattern (any cloud-agent → Linear → reviewer flow with best-effort transitions) follow the same shape.
- Plugin version 1.7.0 → 1.8.0.

### Added

**Codex delegation workflow (Phase 9)**
- New `[CX]` task marker in `task-prioritization.md` — default-on for tasks meeting all criteria (self-contained, no Tidewave / live-data needs, no dep changes, no `.mcp.json`/hooks/CI changes, spec fully captured in Linear). Counterweight to Claude's bias to grab work locally. Auto-syncs to `roadmap-planning/SKILL.md`.
- Two new `critical-rules.md` sections: "🚨 DON'T STEAL `[CX]` TASKS" (skip `[CX]` rows from ROADMAP.md unless user explicitly redirects) and "🚨 DON'T AUTO-MERGE PRS" (`commit-review` produces a verdict; user merges).
- `scripts/sync-agents-md.sh` — generates per-repo `AGENTS.md` for Codex by inlining the project CLAUDE.md's `@`-imports. Run from inside the target repo. Codex receives the same rules our local hooks would have enforced (testing discipline, format, coverage gate, no-fabrication, etc.). `--dry-run` flag, exit-1 on missing/unreadable imports.
- `plugins/staged-review/skills/commit-review/SKILL.md` — sibling of `code-review` for cloud-agent PR review. Polls Linear `In Review` issues delegated to Codex, fetches PR via `gh pr checkout`, runs full local harness (Codex's output drifts on credo/dialyzer/format since it lacks our hooks), runs the same 5-category audit + Codex second-opinion as `code-review`, presents verdict (✅ ready / ⚠️ blockers / 💬 discussion). Offers Linear comment post; user merges.
- `plugins/elixir/scripts/check-branch-behind-origin.sh` + `SessionStart` registration in `hooks.json` (first SessionStart hook in the elixir plugin) — `git fetch origin main` and warn if the working branch is behind, so Claude rebases before claiming a roadmap task that Codex may have advanced. Fails open on no-repo / fetch errors.
- `task-driver` SKILL.md updated with Step 3.5 router branch: `[CX]` + `🔄 in-review` → invoke `commit-review` and exit; `[CX]` + `⬜` → halt and ask "delegate via Linear or redirect to local?"; otherwise existing local flow.

**5 new skills synced from `~/.claude/includes/`** (elixir plugin: 18 → 23)
- `reach` — Reach PDG/SDG (program dependence graph) for Elixir/Erlang/Gleam/BEAM. Backward/forward slicing, taint analysis, dead-code detection, OTP state-machine analysis, `mix reach` HTML viz, codebase-level analysis (coupling, hotspots, depth, effects, xref, boundaries, concurrency).
- `elixir-volt` — Elixir-Volt ecosystem map (JS on the BEAM without Node.js). Routes to OXC, QuickBEAM, npm_ex, and the Phoenix frontend stack (volt, oxide_ex, vize_ex, phoenix_vapor).
- `agent-economy` — Designing APIs for AI agent consumers using Descripex (`api()` macro, progressive disclosure, MCP tool generation, EIP-8004 trustless verification).
- `api-toolkit` — Reusable infrastructure for Elixir API services. InboundLimiter (sliding window), RateLimiter (token bucket), Cache (TTL ETS), Metrics, Provider DSL with `defapi`, Discovery generating 8 functions.
- `upstream-pr-workflow` — Contributing PRs to forked external libraries without leaking personal dev tooling stack into the diff. Worktree vs separate-clone setup, additive-vs-mandate distinction, alias-based hook bypass.
- All 5 added to `scripts/sync-skills-from-includes.sh` MAPPINGS (15 → 20 mapped skills). Bodies auto-sync from canonical includes; only frontmatter is hand-written. CLAUDE.md skill table updated (23 → 28 total).

**Codex integration state handoff**
- Added `codex_hooks_state.md` at the repo root. It records the verified local
  Codex plugin/hook state, what works today (skills + Bash hooks), what does
  not yet work in the released path we tested (edit-time hooks), and the
  upstream tracking links for `apply_patch` hook support.

**Codex plugin sync script**
- Added `scripts/sync-codex-plugins.py` — generates a Codex-friendly subset of this marketplace at `~/plugins/` and `~/.agents/plugins/marketplace.json`. Transforms markdown (strips `allowed-tools:` frontmatter; renames `Claude Code`, `AskUserQuestion`, `TodoWrite`/`TaskCreate`/`TaskUpdate`, `SlashCommand` to Codex equivalents), filters the `elixir` plugin's hooks to Bash + UserPromptSubmit only, rewrites hook commands to absolute paths under the destination root, and emits a `.codex-plugin/plugin.json` per plugin.
- Syncs the `elixir`, `phoenix`, `staged-review`, `task-driver`, and `portfolio-strategy` plugins. The elixir subset is narrowed further via explicit allow-lists (6 skills, 8 scripts) to exclude Claude-only tooling.
- CLI modes: `--dry-run` (default), `--apply`, `--plugin` (repeatable), `--marketplace-only`, `--skip-core-sync`. Delegates include→skill sync to `~/.codex/skills/sync-claude-includes/scripts/sync_claude_includes.py`.
- Added `test/test-sync-codex-plugins.sh` (4 test cases: dry-run no-write, full apply, filtered plugin sync, marketplace-only). Registered in `test/run-all-tests.sh`.
- **Known limitation:** the markdown replacement table translates tool names, not workflow concepts. Synced `task-driver` and `staged-review:code-review` skills still reference Claude Code plan-mode (`EnterPlanMode`/`ExitPlanMode`); synced `hex-docs-search` still references `WebSearch`. Codex users of those skills will encounter nonexistent tools until a Codex-native rewrite or exclusion decision is made.

### Changed

**staged-review v1.4.0: reviewer writes doc updates instead of just flagging gaps**
- Reverses the prior "report doc gaps but don't write them" stance. Doc updates now flow through the same path as every other finding: Category 6 row in the findings table → rated → included in the plan-mode batch (Step 7) → applied on plan exit. Nothing is edited silently — the user sees the proposed `ROADMAP.md` / `CHANGELOG.md` / `CLAUDE.md` / `README.md` edits before approving.
- Why the change: the prior rule's "committer's mental model diverges" concern is preserved by plan-mode visibility (user reviews the doc edits in the same batch as the code edits) and by Step 8 leaving reviewer edits unstaged so the committer still inspects via `git diff` before `git add`. The cost the prior rule paid — doc gaps that committers forget to fill in a separate pass — was happening in practice.
- Added **Category 6: Documentation Gaps** with explicit rating defaults (CHANGELOG entry 5-7, ROADMAP status flip 6-8, CLAUDE.md drift 7-9, README drift 6-8, cosmetic 1-2). Includes a "don't invent activity" guard: if the diff doesn't actually complete the task, don't flip ROADMAP; if you can't summarize without speculation, mark `discuss`.
- Scope section flipped: doc updates now appear in "WHAT THIS SKILL DOES" with explicit ROADMAP/CHANGELOG/CLAUDE.md/README.md naming. The "Why review-only on docs" rationale paragraph replaced with "Doc updates are findings, not silent edits" explaining how plan-mode visibility preserves the prior concern.
- Common Mistakes rewritten: removed "silently updating CHANGELOG/ROADMAP" (the new rule); added three replacements covering (a) silent updates without showing the user, (b) inventing doc activity the diff doesn't justify, (c) staging the reviewer's doc edits.
- Example findings table extended with two `doc-gap` rows.
- Plugin: `1.3.1 → 1.4.0`. Minor bump — workflow gains a category and changes a "don't" to a "do," backward-compatible at the skill invocation layer.

**staged-review v1.3.1: bias toward Codex dispatch + mandatory tool inventory in every dispatch**
- Addresses two residual gaps observed after v1.3.0 shipped: (1) Claude sessions still wait to be asked before dispatching Codex during a work session; (2) when Codex is invoked, Claude doesn't brief it on project-local tools, so Codex reasons from training data alone and over-flags.
- Added "Bias toward dispatch" paragraph under **Second-Opinion Review (Required)**: default answer to "should I ask Codex?" is yes; silent misses are the non-asking failure mode.
- Added new **Dispatch Payload** subsection specifying the four required sections of every `codex:codex-rescue` prompt: Task, Context, Project tool inventory (MCP servers like Tidewave, mix tasks for verification, hex-docs `/llms.txt` URLs, mix aliases), Verification instruction ("verify before asserting; training-data recall is insufficient").
- Step 3b amended to require the dispatch payload. Step 9's dialogue dispatch rewritten to follow the same format.
- Two new Common Mistakes rows: "Under-consulting Codex in-session (waiting for the user to say 'ask Codex')" and "Dispatching Codex without the project tool inventory."
- Plugin: `1.3.0 → 1.3.1`. Patch — refinements within existing Codex dispatch steps, no workflow renumbering.

**staged-review v1.3.0: mandatory Codex second-opinion + Claude+Codex dialogue for discuss-tier**
- Flipped Codex from opt-in to required. Observation driving the change: left optional, the second-opinion pass was never invoked — neither user nor Claude thought to ask. The opt-in framing looked reasonable but produced a single-reviewer pass every time.
- Workflow now dispatches `codex:codex-rescue` in parallel with Claude's own Category 1-5 review (Step 3b), merges both findings sets at Step 4 (Codex-only items default to `discuss` until verified against real code — calibration preserved: Codex over-flags, Claude under-flags).
- Discuss-tier no longer defaults to "ask the user." Step 9 is now a Claude+Codex dialogue with ROADMAP.md in scope: convergence applies the fix with recorded reasoning; divergence escalates to the user. User becomes the escalation target, not the first responder — preserves attention for genuine design disagreements.
- Closing summary now states `dual-reviewer pass` or `Codex unreachable — single-reviewer pass` (honest either way; no silent fallback).
- Step numbering: 3 → 3a/3b, inserted Step 4 (merge), shifted 4-9 → 5-10.
- Plugin: `1.2.1 → 1.3.0`. Minor bump — workflow behavior change, backward-compatible at the skill invocation layer.

### Removed

**Orphaned skills retired (Opus 4.7 selective-load philosophy)**
- `~/.claude/includes/` was pruned for the Opus 4.7 (Jan 2026 cutoff) training window: generic Phoenix 1.8 / LiveView / daisyUI 5 / macro patterns now live in the model, so their corresponding includes were dropped from the canonical set. This marketplace hosted 6 skills whose source includes no longer exist, leaving them as self-asserting empty-shell discovery surfaces
- Retired the following skills (last-existed at commit `56c950e`, resurrect via `git show 56c950e:<path>` if a model gap is later discovered):
  - `plugins/elixir/skills/api-consumer` — generic REST API wrapper macro patterns (training-data covered)
  - `plugins/elixir/skills/meta-development` — generic Elixir macros / code generators (hexdocs canonical, training-data covered)
  - `plugins/phoenix/skills/phoenix-js` — Phoenix JS hooks, channels, presence (hexdocs verbatim, training-data covered)
  - `plugins/phoenix/skills/phoenix-patterns` — Phoenix 1.8 / LiveView forms / streams / HEEx (training-data covered)
  - `plugins/phoenix/skills/phoenix-scope` — Phoenix 1.8 Scope struct (training-data covered)
  - `plugins/phoenix/skills/daisyui` — daisyUI 5 + Tailwind v4 component patterns (training-data covered)
- Preserved 3 proprietary `references/` files (describing methodology for the sibling `ccxt_client` and `ccxt_extract` projects, not in any training corpus) to `docs/archive/ccxt/` — long-term these belong in the owning repos at `../ccxt_client` and `../ccxt_extract`
- Removed the 6 corresponding mappings from `scripts/sync-skills-from-includes.sh`
- Removed 3 broken `@` imports from marketplace `CLAUDE.md` (`elixir-patterns.md`, `library-design.md`, `meta-development.md` — retired from `~/.claude/includes/` in the same pruning pass)
- Removed `daisyui` from `plugins/phoenix/.claude-plugin/plugin.json` keywords
- `elixir` plugin bumped to 1.20.0; `phoenix` plugin bumped to 1.1.0. No marketplace-level version bump (catalog structure unchanged — no plugins added or removed)
- Corrected a pre-existing skill-count undercount in `CLAUDE.md` and `README.md` tables (5 Elixir skills existed on disk but were absent from the tables: `oxc`, `quickbeam`, `npm-ci-verify`, `npm-security-audit`, `npm-dep-analysis`). New documented totals: Elixir **18**, Phoenix **2**, marketplace **23**

### Added

**code-quality Plugin** (extracted from elixir plugin)
- New standalone plugin at `plugins/code-quality/` containing the language-agnostic LLM-based code quality gate (PreToolUse `type: prompt` hook)
- Blocks untracked TODO/FIXME markers, unmarked deferred-work comments, stub functions, and silent workarounds on source files across Elixir, Go, Rust, JS/TS, Python, Ruby, Java, and C/C++
- Can now be installed on non-Elixir projects without pulling in `mix`-based tooling
- Marketplace bumped to 1.1.0 (new plugin); elixir plugin bumped to 1.19.0 (hook removed)

**Setup Guide Sync Check Script**
- Added `scripts/check-setup-guide.sh` — compares `~/.claude/setup-guide.md` against actual files in `~/.claude/includes/`, reports drift (undocumented or missing includes)
- Supports `--quiet` flag for CI/scripting (exit code only)
- Companion to `sync-skills-from-includes.sh` for marketplace maintenance

**SessionStart Prompt Hook** (user settings, not in repo)
- Added prompt-based SessionStart hook to `~/.claude/settings.json` that checks per-project CLAUDE.md includes against the project's detected stack

**Workflow Philosophy Integration**
- Created `~/.claude/includes/workflow-philosophy.md` — language-agnostic workflow principles derived from Anthropic's ["Harness Design for Long-Running Apps"](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- Session-per-phase model, acceptance criteria requirements, evaluator separation, model assumption tagging, workflow routing table, layered architecture diagram
- Imported in project CLAUDE.md via `@~/.claude/includes/workflow-philosophy.md`

### Changed

**CLAUDE.md: Include-set pruning**
- Removed `@` imports for retired includes `documentation-guidelines.md` and `ai-coder-docs.md` (archived to `~/.claude/includes/_retired/` — content was generic philosophy already covered by training data)
- Four includes condensed in place at the canonical location, preserving post-training knowledge (Phoenix 1.8 patterns, daisyUI 5, Tito's Hex package conventions) and opinionated Elixir style: `code-style.md`, `development-philosophy.md`, `library-design.md`, `task-writing.md`
- No mirrored copy exists in this repo; `~/.claude/includes/` remains canonical
- SKILL.md cross-references to `task-writing.md` (roadmap-planning) and `library-design.md` (api-consumer) still resolve — condensed versions retain the referenced sections

**Sync skills with canonical includes** (pre-existing drift cleanup)
- Ran `scripts/sync-skills-from-includes.sh` to reconcile drift accumulated from prior include edits — not caused by the pruning task above, but surfaced while verifying the pruning was sync-neutral
- Updated skill bodies (frontmatter preserved) for: `meta-development`, `api-consumer` (← `api-integration.md`), `development-commands`, `elixir-setup`, `oxc`, `quickbeam`, `npm-ci-verify`, `npm-security-audit`, `npm-dep-analysis`

**WORKFLOWS.md: Layered Architecture and Routing**
- Added architecture section documenting the layered model (global includes → universal skills → Elixir commands → hooks)
- Added session-per-phase model guidance with file handoff patterns
- Added routing table: when to use task-driver vs elixir-plan vs code-review vs elixir-qa

**README.md: Architecture and Plugin Organization**
- Added "Architecture" section explaining layered model and workflow philosophy
- Added "Workflow Model" section showing session-per-phase pattern
- Reorganized plugin table into "Universal" (staged-review, task-driver, git-commit, notifications) and "Elixir/Phoenix" categories

**Hook Rationale Tags** (elixir plugin README)
- Tagged all hooks as `[convention]` (permanent quality gate) or `[model-limitation]` (review when models improve)
- Convention: auto-format, compile check, hidden failure detection, typespec/typedoc checks, pre-commit validation, prefer-test-json, prefer-dialyzer-json
- Model-limitation: documentation recommendation on read, suggest --failed, documentation recommendation on prompt

**elixir-plan Command: Acceptance Criteria and D/B/U Scoring**
- Added mandatory "Acceptance Criteria" section to plan template — specific, verifiable outcomes for QA validation
- Fixed D/B scoring to use D/B/U formula: `[D:X/B:Y/U:Z → Eff:W]` where Eff = (B + U) / (2 x D)
- Added note that plans are session artifacts read by fresh implement sessions

**elixir-implement Command: Task-Driver Patterns**
- Added doc update requirements (ROADMAP, CHANGELOG, CLAUDE.md, README) as mandatory implementation step
- Added `TODO(Task N):` marker pattern for discovered work during implementation
- Added note that implementation reads plan artifacts from `.thoughts/` as a fresh session

**elixir-qa Command: Evaluator Role and Plan Validation**
- Documented evaluator separation principle — QA is the evaluator, never let the implementer grade its own work
- Added plan-specific validation: reads `.thoughts/plans/` acceptance criteria and checks each
- Referenced `staged-review:code-review` skill for code analysis

**elixir-oneshot Command: Scope Guidance**
- Added scope guidance: recommended for small-medium tasks only
- Added recommendation to use session-per-phase model for large features (5+ files, multiple architectural decisions)
- Added concrete example of separate-session workflow

**5 New Skills: OXC, QuickBEAM, npm_ex trilogy** (elixir plugin)
- **oxc**: OXC Elixir bindings for parsing, transforming, bundling, and minifying JS/TS via Rust NIFs — ESTree AST navigation, class hierarchy extraction, code generation, walk/postwalk/collect traversal, patch_string
- **quickbeam**: QuickBEAM JavaScript runtime for the BEAM — run JS libraries, npm packages, and async code inside Elixir GenServers via Zig NIFs. Covers start/eval/call lifecycle, handler pattern, Pool/ContextPool, correct browser global stub pattern
- **npm-ci-verify**: npm_ex CI/CD and installation verification — mix npm.ci, npm.check, npm.verify, npm.doctor, npm.shrinkwrap, --frozen flag
- **npm-security-audit**: npm_ex security auditing and supply chain assessment — mix npm.audit, npm.licenses, npm.deprecations, CVE scanning, license compliance
- **npm-dep-analysis**: npm_ex dependency graph analysis and size optimization — mix npm.stats, npm.size, npm.tree, npm.why, npm.dedupe, package quality scoring
- All synced from canonical includes via `scripts/sync-skills-from-includes.sh`

### Changed

**Sync script updated for 5 new skill mappings**
- Added oxc, quickbeam, npm-ci-verify, npm-security-audit, npm-dep-analysis to include-skill sync mappings (15 → 20 mappings)

**Roadmap-planning skill: full doc update checklist** (elixir v1.17.4)
- Added all 5 docs to the "When completing a task" checklist: ROADMAP.md, CHANGELOG.md, CLAUDE.md, README.md, and project-specific tracking docs
- Previously only covered ROADMAP.md and CHANGELOG.md archiving
- Synced from canonical include `~/.claude/includes/task-prioritization.md`

**New Plugin: task-driver** (task-driver v1.0.0)
- Roadmap-driven task execution workflow — reads ROADMAP.md, selects tasks by D/B efficiency, enters plan mode for user approval, implements with TodoWrite tracking
- Adds `TODO(Task N):` markers for discovered work during implementation, with corresponding ROADMAP.md entries
- Updates all project docs after implementation: ROADMAP.md (status), CHANGELOG.md (entry), CLAUDE.md (if architecture changed), README.md (if user-facing)
- Language-agnostic — works with any project that has a ROADMAP.md
- Marketplace version: 1.0.8 → 1.0.9

**New Plugin: staged-review** (staged-review v1.0.0)
- Universal code review workflow skill — language-agnostic, works with Elixir, Rust, Go, or any language
- Reviews `git diff --staged` against 5 categories: bugs, missing extractions (code AND data), TODO markers referencing ROADMAP.md tasks, abstraction opportunities (3+ patterns), and actionable TODOs
- Each finding rated 1-10 priority; actionable items fixed directly
- Complements existing language-specific commands (`/elixir-code-review`, `/rust-code-review`) as deep-dive references
- Marketplace version: 1.0.7 → 1.0.8

**Anti-Evasion Rules in critical-rules.md** (global include)
- Added "No Evasion — Sit With The Hard Thing" section to `~/.claude/includes/critical-rules.md`
- Documents evasion patterns: task abandonment, scope reduction, false completion, deflection to user
- Provides "what to do instead" rules — stay with it, flag blockers, ask before deferring, never write workarounds silently
- Fires at thinking time (preventive) — complements the reactive prompt hook and stop hook

**Structural Stop Hook** (global hookify rule)
- `~/.claude/hookify.unfinished-work.local.md` — blocks session stop when unfinished work exists
- Checks for: incomplete tasks, unresolved TODOs, deferred/skipped work, unresolved test failures
- Structural check (state-based), not phrase-matching — harder for Claude to evade
- Global rule — applies across all projects

**Prompt-based Code Quality Hook** (elixir v1.17.0)
- First prompt-based hook in the marketplace — uses LLM reasoning instead of bash scripts
- Blocking PreToolUse hook on Edit/Write/MultiEdit checks for three issues in a single pass:
  1. **Missing TODO markers**: comments with temporary implementations, workarounds, or production references lacking TODO/FIXME prefix (includes deferred/postponed/skipped patterns)
  2. **Stub functions**: functions that look complete but return hardcoded values, ignore parameters, or have placeholder comments as their only body
  3. **Silent workarounds**: code that masks problems instead of fixing them — try/rescue without re-raise, nil guards hiding upstream bugs, generic error fallbacks. Requires TODO pointing to the source if fix is in another file
- Language-agnostic: works across all comment syntaxes (`#`, `//`, `/* */`, `--`)
- Smart: only flags comments (not string literals) and distinguishes stubs from intentionally simple functions

**Corresponding Test Execution in Post-Edit Hook** (elixir v1.15.0)
- Post-edit hook now runs `mix test.json` on the matching test file after every edit
- Maps `lib/foo.ex` → `test/foo_test.exs` automatically; runs test files directly when edited
- Skips silently when no matching test exists or ex_unit_json is not installed

### Changed

**Backport Skill Knowledge to Canonical Includes**
- Rewrote 4 include files with condensed knowledge from skills + references, grounded in ccxt_ex/ccxt_client real-world patterns:
  - `zen-websocket.md`: Added error categories, reconnection behavior, three-layer architecture, heartbeat types, common issues, DO NOT rules
  - `meta-development.md`: Added macro decision tree, two-stage macro pattern, `Macro.escape`, `@external_resource`, function head dispatch, pattern-based architecture, introspection functions, debugging/testing macros
  - `api-integration.md`: Added scope boundary, decision tree, declarative macro tuple format, shared dispatcher, layered abstraction, sync checking, fixture generation, compile-time test generation
  - `phoenix-js.md`: Added Phoenix Channels, Presence tracking, DOM patching, debugging, modal focus trap, phx-* attributes reference, colocated hooks
- Created `scripts/sync-skills-from-includes.sh`: Automated sync of 15 skill-include pairs (preserves SKILL.md frontmatter, replaces body)
- Fixed stale `core:` namespace references → `elixir:` across 9 files (agents, hook scripts, workflow templates)

### Removed

**md-includes Plugin (Retired)**
- Removed md-includes plugin — Claude Code now natively supports `@path/to/file` imports in CLAUDE.md (added mid-2025)
- The plugin was a workaround (`@include` syntax) that is no longer needed
- Migrated project CLAUDE.md from `@include ~/.claude/includes/foo.md` to native `@~/.claude/includes/foo.md` syntax
- See: https://code.claude.com/docs/en/memory#import-additional-files
- Marketplace version: 1.0.6 → 1.0.7

### Changed

**Documentation Updates (Tasks 12 & 13)**
- Updated CLAUDE.md skills section: expanded from 3 documented skills to all 21, organized by plugin with table format (elixir: 14, phoenix: 6, elixir-workflows: 1)
- Added "Available Skills (21)" section to README.md with complete skill inventory grouped by plugin
- Updated elixir plugin description in README.md to reference 14 skills
- Roadmap: 27/27 tasks complete (100%)

### Added

**AI-Coder-Docs Scope Sections (Task 25)**
- Added `## Scope` (Does/Does Not) boundary sections to 8 skills: usage-rules, hex-docs-search, web-command, api-consumer, integration-testing, elixir-setup, tidewave-guide, workflow-generator
- Added reciprocal scope section to phoenix-setup for elixir-setup cross-reference
- Bidirectional cross-references between confused-pair skills (usage-rules ↔ hex-docs-search, elixir-setup ↔ phoenix-setup)

### Changed

**Sync Skills with Updated Includes (Task 27)**
- Fixed `web-command` skill: Removed "NEVER use WebFetch" contradiction, aligned with canonical dual-tool guidance (WebFetch for read-only docs/articles, `web` for interactions/forms/JS/LiveView)
- Updated `elixir-setup` skill: Added ex_unit_json, dialyzer_json, descripex deps; added cli/0 section; updated dep versions (styler ~> 1.4, ex_doc ~> 0.39, doctor ~> 0.22, bandit ~> 1.10); updated quality gates and quick reference commands
- Fixed stale `core:phoenix-js` namespace references to `phoenix:phoenix-js` in user includes (phoenix-js.md, skills-awareness.md)
- elixir: 1.13.11 -> 1.13.12, phoenix: 1.0.2 -> 1.0.3

### Added

**New Skills (Task 27)**
- **ex-unit-json** (elixir@deltahedge): AI-friendly test output with `mix test.json` — flags, workflows, output schema, jq patterns, troubleshooting
- **dialyzer-json** (elixir@deltahedge): AI-friendly Dialyzer output with `mix dialyzer.json` — fix hints (code/spec/pattern), grouping, filtering
- **phoenix-setup** (phoenix@deltahedge): Phoenix project setup — critical `--live` flag for phx.gen.auth, Sobelow, LiveDebugger, formatter config, Tidewave endpoint plug
- **development-commands** (elixir@deltahedge): Mix commands reference — test.json, dialyzer.json, credo JSON, Phoenix --binary-id, production builds

### Changed

**Progressive Disclosure for Oversized Skills (Task 23)**
- Refactored 4 oversized skills by extracting detailed content to `references/` subdirectories
- phoenix-js: 845 -> 316 lines (channels, presence, common patterns, attributes reference extracted)
- workflow-generator: 842 -> 186 lines (command generation steps, WORKFLOWS.md template, usage instructions extracted)
- api-consumer: 817 -> 237 lines (layered abstraction, sync/fixtures, OpenAPI generation extracted)
- usage-rules: 624 -> 159 lines (5 detailed examples and troubleshooting extracted)
- 11 reference files created across 4 skills (1,439 lines total)
- Evaluated and kept 3 borderline skills as-is: roadmap-planning (576), popcorn (538), zen-websocket (528)
- elixir: 1.13.10 -> 1.13.11, phoenix: 1.0.1 -> 1.0.2, elixir-workflows: 1.0.4 -> 1.0.5

**Skill Description Optimization (Task 24)**
- Rewrote all 17 skill YAML descriptions with pushy trigger language
- Added "ALWAYS invoke" / "Use when" imperative triggers to combat undertriggering
- Fixed web-command description contradiction ("NEVER use WebFetch" → correct guidance)
- Added concrete trigger scenarios (e.g., "mix new", "IEx", "phx-hook", "to_form/2")
- Added cross-references between confused pairs (usage-rules ↔ hex-docs-search)
- elixir: 1.13.9 → 1.13.10, phoenix: 1.0.0 → 1.0.1, elixir-workflows: 1.0.3 → 1.0.4

### Added

**dialyzer_json Support**
- New PreToolUse hook `prefer-dialyzer-json.sh` blocks `mix dialyzer` and redirects to `mix dialyzer.json`
- Updated `pre-commit-unified.sh` to use `mix dialyzer.json --quiet` for AI-friendly JSON output
- Filters for `fix_hint == "code"` warnings only (real bugs, not spec issues)
- Projects without `dialyzer_json` dependency skip dialyzer check entirely (no fallback)
- Provides installation instructions when blocked
- elixir: 1.13.8 → 1.13.9

### Changed

**Concise output for Credo and Doctor in hooks**
- Added `--format oneline --no-color` to Credo commands for single-line output
- Added `--summary --failed` to Doctor commands for focused failure reporting
- Reduces noise in hook feedback, makes issues more actionable
- Updated both `post-edit-check.sh` and `pre-commit-unified.sh`
- elixir: 1.13.7 → 1.13.8

### Fixed

**Post-edit struct hint grep failure**
- Fixed `post-edit-check.sh` struct hint heuristic failing when no map patterns found
- Added `|| true` to grep pipeline to handle empty matches with `set -eo pipefail`
- elixir: 1.13.4 → 1.13.5

**Pre-commit hook suppressOutput**
- Fixed `pre-commit-unified.sh` not emitting `{"suppressOutput": true}` for non-commit commands
- Hooks should always emit proper JSON output, not exit silently
- elixir: 1.13.3 → 1.13.4

**Test Suite for Consolidated Hooks**
- Updated test suite to use consolidated hooks instead of deprecated scripts
- Replaced references to `auto-format.sh`, `compile-check.sh`, `pre-commit-check.sh`
- Now tests `post-edit-check.sh` and `pre-commit-unified.sh`
- Removed broken reference to non-existent `precommit-test-pass` fixture
- Updated test README with all 9 active hook scripts and their behaviors
- 30 tests passing

**Plugin Cache Shared Library Bug**
- Fixed post-edit hooks failing in cached plugins due to missing `_shared/` directory
- Changed `post-edit-check.sh` and `ash-codegen-check.sh` to use local `../lib/` instead of `../../_shared/`
- Elixir plugin is now fully self-contained and works correctly when cached
- elixir: 1.13.0 → 1.13.1

### Changed

**Post-Edit Hook Consolidation (12 → 2 hooks)**
- Consolidated 12 post-edit hooks into 2 focused scripts (83% reduction)
- New `post-edit-check.sh`: format, compile, credo, sobelow, doctor, struct-hint, hidden-failures, mixexs-check
- New `ash-codegen-check.sh`: Ash codegen validation (only runs if Ash dep exists)
- Doctor now replaces grep-based typespec/typedoc/private-docs checks (authoritative source)
- **Fail loud**: Errors immediately if credo, sobelow, or doctor deps missing (required, not optional)
- Dialyzer stays pre-commit only (too slow for post-edit at 2-10+ seconds)
- Archived 8 deprecated scripts to `plugins/core/scripts/_deprecated/`
- Updated hooks.json in: core, credo, sobelow, ash, struct-reminder
- core: 1.11.0 → 1.12.0

**Pre-Commit Hook Consolidation (10 → 1 hook)**
- Consolidated 10 pre-commit hooks into 1 unified script (90% reduction)
- New `pre-commit-unified.sh` runs ALL quality checks in sequence:
  - Always: format, compile, deps.unlock, credo
  - If test/ exists: mix test --stale
  - If deps exist: doctor, sobelow, dialyzer, mix_audit, ash.codegen, ex_doc
- Defers to `mix precommit` alias if it exists (Phoenix 1.8+ standard)
- 180s timeout to accommodate dialyzer analysis time
- Emptied hooks in: credo, dialyzer, sobelow, ex_doc, mix_audit, ex_unit, precommit, doctor, ash
- Archived 10 deprecated scripts to respective `_deprecated/` directories
- core: 1.12.0 → 1.13.0

**Plugin Consolidation (17 → 7 plugins)**
- Deleted 10 empty shell plugins (credo, dialyzer, sobelow, ex_doc, mix_audit, ex_unit, precommit, doctor, ash, struct-reminder)
- Renamed 4 plugins for clarity:
  - core → elixir (main Elixir hooks + skills)
  - elixir-meta → elixir-workflows (workflow commands)
  - git → git-commit (commit workflow)
  - claude-md-includes → md-includes (include processing)
- 59% reduction in plugin count
- Updated all cross-references in CLAUDE.md, README.md, plugin READMEs, test files
- Marketplace version: 1.0.5 → 1.0.6

**scripts/clear-cache.sh**
- Now also cleans orphaned `@deltahedge` entries from `~/.claude/settings.json` enabledPlugins

### Added

**New Plugin: phoenix**
- Extracted 5 Phoenix-specific skills from core plugin
- Skills: phoenix-patterns, phoenix-scope, phoenix-js, daisyui, nexus-template
- Non-Phoenix projects no longer see irrelevant skills
- Location: `plugins/phoenix/`

**New Plugin: elixir-lsp**
- Expert LSP integration - the official Elixir language server
- Configures Claude Code's LSP tool for Elixir files (.ex, .exs, .heex, .leex)
- Enables: go-to-definition, find-references, hover, document/workspace symbols
- Expert is the merger of elixir-ls, Lexical, and Next LS
- Location: `plugins/elixir-lsp/`

**New Plugin: notifications**
- Native OS notifications when Claude Code needs attention
- Triggers on `idle_prompt` (60+ seconds waiting) and `permission_prompt`
- Cross-platform support: macOS (osascript), Linux (notify-send), Windows (PowerShell)
- Works with any terminal (Ghostty, Alacritty, Kitty, etc.)
- Location: `plugins/notifications/`

**New Plugin: serena**
- MCP auto-activation plugin for Serena language server integration
- SessionStart hook detects Serena MCP and prompts project activation
- Project mapping feature stores Serena project paths for directories
- Think reminder hooks for collected information, task adherence, and completion
- Commands: `/serena:status`, `/serena:memory`, `/serena:project-map`, `/serena:prep-handoff`
- Location: `plugins/serena/`

**New Skills**
- **daisyui** (core@deltahedge): daisyUI 5 + Tailwind CSS v4 component library reference
  - Semantic color system, theming, component patterns
  - Location: `plugins/core/skills/daisyui/`
- **nexus-template** (core@deltahedge): Nexus Phoenix admin template architecture
  - Iconify icons, partials system, layout pipelines, Alpine.js
  - Location: `plugins/core/skills/nexus-template/`
- **phoenix-js** (core@deltahedge): Phoenix JavaScript patterns
  - Client hooks, JS commands, channels, presence, optimistic UIs
  - Location: `plugins/core/skills/phoenix-js/`
- **integration-testing** (core@deltahedge): Integration testing patterns for Elixir
  - Credential handling, external API testing, never skip silently
  - Location: `plugins/core/skills/integration-testing/`

**Documentation**
- Plugin Development Tools section in CLAUDE.md
- Roadmap maintenance guidelines with CHANGELOG anchoring
- Task descriptions as prompts guidance (not implementation details)
- Macro and API abstraction guidance in skills

### Changed

**hex-docs-search Skill Rewrite**
- Changed from local-first to HexDocs-first search strategy
- Replaced all `curl` commands with `web` command
- Simplified search strategy from 6 steps to 4 steps
- Added examples/sample-queries.md with common patterns
- core: 1.7.0 → 1.8.0

**Marketplace Version**
- Bumped marketplace version: 1.0.1 → 1.0.2

### Fixed

- Fix serena plugin hooks.json schema format (keyed by event type)
- Fix plugin.json author format to be object (not string)
- Fix SessionStart hook to read cwd from stdin JSON (not env var)
- Fix unbound variable bug in marketplace instructions
- Exclude TODO/FIXME checks from Credo pre-commit hook

---

## [1.0.1] - 2025-01-05

### Changed

**Version Bump (All Plugins)**
- Bumped marketplace version: 1.0.0 → 1.0.1
- Bumped all 13 plugin versions to trigger Claude Code reload
- core: 1.5.0 → 1.5.1, credo/ash/dialyzer/sobelow/mix_audit/ex_unit: 1.1.2 → 1.1.3
- precommit: 1.1.0 → 1.1.1, ex_doc: 1.0.0-rc.7 → 1.0.0-rc.8
- elixir-meta/git/claude-md-includes/doctor: 1.0.0 → 1.0.1

**Script Consolidation (Tasks 1-3)**
- Created shared bash library at `plugins/_shared/` with core utilities
- `lib.sh`: project detection, JSON parsing, git directory extraction, output truncation
- `precommit-utils.sh`: defer-to-precommit, deny JSON emission, git commit detection
- `postedit-utils.sh`: context JSON emission, Elixir file validation
- Migrated all 10 pre-commit scripts to use shared library
- Migrated all 5 post-edit scripts to use shared library
- Reduced script duplication from ~350 lines to ~50 lines
- All 27 shared library tests pass

**Metadata Standardization (Task 6)**
- Standardized author fields across all 13 plugin.json files
- Unified author name to "DeltaHedge" (was "Bradley Golden" in most plugins)
- Unified author URL to "https://github.com/ZenHive" (was personal GitHub or email)
- Removed `email` field from git plugin in favor of `url`
- Added missing `url` field to claude-md-includes plugin

**Hook Timeout Documentation (Task 7)**
- Added timeout rationale tables to all 11 plugin READMEs
- Added missing timeouts to core hooks: recommend-docs-on-read (10s), recommend-docs-lookup (10s)
- Added missing timeout to claude-md-includes session-start hook (15s)

**Documentation Cleanup (Task 9)**
- Replaced verbose TodoWrite structure examples with references to CLAUDE.md best practices
- Updated elixir-interview.md, elixir-research.md, elixir-plan.md, elixir-implement.md, elixir-oneshot.md
- Reduced TodoWrite documentation duplication from ~200 lines to ~30 lines

**README Standardization (Task 10)**
- Standardized section order across all plugin READMEs
- Order: Title → Installation → Requirements (if applicable) → Features → Hook Timeouts
- Reordered ash, mix_audit, sobelow, and git READMEs to follow standard

**Naming Consistency & Cleanup (Tasks 4, 5, 11)**
- Renamed test directories from underscores to hyphens (`postedit_test` → `postedit-test`)
- Renamed `hooks-handlers/` to `scripts/` in claude-md-includes plugin
- Renamed `pre-commit-test.sh` to `pre-commit-check.sh` in ex_unit plugin
- Removed unused `keywords` arrays from marketplace.json (-80 lines)
- Added composable @include directives to project CLAUDE.md
- Fixed command names in CLAUDE.md to match actual file names (`/interview` → `/elixir-interview`, etc.)
- Documented naming convention: `elixir-` prefix for Elixir-specific commands, `/create-plugin` intentionally unprefixed

**Script Style Standardization (Task 12)**
- Standardized all scripts to use `#!/usr/bin/env bash` shebang
- Fixed NULL check order to use `-z` check first consistently
- Fixed 6 scripts: session-start.sh, post-edit-check.sh (sobelow), auto-format.sh, recommend-docs-lookup.sh, compile-check.sh, recommend-docs-on-read.sh

### Added

**Refactoring Roadmap**
- Added refactor.md tracking 12 technical debt cleanup tasks across 5 phases
- All 12/12 tasks complete (100%)

### Plugins

**Task 9: Meta Plugin Rename & Template Updates** [D:6/B:8]
- Renamed `meta` plugin to `elixir-meta`
- Updated marketplace.json and plugin.json references
- Prefixed workflow commands with `elixir-` (elixir-research, elixir-plan, elixir-implement, elixir-qa, elixir-oneshot, elixir-interview)
- Added D/B scoring format to plan and QA templates
- Replaced WebFetch with `web` command in popcorn skill
- Documented workflow evaluation decision in elixir-meta README
- Decision: Keep workflow commands as complementary tools to roadmap-based development

### Skills

**Task 14: Popcorn (Browser Elixir) Skill** [D:4/B:6]
- Client-side Elixir guide for browser WebAssembly apps via Popcorn library
- Architecture overview: Elixir → AtomVM → WASM → Browser
- When to use: offline-first tools, calculators, privacy-preserving analytics
- When NOT to use: real-time trading, streaming data, persistent state
- Project setup with OTP 26.0.2 / Elixir 1.17.3 requirements
- JS interop: `Popcorn.Wasm.run_js/3`, event listeners, data type mapping
- Limitations and workarounds (no direct API calls, localStorage for persistence)
- Example patterns: calculator, data filter, form validation
- Location: `plugins/core/skills/popcorn/`

### Hooks

**Suggest --failed --trace for Repeated Test Runs**
- PreToolUse hook tracks consecutive `mix test` calls
- On 2nd run, suggests `--failed`, `--failed --trace`, `--failed --seed 0`
- Resets counter when `--failed` is used or tests pass (0 failures)
- 10-minute timeout resets counter for fresh sessions
- Speeds up test-fix-test cycle by running only previously failed tests
- Location: `plugins/core/scripts/suggest-test-failed.sh`, `plugins/core/scripts/reset-test-tracker.sh`
- core: 1.5.13 → 1.5.14

**Task 7: Strict Pre-commit Mode** [D:3/B:8]
- Enhanced precommit plugin to run comprehensive quality gates when no `mix precommit` alias exists
- Checks: `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix doctor`
- All checks always required (no conditional dependency detection)
- Clear error messages indicating which check failed
- Bypassable with `--no-verify`
- Location: `plugins/precommit/scripts/pre-commit-check.sh`

**Task 8: Test Failure Pattern Detection** [D:4/B:10]
- PostToolUse hook detects test patterns that silently pass on errors
- Detects: `{:error, _} -> assert true`, `{:error, _} -> :ok`
- Non-blocking warning via `additionalContext` with correct alternatives
- Only scans `_test.exs` files
- Location: `plugins/core/scripts/detect-hidden-failures.sh`

### Skills

**Phoenix Scope Patterns Skill**
- Guide for Phoenix 1.8+ Scope struct patterns
- Basic usage in LiveViews, templates, and contexts
- Key principles: always pass scope, validate ownership, access user via scope
- Extending Scope with custom fields (e.g., exchange capabilities, permissions)
- UI feature toggling based on scope capabilities
- Common patterns: optional auth, scope in changesets, testing
- What NOT to put in scope, refreshing scope
- Location: `plugins/core/skills/phoenix-scope/`

**Task 0f: API Consumer Macro Skill** [D:3/B:9]
- Macro-based API client generation for Elixir REST APIs
- Part 0: Layered abstraction pattern (wrap existing libraries, don't reimplement)
- Part 1: Declarative macro pattern with compile-time code generation
- Part 2: API sync checking mix task and fixture generation
- Part 3: OpenAPI enhancement (optional code generation from specs)
- Decision tree: Build vs Wrap for API client architecture
- Location: `plugins/core/skills/api-consumer/`

**Task 5: Phoenix 1.8 Patterns Skill** [D:3/B:9]
- Quick reference for Phoenix 1.8+ framework patterns
- Covers: project setup, template wrapper, form handling, LiveView streams
- Authentication routing, HEEx syntax, verified routes, Tailwind v4
- Common pitfalls and runtime error patterns
- Location: `plugins/core/skills/phoenix-patterns/`

---

## [1.0.0] - 2025-12-13

### Fork & Rebrand

**Task 1: Update Marketplace Ownership** [D:1/B:8]
- Changed owner from "Bradley Golden" to "DeltaHedge"
- Updated all repository URLs to `https://github.com/ZenHive/claude-marketplace-elixir`
- Updated LICENSE with fork attribution
- Updated README with attribution section

**Task 2: Update Namespace** [D:1/B:6]
- Changed namespace from `elixir` to `deltahedge`
- Plugins now referenced as `core@deltahedge`, `credo@deltahedge`, etc.
- Updated all documentation and command files

### New Plugins

**Task 3: claude-md-includes Plugin** [D:1/B:9]
- SessionStart hook processes `@include <path>` directives in CLAUDE.md
- Enables composable instruction files from reusable components
- Recursive includes with circular detection (max depth: 10)
- Path resolution: `~/` (home), `./` (relative), absolute paths
- Security: Path traversal validation, code block detection
- Location: `plugins/claude-md-includes/`

**Task 4: Doctor Plugin** [D:2/B:9]
- Pre-commit hook for `mix doctor` documentation validation
- Blocks commits if documentation issues found
- 7 tests pass
- Location: `plugins/doctor/`

### New Skills

**Task 0b: Web Command Skill** [D:2/B:9]
- Documents `web` command for browsing in Claude Code
- Covers LiveView forms, screenshots, JavaScript execution, session persistence
- Replaces WebFetch usage guidance
- Location: `plugins/core/skills/web-command/`

**Task 0d: Git Worktrees Skill** [D:2/B:9]
- Guides parallel Claude Code sessions with git worktrees
- Covers setup, workflow patterns, cleanup
- Location: `plugins/core/skills/git-worktrees/`

**Task 0g: Roadmap Planning Skill** [D:2/B:8]
- D/B scoring framework for task prioritization
- Priority indicators, phase organization, dependency tracking
- Location: `plugins/core/skills/roadmap-planning/`

**Task 6: Tidewave Guide Skill** [D:2/B:8]
- MCP tools usage guide for Elixir development
- Setup instructions, "explore before coding" workflow
- Location: `plugins/core/skills/tidewave-guide/`

### Infrastructure

**Task 0a: D/B Scoring Documentation** [D:1/B:7]
- Already implemented in `~/.claude/includes/task-prioritization.md`
- Projects include via `@include` directive

**Task 0c: WebFetch Cleanup** [D:1/B:8]
- Audited all files for WebFetch references
- Codebase clean - uses WebSearch and curl appropriately

**Task 0e: Local Marketplace Testing** [D:1/B:10]
- Marketplace added to Claude Code session for development testing
- Enables immediate validation of plugins during development

**Task 0h: Plugin Structure Validation** [D:1/B:7]
- Validated 12/12 plugins exist and have valid JSON
- Validated 3/3 skills have proper frontmatter
- Validated 17/17 hook scripts are executable
- Baseline: 86 tests pass

**Task 3b: Split Global CLAUDE.md** [D:2/B:8]
- Created 12 modular include files in `~/.claude/includes/`
- Universal includes: critical-rules, task-prioritization, web-command, code-style, development-philosophy, documentation-guidelines
- Elixir/Phoenix includes: development-commands, slash-commands, phoenix-setup, phoenix-patterns, elixir-patterns, library-design

**Task 14: Full Test Suite Validation** [D:2/B:9]
- All 93/93 plugin tests pass
- All 13/13 plugins validated
- Fixed missing plugin entries in settings
- Fixed outdated agent documentation

---

## Summary

| Category | Count |
|----------|-------|
| Plugins Added | 3 (claude-md-includes, doctor, serena) |
| Skills Added | 12 (web-command, git-worktrees, roadmap-planning, tidewave-guide, api-consumer, phoenix-patterns, popcorn, phoenix-scope, daisyui, nexus-template, phoenix-js, integration-testing) |
| Hooks Added | 2 (strict precommit, test failure detection) |
| Tests Passing | 93/93 |

## Attribution

This marketplace is forked from [Bradley Golden's claude-marketplace-elixir](https://github.com/bradleygolden/claude-marketplace-elixir) under MIT license.
