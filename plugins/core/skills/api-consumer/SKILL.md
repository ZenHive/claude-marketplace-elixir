---
name: api-consumer
description: Macro-based API client generation for Elixir. Use when building clients for REST APIs with 10+ similar endpoints. Primary pattern uses declarative method definitions with auto-generated functions. Optional enhancement uses OpenAPI spec generation for discovery.
allowed-tools: Read, Bash, Grep, Glob
---

# API Consumer Macro Pattern

Build production-grade API clients in Elixir using declarative macros and compile-time code generation.

## When to use this skill

Use this skill when:
- Deciding how to structure an API client (plain functions vs helpers vs macros)
- Building an Elixir client for a REST API with 10+ similar endpoints
- Need consistent error handling, timeouts, and retries across all endpoints
- Want auto-generated documentation and tests from method definitions
- Need API sync checking to detect upstream changes
- Understanding when abstraction is justified vs premature

## Decision tree: Build vs Wrap

Before building your own client, follow this decision tree:

```
Does a battle-tested library exist? (CCXT, Stripe SDK, AWS SDK, etc.)
│
├─ YES → WRAP IT (Part 0: Layered Abstraction)
│        Create thin Elixir wrapper around existing library
│        Don't reimplement protocol logic
│
└─ NO → BUILD YOUR OWN
         │
         ├─ 10+ similar endpoints? → DECLARATIVE MACRO (Part 1)
         │                           Single source of truth
         │                           Auto-generated functions + tests
         │
         └─ <10 endpoints? → SIMPLE MODULE
                             Just write functions directly
                             Macros are overkill
```

---

## Always Prove First

**Never build abstractions speculatively.** Implement 3-5 endpoints manually first to:
- Understand the actual response structures
- Discover error patterns and edge cases
- Identify what's truly repetitive vs. what varies

**Key principle**: Repetition is cheaper than wrong abstraction. A few duplicated lines are easier to maintain than a complex abstraction that doesn't quite fit. Wait until you feel the pain before abstracting.

## What to Standardize (when scale justifies it)

Common boilerplate worth abstracting at scale:
- HTTP client configuration (base URL, headers, timeouts)
- Authentication (API keys, OAuth, signature generation)
- Error response parsing and normalization
- Rate limiting and retry logic
- Response validation and type conversion

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

## Elixir-Specific: Macros Are Idiomatic

Unlike most languages, Elixir embraces macros for declarative APIs. Phoenix, Ecto, and most major libraries use them extensively (`plug`, `get/post`, `field`, `attr`).

**When macros ARE the right choice in Elixir:**
- Declarative configuration (routes, schema fields, plugs)
- Compile-time validation of API contracts
- Reducing boilerplate where patterns repeat 3+ times with only data differences
- DSLs that read like configuration, not code

**Signs you should use a macro instead of repetitive functions:**
- Multiple functions differing only in method name, path, or params
- Copy-paste patterns where inconsistency causes bugs
- Configuration-like definitions benefiting from compile-time checks
- You're wrapping an external API with 10+ similar endpoints

**Don't fight Elixir idioms.** Ten nearly-identical functions with minor variations is a signal to consider a macro - that's elegant simplicity in Elixir, not premature abstraction.

---

## Part 0: Layered Abstraction Pattern

**Rule: Wrap battle-tested libraries, don't reimplement them.**

When a mature library exists for your target API, create a thin wrapper that:
1. Provides Elixir-idiomatic interface
2. Handles credential management
3. Adds application-specific logic

### Architecture Example: Elixir → Bridge → Library → API

```
┌─────────────────────────────────────────────────────────┐
│                     Your Elixir App                      │
├─────────────────────────────────────────────────────────┤
│  CryptoBridge.CCXT                                       │
│  - Elixir functions with specs                          │
│  - Explicit credential passing                          │
│  - {:ok, result} | {:error, reason} returns             │
├─────────────────────────────────────────────────────────┤
│  Node.js Bridge (Unix Socket)                           │
│  - Thin HTTP wrapper                                    │
│  - Translates Elixir calls to library calls             │
├─────────────────────────────────────────────────────────┤
│  CCXT Library (Node.js)                                 │
│  - Battle-tested across 100+ exchanges                  │
│  - Handles auth, rate limits, pagination                │
│  - Unified API for different exchange protocols         │
├─────────────────────────────────────────────────────────┤
│  Exchange REST APIs                                     │
│  - Binance, Bybit, Deribit, etc.                       │
└─────────────────────────────────────────────────────────┘
```

