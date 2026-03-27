---
name: quickbeam
description: "QuickBEAM JavaScript runtime for the BEAM — run JS libraries, npm packages, and async code inside Elixir GenServers via Zig NIFs. ALWAYS use this skill when you need to execute JavaScript at runtime, load npm browser bundles, bridge Elixir and JS with handlers, manage JS runtime pools or lightweight contexts, or evaluate TypeScript on the BEAM. Covers start/eval/call lifecycle, correct browser global stub pattern (critical — the common pattern is wrong), handler pattern (Beam.call/Beam.callSync), Pool and ContextPool for concurrency, DOM access, and the define-then-call recipe. Use this even if you think you know QuickBEAM — it contains runtime-verified corrections."
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/quickbeam.md — do not edit manually -->

## QuickBEAM: JavaScript Runtime for the BEAM

Embeds QuickJS-NG as a Zig NIF. Each runtime is a GenServer with a persistent JavaScript context — run JS libraries, bridge Elixir and JS bidirectionally. No Node.js required.

### Scope

WHAT THIS COVERS:
  - Starting and managing JS runtimes (GenServer lifecycle)
  - Evaluating JS/TS code and calling JS functions
  - Setting/getting global variables and bridging Elixir<->JS
  - Handler pattern (JS calling Elixir functions)
  - Pool and ContextPool for concurrency
  - Loading npm browser bundles
  - Module loading and bytecode compilation
  - Memory limits and resource management

WHAT THIS DOES NOT COVER:
  - Static analysis of JS/TS source (use OXC for parsing, AST traversal)
  - Installing npm packages (use npm_ex: `mix npm.install`)
  - Frontend build pipelines (use Volt)

### API Reference

#### Lifecycle

```elixir
# Start a runtime (GenServer)
{:ok, rt} = QuickBEAM.start()

# With options
{:ok, rt} = QuickBEAM.start(
  name: MyApp.JSRuntime,       # register name
  script: "priv/js/app.ts",   # file to run at startup (auto-bundles imports)
  apis: :browser,              # :browser | :node | [:browser, :node] | false
  handlers: %{},               # Elixir functions callable from JS
  define: %{},                 # compile-time globals (JSON-encoded)
  memory_limit: 256_000_000,   # 256MB default
  max_stack_size: 4_000_000,   # 4MB default
  max_convert_depth: 32,       # nested structure depth limit
  max_convert_nodes: 10_000    # total nodes in conversion
)

# Stop and free resources
QuickBEAM.stop(rt)

# Reset to fresh context (clears all state)
QuickBEAM.reset(rt)

# Diagnostics
QuickBEAM.info(rt)
QuickBEAM.memory_usage(rt)     # => %{malloc_size: ..., memory_used_size: ..., obj_count: ..., ...}
QuickBEAM.globals(rt)          # list all global names
QuickBEAM.globals(rt, user_only: true)  # only user-defined globals
```

**API surfaces** — what each `:apis` option provides:
| Option | Provides | Does NOT provide |
|--------|----------|-----------------|
| `:browser` (default) | `fetch`, `document`, `crypto`, `WebSocket`, `URL`, `TextEncoder` | `self`, `window`, `process` |
| `:node` | `process`, `path`, `fs`, `os` | `fetch`, `document` |
| `[:browser, :node]` | Both sets | — |
| `false` | Bare QuickJS engine | Everything above |

Note: `:browser` does NOT define `self` or `window`. See "Loading npm Browser Bundles" below for the correct stub pattern.

#### Code Execution

