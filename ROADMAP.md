# Marketplace Personalization Roadmap

Remaining tasks to personalize the Claude Code plugin marketplace. See [CHANGELOG.md](CHANGELOG.md) for completed work.

## Progress Summary

| Phase | Status | Remaining |
|-------|--------|-----------|
| 0. Foundation | 7/8 | Task 0f |
| 1. Ownership | 2/2 ✅ | - |
| 2. New Plugins | 5/5 ✅ | - |
| 3. Pre-commit | 0/2 | Tasks 7-8 |
| 4. Workflows | 0/1 | Task 9 |
| 5. Documentation | 1/3 | Tasks 12-13 |
| 6. New Skills | 0/1 | Task 14 |

**Total: 15/22 complete (68%) | 7 remaining**

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

#### Task 12: Update Project CLAUDE.md [D:2/B:7 → Priority:3.5] 🎯

**Goal:** Update the project's CLAUDE.md with new plugins, skills, and preferences.

**Updates needed:**
1. Add claude-md-includes plugin documentation
2. Add Doctor plugin documentation
3. Add new skills documentation (web-command, git-worktrees, roadmap-planning, tidewave-guide)
4. Update ownership references
5. Add D/B scoring explanation

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- [ ] All new plugins documented
- [ ] All new skills documented
- [ ] D/B scoring format explained

---

#### Task 0f: Create API Consumer Macro Skill [D:3/B:9 → Priority:3.0] 🎯

**Goal:** Create an on-demand skill for macro-based API client generation with tooling.

**Sources:**
- `crypto_bridge` - Declarative macro pattern (primary)
- `zen_cex` - OpenAPI generation pattern (optional enhancement)

**Skill location:** `plugins/core/skills/api-consumer/`

**Content sections:**

**Part 0: Layered Abstraction Pattern**
- When NOT to build your own API client
- If a battle-tested library exists (CCXT, Stripe SDK, etc.), wrap it declaratively
- Example: crypto_bridge architecture (Elixir → TS Bridge → CCXT → APIs)

**Part 1: Declarative Macro Pattern (Primary)**
- When to use macros for API clients (10+ similar endpoints, no existing library)
- Declarative method definition format
- HTTP client patterns with Req
- Explicit credentials (no env fallback in library code)

**Part 2: Sync Checking & Fixtures**
- Mix task for API sync checking
- Fixture generation from real API responses

**Part 3: OpenAPI Enhancement (Optional)**
- When to use OpenAPI generation
- OpenAPI → Elixir generation mix task

**SKILL.md frontmatter:**
```yaml
---
name: api-consumer
description: Macro-based API client generation for Elixir. Use when building clients for REST APIs with 10+ similar endpoints. Primary pattern: declarative method definitions with auto-generated functions. Optional: OpenAPI spec generation for discovery.
allowed-tools: Read, Bash
---
```

**Acceptance criteria:**
- [ ] Layered abstraction pattern: wrap existing libraries, don't reimplement
- [ ] Declarative macro pattern documented as primary approach
- [ ] OpenAPI generation documented as optional enhancement
- [ ] Mix task pattern for API sync checking
- [ ] Fixture generation workflow documented
- [ ] SKILL.md has proper frontmatter

---

#### Task 13: Update README.md [D:2/B:6 → Priority:3.0] 🎯

**Goal:** Update README with new features and fork attribution.

**Updates needed:**
1. Attribution to original project (MIT license)
2. New plugin list (claude-md-includes, Doctor)
3. New skills list (web-command, git-worktrees, roadmap-planning, tidewave-guide)
4. Installation instructions current

**Files to modify:**
- `README.md`

**Acceptance criteria:**
- [ ] Attribution clear and correct
- [ ] All new features documented
- [ ] Installation instructions current

---

### Medium Priority (🎯 Priority 2.5-3.0)

#### Task 7: Update Precommit Plugin for Strict Mode [D:3/B:8 → Priority:2.67] 🎯

