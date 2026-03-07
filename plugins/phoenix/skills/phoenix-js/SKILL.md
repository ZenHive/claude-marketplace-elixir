---
name: phoenix-js
description: Phoenix JavaScript client-side patterns — LiveView hooks (phx-hook), JS commands (Phoenix.LiveView.JS), channels, presence tracking, and optimistic UIs. Use when adding client-side interactivity, handling phx-hook lifecycle, coordinating client-server events, or implementing real-time features.
allowed-tools: Read
---

# Phoenix JavaScript Patterns Reference

Quick reference for Phoenix client-side JavaScript patterns including LiveView hooks, JS commands, and optimistic UI techniques.

## When to use this skill

- Creating client hooks with `phx-hook`
- Using `Phoenix.LiveView.JS` commands
- Building optimistic UIs
- Working with Phoenix channels/sockets
- Handling server-pushed events
- Managing presence (who's online)
- DOM patching and lifecycle events
- Event bindings (click, focus, key, form events)
- Rate limiting with debounce/throttle

## Event Bindings

LiveView bindings connect DOM events to server-side handlers.

### Click Events

```heex
<%# Basic click %>
<button phx-click="increment">+1</button>

<%# Click with value %>
<button phx-click="delete" phx-value-id={@item.id}>Delete</button>

<%# Multiple values %>
<button phx-click="move" phx-value-id={@id} phx-value-direction="up">Move Up</button>

<%# Target specific component %>
<button phx-click="save" phx-target={@myself}>Save</button>

<%# Click away (close on outside click) %>
<div phx-click-away="close_dropdown">Dropdown content</div>
```

Server handler receives values as string map:

```elixir
def handle_event("delete", %{"id" => id}, socket) do
  # id is a string, convert if needed
  {:noreply, socket}
end
```

### Focus, Blur, and Key Events

```heex
<%# Element focus/blur %>
<input phx-focus="field_focused" phx-blur="field_blurred" />

<%# Window focus/blur (tab visibility) %>
<div phx-window-focus="user_returned" phx-window-blur="user_left">Content</div>

<%# Key events on element %>
<input phx-keyup="search" phx-keydown="handle_key" />

<%# Filter to specific key %>
<input phx-keydown="submit" phx-key="Enter" />
<div phx-window-keydown="escape_pressed" phx-key="Escape">Modal</div>
```

### Debounce and Throttle

```heex
<%# Debounce: Wait for pause in events (good for search) %>
<input phx-keyup="search" phx-debounce="300" />

<%# Blur debounce: Fire on blur if pending %>
<input phx-change="validate" phx-debounce="blur" />

<%# Throttle: Max one event per interval (good for scroll) %>
<div phx-scroll="scroll_position" phx-throttle="100">Scrollable content</div>
```

- `phx-debounce="300"` - Wait 300ms after last event before firing
- `phx-debounce="blur"` - Fire immediately on blur if change pending
- `phx-throttle="100"` - Fire at most once per 100ms

## Form Bindings

```heex
<.form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:name]} type="text" />
  <.input field={@form[:email]} type="email" />
  <button type="submit" phx-disable-with="Saving...">Save</button>
</.form>
```

```elixir
def handle_event("validate", %{"user" => params}, socket) do
  changeset = User.changeset(%User{}, params) |> Map.put(:action, :validate)
  {:noreply, assign(socket, form: to_form(changeset))}
end

def handle_event("save", %{"user" => params}, socket) do
  case Users.create(params) do
    {:ok, user} -> {:noreply, push_navigate(socket, to: ~p"/users/#{user}")}
    {:error, changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

Form recovery: `phx-auto-recover="ignore"` or `phx-auto-recover="recover_form"`.

## Client Hooks via phx-hook

Hooks allow client-side JavaScript to interact with LiveView elements.

### Hook Structure

```javascript
// assets/js/app.js
let Hooks = {}

Hooks.MyHook = {
  mounted() {
    this.el              // The DOM element
    this.pushEvent       // Push event to server
    this.pushEventTo     // Push to specific component
    this.handleEvent     // Handle server-pushed events

    this.el.addEventListener("click", () => {
      this.pushEvent("clicked", {value: this.el.dataset.value})
    })

    this.handleEvent("highlight", ({id}) => {
      document.getElementById(id).classList.add("highlight")
    })
  },
  updated() { /* Re-initialize after DOM update */ },
  beforeDestroy() { /* Cleanup: remove listeners, cancel timers */ },
  destroyed() { /* Final cleanup */ },
  disconnected() { /* Handle offline state */ },
  reconnected() { /* Restore online state */ }
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})
```

**Requirements:** Element MUST have unique `id` attribute. Hook name must match exactly (case-sensitive).

### Hook Properties and Methods

```javascript
this.el           // DOM element
this.liveSocket   // LiveSocket instance
this.viewName     // LiveView module name

