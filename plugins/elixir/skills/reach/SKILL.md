---
name: reach
description: Reach — Program Dependence Graph (PDG/SDG) for Elixir, Erlang, Gleam, and compiled BEAM. Use when doing static analysis, backward/forward slicing, taint analysis, dead-code detection, OTP state-machine analysis, impact analysis, or visualizing call graphs via `mix reach`. Also use for cross-language Elixir↔JavaScript graph stitching via Reach.Plugins.QuickBEAM, codebase-level analysis (coupling, hotspots, depth, effects, xref, boundaries, concurrency), or building Reach.Project SDGs across modules. Covers source vs BEAM frontends, dynamic dispatch capture, the `Reach.Plugin` behaviour, and the 1.7 frontend additions.
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/reach.md — do not edit manually -->

## Reach: Program Dependence Graph for Elixir

Builds PDG/SDG from Elixir, Erlang, Gleam, or compiled BEAM. Backward/forward slicing, taint analysis, independence checks, dead-code detection, OTP state-machine analysis, `mix reach` HTML viz.

**Min version: `{:reach, "~> 2.2"}`** (pin floor `~> 2.0.1` — `2.0.0` is uninstallable from Hex due to `ex_ast` dep-scope bug fixed in 2.0.1; use `~> 2.2` for the latest smell surface).

**2.0 (breaking) — Canonical CLI.** Five commands replace the 16 legacy tasks: `mix reach.map`, `reach.inspect TARGET`, `reach.trace`, `reach.check`, `reach.otp`. Legacy task names fail fast with migration hints (no analysis runs). New `.reach.exs` architecture policy file (`layers`, `deps[:forbidden]`, `source[:forbidden_modules]`/`forbidden_files`, `calls[:forbidden]`, `effects[:allowed]`, `boundaries[:public]`/`internal`/`internal_callers`, `risk[:changed]`, `candidates`, `smells`, `tests`) drives `mix reach.check --arch`/`--changed`/`--candidates`. Advisory refactoring candidates: `introduce_boundary`, `isolate_effects`, `extract_pure_region`, `break_cycle` — each with `confidence`, `actionability`, `proof`, and (for cycles) `representative_calls`. Large new smell-check surface: collection/idiom (`Enum.reverse |> hd`, `Enum.reverse ++ tail`, chained `String.replace`, `Map.keys |> Enum.map`, `List.to_tuple |> elem`, redundant `Enum.join("")`, anon-fn `.()` in pipes, …); pipeline waste (`Enum.reverse |> Enum.reverse`, `filter |> count`, `map |> count`, `filter |> filter`, `sort |> take/reverse/at`, `drop |> take`, …); loop antipatterns (`++`/`<>` inside loop O(n²), manual reduce min/max/sum/frequency); idiom mismatch (guard equality where pattern-match suffices, `Map.update` then `Map.get` on same var); repeated map shape detection; behaviour candidates; compile-time vs runtime config (`Application.get_env`/`fetch_env` in module attrs, `compile_env` inside runtime fns); ExAST-backed pattern smell DSL (`use Reach.Smell.PatternCheck`, `smell ~p[...]`, guarded via `from(~p[...]) |> where(...)`). Umbrella source scanning includes `apps/*/lib/**/*.ex`. Optional `:boxart` bumped to `~> 0.3.3` for Unicode-safe syntax highlighting. Taint-tracing dropped from ~130s → ~3s on Plausible (per-source reachability instead of per-pair recomputation). The **programmatic API** (`Reach.file_to_graph!`, `string_to_graph`, `module_to_graph`, `ast_to_graph`, `backward_slice`, `forward_slice`, `chop`, `taint_analysis`, `dead_code`, `Reach.Plugin` behaviour, `Reach.Project`, `Reach.Frontend.JavaScript`, `Reach.Plugins.QuickBEAM`) is **unchanged in 2.x** — only the CLI surface broke.

