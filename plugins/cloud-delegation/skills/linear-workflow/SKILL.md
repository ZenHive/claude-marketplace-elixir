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

> **🚨 Code-mutation delegation suspended (Elixir projects, 2026-05-05).** Codex Cloud has no Elixir runtime — `mix`/`iex`/`elixir` not installed. See `task-prioritization.md` § "Codex Delegation (`[CX]`)" and `cloud-agent-environments.md` § "Codex Cloud → Code-mutation delegation SUSPENDED" for verification details and the path back to eligibility.

**Currently permitted:** review-only Codex delegations (see § "Codex-Reviews-Cursor Pattern" below). The agent reads a PR diff embedded in the issue body and posts a verdict comment — no runtime needed.

**When restored:** the flow mirrors the Cursor Delegation Flow below — `team` / `project` / `labels: ["cx-eligible"]` / `delegate: "Codex"` / status `Todo` / body-as-prompt. The implementer/reviewer handoff shape is identical. Until restored, treat any new code-mutation `[CX]` issue as a routing mistake — redirect to `[CSR]` (Cursor).

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

4. **Pushing back to Cursor:** post a Linear comment on the issue with `@cursor` mention. The Linear-displayName for Cursor's Background Agent is `cursor` (id `b8668f6b-992f-4152-9e59-13b6fe1f599b`). **Verified channel** (early Cursor round-trip testing, 2026-05): Cursor picks up `@cursor` mentions on Linear comments within ~5 min, amends the PR with a fresh commit, posts confirmation comments back on the issue, and reruns the harness. A verbatim code-suggestion push-back was applied surgically with no scope creep. Linear @-mention is preferred over GitHub PR comment for Cursor push-back — keeps the conversation thread on the issue. **See § "Wake-Mention Discipline" below for the rules around `@cursor` placement.**

5. **User merges.** Same rule — verdict is informational, user merges per `critical-rules.md` § "DON'T AUTO-MERGE PRS".

### Wake-Mention Discipline

`@cursor` (and `@codex`, and any future cloud-agent display name) is a **wake/summon signal, not a tag**. Within ~5 min of an `@cursor` mention on a Linear comment, Cursor's Background Agent picks up the comment as a fresh push-back and runs a session against the issue — including issues already in `Done`. Three hard rules:

1. **Never use `@cursor` on a "stop," "FYI," or closing-out comment.** Posting `@cursor — INE-13 is complete; please don't spawn further sessions on this issue` literally summons the session you're trying to prevent. (Observed 2026-05-04 on cartouche INE-13: comment was edited within minutes to drop the `@`, no new PR appeared — lucky, the pickup window hadn't fired.) For closing-out / informational mentions, write `Cursor:` or `Cursor —` in plain prose. Reserve `@cursor` for the one legitimate use: **fix-this-now push-back** where you want the agent to pick up and amend the PR.

2. **One wake mention per push-back round, not one per surface.** When pushing back across both surfaces — GitHub PR review (line-level) and Linear comment (scope/intent paragraph) — the wake mention goes on **exactly one** of them. Two `@cursor` mentions inside the agent's ~5min pickup window risks double-summons (parallel sessions on the same PR) and is at minimum redundant ceremony.

3. **Decide BEFORE posting either surface.** If `@cursor` placement is genuinely ambiguous, ask the user before the first surface goes up — not after. Posting one with `@cursor` and then asking "should I also `@cursor` the other" has already burned the wake signal you may not have wanted. Same shape applies to `@codex` for Codex push-back.

**Where to place the one mention:**

- **Linear `@cursor` comment is the verified wake channel** — observed end-to-end in early Cursor round-trip testing. Prefer Linear when picking one.
- The GitHub PR review's line-level findings are the **content**, not the wake signal — post them WITHOUT `@cursor` if the Linear comment carries the mention. Linear's GitHub-sync surfaces the PR activity on the issue thread either way.
- Cleanest single-surface shape: skip the GitHub review entirely, put line-level findings + scope paragraph inline in **one** Linear `@cursor` comment with verbatim code blocks (see § "Preferred channel for fix-locally-required findings" below).

