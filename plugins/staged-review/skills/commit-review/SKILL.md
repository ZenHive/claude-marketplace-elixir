---
name: commit-review
description: Use when reviewing a Codex (or other cloud-agent) PR before merging. Polls Linear for Codex-delegated issues with an open PR attachment (status ∈ In Review or In Progress, since Codex transitions are unreliable), fetches the PR branch via `gh pr checkout`, fetches existing review comments from upstream reviewers (Copilot, CodeRabbit, humans) so the audit doesn't duplicate their findings, runs the full local harness (mix format check, compile, credo --strict, mix dialyzer.json, mix test.json --cover, doctor, sobelow), reviews the diff against Linear acceptance criteria, fixes harness-flagged issues since Codex doesn't run our hooks, and surfaces a verdict with explicit push-back-vs-fix-locally guidance — but does NOT merge (user merges). Sibling of `staged-review:code-review` for already-committed-on-a-branch flows.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, MultiEdit, TaskCreate, Agent
---

# Commit Review — Cloud-Agent PR Workflow

Read the PR diff. Read upstream reviewer comments. Run the local harness Codex didn't have. Fix harness drift. Review the diff against Linear acceptance criteria. Surface a verdict with explicit push-back-vs-fix-locally guidance. **Don't merge** — the user merges (per `critical-rules.md` § "DON'T AUTO-MERGE PRS").

## Scope

