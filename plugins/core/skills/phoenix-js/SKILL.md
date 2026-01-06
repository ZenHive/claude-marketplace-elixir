---
name: phoenix-js
description: Phoenix JavaScript client-side patterns - hooks, JS commands, channels, presence, and optimistic UIs. Use when working with phx-hook, Phoenix.LiveView.JS, Phoenix channels, or client-server coordination.
allowed-tools: Read
---

# Phoenix JavaScript Patterns Reference

Quick reference for Phoenix client-side JavaScript patterns including LiveView hooks, JS commands, channels, presence, and optimistic UI techniques.

## When to use this skill

- Creating client hooks with `phx-hook`
- Using `Phoenix.LiveView.JS` commands
- Building optimistic UIs
- Working with Phoenix channels/sockets
- Handling server-pushed events
- Managing presence (who's online)
- DOM patching and lifecycle events
- Colocated hooks (LiveView 1.1+)
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

### Focus and Blur Events

```heex
<%# Element focus/blur %>
<input phx-focus="field_focused" phx-blur="field_blurred" />

<%# Window focus/blur (tab visibility) %>
<div phx-window-focus="user_returned" phx-window-blur="user_left">
  Content
</div>
```

### Key Events

```heex
<%# Key events on element %>
<input phx-keyup="search" phx-keydown="handle_key" />

<%# Window-level key events %>
<div phx-window-keyup="global_shortcut" phx-window-keydown="handle_global_key">
  Content
</div>

<%# Filter to specific key %>
<input phx-keydown="submit" phx-key="Enter" />
<div phx-window-keydown="escape_pressed" phx-key="Escape">Modal</div>
```

Key event payload includes key info:

```elixir
def handle_event("handle_key", %{"key" => key, "value" => value}, socket) do
  case key do
    "Enter" -> # Submit
    "Escape" -> # Cancel
    _ -> {:noreply, socket}
  end
end
```

### Debounce and Throttle

Rate-limit events to reduce server load:

```heex
<%# Debounce: Wait for pause in events (good for search) %>
<input phx-keyup="search" phx-debounce="300" />

<%# Blur debounce: Fire on blur if pending %>
<input phx-change="validate" phx-debounce="blur" />

<%# Throttle: Max one event per interval (good for scroll) %>
<div phx-scroll="scroll_position" phx-throttle="100">
  Scrollable content
</div>
```

**Debounce vs Throttle:**
- `phx-debounce="300"` - Wait 300ms after last event before firing
- `phx-debounce="blur"` - Fire immediately on blur if change pending
- `phx-throttle="100"` - Fire at most once per 100ms

## Form Bindings

### Form Events

```heex
<.form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:name]} type="text" />
  <.input field={@form[:email]} type="email" />
  <button type="submit">Save</button>
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

### Error Feedback

Errors show only after field interaction:

```heex
<%# Errors appear after user interacts with field %>
<.input field={@form[:email]} type="email" phx-feedback-for="user[email]" />
```

### Form Disable During Submit

```heex
<%# Disable button during submit %>
<button type="submit" phx-disable-with="Saving...">Save</button>
```

### Form Recovery

Forms auto-recover after disconnect/reconnect. Control with:

```heex
<%# Opt out of recovery %>
<.form for={@form} phx-auto-recover="ignore">

<%# Custom recovery handler %>
<.form for={@form} phx-auto-recover="recover_form">
```

### Triggering Form Events from JavaScript

```javascript
// Trigger phx-change
const input = document.querySelector("input")
input.dispatchEvent(new Event("input", {bubbles: true}))

// Trigger phx-submit
const form = document.querySelector("form")
form.dispatchEvent(new Event("submit", {bubbles: true, cancelable: true}))
```

## Client Hooks via phx-hook

Hooks allow client-side JavaScript to interact with LiveView elements.

### Hook Structure

```javascript
// assets/js/app.js
let Hooks = {}

Hooks.MyHook = {
  // Called when element is added to DOM
  mounted() {
    this.el              // The DOM element
    this.pushEvent       // Push event to server
    this.pushEventTo     // Push to specific component
    this.handleEvent     // Handle server-pushed events

    // Example: push event to server
    this.el.addEventListener("click", () => {
      this.pushEvent("clicked", {value: this.el.dataset.value})
    })

    // Example: handle server events
    this.handleEvent("highlight", ({id}) => {
      document.getElementById(id).classList.add("highlight")
    })
  },

  // Called when element is updated by LiveView
  updated() {
    // Re-initialize any JS state after DOM update
  },

  // Called before element is removed
  beforeDestroy() {
    // Cleanup: remove listeners, cancel timers
  },

  // Called when element is removed
  destroyed() {
    // Final cleanup
  },

  // Called when LiveView disconnects
  disconnected() {
    // Handle offline state
  },

  // Called when LiveView reconnects
  reconnected() {
    // Restore online state
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})
```

### Template Usage

```heex
<div id="my-element" phx-hook="MyHook" data-value="123">
  Hook content
</div>
```

**Requirements:**
- Element MUST have unique `id` attribute
- Hook name must match exactly (case-sensitive)
- ID must be stable across updates

### Hook Callbacks Reference

| Callback | When Called |
|----------|-------------|
| `mounted()` | Element added to DOM |
| `updated()` | Element updated by LiveView |
| `beforeUpdate()` | Before element update (access old state) |
| `beforeDestroy()` | Before element removal |
| `destroyed()` | After element removed |
| `disconnected()` | WebSocket disconnected |
| `reconnected()` | WebSocket reconnected |

### Hook Properties and Methods

```javascript
// Properties
this.el           // DOM element
this.liveSocket   // LiveSocket instance
this.viewName     // LiveView module name

// Methods
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
JS.transition("fade-in", to: "#element")
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

Chain multiple commands:

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

### Transition Options

```elixir
JS.show(
  to: "#modal",
  transition: {"ease-out duration-300", "opacity-0", "opacity-100"},
  time: 300,  # milliseconds
  display: "flex"  # CSS display value when shown
)

JS.hide(
  to: "#modal",
  transition: {"ease-in duration-200", "opacity-100", "opacity-0"},
  time: 200
)
```

### DOM Selectors

JS commands support CSS selectors:

```elixir
JS.hide(to: "#specific-id")
JS.hide(to: ".all-matching-class")
JS.hide(to: "[data-role=modal]")
JS.hide(to: {:closest, ".parent"})    # Closest ancestor
JS.hide(to: {:inner, "#container"})   # All descendants
```

## Server-Pushed Events

Push events from server to specific client hooks.

### Server Side

```elixir
# In LiveView
def handle_event("save", params, socket) do
  # Push event to client
  {:noreply, push_event(socket, "saved", %{id: 123})}
end

# Push to specific component
def handle_event("save", params, socket) do
  {:noreply, push_event(socket, "highlight", %{id: id}, to: "#my-component")}
end
```

### Client Side

```javascript
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

LiveView automatically manages loading classes:

```heex
<%# phx-click-loading added during server round-trip %>
<button phx-click="save" class="phx-click-loading:opacity-50">
  Save
</button>

<%# Form submission loading %>
<.form phx-submit="create" class="phx-submit-loading:pointer-events-none">
  <button class="phx-submit-loading:animate-pulse">Submit</button>
</.form>
```

**Available loading classes:**
- `phx-click-loading` - During click event
- `phx-submit-loading` - During form submit
- `phx-change-loading` - During form change
- `phx-page-loading` - During navigation

### Via JS Commands

Immediate UI feedback before server response:

```heex
<button
  phx-click={JS.add_class("saving") |> JS.push("save")}
  class="saving:opacity-50"
>
  Save
</button>
```

### Via Hooks

Full control with JavaScript:

```javascript
Hooks.OptimisticDelete = {
  mounted() {
    this.el.addEventListener("click", () => {
      // Immediately hide
      this.el.closest("tr").style.opacity = "0.5"

      // Push to server
      this.pushEvent("delete", {id: this.el.dataset.id}, (reply) => {
        if (reply.error) {
          // Revert on error
          this.el.closest("tr").style.opacity = "1"
        }
      })
    })
  }
}
```

## Phoenix Channels (Non-LiveView)

For real-time features outside LiveView.

### Client Setup

```javascript
import {Socket} from "phoenix"

let socket = new Socket("/socket", {
  params: {token: userToken}
})
socket.connect()

let channel = socket.channel("room:lobby", {})

// Join channel
channel.join()
  .receive("ok", resp => console.log("Joined!", resp))
  .receive("error", resp => console.log("Failed", resp))

// Listen for events
channel.on("new_msg", payload => {
  console.log("New message:", payload.body)
})

// Push events
channel.push("new_msg", {body: "Hello!"})
  .receive("ok", resp => console.log("Sent"))
  .receive("error", resp => console.log("Error", resp))
  .receive("timeout", () => console.log("Timeout"))
```

### Channel Lifecycle

```javascript
channel.onError(() => console.log("Channel error"))
channel.onClose(() => console.log("Channel closed"))

// Leave channel
channel.leave()
  .receive("ok", () => console.log("Left channel"))
```

## Presence

Track who's online in real-time.

### Client Setup

```javascript
import {Presence} from "phoenix"

let presence = new Presence(channel)

// Track all presence changes
presence.onSync(() => {
  renderUsers(presence.list())
})

// Individual join/leave
presence.onJoin((id, current, newPres) => {
  if (!current) {
    console.log("User joined:", id)
  }
})

presence.onLeave((id, current, leftPres) => {
  if (current.metas.length === 0) {
    console.log("User left:", id)
  }
})

// List with custom selector
let users = presence.list((id, {metas: [first, ...rest]}) => {
  return {id, name: first.name, count: rest.length + 1}
})
```

## Colocated Hooks (LiveView 1.1+)

Define hooks alongside your LiveView/Component.

### Basic Usage

```elixir
defmodule MyAppWeb.ChartLive do
  use Phoenix.LiveView
  use Phoenix.LiveView.ColocatedHook

  @colocated_hook """
  export default {
    mounted() {
      this.chart = new Chart(this.el, this.el.dataset)
    },
    updated() {
      this.chart.update(this.el.dataset)
    },
    destroyed() {
      this.chart.destroy()
    }
  }
  """

  def render(assigns) do
    ~H"""
    <canvas id="chart" phx-hook={@colocated_hook} data-values={Jason.encode!(@values)} />
    """
  end
end
```

### With Options

```elixir
use Phoenix.LiveView.ColocatedHook,
  name: "MyChart",           # Custom hook name
  imports: ["chart.js"]      # Additional imports
```

## DOM Patching

Control how LiveView patches the DOM.

### phx-update Modes

```heex
<%# Default: Replace entire container %>
<div id="list">...</div>

<%# Stream: Efficient list updates %>
<div id="items" phx-update="stream">
  <div :for={{id, item} <- @streams.items} id={id}>
    {item.name}
  </div>
</div>

<%# Ignore: Never update this element %>
<div id="static" phx-update="ignore">
  Content managed by JS
</div>
```

### Lifecycle Events

```javascript
// Listen for LiveView lifecycle
window.addEventListener("phx:page-loading-start", info => {
  // Show loading indicator
})

window.addEventListener("phx:page-loading-stop", info => {
  // Hide loading indicator
})

// Element lifecycle
element.addEventListener("phx:mounted", e => {
  // Element was mounted by LiveView
})

element.addEventListener("phx:updated", e => {
  // Element was updated
})
```

### Custom Events

```javascript
// Listen for custom dispatched events
window.addEventListener("my:event", e => {
  console.log(e.detail)  // Data from JS.dispatch
})
```

## Debugging

### Enable Debug Mode

```javascript
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
  // Enable debug logging
  logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data) }
})