**Goal:** Make pre-commit validation strict by default, matching CLAUDE.md quality gates.

**Enhanced behavior:**
1. Check `mix format --check-formatted`
2. Check `mix compile --warnings-as-errors`
3. Check `mix credo --strict`
4. Check `mix doctor` (new)
5. Check `mix test` (if ex_unit plugin enabled)
6. Block commit if ANY fail

**Files to modify:**
- `plugins/precommit/scripts/pre-commit-check.sh`
- `plugins/precommit/README.md`

**Acceptance criteria:**
- [ ] All quality gates checked before commit
- [ ] Clear error messages indicating which check failed
- [ ] Can be bypassed with `--no-verify`
- [ ] Tests pass for all check combinations

---

#### Task 8: Add Test Failure Pattern Detection [D:4/B:10 → Priority:2.5] 🎯

**Goal:** Detect and warn about tests that hide failures (your "never hide test failures" rule).

**Detection patterns (from CLAUDE.md):**
```elixir
# BAD patterns to detect:
{:error, _} -> assert true           # Makes all failures pass
{:error, _reason} -> :ok             # Silent pass on any error
```

**Implementation:** PostToolUse hook in core plugin (immediate feedback)

**Files to create:**
- `plugins/core/scripts/detect-hidden-failures.sh`

**Files to modify:**
- `plugins/core/hooks/hooks.json`
- `plugins/core/README.md`

**Acceptance criteria:**
- [ ] Detects `{:error, _} -> assert true` pattern
- [ ] Detects `{:error, _} -> :ok` pattern
- [ ] Warns via `additionalContext` (non-blocking)
- [ ] Provides correct alternative patterns
- [ ] Only scans `_test.exs` files

---

### Lower Priority (📋 Priority < 2.0)

#### Task 14: Create Popcorn (Browser Elixir) Skill [D:4/B:6 → Priority:1.5] 🚀

**Goal:** Create an on-demand skill for Popcorn - running Elixir in the browser via WebAssembly.

**Context:** Popcorn is a library by Software Mansion that compiles Elixir to run in browsers via AtomVM (a tiny Erlang VM compiled to WASM). It enables offline-first, client-side Elixir applications with JS interoperability.

**Skill location:** `plugins/core/skills/popcorn/`

**Content sections:**

**Part 1: Overview & When to Use**
- What Popcorn is (Elixir → AtomVM → WASM → Browser)
- Ideal use cases: calculators, offline tools, local-first apps, privacy-preserving analytics
- NOT for: real-time trading, HFT, streaming data, persistent connections

**Part 2: Project Setup**
- Installation and configuration
- Build process (`mix popcorn.build`)
- Integration with existing projects

**Part 3: JS Interoperability**
- Calling JS from Elixir
- Calling Elixir from JS
- Data type mapping between Elixir and JS

**Part 4: Limitations & Workarounds**
- No direct API calls from WASM (use JS interop bridge)
- No GenServer persistence across page reloads (use localStorage via JS)
- Early stage - some OTP features limited
- Performance considerations vs native Elixir

**Part 5: Example Patterns**
- Client-side calculators (P&L, position sizing)
- Offline data processing
- Form validation with Elixir logic

**SKILL.md frontmatter:**
```yaml
---
name: popcorn
description: Popcorn client-side Elixir guide for browser WebAssembly apps. Use when building offline-first tools, client-side calculators, or privacy-preserving analytics. Covers setup, JS interop, limitations, and example patterns.
allowed-tools: Read, Bash, WebFetch
---
```

**Resources:**
- GitHub: https://github.com/software-mansion/popcorn
- Docs: https://hexdocs.pm/popcorn
- Examples: https://popcorn.swmansion.com/

**Acceptance criteria:**
- [ ] Overview explains Popcorn architecture (Elixir → AtomVM → WASM)
- [ ] Clear guidance on when to use vs when NOT to use
- [ ] JS interop patterns documented
- [ ] Limitations and workarounds explained
- [ ] Example patterns for common use cases
- [ ] SKILL.md has proper frontmatter

