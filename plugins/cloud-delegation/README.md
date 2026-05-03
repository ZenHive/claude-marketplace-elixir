# cloud-delegation

Linear-as-queue + cloud-agent (Codex, Cursor) delegation workflow.

Two skills, both bodies auto-synced from the canonical includes in `~/.claude/includes/`. Don't edit the SKILL.md bodies directly — they get overwritten by `scripts/sync-skills-from-includes.sh`.

## Skills

| Skill | Purpose | Canonical source |
|---|---|---|
| `linear-workflow` | Reviewer / dispatcher view: Linear MCP setup, workspace shape, per-agent delegation flows (Codex + Cursor), polling for ready-to-review, push-back-vs-fix-locally matrix, comment-fetch from both GitHub PR and Linear issue, cross-repo coordination, issue-body-as-prompt template | `~/.claude/includes/linear-workflow.md` |
| `cloud-agent-environments` | Agent's-own-env reference: what each cloud agent's harness can / can't do (hex.pm, mix tasks, Tidewave, external HTTP), runtime gotchas, AGENTS.md generation workflow | `~/.claude/includes/cloud-agent-environments.md` |

## When to install this plugin

Adopt when:

- A repo uses cloud-agent delegation (Codex, Cursor) and wants the queue / push-back / review patterns documented in-repo via skills rather than only via per-user CLAUDE.md `@`-imports.
- The repo's own `AGENTS.md` references Linear-as-queue conventions; installing the plugin makes the same reference material available as a discoverable skill, not just a manual import.

Skip when:

- The repo doesn't use Linear or cloud-agent delegation.
- The reference material lives in the user's CLAUDE.md `@`-import chain and that's sufficient — the plugin is value-add when team members or fresh sessions need the skill discoverable in a marketplace search, not strictly required for a single-user setup.

## Linear MCP tools referenced

The skills reference these Linear MCP tools (install the Linear MCP server first):

- `mcp__linear-server__list_issues` / `get_issue` / `save_issue`
- `mcp__linear-server__list_comments` / `save_comment`
- `mcp__linear-server__list_users` (look up agent ids by `displayName`)
- `mcp__linear-server__list_projects` / `save_project`

See `~/.claude/includes/linear-workflow.md` § "MCP Tool Reference" for the full surface.

## Sync workflow

The two SKILL.md files are kept in sync with the canonical includes via the marketplace's `scripts/sync-skills-from-includes.sh`. After editing either include:

```bash
./scripts/sync-skills-from-includes.sh
```

This preserves the SKILL.md frontmatter (name, description, allowed-tools) and replaces the body with the include content.
