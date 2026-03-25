---
name: meta-development
description: >-
  Elixir meta-development patterns — macros, code generators, DSLs.
  This skill should be used when the user asks to "write a macro",
  "create a DSL", "build a code generator", "use @before_compile",
  "generate modules at compile time", "module attribute accumulation",
  "quote unquote patterns", or is working on projects where the tool
  that builds things IS the product (extractors, ETL pipelines,
  schema-to-code tools, template systems).
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/meta-development.md — do not edit manually -->

## Meta-Development Philosophy

**When the tool that builds things IS the product.**

This applies to: macros, DSLs, code generators, template systems, extractors, ETL pipelines, API client generators, schema-to-code tools.

### Scope

WHAT THIS COVERS:
  - Macro programming patterns (quote/unquote, @before_compile, __using__/1)
  - Code generation architecture (compile-time, Mix tasks, runtime)
  - DSL design (declarative APIs, module attribute accumulation, escape hatches)
  - Meta-development philosophy ("solve for N, not 1")

WHAT THIS DOES NOT COVER:
  - Simple function abstractions (just write functions)
  - API client generation specifically (→ api-integration.md)
  - Runtime metaprogramming only (Protocol, Behaviour — standard Elixir)

### Core Principle: Solve for N, Not 1

The goal is solving the **meta-problem once** rather than individual problems N times.

Before writing instance-specific code, ask:
> "Could the generator/extractor/macro do this for all N instances at once?"

If yes → extend the meta-layer, not the instance.

### Anti-Patterns in Meta-Development

#### 1. Premature Data Filtering
**Trap**: "We only need X for the immediate problem"
**Rule**: Capture/extract EVERYTHING. Let consumers filter. Storage is cheap; missing data is expensive.

#### 2. Solving Instances Instead of the Meta-Problem
**Trap**: "Let me fix this for [specific case]"
**Rule**: If code mentions a specific instance by name, it's probably wrong. Parameterize the generator.

#### 3. Artificial Scope Limits on Infrastructure
**Trap**: "Let's start with just [subset], add [rest] later"
**Rule**: If the source supports N variants, your tool should too from the start.

#### 4. Trusting Specs Over Runtime Behavior
**Trap**: Reading types/schemas/docs to understand what something does.
**Rule**: Observe what actually happens. Intercept real calls. Specs lie, runtime doesn't.

#### 5. Gravitational Pull of Existing Code
**Trap**: Extending existing classification patterns (e.g., `pattern_from_ast/1 → :hmac_sha256_query`) instead of questioning whether those patterns match the new data source.
**Rule**: Old code shapes new code, even when the old code is wrong. When switching data sources (e.g., JS extraction → Go AST), delete and rebuild rather than adapt. Fresh instances that see existing atoms/patterns will naturally extend them instead of asking "what does the data actually contain?" This is a design principle for AI-authored codebases — if you want fresh thinking, remove the old scaffolding.

### The Reframe Questions

1. "Am I solving for ONE instance, or for N?"
2. "Am I filtering based on what I THINK is needed?"
3. "Am I trusting docs/specs instead of runtime behavior?"
4. "Could the generator do this automatically?"

---

## Macro Decision Tree

```
Do you have 3+ similar definitions differing only in data?
├── NO → Write plain functions or use a Behaviour
└── YES → Can a simple helper function handle it?
    ├── YES → Use a helper function
    └── NO (need compile-time code generation) → Use a macro
        └── Is the pattern stable and well-understood?
            ├── YES → Build the macro DSL
            └── NO → Prove with 3-5 manual implementations first
```

## Generation Strategies

| Strategy | Best For | Strengths | Weaknesses |
|----------|----------|-----------|------------|
| **Compile-time macros** | DSLs, API clients, schema-driven code | Compile-time validation, zero runtime overhead | Harder to debug, compile time |
| **Mix tasks** | One-time scaffolding, human-maintained code | Readable, modifiable output | Files drift from spec |
| **Runtime generation** | Plugin systems, hot-loaded config | Dynamic, no recompile | No compile-time checks |

