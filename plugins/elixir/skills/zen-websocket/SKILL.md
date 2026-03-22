---
name: zen-websocket
description: ZenWebsocket library for Elixir WebSocket connections. Use when implementing WebSocket clients, handling reconnection logic, or integrating with trading APIs (Deribit, Binance). Covers the 5 core functions (connect, send_message, subscribe, get_state, close), message handling, heartbeats, and platform-specific patterns.
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion
---

<!-- Auto-synced from ~/.claude/includes/zen-websocket.md — do not edit manually -->

## ZenWebsocket Patterns

Production-grade WebSocket client for financial APIs built on Gun. Uses only 5 core functions with automatic reconnection and real-world testing.

### The 5 Essential Functions

```elixir
# 1. Connect
{:ok, client} = ZenWebsocket.Client.connect("wss://api.example.com/ws")

# 2. Send message
:ok = ZenWebsocket.Client.send_message(client, Jason.encode!(%{method: "ping"}))

# 3. Subscribe (JSON-RPC convenience)
:ok = ZenWebsocket.Client.subscribe(client, ["channel.name"])

# 4. Check state
state = ZenWebsocket.Client.get_state(client)  # :connected | :connecting | :disconnected

# 5. Close
:ok = ZenWebsocket.Client.close(client)
```

### Connection Patterns

**Development (no supervision):**
```elixir
{:ok, client} = ZenWebsocket.Client.connect(url)
# Messages sent to calling process as {:websocket_message, data}
```

**Production (dynamic supervision):**
```elixir
# Add to supervision tree
children = [ZenWebsocket.ClientSupervisor]

# Start connections dynamically
{:ok, client} = ZenWebsocket.ClientSupervisor.start_client(url, opts)
```

**Production (fixed connections):**
```elixir
children = [
  {ZenWebsocket.Client, [
    url: "wss://api.example.com/ws",
    id: :main_ws,
    heartbeat_config: %{type: :ping, interval: 30_000}
  ]}
]
```

### Three-Layer Architecture (ccxt_client pattern)

Build WebSocket consumers in layers — use only what you need:

| Layer | Module | State | Use When |
|-------|--------|-------|----------|
| **1. Pure helpers** | `MyApp.WS.Helpers` | None | URL resolution, config building, message formatting |
| **2. Stateless client** | Thin wrapper around `ZenWebsocket.Client` | None | One-off connections, simple subscribe/receive |
| **3. Stateful adapter** | GenServer using ZenWebsocket | Reconnection, auth, subscriptions | Production with auto-reconnect, auth state machine |

Layer 3 is optional. ccxt_client's adapter manages: connection lifecycle, auth state (`:unauthenticated` → `:authenticating` → `:authenticated` → `:expired`), subscription restoration after reconnect, and exponential backoff. But Layer 2 (5 functions directly) is sufficient for most use cases.

### Configuration Options

```elixir
opts = [
  timeout: 5000,              # Connection timeout (ms)
  headers: [],                # Custom HTTP headers
  retry_count: 3,             # Max reconnection attempts
  retry_delay: 1000,          # Initial backoff delay (exponential)
  max_backoff: 30_000,        # Max delay between retries
  reconnect_on_error: true,   # Auto-reconnect on errors
  restore_subscriptions: true, # Re-subscribe after reconnect
  request_timeout: 30_000,    # JSON-RPC correlation timeout
  heartbeat_config: %{
    type: :ping,              # :ping | :deribit | :custom
    interval: 30_000          # Heartbeat interval (ms)
  }
]
```

### Heartbeat Types

| Type | Behavior | Use For |
|------|----------|---------|
| `:ping` | Standard WebSocket ping/pong frames | Most exchanges |
| `:deribit` | Auto-responds to `test_request`, sends `public/test` | Deribit |
| `:custom` | Sends user-defined message at interval | Exchanges with custom ping format |

```elixir
# Custom heartbeat for exchanges that expect JSON ping
heartbeat_config: %{
  type: :custom,
  interval: 30_000,
  message: Jason.encode!(%{op: "ping"})
}
```

### Message Handling

Messages arrive at the calling process (or configured handler):
```elixir
def handle_info({:websocket_message, data}, state) do
  case Jason.decode(data) do
    {:ok, %{"result" => result, "id" => id}} -> handle_response(id, result, state)
    {:ok, %{"error" => error, "id" => id}} -> handle_error(id, error, state)
    {:ok, %{"method" => method, "params" => params}} -> handle_notification(method, params, state)
    {:ok, other} -> handle_json(other, state)
    {:error, _} -> handle_raw(data, state)
  end
end

# Connection lifecycle events
def handle_info({:websocket_error, reason}, state) do ...end
def handle_info({:websocket_closed, reason}, state) do ...end
def handle_info({:websocket_reconnected, _}, state) do ...end
```

### JSON-RPC Support

