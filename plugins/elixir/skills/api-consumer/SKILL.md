---
name: api-consumer
description: Macro-based API client generation for Elixir REST APIs. Use when building a client with 10+ similar endpoints — provides declarative method definitions with auto-generated functions. NOT for simple HTTP calls (use Req directly); this is for code-generated API wrappers with compile-time validation.
allowed-tools: Read, Bash, Grep, Glob
---

<!-- Auto-synced from ~/.claude/includes/api-integration.md — do not edit manually -->

## API Integration Guidelines

### Scope

WHAT THIS COVERS:
  - Decision framework for API client architecture (plain functions → helpers → macro DSL)
  - Declarative macro pattern for 10+ similar endpoints
  - Wrapping battle-tested libraries with thin Elixir wrappers
  - Sync checking and fixture generation from real APIs

WHAT THIS DOES NOT COVER:
  - Simple 1-3 endpoint HTTP calls (just use Req directly)
  - WebSocket or streaming APIs (→ zen-websocket.md)
  - Wrapping existing Elixir SDKs (use the SDK directly)
  - General macro patterns (→ meta-development.md)

### Decision Tree

```
Does a battle-tested library exist? (CCXT, Stripe SDK, AWS SDK, etc.)
├── YES → WRAP IT (thin Elixir wrapper, see Layered Abstraction below)
└── NO → BUILD YOUR OWN
    ├── 1-3 endpoints → Plain functions (just write them)
    ├── 4-9 endpoints → Shared helper module (auth, errors, retries)
    └── 10+ similar endpoints → Declarative macro DSL
```

### Always Prove First

**Never build abstractions speculatively.** Implement 3-5 endpoints manually first to:
- Understand the actual response structures
- Discover error patterns and edge cases
- Identify what's truly repetitive vs. what varies

**Repetition is cheaper than wrong abstraction.**

### Example Progression

```elixir
# Stage 1: Manual (1-3 endpoints) - Just write the functions
def get_user(id, api_key) do
  Req.get!("#{@base_url}/users/#{id}", headers: [{"Authorization", api_key}])
end

# Stage 2: Shared helpers (4-9 endpoints) - Extract common patterns
defp api_request(method, path, opts) do
  # Shared auth, error handling, retries
end

# Stage 3: DSL (10+ endpoints) - Only if patterns are truly uniform
defmodule MyAPI do
  use MyAPI.DSL
  api_method :get_user, :get, "/users/:id", [:id]
  api_method :create_user, :post, "/users", [], [:name, :email]
end
```

---

### Declarative Macro Pattern

**Rule: Define methods once, generate functions, docs, specs, and tests.**

#### Tuple Format (single source of truth)

```elixir
@api_methods [
  # {function_name, http_method, path_template, required_params, optional_params, fixture_type}
  {:get_account,  :get,    "/api/v1/account",        [],          [],                    :account},
  {:get_ticker,   :get,    "/api/v1/ticker/:symbol",  [:symbol],   [],                    :ticker},
  {:create_order, :post,   "/api/v1/orders",          [],          [symbol: nil, side: nil, type: nil], :order},
  {:get_orders,   :get,    "/api/v1/orders",           [],          [symbol: nil, limit: 100], :orders}
]
```

| Position | Type | Description |
|----------|------|-------------|
| 1 | atom | Function name |
| 2 | atom | HTTP method (`:get`, `:post`, `:delete`) |
| 3 | string | Path template with `:param` placeholders |
| 4 | list | Required parameters (positional args) |
| 5 | keyword | Optional parameters with defaults |
| 6 | atom | Fixture type for testing |

#### Compile-Time Generation

```elixir
# Expose methods for introspection (testing, sync checking)
def __methods__, do: @api_methods

for {name, http_method, path_template, required_params, optional_params, _fixture} <- @api_methods do
  path_params = Regex.scan(~r/:(\w+)/, path_template)
    |> Enum.map(fn [_, p] -> String.to_atom(p) end)
  all_required = path_params ++ (required_params -- path_params)
  args = Enum.map(all_required, &Macro.var(&1, __MODULE__))

  # Generate function with correct arity
  def unquote(name)(unquote_splicing(args), opts \\ []) do
    path = interpolate_path(unquote(path_template), unquote(path_params), binding())
    params = build_params(unquote(required_params -- path_params), binding(), opts, unquote(optional_params))
    do_request(unquote(http_method), path, params)
  end
end
```