```
Will generated code be modified by humans?
├── YES → Mix Task (scaffold once, humans maintain)
└── NO → Data available at compile time?
    ├── YES → Compile-time macro
    └── NO → Runtime generation (Module.create)
```

---

## Core Macro Patterns

### Two-Stage Macro: `__using__/1` → `__generate__/2`

When `__using__` needs to load external data (specs, config) based on options:

```elixir
defmacro __using__(opts) do
  spec_id = Keyword.get(opts, :spec)
  quote do
    require MyGenerator
    MyGenerator.__generate__(unquote(spec_id))
  end
end

defmacro __generate__(spec_id) do
  spec = SpecLoader.load!(spec_id)  # Runs at compile time
  quote do
    @my_spec unquote(Macro.escape(spec))
    # ... generate functions from spec
  end
end
```

**Why two stages?** Direct `__using__` evaluates options at quote-time. The indirection lets `spec_id` be unquoted into the inner macro where it can drive compile-time data loading. ccxt_ex uses this: `use CCXT.Generator, spec: "bybit"` → loads spec → generates ~20 functions.

### Module Attribute Accumulation + `@before_compile`

The standard DSL pattern — accumulate declarations, generate code at end:

```elixir
defmacro __using__(_opts) do
  quote do
    import MyDSL
    @before_compile MyDSL
    Module.register_attribute(__MODULE__, :methods, accumulate: true)
  end
end

defmacro api_method(name, method, path) do
  quote do
    @methods {unquote(name), unquote(method), unquote(path)}
  end
end

defmacro __before_compile__(env) do
  methods = Module.get_attribute(env.module, :methods)
  for {name, method, path} <- methods do
    quote do
      def unquote(name)(), do: request(unquote(method), unquote(path))
    end
  end
end
```

### `Macro.escape` for Large Data

Embed complex data structures (maps, structs) in quoted code. Without it, maps/structs fail inside `quote` blocks.

```elixir
spec = load_spec!("bybit")  # Large map with endpoints, signing config, etc.
spec_lean = strip_dead_weight(spec)  # Remove extraction-only data before escaping

quote do
  @ccxt_spec unquote(Macro.escape(spec_lean))
end
```

**Strip dead weight before escaping**: ccxt_ex removes JS source code (~170KB per exchange) that's only needed during extraction, not at runtime.

### `@external_resource` for Recompilation

Track external files so modules recompile when data changes:

```elixir
for path <- spec_file_paths do
  @external_resource path
end
```

ccxt_ex tracks spec files so exchange modules rebuild when extracted specs are updated.

### `bind_quoted` — Prevent Re-evaluation

Without it, each `unquote(expr)` evaluates the expression again (side effects run twice):

```elixir
# BAD: expr evaluated twice
quote do: IO.puts(unquote(expr)); IO.puts(unquote(expr))

# GOOD: expr evaluated once
quote bind_quoted: [expr: expr] do: IO.puts(expr); IO.puts(expr)
```

**Rule**: Always use `bind_quoted` unless you need `unquote` in pattern position (function heads).

### Dynamic Arities with `Macro.generate_arguments/2`

```elixir
params = [:id, :name]
args = Macro.generate_arguments(length(params), __MODULE__)
quote do
  def unquote(fn_name)(unquote_splicing(args)), do: ...
end
```

### Compile-Time Validation

```elixir
defmacro endpoint(name, method, path) do
  unless method in [:get, :post, :put, :delete] do
    raise CompileError, description: "Invalid HTTP method: #{inspect(method)}"
  end
  quote do: @endpoints {unquote(name), unquote(method), unquote(path)}
end
```

---

## Architecture Patterns (from ccxt_ex)

### Function Head Dispatch Over Case

Route by pattern atom using function heads, not case statements:

```elixir
def sign(:hmac_sha256_query, request, credentials, config) do
  HmacSha256Query.sign(request, credentials, config)
end
def sign(:hmac_sha256_headers, request, credentials, config) do
  HmacSha256Headers.sign(request, credentials, config)
end
def sign(:custom, request, credentials, config) do
  Custom.sign(request, credentials, config)
end
```

ccxt_ex: 7 signing patterns as function heads cover 100+ exchanges. ccxt_client: 14 subscription patterns cover all exchange WebSocket protocols.

