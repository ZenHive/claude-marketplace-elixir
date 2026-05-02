# Marketplace Personalization Roadmap

Remaining tasks to personalize the Claude Code plugin marketplace. See [CHANGELOG.md](CHANGELOG.md) for completed work.

## Progress Summary

| Phase | Status | Remaining |
|-------|--------|-----------|
| 0. Foundation | 8/8 ✅ | - |
| 1. Ownership | 2/2 ✅ | - |
| 2. New Plugins | 5/5 ✅ | - |
| 3. Pre-commit | 2/2 ✅ | - |
| 4. Workflows | 1/1 ✅ | - |
| 5. Documentation | 3/3 ✅ | - |
| 6. New Skills | 1/1 ✅ | - |
| 7. Skill Quality | 5/5 ✅ | - |
| 8. Hook Scripts | 0/4 | 4 |

**Total: 28/32 complete (88%)**

---

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

## Remaining Tasks by Priority

### High Priority (🎯 Priority > 3.0)

#### Task 12: Update Project CLAUDE.md ✅ [D:2/B:7/U:5 → Eff:3.0]

Updated CLAUDE.md skills section to document all 21 skills organized by plugin (elixir: 14, phoenix: 6, elixir-workflows: 1). See [CHANGELOG.md](CHANGELOG.md).

---

#### Task 13: Update README.md ✅ [D:2/B:6/U:5 → Eff:2.75]

Added "Available Skills (21)" section to README.md with complete skill inventory. Updated plugin table descriptions. See [CHANGELOG.md](CHANGELOG.md).

---

### Phase 7: Skill Quality

> **Methodology:** Informed by Anthropic's `document-skills:skill-creator` patterns — progressive disclosure, pushy descriptions, AI-coder-docs scope boundaries.

#### Task 23: Progressive Disclosure for Oversized Skills ✅ [D:4/B:7/U:6 → Eff:1.63]

Refactored 4 oversized skills with progressive disclosure pattern. Evaluated 3 borderline skills and kept as-is. See [CHANGELOG.md](CHANGELOG.md).

---

#### Task 24: Skill Description Optimization ✅ [D:2/B:8/U:7 → Eff:3.75]

All 17 skill YAML descriptions rewritten with pushy trigger language. See [CHANGELOG.md](CHANGELOG.md).

---

#### Task 25: AI-Coder-Docs Patterns for Skills ✅ [D:3/B:6/U:5 → Eff:1.83]

Added Does/Does Not scope sections to 8 skills plus phoenix-setup cross-reference. See [CHANGELOG.md](CHANGELOG.md).

---

#### Task 26: Update Tasks 12-13 for Current State [D:1/B:4/U:5 → Eff:4.50]

**Goal:** Refresh the documentation tasks (12, 13) to reflect current marketplace state — they reference stale plugin names and incomplete skill lists.

See updated Tasks 12 and 13 above (already updated in this roadmap revision).

**Status:** ✅ Complete (updated inline)

---

#### Task 27: Sync Skills with Updated Includes ✅ [D:3/B:8/U:8 → Eff:2.67]

Skills synced with canonical includes. See [CHANGELOG.md](CHANGELOG.md).

---

#### Task 28: Backport Skill Knowledge to Canonical Includes ✅ [D:5/B:9/U:9 → Eff:1.8]

Rewrote 4 include files (zen-websocket, meta-development, api-integration, phoenix-js) with condensed knowledge from skills + references, grounded in ccxt_ex/ccxt_client. Created sync script for 15 skill-include pairs. Fixed stale `core:` → `elixir:` namespace references across 9 files. See [CHANGELOG.md](CHANGELOG.md).

---

### Phase 8: Hook Scripts

> **Methodology:** New scripts in `plugins/elixir/scripts/`, wired into `plugins/elixir/hooks/hooks.json`. Use `prefer-test-json.sh` / `prefer-dialyzer-json.sh` as the `PreToolUse:Bash` template (warn vs. deny JSON shapes); use `post-edit-check.sh`'s hidden-failures section as the `PostToolUse:Edit|Write|MultiEdit` template. Canonical rules live in `~/.claude/includes/critical-rules.md`, `development-commands.md`, `development-philosophy.md` — link to those, don't duplicate the prose.

#### Task 29: Block destructive Bash patterns [D:3/B:8/U:7 → Eff:2.50] 🎯

Add `PreToolUse:Bash` hooks that **block** three command shapes Claude is explicitly told never to run:

- `mix phx.server` — server is always already running (`critical-rules.md` § "NEVER START THE PHOENIX SERVER")
- Destructive deps/build commands: `mix deps.clean`, `mix clean`, `mix deps.unlock --all`, `rm -rf _build`, `rm -rf deps` (`critical-rules.md` § "NEVER RUN DESTRUCTIVE DEPENDENCY COMMANDS"). Must allow `mix deps.unlock --check-unused` (used by `pre-commit-unified.sh`).
- Bare `rm` outside of `git rm` (`critical-rules.md` § "Shell Safety"). Must allow `git rm`.

