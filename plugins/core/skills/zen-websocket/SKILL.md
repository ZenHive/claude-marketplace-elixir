---
name: zen-websocket
description: ZenWebsocket library patterns and usage. Use when implementing WebSocket connections, handling reconnection logic, integrating with trading APIs (Deribit, Binance), or troubleshooting WebSocket issues. Provides connection patterns, message handling, and platform-specific guidance.
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion
---

# ZenWebsocket Usage Guide

Production-grade WebSocket client for Elixir, built on Gun with automatic reconnection, exponential backoff, and real-world testing. Designed for financial APIs with only 5 core functions.

## When to use this skill

Use this skill when you need to:
- Implement WebSocket connections in Elixir
- Handle automatic reconnection with exponential backoff
- Integrate with trading APIs (Deribit, Binance, etc.)
- Troubleshoot WebSocket connection issues
- Understand JSON-RPC correlation patterns
- Configure heartbeat mechanisms
- Set up rate limiting for WebSocket messages

## Core Concepts

### The 5 Essential Functions

ZenWebsocket intentionally limits its public API to 5 functions:

| Function | Purpose | Returns |
|----------|---------|---------|
| `connect/2` | Establish WebSocket connection | `{:ok, client}` or `{:error, reason}` |
| `send_message/2` | Send message to server | `:ok` or `{:error, reason}` |
| `subscribe/2` | Subscribe to channels (JSON-RPC) | `:ok` |
| `get_state/1` | Check connection state | `:connected` `:connecting` `:disconnected` |
| `close/1` | Close connection gracefully | `:ok` |

### Client Struct

The returned `client` is a struct containing:
- `gun_pid` - Gun process ID
- `stream_ref` - WebSocket stream reference
- `state` - Connection state
- `url` - Connected URL
- `monitor_ref` - Process monitor reference
- `server_pid` - GenServer PID (if using GenServer mode)

## Instructions

### Step 1: Determine the use case

Ask the user or determine from context which pattern they need:

1. **Development/Testing** - Direct connection, no supervision
2. **Production (Dynamic)** - ClientSupervisor for runtime-created connections
3. **Production (Fixed)** - Supervision tree with predefined connections

### Step 2: Provide appropriate pattern

#### Pattern 1: Development/Testing (No Supervision)

```elixir
# Simple direct connection
{:ok, client} = ZenWebsocket.Client.connect("wss://test.deribit.com/ws/api/v2")

# Messages arrive at calling process as {:websocket_message, data}
receive do
  {:websocket_message, data} ->
    IO.inspect(data, label: "Received")
end

# Always close when done
ZenWebsocket.Client.close(client)
```

#### Pattern 2: Production with Dynamic Connections

```elixir
# Add to application supervision tree
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      ZenWebsocket.ClientSupervisor,
      # ... other children
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

# Start connections dynamically at runtime
{:ok, client} = ZenWebsocket.ClientSupervisor.start_client(
  "wss://api.example.com/ws",
  [
    heartbeat_config: %{type: :ping, interval: 30_000},
    retry_count: 5
  ]
)
```

#### Pattern 3: Production with Fixed Connections

```elixir
# Define connections in supervision tree
children = [
  {ZenWebsocket.Client, [
    url: "wss://api.example.com/ws",
    id: :main_websocket,
    heartbeat_config: %{type: :ping, interval: 30_000},
    retry_count: 5,
    retry_delay: 1000
  ]}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

### Step 3: Configure connection options

Present available options based on user needs:

```elixir
opts = [
  # Connection
  timeout: 5000,              # Connection timeout in ms (default: 5000)
  headers: [],                # Custom HTTP headers

  # Reconnection
  retry_count: 3,             # Max reconnection attempts (default: 3)
  retry_delay: 1000,          # Initial backoff delay in ms (default: 1000)
  max_backoff: 30_000,        # Max delay between retries (default: 30_000)
  reconnect_on_error: true,   # Auto-reconnect on errors (default: true)
  restore_subscriptions: true, # Re-subscribe after reconnect (default: true)

  # Heartbeat
  heartbeat_config: %{
    type: :ping,              # :ping | :deribit | :custom
    interval: 30_000,         # Heartbeat interval in ms
    message: nil              # Custom heartbeat message (for :custom type)
  },

  # JSON-RPC correlation
  request_timeout: 30_000,    # Timeout for correlated requests (default: 30_000)

  # Debug
  debug: false                # Enable verbose debug logging
]
```

### Step 4: Message handling patterns

#### Basic message handling

```elixir
def handle_info({:websocket_message, data}, state) do
  case Jason.decode(data) do
    {:ok, %{"result" => result, "id" => id}} ->
      # JSON-RPC response
      handle_response(id, result, state)

    {:ok, %{"error" => error, "id" => id}} ->
      # JSON-RPC error
      handle_error(id, error, state)

    {:ok, %{"method" => method, "params" => params}} ->
      # JSON-RPC notification (subscription data)
      handle_notification(method, params, state)

    {:ok, other} ->
      # Other JSON message
      handle_json(other, state)

    {:error, _} ->
      # Non-JSON message
      handle_raw(data, state)
  end
