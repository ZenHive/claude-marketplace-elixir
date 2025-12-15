# Marketplace Refactoring Roadmap

Technical debt and consistency improvements for the Claude Code plugin marketplace. Based on comprehensive codebase review identifying duplication, inconsistencies, and consolidation opportunities.

## Progress Summary

| Phase | Status | Tasks |
|-------|--------|-------|
| 1. Script Consolidation | 3/3 ✅ | Tasks 1-3 complete |
| 2. Naming Consistency | 2/2 ✅ | Tasks 4-5 complete |
| 3. Metadata Standardization | 2/2 ✅ | Tasks 6-7 complete |
| 4. Documentation Cleanup | 2/3 | Tasks 8-9 complete, Task 10 pending |
| 5. Polish | 1/2 | Task 11 complete, Task 12 pending |

**Total: 11/12 complete (92%)**

---

## Impact Summary

| Metric | Current | After Refactor |
|--------|---------|----------------|
| Script duplication | ~350 lines | ~50 lines |
| Documentation duplication | ~500 lines → ~300 lines ✅ | ~200 lines |
| Naming inconsistencies | 5 → 0 ✅ | 0 |
| Author format variations | 4 → 1 ✅ | 1 |
| Undocumented timeouts | 9 → 0 ✅ | 0 |

---

## Phase 1: Script Consolidation

### Task 1: Create Shared Script Library [D:4/B:9 → Priority:2.25] 🚀

**Goal:** Extract duplicated bash functions into a shared library to eliminate ~350 lines of duplication across 11+ scripts.

**New files to create:**
```
plugins/_shared/
├── lib.sh              # Core utilities (project detection, JSON parsing)
├── precommit-utils.sh  # Pre-commit specific patterns
└── postedit-utils.sh   # Post-edit specific patterns
```

**Functions to extract to `lib.sh`:**
1. `find_mix_project_root()` - Mix project detection (11 occurrences)
2. `parse_hook_input()` - JSON input validation (11+ occurrences)
3. `extract_git_dir()` - Git directory from `-C` flag (12+ occurrences)
4. `truncate_output()` - Output line limiting (10+ occurrences)

**Functions to extract to `precommit-utils.sh`:**
1. `defer_to_precommit()` - Check for mix precommit alias (10+ occurrences)
2. `emit_deny_json()` - Blocking permission response (10+ occurrences)
3. `detect_git_commit()` - Git commit command detection

**Functions to extract to `postedit-utils.sh`:**
1. `emit_context_json()` - Non-blocking additionalContext response
2. `validate_elixir_file()` - Check .ex/.exs extension

**Acceptance criteria:**
- [x] `plugins/_shared/lib.sh` created with core functions
- [x] `plugins/_shared/precommit-utils.sh` created
- [x] `plugins/_shared/postedit-utils.sh` created
- [x] All functions have consistent error handling
- [x] Functions tested in isolation (27 tests pass)

---

### Task 2: Migrate Pre-commit Scripts to Shared Library [D:5/B:8 → Priority:1.6] 🚀

**Goal:** Update all pre-commit-check.sh scripts to use shared library.

**Files to modify (11 scripts):**
- `plugins/core/scripts/pre-commit-check.sh`
- `plugins/credo/scripts/pre-commit-check.sh`
- `plugins/dialyzer/scripts/pre-commit-check.sh`
- `plugins/ash/scripts/pre-commit-check.sh`
- `plugins/sobelow/scripts/pre-commit-check.sh`
- `plugins/ex_doc/scripts/pre-commit-check.sh`
- `plugins/mix_audit/scripts/pre-commit-check.sh`
- `plugins/ex_unit/scripts/pre-commit-test.sh`
- `plugins/precommit/scripts/pre-commit-check.sh`
- `plugins/doctor/scripts/pre-commit-check.sh`

**Pattern:**
```bash
#!/usr/bin/env bash
set -eo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../_shared/lib.sh"
source "$SCRIPT_DIR/../../_shared/precommit-utils.sh"

# Plugin-specific logic only
```

