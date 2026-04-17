# Code Generation Patterns

Architecture patterns for generating Elixir code at scale — when to use macros, Mix tasks, or runtime generation.

## Generation Strategies

### 1. Compile-Time Macros (Primary Pattern)

Generate functions when the module compiles. Best for: DSLs, API clients, schema-driven code.

```elixir
defmodule MyAPI do
  use CCXT.Generator, spec: "bybit"
  # Generates ~20 functions at compile time
end
```

**Strengths**: Compile-time validation, documentation generation, zero runtime overhead
**Weaknesses**: Longer compile times, harder to debug, requires macro expertise

### 2. Mix Tasks (Code Scaffolding)

Generate source files that become part of the codebase. Best for: one-time scaffolding, code that humans will modify.

```elixir
# mix gen.api_client --spec openapi.json --output lib/my_api/
defmodule Mix.Tasks.Gen.ApiClient do
  use Mix.Task

  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [spec: :string, output: :string])
    spec = parse_spec(opts[:spec])

    for endpoint <- spec.endpoints do
      content = EEx.eval_string(template(), assigns: [endpoint: endpoint])
      File.write!(Path.join(opts[:output], "#{endpoint.name}.ex"), content)
    end
  end
end
```

**Strengths**: Generated code is readable, debuggable, modifiable
**Weaknesses**: Generated files can drift from spec, no compile-time validation

### 3. Runtime Code Generation

Generate modules dynamically at runtime. Best for: plugin systems, hot-loaded configurations.

```elixir
defmodule PluginLoader do
  def load_plugin(name, config) do
    module_name = Module.concat([MyApp.Plugins, Macro.camelize(name)])

    Module.create(module_name, quote do
      def run(input), do: process(input, unquote(Macro.escape(config)))
    end, Macro.Env.location(__ENV__))
  end
end
```

**Strengths**: Dynamic, no recompilation needed
**Weaknesses**: No compile-time checks, modules may not persist across restarts

### Decision: Which Strategy?

```
Will the generated code be modified by humans?
|
+-- YES -> Mix Task (scaffold once, humans maintain)
|
+-- NO -> Is the data source available at compile time?
          |
          +-- YES -> Compile-time macro (best validation + performance)
          |
          +-- NO -> Runtime generation (dynamic plugins, user configs)
```

## The ccxt_extract Case Study: 110 Modules from Specs

**Problem**: Supporting 100+ cryptocurrency exchanges, each with unique auth, endpoints, and quirks.

**Insight**: 95% of exchanges use variations of just 7 signing patterns. Don't write 110 modules — solve the meta-problem once.

**Architecture**:

```
1. EXTRACT: Node.js script analyzes CCXT source code
   → Produces JSON specs per exchange (signing, endpoints, capabilities)

2. GENERATE: `use CCXT.Generator, spec: "bybit"`
   → Reads JSON spec at compile time
   → Selects signing pattern (1 of 7)
   → Generates all endpoint functions with correct auth

3. PARAMETERIZE: 7 signing implementations cover 95%+ of exchanges
   → Configuration, not code, differentiates exchanges
   → New exchange = new JSON spec file, zero Elixir code
```

**Key decisions**:
- Extract specs from CCXT's 7 years of accumulated knowledge (don't re-discover)
- JSON specs as the data layer between extraction and generation
- Signing patterns as the abstraction boundary (not per-exchange modules)
- GitHub Actions to sync with upstream CCXT updates

**Result**: Built in 7 days instead of 7 years. Adding a new exchange is adding a JSON file.

## Macro DSL for Repetitive API Methods

When an API has 10+ similar endpoints differing only in name, HTTP method, path, and parameters:

```elixir
defmodule MyExchange do
  use ExchangeAPI

  # Each line generates a typed, documented function
  api_method :get_ticker,    :get,  "/api/v1/ticker",    [:symbol]
  api_method :get_orderbook, :get,  "/api/v1/depth",     [:symbol, :limit]
  api_method :place_order,   :post, "/api/v1/order",     [:symbol, :side, :quantity, :price]
  api_method :cancel_order,  :delete, "/api/v1/order",   [:symbol, :order_id]
end
```

Each `api_method` call accumulates in `@api_methods`. At `@before_compile`, the macro generates:
- The public function with correct arity
- `@spec` typespec
- `@doc` documentation with endpoint info
- Request building with path parameter interpolation
- Authentication (selected by signing pattern)

## ETL Pipeline Generators

For ETL systems where each source follows the same extract-transform-load pattern:

```elixir
defmodule ETL do
  defmacro source(name, opts) do
    quote do
      @sources {unquote(name), unquote(Macro.escape(opts))}
    end
  end

  defmacro __before_compile__(env) do
    sources = Module.get_attribute(env.module, :sources)

    for {name, opts} <- sources do
      extract_fn = :"extract_#{name}"
      transform_fn = :"transform_#{name}"
      load_fn = :"load_#{name}"

      quote do
        def unquote(extract_fn)() do
          ETL.Extractor.run(unquote(Macro.escape(opts)))
        end

        def unquote(transform_fn)(data) do
          ETL.Transformer.run(data, unquote(Macro.escape(opts)))
        end

        def unquote(load_fn)(data) do
          ETL.Loader.run(data, unquote(Macro.escape(opts)))
        end

        def pipeline_unquote(name)() do
          unquote(extract_fn)()
          |> unquote(transform_fn)()
          |> unquote(load_fn)()
        end
      end
    end
  end
end
```

## Schema-to-Code Patterns

Generate Elixir code from external schema definitions (JSON Schema, Protobuf, GraphQL):

```elixir
defmodule SchemaGen do
  defmacro from_json_schema(path) do
    schema = path |> File.read!() |> Jason.decode!()

    fields = for {name, spec} <- schema["properties"] do
      type = json_type_to_ecto(spec["type"])
      {String.to_atom(name), type}
    end

    quote do
      use Ecto.Schema

      embedded_schema do
        unquote(for {name, type} <- fields do
          quote do
            field unquote(name), unquote(type)
          end
        end)
      end
    end
  end
end
```

## Relationship to Other Principles

### Generated Code Should Be Simple

Premature abstraction still applies to the *generated* code. The meta-layer can be sophisticated, but what it produces should be straightforward:

```
META-LAYER (can be complex):
  Macro DSL, @before_compile, module attributes, compile-time validation

GENERATED CODE (should be simple):
  Plain functions, direct API calls, simple pattern matching
```

### "Start Small" Applies Differently

- **Features**: Start small, add as needed (normal advice)
- **Meta-layer scope**: Handle ALL variants from the start (inverted advice)

The meta-layer's job is completeness. Skipping variants creates technical debt that's harder to add later than to include upfront.

### Capture Everything, Filter Later

When extracting data from external sources (APIs, specs, codebases):
- Extract ALL available data into your intermediate format
- Let consumers decide what to use
- Adding new fields to the extractor is easy; re-running extraction for missed fields is expensive