// Or enable in browser console
liveSocket.enableDebug()
```

### Simulate Latency

```javascript
// In browser console - add 1000ms latency
liveSocket.enableLatencySim(1000)

// Disable
liveSocket.disableLatencySim()
```

## Common Patterns

### Modal with Focus Trap

```elixir
def show_modal(js \\ %JS{}, id) do
  js
  |> JS.show(to: "##{id}")
  |> JS.show(to: "##{id}-backdrop", transition: "fade-in")
  |> JS.push_focus()
  |> JS.focus_first(to: "##{id}-content")
end

def hide_modal(js \\ %JS{}, id) do
  js
  |> JS.hide(to: "##{id}-backdrop", transition: "fade-out")
  |> JS.hide(to: "##{id}", transition: "fade-out-scale")
  |> JS.pop_focus()
end
```

### Dropdown Toggle

```heex
<div class="relative">
  <button
    phx-click={JS.toggle(to: "#dropdown")}
    phx-click-away={JS.hide(to: "#dropdown")}
  >
    Menu
  </button>
  <div id="dropdown" class="hidden absolute">
    <%# Dropdown content %>
  </div>
</div>
```

### Flash Message Auto-Dismiss

```javascript
Hooks.Flash = {
  mounted() {
    this.timer = setTimeout(() => {
      this.pushEvent("lv:clear-flash", {key: this.el.dataset.key})
    }, 5000)
  },
  destroyed() {
    clearTimeout(this.timer)
  }
}
```

### Copy to Clipboard

```javascript
Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.value
      navigator.clipboard.writeText(text).then(() => {
        this.pushEvent("copied", {})
      })
    })
  }
}
```

### Infinite Scroll

```javascript
Hooks.InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) {
        this.pushEvent("load-more", {})
      }
    })
    this.observer.observe(this.el)
  },
  destroyed() {
    this.observer.disconnect()
  }
}
```

```heex
<div id="items" phx-update="stream">
  <div :for={{id, item} <- @streams.items} id={id}>{item.name}</div>