```elixir
# Evaluate JS — supports top-level await
{:ok, 42} = QuickBEAM.eval(rt, "40 + 2")
{:ok, 42} = QuickBEAM.eval(rt, "await Promise.resolve(42)")

# With timeout (runtime remains usable after timeout)
{:error, %QuickBEAM.JSError{}} = QuickBEAM.eval(rt, "while(true){}", timeout: 1000)

# With vars — injected as globals, auto-cleaned up after execution (even on error)
{:ok, "QUICKBEAM"} = QuickBEAM.eval(rt, "name.toUpperCase()", vars: %{"name" => "quickbeam"})
{:ok, 40} = QuickBEAM.eval(rt, "items.map(i => i.price * i.qty).reduce((a, b) => a + b, 0)",
  vars: %{"items" => [%{"price" => 10, "qty" => 3}, %{"price" => 5, "qty" => 2}]})

# Evaluate TypeScript (transforms via OXC, then evaluates)
{:ok, 42} = QuickBEAM.eval_ts(rt, "const x: number = 42; x")

# Call a global JS function — auto-awaits promises
{:ok, 5} = QuickBEAM.call(rt, "add", [2, 3])
{:ok, result} = QuickBEAM.call(rt, "fetchData", [url], timeout: 10_000)
```

**`call/3,4` vs `eval/2,3`**: Prefer `call` when invoking functions — it passes arguments natively (no string interpolation needed) and auto-awaits Promises. Use `eval` for defining functions, running scripts, or when you need `:vars`.

#### Globals

```elixir
# Set a JS global from Elixir (native BEAM->JS conversion, not JSON)
QuickBEAM.set_global(rt, "config", %{"key" => "value"})
QuickBEAM.set_global(rt, "items", [1, 2, 3])

# Get a JS global back to Elixir — returns STRING-keyed maps (not atom-keyed)
{:ok, %{"key" => "value"}} = QuickBEAM.get_global(rt, "config")

# Inline objects from eval/call are also string-keyed
{:ok, %{"x" => 1, "y" => 2}} = QuickBEAM.eval(rt, "({x: 1, y: 2})")
```

**Key type difference**: OXC AST uses atom keys (`.type`, `.name`). QuickBEAM returns string keys (`"type"`, `"name"`). This matters when pattern matching on JS results.

#### Module Loading

```elixir
# Load ES module
QuickBEAM.load_module(rt, "utils", "export function add(a, b) { return a + b; }")

# Compile to bytecode (for reuse across runtimes)
{:ok, bytecode} = QuickBEAM.compile(rt, code)
QuickBEAM.load_bytecode(rt, bytecode)

# Disassemble bytecode for inspection
{:ok, bc} = QuickBEAM.disasm(bytecode)
# => %QuickBEAM.Bytecode{opcodes: [{0, :push_i32, 40}, ...], ...}
```

### Handlers: JS Calling Elixir

Define Elixir functions that JavaScript can invoke:

```elixir
{:ok, rt} = QuickBEAM.start(handlers: %{
  "fetchData" => fn [url] ->
    case Req.get(url) do
      {:ok, %{body: body}} -> body
      {:error, _} -> nil
    end
  end,
  "log" => fn [message] ->
    Logger.info("JS: #{message}")
    :ok
  end
})
```

JS invokes handlers two ways:
```javascript
// Synchronous — blocks JS until Elixir returns
const data = Beam.callSync("fetchData", "https://api.example.com");

// Asynchronous — returns a Promise
const data = await Beam.call("fetchData", "https://api.example.com");
```

**Handler arg format**: Arguments arrive as a flat list. `Beam.callSync("fn", "a", "b", "c")` -> handler receives `["a", "b", "c"]`.

### Loading npm Browser Bundles

Many npm packages ship browser-ready bundles. To load them into QuickBEAM:

```elixir
{:ok, rt} = QuickBEAM.start()

# Step 1: Stub browser globals the library expects
# IMPORTANT: self and window must BE globalThis, not just be defined.
# set_global with an atom value converts it to a string, NOT to globalThis.
QuickBEAM.eval(rt, "globalThis.self = globalThis; globalThis.window = globalThis")
QuickBEAM.set_global(rt, "navigator", %{"userAgent" => "QuickBEAM"})
QuickBEAM.set_global(rt, "location", %{"protocol" => "https:"})

# Step 2: Load the bundle
bundle = File.read!("node_modules/library/dist/library.browser.min.js")
{:ok, _} = QuickBEAM.call(rt, "eval", [bundle])

# Step 3: Use the library
{:ok, result} = QuickBEAM.eval(rt, "libraryName.doThing('input')")
```

### Returning Complex Data from JS