```elixir
# Build and send JSON-RPC request (auto-generates unique ID)
{:ok, request} = ZenWebsocket.JsonRpc.build_request("public/subscribe", %{channels: channels})
:ok = ZenWebsocket.Client.send_message(client, Jason.encode!(request))

# Requests with "id" field are tracked and correlated automatically
# Responses arrive matched to pending requests by ID
```

### Error Categories

| Category | Errors | Action |
|----------|--------|--------|
| **Recoverable** | `:timeout`, `:econnrefused`, `:nxdomain`, `:ehostunreach`, `:gun_down`, `:gun_error`, `:tls_alert` | Auto-reconnect with backoff |
| **Fatal** | `:invalid_frame`, `:frame_too_large`, `:bad_frame`, `:unauthorized`, `:invalid_credentials`, `:token_expired` | Stop connection, notify caller |

### Reconnection Behavior

When a recoverable error occurs:
1. Current connection cleaned up
2. Backoff calculated: `retry_delay * 2^attempt` (capped at `max_backoff`)
3. Reconnection attempted after backoff
4. If `restore_subscriptions: true`, previous subscriptions re-sent
5. After `retry_count` failures, connection stops permanently

### Rate Limiting

```elixir
# Initialize rate limiter (per-connection)
:ok = ZenWebsocket.RateLimiter.init(:my_conn, rate: 100, interval: 1000)

# Consume before sending
case ZenWebsocket.RateLimiter.consume(:my_conn) do
  :ok -> send_message(client, msg)
  {:error, :rate_limited} -> queue_message(msg)
end

# Exchange-specific cost functions:
# ZenWebsocket.RateLimiter.deribit_cost/1  - Credit-based
# ZenWebsocket.RateLimiter.binance_cost/1  - Weight-based
# ZenWebsocket.RateLimiter.simple_cost/1   - Fixed cost of 1
```

### Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Connection keeps timing out | Network/firewall, wrong URL | Increase `timeout: 10_000`, verify `wss://` vs `ws://` |
| Messages not received | Wrong process | Messages go to process that called `connect/2` — verify with `get_state/1` |
| Reconnection not working | Fatal error category | Fatal errors stop permanently — check if error is recoverable |
| Subscriptions lost after reconnect | `restore_subscriptions` disabled | Set `restore_subscriptions: true` (default), or handle `{:websocket_reconnected, _}` manually |

### DO NOT

1. **Don't create wrapper modules** — Use the 5 functions directly (ccxt_client uses them as-is)
2. **Don't mock WebSocket behavior** — Test against real endpoints (use MockWebSockServer for controlled tests)
3. **Don't add custom reconnection logic** — Use built-in retry options
4. **Don't transform errors** — Handle raw Gun/WebSocket errors
5. **Don't skip heartbeats in production** — Always configure appropriate heartbeat type

### Platform-Specific: Deribit

```elixir
{:ok, client} = ZenWebsocket.Client.connect("wss://test.deribit.com/ws/api/v2", [
  heartbeat_config: %{type: :deribit, interval: 30_000}
])
# Auto-responds to test_request heartbeats
# Sends JSON-RPC public/test as heartbeat

# Subscribe to channels
ZenWebsocket.Client.subscribe(client, ["book.BTC-PERPETUAL.raw", "trades.BTC-PERPETUAL.raw"])

# Authentication (manual JSON-RPC)
auth = %{"jsonrpc" => "2.0", "id" => :erlang.unique_integer([:positive]),
  "method" => "public/auth",
  "params" => %{"grant_type" => "client_credentials",
    "client_id" => client_id, "client_secret" => client_secret}}
:ok = ZenWebsocket.Client.send_message(client, Jason.encode!(auth))
```

### Testing Rules

```elixir
# ALWAYS test against real endpoints
@tag :integration
test "real WebSocket behavior" do
  {:ok, client} = ZenWebsocket.Client.connect("wss://test.deribit.com/ws/api/v2")
  assert ZenWebsocket.Client.get_state(client) == :connected
  ZenWebsocket.Client.close(client)
end

# For controlled testing, use local mock server (NOT library mocks)
{:ok, _server} = ZenWebsocket.MockWebSockServer.start(port: 8080)
{:ok, client} = ZenWebsocket.Client.connect("ws://localhost:8080")
```

### Telemetry Events

```elixir
:telemetry.attach("ws-logger", [:zen_websocket, :client, :message_received],
  fn _event, measurements, metadata, _config ->
    Logger.info("Message: #{measurements.size} bytes from #{metadata.url}")
  end, nil)

# Health check
{:ok, health} = ZenWebsocket.Client.get_heartbeat_health(client)
# %{last_heartbeat_at: timestamp, failures: 0, active: true}
```

### Performance Characteristics

- Connection time: < 100ms typical
- Message latency: < 1ms processing
- Memory: ~50KB per connection
- Reconnection: Exponential backoff (1s, 2s, 4s... capped at max_backoff)
