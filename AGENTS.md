<!-- Auto-generated from CLAUDE.md by claude-marketplace-elixir/scripts/sync-agents-md.sh — do not edit manually -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<!-- @-import: ~/.claude/includes/critical-rules.md -->
## 🚨 BE A REAL PARTNER, NOT A YES-SAYER

**Challenge ideas that seem wrong, risky, or suboptimal.** Not every user request is a good idea. A real partner pushes back when it matters.

- **Flawed approach:** "I'd push back on this because..." — don't just comply
- **Better alternative exists:** present it with reasoning, not "have you considered..."
- **Scope too big or small:** flag it. "This feels like it's solving the wrong problem" is valid
- **Wrong assumptions:** correct them; don't build on a shaky foundation
- **Tone:** direct and respectful, not combative. Disagree like a trusted colleague
- **When to yield:** if you've made your case and the user still wants to proceed, commit fully. Pushback ≠ blocking

## 🚨 NEVER START THE PHOENIX SERVER

The Phoenix server is always already running. Never run `mix phx.server` via Bash. Assume localhost:4000. User starts/stops manually. To verify behavior, ask the user to check the browser.

## 🚨 ALWAYS WRITE TESTS

Every feature MUST have tests, even if the spec doesn't mention them. Unit tests for context functions, integration tests for LiveViews, tests for all CRUD/validations/error cases/edge cases (nil, empty, boundary). A feature without tests is not complete.

## 🚨 RAISE COVERAGE BEFORE MUTATING

**Before any code-changing task on an existing module, that module's `mix test.json --cover` percentage must be at the target tier:**

- **≥80%** for standard business logic
- **≥95%** for critical business logic (signing, money handling, cryptographic operations, low-level encoders, security-sensitive parsers)

If below tier, raise coverage **first** — write the missing tests, confirm the gate passes, then implement the change. The new tests are part of the task, not a follow-up.

**Scope — code-changing mutations only.** Exempt:
- Doc-only edits (`@doc`, `@moduledoc`, inline comments, README, CHANGELOG)
- Formatting, whitespace, alias reordering, autoformat-driven changes
- Pure renames (variable, function, module — no behavior change)
- Typo fixes in strings, log messages, error messages

The gate is a "do I have a safety net before I touch this?" check; writing the missing tests also surfaces the module's actual contract.

**How to apply:**
1. Run `mix test.json --cover --quiet --output /tmp/cov.json` (or `--cover-threshold 80` for a hard exit).
2. Inspect the touched module's percentage: `jq '.coverage.modules[] | select(.module == "MyApp.Foo")' /tmp/cov.json`.
3. If below tier, write tests for the uncovered lines until the gate passes — even if those lines aren't the ones you came to change.
4. Then implement the original mutation.

**Tier classification:** "critical business logic" is project-defined. When in doubt, treat anything that handles money, signs/verifies, encodes/decodes wire formats, or enforces authorization as critical (95%). Plain data transforms, UI glue, and reporting code are standard (80%).

## 🚨 NEVER HIDE TEST FAILURES

**TESTS THAT HIDE ERRORS ARE WORSE THAN NO TESTS AT ALL.** Tests find bugs — a test that silently passes on errors is lying and will cause production bugs.

### ABSOLUTELY FORBIDDEN — NEVER WRITE THESE:

```elixir
# ❌ MAKES ANY OUTCOME PASS - COMPLETELY WORTHLESS
case result do
  {:ok, _} -> assert true
  {:error, _} -> assert true  # ← This makes ALL failures pass silently!
end

# ❌ HIDES ALL ERRORS WITH COMMENTS - DANGEROUS
{:error, _reason} ->
  # This is acceptable for testnet
  :ok  # ← NO! This silently passes EVERY error!

# ❌ COMMENTS DON'T VALIDATE BEHAVIOR
{:error, reason} ->
  IO.puts("Error may be normal: #{inspect(reason)}")
  assert true  # ← Still worthless!
```

### CORRECT PATTERNS — ALWAYS USE THESE:

```elixir
# ✅ FAILS LOUDLY ON UNEXPECTED ERRORS
case result do
  {:ok, data} -> assert is_map(data)
  {:error, :specific_expected_error} -> :ok
  {:error, other} -> flunk("Unexpected error: #{inspect(other)}")
end

# ✅ EXPLICIT ABOUT WHAT'S ACCEPTABLE
{:error, :insufficient_balance} ->
  :ok  # This specific error is expected and valid
{:error, other} ->
  flunk("Expected :insufficient_balance, got #{inspect(other)}")

# ✅ TEST SPECIFIC BEHAVIOR, NOT OUTCOMES
test "returns not_found when account doesn't exist" do
  assert {:error, :not_found} = get_account("invalid_id")
end

test "returns data when account exists" do
  assert {:ok, %{balance: _}} = get_account("valid_id")
end
```

**THE RULE:** If you don't know what error to expect, DON'T write the test yet. Explore via Tidewave MCP first, understand the real error cases, THEN write assertions. A test should FAIL when the code is wrong.

### INTEGRATION TESTS: NEVER SKIP SILENTLY ON MISSING CREDENTIALS

Integration tests requiring API credentials must **fail loudly** with actionable setup instructions, not skip silently:

```elixir
# ❌ BAD: Silent skip - test appears to pass when it didn't run
setup do
  api_key = System.get_env("API_KEY")
  if is_nil(api_key), do: :skip  # ← DANGEROUS! Test suite "passes" with 0 tests run
  {:ok, api_key: api_key}
end

# ❌ BAD: Returns :ok on nil - same problem
test "authenticated endpoint", %{credentials: nil} do
  :ok  # ← Test silently passes without actually testing anything
end

# ✅ GOOD: Fails loudly with actionable instructions
test "authenticated endpoint", %{credentials: credentials} do
  if is_nil(credentials) do
    flunk("""
    Missing testnet credentials!

    Set these environment variables:
      export BINANCE_TESTNET_API_KEY="your_key"
      export BINANCE_TESTNET_API_SECRET="your_secret"

    Get credentials at: https://testnet.binance.vision
    """)
  end

  # Actual test code...
end
```