#### Shared Dispatcher (ccxt_client pattern)

Generated functions don't inline logic — delegate to a shared dispatcher:

```elixir
def fetch_ticker(symbol, opts \\ []) do
  Dispatch.call(__MODULE__, :fetch_ticker, %{symbol: symbol}, opts, nil)
end
```

**Why?** 1 maintenance point, not N. Dispatcher handles: param merging, path interpolation, auth, HTTP execution, error handling.

---

### Layered Abstraction (Wrapping Libraries)

When a mature library exists, create a thin Elixir wrapper:

```
+----------------------------------------------------------+
|  Your Elixir App                                          |
+----------------------------------------------------------+
|  MyApp.ExchangeClient                                     |
|  - Elixir functions with specs                            |
|  - Explicit credential passing                            |
|  - {:ok, result} | {:error, reason} returns               |
+----------------------------------------------------------+
|  Bridge (Unix Socket, HTTP, NIF)                          |
+----------------------------------------------------------+
|  Battle-tested Library (CCXT, Stripe SDK, etc.)           |
+----------------------------------------------------------+
|  External API                                             |
+----------------------------------------------------------+
```

**Wrap when:** Library has >1000 stars + active maintenance, handles complex protocols, battle-tested in production.
**Build when:** No mature library exists, library abandoned, need full HTTP control, API is simple.

---

### Sync Checking (API Drift Detection)

Expose `__methods__/0` for introspection, then compare against upstream:

```elixir
# Mix task compares client methods vs upstream API
defmodule Mix.Tasks.Api.CheckMethods do
  def run(_args) do
    client_methods = MyAPI.__methods__() |> Enum.map(&elem(&1, 0)) |> MapSet.new()
    upstream_methods = fetch_upstream_methods()

    missing = MapSet.difference(upstream_methods, client_methods)
    extra = MapSet.difference(client_methods, upstream_methods)
    # Report missing/extra methods
  end
end
```

### Fixture Generation from Real APIs

Generate test fixtures from real API responses:

```elixir
# mix api.generate_fixtures --env testnet
defmodule Mix.Tasks.Api.GenerateFixtures do
  def run(args) do
    fixtures = MyAPI.__methods__()
      |> Enum.map(fn {name, _, _, _, _, fixture_type} ->
        {fixture_type, fetch_real_response(name)}
      end)
      |> Enum.into(%{})

    # Write as module: test/support/api_fixtures.ex
  end
end
```

### Compile-Time Test Generation

Generate tests per endpoint from method definitions:

```elixir
for {name, _method, _path, required, optional, fixture_type} <- MyAPI.__methods__() do
  describe "#{name}" do
    test "returns #{fixture_type} on success" do
      fixture = apply(APIFixtures, unquote(fixture_type), [])
      stub(MyAPI, fn conn -> Req.Test.json(conn, fixture) end)
      args = build_test_args(unquote(required), unquote(optional))
      assert {:ok, _} = apply(MyAPI, unquote(name), args)
    end
  end
end
```

---

### Elixir-Specific: Macros Are Idiomatic

Unlike most languages, Elixir embraces macros for declarative APIs. Phoenix, Ecto, and most major libraries use them (`plug`, `get/post`, `field`, `attr`).

**When macros ARE the right choice:**
- Declarative configuration (routes, schema fields, plugs)
- Compile-time validation of API contracts
- Reducing boilerplate where patterns repeat 3+ times with only data differences
- DSLs that read like configuration, not code

**Don't fight Elixir idioms.** Ten nearly-identical functions with minor variations is a signal to consider a macro — that's elegant simplicity, not premature abstraction.

### Credential Handling

**Libraries NEVER read ENV.** Pass credentials explicitly:

```elixir
# Option A: Module-level config (set once per process)
MyAPI.configure(api_key, secret)

# Option B: Per-call credentials (more explicit, multi-tenant safe)
MyAPI.get_ticker(credentials, "BTC-USD")
```

See library-design.md for full credential management guidelines.
