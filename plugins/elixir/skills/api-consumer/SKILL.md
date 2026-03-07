---
name: api-consumer
description: Macro-based API client generation for Elixir REST APIs. Use when building a client with 10+ similar endpoints — provides declarative method definitions with auto-generated functions. NOT for simple HTTP calls (use Req directly); this is for code-generated API wrappers with compile-time validation.
allowed-tools: Read, Bash, Grep, Glob
---

# API Consumer Macro Pattern

Build production-grade API clients in Elixir using declarative macros and compile-time code generation.

## Scope

WHAT THIS SKILL DOES:
  ✓ Macro-based API client generation for 10+ similar endpoints
  ✓ OpenAPI spec-driven code generation
  ✓ Decision guidance: plain functions vs helpers vs macro DSL

WHAT THIS SKILL DOES NOT DO:
  ✗ Simple 1-3 endpoint HTTP calls (→ just use Req directly)
  ✗ WebSocket or streaming APIs (→ zen-websocket)
  ✗ Wrapping existing Elixir SDKs (→ use the SDK directly)

## When to use this skill

- Deciding how to structure an API client (plain functions vs helpers vs macros)
- Building an Elixir client for a REST API with 10+ similar endpoints
- Need consistent error handling, timeouts, and retries across all endpoints
- Want auto-generated documentation and tests from method definitions
- Understanding when abstraction is justified vs premature

## Decision tree: Build vs Wrap

```
Does a battle-tested library exist? (CCXT, Stripe SDK, AWS SDK, etc.)
|
+-- YES -> WRAP IT (see references/layered-abstraction.md)
|          Create thin Elixir wrapper around existing library
|
+-- NO -> BUILD YOUR OWN
           |
           +-- 10+ similar endpoints? -> DECLARATIVE MACRO (below)
           |
           +-- <10 endpoints? -> SIMPLE MODULE (just write functions)
```

## Always Prove First

**Never build abstractions speculatively.** Implement 3-5 endpoints manually first to:
- Understand the actual response structures
- Discover error patterns and edge cases
- Identify what's truly repetitive vs. what varies

**Key principle**: Repetition is cheaper than wrong abstraction.

## Example Progression

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
defapi :users do
  get :show, "/users/:id"
  post :create, "/users"
end
```

## Declarative Macro Pattern (Primary)

**Rule: Define methods once, generate functions, docs, specs, and tests.**

### Step 1: Define method specifications

```elixir
defmodule MyApp.API do
  @api_methods [
    # {function_name, http_method, path_template, required_params, optional_params, fixture_type}
    {:get_account, :get, "/api/v1/account", [], [], :account},
    {:get_ticker, :get, "/api/v1/ticker/:symbol", [:symbol], [], :ticker},
    {:create_order, :post, "/api/v1/orders", [],
     [symbol: nil, side: nil, type: nil, quantity: nil, price: nil], :order},
    {:cancel_order, :delete, "/api/v1/orders/:order_id", [:order_id], [symbol: nil], :canceled},
    {:get_orders, :get, "/api/v1/orders", [], [symbol: nil, status: nil, limit: 100], :orders}
  ]
```

**Tuple format:**
| Position | Type | Description | Example |
|----------|------|-------------|---------|
| 1 | atom | Function name | `:get_ticker` |
| 2 | atom | HTTP method | `:get`, `:post`, `:delete` |
| 3 | string | Path template with `:param` placeholders | `"/api/v1/ticker/:symbol"` |
| 4 | list | Required parameters (positional args) | `[:symbol]` |
| 5 | keyword | Optional parameters with defaults | `[limit: 100]` |
| 6 | atom | Fixture type for testing | `:ticker` |

### Step 2: Generate functions at compile time

```elixir
  # Expose methods for introspection (testing, sync checking)
  @doc false
  def __methods__, do: @api_methods

  for {name, http_method, path_template, required_params, optional_params, _fixture_type} <-
        @api_methods do

    path_params =
      Regex.scan(~r/:(\w+)/, path_template)
      |> Enum.map(fn [_, param] -> String.to_atom(param) end)

    body_params = required_params -- path_params
    all_required = path_params ++ body_params
    args = Enum.map(all_required, &Macro.var(&1, __MODULE__))
    has_opts = optional_params != []

    if has_opts do
      @spec unquote(name)(unquote_splicing(Enum.map(all_required, fn _ -> quote do: term() end)), keyword()) ::
              {:ok, map()} | {:error, term()}
      def unquote(name)(unquote_splicing(args), opts \\ []) do
        path = unquote(path_template)
              |> interpolate_path(unquote(path_params), binding())
              |> encode_path_segments()
        params = build_params(unquote(body_params), binding(), opts, unquote(optional_params))
        do_request(unquote(http_method), path, params)
      end
    else
      @spec unquote(name)(unquote_splicing(Enum.map(all_required, fn _ -> quote do: term() end))) ::
              {:ok, map()} | {:error, term()}
      def unquote(name)(unquote_splicing(args)) do
        path = unquote(path_template)
              |> interpolate_path(unquote(path_params), binding())
              |> encode_path_segments()
        params = build_params(unquote(body_params), binding(), [], [])
        do_request(unquote(http_method), path, params)
      end
    end
  end