**Pattern:** let the test run (don't skip in setup), check credentials at test start, use `flunk()` with multi-line message listing missing env vars, exact export commands, and the URL to get them. A suite with "0 failures" that ran 0 tests is lying.

## 🚨 FIX HOOK-FLAGGED ISSUES ON FILES YOU TOUCH

**When our hooks flag issues on files you touched, just fix them — including pre-existing flags unrelated to your change.** Don't plan around it, don't ask permission, don't burn tokens discussing whether to. Hook fires → fix → re-run → stage.

Applies to every hook-driven check (credo, format, dialyzer, doctor, sobelow, ex_dna, etc.). Scope is **only the files your change touched** — not the whole project. User pre-approves the broader scope so each fix doesn't need a clarifying question; debt accumulates across sessions otherwise, and a touched file ending dirtier than baseline makes the next session noisier.

**How to apply:**
- Pre-existing flags in your touched file count too: alias ordering, unused vars, refactor opportunities, `TODO:` formatting.
- Generated files → fix the generator, not the output.
- Don't move the fix to ROADMAP or a follow-up task. It happens in this commit.
- **Don't manually re-run a check the hook just ran on the same files.** Act on the hook output directly — re-running `mix test.json` / `mix credo` / `mix dialyzer.json` / `mix sobelow` / `mix precommit` on the file set the hook already graded is duplicated work. Full-suite re-runs earn their cost only before a PR/merge, after `mix deps.get` or a branch switch, or when the user asks. See `~/.claude/CLAUDE.md` § "Don't Re-Run Hook-Driven Checks on the Same Files" for the host-specific rule.

## 🚨 READ TO THE ANSWER — DON'T USE THE RUNNER AS AN ORACLE

**Reason to the fix by reading code; run once to CONFIRM — don't run to DISCOVER.**
The recurring failure mode: change → run full suite → read one failure → fix one
thing → run again, N times. Each cycle pays the suite-compile tax; N cycles for a
problem one read would have surfaced whole.

- **Read the code path before running the test that exercises it.** Front-load the
  model; don't outsource it to the runner. A 10-line read of the function beats
  learning its shape from a failing assertion three fixes later.
- **Treat a failure as a SURVEY, not a single fix.** Enumerate every plausible
  cause from the output + one read, fix them in a batch, then run once. Don't
  fix-one-and-rerun.
- **Verify handoffs/summaries against ground truth before building on them.** A
  compaction summary or another session's claim ("X is already wired") is a
  hypothesis. `grep` the load-bearing claim before you act on it.
- **Trust the hooks** (pairs with FIX HOOK-FLAGGED + the host CLAUDE.md rerun rule):
  per-edit checks already graded the file; re-running is wasted cycles.
- **Under a flaky terminal, go sequential-and-simple by default** — one command →
  write to a file → Read it. No parallel batches of *dependent* calls: one early
  failure cancels the whole round.

**Failure-mode tell — about to run the same test a 3rd time to find the *next*
problem? STOP. Read the code path and the opts you're passing against a known-good
sibling, list all the causes, fix them together, run once.**

## 🛑 MINIMALIST APPROACH FIRST

**Do exactly what is asked — nothing more, nothing less.**

- **NO** proactive features or improvements unless explicitly requested
- **NO** additional error handling beyond what's needed
- **NO** extra validation, refactoring, or documentation files
- **ALWAYS** ask before adding anything not explicitly mentioned
- **IF UNCLEAR:** Ask "Should I also do X?" before proceeding

### BUT: Minimalism Is Not Incomplete Work

**"Start minimal" means no EXTRA features — not skipping items the task implies.**

When a task says "define unified data structs," the scope is ALL structs the system needs, not "the 7 I can think of." When a source of truth exists (e.g., `method_defs/0` listing 241 methods, each implying a return type), audit it — don't cherry-pick.

**The pattern to avoid:**
1. Task says "build X for all Y"
2. Claude scopes to "build X for the obvious Y" (filtering/cherry-picking)
3. Later session discovers the gap and adds a fix-up task
4. The fix-up task does what should have been done originally

**How to catch it:**
- If the task mentions "all," audit the source of truth — don't rely on what comes to mind
- If a data source defines N items, process N items (or explain why some are excluded)
- If you're writing "for now we'll just do these 7" without being asked to limit scope — STOP. That's scoping out, not starting minimal.

**Minimalism guards against:** adding caching when nobody asked, building admin UIs "just in case," over-abstracting simple code.

**Minimalism does NOT mean:** skipping half the items in an enumerable set, cherry-picking "common" cases from a known complete list, or deferring clearly-implied work to future tasks.

## 🚨 NO PSEUDO-RIGOROUS HEDGING

**Don't gate user-requested work behind invented "evidence requirements" you cannot satisfy.**

You have no consumer telemetry. No usage counts. No signal about whether a feature will be called 12 times or 1200 times. So phrases like *"demand for this is unproven"*, *"we should wait until N consumers ask for this"*, *"is this widely needed?"*, *"only worth doing if a Nth+ use case is imminent"* are **risk-aversion theater**, not analysis. They sound rigorous; they're hedging.

- In single-developer codebases or focused teams, the developer IS the demand signal. They asked. That's the data point.
- "Wait for usage data" is a corporate-flavored instinct that doesn't apply to small teams. There's no telemetry pipeline; there's the user in front of you.
- It gaslights the user: their request is reframed as "unproven need" requiring further validation. They have to argue for what they already asked for.

**Distinguish from minimalism (the section above):**
- Minimalism = don't add features the user **didn't ask for**.
- This rule = don't refuse / defer features the user **did ask for** by inventing evidence requirements.

**Failure-mode test — if you're about to write any of these, STOP:**
- "Demand for X is unproven"
- "We should wait until..."
- "Is this widely needed?"
- "Only worth doing if a Nth+ case is imminent"
- "Bet on usage data before building"

You don't have data either way. The honest framing is: *"I don't know if you'll use this 12 more times — that's your call."*

**What to do instead:**
- Name the **actual technical risks** (e.g., "the macro might grow more knobs than the duplication it removes," "this couples us to an upstream that breaks every release," "the test surface explodes at N+1 cases"). Those are real costs you can reason about.
- Cite **concrete precedents** when scoring complexity (see `development-philosophy.md` "Cite Ecosystem Precedents Before Crying Complexity"). Generic "this could grow" without naming a specific failure pattern is the same hedging by another name.
- If the task genuinely scores low on benefit/usefulness, score it that way honestly — don't smuggle a demand-speculation into the U/B numbers and pretend it came from analysis.

**Scope extends to task `body` fields and scoring justifications, not just live responses.** Same hedge phrases written into a task's `body` to justify B/U — "table-stakes", "increasingly expected", "now standard", "buyers expect", "competitors are starting to", "modern apps all do" — inflate the score the same way they inflate a response. Required instead: named consumer evidence (named partner asked, named competitor lever, measured conversion uplift) OR honest low score. Enforced at task-creation time by `task-writing.md` § Pre-Creation Gate (question 5).

## 🚨 GIT COMMIT / PUSH / PR-CREATE — SCOPED BY WORKTREE

**The act of creating a tracked worktree under `~/_DATA/worktrees/<repo>/<id>/` is itself the scope authorization for git operations on that branch.** Outside a tracked worktree, the strict default still applies: don't commit or push without explicit user request. See `~/.claude/includes/worktree-workflow.md` for the worktree workflow itself.

### ✅ Auto-allowed inside a tracked worktree (`~/_DATA/worktrees/<repo>/<id>/`)

- `git commit` to the worktree's own branch
- `git push -u origin <branch>` to publish the feature branch
- `gh pr create` against the repo's default base branch

The worktree's HEAD is the feature branch by construction, so accidental commits to a shared branch (`main`, `master`, `development`) can't happen here.

### ✅ Auto-allowed: `audit(...)` commits from `audit-review`

`staged-review:audit-review` commits its findings as a single commit per run with subject prefix `audit(...)` (e.g. `audit(abc1234): 3 fixes — dual-reviewer pass`). These are auto-allowed:

- **Inside a tracked worktree** — same as any commit on the worktree's own branch (covered above).
- **On the repo's default branch** (`main`, `master`, or `development` — many of this user's repos use `development` as the default; treat the repo's actual default branch, whatever it's named, as the target) — post-merge audit-review runs on the default branch by design (audit IS the post-merge bookkeeping commit). This is one of the few exceptions to the strict "no commits to shared branches" rule, scoped specifically to commits whose subject matches `^audit\(` from a single audit-review run.

