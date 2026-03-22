---
name: phoenix-scope
description: Phoenix 1.8+ Scope struct patterns for authorization and user-scoped data. Use when implementing user-scoped queries, role-based authorization, or extending Scope with custom fields (e.g., exchange capabilities, tenant context). Covers Scope creation, plug integration, and LiveView scope access.
allowed-tools: Read
---

<!-- Auto-synced from ~/.claude/includes/phoenix-scope.md — do not edit manually -->

## Phoenix Scope Patterns

Guide for working with Phoenix 1.8+ Scope struct for authorization, user-scoped data, and extending scope with application-specific context.

### What is Scope?

Phoenix 1.8 `phx.gen.auth --live` generates a `Scope` struct that represents the current user's session context:

```elixir
# lib/my_app/accounts/scope.ex
defmodule MyApp.Accounts.Scope do
  defstruct [:user]
end
```

The scope is mounted in LiveViews via `UserAuth.on_mount/4` and available as `@current_scope`.

### Basic Usage

**In LiveViews:**
```elixir
def mount(_params, _session, socket) do
  items = Items.list_items(socket.assigns.current_scope)
  {:ok, assign(socket, items: items)}
end
```

**In Templates:**
```heex
<Layouts.app flash={@flash} current_scope={@current_scope}>
  <p>Welcome, {@current_scope.user.email}!</p>
</Layouts.app>
```

**In Contexts:**
```elixir
def list_items(%Scope{user: user}) do
  Item |> where(user_id: ^user.id) |> Repo.all()
end

def create_item(%Scope{user: user}, attrs) do
  %Item{}
  |> Item.changeset(attrs)
  |> Ecto.Changeset.put_change(:user_id, user.id)
  |> Repo.insert()
end
```

### Key Principles

**1. Always Pass Scope to Contexts:**
```elixir
# Correct - scope ensures user-scoping
Items.list_items(@current_scope)
Items.delete_item(@current_scope, item)

# Wrong - bypasses authorization
Items.list_items()
Items.delete_item(item)
```

**2. Validate Ownership in Contexts:**
```elixir
def delete_item(%Scope{} = scope, %Item{} = item) do
  case get_item(scope, item.id) do
    {:ok, item} -> Repo.delete(item)
    {:error, :not_found} -> {:error, :unauthorized}
  end
end
```

**3. Access User via Scope:**
```elixir
# Correct
@current_scope.user.email

# Wrong - doesn't exist in Phoenix 1.8+
@current_user.email
```

### Extending Scope

Scope can be extended with application-specific context loaded at session start.

**Extended scope structure:**
```elixir
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

**Loading Extended Scope (in UserAuth):**
```elixir
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

**Building the Scope Map:**
```elixir
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

**Using Extended Scope:**
```elixir
def supports_method?(%Scope{exchanges: exchanges}, exchange_id, method) do
  case Map.get(exchanges, exchange_id) do
    %{supported_methods: methods} -> MapSet.member?(methods, method)
    nil -> false
  end
end

def fetch_funding_rate(%Scope{} = scope, exchange_id, symbol) do
  with :ok <- validate_exchange_access(scope, exchange_id),
       :ok <- validate_method_support(scope, exchange_id, "fetchFundingRate") do
    Bridge.CCXT.fetch_funding_rate(exchange_id, symbol)
  end
end
```

**UI Feature Toggling:**
```heex
<button
  phx-click="fetch_funding"
  disabled={not supports_method?(@current_scope, "binance", "fetchFundingRate")}
>
  Fetch Funding Rate
</button>
```

### Common Patterns

**Optional Scope (Public + Private Data):**
```elixir
def list_items(%Scope{user: nil}) do
  Item |> where(public: true) |> Repo.all()
end

def list_items(%Scope{user: user}) do
  Item |> where([i], i.user_id == ^user.id or i.public == true) |> Repo.all()
end
```

**Scope in Changesets:**
```elixir
def changeset(%Item{} = item, %Scope{user: user}, attrs) do
  item
  |> cast(attrs, [:title, :content])
  |> put_change(:user_id, user.id)  # Never from attrs!
end
```

**Testing with Scope:**
```elixir
test "returns only user's items" do
  user = insert(:user)
  other_user = insert(:user)
  scope = %Scope{user: user}

  my_item = insert(:item, user: user)
  _other_item = insert(:item, user: other_user)

  assert [^my_item] = Items.list_items(scope)
end
```

### What NOT to Put in Scope

- **Large data sets** - Scope is loaded on every request
- **Frequently changing data** - Scope is cached for session duration
- **Derived/computed data** - Compute in contexts instead
- **Non-authorization data** - Scope is for "what can this user access?"

### Refreshing Scope

When user's capabilities change (e.g., new exchange credentials):

```elixir
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
