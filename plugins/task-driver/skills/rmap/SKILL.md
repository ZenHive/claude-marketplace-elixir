---
name: rmap
description: Use when working with a project roadmap — picking the next task, scoring with D/B/U, changing task status or markers, creating tasks, rendering ROADMAP.md, or migrating a hand-edited ROADMAP.md to the rmap substrate. rmap is the CLI that manages roadmap/tasks.toml as canonical source and renders ROADMAP.md + roadmap/data.json. Language-agnostic.
allowed-tools: Read, Bash
---

<!-- Auto-synced from ~/.claude/includes/rmap.md — do not edit manually -->

## rmap — Roadmap Substrate

`rmap` is a single-binary CLI that manages `roadmap/tasks.toml` as the typed source of truth for a project's roadmap, rendering `ROADMAP.md` (human view) and `roadmap/data.json` (agent view) from it. **Every project uses rmap** — `tasks.toml` is canonical, `ROADMAP.md` is generated. Hand-editing task tables in `ROADMAP.md` is legacy; migrate (see below).

This file is the **decision layer** — *which* command, *when*. The authoritative command contract is `rmap --help` / `rmap schema` (the live `tasks.toml` field list, derived from the source) plus rmap's own CI-gated `SKILLS.md` in the rmap repo. Don't hand-maintain a parallel command reference here.

### Project layout

```
<project_root>/
├── ROADMAP.md         # rendered — hand-edited prose outside marker pairs is byte-preserved
└── roadmap/
    ├── tasks.toml     # canonical source — author this
    └── data.json      # generated — agents read it for structured access
```

`rmap` walks ancestors of cwd to find `roadmap/tasks.toml`.

### Command surface, by intent

| Intent | Command |
|---|---|
| Read one task / many | `rmap show <id> [--json]` · `rmap list --status\|--phase\|--marker\|--bundle\|--milestone [--json]` |
| Pick the next task | `rmap next [--marker M] [--bundle B] [--milestone V] [--count N] [--json]` |
| Pick a session-sized bundle | `rmap next-bundle [--json]` · `rmap bundles` to discover them |
| List release lines / pin to a release | `rmap milestones [--has-next\|--status\|--json]` · `rmap milestone <id> <name\|none>` |
| Change status | `rmap status <id> <pending\|in_progress\|blocked\|done\|superseded> [--implemented "..."]` (bulk `1,2,3` atomic; `done` requires `implemented`) |
| Toggle a marker | `rmap mark <id> +parallel -cx` |
| Add a dependency | `rmap depend <id> on <id>` |
| Create task(s) | `rmap new --from-stdin` (TOML on stdin, atomic batch) — see `task-writing.md` |
| Format a task as a cloud-agent prompt | `rmap delegate <id> --to claude\|codex\|cursor` |
| Migrate a hand-edited ROADMAP.md | `rmap import` |
| See what changed vs a git ref | `rmap diff [--verbose] [--json]` |
| Health signals (soft, always exit 0) | `rmap doctor [--json]` |
| Strict gates (pre-commit / CI) | `rmap validate` · `rmap validate --check-render` |
| Render after editing tasks.toml directly | `rmap render` (or `rmap watch` for live re-render) |

All mutators **validate-then-write**: an invalid mutation leaves `tasks.toml` byte-equal to its prior state. `--json` envelopes on the read commands are append-only stable surfaces.

### Batches are derived, not declared

`rmap next-bundle` returns a session-sized **bundle** — a set of related pending tasks. A *batch* is a finer-grained slice of that bundle: the executor groups bundle tasks by `depends_on` into successive layers of disjoint work (per `workflow-philosophy.md` § "Batched Execution"). There is no `rmap batch` command — batch derivation is the executor's job, not the source-of-truth's. Hierarchy: phase ⊇ bundle ⊇ batch ⊇ task.

### D/B/U mapping

rmap's scoring **is** the `task-prioritization.md` framework, executable:

