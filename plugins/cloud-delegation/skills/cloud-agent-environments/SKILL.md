---
name: cloud-agent-environments
description: Operational reference for cloud-agent harnesses (Codex Cloud, Cursor Background Agent) — what each can and can't reach (hex.pm, mix tasks, Tidewave, external HTTP), runtime gotchas (Cursor's Erlang/Elixir paths, asdf shim interception, Credo TODO exit-code-2 expected behavior), self-validation expectations (Cursor should run the harness pre-PR; Codex can't), and the AGENTS.md generation workflow that gives both agents the same instruction set Claude Code uses. Loaded into AGENTS.md via @-import. Sibling of linear-workflow (the reviewer/dispatcher view).
allowed-tools: Read, Grep, Glob, Bash
---

<!-- Auto-synced from ~/.claude/includes/cloud-agent-environments.md — do not edit manually -->

## Cloud Agent Environments

Operational reference for cloud-agent harnesses (Codex Cloud, Cursor Background Agent). Loaded into AGENTS.md via `@`-import so agents read env-specific runtime details, gotchas, and capability scope before doing work.

For the **reviewer / dispatcher** view (push-back-vs-fix calculus, eligibility markers), see `linear-workflow.md` § "Cloud Agent Environments". This file is the **agent's own** env reference.

### Codex Cloud

#### 🚨 Code-mutation delegation SUSPENDED (Elixir projects, 2026-05-05)

**Codex Cloud has no Elixir/Erlang runtime.** `mix`, `iex`, `elixir`, and `erl` are not installed in the harness — verified 2026-05-05 against in-flight cartouche PRs where Codex's own testing log surfaced `mix: command not found in this container` for every attempted `mix` invocation (compile, format, test, credo, dialyzer). PRs landed with zero harness evidence; every check the agent claimed to run was a no-op.

This is a structural env gap, not a configuration miss. Until the Codex Cloud harness is restored to a working Elixir env, **`[CX]` code-mutation delegation is suspended** for any Elixir repo. See `task-prioritization.md` § "Codex Delegation (`[CX]`)" for the policy lock; route everything to `[CSR]` (Cursor) in the meantime — Cursor's harness has Elixir/OTP and runs the full mix toolchain.

**What's still permitted (no runtime needed):** review-only delegations — see § "Review-only tasks" below. Codex reads PR diffs from the issue body and posts a verdict comment; no `mix` invocation, no compile, no test runner involved. The Codex-Reviews-Cursor pattern (in `linear-workflow.md`) remains usable while the code-mutation suspension is in force, but treat as exception-not-default until the broader env is verified healthy.

#### Constraints (no internet, no Elixir runtime)

Even setting aside the suspended-delegation policy above, Codex Cloud's env has structural gaps that scope what it can do at all:

- **No Elixir runtime.** `mix`, `iex`, `elixir`, `erl` not installed. Codex cannot run any mix task — compile, format, test, credo, dialyzer all unavailable. Verified 2026-05-05.
- **No hex.pm.** Even if mix were installed, `mix deps.get` would fail — third-party hex-package API signatures cannot be verified at runtime. Stick to API surface that's reliably in training data; flag any uncertainty as `# TODO: verify against hex_docs` for the local reviewer rather than guessing.
- **No Tidewave.** `mcp__tidewave__project_eval` is not available. Tasks needing live-data diagnosis or runtime-state inspection should not be in scope.
- **No external HTTP.** RFCs, EIPs, reference implementations, vendor docs cannot be fetched. Cite the spec the user already pasted into the issue body; don't speculate from training-data recall.

#### What to ship in the PR (when delegation is restored)

When the runtime gap is fixed and `[CX]` code-mutation delegation resumes, Codex PRs may still ship without full local test evidence depending on what's been restored — the local reviewer (via `staged-review:commit-review`) runs the harness Codex couldn't. Make the reviewer's job easier:

- **List acceptance criteria you addressed** in the PR description (one bullet per criterion).
- **Flag uncertainty explicitly** — "I'm assuming `assert_receive/3` here based on training-data recall; please verify against ExUnit's hex docs."
- **Don't fabricate test counts or runtime claims** you can't verify. Past failure mode (2026-05-05): Codex PRs claimed harness runs that the env couldn't actually execute. CI is the only honest signal until the env is verified — see `linear-workflow.md` § "CI as the Shared Harness".

#### Review-only tasks (review delegation)

When you (Codex Cloud) are assigned an issue whose body opens with `REVIEW-ONLY task. Do NOT open a PR, commit code, or edit files`, the deliverable is a Linear comment — not a PR.

1. The issue body embeds the full PR diff inline under "## PR Diff". Read it from the issue body; you do NOT need `gh pr diff`.
2. Optionally — if `gh` CLI is available in your sandbox — run read-only commands `gh pr view <N> --json reviews,comments`, `gh api repos/<OWNER>/<REPO>/pulls/<N>/comments`, `gh pr checks <N>` for additional context. If `gh` is unavailable, skip this; the embedded diff is sufficient.
3. Post ONE comment on the delegation issue with: verdict line (APPROVED / BLOCKED / DISCUSS), findings table (`file:line | category | severity (1-10) | description`), one paragraph on acceptance-criteria coverage.
4. Transition the issue to Done.
5. Do **not** open a pull request. Do **not** commit code. Do **not** edit any file. Do **not** post review comments on the GitHub PR — verdict goes on the Linear issue only.

**Pilot status (2026-05):** the "no PR" instruction's reliability is unverified. If your harness pushes you toward opening a PR for a review-only issue, **stop and post a Linear comment instead**. Stray review-PRs are a known v1 risk.

### Cursor Cloud

#### Runtime

The Cursor Background Agent Linux env ships with Erlang and Elixir at non-asdf paths. Set PATH explicitly before any mix command:

- **Erlang/OTP 27** — installed at `/usr/local/bin/erl` (prebuilt `.deb` from [benoitc/erlang-dist](https://github.com/benoitc/erlang-dist)).
- **Elixir 1.18.4** — installed at `/usr/local/elixir/bin/`. Add to PATH:

  ```bash
  export PATH="/usr/local/elixir/bin:$PATH"
  ```

- **asdf shim gotcha** — if `asdf` shims are present in PATH (often inherited from `~/.bashrc`), they intercept `erl` and fail with `"No version is set for command erl"`. The Cursor environment-setup script removes them; if the error reappears mid-session, check `~/.bashrc` for asdf entries and restart the shell.

#### Capabilities

Cursor cloud has internet + can run mix tasks (verified in round-trip testing):

- **hex.pm reachable** — third-party hex-package API signatures can be verified directly. The `assert_received` vs `assert_receive` class of bug should not recur on Cursor PRs.
- **Mix tasks runnable** — `mix deps.get`, `mix compile`, `mix test` (and `mix test.json` if `ex_unit_json` is in deps), `mix credo --strict`, `mix format --check-formatted`, `mix dialyzer` (provided the PLT cache builds — first-run cost on a fresh env).
- **General HTTP likely available** — not yet stress-tested against arbitrary external APIs / RFCs / EIPs. Treat as broadly available pending counter-evidence.

#### Self-validation expectation

**Cursor MUST run the full harness green before opening the PR.** A PR that opens with any harness check failing is a defect, not a draft for review — the local reviewer's job is the 5-category audit + acceptance-criteria cross-reference, *not* triaging mechanical harness failures the agent could have caught itself. A red harness in a Cursor PR is a push-back finding regardless of severity: stop the audit, post a Linear `@cursor` comment naming the failing check, wait for re-push.

**Mandatory pre-PR checklist** (every check must exit clean — exit 0 for tools that don't have content-aware exit codes; for `mix credo` see the TODO/FIXME exit-2 carve-out below):

```bash
mix format --check-formatted     # MUST be clean — no drift on touched files
mix compile --warnings-as-errors # MUST compile with no warnings
mix credo --strict               # MUST be clean (TODO/FIXME exit-2 is the only acceptable non-zero — see Gotchas)
mix sobelow --exit Low           # MUST be clean — security scanner; project's `.sobelow-skips` baseline applies
mix doctor                       # MUST be clean — every public function has @doc + @spec; honors `.doctor.exs` ignore_paths
mix test.json --quiet            # MUST be green — every test passes
mix test.json --cover --cover-threshold N  # MUST meet repo's coverage tier (≥80 standard, ≥95 critical)
mix dialyzer                     # MUST be clean — first-run PLT cost is on Cursor's clock, subsequent runs are cached
```

**Why MUST not SHOULD:** Cursor's env has the runtime to do this work; if the harness fails post-push, every reviewer/CI cycle that catches it is wasted ceremony. Push-back-on-red-harness is the cheapest enforcement loop — Cursor amends, re-pushes, CI re-runs in parallel with whatever else is in flight. The reviewer's audit attention should land on the diff's *substance* (acceptance criteria coverage, design judgment, edge cases the harness can't catch), not on `mix format` complaints.

**For the issue body's acceptance criteria:** see `linear-workflow.md` § "Mandatory Acceptance-Criteria Bullets" — every delegated issue carries an explicit "harness green at PR open" bullet, so a failing harness is a blocking acceptance-criterion miss, not a "soft polish" item.

#### Gotchas

- **Credo TODO/FIXME exit code** — Credo flags `TODO:` / `FIXME:` tags as design suggestions and exits with code 2 even when nothing else is wrong. Per `~/.claude/includes/development-philosophy.md` § "TODO Comment Requirements", surfaced TODOs are _tracked debt working as intended_, not regressions. Don't strip them. Treat exit code 2 with only TODO/FIXME findings as expected, not as a blocker.
- **`mix format --check-formatted` on pre-existing drift** — repos that aren't fully formatted may surface format violations on files outside the diff. Only fix drift on files the PR touches (per `critical-rules.md` § "FIX HOOK-FLAGGED ISSUES ON FILES YOU TOUCH"); leave the rest for the repo owner.

#### Linear handle

Cursor's Background Agent has Linear-displayName `cursor` (verified id: `b8668f6b-992f-4152-9e59-13b6fe1f599b`). Reviewers push back via Linear comments with `@cursor` mention; Cursor picks up the mention within ~5 min and amends the PR with a fresh commit, posting confirmation comments back on the issue. **Verified end-to-end** in early Cursor round-trip testing (2026-05): a verbatim code-suggestion push-back was applied surgically, no scope creep. Linear @-mention preferred over GitHub PR comment — keeps the conversation thread on the issue.

### CI as the Shared Harness

When the target repo has a `harness.yml` (see `elixir-ci-harness` skill in `claude-marketplace-elixir`), every PR push runs the full Elixir harness as a GitHub check — visible to user, agent, and PR review tooling. CI was originally pitched as the canonical fix for Codex's hex.pm gap (the harness could verify what Codex's env couldn't), but the 2026-05-05 finding that Codex's env has no Elixir runtime *at all* makes CI a fix-only-on-paper for Codex code-mutation delegation: a PR with no harness-validated commits is one CI green away from the same uncertainty either way. This is one of the reasons code-mutation `[CX]` delegation is currently suspended (§ "Codex Cloud → Code-mutation delegation SUSPENDED"). Cursor's env can run mix tasks but doesn't *guarantee* it pre-PR; CI still enforces the gate uniformly for Cursor PRs and remains the authoritative harness signal.

The shift this enables:

- **Reviewer reads `gh pr checks <n>`** instead of running the full local harness (was 15+ min per PR via local mix; CI runs in parallel with the agent's work and is done by the time the reviewer looks)
- **Push-back becomes the default for harness drift.** When CI flags a format / credo / dialyzer / coverage issue, the reviewer's job is to point the agent at the failing check — not to fix it locally. The cloud agent (Cursor especially, since it has hex.pm + can run mix) iterates against the same CI signal the reviewer sees
- **Local fix shrinks to the env-constraint exception cases.** Per `linear-workflow.md` § "Push-Back-vs-Fix-Locally Matrix by Agent", local-fix is reserved for items the agent fundamentally can't verify — hex.pm for Codex, Tidewave for both, external specs for Codex. CI handles everything else

`staged-review:commit-review` defers to CI status when present (Step 6 reads `gh pr checks` and treats green as the harness-gate signal). When CI is absent, it falls back to running the local harness inline and surfaces a `TODO(setup-ci)` finding pointing at this skill so the next iteration of the PR has CI.

**Adoption path for delegation-target repos without CI:** copy `templates/harness.yml` from the `elixir-ci-harness` skill into the target repo's `.github/workflows/`, customize the four marked points (branch, MIX_ENV, coverage threshold, integration tag), commit. The next PR push gets the harness check.

### AGENTS.md Generation

Both Codex and Cursor read `AGENTS.md` at the repo root if present. Generate it from `CLAUDE.md` so agents see the same instruction set Claude Code does — same hooks-equivalent guardrails, same `@`-imported includes.

#### Canonical generator

`scripts/sync-agents-md.sh` in the `claude-marketplace-elixir` plugin (path: `~/_DATA/code/claude-marketplace-elixir/scripts/sync-agents-md.sh`). Run from inside the target repo:

```bash
bash ~/_DATA/code/claude-marketplace-elixir/scripts/sync-agents-md.sh
```

The script reads `./CLAUDE.md`, resolves `@`-imports (including `~/`), inlines content with `<!-- @-import: ... -->` markers, and writes `./AGENTS.md`. Marker comment at the top reads `<!-- Auto-generated from CLAUDE.md by ... — do not edit manually -->`.

#### Workflow

1. Edit project `CLAUDE.md` (or any `~/.claude/includes/*.md` it imports).
2. Run `sync-agents-md.sh` to regenerate `AGENTS.md`.
3. Commit both files together — they should never drift.

#### When Cursor auto-generates an AGENTS.md PR

Cursor's setup task can autonomously open a PR scaffolding an `AGENTS.md` for its env (observed in round-trip testing). When this happens in a repo that already uses the `sync-agents-md.sh` workflow:

- **Close the auto-generated PR.** The canonical generator is the source of truth.
- **Extract any genuinely useful env-specific bits** (paths, gotchas, runtime quirks) and add them here in this include — so they auto-flow to every repo's AGENTS.md via the standard `@`-import chain.
- Don't merge ad-hoc per-repo `AGENTS.md` content. The whole point of generating from `CLAUDE.md` is single-source consistency across the portfolio.

### Cross-References

- `linear-workflow.md` § "Cloud Agent Environments" — reviewer-side push-back-vs-fix calculus
- `linear-workflow.md` § "Cursor Delegation Flow" / "Codex Delegation Flow" — issue creation, PR review, merge gate
- `task-prioritization.md` § "Codex Delegation (`[CX]`)" — eligibility criteria for delegation
- `critical-rules.md` § "FIX HOOK-FLAGGED ISSUES ON FILES YOU TOUCH" — touched-file scope for harness fixes
- `elixir-ci-harness` skill (claude-marketplace-elixir) — copy-ready CI workflow that closes the Codex-Cloud-no-hex.pm gap
- `feedback_codex_sandbox_pr_gap.md` — observed Codex env gaps post-allowlist