```

### Step 3: Helper functions

```elixir
  defp interpolate_path(template, params, bindings) do
    Enum.reduce(params, template, fn param, path ->
      value = Keyword.get(bindings, param) |> to_string()
      String.replace(path, ":#{param}", value)
    end)
  end

  defp encode_path_segments(path) do
    path |> String.split("/") |> Enum.map(&URI.encode/1) |> Enum.join("/")
  end

  defp build_params(body_params, bindings, opts, defaults) do
    required = body_params
      |> Enum.map(fn param -> {param, Keyword.get(bindings, param)} end)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
    optional = defaults |> Keyword.merge(opts) |> Enum.reject(fn {_, v} -> is_nil(v) end)
    Keyword.merge(required, optional)
  end
```

### Step 4: HTTP client with Req

```elixir
  @request_timeout_ms 30_000
  @req_options [receive_timeout: @request_timeout_ms, retry: false]

  defp do_request(method, path, params) do
    opts = build_request_opts(method, path, params)
    execute_request(method, opts)
  end

  defp build_request_opts(:get, path, params) do
    query = URI.encode_query(params)
    url = if query == "", do: base_url() <> path, else: base_url() <> path <> "?" <> query
    [url: url] ++ @req_options ++ auth_headers()
  end

  defp build_request_opts(:post, path, params) do
    [url: base_url() <> path, json: Map.new(params)] ++ @req_options ++ auth_headers()
  end

  defp execute_request(:get, opts), do: Req.get(opts) |> handle_response()
  defp execute_request(:post, opts), do: Req.post(opts) |> handle_response()
  defp execute_request(:delete, opts), do: Req.delete(opts) |> handle_response()

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299, do: {:ok, body}
  defp handle_response({:ok, %Req.Response{status: status, body: body}}),
    do: {:error, {:http_error, status, body}}
  defp handle_response({:error, exception}),
    do: {:error, {:request_failed, exception}}
```

### Step 5: Credential handling (EXPLICIT, never from env)

```elixir
  # Option A: Module-level config (set once per process)
  def configure(api_key, secret) do
    Process.put(:api_credentials, %{api_key: api_key, secret: secret})
  end

  # Option B: Pass credentials to each function (more explicit)
  @spec get_ticker(credentials(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_ticker(credentials, symbol) do
    # Use credentials directly...
  end
end
```

## Best practices summary

### DO

1. **Start with decision tree** - Wrap existing libraries when possible
2. **Single source of truth** - Method definitions drive everything
3. **Explicit credentials** - Never load from env in library code
4. **Compile-time generation** - Generate functions, docs, specs, tests
5. **Introspection function** - Expose `__methods__/0` for tooling
6. **Consistent returns** - Always `{:ok, data} | {:error, reason}`

### DON'T

1. **Don't reimplement protocols** - Use battle-tested libraries
2. **Don't hardcode credentials** - Pass explicitly or configure once
3. **Don't skip validation** - Validate params before HTTP call
4. **Don't retry blindly** - Order operations should never auto-retry

## Troubleshooting

- **Function not generating expected signature**: Check path template matches required_params. Path params extracted from `:param` in template.
- **Credentials not found**: Ensure `configure/2` called before API calls. Consider explicit credentials for multi-tenant.
- **Sync check shows false positives**: Verify upstream methods list is accurate. Check for renamed methods.

## References

For extended patterns beyond the core declarative macro:

- **`references/layered-abstraction.md`** - Part 0: Wrapping battle-tested libraries (CCXT, Stripe SDK, etc.) with thin Elixir wrappers
- **`references/sync-fixtures.md`** - Part 2: Mix tasks for API sync checking and test fixture generation from real responses
- **`references/openapi-generation.md`** - Part 3: Generating API clients from OpenAPI/Swagger specifications