**2.0.1 — critical hotfix.** `ex_ast` was declared `only: [:dev, :test]`, which made Reach uninstallable from Hex (pattern smell checks `import ExAST` at compile time). Pin `~> 2.0.0` literally fails. Pin must be `~> 2.0.1`+; recommend `~> 2.2`. Also tightened the smell surface: 63% fewer findings on a 19-package Hex sample, all remaining verified true positives.

**2.1 — new smells.** `Enum.at`/`List.delete_at` inside loops (O(n²)); `Enum.count/1` (no predicate) → `length/1` (avoids protocol dispatch); `Map.put` with variable key + boolean value → `MapSet` (membership tracking); `Map.values |> Enum.all?/any?/find/filter/map` → iterate `{key, value}` pairs; `Enum.map → Enum.max/min/sum` (allocates intermediate list); `List.foldl/3` → `Enum.reduce/3`; `String.graphemes |> Enum.reverse |> Enum.join` → `String.reverse/1`; redundant negated guard (`when x != y` immediately after `when x == y`); destructure-then-reconstruct (`[a, b, c]` rebuilt as same list). Frontend crash fixes: `import Mod, only: :macros` (atom values), bare atoms in `with` clause lists, non-list `else`/handler clauses.

**2.2 — polish.** `length(list) == 0`/`0 == length(list)`/`length(list) > 0` → list pattern matching, `== []`, or `!= []`; identity `Enum.uniq_by(coll, fn x -> x end)` → `Enum.uniq/1`; identity `Enum.sort_by(coll, fn x -> x end)` → `Enum.sort/1`; small-literal `length/1` comparisons in guards. Regression coverage for bare literal `with` clauses (e.g. `true`).

**1.8 — OTP-aware analyzer.** `mix reach.otp` (now `mix reach.otp` in 2.x — name unchanged) gained: gen_statem support (both `:state_functions` and `:handle_event_function` modes, with initial states, transition graph, event types per state); dead GenServer reply detection (`GenServer.call` where the reply is discarded — candidates for `cast`); cross-process coupling (flags `GenServer.call`/`cast` where caller and callee share ETS tables or process-dictionary keys, conflict type `callee_writes` or `callee_reads_caller_write`); supervision tree extraction (resolves `Supervisor.start_link(children, opts)` child references). ~1000× speedup on the OTP analysis. Smell-detection false-positive fixes (cons `|`, string-interp `to_string`, unrelated `Enum.map`/`List.first` pairs).

**1.7 — JavaScript frontend + cross-language plugin.** `Reach.Frontend.JavaScript` parses JS/TS via QuickBEAM bytecode disasm into Reach IR. `Reach.Plugins.QuickBEAM` stitches Elixir ↔ JS through `QuickBEAM.eval`/`QuickBEAM.call` sites with edges `:js_eval`, `{:js_call, name}`, `:beam_call`. New `analyze_embedded/2` plugin callback. File I/O effects split (`File.read`/`stat`/`exists?` → `:read`; `File.write`/`cp`/`rm`/`mkdir` → `:write`). Dead-code false positives near-zero (fixed pre-existing `with do ... end` body translation bug).

**1.6 — unified target format.** `reach.slice`/`impact`/`deps`/`graph` (now `reach.trace`/`reach.inspect --impact`/`--deps`/`--graph` in 2.x) all accept both `Module.function/arity` and `file:line`. 100–500× faster function resolution.

**1.5 — codebase-scope analyses.** Seven project-level commands added (`coupling`, `hotspots`, `depth`, `effects`, `xref`, `boundaries`, `concurrency`) — all subcommands of `mix reach.map` in 2.x.

**Caveat:** `dead_code` false positives are near-zero in 1.7+ but not zero — treat output as hint material, not a worklist.

**Does NOT cover:** runtime execution (static only), type inference (→ Dialyzer), dep security audit (→ Sobelow, npm_ex audit).

### Two Frontends

Both capture dynamic dispatch. Remaining differences:

