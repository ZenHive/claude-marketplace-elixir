---
name: daisyui
description: daisyUI 5 + Tailwind CSS v4 component patterns for Phoenix LiveView. Use when styling forms, buttons, modals, cards, or any UI component with daisyUI classes. Covers semantic color system, theme configuration, HEEx component styling, and responsive patterns.
allowed-tools: Read, WebFetch
---

<!-- Auto-synced from ~/.claude/includes/daisyui.md — do not edit manually -->

## daisyUI 5 + Tailwind CSS v4

This project uses **daisyUI 5** on **Tailwind CSS v4**.

### Getting Code Snippets

Use the **daisyUI MCP server** (`daisyUI-Snippets` tool) for complete component examples, layout templates, and theme configurations beyond this quick reference.

### Setup (No tailwind.config.js)

Tailwind v4 uses CSS-based configuration. A minimal setup:

```css
@import "tailwindcss";
@plugin "daisyui";
```

With theme config:
```css
@plugin "daisyui" {
  themes: light --default, dark --prefersdark;
  logs: false;
}
```

### Core Rules

1. **Use daisyUI semantic colors** (`primary`, `base-100`, `error`) instead of Tailwind colors (`red-500`, `gray-800`)
2. **No `dark:` prefix needed** - daisyUI colors adapt to theme automatically
3. **Override with `!` suffix** for specificity issues (e.g., `bg-red-500!`) - last resort only
4. **No `@apply` in CSS** - write Tailwind classes directly in templates
5. **No custom CSS needed** - use daisyUI classes + Tailwind utilities
6. **Responsive layout** - use Tailwind responsive prefixes (`sm:`, `lg:`) with daisyUI

### Color System

**Semantic colors** (change with theme):
- `primary`, `primary-content` - Main brand color
- `secondary`, `secondary-content` - Secondary brand color
- `accent`, `accent-content` - Accent color
- `neutral`, `neutral-content` - Unsaturated UI parts
- `base-100`, `base-200`, `base-300`, `base-content` - Surface colors
- `info`, `success`, `warning`, `error` + their `-content` variants

**Usage rules:**
- Use `base-*` colors for majority of page, `primary` for important elements
- Never use Tailwind colors for text on daisyUI backgrounds (e.g., `text-gray-800` on `bg-base-100` is unreadable in dark theme)
- `-content` colors provide proper contrast on their associated colors

### Component Pattern

daisyUI components use this structure:
```html
<div class="component modifier-1 modifier-2">
  <div class="component-part">...</div>
</div>
```

Class types:
- **component**: Required base class (`btn`, `card`, `modal`)
- **part**: Child elements (`card-body`, `modal-box`)
- **style**: Visual variants (`btn-outline`, `card-bordered`)
- **color**: Color variants (`btn-primary`, `alert-error`)
- **size**: Size variants (`btn-sm`, `input-lg`)
- **modifier**: Behavior/layout (`btn-wide`, `modal-open`)

### Common Components Quick Reference

**Buttons:**
```html
<button class="btn btn-primary btn-sm">Click</button>
<button class="btn btn-outline btn-error">Delete</button>
```
Colors: `btn-neutral`, `btn-primary`, `btn-secondary`, `btn-accent`, `btn-info`, `btn-success`, `btn-warning`, `btn-error`
Styles: `btn-outline`, `btn-dash`, `btn-soft`, `btn-ghost`, `btn-link`
Sizes: `btn-xs`, `btn-sm`, `btn-md`, `btn-lg`, `btn-xl`

**Cards:**
```html
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Title</h2>
    <p>Content</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>
```

**Forms:**
```html
<input type="text" class="input input-bordered" placeholder="Type here" />
<select class="select select-bordered">
  <option>Option</option>
</select>
<textarea class="textarea textarea-bordered"></textarea>
```

**Modals (HTML dialog):**
```html
<button onclick="my_modal.showModal()">Open</button>
<dialog id="my_modal" class="modal">
  <div class="modal-box">
    <h3 class="text-lg font-bold">Title</h3>
    <p>Content</p>
  </div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
</dialog>
```

**Dropdowns (popover API):**
```html
<button popovertarget="dropdown1" style="anchor-name:--dropdown1">Click</button>
<ul class="dropdown-content menu" popover id="dropdown1" style="position-anchor:--dropdown1">
  <li><a>Item 1</a></li>
</ul>
```

**Alerts:**
```html
<div role="alert" class="alert alert-info">
  <span>Info message</span>
</div>
```

**Tables:**
```html
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Name</th></tr></thead>
    <tbody><tr><td>Value</td></tr></tbody>
  </table>
</div>
```

**Loading:**
```html
<span class="loading loading-spinner loading-md"></span>
```

**Badges:**
```html
<span class="badge badge-primary">New</span>
```

**Menu:**
```html
<ul class="menu bg-base-200 w-56">
  <li><a>Item 1</a></li>
  <li><a class="menu-active">Active</a></li>
</ul>
```

**Drawer:**
```html
<div class="drawer lg:drawer-open">
  <input id="my-drawer" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content">
    <label for="my-drawer" class="btn drawer-button lg:hidden">Open</label>
    <!-- Page content -->
  </div>
  <div class="drawer-side">
    <label for="my-drawer" class="drawer-overlay"></label>
    <ul class="menu bg-base-200 w-80 min-h-full">
      <li><a>Sidebar Item</a></li>
    </ul>
  </div>
</div>
```

### Responsive Patterns

Use Tailwind responsive prefixes with daisyUI:
```html
<div class="stats stats-vertical lg:stats-horizontal">
<ul class="menu menu-vertical lg:menu-horizontal">
<div class="drawer lg:drawer-open">
```

### Theme Switching

```html
<input type="checkbox" value="dark" class="theme-controller" />
```

Or set theme on HTML element:
```html
<html data-theme="dark">
```

### Full Component Docs

For complete component reference: https://daisyui.com/components/