Each script outputs the deny-JSON shape with a `permissionDecisionReason` pointing to the safe alternative. Tests in `test/` exercise both the block patterns and each documented exception (no false positives on the allowed forms).

---

#### Task 30: Warn on tooling-flag omissions [D:2/B:6/U:6 → Eff:3.00] 🎯

Add `PreToolUse:Bash` hooks that **warn** (no block) when project-standard flags are missing:

- `mix credo` invoked without `--strict --format json` (`development-commands.md`)
- `mix compile` invoked without a `time` prefix (`development-commands.md`)

False-positive guard: don't fire on `post-edit-check.sh` / `pre-commit-unified.sh`'s own internal `mix credo` / `mix compile` invocations (those run inside hook scripts, not via Claude's Bash tool — verify this is actually true before adding complex matching).

---

#### Task 31: Warn on doctest IO and untagged temporary code [D:4/B:6/U:4 → Eff:1.25] 📋

Extend `post-edit-check.sh` (or add a sibling `PostToolUse:Edit|Write|MultiEdit` script) with two warn-only checks credo can't see:

- `IO.puts` / `IO.inspect` inside `@doc` heredoc blocks (`development-philosophy.md` § "No IO in @doc examples")
- `#` comments starting with "For now,", "Currently,", "Temporarily,", "In production,", or "This is a workaround," NOT preceded by `TODO:` (`development-philosophy.md` § "TODO Comment Requirements")

False-positive guards: never trigger when patterns appear inside string literals or `~s`/`~S` sigils. Tune for low noise — these will fire less often than hidden-failures but each fire should be a real catch.

---

#### Task 32: Warn on shell-eval Elixir, prefer Tidewave [D:2/B:7/U:7 → Eff:3.50] 🎯

Add a `PreToolUse:Bash` hook that **warns** (no block) when Claude is about to run Elixir code through the shell — the cases that have a direct `mcp__tidewave__project_eval` / `get_logs` equivalent:

- `mix run -e "<code>"`
- `elixir -e "<code>"`
- `iex -e "<code>"`
- `mix run <path>.exs` (legitimate `priv/repo/seeds.exs` shares the shape — accepted false positive, called out in the warning)

**Why:** Tidewave attaches to the same BEAM as the running dev server, so `project_eval` sees current state, GenServers, ETS, application env — and skips the 3–10s fresh-VM startup that `mix run` incurs. Returns structured Elixir terms instead of stringified stdout. The `tidewave-guide` skill exists but Claude regularly forgets it under shell-muscle-memory; this hook is the user's #1 unprompted-reminder frustration.

**Reference implementation:** working version already in `hieroglyph/.claude/hookify.prefer-tidewave-over-shell-eval.local.md` (12-case regex test included in that session's transcript). Port the regex and warning text — the warning includes a replacement table, the `recompile()` workaround for stale bytecode, and a "legitimate exceptions" footer (seeds, one-shot CI scripts).

**Success criteria:**
- New script in `plugins/elixir/scripts/`, registered in `plugins/elixir/hooks/hooks.json` under `PreToolUse:Bash`
- Warn-only (must NOT block — seeds and CI scripts share the shape)
- Test cases: 4 trigger patterns fire, none of `mix test`/`iex -S mix`/`iex -S mix tidewave`/`mix phx.server`/`mix compile` fire
- Warning message points to `mcp__tidewave__project_eval` and `mcp__tidewave__get_logs` by their MCP tool names so Claude can call them directly

---

### Completed (Phase 0-4, 6)

#### Task 9: Rename Meta Plugin & Update Templates ✅

Plugin renamed from `meta` to `elixir-workflows`. All references updated. Workflow commands evaluated. Templates aligned with CLAUDE.md patterns.

---

## Execution Order by ROI

| Order | Tasks | Rationale |
|-------|-------|-----------|
| 1 | ~~Task 26~~ ✅ | Updated tasks 12-13 inline |
| ~~2a~~ | ~~Task 23 (progressive disclosure)~~ ✅ | Complete |
| ~~2b~~ | ~~Task 24 (descriptions)~~ ✅ | Complete |
| 2c | Task 27 (sync with includes) `[P]` | Independent — fix stale content + create new skills |
| ~~3~~ | ~~Task 25 (AI-coder-docs)~~ ✅ | Complete |
| ~~4~~ | ~~Tasks 12, 13 (documentation)~~ ✅ | Complete |

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

---

## Decisions Made

| Question | Decision |
|----------|----------|
| Namespace | `deltahedge` |
| Owner name | DeltaHedge |
| Attribution | Keep Bradley Golden as original author |
| Repository URL | `https://github.com/ZenHive/claude-marketplace-elixir` |