| | Source (`file_to_graph!`, `string_to_graph`) | BEAM (`module_to_graph`) |
|---|---|---|
| Dynamic dispatch (`fn_var.(args)`, `state.handler.(args)`) | Captured as `kind: :dynamic` (since 1.3) | Captured as `kind: :dynamic` |
| Macro-expanded code | Invisible | Visible |
| `use GenServer` generated callbacks | Invisible | Visible |
| Source spans | Always available | Always available (normalized in 1.3) |
| `Reach.Project` cross-module SDG | **Supported** | **Not supported** — `Reach.Project` is source-only |
| Scope | Single file or project glob | Single module |

**Use BEAM when:** you need macro expansion or `use GenServer`-generated callbacks. Otherwise source is faster, supports project-wide SDG, and handles dynamic dispatch correctly.

### Building a Graph

```elixir
graph = Reach.file_to_graph!("lib/my_module.ex")
{:ok, graph} = Reach.string_to_graph("def foo(x), do: x + 1")
{:ok, graph} = Reach.file_to_graph("src/my_module.erl")    # Erlang
{:ok, graph} = Reach.file_to_graph("src/app.gleam")        # Gleam (needs glance)
{:ok, graph} = Reach.ast_to_graph(ast)                     # pre-parsed
{:ok, graph} = Reach.module_to_graph(MyApp.Accounts)       # BEAM — macros + generated callbacks

# Whole project (source frontend only)
project = Reach.Project.from_mix_project()
project = Reach.Project.from_glob("lib/**/*.ex")

# 1.7+: JavaScript — returns IR nodes (NOT a graph), consumed by Reach.Plugins.QuickBEAM
{:ok, js_nodes} = Reach.Frontend.JavaScript.parse("function f(x) { return x + 1 }")
{:ok, js_nodes} = Reach.Frontend.JavaScript.parse_file("priv/handler.js")
```

### Structural Queries

```elixir
Reach.nodes(graph)
Reach.nodes(graph, type: :call, module: :gun, function: :ws_send)
Reach.nodes(graph, type: :call, kind: :dynamic)
Reach.nodes(graph, type: :function_def, name: :handle_info)

# node.type         :call | :function_def | :var | :match | :case | ...
# node.meta         %{module:, function:, arity:, kind: :remote | :local | :dynamic}
# node.source_span  %{file:, start_line:, ...}
# node.id           opaque handle for slice/taint
```

### Slicing

```elixir
Reach.backward_slice(graph, node.id)              # what affects this node?
Reach.forward_slice(graph, node.id)               # what does this node affect?
Reach.chop(graph, source_id, sink_id)             # all paths A→B
Reach.context_sensitive_slice(graph, node.id)     # Horwitz-Reps-Binkley interprocedural
Reach.Project.taint_analysis(project, ...)        # project-level (source)
```

### Taint Analysis

```elixir
# Single-graph — result: %{source:, sink:, path: [node_id], sanitized: bool}
results = Reach.taint_analysis(graph,
  sources: [type: :call, function: :params],
  sinks: [type: :call, module: System, function: :cmd],
  sanitizers: [type: :call, function: :sanitize]
)

# Cross-module (source frontend; dynamic-dispatch sinks reachable)
Reach.Project.taint_analysis(project,
  sources: [type: :call, function: :params],
  sinks: &(&1.type == :call and &1.meta[:kind] == :dynamic)
)
```

Source/sink/sanitizer specs: keyword list (matched against `node.type` + `node.meta`) or predicate `(node -> boolean)`.

### Independence / Reordering

```elixir
Reach.independent?(graph, a.id, b.id)                    # safe to reorder?
Reach.depends?(graph, id_a, id_b)
Reach.data_flows?(graph, source_id, sink_id)
Reach.passes_through?(graph, source_id, mid_id, sink_id)
Reach.controls?(graph, control_id, controlled_id)
Reach.canonical_order(graph, node_ids)                   # topo-sort
```

Two public GenServer client functions on the same PID correctly report `independent?: false` (they mutate shared server state).

