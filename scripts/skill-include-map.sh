#!/usr/bin/env bash
# Single source of truth for SKILL.md ↔ include mapping.
# Sourced by both:
#   - scripts/sync-skills-from-includes.sh (writes the synced bodies)
#   - plugins/marketplace-hygiene/scripts/block-skill-edits.sh (denies direct edits)
#
# Format: "relative/path/to/SKILL.md:include-filename.md"
# Adding a new entry here registers the skill as auto-synced; the block hook
# starts denying direct edits to it on the next session.

MAPPINGS=(
  "plugins/elixir/skills/zen-websocket/SKILL.md:zen-websocket.md"
  "plugins/phoenix/skills/phoenix-setup/SKILL.md:phoenix-setup.md"
  "plugins/phoenix/skills/nexus-template/SKILL.md:nexus-template.md"
  "plugins/elixir/skills/ex-unit-json/SKILL.md:ex-unit-json.md"
  "plugins/elixir/skills/dialyzer-json/SKILL.md:dialyzer-json.md"
  "plugins/elixir/skills/development-commands/SKILL.md:development-commands.md"
  "plugins/elixir/skills/elixir-setup/SKILL.md:elixir-setup.md"
  "plugins/elixir/skills/web-command/SKILL.md:web-command.md"
  "plugins/elixir/skills/roadmap-planning/SKILL.md:task-prioritization.md"
  "plugins/elixir/skills/oxc/SKILL.md:oxc.md"
  "plugins/elixir/skills/quickbeam/SKILL.md:quickbeam.md"
  "plugins/elixir/skills/npm-ci-verify/SKILL.md:npm-ci-verify.md"
  "plugins/elixir/skills/npm-security-audit/SKILL.md:npm-security-audit.md"
  "plugins/elixir/skills/npm-dep-analysis/SKILL.md:npm-dep-analysis.md"
  "plugins/portfolio-strategy/skills/portfolio-strategy/SKILL.md:portfolio-strategy.md"
  "plugins/elixir/skills/reach/SKILL.md:reach.md"
  "plugins/elixir/skills/elixir-volt/SKILL.md:elixir-volt.md"
  "plugins/elixir/skills/agent-economy/SKILL.md:agent-economy.md"
  "plugins/elixir/skills/api-toolkit/SKILL.md:api-toolkit.md"
  "plugins/elixir/skills/upstream-pr-workflow/SKILL.md:upstream-pr-workflow.md"
  "plugins/cloud-delegation/skills/linear-workflow/SKILL.md:linear-workflow.md"
  "plugins/cloud-delegation/skills/linear-queue/SKILL.md:linear-queue.md"
  "plugins/cloud-delegation/skills/agent-dispatch/SKILL.md:agent-dispatch.md"
  "plugins/cloud-delegation/skills/agent-pr-review/SKILL.md:agent-pr-review.md"
  "plugins/cloud-delegation/skills/flow-review/SKILL.md:flow-review.md"
  "plugins/cloud-delegation/skills/cloud-agent-environments/SKILL.md:cloud-agent-environments.md"
  "plugins/cloud-delegation/skills/sprite-claude-code/SKILL.md:sprite-claude-code.md"
  "plugins/elixir/skills/git-worktrees/SKILL.md:worktree-workflow.md"
  "plugins/dev-lifecycle/skills/dev-lifecycle/SKILL.md:dev-lifecycle.md"
  "plugins/task-driver/skills/rmap/SKILL.md:rmap.md"
)
