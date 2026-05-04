---
name: linear-workflow
description: Use when delegating self-contained tasks to a cloud agent (Codex, Cursor, or others). Covers Linear MCP setup, workspace shape (one team, one project per repo, label-as-queue-selector), per-agent delegation flows (Codex via cx-eligible label + delegate field; Cursor via cursor-eligible + delegate), polling for ready-to-review (PR attachment is authoritative, not Linear status), push-back-vs-fix-locally matrix split by agent capability, fetching existing comments from both the GitHub PR and the Linear issue before auditing, cross-repo coordination via relatedTo / blocks, and the issue-body-as-prompt template. Sibling of cloud-agent-environments (the agent's-own-env reference).
allowed-tools: Read, Grep, Glob, Bash
---

<!-- Auto-synced from ~/.claude/includes/linear-workflow.md — do not edit manually -->

## Linear-as-Queue Workflow

Cross-repo issue tracking via Linear MCP, primarily for **cloud-agent delegation** (Codex, Cursor, others as the lineup grows) and **multi-repo coordination**. The shape is generic — any repo can adopt it. Family-specific workspace details (team key, project IDs, repo↔project mapping) belong in a separate workspace include or per-repo CLAUDE.md, **not here**.

### When to Adopt

Use Linear-as-queue when:

- **Cloud-agent delegation is in active use.** `[CX]` (Codex) or `[CSR]` (Cursor) tasks need a queue the agent can poll; ROADMAP.md alone isn't pollable.
- **Work spans 2+ repos with cross-cutting issues.** "Library release → downstream-app bump" deserves linked issues, not a single sprawling task.
- **You want issue state to survive across Claude sessions and the IDE.** Linear's UI/Slack/email integrations beat ROADMAP.md for keeping work top-of-mind.

Don't adopt when:

- **Single-repo with a clean ROADMAP.md is doing the job.** D/B-scored task lists in markdown are simpler and Git-versioned.
- **No cloud-agent delegation in flight.** Linear's main lift here is being the handoff queue. Without a delegate marker, ROADMAP.md does what Linear would.
- **The work fits in a TodoWrite session.** Don't promote ephemeral within-session tasks into Linear.

### MCP Registration

Linear is one workspace per user — register the MCP server at **user scope** so every project picks it up automatically:

```bash
claude mcp add --scope user --transport http linear-server https://mcp.linear.app/mcp
```

| Scope | Behavior |
|---|---|
| `user` (recommended) | Available in every Claude session. Single registration. |
| `local` (per-project) | Only the project where it was added sees the server. Useful only if Linear is intentionally siloed to one repo. |
| `project` (`.mcp.json`) | Avoid for Linear — `.mcp.json` is checked-in and shared with collaborators who may not have Linear access. |

**Tidewave parallel:** Tidewave is per-project (each repo has a unique port → `.mcp.json` makes sense). Linear is one workspace serving all repos → user-scope is the right shape. Don't reflexively copy the Tidewave registration pattern.

Verify with `claude mcp list` — should show `linear-server` connected. Restart Claude Code after registration if tools don't appear.

### Workspace Shape

Linear hierarchy: **Workspace → Teams → Projects → Issues**, with optional Cycles, Milestones, and Initiatives.

Recommended pattern:

- **One team per workspace** is fine for a personal portfolio. Teams matter when multiple humans need separate workflows; solo work doesn't need that split.
- **One project per repo.** Clean `project: <repo>` filter on every `save_issue`. Cross-repo work uses `relatedTo` between issues across projects.
- **Workspace-wide labels** — queue selectors that `staged-review:commit-review` and the agents themselves filter on:
  - `cx-eligible` — Codex-eligible (env-constrained; see § "Cloud Agent Environments")
  - `cursor-eligible` — Cursor-eligible (broader than Codex; hex.pm + mix tasks reachable)
  - Generic: `Bug`, `Feature`, etc.
- **Status flow** (default Linear team workflow):
  `Backlog` → `Todo` → `In Progress` → `In Review` → `Done` (plus `Canceled`, `Duplicate`)

**Alternative** (one mega-project + repo-tagged labels): only when project-create permissions are restricted or when the repo set churns weekly. The cross-repo `relatedTo` story is harder, and project-level filtering in the Linear UI breaks down. Treat as escape hatch.

### Codex Delegation Flow

This builds on `task-prioritization.md` § "Codex Delegation (`[CX]`)" — read that first for the eligibility criteria. The Linear-specific bits:

1. **Create issue** with:
   - `team: <team>` (your workspace's team, e.g. `INE`)
   - `project: <repo project>` (matches the on-disk repo)
   - `labels: ["cx-eligible"]`
   - `delegate: "Codex"` field
   - **Body = the prompt.** Sections: Context / Task / Acceptance criteria / Out of scope / File paths / Scoring / Reviewer note. See `task-writing.md` — issue bodies follow the same "WHAT, not HOW" rule as ROADMAP rows.
   - Initial status: `Todo` (not `Backlog` — Codex polls `Todo`+).

2. **Codex picks it up.** *Intended* flow: transitions to `In Progress`, opens a PR on the linked repo, transitions to `In Review` when the PR is open. **Observed** flow: transitions are unreliable — sometimes the issue stays at `Backlog` (no PR auto-open), sometimes the PR auto-opens but status stays at `In Progress`, sometimes the canonical flow fires correctly. Don't rely on `In Review` as the readiness signal. **Canonical fix:** see § "Agent Status-Transition Guidance" — the status flip is the agent's responsibility, not Linear's, and the workspace-level "Additional guidance for agents" is the right place to enforce it.

3. **Local Claude session reviews** via `staged-review:commit-review` skill — fetches the PR, runs the review harness (which Codex couldn't run for itself given its env constraints), posts verdict back to the Linear issue (or to the PR thread).

4. **Pushing back to Codex:** post a Linear comment on the issue describing the blocker, or comment on the GitHub PR. Codex picks up Linear comments via the Linear→Codex integration and amends the PR.

5. **User merges.** Per `critical-rules.md` § "DON'T AUTO-MERGE PRS" — the verdict is informational, the merge is the user's call. Issue auto-transitions to `Done` on merge if the GitHub integration is wired.

This is the same implementer/reviewer handoff shape from `workflow-philosophy.md` § "Implementer / Reviewer Handoff" — Codex is the implementer, local Claude is the reviewer, the user is the merge gate. Linear is just the queue routing the handoff.

### Cursor Delegation Flow

Same shape as the Codex flow with **broader eligibility**. Cursor's cloud environment can reach hex.pm and run `mix` tasks (verified empirically in early Cursor round-trip testing — see § "Cloud Agent Environments"), so the eligibility criteria from `task-prioritization.md` § "Codex Delegation" relax: Cursor can take tasks Codex can't.

1. **Create issue** with:
   - `team: <team>`
   - `project: <repo project>`
   - `labels: ["cursor-eligible"]`
   - `delegate: "Cursor"` field
   - **Body = the prompt** — same template as Codex (Context / Task / Acceptance criteria / Out of scope / File paths / Scoring / Reviewer note).
   - Initial status: `Todo`.

2. **Cursor picks it up.** *Intended* flow: Cursor's Background Agent transitions `Todo` → `In Progress`, opens a PR with body markers (`<!-- CURSOR_AGENT_PR_BODY_BEGIN -->` / `<!-- CURSOR_AGENT_PR_BODY_END -->`), transitions to `In Review`. **Observed** flow: in early Cursor round-trips, the PR auto-opened but status stayed at `In Progress` — same partial-transition failure mode as Codex. Don't rely on `In Review` as the readiness signal. **Canonical fix:** see § "Agent Status-Transition Guidance" — Linear confirmed the status flip is the agent's responsibility, not a built-in Linear behavior, and is enforced via workspace-level "Additional guidance for agents."

3. **Cursor self-validates before opening the PR** — verified `mix test.json --quiet`, `mix credo --strict`, `mix format --check-formatted`, targeted `mix test test/...` runs all happen in Cursor's harness. PRs ship with the harness already green from Cursor's side. The local `commit-review` reviewer's job becomes the **5-category audit** + acceptance-criteria cross-reference, not "did the harness pass" (that's expected baseline).

4. **Pushing back to Cursor:** post a Linear comment on the issue with `@cursor` mention. The Linear-displayName for Cursor's Background Agent is `cursor` (id `b8668f6b-992f-4152-9e59-13b6fe1f599b`). **Verified channel** (early Cursor round-trip testing, 2026-05): Cursor picks up `@cursor` mentions on Linear comments within ~5 min, amends the PR with a fresh commit, posts confirmation comments back on the issue, and reruns the harness. A verbatim code-suggestion push-back was applied surgically with no scope creep. Linear @-mention is preferred over GitHub PR comment for Cursor push-back — keeps the conversation thread on the issue.

5. **User merges.** Same rule — verdict is informational, user merges per `critical-rules.md` § "DON'T AUTO-MERGE PRS".

### Cloud Agent Environments

Cloud-agent envs differ in what they can reach during their work session. The differences shape both delegation eligibility and the push-back-vs-fix-locally calculus when reviewing their PRs.

#### Codex Cloud Constraints

**Codex cloud has no internet access.** Structural, not a configuration gap:

- **No hex.pm.** Codex cannot verify hex-package API signatures. Observed failure mode: a Codex PR shipped `assert_received/2` with a timeout int as 2nd arg (which is the `failure_message :: binary()` slot — should have been `assert_receive/3`). Codex was guessing from training data because it couldn't look up the macro signature.
- **No Tidewave.** Codex cannot run `mcp__tidewave__project_eval`, inspect runtime state, or query live data sources.
- **No external HTTP.** Codex cannot fetch live API responses, RFCs, EIPs, or reference implementations during its work session.
- **Allowlist exists but doesn't fix hex.pm.** Per `feedback_codex_sandbox_pr_gap.md`: post-allowlist, hex.pm remains unreachable; PRs frequently arrive without local test evidence (Codex couldn't run `mix test` against current deps).

**Implications for `[CX]` eligibility** (codified in `task-prioritization.md` § "Codex Delegation"): tasks that need third-party signature verification, live-data exploration, mix-task validation, or external API fetches are NOT good `[CX]` candidates — keep them local.

#### Cursor Cloud Capabilities

**Cursor cloud has hex.pm + can run mix tasks.** Verified in round-trip testing: a Cursor PR ran `mix test.json --quiet`, `mix credo --strict`, targeted `mix test`, and `mix format --check-formatted` end-to-end before opening.

What Cursor can do that Codex can't:

- **hex.pm reachable** — verifies third-party hex-package API signatures. The `assert_received` vs `assert_receive` class of bug shouldn't recur on Cursor PRs because Cursor can fetch the macro signature itself.
- **Runs mix tasks** — `mix test`, `mix credo --strict`, `mix format --check-formatted`, `mix dialyzer.json --quiet` (provided the PLT cache builds in the Cursor env), `mix test --cover`. Cursor can self-validate before opening the PR.
- **Auto-generates AGENTS.md** — Cursor opens PRs that scaffold an `AGENTS.md` for its own env (the env-specific paths, mix command tables, mock client names, etc.). Repos that already have an AGENTS.md generated from CLAUDE.md should close those PRs and redirect to the canonical generator (`scripts/sync-agents-md.sh` in the marketplace plugin).
- **Likely full HTTP** — not yet stress-tested on RFC/EIP fetches or arbitrary external APIs; treat as broadly available pending counter-evidence.

What Cursor still can't do (assume — pending verification):

- **No Tidewave** — Cursor's env doesn't have `mcp__tidewave__project_eval` access. Tasks needing live-data diagnosis stay local.

**Implications for `[CSR]` eligibility:** broader than `[CX]`. Tasks requiring hex.pm verification, third-party hex-API correctness, or running mix tasks to validate become eligible. Tasks needing Tidewave or live runtime state still stay local. *(Marker convention is in flight — `[CSR]` is provisional. Open question: expand `[CX]` to mean "cloud-agent-eligible" with the delegate field disambiguating Codex vs Cursor, or keep parallel `[CX]` / `[CSR]` markers. Pending project-level convention.)*

#### Push-Back-vs-Fix-Locally Matrix by Agent

**The matrix is the exception list, not the default.** Default action on a blocker is push-back to the agent (PR review comment for line-level findings, Linear comment for scope/intent drift — see `staged-review:commit-review` § "Asymmetric Push-Back Channels"). Local fix is reserved for items in the rows below — typically env-constraint cases the agent fundamentally can't verify (hex.pm for Codex, Tidewave for both, external specs for Codex). With CI handling the mechanical harness gates (see `elixir-ci-harness` skill in the marketplace), the local-fix surface shrinks further: format / credo / dialyzer / coverage drift becomes a CI failure that pushes back to the agent automatically, not a local fix-up step.

When `commit-review` finds blockers in a cloud-agent PR, classify by what the agent can fix from its env:

| Bug class | Codex action | Cursor action |
|---|---|---|
| User-code logic / project-internal API misuse | Push back | Push back |
| Hex-package API correctness (ExUnit, Phoenix, Ecto, third-party signatures) | **Fix locally** — Codex has no hex.pm | **Push back** — Cursor has hex.pm |
| Test failure / coverage gap on new code | Push back (best Codex can do without `mix test`) | **Push back** — Cursor runs `mix test` |
| Coverage gap on legacy code surfaced by the PR | **Fix locally** — pre-existing debt, not the agent's fault | **Fix locally** — same |
| Live-data / runtime-state diagnosis (Tidewave, IEx) | **Fix locally** | **Fix locally** — neither has Tidewave |
| External spec / RFC / EIP correctness (wire format, gas costs) | **Fix locally** — Codex has no external HTTP | Push back (Cursor likely has HTTP — pending verification) |
| Acceptance criteria not met (diff didn't do the thing) | Push back | Push back |

**Hybrid is fine:** a single PR may have both push-back and fix-locally blockers. Surface them in two groups; the user decides whether to push fixes locally and amend the PR branch, or push back to the agent with the logic bugs and only fix the unreachable-class ones locally.

### Fetch Existing Comments Before Auditing

**Before any cloud-agent PR audit, fetch existing comments from BOTH the GitHub PR and the Linear issue.** Both streams carry context the audit needs — auditing without either duplicates work, misses prior decisions, or re-litigates resolved scope.

**GitHub PR comments** — Copilot, CodeRabbit, Codex's own GitHub bot, human reviewers leaving line-level critique:

```bash
gh pr view <number> --json reviews,comments        # PR-level review summaries + issue-style comments
gh api repos/OWNER/REPO/pulls/<number>/comments    # line-level review comments
```

**Linear issue comments** — the delegating user's clarifications, scope adjustments, prior-reviewer notes, the agent's own summary on PR open, and any `@codex` / `@cursor` push-back exchanges from prior rounds:

```
mcp__linear-server__list_comments   # filter by issueId
mcp__linear-server__get_issue       # also returns the comment thread
```

Surface findings from both before the audit so it can:

- **Skip** issues already flagged (don't duplicate work)
- **Cross-reference** with own findings (agreement / disagreement)
- **Defer to** existing reviewers when they've explained something is intentional
- **Detect scope drift** — if the Linear issue body and a follow-up Linear comment disagree, the comment usually wins (the user added context the agent missed)
- **Track push-back round-trips** — prior `@codex` / `@cursor` mentions tell you whether this is a fresh review or a revision

This applies to ALL cloud-agent PR reviews — not just Codex's, not just Cursor's, not just `commit-review`. Per `feedback_pr_bot_review_calibration.md`: Copilot can fabricate verbatim diff citations (verify before acting); Codex's GitHub bot does evidence-based fact-checking with permalinks (useful counter-reviewer for bot-vs-bot disputes).

### Agent Status-Transition Guidance

**The "open PR → flip status to `In Review`" transition is the cloud agent's responsibility, not a built-in Linear behavior.** Linear syncs PR state from GitHub but does not auto-flip issue status when a PR opens — confirmed directly with Linear support:

> "This should be handled by the Cursor agent, not a built-in Linear setting. Linear syncs pull request state from GitHub, but setting the issue status to 'ready for review' when a PR opens is something you'd enforce through agent guidance or the agent's own behavior. In Linear, you can add that instruction under workspace or team **Additional guidance for agents** so Cursor follows your review workflow consistently."

This applies to **every** cloud agent (Codex, Cursor, future) — not just Cursor. The fix is one workspace-config change, not per-flow code.

**How to apply:**

1. In Linear, open **Workspace settings → Additional guidance for agents** (or **Team settings → Additional guidance for agents** if you want it scoped narrower than the whole workspace).
2. Add an instruction along the lines of:

   > "When you open a pull request linked to an issue, transition that issue's status to **In Review**. When you close or merge a PR, leave the status alone — the GitHub integration handles the merge → Done transition."

3. Cursor (and any other agent reading workspace guidance — Codex via the Linear→Codex integration may behave similarly) will pick this up and start flipping status correctly. Codex's behavior here is less verified than Cursor's; treat it as best-effort until observed.

**Until the workspace guidance is set, OR for any agent that doesn't read it,** the polling shape in § "Polling for 'Ready for Review'" below remains the safety net — broaden the filter to include `In Progress` and trust the PR-attachment as the authoritative signal. The workspace guidance is the canonical fix; the broadened polling is the compensation pattern. Both can coexist — set the guidance AND keep the polling shape, since not every agent reads workspace guidance reliably.

### Polling for "Ready for Review"

**The PR attachment is the authoritative signal, not the issue status.** Linear's status field is just a cached version of "agent opened a PR" — and neither Codex nor Cursor write the cache reliably (see Step 2 of each delegation flow above).

Canonical poll for skills/sessions looking for cloud-agent PRs awaiting review:

```
filter:
  delegate ∈ { Codex, Cursor }
  status ∈ { In Review, In Progress }
then:
  filter to issues with at least one open GitHub PR attachment
  (via mcp__linear-server__get_issue → attachments[].url)
```

Group results into:

- **`In Review` (canonical):** the agent's transition fired correctly
- **`In Progress` with open PR (non-canonical):** agent opened the PR but didn't flip status — surface explicitly so the reviewer/user can manually flip status after review (or include the flip in the post-review Linear comment)

This is the polling shape `staged-review:commit-review` Step 2 uses. Future skills/sessions matching this pattern (any cloud-agent → Linear → reviewer flow where the agent's status transitions are best-effort) should follow the same shape and be agent-agnostic in the filter.

### Cross-Repo Coordination

When work spans repos:

- Use `relatedTo` on `save_issue` to link issues across projects. Loose coupling — "these are about the same thing."
- Use `blocks` / `blockedBy` for hard ordering — "library release blocks downstream-app bump."
- **Don't** pile cross-repo work into one issue. Each repo owns its own PR; one issue per repo keeps PR review surface aligned with repo boundaries.

If cross-repo coordination becomes a regular pattern (3+ linked issues per month), promote to a Linear **Initiative** as a grouping overlay. Skip until load-bearing — Initiatives are a UI flourish, not a workflow requirement.

### Issue Body = The Prompt

Same rule as `task-writing.md`: the body is for the cloud agent (and local-review session) to read and execute, not a spec doc. Recommended sections:

```markdown
## Context
Why this exists, what it depends on, what's already in place.

## Task
The thing to do, in prose. WHAT, not HOW.

## Acceptance criteria
- Bullet list a fresh QA session can verify.
- Each item is a concrete observable, not "works correctly."

## Out of scope
What this issue explicitly does NOT do.

## File paths
Anchor file:line references — reviewer's starting points.

## Scoring
[D:X/B:Y/U:Z → Eff:W] (matches ROADMAP scoring)

## Reviewer note
Anything the local-review session needs to know — known gotchas, prior context, env-specific caveats (e.g. "Cursor: please run `mix test` against the touched files before opening the PR").
```

The `Acceptance criteria` and `Reviewer note` sections are what make the issue reviewable. Without them, `staged-review:commit-review` can't form a verdict.

### Workspace-Specific Layout

The team key, the list of projects, the repo↔project mapping, project IDs, and worked examples (e.g. "issue X was the first Codex round-trip-verification issue; issue Y was the first Cursor round-trip") are **workspace-specific** — they belong in:

- A separate include like `<workspace>-workspace.md` (imported only by repos in that workspace's family), or
- The project-level `CLAUDE.md` of the repo(s) that need it.

**Not here.** This file documents the *shape* of the workflow so any repo (including future ones unrelated to existing workspaces) can adopt it. Workspace specifics rot fast — project IDs change, repos get added, teams split.

### MCP Tool Reference

Discovery / read:

- `mcp__linear-server__list_teams`
- `mcp__linear-server__list_projects`
- `mcp__linear-server__list_issues` (filter by team, project, labels, assignee, status, delegate)
- `mcp__linear-server__list_issue_labels`
- `mcp__linear-server__list_issue_statuses`
- `mcp__linear-server__list_users` (look up agent user ids by displayName, e.g. `codex` / `cursor`)
- `mcp__linear-server__get_issue` / `get_project` / `get_team`

Write:

- `mcp__linear-server__save_project` (create / update)
- `mcp__linear-server__save_issue` (create / update — same tool, omit ID to create)
- `mcp__linear-server__save_comment` (the channel for `@cursor` push-back mentions)

Plus ~20 more (milestones, cycles, attachments, documents). Use `ToolSearch` with `mcp__linear-server__` prefix when you need a specific one.

**MCP server instruction (from `linear-server`):** when passing strings, send literal newlines and special characters directly — do not use escape sequences (`\n`, etc.). The server treats input as raw text.

### Cross-References

- `task-prioritization.md` § "Codex Delegation (`[CX]`)" — eligibility criteria, status flow, when to delegate
- `task-writing.md` — body-as-prompt principle (issue bodies follow the same rule as ROADMAP rows)
- `critical-rules.md` § "DON'T AUTO-MERGE PRS" — `In Review` → user-merge boundary
- `critical-rules.md` § "NEVER COMMIT WITHOUT EXPLICIT REQUEST" — local review verdict is informational, not merge authorization
- `workflow-philosophy.md` § "Implementer / Reviewer Handoff" — the handoff shape Linear+cloud-agent implements