### Effects

```elixir
Reach.pure?(node)
Reach.classify_effect(node)       # :pure | {:io, ...} | {:send, ...} | ...
Reach.Effects.classify(node)
Reach.Effects.effectful?(node, kind)
Reach.Effects.conflicting?(a, b)
```

Built-in classification covers Enum, Map, String, Process, :ets, :code, Node, System, 30+ more. **1.5** reclassifies many stdlib calls correctly (`Enum.each` → `:io`, `Application.get_env` → `:read`, `:atomics`/`:counters`/`:persistent_term` → `:read`/`:write`), adds Access/Calendar/Date/Time as pure, and infers effects of local functions via fixed-point iteration. On Elixir 1.19+ it reads the `ExCk` BEAM chunk for compiler-inferred type signatures (gracefully disabled on older Elixir).

**Plugin `classify_effect/1` callback (1.5):** plugins teach the classifier about framework calls. All 8 built-ins implement it — Phoenix assigns/route helpers → `:pure`, Ecto queries → `:pure`, Repo reads → `:read`, writes → `:write`, Oban `insert` → `:write`, GenStage/Jido signal dispatch → `:send`, OpenTelemetry spans → `:io`, Jason → `:pure`.

**Alias/import/field access (1.5):** `alias Plausible.Ingestion.Event; Event.build()` now resolves correctly (incl. `:as`, multi-alias `{}`). `import Ecto.Query` then bare `from(...)` resolves to `Ecto.Query.from` (honours `:only`/`:except`). `socket.assigns`, `conn.params`, `state.count` are tagged `kind: :field_access` (pure) instead of fake remote calls. Compile-time noise (`@doc`, `use`, `::`, `__aliases__`) is classified `:pure` instead of `:unknown`.

### Dead Code

```elixir
for node <- Reach.dead_code(graph) do
  IO.warn("#{node.source_span.start_line}: unused #{node.type}")
end
```

1.3 cut false positives ~91% on real codebases (Phoenix 628→58) via fixed-point alive expansion, branch-tail return tracing, guard exclusion, comprehension generator/filter exclusion, impure-module blocklist (Process, :code, :ets, Node, System, …), typespec exclusion, impure-call descendant marking. Still a hint source — verify before deleting.

### Canonical CLI (`mix reach.*`, 2.0+)

Five commands replace the 16 legacy tasks. `--format text` (default, colored), `json`, or `oneline`. ANSI auto-disables when piped. Analysis commands accept a positional path filter where applicable (e.g. `mix reach.map lib/my_app/`).

**`mix reach.map`** — project bird's-eye view.

```bash
mix reach.map                                # default: modules summary
mix reach.map --modules                      # inventory, OTP/LiveView detection
mix reach.map --coupling --sort instability  # afferent/efferent, Martin's instability, cycles
mix reach.map --coupling --orphans           # unreferenced modules
mix reach.map --hotspots                     # complexity × caller count (with clause breakdown)
mix reach.map --depth --top 20               # dominator-tree depth (control-flow nesting)
mix reach.map --effects                      # effect distribution + top unclassified calls
mix reach.map --boundaries --min 2           # functions with multiple distinct side effects
mix reach.map --data                         # cross-function data flow via SDG
```

**`mix reach.inspect TARGET`** — target-local view. `TARGET` accepts `Module.function/arity` or `file:line`.

```bash
mix reach.inspect MyApp.Accounts.register/2 --context
mix reach.inspect MyApp.Accounts.register/2 --deps        # direct callers, callee tree, shared writers
mix reach.inspect MyApp.Accounts.register/2 --impact      # transitive callers, risk
mix reach.inspect MyApp.Accounts.register/2 --data --variable user
mix reach.inspect MyApp.Accounts.register/2 --why MyApp.Auth.login/1
mix reach.inspect MyApp.Accounts.register/2 --candidates  # advisory refactoring (see below)
mix reach.inspect lib/my_app/accounts.ex:45 --graph
```

