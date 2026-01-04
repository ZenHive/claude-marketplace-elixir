---
name: nexus-template
description: Nexus Phoenix admin template architecture, Iconify icons, partials system, layout pipelines, and Alpine.js interactivity patterns.
allowed-tools: Read
---

# Nexus Phoenix Admin Template Reference

Nexus is an admin dashboard template built on Phoenix 1.8 with daisyUI 5, Tailwind CSS v4, and Iconify icons.

## When to use this skill

- Working with Nexus template structure
- Using Iconify icons
- Understanding partials system
- Setting up layout pipelines
- Adding Alpine.js interactivity

## Architecture

```
lib/nexus_phoenix_web/
├── components/
│   ├── core_components.ex    # Phoenix core UI components
│   ├── layouts.ex            # Layout components (embed_templates)
│   ├── partials.ex           # Reusable partial modules
│   └── layouts/              # Layout templates (root, admin, auth, etc.)
├── controllers/
│   ├── page_controller.ex    # Dynamic page dispatching
│   └── page_html/            # HEEx page templates
└── router.ex                 # Routes with layout pipelines

assets/styles/
├── app.css                   # Entry point with imports
├── daisyui.css               # daisyUI plugin and theme config
├── tailwind.css              # Tailwind base imports
├── core/                     # Custom animations and components
└── plugins/                  # Third-party plugin overrides
```

## Routing & Layouts

The router uses layout pipelines to select different root layouts:

```elixir
# In router.ex
pipeline :layout_empty do
  plug :put_root_layout, html: {NexusPhoenixWeb.Layouts, :empty}
end

pipeline :layout_auth do
  plug :put_root_layout, html: {NexusPhoenixWeb.Layouts, :auth}
end

pipeline :layout_admin do
  plug :put_root_layout, html: {NexusPhoenixWeb.Layouts, :admin}
end

scope "/", NexusPhoenixWeb do
  pipe_through [:browser, :layout_admin]
  get "/dashboard", PageController, :dashboard
end
```

Layout mapping:
- `layout_empty` -> `empty.html.heex` (landing pages)
- `layout_auth` -> `auth.html.heex` (authentication pages)
- `layout_components` -> `components.html.heex` (component showcase)
- `layout_admin` -> `admin.html.heex` (admin dashboard pages)

## Iconify Icons

Nexus uses `iconify_ex` with three icon sets: `lucide`, `heroicons-solid`, `heroicons-outline`.

**Syntax:**
```heex
<.iconify icon="lucide:sun" class="size-4" />
<.iconify icon="lucide:dollar-sign" class="text-base-content/60 size-4" />
<.iconify icon="heroicons-solid:check" class="size-5 text-success" />
```

**Icon commands:**
```bash
mix icons.install   # Download icon sets
mix icons.patch     # Patch iconify for Phoenix compatibility
```

**Common icon patterns:**
```heex
<%# In buttons %>
<button class="btn btn-primary">
  <.iconify icon="lucide:plus" class="size-4" />
  Add Item
</button>

<%# In navigation %>
<li>
  <a href="#">
    <.iconify icon="lucide:home" class="size-5" />
    Dashboard
  </a>
</li>

<%# Status indicators %>
<.iconify icon="lucide:check-circle" class="size-4 text-success" />
<.iconify icon="lucide:alert-circle" class="size-4 text-error" />
```

## Partials System

Partials are organized as separate modules in `partials.ex`, each embedding templates:

```elixir
defmodule NexusPhoenixWeb.Partials.Layouts.Sidebar do
  use NexusPhoenixWeb, :html
  embed_templates("partials/layouts/sidebar/*")
end

defmodule NexusPhoenixWeb.Partials.Layouts.Topbar do
  use NexusPhoenixWeb, :html
  embed_templates("partials/layouts/topbar/*")
end

defmodule NexusPhoenixWeb.Partials.Interactions.Carousel do
  use NexusPhoenixWeb, :html
  embed_templates("partials/interactions/carousel/*")
end
```