### When to wrap vs build

**Wrap existing library when:**
- Library has >1000 GitHub stars and active maintenance
- Library handles complex protocol details (OAuth, WebSocket, pagination)
- Library is battle-tested across production use cases
- Protocol has edge cases you don't want to discover yourself

**Build your own when:**
- No mature library exists
- Library is abandoned or poorly maintained
- You need control over every HTTP request
- API is simple and well-documented

### Wrapper implementation pattern

```elixir
defmodule MyApp.ExternalService do
  @moduledoc """
  Thin wrapper around ExternalLibrary.

  Provides Elixir-idiomatic interface with explicit credentials.
  """

  alias MyApp.ExternalService.Bridge

  @doc """
  Get account balance.

  ## Examples

      iex> get_balance(credentials, "USD")
      {:ok, %{currency: "USD", amount: "1000.00"}}

  """
  @spec get_balance(credentials(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_balance(credentials, currency) do
    Bridge.call(:get_balance, credentials, %{currency: currency})
  end

  # Credentials are ALWAYS explicit, never from env
  @type credentials :: %{api_key: String.t(), secret: String.t()}
end
```

---

## Part 1: Declarative Macro Pattern (Primary)

**Rule: Define methods once, generate functions, docs, specs, and tests.**

This is the primary pattern for building API clients with many similar endpoints.

### Step 1: Define method specifications

Create a module attribute with all API methods:

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

Use a `for` comprehension to generate functions:

```elixir
  # Expose methods for introspection (testing, sync checking)
  @doc false
  def __methods__, do: @api_methods

  for {name, http_method, path_template, required_params, optional_params, _fixture_type} <-
        @api_methods do

    # Extract path parameters from template
    path_params =
      Regex.scan(~r/:(\w+)/, path_template)
      |> Enum.map(fn [_, param] -> String.to_atom(param) end)

    # Parameters that go in request body (not in path)
    body_params = required_params -- path_params

    # All required params become positional arguments
    all_required = path_params ++ body_params

    # Build function arguments
    args = Enum.map(all_required, &Macro.var(&1, __MODULE__))

    # Has optional params?
    has_opts = optional_params != []

    if has_opts do
      @doc """
      #{name |> to_string() |> String.replace("_", " ") |> String.capitalize()}

      ## Required parameters
      #{Enum.map_join(all_required, "\n", fn p -> "- `#{p}`" end)}

      ## Optional parameters
      #{Enum.map_join(optional_params, "\n", fn {k, v} -> "- `#{k}` (default: `#{inspect(v)}`)" end)}
      """
      @spec unquote(name)(unquote_splicing(Enum.map(all_required, fn _ -> quote do: term() end)), keyword()) ::
              {:ok, map()} | {:error, term()}
      def unquote(name)(unquote_splicing(args), opts \\ []) do
        path =
          unquote(path_template)
          |> interpolate_path(unquote(path_params), binding())
          |> encode_path_segments()

        params = build_params(unquote(body_params), binding(), opts, unquote(optional_params))
        do_request(unquote(http_method), path, params)
      end
    else
      @doc """
      #{name |> to_string() |> String.replace("_", " ") |> String.capitalize()}

      ## Parameters
      #{Enum.map_join(all_required, "\n", fn p -> "- `#{p}`" end)}
      """
      @spec unquote(name)(unquote_splicing(Enum.map(all_required, fn _ -> quote do: term() end))) ::
              {:ok, map()} | {:error, term()}
      def unquote(name)(unquote_splicing(args)) do
        path =
          unquote(path_template)
          |> interpolate_path(unquote(path_params), binding())
          |> encode_path_segments()

        params = build_params(unquote(body_params), binding(), [], [])
        do_request(unquote(http_method), path, params)
      end
    end
  end
```

### Step 3: Implement helper functions

```elixir
  # Path interpolation: "/orders/:id" + [id: "123"] → "/orders/123"
  defp interpolate_path(template, params, bindings) do
    Enum.reduce(params, template, fn param, path ->
      value = Keyword.get(bindings, param) |> to_string()
      String.replace(path, ":#{param}", value)
    end)
  end

  # URL encode path segments
  defp encode_path_segments(path) do
    path
    |> String.split("/")
    |> Enum.map(&URI.encode/1)
    |> Enum.join("/")
  end

  # Build request params from required + optional
  defp build_params(body_params, bindings, opts, defaults) do
    required =
      body_params
      |> Enum.map(fn param -> {param, Keyword.get(bindings, param)} end)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    optional =
      defaults
      |> Keyword.merge(opts)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    Keyword.merge(required, optional)
  end
```

### Step 4: HTTP client with Req

```elixir
  @request_timeout_ms 30_000
  @req_options [
    receive_timeout: @request_timeout_ms,
    retry: false
  ]

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

  defp build_request_opts(:delete, path, params) do
    query = URI.encode_query(params)
    url = if query == "", do: base_url() <> path, else: base_url() <> path <> "?" <> query
    [url: url] ++ @req_options ++ auth_headers()
  end

  defp execute_request(:get, opts), do: Req.get(opts) |> handle_response()
  defp execute_request(:post, opts), do: Req.post(opts) |> handle_response()
  defp execute_request(:delete, opts), do: Req.delete(opts) |> handle_response()

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, {:http_error, status, body}}
  end

  defp handle_response({:error, exception}) do
    {:error, {:request_failed, exception}}
  end
```

### Step 5: Credential handling (EXPLICIT, never from env)

```elixir
  # Store credentials in process dictionary or pass explicitly
  # NEVER load from environment variables in library code

  # Option A: Module-level config (set once per process)
  def configure(api_key, secret) do
    Process.put(:api_credentials, %{api_key: api_key, secret: secret})
  end

  defp auth_headers do
    case Process.get(:api_credentials) do
      nil -> raise "API credentials not configured. Call configure/2 first."
      %{api_key: key, secret: secret} ->
        timestamp = System.system_time(:millisecond)
        signature = sign_request(secret, timestamp)
        [headers: [
          {"X-API-KEY", key},
          {"X-TIMESTAMP", to_string(timestamp)},
          {"X-SIGNATURE", signature}
        ]]
    end
  end

  # Option B: Pass credentials to each function (more explicit)
  @spec get_ticker(credentials(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_ticker(credentials, symbol) do
    # Use credentials directly...
  end
end
```

---

## Part 2: Sync Checking & Fixtures

**Rule: Detect when your client is out of sync with the upstream API.**

### Mix task for API sync checking

Create a mix task that compares your client's methods against the actual API:

```elixir
defmodule Mix.Tasks.Api.CheckMethods do
  @moduledoc """
  Check if API client methods are in sync with upstream API.

  ## Usage

      mix api.check_methods
      mix api.check_methods --verbose

  """
  use Mix.Task

  @shortdoc "Check API client methods against upstream API"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [verbose: :boolean])
    verbose = Keyword.get(opts, :verbose, false)

    # Get methods defined in your client
    client_methods =
      MyApp.API.__methods__()
      |> Enum.map(fn {name, _, _, _, _, _} -> name end)
      |> MapSet.new()

    # Get methods from upstream API documentation or spec
    upstream_methods = fetch_upstream_methods()

    # Compare
    missing = MapSet.difference(upstream_methods, client_methods)
    extra = MapSet.difference(client_methods, upstream_methods)

    # Report
    if MapSet.size(missing) > 0 do
      Mix.shell().info("\n#{IO.ANSI.yellow()}Missing methods (in API, not in client):#{IO.ANSI.reset()}")
      Enum.each(missing, &Mix.shell().info("  - #{&1}"))
    end

    if MapSet.size(extra) > 0 do
      Mix.shell().info("\n#{IO.ANSI.cyan()}Extra methods (in client, not in API):#{IO.ANSI.reset()}")
      Enum.each(extra, &Mix.shell().info("  - #{&1}"))
    end

    if MapSet.size(missing) == 0 and MapSet.size(extra) == 0 do
      Mix.shell().info("#{IO.ANSI.green()}Client is in sync with API#{IO.ANSI.reset()}")
    end

    if verbose do
      Mix.shell().info("\n#{IO.ANSI.blue()}All client methods:#{IO.ANSI.reset()}")
      Enum.each(client_methods, &Mix.shell().info("  - #{&1}"))
    end
  end

  defp fetch_upstream_methods do
    # Implementation depends on API:
    # - Parse OpenAPI spec
    # - Parse HTML documentation
    # - Query a methods endpoint
    # - Execute a script that inspects library source
    MapSet.new([:get_account, :get_ticker, :create_order, :cancel_order])
  end
end
```

### Fixture generation for tests

Generate test fixtures from real API responses:

```elixir
defmodule Mix.Tasks.Api.GenerateFixtures do
  @moduledoc """
  Generate test fixtures from real API responses.

  ## Usage

      mix api.generate_fixtures --env testnet

  """
  use Mix.Task

  @shortdoc "Generate test fixtures from real API"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [env: :string])
    env = Keyword.get(opts, :env, "testnet")

    # Configure API for testnet
    configure_api(env)

    # Generate fixtures for each method
    fixtures =
      MyApp.API.__methods__()
      |> Enum.map(fn {name, _, _, _, _, fixture_type} ->
        {fixture_type, fetch_fixture(name)}
      end)
      |> Enum.into(%{})

    # Write to fixtures file
    content = """
    defmodule MyApp.APIFixtures do
      @moduledoc "Auto-generated from real API responses"

      #{Enum.map_join(fixtures, "\n\n", &fixture_function/1)}
    end
    """

    File.write!("test/support/api_fixtures.ex", content)
    Mix.shell().info("Generated fixtures in test/support/api_fixtures.ex")
  end

  defp fetch_fixture(:get_ticker) do
    {:ok, response} = MyApp.API.get_ticker("BTC-USD")
    response
  end

  # ... more fixture fetchers

  defp fixture_function({type, data}) do
    """
      def #{type}(overrides \\\\ %{}) do
        Map.merge(#{inspect(data, pretty: true)}, overrides)
      end
    """
  end
end
```

### Using fixtures in tests

```elixir
defmodule MyApp.APITest do
  use ExUnit.Case
  import Req.Test

  alias MyApp.API
  alias MyApp.APIFixtures

  # Generate tests at compile time from method definitions
  for {name, http_method, _path, required, optional, fixture_type} <- API.__methods__() do
    arity = length(required) + if(optional == [], do: 0, else: 1)

    describe "#{name}/#{arity}" do
      test "returns #{fixture_type} on success" do
        fixture = apply(APIFixtures, unquote(fixture_type), [])

        stub(MyApp.API, fn conn ->
          Req.Test.json(conn, fixture)
        end)

        # Build args for function call
        args = build_test_args(unquote(required), unquote(optional))
        result = apply(API, unquote(name), args)

        assert {:ok, response} = result
        assert is_map(response)
      end

      test "returns error on HTTP error" do
        stub(MyApp.API, fn conn ->
          Req.Test.json(conn, %{"error" => "bad request"}, status: 400)
        end)

        args = build_test_args(unquote(required), unquote(optional))
        result = apply(API, unquote(name), args)

        assert {:error, {:http_error, 400, _}} = result
      end
    end
  end

  defp build_test_args(required, optional) do
    required_args = Enum.map(required, fn _ -> "test_value" end)
    if optional == [], do: required_args, else: required_args ++ [[]]
  end
end
```

---

## Part 3: OpenAPI Enhancement (Optional)

**Rule: When API provides OpenAPI spec, generate code from it.**

This is an alternative approach when you have access to an OpenAPI specification.

### When to use OpenAPI generation

**Use OpenAPI generation when:**
- API provides official OpenAPI/Swagger spec
- Spec is actively maintained and accurate
- You want auto-generated type specs
- API has many endpoints (50+)

**Use declarative macros when:**
- No OpenAPI spec available
- Spec is outdated or incomplete
- You need precise control over function signatures
- API has moderate endpoints (10-50)

### OpenAPI generation mix task

```elixir
defmodule Mix.Tasks.Api.GenerateFromSpec do
  @moduledoc """
  Generate API client from OpenAPI specification.

  ## Usage

      mix api.generate_from_spec --url https://api.example.com/openapi.yaml
      mix api.generate_from_spec --file priv/openapi.json

  """
  use Mix.Task

  @shortdoc "Generate API client from OpenAPI spec"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [url: :string, file: :string])

    spec =
      cond do
        opts[:url] -> fetch_spec(opts[:url])
        opts[:file] -> read_spec(opts[:file])
        true -> raise "Must provide --url or --file"
      end

    endpoints = parse_openapi(spec)
    content = generate_module(endpoints)

    File.write!("lib/my_app/api/generated_endpoints.ex", content)
    Mix.shell().info("Generated #{length(endpoints)} endpoints")
  end

  defp fetch_spec(url) do
    {:ok, %{body: body}} = Req.get(url)
    parse_yaml_or_json(body)
  end

  defp read_spec(path) do
    path |> File.read!() |> parse_yaml_or_json()
  end

  defp parse_openapi(spec) do
    spec["paths"]
    |> Enum.flat_map(fn {path, methods} ->
      Enum.map(methods, fn {method, details} ->
        %{
          operation: derive_operation_name(details["operationId"], method, path),
          method: String.to_atom(method),
          path: path,
          requires_auth: details["security"] != nil,
          params: extract_params(details["parameters"] || []),
          response_type: extract_response_type(details["responses"], spec),
          doc: details["summary"] || details["description"] || ""
        }
      end)
    end)
  end

  defp derive_operation_name(nil, method, path) do
    # Generate name from method + path
    path
    |> String.replace(~r/[{}]/, "")
    |> String.split("/")
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("_")
    |> then(&"#{method}_#{&1}")
    |> String.to_atom()
  end

  defp derive_operation_name(operation_id, _, _), do: String.to_atom(operation_id)

  defp extract_params(params) do
    Enum.map(params, fn param ->
      %{
        name: String.to_atom(param["name"]),
        in: param["in"],
        required: param["required"] || false,
        type: schema_to_type(param["schema"])
      }
    end)
  end

  defp extract_response_type(responses, spec) do
    case responses["200"]["content"]["application/json"]["schema"] do
      %{"$ref" => ref} -> resolve_ref(ref, spec)
      schema -> schema_to_type(schema)
    end
  end

  defp schema_to_type(%{"type" => "string"}), do: "String.t()"
  defp schema_to_type(%{"type" => "integer"}), do: "integer()"
  defp schema_to_type(%{"type" => "number"}), do: "float()"
  defp schema_to_type(%{"type" => "boolean"}), do: "boolean()"
  defp schema_to_type(%{"type" => "array", "items" => items}), do: "list(#{schema_to_type(items)})"
  defp schema_to_type(%{"type" => "object"}), do: "map()"
  defp schema_to_type(_), do: "term()"

  defp generate_module(endpoints) do
    """
    # Auto-generated from OpenAPI spec
    # Do not edit manually - regenerate with: mix api.generate_from_spec

    [
    #{Enum.map_join(endpoints, ",\n", &endpoint_to_map/1)}
    ]
    """
  end

  defp endpoint_to_map(endpoint) do
    """
      %{
        operation: #{inspect(endpoint.operation)},
        method: #{inspect(endpoint.method)},
        path: #{inspect(endpoint.path)},
        requires_auth: #{endpoint.requires_auth},
        doc: #{inspect(endpoint.doc)}
      }
    """
  end
end
```

### Loading generated endpoints

```elixir
defmodule MyApp.API.EndpointLoader do
  @moduledoc """
  Load generated endpoints at compile time.
  """

  defmacro load_endpoints(filename) do
    quote do
      @external_resource Path.join([__DIR__, unquote(filename)])

      @generated_endpoints (
        path = Path.join([__DIR__, unquote(filename)])

        case File.read(path) do
          {:ok, content} ->
            {result, _} = Code.eval_string(content)
            result

          {:error, _} ->
            Mix.shell().info("Warning: #{path} not found, using empty endpoints")
            []
        end
      )

      def __endpoints__, do: @generated_endpoints
    end
  end
end
```

---

## Best practices summary

### DO

1. **Start with decision tree** - Wrap existing libraries when possible
2. **Single source of truth** - Method definitions drive everything
3. **Explicit credentials** - Never load from env in library code
4. **Compile-time generation** - Generate functions, docs, specs, tests
5. **Introspection function** - Expose `__methods__/0` for tooling
6. **Consistent returns** - Always `{:ok, data} | {:error, reason}`
7. **API sync checking** - Mix task to detect upstream changes
8. **Fixture generation** - Real responses for realistic tests

### DON'T

1. **Don't reimplement protocols** - Use battle-tested libraries
2. **Don't hardcode credentials** - Pass explicitly or configure once
3. **Don't skip validation** - Validate params before HTTP call
4. **Don't ignore rate limits** - Add weight tracking if API has limits
5. **Don't retry blindly** - Order operations should never auto-retry

## Troubleshooting

### Function not generating expected signature

- Check path template matches required_params
- Path params are extracted from `:param` in template
- Body params = required_params - path_params

### Credentials not found

- Ensure `configure/2` called before API calls
- Check process dictionary isn't cleared between calls
- Consider explicit credentials pattern for multi-tenant

### Sync check shows false positives

- Verify upstream methods list is accurate
- Check for renamed methods (old name in client, new in API)
- Some APIs have undocumented methods

### Generated tests failing

- Update fixtures from real API responses
- Check API changed response format
- Verify testnet has same endpoints as production