**`mix reach.trace`** — taint flow + slicing.

```bash
mix reach.trace --from conn.params --to Repo                        # taint
mix reach.trace --from conn.params --to System.cmd --all
mix reach.trace --variable token --in MyApp.Auth.login/2            # variable trace
mix reach.trace MyApp.Accounts.register/2                           # backward slice (default)
mix reach.trace lib/my_app/accounts.ex:45 --forward                 # forward slice
```

**`mix reach.check`** — CI / release-safety gates.

```bash
mix reach.check --arch                       # validate against .reach.exs policy
mix reach.check --changed --base main        # changed-risk report (callers, public-API touches, suggested tests)
mix reach.check --dead-code                  # unused pure expressions
mix reach.check --smells                     # the full smell surface (see below)
mix reach.check --candidates                 # advisory refactoring candidates
```

**`mix reach.otp`** — OTP / process analysis.

```bash
mix reach.otp                                # GenServer + gen_statem state machines, supervision trees,
                                             # ETS/process-dict coupling, dead replies, missing handlers
mix reach.otp MyApp.Worker                   # scope to one module
mix reach.otp --concurrency                  # Task.async/await, monitors, spawn/link, supervisor topology
mix reach.otp --format json
```

**Terminal rendering (`--graph`, requires `{:boxart, "~> 0.3.3"}`):**

```bash
mix reach.inspect MyApp.Server.handle_call/3 --graph        # CFG with highlighted source
mix reach.inspect MyApp.Server.handle_call/3 --graph --call-graph
mix reach.map --coupling --graph                            # module dependency graph
mix reach.map --depth --graph                               # CFG of deepest function
mix reach.map --effects --graph                             # effect distribution
mix reach.otp --graph                                       # GenServer state diagrams
```

Without boxart, `--graph` exits cleanly with a message asking you to add it. 0.3.3 is required for Unicode-safe syntax highlighting.

### Migration from 1.x

Legacy tasks fail fast in 2.x with the migration hint — they don't run analysis.

| 1.x                              | 2.x                                       |
|----------------------------------|-------------------------------------------|
| `mix reach.modules`              | `mix reach.map --modules`                 |
| `mix reach.coupling`             | `mix reach.map --coupling`                |
| `mix reach.hotspots`             | `mix reach.map --hotspots`                |
| `mix reach.depth`                | `mix reach.map --depth`                   |
| `mix reach.effects`              | `mix reach.map --effects`                 |
| `mix reach.boundaries`           | `mix reach.map --boundaries`              |
| `mix reach.xref`                 | `mix reach.map --data`                    |
| `mix reach.deps TARGET`          | `mix reach.inspect TARGET --deps`         |
| `mix reach.impact TARGET`        | `mix reach.inspect TARGET --impact`       |
| `mix reach.slice TARGET`         | `mix reach.trace TARGET`                  |
| `mix reach.flow ...`             | `mix reach.trace ...`                     |
| `mix reach.dead_code`            | `mix reach.check --dead-code`             |
| `mix reach.smell`                | `mix reach.check --smells`                |
| `mix reach.graph TARGET`         | `mix reach.inspect TARGET --graph`        |
| `mix reach.concurrency`          | `mix reach.otp --concurrency`             |

### `.reach.exs` Architecture Policy (2.0+)

Drives `mix reach.check --arch`/`--changed`/`--candidates`/`--smells`. The file evaluates to a keyword list. Patterns are module-name strings with `*` wildcards.

