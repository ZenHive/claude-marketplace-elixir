#!/usr/bin/env bash
# Block (deny) three command shapes Claude is explicitly told never to run:
#
#   1. `mix phx.server`
#      critical-rules.md § NEVER START THE PHOENIX SERVER —
#      the server is always already running; assume localhost:4000.
#
#   2. Destructive dependency / build operations:
#      `mix deps.clean`, `mix clean`, `mix deps.unlock --all`,
#      `rm -rf _build`, `rm -rf deps`
#      critical-rules.md § NEVER RUN DESTRUCTIVE DEPENDENCY COMMANDS.
#      Allows: `mix deps.unlock --check-unused`, `mix deps.compile <dep> --force`.
#
#   3. Bare `rm` outside of an allow-listed `<tool> rm` wrapper
#      critical-rules.md § Shell Safety — use `git rm` for tracked files,
#      manual delete via file explorer for untracked.
#      Allow-listed wrappers: git / npm / pnpm / yarn / bundle / cargo / gem.
#      Check is segment-aware so `git rm a.ex && rm b.ex` denies the second
#      segment instead of allowing the whole line.
#
# Each block returns a deny-JSON with a permissionDecisionReason naming the
# safe alternative.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/lib.sh"
source "$SCRIPT_DIR/../lib/precommit-utils.sh"

read_hook_input
parse_precommit_input || { emit_suppress_json; exit 0; }

# --- Category 1: mix phx.server --------------------------------------------

if echo "$HOOK_COMMAND" | grep -qE '(^|[[:space:]])mix[[:space:]]+phx\.server([[:space:]]|$)'; then
  REASON="BLOCKED: 'mix phx.server' — the Phoenix server is always already running.

The user starts and stops the server manually. Assume localhost:4000 is up;
to verify behavior, ask the user to check the browser. (See critical-rules.md
§ NEVER START THE PHOENIX SERVER.)"
  emit_deny_json "$REASON" "Blocked: mix phx.server (server is always already running)"
  exit 0
fi

# --- Category 2: destructive deps / build ---------------------------------
# Must NOT match `mix deps.unlock --check-unused` (used by pre-commit-unified.sh
# and legitimately by users) or `mix deps.compile foo --force`.

destructive_match=""
if echo "$HOOK_COMMAND" | grep -qE '(^|[[:space:]])mix[[:space:]]+deps\.clean([[:space:]]|$)'; then
  destructive_match="mix deps.clean"
elif echo "$HOOK_COMMAND" | grep -qE '(^|[[:space:]])mix[[:space:]]+clean([[:space:]]|$)'; then
  destructive_match="mix clean"
elif echo "$HOOK_COMMAND" | grep -qE '(^|[[:space:]])mix[[:space:]]+deps\.unlock[[:space:]]+--all([[:space:]]|$)'; then
  destructive_match="mix deps.unlock --all"
elif echo "$HOOK_COMMAND" | grep -qE '(^|[[:space:]])rm[[:space:]]+-rf?[[:space:]]+(_build|deps)([[:space:]]|/|$)'; then
  destructive_match="rm -rf _build/deps"
fi

if [[ -n "$destructive_match" ]]; then
  REASON="BLOCKED: '$destructive_match' is a destructive dependency / build command.

Most 'corrupt cache' issues are transient. Try one of these first:
  • Re-run \`mix compile\` or \`mix test\` (often the simplest fix)
  • Specific dep issue: \`mix deps.compile <dep_name> --force\`

The command Claude tried to run nukes build artifacts and slows recovery
significantly. Ask the user before running any destructive deps/build command.
(See critical-rules.md § NEVER RUN DESTRUCTIVE DEPENDENCY COMMANDS.)"
  emit_deny_json "$REASON" "Blocked: destructive deps/build command"
  exit 0
fi

# --- Category 3: bare rm outside <tool> rm --------------------------------
# Split the command line on shell segment separators (; && || |) so each
# segment is evaluated independently — `git rm a && rm b` is two segments,
# the second of which is a bare rm that must be denied even though the line
# also contains an allowed `git rm`.
#
# A segment is "allowed" if its first command-token (after stripping leading
# whitespace and `VAR=val` env prefixes) is one of the package-manager
# wrappers (git / npm / pnpm / yarn / bundle / cargo / gem) followed by rm.
# Bare rm denial fires when the first token is `rm` or `sudo rm`.

bare_rm_found=false
while IFS= read -r segment; do
  segment_trimmed="$(printf '%s' "$segment" \
    | sed -E 's/^[[:space:]]+//; s/^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)+//')"
  [[ -z "$segment_trimmed" ]] && continue
  # <tool> rm — allowed wrapper subcommand
  if echo "$segment_trimmed" \
       | grep -qE '^(git|npm|pnpm|yarn|bundle|cargo|gem)[[:space:]]+rm([[:space:]]|$)'; then
    continue
  fi
  # rm or sudo rm — bare destructive shape
  if echo "$segment_trimmed" | grep -qE '^(sudo[[:space:]]+)?rm([[:space:]]|$)'; then
    bare_rm_found=true
    break
  fi
done < <(echo "$HOOK_COMMAND" | tr ';&|' '\n')

if [[ "$bare_rm_found" == "true" ]]; then
  REASON="BLOCKED: bare 'rm' command.

Use one of these instead:
  • \`git rm <path>\` for tracked files
  • Manual delete via file explorer (Finder/VS Code) for untracked files
  • Move to a temp folder if you want a reversible 'delete'

Allowed wrapper subcommands: \`<tool> rm\` where tool ∈
{git, npm, pnpm, yarn, bundle, cargo, gem}.

(See critical-rules.md § Shell Safety — \"Never use rm (including rm -rf) in
docs, scripts, or commands.\")"
  emit_deny_json "$REASON" "Blocked: bare rm (use git rm or manual delete)"
  exit 0
fi

# --- No match — allow through ---------------------------------------------

emit_suppress_json
exit 0
