# Codex Hooks and Plugin State

Last updated: 2026-04-20

╔══════════════════════════════════════════════════════════════════════╗
║ AI CODER PROMPT: This file records the CURRENT Codex integration    ║
║ state for this repo and one user's local setup. Treat it as an      ║
║ operational handoff, not a product spec. Re-verify behavior when    ║
║ Codex versions change.                                              ║
╚══════════════════════════════════════════════════════════════════════╝

## Purpose

This repo started as a Claude marketplace. We extracted a Codex-friendly subset
for local use and then validated which parts of that workflow actually work in
current Codex.

This document captures:
- what was synced
- where active Codex state lives
- what behavior was verified in real Codex sessions
- what is still blocked by current Codex hook support
- what upstream work already exists

## Local State

This section describes the verified local setup on `/Users/efries/...`.

| Item | Current state |
|------|---------------|
| Codex plugin sync script | `scripts/sync-codex-plugins.py` |
| Local plugin install root | `~/plugins/` |
| Personal marketplace | `~/.agents/plugins/marketplace.json` |
| Active discovered hooks | `~/.codex/hooks.json` |
| Codex feature flag | `~/.codex/config.toml` with `[features] codex_hooks = true` |

### Synced plugin subset

- `elixir`
- `phoenix`
- `staged-review`
- `task-driver`
- `portfolio-strategy`

### Intentionally excluded from Codex sync

- `serena`
- `elixir-workflows`
- `git-commit`
- `notifications`
- `code-quality`

## What We Verified

### Skills and plugin loading: working

In fresh Codex sessions, the local plugins appeared correctly after install.

Verified visible skills included:
- `elixir:hex-docs-search`
- `elixir:usage-rules`
- `elixir:tidewave-guide`
- `elixir:integration-testing`
- `phoenix:phoenix-setup`
- `phoenix:nexus-template`
- `task-driver:task-driver`
- `staged-review:code-review`

Key learning:
- marketplace entries make plugins available
- plugins still need to be installed/enabled in Codex
- fresh sessions then load the skills correctly

### Bash hooks: working

After moving hook registration into `~/.codex/hooks.json`, real Codex sessions
showed visible `PreToolUse` interception for Bash commands.

Verified visible behavior:
- `mix test` was blocked and redirected to `mix test.json`
- `mix dialyzer` was blocked and redirected to `mix dialyzer.json`

Key learning:
- current Codex hook discovery is driven by discovered `hooks.json` files
- plugin-local hook files alone were not enough for active hook behavior

### Pre-commit hook: likely running, but silent on success

The generated `~/.codex/hooks.json` includes the `pre-commit-unified.sh` hook.

Observed behavior:
- `git commit --dry-run -m "hook smoke test"` was not visibly blocked
- output looked like normal Git dry-run output

Interpretation:
- this does not prove the hook failed to run
- in the Phoenix playground app, `mix.exs` defines a `precommit` alias
- `pre-commit-unified.sh` is designed to defer to `mix precommit` and emit
  suppressed output on success

So the most likely reading is:
- the hook matched the command
- the success path was intentionally silent

### Edit-time hooks: not active in released Codex path we tested

We tested an edit-only style probe in `playground_test/lib/playground_test/example.ex`
by introducing bad spacing and checking whether any edit-time validation ran.

Observed behavior:
- the edit completed with normal patch success output only
- the bad spacing remained immediately after the edit
- there was no visible hook annotation
- no positive evidence showed `mix format` or `mix test` running

Interpretation:
- this is expected with the current exported hook setup
- we only export hooks Codex supports reliably today
- Codex in the tested version only gave us working hook behavior for `Bash`

Important distinction:
- the source `plugins/elixir/hooks/hooks.json` still contains Claude-era
  `Edit|Write|MultiEdit` and `Read` hook definitions
- those are not part of the active discovered Codex hook file we export today

## Architecture Decision

The current working model is:

- plugins are for skills
- `~/.codex/hooks.json` is for active hooks

This was an important correction. Earlier attempts treated plugin-local hooks as
if Codex would activate them directly. Current docs and real behavior showed the
working setup is:

1. sync/install plugins for skills
2. export supported hooks into a discovered `hooks.json` layer

## Current Sync Behavior

`scripts/sync-codex-plugins.py` now does three distinct things:

1. Sync include-backed core skills through:
   `~/.codex/skills/sync-claude-includes/scripts/sync_claude_includes.py`
2. Sync supported plugin skills into `~/plugins/<plugin>/`
3. Export retained Elixir hooks into `~/.codex/hooks.json`

Important implementation detail:
- the sync tool no longer writes a plugin manifest `hooks` field
- instead, it writes a discovered hook layer and merges managed Elixir hook
  entries without wiping unrelated existing hooks

## Supported Hook Export Today

The exported Codex hook layer currently retains only:
- `PreToolUse` for `Bash`
- `PostToolUse` for `Bash`
- `UserPromptSubmit`

Managed Elixir scripts currently exported into active Codex hooks:
- `pre-commit-unified.sh`
- `suggest-test-failed.sh`
- `phx-new-check.sh`
- `prefer-test-json.sh`
- `prefer-dialyzer-json.sh`
- `suggest-test-include.sh`
- `reset-test-tracker.sh`
- `recommend-docs-lookup.sh`

Not currently exported into active Codex hooks:
- `post-edit-check.sh`
- `ash-codegen-check.sh`
- `recommend-docs-on-read.sh`

Reason:
- the released Codex workflow we validated supports Bash hooks in practice
- edit/read hook coverage is still incomplete in the released path we tested

## Upstream Status

We checked `openai/codex` before filing anything new.

Relevant upstream items:
- Issue `#16732`: `ApplyPatchHandler doesn't emit PreToolUse/PostToolUse hook event. Hooks only fire for Bash tool.`
- PR `#18391`: `fix(core): emit hooks for apply_patch edits`
- PR `#18385`: `Support MCP tools in hooks`

Action already taken:
- added a workflow comment to PR `#18391` describing the Elixir/Phoenix
  post-edit validation need and why `apply_patch` hook events matter

## What To Do Next

### If you want to resync the local Codex state

Run:

```bash
python3 scripts/sync-codex-plugins.py --apply
```

### If you want to test current Bash hook behavior

Use commands like:
- `mix test`
- `mix dialyzer`
- `git commit --dry-run -m "hook smoke test"`

Expected:
- `mix test` should be blocked in favor of `mix test.json`
- `mix dialyzer` should be blocked in favor of `mix dialyzer.json`
- commit behavior may stay silent on success

### If you want post-edit validation in Codex today

Current options:
- wait for upstream `apply_patch` hook support to land
- or implement a `Stop`-hook-based fallback that validates changed Elixir files
  at turn end

Tradeoff:
- `Stop` is weaker and later than true post-edit validation
- but it is the only realistic fallback until file-edit hook support lands

## Decision Routing

| Question | Current answer |
|----------|----------------|
| Are local plugins loading? | Yes, after install and fresh session |
| Are Bash hooks working? | Yes |
| Are plugin-local hooks alone enough? | No |
| Are edit-time hooks working in the tested released path? | No |
| Should we open a duplicate upstream issue? | No, not for `apply_patch` |
| Best upstream reference | PR `#18391` and issue `#16732` |

## Bottom Line

The important learnings are:

- plugin skills are working
- Bash hook interception is working
- active Codex hooks must live in discovered `hooks.json` layers
- edit-time Elixir validation is still not available in the released path we
  validated
- the correct near-term strategy is to track upstream `apply_patch` hook work
  and use a `Stop`-hook fallback only if the workflow pressure justifies it