**Recovery:** if you slip and post a wake-mention in a stop-intent comment, edit-update the comment via `mcp__linear-server__save_comment` with the comment `id` to replace the body — fast edit beats most polls.

### Codex-Reviews-Cursor Pattern (Review Delegation)

> **Status (2026-05-05):** review-only Codex delegations remain permitted under the broader `[CX]` code-mutation suspension — Codex reads the PR diff embedded in the issue body and posts a verdict comment, no `mix`/runtime invocation involved. Treat as exception-not-default while the suspension is in force; if review verdicts start arriving with fabricated harness claims (the failure pattern that drove the code-mutation suspension), pause this pattern too and surface to the user.

A specific composition of the two flows above: Cursor implements, Codex reviews. Activated by `staged-review:commit-review` Step 10b when the polled PR's source Linear issue has `delegate = Cursor` and CI is green.

**Shape:** `commit-review` creates a second Linear issue (`cx-eligible`, `delegate: "Codex"`, status `Todo`) whose body is a REVIEW-ONLY prompt referencing the Cursor PR (with the diff embedded inline). A tracking comment on the GitHub PR (`Codex Cloud review delegated: <URL>`) stores the delegation issue ID across sessions. On the second `commit-review` invocation, the skill reads Codex's verdict comment from that issue and applies the push-back-vs-fix matrix using **Cursor's row** — the matrix is implementer-keyed, not reviewer-keyed.

**Key constraint:** delegation is gated on CI being green. Red CI → push back to Cursor as normal; the delegation issue is not created until CI passes.

**Pilot guard:** if Codex opens a stray PR despite the REVIEW-ONLY instruction, surface a warning on the next fetch-path invocation. No automated cleanup in v1 — user closes the rogue PR manually.

**State:** no local state files. Linear delegation issue + GitHub PR tracking comment is the full state machine.

### Cloud Agent Environments

Cloud-agent envs differ in what they can reach during their work session. The differences shape both delegation eligibility and the push-back-vs-fix-locally calculus when reviewing their PRs.

For agent-side env details (runtime paths, hex.pm/Tidewave/HTTP scope, gotchas, self-validation expectations), see `cloud-agent-environments.md`. Reviewer-side recap:

| Agent | hex.pm | mix tasks | Tidewave | External HTTP |
|---|---|---|---|---|
| **Codex Cloud** | ❌ | ❌ (no Elixir runtime, 2026-05-05) | ❌ | ❌ |
| **Cursor Cloud** | ✅ | ✅ (Erlang/OTP 27 + Elixir 1.18.4) | ❌ | ✅ (assumed; not stress-tested on RFCs/EIPs) |

**Implications for delegation eligibility:**

- `[CX]` — code-mutation suspended; review-only OK. See `task-prioritization.md` § "Codex Delegation (`[CX]`)".
- `[CSR]` — broader scope: hex.pm verification, mix-task validation, third-party API correctness all in-scope. Tidewave / live-runtime tasks stay local.

*(Marker convention is in flight — `[CSR]` is provisional. Open question: expand `[CX]` to mean "cloud-agent-eligible" with the delegate field disambiguating Codex vs Cursor, or keep parallel markers. Pending project-level convention.)*

#### Push-Back-vs-Fix-Locally Matrix by Agent

**Default flow is review-only.** The reviewer reads the diff via `gh pr view`, `gh pr diff`, and `gh api repos/.../pulls/<n>/comments`. The reviewer does NOT spin up a worktree or run `gh pr checkout` unless the finding lands in a fix-locally row of the matrix below OR CI is absent (forcing local-harness fallback). Branch checkout silently biases toward "I'll amend this," contradicting the push-back default.

**CI is the shared error gate.** Every push to a cloud-agent's branch triggers `harness.yml` (per `cloud-agent-environments.md` § "CI as the Shared Harness"). Push-back → agent re-pushes → CI runs → green = ready / red = next push-back round. The reviewer doesn't need to run the harness locally; CI does. Local checkout + local fix + local push to the agent's branch attributes the code to the agent without the agent's own verification cycle catching anything — bypassing the error gate.

