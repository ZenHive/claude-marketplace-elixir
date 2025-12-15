---
name: phoenix-patterns
description: Phoenix 1.8 framework patterns reference. Use when working with Phoenix templates, forms, LiveView streams, auth routing, HEEx syntax, Tailwind v4, Elixir macros, or API integration patterns.
allowed-tools: Read
---

# Phoenix 1.8 Patterns Reference

Quick reference for Phoenix 1.8+ framework patterns, Elixir idioms, common pitfalls, and best practices.

## When to use this skill

- Working with Phoenix templates or LiveView
- Handling forms in Phoenix 1.8
- Using LiveView streams for collections
- Setting up authentication routing
- Writing HEEx templates
- Configuring Tailwind CSS v4
- Understanding when to use Elixir macros
- Building API clients (when to abstract, macro DSLs)

## Project Setup

### Auth Generation (CRITICAL)

**ALWAYS use the `--live` flag** when generating authentication:

```bash
# ✅ CORRECT - Generates LiveView-based auth with proper scoping
mix phx.gen.auth Accounts User users --live

# ❌ WRONG - Does NOT configure LiveView scoping
mix phx.gen.auth Accounts User users
```

**Why this matters:**
- Without `--live`: Future `phx.gen.live` commands won't be scoped to current user
- With `--live`: All subsequent generators auto-scope by `user_id` (security by default)
- Forgetting requires complete redo of auth setup

### Recommended Dependencies

```elixir
defp deps do
  [
    {:styler, "~> 1.9", only: [:dev, :test], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
    {:doctor, "~> 0.21", only: [:dev, :test], runtime: false},
    {:tidewave, "~> 0.5", only: :dev},
    {:live_debugger, "~> 0.5", only: :dev}
  ]
end
```

## Template Wrapper Requirement

**Always wrap LiveView templates** with `<Layouts.app>`:

```heex
<Layouts.app flash={@flash} current_scope={@current_scope}>
  <!-- Your content here -->
</Layouts.app>
```

**Key points:**
- `Layouts` is aliased in `my_app_web.ex` - no need to alias again
- Phoenix 1.8 moved `<.flash_group>` to Layouts - **forbidden** to call outside layouts.ex
- Use `<.icon name="hero-x-mark" class="w-5 h-5"/>` for hero icons (imported in core_components.ex)

## Form Handling (CRITICAL)

**This is the most common source of errors in Phoenix 1.8.**

### Correct Pattern

```elixir
# LiveView
assign(socket, :form, to_form(changeset))

# Template
<.form for={@form} id="unique-form-id">
  <.input field={@form[:field_name]} type="text" />
</.form>
```

### Forbidden Patterns

```elixir
# ❌ NEVER use changeset directly in templates
<.form for={@changeset}>

# ❌ NEVER access changeset in templates
<.input field={@changeset[:field]}>

# ❌ Deprecated pattern
<.form let={f}>
```

### Requirements

- Always provide unique DOM IDs to forms (`id="product-form"`)
- Always use imported `<.input>` component (from core_components.ex)
- Form field access: `@form[:field]` not `@changeset[:field]`

## LiveView Streams

**Always use streams for collections** to avoid memory issues:

### Basic Operations

```elixir
stream(socket, :items, items)                    # append
stream(socket, :items, new_items, at: 0)         # prepend
stream(socket, :items, filtered, reset: true)    # filter/reset
stream_delete(socket, :items, item)              # delete
```

### Template Pattern

```heex
<div id="items" phx-update="stream">
  <div :for={{id, item} <- @streams.items} id={id}>
    {item.text}
  </div>
</div>
```

### Important Limitations

- Streams are **NOT enumerable** - cannot use `Enum.filter/2` or `Enum.count/1`
- Track counts separately: `assign(socket, :items_count, length(items))`
- For filtering: re-fetch data and use `stream(..., reset: true)`
- Empty states: use CSS `class="hidden only:block"` or separate assign

### Common Mistakes

```elixir
# ❌ NEVER use deprecated attributes
phx-update="append"
phx-update="prepend"

# ✅ Use stream attribute
phx-update="stream"
```

## Authentication Routing

`phx.gen.auth --live` creates multiple router scopes.

### Routes Requiring Authentication

```elixir
scope "/", AppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{AppWeb.UserAuth, :require_authenticated}] do
    live "/dashboard", DashboardLive, :index
  end
end
```

### Routes With Optional Auth

```elixir
scope "/", AppWeb do
  pipe_through [:browser]

  live_session :current_user,
    on_mount: [{AppWeb.UserAuth, :mount_current_scope}] do
    live "/", HomeLive, :index
  end
end
```

### Key Points

- Auth assigns `@current_scope` (NOT `@current_user`)
- Access user: `@current_scope.user` (never `@current_user`)
- Pass scope to contexts: `MyContext.list_items(@current_scope)`
- **Never** duplicate `live_session` names
- Always pass `current_scope={@current_scope}` to `<Layouts.app>`

## HEEx Templates

### Interpolation Rules