this.pushEvent(event, payload, callback)
this.pushEventTo(selector, event, payload, callback)
this.handleEvent(event, callback)
this.upload(name, files)
this.uploadTo(selector, name, files)
```

### Push with Reply

```javascript
this.pushEvent("validate", {data: value}, (reply, ref) => {
  if (reply.valid) {
    this.el.classList.add("valid")
  } else {
    this.el.classList.add("invalid")
  }
})
```

## Phoenix.LiveView.JS Commands

Client-side commands that run without server round-trip.

### Quick Reference

```elixir
# Show/Hide/Toggle
JS.show(to: "#modal")
JS.hide(to: "#modal", transition: "fade-out")
JS.toggle(to: "#dropdown")

# Classes
JS.add_class("active", to: "#tab")
JS.remove_class("active", to: "#tab")
JS.toggle_class("open", to: "#menu")

# Attributes
JS.set_attribute({"aria-expanded", "true"}, to: "#dropdown")
JS.remove_attribute("disabled", to: "#button")
JS.toggle_attribute({"aria-hidden", "true", "false"}, to: "#panel")

# Push event to server
JS.push("save", value: %{id: @item.id})
JS.push("delete", target: "#component-id")

# Navigation
JS.navigate(~p"/users/#{@user}")
JS.patch(~p"/users?page=2")

# Focus
JS.focus(to: "#input")
JS.focus_first(to: "#modal")
JS.push_focus()
JS.pop_focus()

# Transitions
JS.transition({"fade-in", "opacity-0", "opacity-100"}, to: "#el")

# Dispatch custom event
JS.dispatch("click", to: "#button")
JS.dispatch("my-event", detail: %{foo: "bar"})

# Run stored JS from data attribute
JS.exec("data-cancel", to: "#modal")

# Ignore attributes during patching (v1.1+)
JS.ignore_attributes(["class"], to: "#animated")
```

### Composing Commands

```elixir
def hide_modal(js \\ %JS{}) do
  js
  |> JS.hide(to: "#modal", transition: "fade-out")
  |> JS.hide(to: "#modal-backdrop")
  |> JS.pop_focus()
end

# In template
<button phx-click={hide_modal()}>Close</button>
<button phx-click={JS.push("save") |> hide_modal()}>Save & Close</button>
```

### DOM Selectors

```elixir
JS.hide(to: "#specific-id")
JS.hide(to: ".all-matching-class")
JS.hide(to: "[data-role=modal]")
JS.hide(to: {:closest, ".parent"})    # Closest ancestor
JS.hide(to: {:inner, "#container"})   # All descendants
```

## Server-Pushed Events

```elixir
# Server side - push event to client hooks
def handle_event("save", params, socket) do
  {:noreply, push_event(socket, "saved", %{id: 123})}
end
```

```javascript
// Client side - receive in hook
Hooks.MyHook = {
  mounted() {
    this.handleEvent("saved", ({id}) => {
      console.log("Item saved:", id)
      this.el.classList.add("saved")
    })
  }
}
```

## Optimistic UIs

### Via Loading Classes

```heex
<%# phx-click-loading added during server round-trip %>
<button phx-click="save" class="phx-click-loading:opacity-50">Save</button>

<%# Form submission loading %>
<.form phx-submit="create" class="phx-submit-loading:pointer-events-none">
  <button class="phx-submit-loading:animate-pulse">Submit</button>
</.form>
```

Available: `phx-click-loading`, `phx-submit-loading`, `phx-change-loading`, `phx-page-loading`.

### Via Hooks (Full Control)

```javascript
Hooks.OptimisticDelete = {
  mounted() {
    this.el.addEventListener("click", () => {
      this.el.closest("tr").style.opacity = "0.5"
      this.pushEvent("delete", {id: this.el.dataset.id}, (reply) => {
        if (reply.error) {
          this.el.closest("tr").style.opacity = "1"
        }
      })
    })
  }
}
```

## References

For detailed patterns and advanced techniques, consult:

- **`references/channels-presence.md`** - Phoenix Channels (non-LiveView real-time) and Presence tracking
- **`references/advanced-patterns.md`** - Colocated Hooks (LiveView 1.1+), DOM patching, debugging, and common patterns (modal, dropdown, flash, clipboard, infinite scroll)
- **`references/attributes-reference.md`** - Complete phx-* attributes quick reference tables