- `scores = { d, b, u }` on each `[[task]]` ⇒ the `[D:X/B:Y/U:Z]` you'd otherwise hand-write
- `eff = (b + u) / (2 × d)`, computed at read time, never stored — same formula, same tiers (`≥2.0 🎯 / ≥1.5 🚀 / ≥1.0 📋 / else ⚠️`)
- `scored_at` older than 30 days renders an `Eff:W?` decay suffix

Set scores in `tasks.toml` (via `rmap new` or editing the file); never hand-format the bracket — `rmap render` produces it.

### Status & marker vocabulary

- **status:** `pending | in_progress | blocked | done | superseded` — transitions go through `rmap status`. `blocked` requires a `blocked_reason`; `done` requires `implemented` (set inline via `--implemented "..."`, or pre-populated in `tasks.toml`; on a TTY without the flag, `rmap status` prompts).
- **markers:** `parallel | cx | csr | bug | security | docs` — `parallel` is the old `[P]`; `cx` / `csr` are the Codex / Cursor delegation markers.
- **milestone status:** `pending | active | done` — distinct vocabulary from task status. Flip by hand-editing `[milestones.<name>].status` (no mutator yet); `active` milestones sort first in `rmap milestones` and are the load-bearing affordance for the "what release am I cutting next?" query.

### Milestones — first-class release lines

`[milestones.<name>]` is a fourth top-level concept alongside phases / bundles / markers. **Phase** orders work, **bundle** groups topically, **markers** modify execution, **milestone** pins a task to a release line. Milestones cross phases by design: a `v1.0` cut typically pulls from several phases.

- Author the table in `tasks.toml`: `[milestones.v0_1] name = "..." order = N status = "active" target_version = "0.1.0"`. `target_version` is optional free-text.
- Pin a task: `rmap milestone <id> v0_1` (or set `milestone = "v0_1"` directly). Unpin: `rmap milestone <id> none`. One milestone per task.
- Discovery: `rmap milestones` (table view with done/total counts + next-task glyph + active-first sort); `rmap milestones --json` for the agent envelope.
- Drive a release line: `rmap next --milestone v0_1` returns the next pending task in that release; composes with `--bundle`, `--phase`, `--marker`.
- `rmap delegate` surfaces the milestone in `## Context` as `- Milestone: v0_1 (target=0.1.0)` so the target agent knows which release ships their work.
- `rmap render` adds a conditional `🚀 **<milestone>** ·` segment to the task row in `ROADMAP.md` — rows without a milestone render byte-identically to before.

### `body` vs `implemented`

- `body` = original task definition / intent (never mutated after creation — the spec at scoping time).
- `implemented` = what was actually built and why (required when `status = "done"`; `rmap show` renders both side-by-side as `body (original intent):` / `implemented (what shipped):` when present together). For trivial tasks where delivery matched the spec, `implemented = "as specified in body"` is honest and durable.

### Pinning an LLM model per task

`model = "<model-id>"` on a `[[task]]` records which LLM should do the work — free-text, unvalidated (model IDs churn). `rmap delegate` surfaces it as a `- Model:` bullet in the prompt's `## Context` so the target agent knows which model to run. Settable at creation via `rmap new` (interactive + `--from-stdin`) or a direct edit. Distinct from `assignee` (who owns it) and `rmap delegate --to` (which agent *environment*).

### Migrating a hand-edited ROADMAP.md

Run `rmap import` — it emits a paste-ready prompt that walks an agent through converting one or more hand-edited `ROADMAP.md` files into `roadmap/tasks.toml` (schema, marker pairs, validate → render → diff-check). One-time, LLM-driven; the prompt carries the detail so this include doesn't have to.

### Cross-references

- `task-prioritization.md` — the D/B/U framework, tiers, ceremony floor, exclusions that rmap executes
- `task-writing.md` — how to write a task's `body` / `acceptance_criteria`; the `rmap new --from-stdin` shape
- `workflow-philosophy.md` § "Batched Execution" — canonical rule for the batch derivation referenced in § "Batches are derived, not declared"