```heex
<%# ✅ Use {} in attributes %>
<div class={@class}>

<%# ✅ Use <%= %> for block constructs %>
<%= for item <- @items do %>

<%# ❌ NEVER use <%= %> in attributes %>
<div class="<%= @class %>">
```

### Conditional Classes

```heex
<%# ✅ List syntax for conditional classes %>
<div class={["base", @active && "active", @error && "text-red-500"]}>
```

### Iteration

```heex
<%# ✅ Use for comprehension %>
<%= for item <- @items do %>
  <div>{item.name}</div>
<% end %>

<%# ❌ NEVER use Enum.each %>
```

## Verified Routes

**Always use `~p` sigil** for compile-time route verification:

```elixir
<.link navigate={~p"/properties/#{@property}"}>View</.link>
push_navigate(socket, to: ~p"/dashboard")
```

## Tailwind CSS v4

### Configuration (No tailwind.config.js needed)

In `app.css`:
```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/my_app_web";
```

### Rules

- **Never** use `@apply` in raw CSS
- Import vendor deps into app.js/app.css (no external `src`/`href` in layouts)
- **Never** write inline `<script>` tags in templates

## Common Runtime Errors

**These cause runtime crashes, not compile-time warnings:**

### Elixir Patterns

```elixir
# ❌ List access (ArgumentError)
list[i]
# ✅ Correct
Enum.at(list, i)

# ❌ Struct access (UndefinedFunctionError)
struct[:field]
# ✅ Correct
struct.field

# ❌ No else if in Elixir
if x do ... else if y do ...
# ✅ Use cond
cond do
  x -> ...
  y -> ...
end

# ❌ Immutability ignored
if condition do
  assign(socket, :x, 1)
end
# ✅ Capture result
socket = if condition do
  assign(socket, :x, 1)
else
  socket
end
```

### Performance

```elixir
# ❌ O(n) - traverses entire list
length(list) == 0

# ✅ O(1)
Enum.empty?(list)
list == []
```

### Router

```elixir
# Inside scope "/admin", AppWeb.Admin do
# ❌ Full path
live "/users", AppWeb.Admin.UserLive

# ✅ Auto-aliased
live "/users", UserLive
```

### Ecto

```elixir
# ❌ Security vulnerability - user_id in cast
cast(attrs, [:title, :user_id])

# ✅ Set programmatically
|> cast(attrs, [:title])
|> put_change(:user_id, current_scope.user.id)

# ❌ Forgetting preloads
message.user.name  # LazyLoad error in LiveView

# ✅ Always preload
from m in Message, preload: [:user]
```

### Other Critical

- **HTTP client:** Use `:req` (not `:httpoison`, `:tesla`)
- **Predicates:** `active?(user)` not `is_active(user)` (reserve `is_` for guards)
- **Atoms from user input:** NEVER `String.to_atom(user_input)` (memory leak)
- **Module nesting:** Don't nest modules in one file (cyclic dependencies)
- **Task.async_stream:** Use `timeout: :infinity` for back-pressure

## Macro Patterns (Elixir Idiom)

Macros are idiomatic in Elixir - Phoenix, Ecto, and most libraries use them. **Don't avoid macros when they're the right tool.**

**Use macros when:**
- 3+ similar function definitions differing only in data (method name, path, params)
- Declarative DSLs (routes, schema fields, API endpoints, test setup)
- Compile-time validation catches errors before runtime
- The alternative is copy-paste with risk of inconsistency

**Macro structure basics:**
```elixir
defmodule MyDSL do
  defmacro api_method(name, http_method, path, path_params, body_params \\ []) do
    quote do
      @spec unquote(name)(unquote_splicing(generate_param_types(path_params ++ body_params))) ::
              {:ok, map()} | {:error, term()}
      def unquote(name)(unquote_splicing(Macro.generate_arguments(length(path_params ++ body_params), __MODULE__))) do
        # Implementation using bound variables
      end
    end
  end
end
```

**Common patterns:**
- `@before_compile` - Generate functions from accumulated attributes
- `__using__/1` - Setup when module does `use MyDSL`
- Module attributes (`@methods []`) - Accumulate definitions, generate at compile
- `quote` + `unquote` - Template code generation

## API Integration: When to Abstract

- **1-3 endpoints**: Plain functions are fine, copy-paste is acceptable
- **4-9 endpoints**: Consider a shared helper module for common patterns
- **10+ endpoints with similar patterns**: A macro DSL may be justified

**Always prove first** - Implement 3-5 endpoints manually to understand actual patterns before abstracting.

**Signs you should use a macro:**
- Multiple functions differing only in method name, path, or params
- Copy-paste patterns where inconsistency causes bugs
- Configuration-like definitions benefiting from compile-time checks
- Wrapping an external API with 10+ similar endpoints

**Key principle**: Repetition is cheaper than wrong abstraction. Wait until you feel the pain.

## AGENTS.md Reminder

Every `mix phx.new` project generates an `AGENTS.md` file with the latest Phoenix framework rules. **Always check the project's AGENTS.md first** - it contains up-to-date guidelines specific to that project.
