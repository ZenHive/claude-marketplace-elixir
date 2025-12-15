---
name: phoenix-scope
description: Phoenix 1.8 Scope patterns for user-scoped data, authorization, and extending scope with custom fields like exchange capabilities.
allowed-tools: Read
---

# Phoenix Scope Patterns

Guide for working with Phoenix 1.8+ Scope struct for authorization, user-scoped data, and extending scope with application-specific context.

## When to use this skill

- Working with `@current_scope` in LiveViews
- Passing scope to context functions
- Extending scope with custom fields (e.g., capabilities, permissions)
- Understanding user-scoped data patterns
- Authorization checks in contexts

## What is Scope?

Phoenix 1.8 `phx.gen.auth --live` generates a `Scope` struct that represents the current user's session context:

```elixir
# lib/my_app/accounts/scope.ex
defmodule MyApp.Accounts.Scope do
  defstruct [:user]
end
```

The scope is mounted in LiveViews via UserAuth.on_mount/4 and available as `@current_scope`.

## Basic Usage

### In LiveViews

```elixir
def mount(_params, _session, socket) do
  # @current_scope is automatically assigned by UserAuth on_mount
  items = Items.list_items(socket.assigns.current_scope)
  {:ok, assign(socket, items: items)}
end
```

### In Templates

```heex
<Layouts.app flash={@flash} current_scope={@current_scope}>
  <p>Welcome, {@current_scope.user.email}!</p>
</Layouts.app>
```

### In Contexts

```elixir
defmodule MyApp.Items do
  def list_items(%Scope{user: user}) do
    Item
    |> where(user_id: ^user.id)
    |> Repo.all()
  end

  def create_item(%Scope{user: user}, attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Repo.insert()
  end
end
```

## Key Principles

### 1. Always Pass Scope to Contexts

```elixir
# CORRECT - scope ensures user-scoping
Items.list_items(@current_scope)
Items.create_item(@current_scope, attrs)
Items.delete_item(@current_scope, item)

# WRONG - bypasses authorization
Items.list_items()
Items.delete_item(item)
```

### 2. Validate Ownership in Contexts

```elixir
def get_item(%Scope{user: user}, id) do
  Item
  |> where(user_id: ^user.id)
  |> Repo.get(id)
  |> case do
    nil -> {:error, :not_found}
    item -> {:ok, item}
  end
end

def delete_item(%Scope{} = scope, %Item{} = item) do
  # Re-validate ownership even if item was fetched earlier
  case get_item(scope, item.id) do
    {:ok, item} -> Repo.delete(item)
    {:error, :not_found} -> {:error, :unauthorized}
  end
end
```

### 3. Access User via Scope, Never Directly

```elixir
# CORRECT
@current_scope.user.email
@current_scope.user.id

# WRONG - @current_user doesn't exist in Phoenix 1.8+
@current_user.email
```

## Extending Scope

Scope can be extended with application-specific context loaded at session start.

### Example: Exchange Capabilities

```elixir
# lib/my_app/accounts/scope.ex
defmodule MyApp.Accounts.Scope do
  defstruct [:user, exchanges: %{}]

  @type t :: %__MODULE__{
    user: User.t() | nil,
    exchanges: %{String.t() => exchange_info()}
  }

  @type exchange_info :: %{
    credential_id: String.t(),
    label: String.t(),
    sandbox: boolean(),
    supported_methods: MapSet.t(String.t())
  }
end
```

### Loading Extended Scope

```elixir
# lib/my_app_web/user_auth.ex
def on_mount(:mount_current_scope, _params, session, socket) do
  case get_user_from_session(session) do
    nil ->
      {:cont, assign(socket, :current_scope, %Scope{})}

    user ->
      exchanges = Exchanges.list_credentials_as_scope_map(user)
      scope = %Scope{user: user, exchanges: exchanges}
      {:cont, assign(socket, :current_scope, scope)}
  end
end
```

### Building the Scope Map