```elixir
# .reach.exs
[
  layers: [
    web: "MyAppWeb.*",
    domain: "MyApp.*",
    data: ["MyApp.Repo", "MyApp.Schemas.*"]
  ],
  deps: [forbidden: [{:domain, :web}, {:data, :web}]],
  source: [
    forbidden_modules: ["MyApp.Legacy.*"],
    forbidden_files: ["lib/my_app/legacy/**"]
  ],
  calls: [
    forbidden: [
      {"MyApp.Domain.*", ["IO.puts", "Jason.encode!"]},
      {"MyApp.Workers.*", ["System.cmd"], except: ["MyApp.Workers.Cleanup"]}
    ]
  ],
  effects: [allowed: [{"MyApp.Pure.*", [:pure, :unknown]}]],
  boundaries: [
    public: ["MyApp.Accounts"],
    internal: ["MyApp.Accounts.Internal.*"],
    internal_callers: [
      {"MyApp.Accounts.Internal.*", ["MyApp.Accounts", "MyApp.Accounts.*"]}
    ]
  ],
  risk: [
    changed: [
      many_direct_callers: 5,
      wide_transitive_callers: 10,
      branch_heavy: 8,
      high_risk_reason_count: 3
    ]
  ],
  candidates: [
    thresholds: [mixed_effect_count: 2, branchy_function_branches: 8, high_risk_direct_callers: 4],
    limits: [per_kind: 20, representative_calls: 10, representative_calls_per_edge: 3]
  ],
  clone_analysis: [provider: :ex_dna, min_mass: 30, min_similarity: 1.0, max_clones: 50],
  smells: [
    fixed_shape_map: [min_keys: 3, min_occurrences: 3, evidence_limit: 10],
    behaviour_candidate: [min_modules: 3, min_callbacks: 3, module_display_limit: 8, callback_display_limit: 8]
  ],
  tests: [hints: [{"lib/my_app/accounts/**", ["test/my_app/accounts_test.exs"]}]]
]
```

Start from `examples/reach.exs` in the Reach repo. Reach itself ships a root `.reach.exs` and gates CI on `mix reach.check --arch`.

### Smell Checks (cumulative through 2.2)

`mix reach.check --smells` covers (non-exhaustive):

- **Loop antipatterns** — `Enum.at`/`List.delete_at` in loops (O(n²)); `++`/`<>` inside loops; manual `Enum.reduce` min/max/sum/frequency
- **Pipeline waste** — `Enum.reverse |> Enum.reverse`, `filter |> count`, `map |> count`, `filter |> filter`, `sort |> take`/`reverse`/`at`, `drop |> take`, `take_while |> count`/`length`, `map |> Enum.join`
- **Collection idioms** — `Enum.reverse |> hd`, `Enum.reverse ++ tail`, `inspect |> String.starts_with?`, chained `String.replace`, `Map.keys |> Enum.map`, `List.to_tuple |> elem`, redundant `Enum.join("")`, negative `Enum.take`, `String.graphemes |> length`, `String.length == 1`, `Integer.to_string |> String.to_charlist`, anon-fn `.()` in pipes
- **Idiom mismatch** — `Enum.count/1` (no predicate) → `length/1`; `Map.values |> Enum.all?/any?/find/filter/map` → iterate `{k, v}`; `Enum.map → Enum.max/min/sum`; `List.foldl/3` → `Enum.reduce/3`; `String.graphemes |> Enum.reverse |> Enum.join` → `String.reverse/1`; guard equality where pattern match suffices; `Map.update` then `Map.get/fetch` on same var; `Map.put` w/ variable boolean key → `MapSet`
- **Length comparisons (2.2)** — `length(list) == 0`/`0 == length(list)`/`length(list) > 0` → pattern match or `== []`/`!= []`; small-literal `length/1` comparisons in guards
- **Identity callbacks (2.2)** — `Enum.uniq_by(coll, fn x -> x end)` → `Enum.uniq/1`; `Enum.sort_by(coll, fn x -> x end)` → `Enum.sort/1`
- **Map contracts** — same-variable atom/string fallback (`metadata["id"] || metadata[:id]`); repeated atom-key map literals with same shape (struct/contract candidate); fixed-shape map detection
- **Structural drift (clone-backed)** — return-contract drift, side-effect ordering drift, validation drift across similar code
- **Other** — redundant negated guards (`when x != y` after `when x == y`); destructure-then-reconstruct (`[a, b, c]` rebuilt as same list); behaviour-candidate detection (modules exposing the same public callback set); compile-time vs runtime config (`Application.get_env`/`fetch_env` in module attrs, `compile_env` inside runtime fns)