end
```

#### JSON-RPC request/response correlation

```elixir
# Build JSON-RPC request (auto-generates unique ID)
{:ok, request} = ZenWebsocket.JsonRpc.build_request("public/subscribe", %{
  channels: ["deribit_price_index.btc_usd"]
})

# Send and track (requests with "id" field are auto-tracked)
:ok = ZenWebsocket.Client.send_message(client, Jason.encode!(request))

# Response arrives correlated by ID
receive do
  {:websocket_message, data} ->
    case Jason.decode(data) do
      {:ok, %{"id" => ^request_id, "result" => result}} ->
        # Matched response
        {:ok, result}
    end
end
```

### Step 5: Platform-specific integration

#### Deribit Integration

```elixir
# Connect with Deribit heartbeat handling
{:ok, client} = ZenWebsocket.Client.connect(
  "wss://test.deribit.com/ws/api/v2",
  [heartbeat_config: %{type: :deribit, interval: 30_000}]
)

# The :deribit type automatically:
# - Responds to test_request heartbeats from server
# - Sends public/test as outgoing heartbeat

# Subscribe to channels
ZenWebsocket.Client.subscribe(client, [
  "book.BTC-PERPETUAL.raw",
  "trades.BTC-PERPETUAL.raw"
])

# Authentication (manual JSON-RPC)
auth_request = %{
  "jsonrpc" => "2.0",
  "id" => :erlang.unique_integer([:positive]),
  "method" => "public/auth",
  "params" => %{
    "grant_type" => "client_credentials",
    "client_id" => System.get_env("DERIBIT_CLIENT_ID"),
    "client_secret" => System.get_env("DERIBIT_CLIENT_SECRET")
  }
}
:ok = ZenWebsocket.Client.send_message(client, Jason.encode!(auth_request))
```

#### Generic Exchange Integration

```elixir
# Standard WebSocket ping/pong
{:ok, client} = ZenWebsocket.Client.connect(url, [
  heartbeat_config: %{type: :ping, interval: 30_000}
])

# Custom heartbeat message
{:ok, client} = ZenWebsocket.Client.connect(url, [
  heartbeat_config: %{
    type: :custom,
    interval: 30_000,
    message: Jason.encode!(%{op: "ping"})
  }
])
```

### Step 6: Rate limiting (if needed)

```elixir
# Initialize rate limiter for connection
:ok = ZenWebsocket.RateLimiter.init(:my_connection, rate: 100, interval: 1000)

# Check before sending
case ZenWebsocket.RateLimiter.consume(:my_connection) do
  :ok ->
    ZenWebsocket.Client.send_message(client, msg)

  {:error, :rate_limited} ->
    # Queue or drop message
    {:error, :rate_limited}
end

# Exchange-specific cost functions available:
# ZenWebsocket.RateLimiter.deribit_cost/1  - Credit-based
# ZenWebsocket.RateLimiter.binance_cost/1  - Weight-based
# ZenWebsocket.RateLimiter.simple_cost/1   - Fixed cost of 1
```

### Step 7: Telemetry and monitoring

```elixir
# Attach telemetry handler
:telemetry.attach(
  "websocket-monitor",
  [:zen_websocket, :client, :message_received],
  fn _event, measurements, metadata, _config ->
    Logger.info("WS message: #{measurements.size} bytes from #{metadata.url}")
  end,
  nil
)

# Check heartbeat health
{:ok, health} = ZenWebsocket.Client.get_heartbeat_health(client)
# Returns: %{last_heartbeat_at: timestamp, failures: 0, active: true}

# Get detailed metrics
{:ok, metrics} = ZenWebsocket.Client.get_state_metrics(client)
```

## Error Handling

### Error Categories

ZenWebsocket categorizes errors for automatic handling:

| Category | Errors | Action |
|----------|--------|--------|
| **Recoverable** | `:timeout`, `:econnrefused`, `:nxdomain`, `:ehostunreach`, `:gun_down`, `:gun_error`, `:tls_alert` | Auto-reconnect with exponential backoff |
| **Fatal** | `:invalid_frame`, `:frame_too_large`, `:bad_frame`, `:unauthorized`, `:invalid_credentials`, `:token_expired` | Stop connection, notify user |

### Reconnection Behavior

When a recoverable error occurs:
1. Current connection cleaned up
2. Backoff calculated: `retry_delay * 2^attempt` (capped at `max_backoff`)
3. Reconnection attempted after backoff
4. If `restore_subscriptions: true`, previous subscriptions restored
5. After `retry_count` failures, connection stops

### Handling Connection Errors

```elixir
def handle_info({:websocket_error, reason}, state) do
  case reason do
    :timeout ->
      Logger.warn("Connection timeout, will auto-reconnect")
      {:noreply, state}

    {:unauthorized, _} ->
      Logger.error("Authentication failed")
      {:stop, :unauthorized, state}

    other ->
      Logger.warn("WebSocket error: #{inspect(other)}")
      {:noreply, state}
  end
end

