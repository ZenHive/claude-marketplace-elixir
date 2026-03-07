# Part 0: Layered Abstraction Pattern

**Rule: Wrap battle-tested libraries, don't reimplement them.**

When a mature library exists for your target API, create a thin wrapper that:
1. Provides Elixir-idiomatic interface
2. Handles credential management
3. Adds application-specific logic

## Architecture Example: Elixir -> Bridge -> Library -> API

```
+-------------------------------------------------------------+
|                     Your Elixir App                          |
+-------------------------------------------------------------+
|  CryptoBridge.CCXT                                           |
|  - Elixir functions with specs                               |
|  - Explicit credential passing                               |
|  - {:ok, result} | {:error, reason} returns                  |
+-------------------------------------------------------------+
|  Node.js Bridge (Unix Socket)                                |
|  - Thin HTTP wrapper                                         |
|  - Translates Elixir calls to library calls                  |
+-------------------------------------------------------------+
|  CCXT Library (Node.js)                                      |
|  - Battle-tested across 100+ exchanges                       |
|  - Handles auth, rate limits, pagination                     |
|  - Unified API for different exchange protocols              |
+-------------------------------------------------------------+
|  Exchange REST APIs                                          |
|  - Binance, Bybit, Deribit, etc.                            |
+-------------------------------------------------------------+
```

## When to wrap vs build

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

## Wrapper implementation pattern

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