Custom pattern checks via the ExAST-backed DSL: `use Reach.Smell.PatternCheck`, `smell ~p[<source pattern>]`. Guarded patterns: `from(~p[...]) |> where(...)`. Pipes, operators, function calls, and module attributes all work with the `~p` sigil; pattern checks share a zipper cache across modules.

### Advisory Refactoring Candidates (2.0+)

`mix reach.check --candidates` and `mix reach.inspect TARGET --candidates` surface graph-backed suggestions:

- **`introduce_boundary`** — split a function with mixed effects into pure core + effectful shell
- **`isolate_effects`** — group side-effecting calls
- **`extract_pure_region`** — move a pure subexpression out of an effectful function
- **`break_cycle`** — suggest where to cut a module dependency cycle, with `representative_calls` evidence

Each candidate carries `confidence`, `actionability`, `proof`, and (for cycles) `representative_calls` — agents should treat them as suggestions, not automatic edits.

### HTML Visualization

```bash
mix reach lib/my_app/accounts.ex lib/my_app/auth.ex
# → reach_report/index.html (self-contained, offline)
```

Three tabs: Control Flow (CFG), Call Graph (cross-module), Data Flow (def→use chains). Graph data embedded as `window.graphData = {call_graph, control_flow, data_flow}`. `data_flow.taint_paths` slot exists but the CLI doesn't expose source/sink flags — use `mix reach.trace` for taint. Optional deps: `:jason`, `:makeup`, `:makeup_elixir`.

### Recipes

**Call sites of a remote function:**
```elixir
Reach.nodes(graph, type: :call, module: :gun, function: :ws_send)
|> Enum.map(&{&1.source_span.start_line, &1.meta.arity})
```

**What data flows into this call?**
```elixir
[target] = Reach.nodes(graph, type: :call, module: Repo, function: :insert)
Reach.backward_slice(graph, target.id) |> Enum.map(&Reach.node(graph, &1))
```

**Is the inbound-frame → handler path sanitized?**
```elixir
Reach.taint_analysis(graph,
  sources: [type: :call, module: MyApp.MessageHandler, function: :decode],
  sinks: &(&1.type == :call and &1.meta[:kind] == :dynamic),
  sanitizers: [[type: :call, module: Jason, function: :decode]]
) |> Enum.filter(&(not &1.sanitized))
# Use module_to_graph/2 if the handler is generated by `use GenServer`.
```

**Reorder two side-effecting calls?**
```elixir
Reach.independent?(graph, call_a.id, call_b.id)
```

### Tidewave Exploration

Graphs don't persist between `project_eval` calls — rebuild each query:
```elixir
graph = Reach.file_to_graph!("lib/my_module.ex")
Reach.nodes(graph, type: :function_def) |> length()
```

For many related queries in one IEx session, build once and persist via process dictionary or an Agent.

### Plugins (1.4+)

`Reach.Plugin` adds domain-specific edges (framework dispatch, message routing, pipeline topology) not visible to language-level analysis.

Built-ins auto-detect via `Code.ensure_loaded?/1`: `Reach.Plugins.Phoenix`, `Ecto`, `Oban`, `GenStage`, `Jido`, `OpenTelemetry`, and **`QuickBEAM`** (1.7+). They run when the host package is in the dep tree.

```elixir
Reach.string_to_graph!(source, plugins: [Reach.Plugins.Phoenix])
Reach.Project.from_mix_project(plugins: [Reach.Plugins.Ecto])
Reach.string_to_graph!(source, plugins: [])            # disable all
```

