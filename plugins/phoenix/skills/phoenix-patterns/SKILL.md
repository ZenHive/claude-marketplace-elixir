---
name: phoenix-patterns
description: Phoenix 1.8+ framework patterns reference. Use when working with LiveView forms (to_form/2), streams, HEEx templates, auth routing, Tailwind v4 setup, or Phoenix component patterns. Covers template wrappers, form handling, verified routes, and common pitfalls.
allowed-tools: Read
---

<!-- Auto-synced from ~/.claude/includes/phoenix-patterns.md — do not edit manually -->

## Phoenix Guidelines (if applicable)

- **Context Boundaries**: Keep contexts focused and well-defined
- **LiveView**: Use LiveView for interactive UIs, avoid JavaScript when possible
- **Ecto**: Use changesets for data validation
- **Templates**: Keep templates simple, move logic to contexts
- **Channels**: Use channels for real-time features

### Phoenix 1.8 Framework Patterns

**IMPORTANT:** Every `mix phx.new` project generates an `AGENTS.md` file with the latest Phoenix framework rules and patterns. **ALWAYS check the project's `AGENTS.md` first** - it contains up-to-date, comprehensive guidelines for Phoenix 1.8+ projects.

#### Deprecated / Removed
- **`Phoenix.View`**: No longer included with Phoenix - don't use it
- **`live_redirect`/`live_patch`**: Use `<.link navigate={href}>` and `<.link patch={href}>` in templates. Use `push_navigate`/`push_patch` in LiveView modules.
- **`~E` sigil**: Use `~H` or `.html.heex` files only
- **`phx-update="append"`/`"prepend"`**: Use `phx-update="stream"` with streams

#### LiveView Best Practices
- **Avoid LiveComponents** unless you have a strong, specific need for them
- **Name LiveViews** with `Live` suffix (e.g., `AppWeb.WeatherLive`)

#### Template Rules
- **HEEx comments:** Use `<%!-- comment --%>` (not HTML `<!-- -->` comments)
- **`phx-no-curly-interpolation`:** Use on parent tags when rendering literal curly braces in code blocks
- **html_helpers:** Register reusable component imports in `my_app_web.ex`'s `html_helpers` block for availability across all LiveViews

#### Template Wrapper Requirement

- **Always** begin LiveView templates with `<Layouts.app flash={@flash} current_scope={@current_scope}>` wrapper
- The `MyAppWeb.Layouts` module is aliased in `my_app_web.ex`, no need to alias again
- Phoenix v1.8 moved `<.flash_group>` to the Layouts module - **forbidden** to call outside layouts.ex
- Use `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for hero icons (imported in core_components.ex)

#### Form Handling (CRITICAL)

**Always use `to_form/2` pattern** - this is the most common source of errors in Phoenix 1.8:

```elixir
# LiveView
assign(socket, :form, to_form(changeset))

# Template
<.form for={@form} id="unique-form-id">
  <.input field={@form[:field_name]} type="text" />
</.form>
```

**FORBIDDEN patterns:**
- ❌ `<.form for={@changeset}>` - NEVER use changeset directly in templates
- ❌ `<.input field={@changeset[:field]}>` - NEVER access changeset in templates
- ❌ `<.form let={f}>` - Deprecated pattern, don't use

**Requirements:**
- Always provide unique DOM IDs to forms (`id="product-form"`)
- Always use imported `<.input>` component (from core_components.ex)
- Form field access: `@form[:field]` not `@changeset[:field]`

#### LiveView Streams (Memory Efficiency)

**Always use streams for collections** to avoid memory issues with large lists:

```elixir
# Basic operations
stream(socket, :items, items)                    # append
stream(socket, :items, new_items, at: 0)         # prepend
stream(socket, :items, filtered, reset: true)    # filter/reset
stream_delete(socket, :items, item)              # delete
stream_delete_by_dom_id(socket, :items, "items-123")  # delete by DOM ID (v1.1+)

# Configure stream options (v1.1+)
stream_configure(socket, :items, dom_id: &"item-#{&1.id}")

# Async stream loading (v1.1+)
stream_async(socket, :items, fn -> MyApp.list_items() end)
```

**Template requirements:**
```heex
<div id="items" phx-update="stream">
  <div :for={{id, item} <- @streams.items} id={id}>
    {item.text}
  </div>
