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
| 5. Documentation | 1/3 | Tasks 12-13 |
| 6. New Skills | 1/1 ✅ | - |
| 7. Skill Quality | 5/5 ✅ | - |

**Total: 25/27 complete (93%) | 2 remaining**

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

#### Task 12: Update Project CLAUDE.md [D:2/B:7/U:5 → Eff:3.0] 🎯

**Goal:** Update the project's CLAUDE.md to reflect the current marketplace state: 7 plugins, 17 skills, correct namespaces.

**Updates needed:**
1. Document all 17 skills organized by plugin (elixir: 11, phoenix: 5, elixir-workflows: 1)
2. Update plugin names (core → elixir, meta → elixir-workflows throughout)
3. Add skills documentation section with trigger guidance
4. Update ownership references
5. Add D/B/U scoring explanation
6. Include Phase 7 skill quality improvements if completed

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- [ ] All 7 plugins documented with current names
- [ ] All 17 skills listed with descriptions
- [ ] D/B/U scoring format explained
- [ ] No stale references to old plugin names (core, meta)

---

#### Task 13: Update README.md [D:2/B:6/U:5 → Eff:2.75] 🎯

**Goal:** Update README with current marketplace features and fork attribution.

**Updates needed:**
1. Attribution to original project (MIT license)
2. Current plugin list (7 plugins: elixir, phoenix, elixir-workflows, git-commit, md-includes, serena, notifications)
3. Current skills list (17 skills across 3 plugins)
4. Installation instructions verified current
5. Skill categories (Core Development, Phoenix/UI, Specialized, Workflow)

**Files to modify:**
- `README.md`

**Acceptance criteria:**
- [ ] Attribution clear and correct
- [ ] All 7 plugins and 17 skills documented
- [ ] Installation instructions current
- [ ] No stale references to old plugin names

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
| 4 | Tasks 12, 13 (documentation) | Final, after all improvements |

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