**Acceptance criteria:**
- [x] All pre-commit scripts source shared library
- [x] Each script only contains plugin-specific logic
- [x] All tests pass: `./test/run-all-tests.sh`
- [x] Git commit detection tests pass for all plugins

---

### Task 3: Migrate Post-edit Scripts to Shared Library [D:3/B:6 → Priority:2.0] 🚀

**Goal:** Update all post-edit-check.sh scripts to use shared library.

**Files to modify (5 scripts):**
- `plugins/core/scripts/auto-format.sh`
- `plugins/core/scripts/compile-check.sh`
- `plugins/credo/scripts/post-edit-check.sh`
- `plugins/ash/scripts/post-edit-check.sh`
- `plugins/sobelow/scripts/post-edit-check.sh`

**Notes:**
- Ash and Credo post-edit scripts migrated to use `postedit_setup_with_dep`
- Fixed test path naming (`postedit_test` → `postedit-test`) in ash test suite

**Acceptance criteria:**
- [x] All post-edit scripts source shared library
- [x] Each script only contains plugin-specific logic
- [x] Post-edit hook tests pass

---

## Phase 2: Naming Consistency

### Task 4: Fix File and Directory Naming [D:1/B:6 → Priority:6.0] 🎯

**Goal:** Standardize naming patterns across the codebase.

**Fixes:**
1. Rename `plugins/ex_unit/scripts/pre-commit-test.sh` → `pre-commit-check.sh`
2. Rename `test/plugins/ash/postedit_test/` → `postedit-test/`
3. Rename `plugins/claude-md-includes/hooks-handlers/` → `scripts/`

**Files to modify:**
- `plugins/ex_unit/hooks/hooks.json` (update command path)
- `plugins/claude-md-includes/hooks/hooks.json` (update command path)

**Acceptance criteria:**
- [x] All pre-commit scripts named `pre-commit-check.sh`
- [x] All test directories use hyphens, not underscores
- [x] All plugins use `scripts/` directory (not `hooks-handlers/`)
- [x] Hook references updated

---

### Task 5: Standardize Command Naming [D:1/B:5 → Priority:5.0] 🎯

**Goal:** Document command naming conventions.

**Current state:**
- Most commands: `/elixir-research`, `/elixir-plan`, `/elixir-implement`, etc.
- Exception: `/create-plugin` (no prefix)

**Decision: Keep `/create-plugin` as-is** - It's genuinely not Elixir-specific; it creates Claude Code plugins which could be for any language/purpose. Document this as an intentional exception.

**Files to modify:**
- `CLAUDE.md` - add note explaining naming convention and exception

**Acceptance criteria:**
- [x] Decision made: keep `/create-plugin` (not Elixir-specific)
- [x] Exception documented in CLAUDE.md
- [x] Command list in CLAUDE.md matches actual names

---

## Phase 3: Metadata Standardization

### Task 6: Standardize Plugin Author Fields [D:2/B:5 → Priority:2.5] 🚀

**Goal:** Use consistent author field structure across all plugins.

**Current variations:**
- `{name, email}` - git plugin
- `{name, url}` - core, credo, ash, dialyzer, sobelow, etc.
- `{name}` only - claude-md-includes
- Different names: "Bradley Golden" vs "DeltaHedge"

**Standard format:**
```json
"author": {
  "name": "DeltaHedge",
  "url": "https://github.com/ZenHive"
}
```

**Files to modify (14 plugin.json files):**
- `plugins/*/. claude-plugin/plugin.json`

**Acceptance criteria:**
- [x] All plugin.json files use identical author format
- [x] Author name consistent (DeltaHedge)
- [x] URL present in all

---

### Task 7: Document All Hook Timeouts [D:2/B:4 → Priority:2.0] 🚀

**Goal:** Ensure all hooks have timeouts and document rationale in READMEs.

