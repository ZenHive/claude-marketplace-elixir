---
name: daisyui
description: daisyUI 5 + Tailwind CSS v4 component library reference. Use when building UI with daisyUI components, semantic colors, theming, or component patterns.
allowed-tools: Read, WebFetch
---

# daisyUI 5 + Tailwind CSS v4 Reference

Complete reference for daisyUI 5 on Tailwind CSS v4. daisyUI provides semantic component class names for common UI patterns.

## When to use this skill

- Building UI with daisyUI components
- Understanding semantic color system
- Configuring themes
- Component syntax and modifiers
- Debugging styling issues

## Getting Code Snippets

Use the **daisyUI MCP server** (`daisyUI-Snippets` tool) for:
- Complete component code examples beyond this quick reference
- Layout templates (bento grids, sidebars, navbars)
- Full theme configurations
- Component variations and examples

This skill provides concepts and patterns; the MCP provides extensive code snippets.

## Setup (No tailwind.config.js)

Tailwind v4 uses CSS-based configuration:

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

## Core Rules

1. **Use daisyUI semantic colors** (`primary`, `base-100`, `error`) instead of Tailwind colors (`red-500`, `gray-800`)
2. **No `dark:` prefix needed** - daisyUI colors adapt to theme automatically
3. **Override with `!` suffix** for specificity issues (e.g., `bg-red-500!`) - last resort only
4. **No `@apply` in CSS** - write Tailwind classes directly in templates
5. **No custom CSS needed** - use daisyUI classes + Tailwind utilities
6. **Responsive layout** - use Tailwind responsive prefixes (`sm:`, `lg:`) with daisyUI

## Color System

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

## Component Pattern

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

## Common Components Quick Reference

### Buttons
```html
<button class="btn btn-primary btn-sm">Click</button>
<button class="btn btn-outline btn-error">Delete</button>
<button class="btn btn-ghost">Ghost</button>
```
Colors: `btn-neutral`, `btn-primary`, `btn-secondary`, `btn-accent`, `btn-info`, `btn-success`, `btn-warning`, `btn-error`
Styles: `btn-outline`, `btn-dash`, `btn-soft`, `btn-ghost`, `btn-link`
Sizes: `btn-xs`, `btn-sm`, `btn-md`, `btn-lg`, `btn-xl`
Modifiers: `btn-wide`, `btn-block`, `btn-square`, `btn-circle`

### Cards
```html
<div class="card bg-base-100 shadow-xl">
  <figure><img src="..." alt="..." /></figure>
  <div class="card-body">
    <h2 class="card-title">Title</h2>
    <p>Content</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>
```
Styles: `card-border`, `card-dash`
Sizes: `card-xs`, `card-sm`, `card-md`, `card-lg`, `card-xl`
Modifiers: `card-side`, `image-full`

### Form Inputs
```html
<input type="text" class="input input-bordered" placeholder="Type here" />
<select class="select select-bordered">
  <option>Option</option>
</select>
<textarea class="textarea textarea-bordered"></textarea>
<input type="checkbox" class="checkbox checkbox-primary" />
<input type="radio" class="radio radio-primary" name="group" />
<input type="checkbox" class="toggle toggle-primary" />
```

### Modals (HTML dialog)
```html
<button onclick="my_modal.showModal()">Open</button>
<dialog id="my_modal" class="modal">
  <div class="modal-box">
    <h3 class="text-lg font-bold">Title</h3>
    <p>Content</p>
    <div class="modal-action">
      <form method="dialog"><button class="btn">Close</button></form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
</dialog>
```

### Dropdowns (popover API)
```html
<button popovertarget="dropdown1" style="anchor-name:--dropdown1">Click</button>
<ul class="dropdown-content menu" popover id="dropdown1" style="position-anchor:--dropdown1">
  <li><a>Item 1</a></li>
</ul>
```

### Alerts
```html
<div role="alert" class="alert alert-info">
  <span>Info message</span>
</div>
```
Colors: `alert-info`, `alert-success`, `alert-warning`, `alert-error`
Styles: `alert-outline`, `alert-dash`, `alert-soft`

### Tables
```html
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Name</th></tr></thead>
    <tbody><tr><td>Value</td></tr></tbody>
  </table>
</div>
```
Modifiers: `table-zebra`, `table-pin-rows`, `table-pin-cols`
Sizes: `table-xs`, `table-sm`, `table-md`, `table-lg`, `table-xl`

### Loading
```html
<span class="loading loading-spinner loading-md"></span>
```
Styles: `loading-spinner`, `loading-dots`, `loading-ring`, `loading-ball`, `loading-bars`, `loading-infinity`

### Badges
```html
<span class="badge badge-primary">New</span>
```
Styles: `badge-outline`, `badge-dash`, `badge-soft`, `badge-ghost`
Colors: `badge-neutral`, `badge-primary`, `badge-secondary`, `badge-accent`, `badge-info`, `badge-success`, `badge-warning`, `badge-error`

### Menu
```html
<ul class="menu bg-base-200 w-56">
  <li><a>Item 1</a></li>
  <li><a class="menu-active">Active</a></li>
</ul>
```
Direction: `menu-vertical`, `menu-horizontal`
Sizes: `menu-xs`, `menu-sm`, `menu-md`, `menu-lg`, `menu-xl`

### Drawer
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

### Stats
```html
<div class="stats shadow">
  <div class="stat">
    <div class="stat-title">Total Users</div>
    <div class="stat-value">89,400</div>
    <div class="stat-desc">21% more than last month</div>
  </div>
</div>
```

### Tabs
```html
<div role="tablist" class="tabs tabs-box">
  <button role="tab" class="tab">Tab 1</button>
  <button role="tab" class="tab tab-active">Tab 2</button>
</div>
```
Styles: `tabs-box`, `tabs-border`, `tabs-lift`

## Responsive Patterns

Use Tailwind responsive prefixes with daisyUI:
```html
<div class="stats stats-vertical lg:stats-horizontal">
<ul class="menu menu-vertical lg:menu-horizontal">
<div class="drawer lg:drawer-open">
<div class="card sm:card-side">
```

## Theme Switching

```html
<input type="checkbox" value="dark" class="theme-controller" />
```

Or set theme on HTML element:
```html
<html data-theme="dark">
```

## Custom Theme

```css
@plugin "daisyui/theme" {
  name: "mytheme";
  default: true;
  prefersdark: false;
  color-scheme: light;

  --color-base-100: oklch(98% 0.02 240);
  --color-base-200: oklch(95% 0.03 240);
  --color-base-300: oklch(92% 0.04 240);
  --color-base-content: oklch(20% 0.05 240);
  --color-primary: oklch(55% 0.3 240);
  --color-primary-content: oklch(98% 0.01 240);
  /* ... other colors ... */

  --radius-selector: 1rem;
  --radius-field: 0.25rem;
  --radius-box: 0.5rem;

  --size-selector: 0.25rem;
  --size-field: 0.25rem;

  --border: 1px;
  --depth: 1;
  --noise: 0;
}
```

## Full Documentation

For complete component reference: https://daisyui.com/components/