</div>
<div id="infinite-scroll-trigger" phx-hook="InfiniteScroll" />
```

## phx-* Attributes Quick Reference

### Event Handlers

| Attribute | Description |
|-----------|-------------|
| `phx-click` | Handle click events |
| `phx-click-away` | Handle clicks outside element |
| `phx-blur` | Handle element blur |
| `phx-focus` | Handle element focus |
| `phx-keydown` | Handle keydown events |
| `phx-keyup` | Handle keyup events |
| `phx-key` | Filter key events to specific key |
| `phx-window-blur` | Handle window blur (tab hidden) |
| `phx-window-focus` | Handle window focus (tab visible) |
| `phx-window-keydown` | Handle global keydown |
| `phx-window-keyup` | Handle global keyup |
| `phx-viewport-top` | Element enters viewport from top |
| `phx-viewport-bottom` | Element enters viewport from bottom |

### Form Attributes

| Attribute | Description |
|-----------|-------------|
| `phx-change` | Handle form input changes |
| `phx-submit` | Handle form submission |
| `phx-feedback-for` | Show errors after field interaction |
| `phx-disable-with` | Button text during submission |
| `phx-trigger-action` | Submit form via HTTP after event |
| `phx-auto-recover` | Control form recovery behavior |

### Event Modifiers

| Attribute | Description |
|-----------|-------------|
| `phx-value-*` | Pass values to event handler |
| `phx-target` | Target specific LiveView/Component |
| `phx-debounce` | Debounce events (ms or "blur") |
| `phx-throttle` | Throttle events (ms) |

### DOM Control

| Attribute | Description |
|-----------|-------------|
| `phx-update` | Control DOM patching ("stream", "ignore") |
| `phx-hook` | Attach JavaScript hook |
| `phx-mounted` | JS commands on mount |
| `phx-remove` | JS commands on remove |

### Connection Lifecycle

| Attribute | Description |
|-----------|-------------|
| `phx-connected` | Class added when connected |
| `phx-loading` | Class added during loading |
| `phx-disconnected` | Element shown when disconnected |

### Loading State Classes

Applied automatically during server round-trips:

| Class | Applied When |
|-------|--------------|
| `phx-click-loading` | During click event |
| `phx-submit-loading` | During form submit |
| `phx-change-loading` | During form change |
| `phx-page-loading` | During navigation |