</div>
```

**Important limitations:**
- Streams are NOT enumerable - cannot use `Enum.filter/2` or `Enum.count/1`
- Track counts separately: `assign(socket, :items_count, length(items))`
- For filtering: re-fetch data and use `stream(..., reset: true)`
- Empty states: use CSS `class="hidden only:block"` pattern or separate assign

#### Change Tracking in Comprehensions (v1.1+)

Use `:key` with `:for` for efficient diffs - only changed items are re-sent:

```heex
<ul>
  <li :for={item <- @items} :key={item.id}>{item.name}</li>
</ul>
```

- **Without `:key`**: index-based tracking. Prepending an item resends all items after it.
- **With `:key`**: key-based tracking. Only moved/changed items are sent (minimal diff).
- Slightly more memory than streams. Use streams for very large collections.

#### Async Operations

**`assign_async/4`** - Load data asynchronously with built-in loading/ok/failed states:

```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign_async(:org, fn -> {:ok, %{org: fetch_org!()}} end)
   |> assign_async(:profile, fn -> {:ok, %{profile: fetch_profile!()}} end)}
end
```

```heex
<.async_result :let={org} assign={@org}>
  <:loading>Loading organization...</:loading>
  <:failed :let={_failure}>Failed to load</:failed>
  <h1>{org.name}</h1>
</.async_result>
```

**`start_async/4`** - Fire async work, handle result in `handle_async/3`:

```elixir
def mount(_params, _session, socket) do
  {:ok, start_async(socket, :data, fn -> expensive_operation() end)}
end

def handle_async(:data, {:ok, result}, socket) do
  {:noreply, assign(socket, data: result)}
end

def handle_async(:data, {:exit, reason}, socket) do
  {:noreply, put_flash(socket, :error, "Failed: #{inspect(reason)}")}
end
```

#### Portal Component (v1.1+)

`<.portal>` renders content outside the LiveView's DOM tree - useful for modals, tooltips, and overlays that need to escape parent z-index or overflow constraints:

```heex
<.portal>
  <div class="modal-overlay">
    <div class="modal-content">Content rendered at document body level</div>
  </div>
</.portal>
```

#### Form: used_input?/1 (v1.1+)

Check if a form input has been interacted with - useful for progressive validation:

```elixir
# Only show errors for fields the user has touched
def validate(params, socket) do
  changeset = MySchema.changeset(%MySchema{}, params)
  {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
end
```

```heex
<.input field={@form[:email]} type="email"
  errors={if used_input?(@form[:email]), do: @form[:email].errors, else: []} />
```

#### Miscellaneous (v1.1+)

- **`render_with/2`**: Delegate rendering to another module's `render/1`
- **`put_private/3`**: Store private data on socket (not sent to client)
- **`Phoenix.LiveView.Debug`**: Dev tools - `list_liveviews/0`, `socket/1`, `live_components/1`
- **LazyHTML**: Replaces Floki for test assertions. Add `{:lazy_html, ">= 0.0.0", only: :test}` to deps

#### Authentication Routing (phx.gen.auth)

**Router scope awareness** - `phx.gen.auth --live` creates multiple scopes:

**Routes requiring authentication:**
```elixir
scope "/", AppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [{AppWeb.UserAuth, :require_authenticated}] do
    live "/dashboard", DashboardLive, :index
  end
end
```

**Routes working with OR without auth:**
```elixir
scope "/", AppWeb do
  pipe_through [:browser]

  live_session :current_user,
    on_mount: [{AppWeb.UserAuth, :mount_current_scope}] do
    live "/", HomeLive, :index
  end
end
```

**Key points:**
- `phx.gen.auth` assigns `@current_scope` (NOT `@current_user`)
- Access user in templates: `@current_scope.user` (never `@current_user`)
- Pass scope to contexts: `MyContext.list_items(@current_scope)`
- **Never** duplicate `live_session` names (define each once, group all routes)
- Always pass `current_scope={@current_scope}` to `<Layouts.app>`

#### Common Pitfalls

See "Critical Phoenix 1.8 & Elixir Runtime Patterns" section above for: `else if`, HEEx interpolation, router scope aliases.

#### Verified Routes

Always use `~p` sigil for compile-time route verification:

```elixir
<.link navigate={~p"/properties/#{@property}"}>View</.link>
push_navigate(socket, to: ~p"/dashboard")
```

#### Tailwind CSS v4

- **No tailwind.config.js needed** - uses new import syntax in app.css:
  ```css
  @import "tailwindcss" source(none);
  @source "../css";
  @source "../js";
  @source "../../lib/my_app_web";
  ```
- **Never** use `@apply` in raw CSS
- Import vendor deps into app.js/app.css (no external `src`/`href` in layouts)
- **Never** write inline `<script>` tags in templates (exception: colocated hooks with `:type={ColocatedHook}`)