**Current state:**
- Some plugins have undocumented timeouts
- Some plugins missing timeouts entirely

**Note:** JSON does not support comments. Document timeout rationale in plugin README.md instead.

**Pattern for README.md:**
```markdown
## Hook Timeouts

| Hook | Timeout | Rationale |
|------|---------|-----------|
| pre-commit-check | 30s | Format + compile check |
| dialyzer-pre-commit | 120s | Dialyzer analysis can be slow on large codebases |
```

**Files modified:**
- `plugins/*/README.md` - added timeout documentation tables to all 11 plugins
- `plugins/core/hooks/hooks.json` - added missing timeouts to recommend-docs-on-read (10s) and recommend-docs-lookup (10s)
- `plugins/claude-md-includes/hooks/hooks.json` - added missing timeout to session-start (15s)
- Note: ex_doc and doctor already had timeouts (45s and 60s respectively)

**Acceptance criteria:**
- [x] All hooks.json have timeout specified
- [x] All plugin READMEs have timeout rationale table
- [x] JSON remains valid (no comments in JSON files)

---

## Phase 4: Documentation Cleanup

### Task 8: Add Missing CLAUDE.md Includes [D:1/B:4 → Priority:4.0] 🎯

**Goal:** Use include system to reduce duplication.

**Current includes (4):**
```markdown
@include ~/.claude/includes/across-instances.md
@include ~/.claude/includes/critical-rules.md
@include ~/.claude/includes/task-prioritization.md
@include ~/.claude/includes/web-command.md
```

**Add:**
```markdown
@include ~/.claude/includes/code-style.md
@include ~/.claude/includes/development-philosophy.md
```

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- [x] `across-instances.md` added (done)
- [x] `code-style.md` include added
- [x] `development-philosophy.md` include added
- [x] No functionality lost

---

### Task 9: Remove TodoWrite Duplication from Commands [D:2/B:5 → Priority:2.5] 🚀

**Goal:** Consolidate repeated TodoWrite patterns across command files.

**Current duplication (~200 lines total):**
- `elixir-interview.md` lines 35-46
- `elixir-research.md` lines 32-40
- `elixir-plan.md` lines 38-45
- `elixir-implement.md` lines 22-38
- `elixir-oneshot.md` (multiple sections)
- `elixir-qa.md` (multiple sections)

**Decision: Option 1 - Reference CLAUDE.md** - The "TodoWrite Best Practices" section in CLAUDE.md is already comprehensive. Commands should reference it rather than duplicating.

**Pattern for commands:**
```markdown
Follow TodoWrite best practices from CLAUDE.md. Key points:
- Create todos at START of execution
- Mark ONE task `in_progress` at a time
- Mark `completed` IMMEDIATELY after finishing
```

**Acceptance criteria:**
- [x] Decision made: reference CLAUDE.md
- [x] Commands updated to reference rather than duplicate
- [x] Duplication reduced from ~200 lines to ~30 lines

---

### Task 10: Standardize README Structure [D:3/B:4 → Priority:1.33] 📋

**Goal:** Create consistent README template for all plugins.

**Current variance:**
- credo: 51 lines (minimal)
- elixir-meta: 338 lines (extensive)
- Ratio: 6.6x variance

**Template sections:**
```markdown
# plugin-name

One-line description.

## Installation

## Features

### Hook 1
### Hook 2

## Configuration (if applicable)

## Requirements (if applicable)
```

**Files to modify:**
- All `plugins/*/README.md`

**Acceptance criteria:**
- [ ] All READMEs follow same section order
- [ ] All have Installation section
- [ ] All have Features section with hook descriptions

---

## Phase 5: Polish

### Task 11: Consolidate Duplicate Keywords [D:1/B:3 → Priority:3.0] 🎯

**Goal:** Remove keyword duplication between marketplace.json and plugin.json.

**Current state:**
- Keywords appear in both files
- Sometimes with different ordering

**Decision:** Keywords should live in `plugin.json` only (source of truth), marketplace.json should not duplicate.