Custom skeleton:
```elixir
defmodule MyPlugin do
  @behaviour Reach.Plugin
  @impl true
  def analyze(all_nodes, _opts), do: []                 # [{from_id, to_id, label}, ...]
  @impl true
  def analyze_project(_modules_map, _all_nodes, _opts), do: []   # optional, cross-module

  # 1.7+: for plugins that splice additional nodes (e.g. embedded JS) into the host graph.
  # Return {new_nodes, new_edges} — nodes get merged into the IR before analysis queries.
  @impl true
  def analyze_embedded(_all_nodes, _opts), do: {[], []}

  # 1.5+: teach the effect classifier about framework calls
  @impl true
  def classify_effect(_node), do: nil                    # :pure | :read | :write | :io | :send | nil
end
```

### Reach.Plugins.QuickBEAM — Cross-Language Analysis (1.7+)

Stitches Elixir and JavaScript into one graph. Scans for `QuickBEAM.eval/2,3` and `QuickBEAM.call/3,4` callsites where the JS source is a **string literal**, parses it via `Reach.Frontend.JavaScript`, and adds cross-language edges:

| Edge label | From | To | Meaning |
|---|---|---|---|
| `:js_eval` | Elixir runtime-run callsite | JS function_def in the literal source | Defines a JS fn in the runtime |
| `{:js_call, name}` | Elixir `QuickBEAM.call(rt, name, ...)` | JS function_def with matching name | Invokes a previously-defined JS fn |
| `:beam_call` | JS `Beam.call("handler", ...)` site | Elixir fn registered in `QuickBEAM.start(handlers: %{...})` | JS calling back into Elixir |

Also classifies effects on `QuickBEAM.*`: the JS-runtime entrypoints (`eval`, `call`, `load_module`, `load_bytecode`, `send_message`, `start`, `stop`, `reset`) → `:io`; `set_global` → `:write`; `compile`/`disasm`/`globals`/`get_global`/`info`/`memory_usage`/`coverage` → `:read`. OXC AST ops (`parse`, `postwalk`, `patch_string`, `imports`, `format`, `rewrite_specifiers`) → `:pure`; other OXC → `:io`.

```elixir
# Auto-enabled if QuickBEAM is in deps
graph = Reach.file_to_graph!("lib/my_runner.ex")
Reach.nodes(graph) |> Enum.filter(&(&1.meta[:language] == :javascript))
```

Limitation: cross-language edges only form when the JS source is a **literal** at the callsite. Runtime-computed JS (e.g. sourced from a variable or `File.read!/1`) won't be stitched, since the plugin works by peeking at the literal AST node.

### Other 1.4 Public API

- `Reach.compiled_to_graph/2` — graph from `:beam_lib` chunks (alt to `module_to_graph/2`)
- `Reach.call_graph/1`, `function_graph/2` — derive subgraphs
- `Reach.control_deps/2`, `data_deps/2`, `neighbors/3` — direct dep queries
- `Reach.has_dependents?/2` — quick existence check
- `Reach.string_to_graph!/2` — bang variant
- `Reach.to_dot/1`, `to_graph/1` — export to GraphViz / `:digraph`
- `Reach.Project.from_sources/2` — build from `{path, source}` pairs (fixtures, piped code)
- `Reach.Project.summarize_dependency/1` — text summary of an edge

### Dependencies

```elixir
{:reach, "~> 2.2", only: [:dev, :test], runtime: false},
{:boxart, "~> 0.3.3", only: [:dev, :test], runtime: false}   # terminal --graph (2.0+ requires 0.3.3 for Unicode-safe rendering)
```

**Pin floor:** `~> 2.0.1`. Reach `2.0.0` is uninstallable from Hex (`ex_ast` was declared `only: [:dev, :test]` but pattern smell checks `import ExAST` at compile time — fixed in 2.0.1). Pin `~> 2.2` for the latest smell surface.

Pulls in `libgraph`. Optional: `jason`, `makeup`, `makeup_elixir`, `makeup_js` (HTML viz), `boxart` (terminal). For the JS frontend + cross-language plugin (1.7+), add `{:quickbeam, "~> 0.10.4"}` — the plugin activates automatically when QuickBEAM is in the dep tree.