WHAT THIS SKILL DOES:
  - Poll Linear for Codex-delegated issues with an open PR attachment (status ∈ {In Review, In Progress} — Codex's status transitions are unreliable, so the PR attachment is the authoritative signal)
  - `gh pr checkout` the linked PR branch locally
  - **Fetch existing PR review comments** (Copilot, CodeRabbit, humans) before auditing — so we don't duplicate findings and we inherit context they've already documented
  - Run the full local harness Codex's environment lacks (format/compile/credo/dialyzer.json/test.json --cover/doctor/sobelow)
  - **Fix harness-flagged issues in the PR branch** — Codex doesn't run our hooks, so format/credo/dialyzer/test drift is expected
  - Apply `code-review`'s 5-category audit against `gh pr diff <number>`, integrated with upstream reviewer findings
  - Cross-reference findings against the Linear issue's acceptance criteria
  - Run mandatory `codex:codex-rescue` second-opinion pass (same gate as `code-review`)
  - Surface a verdict (✅ ready / ⚠️ blockers / 💬 discussion items) with **explicit push-back-vs-fix-locally guidance** for blockers — Codex cloud has no hex.pm / Tidewave / internet, so hex-API or live-data bugs should be fixed locally rather than bounced back
  - Optionally post the review summary as a Linear comment (offer; user decides)

WHAT THIS SKILL DOES NOT DO:
  - Merge the PR (user merges — see `critical-rules.md` § "DON'T AUTO-MERGE PRS")
  - Commit the harness-fix edits (stage only; user decides whether to push as a follow-up commit on the PR branch)
  - Review local staged work (use `staged-review:code-review` for that)
  - Replace the Codex dispatch — Codex is the implementer here, not the reviewer

**Distinction from `code-review`:**

| Aspect | `code-review` | `commit-review` (this skill) |
|---|---|---|
| Input | `git diff --staged` | `gh pr diff <number>` after `gh pr checkout`, plus upstream PR comments |
| Trigger | Local pre-commit | Codex (or other cloud-agent) PR awaiting review |
| Output | Findings + auto-applied edits + final commit-by-user | Verdict + push-back-vs-fix matrix + optional Linear comment + merge-by-user |
| Harness fixes | Not expected (local hooks ran) | **Expected** (Codex's harness lacked our hooks) |

Both skills share the 5-category audit and the mandatory Codex second-opinion. The difference is **input source**, **upstream-review awareness**, and **output shape**.

## Workflow

```dot
digraph commit_review {
  rankdir=TB;
  node [shape=box];

  detect    [label="1. Detect Linear MCP\n(abort with install instructions if missing)"];
  list      [label="2. List Codex PRs awaiting review\n(delegate=Codex, status∈{In Review, In Progress},\nfiltered to issues with open PR attachment)"];
  spec      [label="3. Read Linear issue body\nspec + acceptance criteria"];
  checkout  [label="4. Resolve PR → `gh pr checkout <n>`"];
  comments  [label="5. Fetch existing PR review comments\nCopilot / CodeRabbit / humans"];
  harness   [label="6. Run full local harness\nformat/compile/credo/dialyzer.json/test.json --cover/doctor/sobelow"];
  fix       [label="7. Stage harness fixes\nDO NOT commit"];
  audit     [label="8. 5-category audit\non `gh pr diff <number>`,\nintegrated with upstream comments"];
  cross     [label="9. Cross-reference Linear\nacceptance criteria"];
  codex     [label="10. Codex second-opinion (mandatory)\nsame gate as code-review"];
  verdict   [label="11. Present verdict\n✅ ready / ⚠️ blockers / 💬 discussion\nPush-back-vs-fix matrix\nOffer Linear comment"];

  detect -> list -> spec -> checkout -> comments -> harness -> fix -> audit -> cross -> codex -> verdict;
}
```

### Step 1: Detect Linear MCP Availability

Verify the Linear MCP is installed and reachable. The skill needs `mcp__linear-server__list_issues`, `mcp__linear-server__get_issue`, and (optionally for the comment-post step) `mcp__linear-server__save_comment`.

If the Linear MCP isn't available:

```
Linear MCP not detected. This skill needs the Linear MCP to find PRs awaiting review.

Install:
  https://linear.app/changelog/2025-05-01-mcp

After install, restart Claude Code so the MCP tools register, then re-invoke this skill.
```

Then **abort**. Don't try to find PRs through `gh` alone — the Linear → PR linkage is what makes the workflow tractable.

### Step 2: List Codex PRs Awaiting Review

**The PR-attachment link in Linear is the authoritative "ready for review" signal.** Linear status is just a cached version of that, and Codex's transition behavior has been unreliable across observed round-trips:

- Sometimes Codex stays at `Backlog` (no auto-transition, no PR auto-open)
- Sometimes Codex auto-opens the PR but stays at `In Progress` (no transition to `In Review`)
- Sometimes the canonical `In Progress` → `In Review` transition fires correctly

So polling **only** `status = In Review` misses real PRs awaiting review. Broaden the filter:

Call `mcp__linear-server__list_issues` filtered for:
- `delegate` = Codex's user id (verified: `cbb4823b-2de9-493b-8238-9697da57a07b`; or look up by email/name if id is stale)
- `status` ∈ { `In Review`, `In Progress` }

Then for each candidate, fetch attachments via `mcp__linear-server__get_issue` (or check the issue body if the integration writes PR links inline) and **filter to issues with at least one open GitHub PR attachment**. The PR-link check is the load-bearing one — it filters out `In Progress` issues Codex is still working on.

Group the results into two lists when presenting:

- **`In Review` (canonical):** issues whose status flipped correctly
- **`In Progress` with open PR (non-canonical):** issues where Codex auto-opened a PR but didn't flip status. Surface these explicitly so the user knows the issue is on a non-canonical status — they may want to manually flip it after the review, or you can include the status flip in the post-review Linear comment

If there's exactly one candidate across both groups, default to it (user can override). Zero candidates → "no Codex PRs awaiting review" and stop. Multiple → list with title + identifier + status and ask which one.

### Step 3: Read the Linear Issue Body

Call `mcp__linear-server__get_issue`. The issue body **is** the spec — full prompt, acceptance criteria, file paths Codex was given. Pull out:

- The acceptance criteria (often at the bottom under "Success criteria" or "Acceptance criteria")
- Any explicit out-of-scope items
- File paths Codex was told to touch (so you know where to look in the diff)

You'll cross-reference this in Step 9.

### Step 4: Resolve PR and Check It Out

Find the PR linked to the Linear issue. Linear surfaces linked PRs in the issue's `attachments` or in the body. If unsure, search:

```bash
gh pr list --search "in:title <issue-identifier>" --state open
gh pr list --search "<issue-identifier>" --state open
```

Then check it out locally — this creates a local branch tracking the remote PR branch, so you can run mix tasks against it:

```bash
gh pr checkout <number>
```

Confirm you're on the PR branch:

```bash
git branch --show-current
git log -1 --oneline
```

### Step 5: Fetch Existing PR Review Comments

**Before auditing, read what other reviewers have already said.** Copilot, CodeRabbit, and human reviewers may have left comments on the PR — auditing without reading them duplicates their work and misses context they've already documented (intent, prior discussion, won't-fix decisions).

Fetch both PR-level reviews and line-level review comments:

```bash
# PR-level review summaries + issue-style PR comments
gh pr view <number> --json reviews,comments

# Line-level review comments (Copilot/CodeRabbit/humans inline on specific diff lines)
gh api repos/OWNER/REPO/pulls/<number>/comments

# Quick scan of comment bodies for triage
gh pr view <number> --json reviews --jq '.reviews[] | {author: .author.login, state, body}'
gh api repos/OWNER/REPO/pulls/<number>/comments --jq '.[] | {author: .user.login, path, line, body: .body[0:200]}'
```

The repo's `OWNER/REPO` is whatever `gh repo view --json nameWithOwner --jq .nameWithOwner` returns.

For each existing comment / review finding, classify it for use in Step 8:

- **Already flagged** — the audit's own categories will mention this; surface it in the table with attribution (e.g., `(also flagged by Copilot)`) rather than as a fresh finding. Don't re-litigate
- **Confirmed-by-upstream** — upstream reviewer agreed the diff is correct or marked something as "intentional / won't fix" — incorporate as context; don't re-flag
- **Disputed** — your audit disagrees with an existing comment. Surface explicitly in Step 11 (verdict) so the user sees the disagreement and decides

If there are no existing comments (fresh PR with no upstream review), proceed normally.

### Step 6: Run the Full Local Harness

Codex's harness lacks our hooks (no `post-edit-check.sh`, no `pre-commit-unified.sh`, no Styler-in-formatter). Run every gate the local hooks would have run:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict --format json
mix dialyzer.json --quiet
mix test.json --quiet --cover
mix doctor      # if available
mix sobelow     # if available
```

Capture the output. Test failures and dialyzer warnings are blockers; format/credo drift is fixable.

**Coverage gate** (per `critical-rules.md` § "RAISE COVERAGE BEFORE MUTATING"): if the PR mutates a module whose `mix test.json --cover` percentage is below tier (≥80% standard, ≥95% critical), raising coverage is part of this review. The PR isn't ready to merge until the gate passes.

### Step 7: Stage Harness Fixes — Don't Commit

For format/credo/dialyzer/doctor drift you can fix mechanically:

- `mix format` — re-run, accept output
- Credo nits (alias ordering, unused vars, doc gaps in your touched scope) — fix per `critical-rules.md` § "FIX HOOK-FLAGGED ISSUES ON FILES YOU TOUCH"
- Doctor doc gaps — add missing `@doc` / `@moduledoc` / `@spec` on public functions
- Trivial dialyzer fixes (`@spec` corrections matching actual return shape) — apply

Stage with `git add <paths>` so the diff is visible. **Do not commit.** The user decides whether to:
- push these as a follow-up commit on the PR branch (typical case)
- ask Codex to amend (cleaner for the PR's history but slow)
- merge as-is and clean up in a follow-up PR

For non-mechanical issues (genuine test failures, dialyzer issues that need redesign, missing test coverage on a code path the PR added), surface them as findings in Step 11 — don't try to "fix" by guessing what Codex's intent was.

### Step 8: Apply the 5-Category Audit (Integrated with Upstream Comments)

Run `code-review`'s Step 3a categories against `gh pr diff <number>` (not against `git diff --staged` — the input is the PR's full diff vs. its base):

```bash
gh pr diff <number>
```

Categories (full text in `staged-review:code-review` SKILL.md):

1. **Bugs & Logic Errors** — null paths, type confusion, silent failures, untested error paths added in this diff
2. **Missing Extractions** — code AND data extractions
3. **Missing TODO Markers** — temporary code without `TODO:` prefix; cross-reference ROADMAP.md
4. **Abstraction Opportunities** — 3+ similar patterns; flag only when stable
5. **Actionable TODOs** — TODOs in the PR diff resolvable right now
6. **Documentation Gaps** — ROADMAP.md, CHANGELOG.md, CLAUDE.md, README.md, in-code `@doc`/`@spec` drift

Same confidence filter as `code-review`: only report bugs you can name the triggering input for. Same rating scale (1-10 or `discuss-trivial`/`discuss-design`).

**Integrate upstream comments from Step 5:** when a finding overlaps with an existing reviewer's comment, attribute it (`also flagged by <reviewer>`) instead of presenting it as a fresh discovery. When you disagree with an upstream comment, mark it `disputed` and include both positions in Step 11. When upstream has marked something "won't fix" or "intentional," don't re-raise unless you have new evidence.

**Delegate the survey to Explore** if the PR touches ~20+ files or needs cross-file tracing — same pattern as `code-review` Step 3a.

### Step 9: Cross-Reference Linear Acceptance Criteria

Walk the acceptance criteria from Step 3. For each one:

- ✅ Met — diff clearly satisfies it (cite file:line)
- ⚠️ Partially met — some-but-not-all of the criterion (cite what's missing)
- ❌ Not met — diff doesn't address it (this is a blocker finding)
- ❓ Ambiguous — criterion is vague enough that it's hard to tell (mark `discuss`)

Acceptance criteria not met are **always blockers** — the PR shouldn't merge until the spec is satisfied or the user decides to descope.

### Step 10: Mandatory Codex Second-Opinion

Per `critical-rules.md` and `code-review` Step 3b: every PR review runs a Codex second-opinion pass. **This is not optional.**

Dispatch `codex:codex-rescue` with the dispatch payload spec from `code-review` (Task / Context / Project tool inventory / Verification instruction). The payload here is:

- **Task** — review this Codex PR for the 5 categories above; verify acceptance criteria met
- **Context** — the PR diff (`gh pr diff <number>`), the Linear issue body, upstream reviewer comments from Step 5, ROADMAP.md excerpts for the current phase
- **Project tool inventory** — MCP servers in `.mcp.json` (e.g., `mcp__tidewave__project_eval`), mix tasks (`mix test.json`, `mix dialyzer.json`, `mix compile`, `mix credo`), hex-docs `/llms.txt` URLs for packages in the diff
- **Verification instruction** — "Before asserting any claim about the codebase, verify it with one of the tools above. Training-data recall is insufficient. Don't comment on style or formatting — those are linter scope. Do NOT run `gh pr merge`."

Merge the result sets per `code-review` Step 4 (corroborated > Claude-only > Codex-only-default-to-discuss-until-verified).

If Codex is unreachable, continue single-reviewer and mark the verdict closing line `Codex unreachable — single-reviewer pass`. Don't silently drop it.

### Step 11: Present Verdict — Don't Merge

Output a single verdict block. Three top-level shapes:

**✅ Ready to merge:**
```
## Verdict: ✅ Ready to merge

**Acceptance criteria:** all met (cite each)
**Upstream comments (Step 5):** N integrated, 0 disputed
**Harness:** clean (or: N format/credo nits staged in <files>, push as follow-up before merging)
**5-category audit:** N findings, all priority ≤ 4 / discuss-trivial — addressed in staged fixes
**Coverage:** N% on touched modules (≥ tier)

User: when ready, run `gh pr merge <number>` (rebase / squash / merge per repo policy).

dual-reviewer pass
```

**⚠️ Blockers:**
```
## Verdict: ⚠️ Blockers — do not merge yet

**Blockers:**
- [list — acceptance criteria not met, test failures, dialyzer warnings, priority 7+ findings]

**Recommended action per blocker:** see push-back-vs-fix matrix below

**Non-blocking findings table:** [the findings table per code-review Step 6 format, with upstream attribution where applicable]

dual-reviewer pass
```

**💬 Discussion items:**
```
## Verdict: 💬 Discussion items — your call

[Cases where the harness passes and acceptance criteria are met but a `discuss-design` finding wants user input. Lay out both reasoners' positions side by side per code-review Step 9. Surface any `disputed` upstream comments here too.]

dual-reviewer pass
```

#### Push-Back-vs-Fix-Locally Matrix (for ⚠️ blockers)

For each blocker, classify by whether **Codex can realistically fix it given its environment constraints** (per `linear-workflow.md` § "Codex Cloud Constraints"). Codex cloud has no hex.pm, no Tidewave, no internet — so hex-API correctness, live-data diagnosis, and external-spec lookups all fail under push-back.

| Blocker class | Default action | Why |
|---|---|---|
| User-code logic (control flow, off-by-one, wrong case branch, missing nil-guard on user data) | **Push back to Codex** — comment on PR or amend the Linear issue with the failure trace | Codex can fix this from the diff + its training. Preserves implementer/reviewer separation; preserves delegation token economics |
| Project-internal API misuse (calling wrong helper, ignoring an existing module) | **Push back to Codex** — point to the right helper in the comment | Codex has the local repo; can find it once told |
| Hex-package API correctness (ExUnit assertion macros, Phoenix/Ecto signatures, version-pinned third-party APIs) | **Fix locally** — local has hex_docs MCP, can verify the signature in seconds | Codex has no hex.pm. Pushing back wastes a round-trip — Codex re-guesses from training data and likely re-ships the same class of bug. **Observed:** INE-6 shipped `assert_received/2` with timeout int as 2nd arg; should have been `assert_receive/3`. Codex couldn't have known |
| Anything needing Tidewave / live runtime state to diagnose | **Fix locally** | Codex can't reach Tidewave. The diagnosis requires running code |
| External spec / RFC / EIP correctness (wire-format byte order, gas costs, JSON-RPC error codes) | **Fix locally** — use WebFetch on the spec, verify against ≥2 reference impls | Codex can't fetch external URLs |
| Acceptance criteria genuinely not met (the diff didn't do the thing) | **Push back to Codex** — quote the missing criterion | Spec gap; Codex needs to know what's missing |
| Coverage below tier on a touched module | **Push back to Codex** if the missing tests are about the new code; **fix locally** if it's pre-existing coverage debt the PR uncovered | New code → Codex's responsibility; legacy gap surfacing now → local fix per `critical-rules.md` § "RAISE COVERAGE BEFORE MUTATING" |

**Hybrid is fine:** a single PR may have both push-back and fix-locally blockers. Surface them in two groups; the user can decide whether to push fixes locally and amend the PR branch, or push back to Codex with the logic bugs and only fix the hex-API ones locally, or any other split.

**Then offer the Linear comment.** Construct a summary suitable for the Linear issue's comment thread:

> "Want me to post this verdict as a Linear comment via `mcp__linear-server__save_comment`? (yes / no / edit first)"

Default is **don't post** — wait for explicit user confirmation. The verdict in this session's chat is the deliverable; the Linear comment is optional persistence.

**Do NOT run `gh pr merge`.** Per `critical-rules.md` § "DON'T AUTO-MERGE PRS", merge is the user's call. The skill's job ends at the verdict.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `gh pr merge` after a ✅ verdict | Skill ends at the verdict. Per `critical-rules.md` § "DON'T AUTO-MERGE PRS", the user merges — never the agent |
| Skipping the local harness ("the PR's CI passed, that's enough") | Codex doesn't run our hooks. Format/credo/dialyzer drift is expected even on green CI. Run the full local harness |
| Committing the harness fixes | Stage only — `git add`. The user decides whether to push as a follow-up commit on the PR branch, ask Codex to amend, or merge as-is |
| Skipping Codex second-opinion | Step 10 is required. Same gate as `code-review` Step 3b |
| Skipping Linear acceptance-criteria cross-reference | Step 9 is the spec gate. Acceptance criteria not met is always a blocker |
| Auto-posting the verdict as a Linear comment without asking | Default is don't post. Offer; wait for explicit confirmation |
| Reviewing staged work with this skill | Use `staged-review:code-review` for local pre-commit. This skill is for cloud-agent PR review |
| Treating Codex MCP user lookups as fact | Verify the Codex user id by name/email if the id seems stale. Linear can rotate user ids on workspace migration |
| Polling only `status = In Review` | Codex's transitions are unreliable — also poll `In Progress` and filter by open-PR-attachment. Status is a cached version of the PR-link signal; the PR attachment is the authoritative one |
| **Skipping Step 5 (fetching upstream PR comments)** | **The audit duplicates Copilot/CodeRabbit/human findings and misses context they've documented. Always fetch `gh pr view --json reviews,comments` AND `gh api .../pulls/<n>/comments` before auditing. Attribute overlapping findings; surface disagreements in the verdict** |
| **Pushing hex-API bugs back to Codex** | **Codex has no hex.pm — it can't verify third-party signatures, will re-guess from training data, likely re-ship the same bug. Hex-API correctness bugs (ExUnit, Phoenix, Ecto, version-pinned libs) are fix-locally per the push-back-vs-fix matrix in Step 11** |
| **Pushing live-data / Tidewave bugs back to Codex** | **Codex has no Tidewave, no internet — can't diagnose anything that needs running code or external lookups. Fix locally per the matrix** |
| Running this skill when Linear MCP isn't installed | Step 1 aborts cleanly with install instructions. Don't fall back to gh-only — Linear → PR linkage is the workflow |
| Surfacing harness fixes as "blockers" when they're mechanical | Mechanical drift (format, alias order, missing `@doc`) is expected and gets staged in Step 7, not blocked. Genuine bugs/test failures/dialyzer issues are blockers |
| Inventing Linear acceptance criteria not in the issue body | If the body lacks explicit criteria, mark "criteria implicit" in the verdict and lean on the 5-category audit. Don't fabricate a checklist |
