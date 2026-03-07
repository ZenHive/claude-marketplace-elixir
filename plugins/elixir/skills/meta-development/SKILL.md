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

# Elixir Meta-Development

Philosophy, patterns, and techniques for building tools that build things — macros, code generators, DSLs, extractors, ETL pipelines.

## Scope

WHAT THIS SKILL DOES:
  - Macro programming patterns (quote/unquote, @before_compile, __using__/1)
  - Code generation architecture (when and how to generate modules at compile time)
  - DSL design (declarative APIs, module attribute accumulation, escape hatches)
  - Meta-development philosophy ("solve for N, not 1")
  - Anti-patterns that undermine meta-development projects

WHAT THIS SKILL DOES NOT DO:
  - Simple function abstractions (just write functions)
  - API client generation specifically (-> elixir:api-consumer)
  - Runtime metaprogramming only (Protocol, Behaviour — standard Elixir)
  - Phoenix/Ecto internals (-> phoenix:phoenix-patterns)

## Core Principle: Solve for N, Not 1

The goal is solving the **meta-problem once** rather than individual problems N times.

Before writing instance-specific code, ask:
> "Could the generator/extractor/macro do this for all N instances at once?"

If yes -> extend the meta-layer, not the instance.

## Anti-Patterns in Meta-Development

These patterns feel right but undermine meta-development projects.

### 1. Premature Data Filtering

**The trap**: "We only need X for the immediate problem"

**The reality**: Filtering at capture time means re-running extraction when needs change. Storage is cheap. Missing data is expensive.

```
BAD:  Extract only fields "currently needed"
GOOD: Extract every field the source provides, let consumers filter
```

### 2. Solving Instances Instead of the Meta-Problem

**The trap**: "Let me fix this for [specific case]"

**The reality**: Every instance-specific fix is a missed opportunity to improve the generator.

```
BAD:  Hand-code special handling for InstanceA, InstanceB, InstanceC
GOOD: Extract the pattern, parameterize the generator
```

If code mentions a specific instance by name, it's probably wrong.

### 3. Artificial Scope Limits on Infrastructure

**The trap**: "Let's start with just [subset], add [rest] later"

**The reality**: When building generators/extractors, "start small" often means "create work for later." The meta-layer should handle ALL cases from the start.

```
BAD:  "We'll add support for TypeB later"
GOOD: Extract TypeA, TypeB, TypeC from the start — they're the same pattern
```

### 4. Trusting Specs Over Runtime Behavior

**The trap**: Reading types, schemas, or documentation to understand what something does.

**The reality**: Specs lie. Documentation gets stale. Only runtime behavior is truth.

```
BAD:  Parse the TypeScript types to understand the API
GOOD: Call the API, intercept the HTTP, record what actually happens
```

### The Reframe Questions

When feeling resistance to meta-development principles, ask:

1. "Am I solving for ONE instance, or for N?"
2. "Am I filtering based on what I THINK is needed?"
3. "Am I trusting docs/specs instead of runtime behavior?"
4. "Could the generator do this automatically?"

## When This Applies

| Project Type | Meta-Layer | Instances |
|--------------|------------|-----------|
| Code generator | The generator | Generated modules |
| Macro DSL | The macro definitions | Modules using the macros |
| API client builder | The spec extractor | Per-API clients |
| ETL pipeline | The extraction logic | Per-source handlers |
| Template system | The template engine | Rendered outputs |
| Schema-to-code | The schema processor | Generated types/validators |

## Elixir Macro Essentials

### When Macros ARE the Right Tool

- 3+ similar function definitions differing only in data
- Declarative DSLs (routes, schema fields, API endpoints)
- Compile-time validation catches errors before runtime
- The alternative is copy-paste with risk of inconsistency

### When Macros ARE NOT the Right Tool

- Only 1-2 use cases (just write functions)
- Runtime flexibility needed (use higher-order functions)
- Simple code reuse (use modules, behaviours, protocols)
- The macro would be harder to understand than the repetition

### Decision Tree

```
Do you have 3+ similar definitions differing only in data?
|
+-- NO -> Write plain functions or use a Behaviour
|
+-- YES -> Can a simple helper function handle it?
           |
           +-- YES -> Use a helper function
           |
           +-- NO (need compile-time code generation) -> Use a macro
               |
               +-- Is the pattern stable and well-understood?
                   |
                   +-- YES -> Build the macro DSL
                   +-- NO -> Prove with 3-5 manual implementations first
```

### Core Patterns (Quick Reference)

**`quote`/`unquote`** — Template code, inject values:
```elixir
quote do
  def unquote(name)(arg), do: process(arg, unquote(config))
end
```

**`bind_quoted`** — Prevent expression re-evaluation:
```elixir
quote bind_quoted: [name: name, path: path] do
  def api_call, do: request(name, path)
end
```

**`__using__/1`** — Setup when module does `use MyDSL`:
```elixir
defmacro __using__(_opts) do
  quote do
    import MyDSL
    @before_compile MyDSL
    Module.register_attribute(__MODULE__, :methods, accumulate: true)
  end
end
```

**`@before_compile`** — Generate functions from accumulated data:
```elixir
defmacro __before_compile__(env) do
  methods = Module.get_attribute(env.module, :methods)
  for {name, path} <- methods do
    quote do
      def unquote(name)(), do: request(unquote(path))
    end
  end
end
```

**Dynamic arities** with `Macro.generate_arguments/2`:
```elixir
params = [:id, :name]
args = Macro.generate_arguments(length(params), __MODULE__)
quote do
  def unquote(fn_name)(unquote_splicing(args)) do
    # args are bound positionally
  end
end
```

**Always provide escape hatches** — Users must bypass the DSL for edge cases:
```elixir
# DSL for common cases
api_method :get_user, :get, "/users/:id", [:id]

# Escape hatch for custom needs
def custom_endpoint(params) do
  MyLib.Client.request(:post, "/custom", params)
end
```

### Relationship to Other Principles

- **Premature abstraction** still applies to *generated* code — keep it simple
- Meta-development inverts the normal advice: comprehensive extraction IS the simpler approach
- "Start small" applies to features, NOT to the scope of what the meta-layer handles

## Additional Resources

### Reference Files

For detailed patterns and techniques, consult:
- **`references/macro-patterns.md`** — Complete macro patterns with real-world examples from Phoenix, Ecto, ExUnit; hygiene; debugging; testing macros
- **`references/code-generation.md`** — Code generation architecture; when to use macros vs Mix tasks vs runtime generation; the ccxt_ex case study

### Related Skills

- **`elixir:api-consumer`** — Specific application of macro DSLs for REST API clients
- **`elixir:usage-rules`** — Package-specific conventions that may affect macro design
