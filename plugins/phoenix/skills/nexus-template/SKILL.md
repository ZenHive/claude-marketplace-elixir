---
name: nexus-template
description: Nexus Phoenix admin dashboard template. Use when building admin interfaces with Nexus, adding Iconify icons, creating layout pipelines, implementing partials, or adding Alpine.js interactivity. Covers Nexus architecture, routing, component organization, and theme configuration.
allowed-tools: Read
---

<!-- Auto-synced from ~/.claude/includes/nexus-template.md — do not edit manually -->

## Nexus Phoenix Admin Template

Nexus is an admin dashboard template built on Phoenix 1.8 with daisyUI 5, Tailwind CSS v4, and Iconify icons.

### Architecture

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

### Routing & Layouts

The router uses layout pipelines to select different root layouts:
- `layout_empty` -> `empty.html.heex` (landing pages)
- `layout_auth` -> `auth.html.heex` (authentication pages)
- `layout_components` -> `components.html.heex` (component showcase)
- `layout_admin` -> `admin.html.heex` (admin dashboard pages)

### Iconify Icons

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

### Partials System

Partials are organized as separate modules in `partials.ex`, each embedding templates:
- `NexusPhoenixWeb.Partials.Layouts.Sidebar`
- `NexusPhoenixWeb.Partials.Layouts.Topbar`
- `NexusPhoenixWeb.Partials.Interactions.Carousel`

Each module uses `embed_templates("partials/path/*")` to load HEEx files.

### Phoenix Functional Components

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

### Interactivity

**Alpine.js first** for client-side interactivity:
```heex
<div x-data="{ open: false }">
  <button @click="open = !open">Toggle</button>
  <div x-show="open">Content</div>
</div>
```

**LiveView** for real-time features - but default to standard Controller/Template rendering for static designs.

### Development Commands

```bash
mix setup              # Install deps, create DB, run migrations, setup assets, install icons
mix phx.server         # Start Phoenix server (localhost:4000)
mix precommit          # Compile (warnings-as-errors), unlock unused deps, format, test
```

### Debugging Checklist

1. **Check Tailwind/daisyUI class names** for typos
2. **Check assets watcher** - ensure `mix phx.server` is running
3. **Check dynamic classes** - Tailwind requires full class names in source code (no string interpolation)
4. **Check icon set** - ensure icon exists in installed sets (lucide, heroicons-solid, heroicons-outline)