---

#### Task 9: Rename Meta Plugin & Update Templates [D:6/B:8 → Priority:1.33] 📋

**Goal:** Rename `meta` → `elixir-meta` and integrate all marketplace capabilities into workflow templates.

**⚠️ Pre-work:** Consolidate `deferred/ELIXIR-META-ROADMAP.md` (25 micro-tasks) into session-sized tasks following this philosophy:

> **Roadmap Philosophy:** Every task should fit into a Claude Code session and make full use of Claude Code's context window. Every task is a prompt.

**Session 1: Rename & Update References**
1. Rename `plugins/meta/` → `plugins/elixir-meta/`
2. Update `plugins/elixir-meta/.claude-plugin/plugin.json` (name field)
3. Update `.claude-plugin/marketplace.json` (source path)
4. Update all references (CLAUDE.md, README.md, commands, skills)

**Session 2: Evaluate Workflow Commands**
- Test if `/research`, `/plan`, `/implement`, `/qa` fit actual workflow
- Actual workflow: Read ROADMAP.md → pick task → work in session → commit
- Decision: Keep, simplify, or remove workflow-generator

**Session 3: Migrate Useful Reference Commands**
- Migrate commands actually used: `/elixir-code-review`, `/elixir-refactor`
- Evaluate others: debug, gotchas, phoenix, performance, tdd, schema, explain
- Commands become `/elixir-meta:<command>`

**Session 4: Align Templates with CLAUDE.md**
- Integrate all new skills into templates
- Add D/B scoring format to plan/QA outputs
- Add Tidewave MCP tools to research phase
- Add Finder/Analyzer pattern documentation
- Replace WebFetch with `web` command

**Session 5: Polish & Validate**
- Update README with all commands
- Validate JSON files and command discovery
- Optional: Remove migrated global commands

**Detailed task breakdown:** See `deferred/ELIXIR-META-ROADMAP.md`

**Acceptance criteria:**
- [ ] Plugin renamed from `meta` to `elixir-meta`
- [ ] All references updated (marketplace.json, plugin.json)
- [ ] Workflow commands evaluated and decision documented
- [ ] Useful reference commands migrated
- [ ] Templates aligned with global CLAUDE.md patterns
- [ ] D/B scoring format in plan and QA outputs
- [ ] `web` command usage instead of WebFetch

---

## Execution Order by ROI

**Note:** Documentation tasks (12, 13) should be done AFTER all implementation is complete.

| Order | Tasks | Rationale |
|-------|-------|-----------|
| 1 | 🎯 0f (API consumer) | High-value skill [Priority 3.0] |
| 2 | 🎯 7 (Strict precommit), 8 (Test detection) | Quality gates [Priority 2.5-2.67] |
| 3 | 🚀 14 (Popcorn skill) | New browser Elixir capability [Priority 1.5] |
| 4 | 📋 9 (elixir-meta) | Integrate all skills + evaluate workflow |
| 5 | 🎯 12 (CLAUDE.md), 13 (README) | Document everything at once |

---

## Non-Goals (Out of Scope)

| Item | Reason |
|------|--------|
| CI/CD automation | Manual testing sufficient |
| Plugin versioning automation | Semantic versioning is manual |
| Removing existing plugins | Working and useful |
| New workflow commands | Enhance existing only |

## Future Scope (Post-Roadmap)

| Plugin | Examples |
|--------|----------|
| TypeScript/JS | Phoenix frontends, LiveView hooks, Node services |
| Go | Services, CLI tools, protocol implementations |
| Rust | NIFs (Rustler), performance-critical modules |

---

## Decisions Made

| Question | Decision |
|----------|----------|
| Namespace | `deltahedge` |
| Owner name | DeltaHedge |
| Attribution | Keep Bradley Golden as original author |
| Repository URL | `https://github.com/ZenHive/claude-marketplace-elixir` |