### Pattern-Based Architecture

Instead of N modules with unique code → N parameterized instances of M patterns:

| Project | Patterns (M) | Instances (N) | Ratio |
|---------|-------------|---------------|-------|
| ccxt_ex signing | 7 | 100+ exchanges | 1:14+ |
| ccxt_client subscriptions | 14 | 100+ exchanges | 1:7+ |
| ccxt_client auth | 8 | 100+ exchanges | 1:12+ |

**Always provide `:custom` escape hatch** for outliers (<5% of cases).

### Introspection Functions

Generate runtime-discoverable metadata for tooling and agents:

```elixir
# Generated per exchange module in ccxt_ex:
def __ccxt_spec__(), do: @ccxt_spec
def __ccxt_endpoints__(), do: @ccxt_spec.endpoints
def __ccxt_signing__(), do: @ccxt_spec.signing
def __ccxt_required_credentials__(), do: @ccxt_spec.required_credentials
# 14+ more introspection functions
```

Enables: "What parameters does `fetch_balance` need on Bybit?" → look up `__ccxt_spec__()`.

### Shared Dispatcher Pattern

Generated functions don't inline logic — they delegate to a shared dispatcher:

```elixir
# Generated for each endpoint:
def fetch_ticker(symbol, opts \\ []) do
  CCXT.Generator.Dispatch.call(__MODULE__, :fetch_ticker, params, opts, nil)
end
```

**Why?** 1 maintenance point instead of N. Dispatcher handles: param merging, path interpolation, HTTP execution, error handling. Functions are thin wrappers.

### Spec-Driven Generation Flow

```
Extract data (Node.js, API calls, source analysis)
    → Spec files (JSON/Elixir maps in priv/)
        → `use Generator, spec: "name"` loads spec at compile time
            → Generated module with typed, documented functions
```

New instance = new spec file, zero Elixir code.

---

## Debugging Macros

```elixir
# Inspect what a macro generates (in IEx/tests):
ast = quote do: MyDSL.endpoint(:get_users, :get, "/users")
ast |> Macro.expand_once(__ENV__) |> Macro.to_string() |> IO.puts()

# IO.inspect inside defmacro runs at COMPILE TIME
defmacro my_macro(expr) do
  IO.inspect(expr, label: "input AST")
  result = quote do: unquote(expr) + 1
  IO.inspect(result, label: "output AST")
  result
end
```

## Testing Macros

```elixir
# Test generated functions (preferred — test the API, not internals)
test "generated function exists and works" do
  assert function_exported?(TestModule, :test_endpoint, 0)
  assert {:ok, _} = TestModule.test_endpoint()
end

# Test compile-time validation
test "rejects invalid HTTP method" do
  assert_raise CompileError, ~r/Invalid HTTP method/, fn ->
    defmodule Bad do
      use MyDSL
      endpoint :bad, :invalid, "/bad"
    end
  end
end
```

## Common Pitfalls

1. **Forgetting `Macro.escape/1`** for maps/structs in `quote` blocks
2. **Not using `bind_quoted`** — causes double evaluation of side effects
3. **Over-using `var!/2`** — prefer returning values over injecting variables
4. **Not providing escape hatches** — users MUST be able to bypass the DSL
5. **Generating too much code** — keep generated functions thin, delegate to shared logic
6. **Debugging at runtime** when issue is compile-time — use `Macro.expand`

---

### When This Applies

| Project Type | Meta-Layer | Instances |
|--------------|------------|-----------|
| Code generator | The generator | Generated modules |
| Macro DSL | The macro definitions | Modules using the macros |
| API client builder | The spec extractor | Per-API clients |
| ETL pipeline | The extraction logic | Per-source handlers |
| Template system | The template engine | Rendered outputs |
| Schema-to-code | The schema processor | Generated types/validators |

### Relationship to Other Principles

- **Premature abstraction** still applies to *generated* code — keep it simple
- Meta-development inverts the normal advice: comprehensive extraction IS the simpler approach
- "Start small" applies to features, NOT to the scope of what the meta-layer handles
- Generated code should be straightforward (plain functions, direct calls) even if the meta-layer is sophisticated