**Files to modify:**
- `.claude-plugin/marketplace.json` (remove keywords from plugin entries)

**Acceptance criteria:**
- [x] Keywords removed from marketplace.json
- [x] Keywords only in plugin.json (source of truth)

---

### Task 12: Standardize Shebang and Script Style [D:1/B:2 → Priority:2.0] 🚀

**Goal:** Consistent script formatting.

**Fixes:**
1. All scripts use `#!/usr/bin/env bash` (not `#!/bin/bash`)
2. Consistent JSON formatting: `'{"suppressOutput": true}'` (no extra spaces)
3. Consistent NULL check order: `[[ -z "$VAR" ]] || [[ "$VAR" == "null" ]]`

**Files to modify:**
- All `plugins/*/scripts/*.sh`

**Acceptance criteria:**
- [ ] All shebangs use `#!/usr/bin/env bash`
- [ ] JSON output formatting consistent
- [ ] NULL checks consistent

---

## Execution Order by ROI

| Order | Task | Priority | Rationale |
|-------|------|----------|-----------|
| 1 | 4 (Fix naming) | 6.0 🎯 | Quick wins, high visibility |
| 2 | 5 (Command naming) | 5.0 🎯 | Decision made, just document |
| 3 | 8 (Add includes) | 4.0 🎯 | Quick, reduces CLAUDE.md size |
| 4 | 11 (Keywords) | 3.0 🎯 | Quick cleanup |
| 5 | 9 (TodoWrite dedup) | 2.5 🚀 | Decision made, straightforward |
| 6 | 6 (Author fields) | 2.5 🚀 | Metadata consistency |
| 7 | 1 (Shared library) | 2.25 🚀 | Foundation for tasks 2-3 |
| 8 | 3 (Post-edit migration) | 2.0 🚀 | After shared library |
| 9 | 7 (Timeout docs) | 2.0 🚀 | Documentation in READMEs |
| 10 | 12 (Script style) | 2.0 🚀 | Polish |
| 11 | 2 (Pre-commit migration) | 1.6 🚀 | After shared library |
| 12 | 10 (README template) | 1.33 📋 | Lower priority polish |

---

## Non-Goals (Out of Scope)

| Item | Reason |
|------|--------|
| Rewriting hooks in different language | Bash works, consistency > elegance |
| Automated script generation | Manual control preferred |
| Removing working plugins | All provide value |
| Version number alignment | Independent versioning is correct |
| README length enforcement | Content > uniformity |

---

## Decisions Made

| Question | Decision | Rationale |
|----------|----------|-----------|
| Shared library location | `plugins/_shared/` | Co-located with plugins |
| Author name | DeltaHedge | Current ownership |
| Shebang style | `#!/usr/bin/env bash` | More portable |
| Keywords location | plugin.json only | Single source of truth |
| `/create-plugin` naming | Keep as-is (no prefix) | Not Elixir-specific |
| Timeout documentation | In README.md tables | JSON doesn't support comments |
| TodoWrite duplication | Reference CLAUDE.md | Already documented there |
| `across-instances.md` | Added to all projects | Recognition across instances |

---

## Session Planning

**Session 1: Quick Wins** (Tasks 4, 5, 8, 11)
- Fix naming inconsistencies (files/directories)
- Document command naming exception
- Add missing includes to CLAUDE.md
- Remove duplicate keywords from marketplace.json

**Session 2: Documentation Cleanup** (Tasks 9, 6)
- TodoWrite deduplication in commands
- Standardize author fields

**Session 3: Shared Library Foundation** (Task 1)
- Create `plugins/_shared/lib.sh`
- Extract and test core functions

**Session 4: Script Migrations** (Tasks 2, 3)
- Migrate pre-commit scripts to shared library
- Migrate post-edit scripts to shared library
- Run full test suite

**Session 5: Polish** (Tasks 7, 12, 10)
- Document timeouts in READMEs
- Fix script style consistency
- README template standardization