Each module uses `embed_templates("partials/path/*")` to load HEEx files.

**Usage in templates:**
```heex
<NexusPhoenixWeb.Partials.Layouts.Sidebar.default />
<NexusPhoenixWeb.Partials.Layouts.Topbar.main />
```

## Phoenix Functional Components

**Always prefer functional components** for reusable UI:

```elixir
attr :title, :string, required: true
attr :class, :string, default: nil
slot :inner_block, required: true

def my_card(assigns) do
  ~H"""
  <div class={["card bg-base-100 shadow-xl", @class]}>
    <div class="card-body">
      <h2 class="card-title">{@title}</h2>
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end
```

**Usage:**
```heex
<.my_card title="Dashboard">
  <p>Card content here</p>
</.my_card>
```

## Alpine.js Interactivity

**Alpine.js first** for client-side interactivity:

```heex
<%# Toggle visibility %>
<div x-data="{ open: false }">
  <button @click="open = !open" class="btn">Toggle</button>
  <div x-show="open" x-transition>Content</div>
</div>

<%# Dropdown %>
<div x-data="{ open: false }" @click.away="open = false">
  <button @click="open = !open" class="btn">Menu</button>
  <ul x-show="open" class="menu bg-base-100 shadow">
    <li><a>Item 1</a></li>
  </ul>
</div>

<%# Tab switching %>
<div x-data="{ tab: 'one' }">
  <div class="tabs">
    <button @click="tab = 'one'" :class="{ 'tab-active': tab === 'one' }" class="tab">One</button>
    <button @click="tab = 'two'" :class="{ 'tab-active': tab === 'two' }" class="tab">Two</button>
  </div>
  <div x-show="tab === 'one'">Content One</div>
  <div x-show="tab === 'two'">Content Two</div>
</div>
```

**LiveView** for real-time features - but default to standard Controller/Template rendering for static designs.

## Development Commands

```bash
mix setup              # Install deps, create DB, run migrations, setup assets, install icons
mix phx.server         # Start Phoenix server (localhost:4000)
mix precommit          # Compile (warnings-as-errors), unlock unused deps, format, test
```

## Debugging Checklist

1. **Check Tailwind/daisyUI class names** for typos
2. **Check assets watcher** - ensure `mix phx.server` is running
3. **Check dynamic classes** - Tailwind requires full class names in source code (no string interpolation)
4. **Check icon set** - ensure icon exists in installed sets (lucide, heroicons-solid, heroicons-outline)

## Common Patterns

### Dashboard Stats Card
```heex
<div class="card bg-base-100 shadow">
  <div class="card-body">
    <div class="flex items-center gap-4">
      <div class="bg-primary/10 p-3 rounded-lg">
        <.iconify icon="lucide:users" class="size-6 text-primary" />
      </div>
      <div>
        <div class="text-sm text-base-content/60">Total Users</div>
        <div class="text-2xl font-bold">12,345</div>
      </div>
    </div>
  </div>
</div>
```

### Sidebar Navigation Item
```heex
<li>
  <a href={~p"/dashboard"} class={["", @current_path == "/dashboard" && "menu-active"]}>
    <.iconify icon="lucide:layout-dashboard" class="size-5" />
    Dashboard
  </a>
</li>
```

### Data Table with Actions
```heex
<div class="overflow-x-auto">
  <table class="table">
    <thead>
      <tr>
        <th>Name</th>
        <th>Status</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <tr :for={item <- @items}>
        <td>{item.name}</td>
        <td><span class="badge badge-success">Active</span></td>
        <td>
          <button class="btn btn-ghost btn-sm">
            <.iconify icon="lucide:edit" class="size-4" />
          </button>
          <button class="btn btn-ghost btn-sm text-error">
            <.iconify icon="lucide:trash-2" class="size-4" />
          </button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```