```elixir
# lib/my_app/exchanges.ex
def list_credentials_as_scope_map(%User{} = user) do
  user
  |> list_credentials()
  |> Map.new(fn cred ->
    {cred.exchange_id, %{
      credential_id: cred.id,
      label: cred.label,
      sandbox: cred.sandbox,
      supported_methods: MapSet.new(cred.supported_methods)
    }}
  end)
end
```

### Using Extended Scope

```elixir
# Check if user has access to an exchange
def has_exchange?(%Scope{exchanges: exchanges}, exchange_id) do
  Map.has_key?(exchanges, exchange_id)
end

# Check if exchange supports a method
def supports_method?(%Scope{exchanges: exchanges}, exchange_id, method) do
  case Map.get(exchanges, exchange_id) do
    %{supported_methods: methods} -> MapSet.member?(methods, method)
    nil -> false
  end
end

# In context functions
def fetch_funding_rate(%Scope{} = scope, exchange_id, symbol) do
  with :ok <- validate_exchange_access(scope, exchange_id),
       :ok <- validate_method_support(scope, exchange_id, "fetchFundingRate") do
    Bridge.CCXT.fetch_funding_rate(exchange_id, symbol)
  end
end

defp validate_exchange_access(%Scope{exchanges: exchanges}, exchange_id) do
  if Map.has_key?(exchanges, exchange_id) do
    :ok
  else
    {:error, {:exchange_not_configured, exchange_id}}
  end
end

defp validate_method_support(%Scope{exchanges: exchanges}, exchange_id, method) do
  case Map.get(exchanges, exchange_id) do
    %{supported_methods: methods} ->
      if MapSet.member?(methods, method) do
        :ok
      else
        {:error, {:unsupported_method, method, exchange_id}}
      end
    _ ->
      {:error, {:exchange_not_configured, exchange_id}}
  end
end
```

### UI Feature Toggling

```elixir
# In LiveView
def mount(_params, _session, socket) do
  {:ok, assign(socket,
    can_fetch_funding: supports_method?(socket.assigns.current_scope, "binance", "fetchFundingRate"),
    available_exchanges: Map.keys(socket.assigns.current_scope.exchanges)
  )}
end
```

```heex
<button
  phx-click="fetch_funding"
  disabled={not @can_fetch_funding}
  class={["btn", not @can_fetch_funding && "opacity-50 cursor-not-allowed"]}
>
  Fetch Funding Rate
</button>

<select name="exchange">
  <option :for={ex <- @available_exchanges} value={ex}>{ex}</option>
</select>
```

## Common Patterns

### Optional Scope (Public + Private Data)

```elixir
def list_items(%Scope{user: nil}) do
  # Public items only
  Item |> where(public: true) |> Repo.all()
end

def list_items(%Scope{user: user}) do
  # User's items + public items
  Item
  |> where([i], i.user_id == ^user.id or i.public == true)
  |> Repo.all()
end
```

### Scope in Changesets

```elixir
def changeset(%Item{} = item, %Scope{user: user}, attrs) do
  item
  |> cast(attrs, [:title, :content])
  |> validate_required([:title])
  |> put_change(:user_id, user.id)  # Never from attrs!
end
```

### Testing with Scope

```elixir
describe "list_items/1" do
  test "returns only user's items" do
    user = insert(:user)
    other_user = insert(:user)
    scope = %Scope{user: user}

    my_item = insert(:item, user: user)
    _other_item = insert(:item, user: other_user)

    assert [^my_item] = Items.list_items(scope)
  end
end
```

## What NOT to Put in Scope

- **Large data sets** - Scope is loaded on every request
- **Frequently changing data** - Scope is cached for session duration
- **Derived/computed data** - Compute in contexts instead
- **Non-authorization data** - Scope is for "what can this user access?"

## Refreshing Scope

When user's capabilities change (e.g., new exchange credentials):

```elixir
# In LiveView after credential change
def handle_info({:credentials_updated, _}, socket) do
  exchanges = Exchanges.list_credentials_as_scope_map(socket.assigns.current_scope.user)
  scope = %{socket.assigns.current_scope | exchanges: exchanges}
  {:noreply, assign(socket, :current_scope, scope)}
end
```

Or redirect to force full reload:

```elixir
{:noreply, push_navigate(socket, to: ~p"/dashboard")}
```