The skill writes `.audit/<sha>.md` reports + applies hygiene fixes + commits as one atomic step. The audit commit IS the inspectable artifact for the run; no manual override is needed.

❌ **Still asks first:** non-`audit(...)` commits to the default branch; multiple audit commits in one run (audit-review batches into one); commits prefixed `audit(...)` from any source other than the audit-review skill.

### ❌ Still requires explicit user request

- **Commit/push on the main checkout** (`~/_DATA/code/<repo>/`) directly to a shared branch (`main`, `master`, `development`) — even if the user authorized commits in a worktree this session, the main checkout is a separate scope
- **Commits in dependency repos / sibling repos checked out for inspection** — original "surprised the user" scenario; these aren't tracked worktrees
- **`gh pr merge`** — governed by `delegation-rules.md` § "DON'T AUTO-MERGE PRS" (in repos that load delegation)
- **Force-push, amend published commits, rebase shared history** — irreversible-by-default
- **`git push` to a cloud-agent's branch** (`codex/...`, `cursor/...`) — governed by `delegation-rules.md` § "Force-Push to `cursor/*` Is One-Shot Scope Authorization"

### 🟡 One-shot scope authorization: force-push to `cursor/*`

Once the user explicitly authorizes a force-push (or any push) to a specific `cursor/<name>` branch in a session, that authorization is **scope-bound to that branch for the remainder of the session** — re-running the same operation against the same branch does NOT require re-asking. Mirrors the worktree rule: scope is granted once, then the loop runs without per-call friction.

- **In scope:** subsequent `git push --force` / `git push --force-with-lease` to the SAME `cursor/<name>` branch in the same session
- **Out of scope (still ask first):** a different `cursor/<other>` branch, any `codex/...` branch (Codex flow remains strict), force-push to shared branches (`main`, `master`, `development`), force-push to your own feature branches outside a worktree
- **How to apply:** when you're about to force-push to a `cursor/*` branch and the user has already authorized it for this branch in this session, just announce in one line ("Force-pushing to `cursor/foo`") and do it. Don't re-ask. If they haven't authorized it yet for this branch, ask once, then proceed freely for the rest of the session.

### How to apply

- **In a tracked worktree:** when work is done, run the full loop (`git commit` → `git push -u origin <branch>` → `gh pr create`) without asking. Briefly state what you're doing in one line, then do it. Cleanup (`git worktree remove`) happens after PR merge — same session, as part of completing the task.
- **In the main checkout or anywhere else:** stage with `git add <paths>` and summarize what's ready. Stop there.
- **Subagents inherit the same scoping.** When dispatching a subagent that may touch git, include the worktree path in the prompt so the subagent knows where it's auto-allowed; outside that path, the strict rule applies.
- **Approval is scope-bound to one branch / one PR.** "Push and PR this fix" authorizes the loop for that worktree's branch — not subsequent branches.