```elixir
# Simple values convert natively (no JSON needed)
{:ok, 42} = QuickBEAM.eval(rt, "40 + 2")
{:ok, "hello"} = QuickBEAM.eval(rt, "'hello'")
{:ok, [1, 2]} = QuickBEAM.eval(rt, "[1, 2]")

# Nested objects also convert, up to max_convert_depth (default: 32)
{:ok, %{"a" => 1, "nested" => %{"b" => 2}}} = QuickBEAM.eval(rt, "({a: 1, nested: {b: 2}})")

# Beyond max_convert_depth, leaves silently become nil
# For very deep structures, use JSON:
{:ok, json} = QuickBEAM.eval(rt, "JSON.stringify(deepObject)")
data = Jason.decode!(json)
```

### Pools and Contexts

#### Pool — Multiple Runtimes

```elixir
# Pool of full runtimes (~2MB each) for concurrent work
# Each runtime resets and re-initializes after use
{:ok, pool} = QuickBEAM.Pool.start_link(
  name: MyApp.JSPool,
  size: 10,               # number of runtimes
  init: fn rt ->           # called after creation AND after each reset
    QuickBEAM.eval(rt, File.read!("priv/js/app.js"))
  end,
  lazy: false              # start all runtimes immediately
)

# Check out, use, check back in (auto-reset after)
result = QuickBEAM.Pool.run(pool, fn rt ->
  {:ok, val} = QuickBEAM.call(rt, "process", [data])
  val
end)
# Pool.run default timeout: 5000ms
```

#### ContextPool — Lightweight Contexts

```elixir
# Contexts share runtime threads (~58-429KB each vs ~2MB for full runtimes)
{:ok, pool} = QuickBEAM.ContextPool.start_link(
  name: MyApp.CtxPool,
  size: System.schedulers_online()  # default
)

# Create a lightweight context — same API as QuickBEAM
{:ok, ctx} = QuickBEAM.Context.start_link(pool: MyApp.CtxPool)
{:ok, 42} = QuickBEAM.Context.eval(ctx, "40 + 2")
QuickBEAM.Context.set_global(ctx, "x", 42)
QuickBEAM.Context.call(ctx, "fn", [args])
QuickBEAM.Context.stop(ctx)
```

**When to use which**: Pool when each runtime needs heavy initialization (loading large bundles). ContextPool when you need many isolated JS environments cheaply (per-connection, per-request).

### DOM Access

QuickBEAM includes a native DOM implementation (with `:browser` APIs):

```elixir
{:ok, el} = QuickBEAM.dom_find(rt, "div.container")
{:ok, els} = QuickBEAM.dom_find_all(rt, "li.item")
{:ok, text} = QuickBEAM.dom_text(rt, "h1")
{:ok, href} = QuickBEAM.dom_attr(rt, "a.link", "href")
{:ok, html} = QuickBEAM.dom_html(rt)
```

### QuickBEAM.JS — TypeScript Toolchain

Mirrors OXC's API but runs inside a QuickBEAM runtime. Returns atom-keyed maps like OXC.

```elixir
{:ok, ast} = QuickBEAM.JS.parse(source, "file.ts")     # atom-keyed, same as OXC
{:ok, js}  = QuickBEAM.JS.transform(source, "file.ts")
{:ok, min} = QuickBEAM.JS.minify(source, "file.js")
{:ok, js}  = QuickBEAM.JS.bundle(files)
{:ok, js}  = QuickBEAM.JS.bundle_file("entry.ts")       # resolves imports from disk
names      = QuickBEAM.JS.collect(ast, fn
  %{type: "Identifier", name: n} -> {:keep, n}
  _ -> :skip
end)
```

Prefer OXC (Rust NIF) for performance. Use `QuickBEAM.JS` when you need `bundle_file` (disk-based resolution) or are already in a QuickBEAM context.

### Recipes

#### Define-then-Call Pattern

The standard pattern for using JS libraries from Elixir:

```elixir
{:ok, rt} = QuickBEAM.start()

# 1. Stub browser globals + load library
QuickBEAM.eval(rt, "globalThis.self = globalThis; globalThis.window = globalThis")
bundle = File.read!("node_modules/lib/dist/lib.browser.min.js")
QuickBEAM.call(rt, "eval", [bundle])

# 2. Define Elixir-friendly wrapper functions
QuickBEAM.eval(rt, """
  globalThis.doWork = async function(input) {
    const result = await lib.process(input);
    return JSON.stringify(result);
  }
""")

# 3. Call from Elixir (call/3 auto-awaits the Promise)
{:ok, json} = QuickBEAM.call(rt, "doWork", [input])
result = Jason.decode!(json)

# 4. Clean up
QuickBEAM.stop(rt)
```

#### Long-Lived Runtime in Supervision Tree

```elixir
defmodule MyApp.JSWorker do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def call_js(function, args), do: GenServer.call(__MODULE__, {:call, function, args})

  @impl true
  def init(_opts) do
    {:ok, rt} = QuickBEAM.start()
    QuickBEAM.eval(rt, "globalThis.self = globalThis; globalThis.window = globalThis")
    bundle = File.read!("node_modules/lib/dist/lib.browser.min.js")
    QuickBEAM.call(rt, "eval", [bundle])
    {:ok, %{runtime: rt}}
  end

  @impl true
  def handle_call({:call, function, args}, _from, %{runtime: rt} = state) do
    {:reply, QuickBEAM.call(rt, function, args), state}
  end

  @impl true
  def terminate(_reason, %{runtime: rt}), do: QuickBEAM.stop(rt)
end
```

#### Elixir-JS Bridge with Handlers

```elixir
{:ok, rt} = QuickBEAM.start(handlers: %{
  "httpGet" => fn [url] ->
    case Req.get(url) do
      {:ok, %{body: body}} when is_binary(body) -> body
      {:ok, %{body: body}} -> Jason.encode!(body)
      {:error, reason} -> {:error, inspect(reason)}
    end
  end,
  "readFile" => fn [path] -> File.read!(path) end
})

# JS can now call Elixir:
QuickBEAM.eval(rt, """
  const html = Beam.callSync("httpGet", "https://example.com");
  const config = JSON.parse(Beam.callSync("readFile", "config.json"));
""")
```

### Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Library globals missing after loading bundle | `self`/`window` are strings, not `globalThis` | Use JS assignment: `globalThis.self = globalThis` — never `set_global` with atoms for this |
| `ReferenceError: self is not defined` | Library expects browser globals | Stub `self`, `window`, `navigator`, `location` before loading |
| Deep nested object has `nil` leaves | Exceeds `max_convert_depth` (default: 32) | Return `JSON.stringify(result)` from JS, decode with Jason |
| Memory grows unbounded | Runtime accumulates state | Use `QuickBEAM.reset/1` or stop/restart |
| Timeout on large bundle load | Default no timeout | Pass `timeout: 30_000` to the loading call |
| String keys unexpected | QuickBEAM returns `%{"key" => val}` | Unlike OXC (atom keys), JS objects come back with string keys |

### DO NOT

1. **Don't use `set_global` to alias globalThis** — `set_global(rt, "self", :some_atom)` converts the atom to a string. To make `self` reference `globalThis`, use `QuickBEAM.eval(rt, "globalThis.self = globalThis")`.
2. **Don't interpolate Elixir values into JS strings** — Use `call/3` with args or `:vars` option. String interpolation risks injection and encoding bugs.
3. **Don't forget to stop runtimes** — Each runtime holds native memory. Always `QuickBEAM.stop/1` or supervise.
4. **Don't use QuickBEAM for static JS/TS analysis** — Use OXC; it's orders of magnitude faster for parsing and AST traversal.

### Performance

| Operation | Approximate Time | Notes |
|-----------|-----------------|-------|
| Start runtime | ~5ms | GenServer + QuickJS init |
| Load 5MB browser bundle | ~2s | One-time per runtime |
| Function call overhead | ~1ms | In-process NIF, no IPC |
| HTTP via fetch | ~140ms | Network-bound (~84ms native Elixir) |
| Context creation | ~1ms | Lightweight, shares runtime thread |
| Runtime memory | ~2MB | Full runtime with JS heap |
| Context memory | ~58-429KB | Depends on API surface loaded |
