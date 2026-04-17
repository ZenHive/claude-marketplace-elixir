#!/usr/bin/env bash
# Sync SKILL.md files from canonical ~/.claude/includes/*.md sources.
# Preserves SKILL.md frontmatter (---...---), replaces body with include content.
#
# Usage:
#   ./scripts/sync-skills-from-includes.sh          # sync all mapped skills
#   ./scripts/sync-skills-from-includes.sh --dry-run # show what would change

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INCLUDES_DIR="$HOME/.claude/includes"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# Mapping: skill_path -> include_filename
# Format: "relative/path/to/SKILL.md:include-filename.md"
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
)

synced=0
skipped=0
errors=0

for mapping in "${MAPPINGS[@]}"; do
  skill_rel="${mapping%%:*}"
  include_name="${mapping##*:}"

  skill_path="$REPO_ROOT/$skill_rel"
  include_path="$INCLUDES_DIR/$include_name"

  # Validate both files exist
  if [[ ! -f "$skill_path" ]]; then
    echo "SKIP: $skill_rel (skill file not found)"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ ! -f "$include_path" ]]; then
    echo "SKIP: $skill_rel (include $include_name not found)"
    skipped=$((skipped + 1))
    continue
  fi

  # Extract frontmatter (everything between first --- and second ---)
  frontmatter=$(awk '/^---$/{c++; if(c==2){print; exit}} {print}' "$skill_path")

  if [[ -z "$frontmatter" ]] || ! echo "$frontmatter" | head -1 | grep -q '^---$'; then
    echo "ERROR: $skill_rel (no valid frontmatter found)"
    errors=$((errors + 1))
    continue
  fi

  # Build new SKILL.md: frontmatter + blank line + sync note + blank line + include content
  include_content=$(cat "$include_path")

  new_content="${frontmatter}

<!-- Auto-synced from ~/.claude/includes/${include_name} — do not edit manually -->

${include_content}"

  # Check if content actually changed
  current_content=$(cat "$skill_path")
  if [[ "$current_content" == "$new_content" ]]; then
    echo "OK:   $skill_rel (already in sync)"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "WOULD SYNC: $skill_rel <- $include_name"
    synced=$((synced + 1))
  else
    echo "$new_content" > "$skill_path"
    echo "SYNCED: $skill_rel <- $include_name"
    synced=$((synced + 1))
  fi
done

echo ""
echo "--- Summary ---"
echo "Synced:  $synced"
echo "Skipped: $skipped"
echo "Errors:  $errors"

if [[ "$DRY_RUN" == true ]]; then
  echo "(dry run — no files modified)"
fi