**Cloud-agent-flow corollaries** (PR merge, push-to-agent-branch, default-DO Linear/PR comments, don't-steal-`[CX]`/`[CSR]` tasks) → see `delegation-rules.md`. Only loaded in repos that actively delegate.

## Shell Safety

`rm` (including `rm -rf`) is permitted — the hook allows it; the old blanket ban caused more friction than it prevented. One habit, not a gate: before an irreversible delete, glance at the target — confirm the path is what you intend (no unexpanded `$VAR`, no wildcard catching more than you mean, not a path you didn't create or weren't asked to remove). `git rm` for tracked files keeps the removal in the diff. (Destructive *dependency / build* commands — `mix deps.clean`, `rm -rf _build` — stay consent-gated below, for slow-recovery reasons, not safety.)

## 🚨 NEVER RUN DESTRUCTIVE DEPENDENCY COMMANDS

**Never run these without explicit user consent:**

- ❌ `mix deps.clean` / `mix deps.clean --all` — deletes compiled deps; slow recovery
- ❌ `mix deps.unlock --all` — unlocks all versions
- ❌ `rm -rf _build` or `rm -rf deps` — nukes build artifacts
- ❌ `mix clean` — removes compiled app files

**What to do instead:**
- Compile error → just retry `mix compile` or `mix test`
- Specific dep issue → `mix deps.compile <dep_name> --force`
- Most "corrupt cache" issues are transient glitches

Ask before running any destructive command.

## 🚨 Integrity and Accuracy

**Never fabricate information, experience, or data.** When providing technical guidance:

- **Honest about sources:** distinguish codebase observations, general knowledge, best practices, and speculation. Never claim production experience you don't have or invent metrics/timelines/stats.
- **No false authority:** don't claim "we learned" without repo evidence; don't state "after X years in production" without evidence; use "typically/often/may/could" when uncertain.
- **Document uncertainty:** identify what you don't know, suggest validation paths, provide ranges over false precision.
- **Trace sources:** "Based on the code in file.ex...", "According to docs/FILE.md...", "Common practice in Elixir...", "This suggests..."

False technical claims cascade into bad architectural decisions, wasted resources, and damaged trust.

## 🚨 RESEARCH BEFORE ASSERTING ON NICHE TECHNICAL CLAIMS

**When the question lives outside reliable training coverage, do online research proactively — without being asked.** The default failure mode is asserting from training-bias confidence on specs/protocols/niche APIs that the model never deeply absorbed. Codex routinely fetches reference implementations to verify assumptions; Claude defaults to "answer from memory." Close the gap.

**Research proactively (use WebFetch on a known URL, WebSearch to discover one) when the topic is:**

- **Wire formats / encodings** — RLP, ABI, SSZ, Protobuf, MessagePack, BLS, BIP-32/39/44 paths, EIP-712 typed data, CBOR, ASN.1 / DER. Fetch the spec or a reference implementation (geth, reth, py-evm, libsecp256k1, official BIPs) before claiming byte order, length-prefix rules, padding, or canonical-form requirements.
- **Protocol details** — EIPs, RFCs, JSON-RPC method shapes/error codes, opcode gas costs, P2P handshake messages, exchange API quirks (Binance/Deribit/OKX rate-limit headers, signature canonicalization, error envelopes).
- **Niche / recent library APIs** — anything outside mainstream-framework training where you'd be guessing function signatures, return shapes, or version-pinned breaking changes. If you'd write `# probably something like` in a comment, that's the signal — go fetch the docs.
- **Cross-implementation edge cases** — when "what does X do when Y is malformed?" matters, check **≥2 reference implementations**. One impl's behavior can be a bug; agreement across two is the spec in practice.

**Don't research (use training memory) when the topic is:**
- Pure Elixir / OTP idioms, stdlib functions, mainstream Phoenix / LiveView / Ecto / Ash patterns
- Generic REST, HTTP, JSON, SQL, shell — well-trodden ground
- Anything already in the project's codebase or in hex docs you've already pulled in this session
- Anything explicitly documented in a CLAUDE.md or include the user has imported

Training-bias overconfidence on niche specs ships off-by-one byte-order bugs, wrong opcode gas costs, malformed RLP encodings, miscounted signature recovery IDs — exactly the class of bug a 30-second reference-impl check catches. Cite the source so the user can verify instead of trusting model authority.

**How to apply:**
1. Notice the trigger — you're about to assert behavior in one of the "research proactively" categories.
2. Prefer **WebFetch** when the canonical URL is known (the EIP, RFC, hex package, or a reference-impl file path on GitHub). Use **WebSearch** to find one when it isn't.
3. Cite what you fetched — link the EIP/RFC, the reference-impl file + line range, the hex doc URL. The citation is part of the answer, not optional.
4. For cross-impl checks, name both implementations: *"geth's RLP encoder treats X as Y; reth agrees — see [link] and [link]."*
5. If a fetch fails or returns ambiguous text, say so explicitly and lower confidence — don't fall back to "well, I think..." without flagging the downgrade.

This rule complements **Integrity and Accuracy** above: that one says *don't fabricate*; this one says *go verify when training is thin*. The combined posture is "cite the source, fetch when needed, never assert with confidence you can't justify."

## 🚨 NO EVASION — SIT WITH THE HARD THING

**When you hit something difficult, do NOT optimize for "appearing productive" by moving to easier work.** The most common failure mode: hit a wall → silently move on → user discovers the gap later.

### Evasion Patterns (don't use without explicit user approval)

**Task abandonment:**
- "let's move on to", "we can defer this", "skip this for now"
- "let's come back to this later", "we can revisit this", "let's table this"

**Scope reduction without asking:**
- "to keep things simple, I'll skip", "for brevity, I won't"
- "that's out of scope", "not strictly necessary"

**False completion:**
- "that should be enough", "the rest is straightforward"
- "I'll leave the rest as an exercise", "the pattern is clear enough"

**Deflection to user:**
- "you might want to", "you could manually", "you'll need to handle"
- (Sometimes legitimate — but often evasion disguised as helpfulness)

### What To Do Instead

1. **Stay with it.** If it's hard, say "this is hard because X" — don't silently move on
2. **Flag blockers explicitly.** "I'm blocked on X because Y. Options: A, B, or C."
3. **Ask before deferring.** "This is taking longer than expected. Should I continue or switch?"
4. **Never write workarounds silently.** If tempted to add a fallback/default/nil-guard for missing data, ask: should this come from upstream? If yes, STOP and report it
5. **Incomplete work gets a TODO.** If you must move on, leave a tracked TODO — not a silent gap


<!-- Selective-load (Opus 4.8): only critical-rules is eager-imported — the irreducible
guardrail floor. Everything this repo used to @-import (across-instances, worktree-workflow,
delegation-rules, task-prioritization, task-writing, rmap, workflow-philosophy, web-command,
code-style, development-philosophy, agent-economy, elixir-setup, development-commands,
ex-unit-json, dialyzer-json) is now reachable as a skill on demand — and every one is a
local file in this repo (~/.claude/includes/ mirror) you can Read directly. Re-add an
@-import here only if Opus quality drops on that surface. See ~/.claude/setup-guide.md
§ "Selective-Load Philosophy" for the rationale and the per-include skill mapping. -->

## Repository Purpose

This is a **Claude Code plugin marketplace** for Elixir and BEAM ecosystem development. It provides automated development workflows through hooks that trigger on file edits and git operations.

**Naming:** GitHub repo is `claude-marketplace-elixir` (describes scope), Claude Code marketplace namespace is `deltahedge` (org identity — also covers language-agnostic plugins: `cloud-delegation`, `staged-review`, `task-driver`, `portfolio-strategy`). Plugins are referenced as `<plugin>@deltahedge`.

### Includes → Skills Sync

**`~/.claude/includes/*.md` files are canonical.** Skill SKILL.md files are auto-synced from includes — never edit skill bodies directly. After editing an include, run:

```bash
./scripts/sync-skills-from-includes.sh          # sync all 30 mapped skills
./scripts/sync-skills-from-includes.sh --dry-run # preview changes
```

The script preserves SKILL.md frontmatter (name, description, allowed-tools) and replaces the body with include content. See `scripts/sync-skills-from-includes.sh` for the full mapping.

### Writing Style: Factual + Terse

Includes (`~/.claude/includes/*.md`) and skill bodies are reference material — every line costs context.

- State the rule. Drop standalone `**Why:**` / `**Why this matters:**` blocks; fold load-bearing rationale into the rule as one parenthetical.
- No dated provenance, past-incident anecdotes, or verification breadcrumbs in prose. Current state only.
- Good/bad example blocks may keep historical context — they teach by showing.
- Drop hedging filler ("essentially", "fundamentally", "the reality is") unless load-bearing.

### Setup Guide Sync Check

Verify `~/.claude/setup-guide.md` is in sync with actual includes on disk:

```bash
./scripts/check-setup-guide.sh          # report drift
./scripts/check-setup-guide.sh --quiet  # exit code only (0=ok, 1=drift)
```

Reports undocumented includes (files on disk not in setup-guide) and missing includes (referenced but not on disk). Run after adding or removing includes.

**Note:** A separate **SessionStart prompt hook** in `~/.claude/settings.json` handles per-project CLAUDE.md checks — it detects the project stack (Elixir, Phoenix, etc.) and flags missing includes against the setup-guide templates. That hook is user-level config, not part of this repo.

### Codex Plugin Sync

Generate a Codex-friendly subset of this marketplace (writes to `~/plugins/` and `~/.agents/plugins/marketplace.json`):

```bash
./scripts/sync-codex-plugins.py                  # dry-run (default)
./scripts/sync-codex-plugins.py --apply          # write files
./scripts/sync-codex-plugins.py --plugin elixir  # sync one plugin
./scripts/sync-codex-plugins.py --marketplace-only  # regenerate marketplace.json only
```

Transforms Claude-Code-specific tool names and frontmatter (`allowed-tools:`, `AskUserQuestion`, `TodoWrite`, `SlashCommand`) to Codex equivalents. The elixir subset is narrowed via explicit allow-lists for skills and scripts. Delegates include→skill sync to `~/.codex/skills/sync-claude-includes/scripts/sync_claude_includes.py` unless `--skip-core-sync` is passed. Tests live at `test/test-sync-codex-plugins.sh`.

For the current verified Codex integration status, active hook model, and
upstream tracking, see `codex_hooks_state.md`.

## Architecture

### Plugin Marketplace Structure

```
.claude-plugin/
└── marketplace.json          # Marketplace metadata and plugin registry

plugins/
├── elixir/                   # Main Elixir development plugin (was: core)
│   ├── .claude-plugin/
│   │   └── plugin.json       # Plugin metadata
│   ├── hooks/
│   │   └── hooks.json        # Hook definitions
│   ├── scripts/              # Consolidated hook scripts
│   └── README.md             # Plugin documentation
├── phoenix/                  # Phoenix-specific skills
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/               # Phoenix patterns, scope, JS, daisyUI, nexus
├── elixir-workflows/         # Workflow commands (was: elixir-meta)
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── commands/             # Workflow slash commands
│   └── skills/               # Workflow generator skill
├── git-commit/               # Commit workflow (was: git)
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── commands/
├── code-quality/             # Language-agnostic LLM code quality gate
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── hooks/                # PreToolUse prompt hook (TODO/workaround enforcement)
├── staged-review/            # Universal code review workflow
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/               # code-review, audit-review skills
├── task-driver/              # Roadmap-driven task execution
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/               # task-driver, rmap (roadmap substrate)
├── cloud-delegation/         # Linear-as-queue + cloud-agent (Codex/Cursor) delegation
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/               # linear-queue, agent-dispatch, agent-pr-review, flow-review, linear-workflow hub, cloud-agent-environments, sprite-claude-code
└── marketplace-hygiene/      # Marketplace-integrity hooks (block SKILL.md edits, validate manifest JSON)
    ├── .claude-plugin/
    │   └── plugin.json
    ├── hooks/
    │   └── hooks.json
    └── scripts/              # block-skill-edits.sh, validate-marketplace-json.sh
```

### Key Concepts

**Marketplace (`marketplace.json`)**: Top-level descriptor that defines the marketplace namespace ("deltahedge"), version, and lists available plugins.

**Plugin (`plugin.json`)**: Each plugin has metadata (name, version, description, author). The `hooks/hooks.json` file is loaded automatically by convention - do NOT add a `hooks` field to plugin.json unless referencing additional hook files.

**Hooks (`hooks.json`)**: Define automated commands that execute in response to Claude Code events:
- `PostToolUse`: Runs after Edit/Write tools (e.g., auto-format, compile check)
- `PreToolUse`: Runs before tools execute (e.g., pre-commit validation before git commands)

### Hook Implementation Details

The marketplace uses consolidated hooks for efficiency (12 post-edit hooks → 2, 10 pre-commit hooks → 1):

**Elixir plugin** - Elixir-specific command hooks:
1. **post-edit-check.sh** (non-blocking, PostToolUse): After editing `.ex`/`.exs` files, runs format, compile, credo, sobelow, doctor, struct hints, hidden failure detection
2. **ash-codegen-check.sh** (non-blocking, PostToolUse): Runs `mix ash.codegen --check` if Ash dependency exists
3. **warn-doctest-io-and-untagged-todos.sh** (non-blocking, PostToolUse): Warns on `IO.puts` / `IO.inspect` inside `@doc` / `@moduledoc` heredocs (development-philosophy.md § "No IO in @doc examples"), and on `#` comments starting with deferred-work phrases ("For now,", "Currently,", "Temporarily,", "In production,", "This is a workaround,") that aren't prefixed with `TODO:` (development-philosophy.md § "TODO Comment Requirements"). False-positive guards: only matches `^[[:space:]]*#` so `#` mid-string doesn't fire; IO check tracks `@doc """ ... """` heredoc range via awk state.
4. **pre-commit-unified.sh** (blocking, PreToolUse): Before `git commit`, runs an authoritative inline quality gate (format, compile, credo, doctor, sobelow, mix_audit, ash.codegen). **No tests, no dialyzer, no ex_doc** — tests run per-edit via `post-edit-check.sh`; tests/dialyzer/`mix docs` are too slow/flaky for the inner loop and belong in CI / manual `mix precommit` / `mix precommit.full`. Does **not** defer to a project `mix precommit` alias (the alias is for manual/CI use). Each failing check's full untruncated output is saved to `/tmp/elixir-precommit/<sha256(project_root)>/<check>.log` and the paths are named in the deny message so the agent reads them instead of re-running. Uses 180s timeout.
5. **block-destructive-bash.sh** (blocking, PreToolUse): Denies two command shapes: `mix phx.server` (critical-rules.md § NEVER START THE PHOENIX SERVER) and destructive deps/build (`mix deps.clean`, `mix clean`, `mix deps.unlock --all`, `rm -rf _build`, `rm -rf deps` — critical-rules.md § NEVER RUN DESTRUCTIVE DEPENDENCY COMMANDS). Allows `mix deps.unlock --check-unused`, `mix deps.compile <dep> --force`. Bare `rm` (ordinary file deletion) is **not** blocked — only the `rm -rf _build` / `rm -rf deps` targets.
6. **warn-shell-eval-elixir.sh** (non-blocking, PreToolUse): Warns when Claude is about to run Elixir code through the shell (`mix run -e`, `elixir -e`, `iex -e`, `mix run X.exs`) — suggests `mcp__tidewave__project_eval` / `mcp__tidewave__get_logs` for same-BEAM evaluation without fresh-VM startup. Warn-only; the warning footer names `priv/repo/seeds.exs` and one-shot CI scripts as legitimate exceptions. Pattern + warning ported from hieroglyph's hookify rule.
7. **warn-missing-tool-flags.sh** (non-blocking, PreToolUse): Warns when `mix credo` is invoked without both `--strict` and `--format json` (per `development-commands.md`), or when `mix compile` runs without a `time` prefix. Skips non-analysis credo subcommands (`--version`, `gen.*`, `help`).
8. **suggest-test-include.sh** (non-blocking, PreToolUse): When `mix test.json` runs without `--include` flags, parses excluded tags from `test/test_helper.exs` and injects them into Claude's context. Prevents false "suite passes" claims when only the offline subset ran. Stays silent on focused runs (`--include`/`--only`/`--failed`/explicit test-file arg) and projects with no `exclude:` list.

**Code-quality plugin** - Language-agnostic LLM gate (separate from Elixir plugin so it installs cleanly on Rust/Go/Python projects):
1. **Code quality gate** (blocking, PreToolUse, `type: prompt`): Before Edit/Write/MultiEdit on source files (`.ex`, `.exs`, `.go`, `.rs`, `.js`, `.ts`, `.py`, `.rb`, `.java`, `.c`, `.cpp`, `.h`), the LLM itself evaluates the diff and denies untracked TODO/FIXME markers, unmarked deferred-work comments ("for now", "temporarily", …), stub functions, and silent workarounds. Markdown/config files bypass the check.

**Cloud-delegation plugin** - Cross-cutting AGENTS.md sync:
1. **agents-md-sync.sh** (non-blocking, PostToolUse): After editing `~/.claude/CLAUDE.md`, any direct child of `~/.claude/includes/`, or any `~/_DATA/code/<repo>/CLAUDE.md`, regenerates `AGENTS.md` via `scripts/sync-agents-md.sh` in every affected repo that has an existing `AGENTS.md` (never auto-creates). Idempotent; never stages or commits. Closes the staleness window between edit and the next SessionStart drift check.

**Staged-review plugin** - Audit-tail detection:
1. **check-unaudited-commits.sh** (non-blocking, SessionStart): Walks `git log --grep '^audit('` to find the last audit ancestor; emits `additionalContext` recommending `/staged-review:audit-status` or `Skill(audit-review)` when ≥3 commits sit past it. Silent below threshold or outside any git repo. Shares `unaudited-commits.sh` helper with the `/audit-status` slash command (Tasks 38 + 39).

**Marketplace-hygiene plugin** - Marketplace-integrity hooks for deltahedge plugin development:
1. **block-skill-edits.sh** (blocking, PreToolUse): Before `Edit|Write|MultiEdit`, denies edits to any of the 30 auto-synced `plugins/*/skills/*/SKILL.md` paths registered in `scripts/skill-include-map.sh`. Deny message names the canonical `~/.claude/includes/<name>.md` and the sync command. Unmapped SKILL.md files (`workflow-generator`, `tidewave-guide`, etc.) pass through. Sources the shared mapping file at runtime via `git rev-parse --show-toplevel` so a single edit point covers both this hook and the sync script.
2. **validate-marketplace-json.sh** (non-blocking, PostToolUse): After `Edit|Write|MultiEdit` on any file basenamed `marketplace.json`, `plugin.json`, or `hooks.json`, runs `jq -e . "$FILE" >/dev/null 2>&1` and surfaces parse errors as `additionalContext` (with the literal `jq:` error message). Silent on valid JSON and non-matching files. Replaces the manual `cat … | jq .` step documented earlier in this file as a one-shot Bash command.

Self-contained — no `_shared/lib.sh` sourcing, inline `jq` envelopes, follows the `cloud-delegation/agents-md-sync.sh` precedent.

Hooks use `jq` to extract tool parameters and bash conditionals to match file patterns or commands. Output is sent to Claude (the LLM) via JSON with either `additionalContext` (non-blocking) or `permissionDecision: "deny"` (blocking).

### Skills (45 total)

Skills provide specialized capabilities for Claude to use on demand, complementing automated hooks with user-invoked research and guidance. The agent-facing catalog (what each does, when to invoke) lives in `SKILLS.md` at the repo root — keep it in sync when adding or removing skills.

**Elixir plugin** (26 skills):

| Skill | Description |
|-------|-------------|
| hex-docs-search | Research Hex package API docs — function signatures, module docs, typespecs |
| usage-rules | Package-specific coding conventions, patterns, and best practices |
| development-commands | Mix commands reference — test.json, dialyzer.json, credo JSON, builds |
| dialyzer-json | AI-friendly Dialyzer output with `mix dialyzer.json` — fix hints, grouping |
| ex-unit-json | AI-friendly test output with `mix test.json` — flags, workflows, jq patterns |
| elixir-setup | Standard project setup — deps (Styler, Credo, Dialyxir, Doctor, Tidewave) |
| tidewave-guide | Tidewave MCP tools for runtime Elixir app interaction |
| web-command | When to use `web` command vs `WebFetch` tool for browsing |
| integration-testing | Integration testing patterns — credential handling, external APIs |
| popcorn | Popcorn: run Elixir in the browser via WebAssembly |
| git-worktrees | Run multiple Claude Code sessions in parallel using git worktrees |
| zen-websocket | ZenWebsocket library for WebSocket connections with reconnection |
| roadmap-planning | Prioritized roadmaps with D/B scoring for task lists |
| oxc | OXC Rust NIF — parse/transform/bundle/minify JS and TS via ESTree AST |
| quickbeam | QuickBEAM JS runtime on the BEAM — eval/call, pools, handler bridge |
| npm-ci-verify | npm_ex CI/install verification — lockfile sync, frozen installs |
| npm-security-audit | npm_ex security — CVE audit, license compliance, supply-chain risk |
| npm-dep-analysis | npm_ex graph analysis — size, fan-in/out, dedup, package quality |
| reach | Reach PDG/SDG — slicing, taint, dead-code, OTP state machines, codebase-level analysis |
| elixir-volt | JavaScript on the BEAM ecosystem map — OXC, QuickBEAM, npm_ex, Phoenix frontend stack |
| agent-economy | Designing APIs for AI agents — Descripex, manifests, MCP tools, EIP-8004 verification |
| api-toolkit | ApiToolkit — InboundLimiter, RateLimiter, Cache, Metrics, Provider DSL, Discovery |
| upstream-pr-workflow | Contributing PRs to forked libraries without leaking personal tooling into the diff |
| elixir-ci-harness | Copy-ready `harness.yml` GitHub Actions workflow — drift-free version sourcing from `.tool-versions`, format/compile/credo/doctor/sobelow/test+cover/dialyzer gate; default 85% coverage; closes the Codex-Cloud-no-hex.pm gap by making harness output a PR check |
| code-style | Complexity-based code-quality KPIs — per-tier budgets (functions/module, lines/function, call/pattern-match depth) + universal standards (Dialyzer 0, Credo 8.0+, 80/95% coverage, 100% public-API docs) |
| development-philosophy | Elixir doc + internal-API conventions — no-IO-in-@doc, defp/@doc-false/@moduledoc-false/underscore decision tree, mandatory @spec, doctests-vs-ExUnit, TODO tagging, tightening-validators, cite-precedents/check-hex-before-crying-complexity |

**Phoenix plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| nexus-template | Nexus Phoenix admin dashboard template with Iconify icons |
| phoenix-setup | Phoenix project setup — phx.gen.auth, Sobelow, LiveDebugger, formatter |

**Elixir-workflows plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| workflow-generator | Generate customized workflow commands (research, plan, implement, qa) |

**Staged-review plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| code-review | Pre-commit single-reviewer triage of `git diff --staged` — 5+1 categories, plan-mode-with-auto-apply (one user gate: exit-plan-to-apply). No Codex dispatch and no Claude+Codex dialogue at this layer — both moved to `audit-review` (deferred). `discuss-design` items escalate to user, who can defer to audit-review's dialogue pass |
| audit-review | Post-commit / post-merge audit on committed code — full 5+1 categories, mandatory parallel Codex dispatch, absorbs bot-comment triage (Step 5d, 3-reasoner merge), Linear close-out (Step 12.5), acceptance-criteria verification (Step 9 extension); auto-applies hygiene fixes (ROADMAP/CHANGELOG/CLAUDE.md/README + in-code `@doc`/`@spec`), auto-resolves `discuss-design` via Claude+Codex dialogue (convergence applies, divergence drops to ROADMAP candidate), writes `.audit/<sha>.md` reports + commits as `audit(...)`. **Fully autonomous — zero user gates.** **Deferred/batched** — SessionStart hook (`check-unaudited-commits.sh`, ≥3 threshold) surfaces unaudited tail; manual `/staged-review:audit-status` for snapshot; manual `Skill(audit-review) <range>` to clear |

**Task-driver plugin** (3 skills):

| Skill | Description |
|-------|-------------|
| task-driver | Roadmap-driven task execution — select by efficiency, implement, update all docs |
| rmap | The `rmap` roadmap substrate — `roadmap/tasks.toml` is canonical, `ROADMAP.md` is rendered output; command surface by intent, D/B/U mapping, status/marker vocabulary, migration procedure for hand-edited roadmaps |
| task-writing | How to write a task's `body` as a prompt — the 5-question pre-creation gate (anchor, baseline-first, one-session=one-task, milestone-fit, no-hedging), over-specified-vs-prompt examples, `rmap new --from-stdin` field set |

**Cloud-delegation plugin** (8 skills):

The Linear-as-queue + cloud-agent delegation workflow is split into four composable skills along a substrate/layer axis, plus a thin hub index. `linear-queue` is standalone — usable without cloud agents at all.

| Skill | Description |
|-------|-------------|
| linear-queue | Substrate — Linear MCP setup, workspace shape, issue-body-as-prompt template, status transitions, self-authored worktree flow, cross-repo coordination, ROADMAP-fallback. **Standalone** — usable without cloud agents |
| agent-dispatch | Dispatch layer — push self-contained tasks to cloud agents (Codex, Cursor): delegation flows, per-agent eligibility, plan-shaped issue specs, batch sizing, pre-flight conflict detection |
| agent-pr-review | Review layer — review and land cloud-agent PRs: polling, comment-fetch, review tiering, push-back-vs-fix-locally matrix, wake-mention discipline |
| flow-review | Merge-train mode for 2+ open cloud-agent PRs — dependency-sort, rebase cascade, per-PR auto-merge |
| linear-workflow | Hub index — points to the four skills above; use it to find which skill owns a concern |
| cloud-agent-environments | Cloud-agent env reference — what each cloud agent can/can't reach (hex.pm, mix tasks, Tidewave, HTTP), runtime gotchas, AGENTS.md generation workflow |
| sprite-claude-code | Operational reference for Fly Sprite-hosted Claude Code as a third cloud-delegation target |
| delegation-rules | The five hard rules of delegation flows — don't-steal-`[CX]`/`[CSR]`-tasks, GH-native auto-merge (never synchronous `gh pr merge`), default-DO Linear/PR comments, never-push-to-`codex/*`, one-shot `cursor/*` force-push scope |

**Dev-lifecycle plugin** (2 skills):

| Skill | Description |
|-------|-------------|
| dev-lifecycle | Canonical five-phase chain reference — answers "which phase am I in?", "which skill owns this?", "what's the handoff?". Pure documentation |
| workflow-philosophy | Language-agnostic multi-session workflow principles — session-per-phase, evaluator separation, staged-but-uncommitted implementer/reviewer handoff, batched execution with `/compact` STOP checkpoints, acceptance-criteria writing, verification-before-completion |

**Portfolio-strategy plugin** (1 skill):

| Skill | Description |
|-------|-------------|
| portfolio-strategy | Power-law portfolio rule for cross-repo decisions — start/continue/kill a project, where to spend attention. NOT for within-project prioritization (use roadmap-planning) |

**Skill Composition**: Skills are single-purpose and composed by agents/commands. `usage-rules` provides conventions (how to use correctly), `hex-docs-search` provides API docs (what's available). Agents can invoke both for comprehensive guidance.

## Development Commands

### Installing from GitHub (Recommended)

```bash
# From Claude Code
/plugin marketplace add ZenHive/claude-marketplace-elixir
/plugin install elixir@deltahedge
```

**Note**: Local directory marketplace loading (`/plugin marketplace add /path/to/dir`) has known bugs with cache/registry sync. Always use the GitHub format for reliable installation.

### Validation

After making changes to marketplace or plugin JSON files, validate structure:
```bash
# Check marketplace.json is valid JSON
cat .claude-plugin/marketplace.json | jq .

# Check plugin.json is valid JSON
cat plugins/elixir/.claude-plugin/plugin.json | jq .

# Check hooks.json is valid JSON
cat plugins/elixir/hooks/hooks.json | jq .
```

### Testing Plugin Hooks

The repository includes an automated test suite for plugin hooks:

```bash
# Run all plugin tests
./test/run-all-tests.sh

# Run tests for a specific plugin
./test/plugins/elixir/test-elixir-hooks.sh

# Via Claude Code slash command
/qa test                   # All plugins
/qa test elixir            # Specific plugin
```

**Test Framework**:
- `test/test-hook.sh` - Base testing utilities
- `test/run-all-tests.sh` - Main test runner
- `test/plugins/*/test-*-hooks.sh` - Plugin-specific test suites

**What the tests verify**:
- Hook exit codes (0 for success) and JSON permissionDecision for blocking
- Hook output patterns and JSON structure
- File type filtering (.ex, .exs, non-Elixir)
- Command filtering (git commit vs other commands)
- Blocking vs non-blocking behavior

See `test/README.md` for detailed documentation.

## Important Conventions

### Marketplace Path Configuration

**Source paths** in `marketplace.json` must:
- Start with `./` (required by schema validation)
- Be relative to the **marketplace root directory** (where `.claude-plugin/` is located)

```json
{
  "plugins": [
    {
      "name": "elixir",
      "source": "./plugins/elixir"  // Correct: relative to repo root
    }
  ]
}
```

**Common mistakes**:
- `"source": "./elixir"` - Wrong: looks for `/repo-root/elixir` instead of `/repo-root/plugins/elixir`
- `"source": "../plugins/core"` - Wrong: must start with `./`
- Adding `"hooks": "./hooks/hooks.json"` to plugin.json - Wrong: causes duplicate hook error (hooks.json is loaded automatically)

### Troubleshooting Plugin Errors

**"Plugin 'X' not found in marketplace 'Y'"**
1. Check that `source` paths in marketplace.json start with `./` and include the full path (e.g., `./plugins/elixir`)
2. Run the cleanup script and re-add from GitHub:
   ```bash
   ./scripts/clear-cache.sh
   # Restart Claude Code, then:
   /plugin marketplace add ZenHive/claude-marketplace-elixir
   /plugin install elixir@deltahedge
   ```

**"Plugin directory not found at path"**
- The `source` path resolves from the marketplace root (where `.claude-plugin/` is located)
- Verify the path exists: `ls -la /path/to/marketplace/<source-path>`
- `pluginRoot` field is metadata only - it does NOT affect source path resolution

**"Duplicate hooks file detected"**
- Remove the `hooks` field from plugin.json - `hooks/hooks.json` is loaded automatically
- Only use the `hooks` field for additional hook files beyond the standard location

**"Invalid schema: source must start with ./"**
- All source paths must begin with `./` (not `../` or absolute paths)
- Correct: `"source": "./plugins/elixir"`
- Wrong: `"source": "../plugins/elixir"` or `"source": "/abs/path"`

**Stale plugin references in settings**
- Check `~/.claude/settings.json` for orphaned `enabledPlugins` entries
- Remove entries referencing non-existent marketplaces
- Restart Claude Code after editing settings

**Changes not taking effect**
1. Run cleanup script: `./scripts/clear-cache.sh`
2. Restart Claude Code completely (close and reopen)
3. Re-add marketplace: `/plugin marketplace add ZenHive/claude-marketplace-elixir`
4. Install plugins: `/plugin install elixir@deltahedge`

### Marketplace Namespace

The marketplace uses the namespace `deltahedge` (defined in `marketplace.json`). Plugins are referenced as `<plugin-name>@deltahedge` (e.g., `elixir@deltahedge`).

### Hook Matcher Patterns

- `PostToolUse` matcher `"Edit|Write|MultiEdit"` triggers on any file modification tool
- `PreToolUse` matcher `"Bash"` triggers before bash commands execute
- Hook commands extract tool parameters using `jq -r '.tool_input.<field>'`

### Version Management

Plugin and marketplace versions are **independent** and version for different reasons:

**Plugin Version** (`plugins/*/. claude-plugin/plugin.json`):
- Bump when plugin functionality changes (hooks, scripts, commands, agents, bug fixes, docs)
- Use semantic versioning: major.minor.patch
- Each plugin versions independently based on its own changes

**Marketplace Version** (`.claude-plugin/marketplace.json`):
- Bump ONLY when catalog structure changes (add/remove plugins, marketplace metadata, reorganization)
- NOT when individual plugin versions change
- NOT when plugin functionality changes

This follows standard package registry practices (npm, PyPI, Homebrew) where the registry version is independent of package versions. Think of it like a bookstore: book editions (plugin versions) change independently of catalog editions (marketplace version).

## File Modification Guidelines

**After completing any task** — `SKILLS.md`, `README.md`, and `CLAUDE.md` all carry skill/plugin catalogs that drift if not updated together. A task is not complete until all three agree:
1. `SKILLS.md` (repo root) — agent-facing skill catalog. If the task added/removed/renamed a skill or changed its description, update the catalog row, the task→skill quick-routing table, and the skill count.
2. `README.md` — human-facing landing page. Update the plugin summary table, skill count, and install surface if the plugin set or counts changed.
3. `CLAUDE.md` (this file) — update the `### Skills` tables, the dir-tree, and the total count if marketplace structure changed.
4. `CHANGELOG.md` — add a `[Unreleased]` entry.

For a task that touches no skills or plugins this is a no-op — but still verify the three catalogs, don't assume.

**When editing JSON files**: Always maintain valid JSON structure. Use `jq` to validate after changes.

**When adding new plugins**:
1. Create plugin directory under `plugins/`
2. Add `.claude-plugin/plugin.json` with metadata inside the plugin directory
3. Add plugin to `plugins` array in `.claude-plugin/marketplace.json`
4. Create `README.md` documenting plugin features
5. Create test directory under `test/plugins/<plugin-name>/`

**When modifying hooks**:
1. Edit `plugins/<plugin-name>/hooks/hooks.json`
2. Update hook script in `plugins/<plugin-name>/scripts/` if needed
3. Run automated tests: `./test/plugins/<plugin-name>/test-<plugin-name>-hooks.sh`
4. Update plugin README.md to document hook behavior
5. Consider hook execution time and blocking behavior

## Hook Script Best Practices

**Exit Codes**:
- `0` - Success (allows operation to continue or suppresses output)
- `1` - Error (script failure)

**JSON Output Patterns**:
```bash
# Non-blocking with context (PostToolUse)
jq -n --arg context "$OUTPUT" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $context
  }
}'

# Suppress output when not relevant
jq -n '{"suppressOutput": true}'

# Blocking (PreToolUse) - JSON permissionDecision with exit 0
jq -n \
  --arg reason "$ERROR_MSG" \
  --arg msg "Commit blocked: validation failed" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    },
    "systemMessage": $msg
  }'
exit 0
```

**Common Patterns**:
- Project detection: Find Mix project root by traversing upward from file/directory
- Dependency detection: Use `grep -qE '\{:dependency_name' mix.exs` to check for specific dependency
- File filtering: Check file extensions with `grep -qE '\.(ex|exs)$'`
- Command filtering: Check for specific commands like `grep -q 'git commit'`
- Exit code handling: Check if variable is empty with `[[ -z "$VAR" ]]`, not `$?` after command substitution

## TodoWrite Best Practices

When using TodoWrite in slash commands and workflows:

**When to use**:
- Multi-step tasks with 3+ discrete actions
- Complex workflows requiring progress tracking
- User-requested lists of tasks
- Immediately when starting a complex command execution

**Required fields**:
- `content`: Imperative form describing what needs to be done (e.g., "Run tests")
- `activeForm`: Present continuous form shown during execution (e.g., "Running tests")
- `status`: One of `pending`, `in_progress`, `completed`

**Best practices**:
- Create todos at the START of command execution, not after
- Mark ONE task as `in_progress` at a time
- Mark tasks as `completed` IMMEDIATELY after finishing (don't batch)
- Break complex tasks into specific, actionable items
- Use clear, descriptive task names
- Update status in real-time as work progresses

**Example pattern**:
```javascript
[
  {"content": "Parse user input", "status": "completed", "activeForm": "Parsing user input"},
  {"content": "Research existing patterns", "status": "in_progress", "activeForm": "Researching existing patterns"},
  {"content": "Generate implementation plan", "status": "pending", "activeForm": "Generating implementation plan"}
]
```

**Elixir-workflows Plugin**: The `elixir-workflows` plugin can generate customized workflow commands for other Elixir projects via `/elixir-workflows:workflow-generator`. Templates use `{{DOCS_LOCATION}}` variable (default: `.thoughts`) for configurability.

### Five-Phase Development Lifecycle

```
task-driver(1) → worktree(2) → bots(3) → merge(4: GH-native gh pr merge --auto) → audit-review(5)
```

| Phase | Skill / Actor |
|---|---|
| 1 — Plan-and-File | `task-driver:task-driver` (Plan-and-File mode) |
| 2 — Implement | implementer session + `staged-review:code-review` (pre-commit sub-phase) |
| 3 — Bots | external (CodeRabbit, Copilot, Codex's GitHub bot) |
| 4 — Merge | GitHub-native `gh pr merge <N> --auto --squash --delete-branch` wired at PR-open; GitHub holds until required checks pass + no `requested-changes` + no `[BLOCK-MERGE]` label |
| 5 — Post-merge audit | `staged-review:audit-review` (deferred — SessionStart hook surfaces unaudited tail at ≥3) |

Canonical reference (full phase descriptions, Linear-status transitions, handoff rules, end-to-end narrative): **`Skill(dev-lifecycle)`** or `~/.claude/includes/dev-lifecycle.md` / `plugins/dev-lifecycle/skills/dev-lifecycle/SKILL.md`. The chain is language-agnostic and composes only the already-language-agnostic `task-driver`, `staged-review`, and `cloud-delegation` plugins. Auto-merge preconditions: `delegation-rules.md` § "DON'T AUTO-MERGE PRS". Worktree scoping: `worktree-workflow.md`.

## Plugin Development Tools

When creating or modifying plugins, hooks, skills, or agents in this marketplace, use these tools from the `plugin-dev` and `hookify` plugins:

### plugin-dev Skills (Documentation & Guidance)

| Skill | When to Use |
|-------|-------------|
| `/plugin-dev:plugin-structure` | Plugin directory layout, manifest configuration, component organization |
| `/plugin-dev:hook-development` | Creating hooks (PreToolUse, PostToolUse, Stop, SessionStart, etc.) |
| `/plugin-dev:command-development` | Slash command structure, YAML frontmatter, dynamic arguments |
| `/plugin-dev:skill-development` | Skill structure, progressive disclosure, best practices |
| `/plugin-dev:agent-development` | Agent frontmatter, system prompts, triggering conditions |
| `/plugin-dev:mcp-integration` | MCP server integration, .mcp.json configuration |
| `/plugin-dev:plugin-settings` | Plugin configuration via .local.md files |

### plugin-dev Workflows & Validation

| Tool | Purpose |
|------|---------|
| `/plugin-dev:create-plugin` | Guided end-to-end plugin creation workflow |
| `plugin-dev:plugin-validator` (agent) | Validates plugin structure and plugin.json schema |
| `plugin-dev:skill-reviewer` (agent) | Reviews skill quality and best practices |
| `plugin-dev:agent-creator` (agent) | Creates autonomous agents for plugins |

### hookify Tools (Hook Generation)

| Tool | Purpose |
|------|---------|
| `/hookify:hookify` | Create hooks from conversation analysis or explicit instructions |
| `/hookify:writing-rules` | Guidance on hookify rule syntax and patterns |
| `/hookify:list` | List all configured hookify rules |
| `/hookify:configure` | Enable or disable hookify rules interactively |
| `/hookify:help` | Get help with the hookify plugin |
| `hookify:conversation-analyzer` (agent) | Analyzes conversations to find behaviors worth preventing |

### Recommended Workflow for Plugin Development

1. **Start**: Run `/plugin-dev:create-plugin` for guided scaffolding
2. **Learn patterns**: Use `/plugin-dev:hook-development`, `/plugin-dev:skill-development`, etc. for specific component guidance
3. **Validate**: Use `plugin-dev:plugin-validator` agent to check structure
4. **Review**: Use `plugin-dev:skill-reviewer` agent to review skill quality
5. **Create hooks from behavior**: Use `/hookify:hookify` to generate hooks from unwanted behaviors

## Git Commit Configuration

**Configured**: 2025-10-28

### Commit Message Format

**Format**: imperative-mood

#### Imperative Mood Template
```
<description>
```
Start with imperative verb: Add, Update, Fix, Remove, etc.