**The matrix is the exception list, not the default.** Default action on a blocker is push-back to the agent (PR review comment for line-level findings, Linear comment for scope/intent drift — see `staged-review:commit-review` § "Asymmetric Push-Back Channels"). Local fix is reserved for items in the rows below — typically env-constraint cases the agent fundamentally can't verify (hex.pm for Codex, Tidewave for both, external specs for Codex). With CI handling the mechanical harness gates (see `elixir-ci-harness` skill in the marketplace), the local-fix surface shrinks further: format / credo / dialyzer / coverage drift becomes a CI failure that pushes back to the agent automatically, not a local fix-up step.

When `commit-review` finds blockers in a cloud-agent PR, classify by what the agent can fix from its env:

> **Codex column: non-applicable while code-mutation `[CX]` is suspended (2026-05-05).** New Codex implementer PRs aren't being created in Elixir repos right now (per `task-prioritization.md` § "Codex Delegation"); the matrix's Codex column applies to (a) any pre-suspension Codex PR still mid-review and (b) future Codex PRs once the env is restored. For Cursor PRs, the right column is the operative one. Codex review verdicts (the Codex-Reviews-Cursor pattern) don't pass through this matrix — they post verdicts on Cursor PRs which then route through Cursor's row.

| Bug class | Codex action | Cursor action |
|---|---|---|
| User-code logic / project-internal API misuse | Push back | Push back |
| Hex-package API correctness (ExUnit, Phoenix, Ecto, third-party signatures) | **Fix locally** — Codex has no hex.pm | **Push back** — Cursor has hex.pm |
| Test failure / coverage gap on new code | Push back (best Codex can do without `mix test`) | **Push back** — Cursor runs `mix test` |
| Coverage gap on legacy code surfaced by the PR | **Fix locally** — pre-existing debt, not the agent's fault | **Fix locally** — same |
| Live-data / runtime-state diagnosis — verification only | **Push back with Tidewave evidence** | **Push back with Tidewave evidence** — Claude verifies, agent fixes |
| Live-data / runtime-state diagnosis — fix requires verifier's runtime context | **Fix locally** (paste-as-comment if viable) | **Fix locally** (paste-as-comment if viable) — same fallback rule |
| External spec / RFC / EIP correctness (wire format, gas costs) | **Fix locally** — Codex has no external HTTP | Push back (Cursor likely has HTTP — pending verification) |
| Acceptance criteria not met (diff didn't do the thing) | Push back | Push back |

**Tidewave is verification, not necessarily fix.** Local Claude has `mcp__tidewave__project_eval` and live runtime/database access; neither Codex nor Cursor does. When reviewing their PRs, this asymmetry is a **push-back strengthener**, not a fix-locally trigger.

**Read-only Tidewave verification flow:**

1. Suspect a bug in the PR diff (e.g., "this fails when `params[:user]` is nil," "this query returns wrong shape on empty result").
2. Open IEx in the **host project** (NOT in a checked-out PR worktree — Tidewave runs against the host's currently-loaded code, fully compatible with the default review-only flow).
3. Run `mcp__tidewave__project_eval` against the suspected case. Examples:
   - Verify upstream library behavior: `Phoenix.LiveView.assign(socket, :foo, nil)` — does this raise or return?
   - Verify live data shape: `Repo.one(from u in User, limit: 1) |> Map.keys()` — what fields does the schema actually expose?
   - Verify hex-package signature you suspect the agent got wrong: `&ExUnit.Assertions.assert_receive/3 |> Function.info()` — confirm arity, then cite in push-back.
4. Paste the verified result into the push-back comment as evidence.

**Before** (unverified push-back): "I think `process/1` fails when `user_id` is nil — please verify."

**After** (Tidewave-verified push-back):
> ```
> @cursor verified failure case via Tidewave:
>
> iex> Acme.Users.process(%{user_id: nil})
> ** (FunctionClauseError) no function clause matching in Acme.Users.process/1
>
> Please add a nil guard or update the spec to exclude nil. Re-pushing should green CI.
> ```

The implementing agent picks up the comment, applies the fix, re-pushes — the agent still owns the code. Claude's role is **evidence generator**, not implementer. This preserves push-back-default while leveraging the local-only capability.

**When does Tidewave verification trigger fix-locally instead of push-back?** Only when the verification reveals a finding whose CODE FIX is too large to paste verbatim, requires generated artifacts the agent can't reproduce, or requires multi-file coordination. Same fallback rule as the rest of the matrix — paste-as-comment first, separate-branch-off-base only when paste isn't viable. Default remains push-back; Tidewave just makes the push-back evidence-grounded.

**Wake-mention rules apply when pushing back.** See § "Wake-Mention Discipline" — one `@cursor` per push-back round, never on stop/FYI comments, decide placement before posting.

**Preferred channel for fix-locally-required findings: paste-as-`@cursor`-comment.**

When a finding lands in a fix-locally matrix row (env-constraint cases — hex.pm for Codex, Tidewave for both, external specs for Codex, pre-existing legacy debt), the local reviewer has done verification work the agent couldn't (hex.pm signature lookup, Tidewave runtime inspection, RFC fetch). The CODE for the fix is usually small. Paste it as a Linear `@cursor` (or `@codex`) comment with a verbatim code block:

> ```
> @cursor please apply verbatim and re-push:
>
> ```elixir
> # exact code block here, with file:line context above
> ```
>
> Verified against [link to hex docs / RFC / Tidewave query result].
> ```

The agent applies, re-pushes, CI verifies the combined state in **one** harness run. Authorship preserved. Single error gate. No two-PR coordination dance.

**Fallback: separate branch off the PR's base commit.** Use only when the fix is too large to paste, too context-sensitive to apply verbatim safely, or requires generated artifacts (large Tidewave-derived data, multi-file refactor) the agent can't reproduce. Stage on a new branch off the PR base; user merges/coordinates.

**Never amends the agent's branch.** See `critical-rules.md` § "NEVER PUSH TO A CLOUD-AGENT'S BRANCH".

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

### Mandatory Acceptance-Criteria Bullets

**Every delegated issue's `## Acceptance criteria` section MUST include explicit bullets for ROADMAP.md and CHANGELOG.md updates** — verbatim, not paraphrased into vague "update docs" wording. Cloud agents (Codex, Cursor, future) do NOT reliably propagate the "task without updated docs is incomplete" rule from `task-prioritization.md` § "Roadmap Maintenance" into their PR scope unless it's a checked acceptance bullet on the specific issue.

Required bullets, copy-paste shape:

- **Full harness green at PR open** — `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix credo --strict` (TODO/FIXME exit-2 carve-out only), `mix sobelow --exit Low`, `mix doctor`, `mix test.json --quiet`, `mix test.json --cover --cover-threshold N` at the repo's coverage tier, and `mix dialyzer` all clean. CI runs the same checks; pre-PR self-validation just shifts the failure round-trip earlier. A red harness on PR open is a blocking acceptance-criterion miss, not a "soft polish" item — see `cloud-agent-environments.md` § "Cursor Cloud → Self-validation expectation" for the per-tool semantics.
- **ROADMAP.md updated** — task row marked ⬜ → ✅ (or struck through with the new state); Current Focus section refreshed if the completed task affected it; for bundle-entrypoint tasks (e.g. a coverage push that gates downstream tasks), name the entrypoint AND the unblocked dependents in the bullet so the agent updates both
- **CHANGELOG.md updated** — entry added under `## [Unreleased]` describing what was built and why; no test counts, function counts, or lines-changed tallies (per `task-prioritization.md` § "No counts or stats in entries")

Place these alongside the technical / test acceptance bullets, not as a final note or in `Reviewer note`. They're not optional polish — they're part of the work's done-definition. Without them as explicit acceptance criteria, the `commit-review` reviewer has no grounds to block the PR for stale docs, and ROADMAP drift compounds across multiple delegated PRs (the failure mode that produces ROADMAP rows still showing ⬜ for tasks the corresponding Linear issue closed weeks ago).

**Exception:** review-only delegated issues (e.g. a Codex issue whose task is to review another agent's PR and post a verdict comment — see § "Codex-Reviews-Cursor Pattern") produce a verdict, not code. No ROADMAP/CHANGELOG row to update; skip these bullets and add a single bullet for "verdict comment posted on the delegation issue with finding table + acceptance-criteria coverage paragraph."

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
