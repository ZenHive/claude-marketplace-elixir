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

#### Constraints (no internet)

Codex cloud has no network reachability beyond the configured sandbox allowlist. Even with the allowlist, hex.pm and external HTTP remain effectively unreachable (per `feedback_codex_sandbox_pr_gap.md`). Plan around:

- **No hex.pm** — third-party hex-package API signatures cannot be verified at runtime. Stick to API surface that's reliably in training data; flag any uncertainty as `# TODO: verify against hex_docs` for the local reviewer rather than guessing.
- **No Tidewave** — `mcp__tidewave__project_eval` is not available. Tasks needing live-data diagnosis or runtime-state inspection should not be in scope.
- **No external HTTP** — RFCs, EIPs, reference implementations, vendor docs cannot be fetched. Cite the spec the user already pasted into the issue body; don't speculate from training-data recall.
- **No `mix test` against current deps reliably** — without hex.pm reach, `mix deps.get` may fail mid-run if the PLT/lock cache isn't already warmed. Document any test gaps in the PR description so the local reviewer can fill them.

#### What to ship in the PR

Codex PRs that ship without local test evidence are expected — the local reviewer (via `staged-review:commit-review`) runs the harness Codex couldn't. Make the reviewer's job easier:

- **List acceptance criteria you addressed** in the PR description (one bullet per criterion).
- **Flag uncertainty explicitly** — "I'm assuming `assert_receive/3` here based on training-data recall; please verify against ExUnit's hex docs."
- **Don't fabricate test counts or runtime claims** you can't verify.

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

Cursor SHOULD run the harness before opening the PR. The local reviewer's job is the **5-category audit + acceptance-criteria cross-reference**, not "did the harness pass." A Cursor PR that ships with failing tests is a Cursor harness gap to flag, not an env limitation.

Recommended pre-PR checklist:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix test.json --quiet
```

#### Gotchas

- **Credo TODO/FIXME exit code** — Credo flags `TODO:` / `FIXME:` tags as design suggestions and exits with code 2 even when nothing else is wrong. Per `~/.claude/includes/development-philosophy.md` § "TODO Comment Requirements", surfaced TODOs are _tracked debt working as intended_, not regressions. Don't strip them. Treat exit code 2 with only TODO/FIXME findings as expected, not as a blocker.
- **`mix format --check-formatted` on pre-existing drift** — repos that aren't fully formatted may surface format violations on files outside the diff. Only fix drift on files the PR touches (per `critical-rules.md` § "FIX HOOK-FLAGGED ISSUES ON FILES YOU TOUCH"); leave the rest for the repo owner.

#### Linear handle

Cursor's Background Agent has Linear-displayName `cursor` (verified id: `b8668f6b-992f-4152-9e59-13b6fe1f599b`). Reviewers push back via Linear comments with `@cursor` mention; Cursor picks up the mention within ~5 min and amends the PR with a fresh commit, posting confirmation comments back on the issue. **Verified end-to-end** in early Cursor round-trip testing (2026-05): a verbatim code-suggestion push-back was applied surgically, no scope creep. Linear @-mention preferred over GitHub PR comment — keeps the conversation thread on the issue.

### CI as the Shared Harness

When the target repo has a `harness.yml` (see `elixir-ci-harness` skill in `claude-marketplace-elixir`), every PR push runs the full Elixir harness as a GitHub check — visible to user, agent, and PR review tooling. This is the canonical fix for the Codex-Cloud-no-hex.pm gap: even when Codex's env can't run `mix dialyzer` or `mix doctor`, the PR check does. Cursor's env can run mix tasks but doesn't *guarantee* it pre-PR; CI enforces the gate uniformly across both agents.

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
