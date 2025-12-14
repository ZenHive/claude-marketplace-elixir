# Marketplace Personalization Roadmap

Remaining tasks to personalize the Claude Code plugin marketplace. See [CHANGELOG.md](CHANGELOG.md) for completed work.

## Progress Summary

| Phase | Status | Remaining |
|-------|--------|-----------|
| 0. Foundation | 8/8 ✅ | - |
| 1. Ownership | 2/2 ✅ | - |
| 2. New Plugins | 5/5 ✅ | - |
| 3. Pre-commit | 2/2 ✅ | - |
| 4. Workflows | 0/1 | Task 9 |
| 5. Documentation | 1/3 | Tasks 12-13 |
| 6. New Skills | 1/1 ✅ | - |

**Total: 19/22 complete (86%) | 3 remaining**

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
3. Add new skills documentation (web-command, git-worktrees, roadmap-planning, tidewave-guide, api-consumer)
4. Update ownership references
5. Add D/B scoring explanation

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- [ ] All new plugins documented
- [ ] All new skills documented
- [ ] D/B scoring format explained

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

### Lower Priority (📋 Priority < 2.0)

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
| 1 | 📋 9 (elixir-meta) | Integrate all skills + evaluate workflow |
| 2 | 🎯 12 (CLAUDE.md), 13 (README) | Document everything at once |

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