def handle_info({:websocket_closed, reason}, state) do
  Logger.info("Connection closed: #{inspect(reason)}")
  {:noreply, state}
end
```

## Common Issues and Solutions

### Connection keeps timing out

```elixir
# Increase timeout
{:ok, client} = ZenWebsocket.Client.connect(url, timeout: 10_000)

# Check network connectivity
# Verify URL is correct (ws:// vs wss://)
# Check if firewall blocks WebSocket connections
```

### Messages not being received

```elixir
# Ensure you're receiving in the correct process
# Messages go to the process that called connect/2

# Verify connection state
:connected = ZenWebsocket.Client.get_state(client)

# Check for JSON decode errors in message handler
```

### Reconnection not working

```elixir
# Verify reconnection is enabled (default: true)
opts = [reconnect_on_error: true, retry_count: 5]

# Check if error is categorized as fatal
# Fatal errors stop the connection permanently

# Monitor logs for reconnection attempts
opts = [debug: true]
```

### Subscriptions lost after reconnect

```elixir
# Enable subscription restoration (default: true)
opts = [restore_subscriptions: true]

# Or manually re-subscribe on reconnect
def handle_info({:websocket_reconnected, _}, state) do
  ZenWebsocket.Client.subscribe(state.client, state.channels)
  {:noreply, state}
end
```

## DO NOT

1. **Don't create wrapper modules** - Use the 5 functions directly
2. **Don't mock WebSocket behavior** - Test against real endpoints
3. **Don't add custom reconnection logic** - Use built-in retry options
4. **Don't transform errors** - Handle raw Gun/WebSocket errors
5. **Don't skip heartbeats in production** - Configure appropriate heartbeat type

## Testing Guidelines

```elixir
# ALWAYS test against real endpoints
@tag :integration
test "connects to Deribit testnet" do
  {:ok, client} = ZenWebsocket.Client.connect("wss://test.deribit.com/ws/api/v2")
  assert ZenWebsocket.Client.get_state(client) == :connected
  ZenWebsocket.Client.close(client)
end

# For controlled testing, use local mock server (NOT mocks)
test "handles disconnection" do
  {:ok, _server} = ZenWebsocket.MockWebSockServer.start(port: 8080)
  {:ok, client} = ZenWebsocket.Client.connect("ws://localhost:8080")
  # Test behavior...
end
```

## Examples

### Example 1: Simple Echo Test

```elixir
{:ok, client} = ZenWebsocket.Client.connect("wss://echo.websocket.org")
:ok = ZenWebsocket.Client.send_message(client, "Hello!")

receive do
  {:websocket_message, "Hello!"} -> IO.puts("Echo received!")
after
  5000 -> IO.puts("Timeout waiting for echo")
end

ZenWebsocket.Client.close(client)
```

### Example 2: Deribit Price Feed

```elixir
defmodule MyApp.PriceFeed do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, client} = ZenWebsocket.Client.connect(
      "wss://test.deribit.com/ws/api/v2",
      [heartbeat_config: %{type: :deribit, interval: 30_000}]
    )

    ZenWebsocket.Client.subscribe(client, ["deribit_price_index.btc_usd"])

    {:ok, %{client: client, last_price: nil}}
  end

  def handle_info({:websocket_message, data}, state) do
    case Jason.decode(data) do
      {:ok, %{"params" => %{"data" => %{"price" => price}}}} ->
        IO.puts("BTC Price: $#{price}")
        {:noreply, %{state | last_price: price}}

      _ ->
        {:noreply, state}
    end
  end
end
```

### Example 3: Supervised Multi-Connection

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      ZenWebsocket.ClientSupervisor,
      MyApp.ConnectionManager
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule MyApp.ConnectionManager do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    # Start connections for multiple exchanges
    {:ok, btc_client} = ZenWebsocket.ClientSupervisor.start_client(
      "wss://test.deribit.com/ws/api/v2",
      [id: :deribit_btc]
    )

    {:ok, eth_client} = ZenWebsocket.ClientSupervisor.start_client(
      "wss://test.deribit.com/ws/api/v2",
      [id: :deribit_eth]
    )

    {:ok, %{btc: btc_client, eth: eth_client}}
  end
end
```

## Tool Usage Summary

When helping users with ZenWebsocket:

1. **Grep** - Search project for existing WebSocket usage patterns
2. **Read** - Read existing connection modules for context
3. **Glob** - Find WebSocket-related files in the project
4. **Bash** - Run mix commands to check dependencies
5. **AskUserQuestion** - Clarify use case (dev vs production, platform requirements)

## Best Practices

1. **Start simple** - Use Pattern 1 for development, add supervision for production
2. **Configure heartbeats** - Always set heartbeat_config for long-lived connections
3. **Handle reconnection** - Trust built-in reconnection, just ensure state is restored
4. **Test against real APIs** - Never mock WebSocket behavior
5. **Use JSON-RPC correlation** - Let ZenWebsocket track request/response matching
6. **Monitor with telemetry** - Attach handlers for production observability
7. **Keep it minimal** - Only 5 functions needed, don't over-abstract
