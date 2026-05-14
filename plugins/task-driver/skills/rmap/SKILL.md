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
| Read one task / many | `rmap show <id> [--json]` · `rmap list --status\|--phase\|--marker\|--bundle [--json]` |
| Pick the next task | `rmap next [--marker M] [--bundle B] [--count N] [--json]` |
| Pick a session-sized bundle | `rmap next-bundle [--json]` · `rmap bundles` to discover them |
| Change status | `rmap status <id> <pending\|in_progress\|blocked\|done\|superseded>` (bulk `1,2,3` atomic) |
| Toggle a marker | `rmap mark <id> +parallel -cx` |
| Add a dependency | `rmap depend <id> on <id>` |
| Create task(s) | `rmap new --from-stdin` (TOML on stdin, atomic batch) — see `task-writing.md` |
| Format a task as a cloud-agent prompt | `rmap delegate <id> --to claude\|codex\|cursor` |
| See what changed vs a git ref | `rmap diff [--verbose] [--json]` |
| Health signals (soft, always exit 0) | `rmap doctor [--json]` |
| Strict gates (pre-commit / CI) | `rmap validate` · `rmap validate --check-render` |
| Render after editing tasks.toml directly | `rmap render` (or `rmap watch` for live re-render) |

All mutators **validate-then-write**: an invalid mutation leaves `tasks.toml` byte-equal to its prior state. `--json` envelopes on the read commands are append-only stable surfaces.

### D/B/U mapping

rmap's scoring **is** the `task-prioritization.md` framework, executable:

- `scores = { d, b, u }` on each `[[task]]` ⇒ the `[D:X/B:Y/U:Z]` you'd otherwise hand-write
- `eff = (b + u) / (2 × d)`, computed at read time, never stored — same formula, same tiers (`≥2.0 🎯 / ≥1.5 🚀 / ≥1.0 📋 / else ⚠️`)
- `scored_at` older than 30 days renders an `Eff:W?` decay suffix

Set scores in `tasks.toml` (via `rmap new` or editing the file); never hand-format the bracket — `rmap render` produces it.

### Status & marker vocabulary

- **status:** `pending | in_progress | blocked | done | superseded` — transitions go through `rmap status`. `blocked` requires a `blocked_reason`.
- **markers:** `parallel | cx | csr | bug | security | docs` — `parallel` is the old `[P]`; `cx` / `csr` are the Codex / Cursor delegation markers.

### Migrating a hand-edited ROADMAP.md

rmap has no `import` command yet — migration is a one-time manual pass:

1. Author `roadmap/tasks.toml` from the existing markdown: `schema_version = 1`, `project`, `default_branch`, `[phases.N]` tables, `[bundles.<name>]` if used, one `[[task]]` per task with `scores`, `status`, `title`, and `body` / `acceptance_criteria` carried from the prose.
2. Replace the hand-maintained task tables in `ROADMAP.md` with marker pairs — `<!-- TASKS:BEGIN phase=N -->` … `<!-- TASKS:END -->` per phase (optional `<!-- FOCUS:BEGIN/END -->` and `<!-- MERMAID:BEGIN/END -->` pairs). Prose, headings, and links outside the markers are byte-preserved across every render.
3. `rmap validate` → `rmap render` → diff-check the rendered `ROADMAP.md` against intent.
4. Commit `roadmap/tasks.toml` + the marker-fied `ROADMAP.md` together.

### Cross-references

- `task-prioritization.md` — the D/B/U framework, tiers, ceremony floor, exclusions that rmap executes
- `task-writing.md` — how to write a task's `body` / `acceptance_criteria`; the `rmap new --from-stdin` shape
