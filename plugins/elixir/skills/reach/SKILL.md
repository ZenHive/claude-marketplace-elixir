---
name: reach
description: Reach — Program Dependence Graph (PDG/SDG) for Elixir, Erlang, Gleam, and compiled BEAM. Use when doing static analysis, backward/forward slicing, taint analysis, dead-code detection, OTP state-machine analysis, impact analysis, or visualizing call graphs via `mix reach`. Also use for cross-language Elixir↔JavaScript graph stitching via Reach.Plugins.QuickBEAM, codebase-level analysis (coupling, hotspots, depth, effects, xref, boundaries, concurrency), or building Reach.Project SDGs across modules. Covers source vs BEAM frontends, dynamic dispatch capture, the `Reach.Plugin` behaviour, and the 1.7 frontend additions.
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/reach.md — do not edit manually -->

## Reach: Program Dependence Graph for Elixir

Builds PDG/SDG from Elixir, Erlang, Gleam, or compiled BEAM. Backward/forward slicing, taint analysis, independence checks, dead-code detection, OTP state-machine analysis, `mix reach` HTML viz.

**Min version: `{:reach, "~> 1.7"}`.** 1.7 adds a **JavaScript source frontend** (`Reach.Frontend.JavaScript` — parses JS/TS via QuickBEAM bytecode disasm into Reach IR) and the **`Reach.Plugins.QuickBEAM`** cross-language plugin that stitches Elixir ↔ JS through `QuickBEAM.eval`/`QuickBEAM.call` sites with edges `:js_eval`, `{:js_call, name}`, and `:beam_call`. 1.7 also introduces a new plugin callback `analyze_embedded/2` (for plugins that splice sub-graphs into the host graph), splits File I/O effects (`File.read`/`stat`/`exists?` → `:read`; `File.write`/`cp`/`rm`/`mkdir` → `:write`), and brings dead-code false positives to near-zero by fixing a pre-existing `with do ... end` body translation bug that was dropping entire `with` bodies from the IR. 1.6 unifies the target format across `reach.slice`, `reach.impact`, `reach.deps`, and `reach.graph` — all four accept both `Module.function/arity` and `file:line`. 1.6 also makes function resolution 100–500× faster and resolves calls with fewer args than the definition to functions with default args (`foo/1` matches `def foo(a, b \\ nil)`). 1.5 adds 7 codebase-level analysis commands (`coupling`, `hotspots`, `depth`, `effects`, `xref`, `boundaries`, `concurrency`). 1.4 added `mix reach.graph` + `--graph` flag and the public `Reach.Plugin` behaviour.

**Caveat:** `dead_code` false positives are near-zero in 1.7 but not zero — treat output as hint material, not a worklist.

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

### CLI Tools (mix reach.*)

16 mix tasks. `--format text` (default, colored), `json`, or `oneline` — ANSI auto-disables when piped. All analysis commands accept a positional path filter (e.g. `mix reach.hotspots lib/my_app/`).

**Function-scope (1.3+):**
```bash
mix reach.modules --sort complexity           # inventory, OTP/LiveView detection
mix reach.dead_code                           # unused pure expressions (parallel)

mix reach.deps   MyApp.Accounts.register/2    # direct callers, callee tree, shared writers
mix reach.impact MyApp.Accounts.register/2    # transitive callers, risk

mix reach.flow --from conn.params --to Repo   # taint analysis
mix reach.flow --variable user                # variable trace
mix reach.slice MyApp.Accounts.register/2     # 1.6+: MFA target accepted
mix reach.slice lib/my_app/accounts.ex:45     # backward slice at file:line
mix reach.slice --forward lib/my_app/accounts.ex:45

mix reach.otp                                 # GenServer state machines, ETS coupling, missing handlers
mix reach.smell                               # redundant traversals, duplicate computations
```

**Codebase-scope (1.5):**
```bash
mix reach.coupling                            # afferent/efferent coupling, Martin's instability, cycles
mix reach.coupling --orphans                  # unreferenced modules
mix reach.hotspots                            # functions ranked by complexity × caller count (with clause breakdown)
mix reach.depth                               # functions ranked by dominator tree depth (control flow nesting)
mix reach.effects                             # effect classification distribution + top unclassified calls
mix reach.xref                                # cross-function data flow via SDG (param/return/state/call edges)
mix reach.boundaries --min 2                  # functions with multiple distinct side effects
mix reach.concurrency                         # Task.async/await, monitors, spawn/link chains, supervisor topology
```

**Terminal rendering (1.4+, requires `{:boxart, "~> 0.3"}`):**
```bash
mix reach.graph MyApp.Server.handle_call/3            # CFG with highlighted source
mix reach.graph MyApp.Server.handle_call/3 --call-graph
mix reach.{deps,impact,modules,otp,slice} --graph     # mindmap / diagram per task
mix reach.coupling --graph                            # module dependency graph
mix reach.depth --graph                               # CFG of deepest function
mix reach.effects --graph                             # pie chart (boxart 0.3.2 fixed FP formatting noise)
mix reach.otp --graph                                 # GenServer state diagrams
```

Without boxart, `--graph` exits cleanly with "boxart is required. Add {:boxart, \"~> 0.3\"} to your deps."

### HTML Visualization

```bash
mix reach lib/my_app/accounts.ex lib/my_app/auth.ex
# → reach_report/index.html (self-contained, offline)
```

Three tabs: Control Flow (CFG), Call Graph (cross-module), Data Flow (def→use chains). Graph data embedded as `window.graphData = {call_graph, control_flow, data_flow}`. `data_flow.taint_paths` slot exists but the CLI doesn't expose source/sink flags — use `mix reach.flow` for taint. Optional deps: `:jason`, `:makeup`, `:makeup_elixir`.

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
{:reach, "~> 1.7", only: [:dev, :test], runtime: false},
{:boxart, "~> 0.3", only: [:dev, :test], runtime: false}   # terminal --graph (1.4+)
```

Pulls in `libgraph`. Optional: `jason`, `makeup`, `makeup_elixir` (HTML viz), `boxart` (terminal). For the JS frontend + cross-language plugin (1.7+), add `{:quickbeam, "~> 0.10.4"}` — the plugin activates automatically when QuickBEAM is in the dep tree.
