# Marketplace Personalization Roadmap

Remaining tasks to personalize the Claude Code plugin marketplace. See [CHANGELOG.md](CHANGELOG.md) for completed work.

## Progress Summary

| Phase | Status | Remaining |
|-------|--------|-----------|
| 0. Foundation | 7/8 | Task 0f |
| 1. Ownership | 2/2 ✅ | - |
| 2. New Plugins | 4/5 | Task 5 |
| 3. Pre-commit | 0/2 | Tasks 7-8 |
| 4. Workflows | 0/3 | Tasks 9-11 |
| 5. Documentation | 1/3 | Tasks 12-13 |

**Total: 14/23 complete (61%) | 9 remaining**

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

#### Task 5: Create Phoenix 1.8 Patterns Skill [D:3/B:9 → Priority:3.0] 🎯

**Goal:** On-demand skill providing Phoenix 1.8 patterns from your CLAUDE.md.

**Skill location:** `plugins/core/skills/phoenix-patterns/`

**Content sections:**
1. Project setup (`--binary-id --live` flags)
2. Template wrapper requirement (`<Layouts.app>`)
3. Form handling (`to_form/2` pattern)
4. LiveView streams
5. Authentication routing patterns
6. HEEx template syntax
7. Verified routes (`~p` sigil)
8. Tailwind v4 patterns
9. Common pitfalls (runtime errors)

**SKILL.md frontmatter:**
```yaml
---
name: phoenix-patterns
description: Phoenix 1.8 framework patterns reference. Use when working with Phoenix templates, forms, LiveView streams, auth routing, HEEx syntax, or Tailwind v4.
allowed-tools: Read
---
```

**Acceptance criteria:**
- [ ] Skill provides all Phoenix 1.8 patterns from CLAUDE.md
- [ ] Organized by category for easy lookup
- [ ] Includes good/bad examples
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

#### Task 9: Add D/B Scoring to Plan Template [D:3/B:4 → Priority:1.33] 📋

**Goal:** Update meta plugin's plan template to generate tasks with D/B scoring.

**Files to modify:**
- `plugins/meta/skills/workflow-generator/templates/plan-template.md`

**Acceptance criteria:**
- [ ] Generated plans include D/B scoring instructions
- [ ] Priority indicators documented (🎯 🚀 📋 ⚠️)

---

#### Task 10: Add D/B Scoring to QA Template [D:3/B:4 → Priority:1.33] 📋

**Goal:** Update meta plugin's QA template to report issues with prioritized scoring.

**Files to modify:**
- `plugins/meta/skills/workflow-generator/templates/qa-template.md`

**Acceptance criteria:**
- [ ] Issues reported with D/B scores
- [ ] Sorted by priority (highest ROI first)

---

#### Task 11: Add Tidewave to Research Template [D:3/B:4 → Priority:1.33] 📋

**Goal:** Update meta plugin's research template to suggest Tidewave MCP tools.

**Files to modify:**
- `plugins/meta/skills/workflow-generator/templates/research-template.md`

**Acceptance criteria:**
- [ ] Research template mentions Tidewave when relevant
- [ ] Suggests `project_eval` for API exploration

---

## Execution Order by ROI

| Priority | Tasks |
|----------|-------|
| 🎯 3.5 | 12 (CLAUDE.md) |
| 🎯 3.0 | 0f (API consumer), 5 (Phoenix), 13 (README) |
| 🎯 2.67 | 7 (Strict precommit) |
| 🎯 2.5 | 8 (Test detection) |
| 📋 1.33 | 9, 10, 11 (Meta templates - low priority) |

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
