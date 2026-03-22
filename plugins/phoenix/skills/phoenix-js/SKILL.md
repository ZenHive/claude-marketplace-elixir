---
name: phoenix-js
description: Phoenix JavaScript client-side patterns — LiveView hooks (phx-hook), JS commands (Phoenix.LiveView.JS), channels, presence tracking, and optimistic UIs. Use when adding client-side interactivity, handling phx-hook lifecycle, coordinating client-server events, or implementing real-time features.
allowed-tools: Read
---

<!-- Auto-synced from ~/.claude/includes/phoenix-js.md — do not edit manually -->

## Phoenix LiveView Client-Side JavaScript

### Client Hooks (phx-hook)

```javascript
// assets/js/app.js
let Hooks = {}

Hooks.MyHook = {
  mounted() {
    this.el              // DOM element
    this.pushEvent       // Push event to server
    this.pushEventTo     // Push to specific component
    this.handleEvent     // Handle server-pushed events
    this.upload          // Upload files
    this.liveSocket      // LiveSocket instance

    this.el.addEventListener("click", () => {
      this.pushEvent("clicked", {value: this.el.dataset.value})
    })

    this.handleEvent("highlight", ({id}) => {
      document.getElementById(id).classList.add("highlight")
    })
  },
  updated() { },        // Element updated by LiveView
  beforeDestroy() { },  // Before removal (cleanup timers/listeners)
  destroyed() { },      // Element removed
  disconnected() { },   // WebSocket disconnected
  reconnected() { }     // WebSocket reconnected
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})
```

```heex
<%# Element MUST have unique id %>
<div id="my-element" phx-hook="MyHook" data-value="123">
  Hook content
</div>
```

**Push with reply:**
```javascript
this.pushEvent("validate", {data: value}, (reply, ref) => {
  if (reply.valid) this.el.classList.add("valid")
  else this.el.classList.add("invalid")
})
```

### JS Commands (No Server Round-Trip)

```elixir
# Show/Hide/Toggle
JS.show(to: "#modal")
JS.hide(to: "#modal", transition: "fade-out")
JS.toggle(to: "#dropdown")

# Classes
JS.add_class("active", to: "#tab")
JS.remove_class("active", to: "#tab")
JS.toggle_class("open", to: "#menu")

# Push event to server
JS.push("save", value: %{id: @item.id})
JS.push("delete", target: "#component-id")

# Navigation
JS.navigate(~p"/users/#{@user}")
JS.patch(~p"/users?page=2")

# Focus management
JS.focus(to: "#input")
JS.focus_first(to: "#modal")
JS.push_focus()
JS.pop_focus()

# Attributes (v1.1+)
JS.set_attribute({"aria-expanded", "true"}, to: "#menu")
JS.remove_attribute("disabled", to: "#btn")
JS.toggle_attribute({"aria-hidden", "true", "false"}, to: "#panel")
JS.ignore_attributes(["style", "class"], to: "#chart")  # prevent LV patching

# Transitions
JS.transition({"fade-in", "opacity-0", "opacity-100"}, to: "#el")

# Dispatch custom event
JS.dispatch("click", to: "#button")
JS.dispatch("my-event", detail: %{foo: "bar"})

# Run stored JS from data attribute
JS.exec("data-cancel", to: "#modal")
```

**DOM selectors:**
```elixir
JS.hide(to: "#id")                    # By ID
JS.hide(to: ".class")                 # By class
JS.hide(to: "[data-role=modal]")      # By attribute
JS.hide(to: {:closest, ".parent"})    # Closest ancestor
JS.hide(to: {:inner, "#container"})   # All descendants
```

**Composing commands:**
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

### Event Bindings

```heex
<%# Click with values %>
<button phx-click="delete" phx-value-id={@item.id}>Delete</button>
<button phx-click="save" phx-target={@myself}>Save</button>

<%# Click away (close on outside click) %>
<div phx-click-away="close_dropdown">Dropdown</div>

<%# Focus/blur %>
<input phx-focus="field_focused" phx-blur="field_blurred" />
<div phx-window-focus="user_returned" phx-window-blur="user_left">Content</div>

<%# Key events %>
<input phx-keyup="search" phx-keydown="handle_key" />
<input phx-keydown="submit" phx-key="Enter" />
<div phx-window-keydown="escape" phx-key="Escape">Modal</div>

<%# Debounce/Throttle %>
<input phx-keyup="search" phx-debounce="300" />
<input phx-change="validate" phx-debounce="blur" />
<div phx-scroll="scroll_pos" phx-throttle="100">Scrollable</div>
```

- `phx-debounce="300"` — Wait 300ms after last event before firing
- `phx-debounce="blur"` — Fire immediately on blur if change pending
- `phx-throttle="100"` — Fire at most once per 100ms

### Form Bindings

```heex
<.form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:name]} type="text" />
  <button type="submit" phx-disable-with="Saving...">Save</button>
</.form>
```

Form recovery: `phx-auto-recover="ignore"` or `phx-auto-recover="recover_form"`.

### Loading State Classes

Applied automatically during server round-trips:

```heex
<button phx-click="save" class="phx-click-loading:opacity-50">Save</button>
<.form phx-submit="create" class="phx-submit-loading:pointer-events-none">
  <button class="phx-submit-loading:animate-pulse">Submit</button>
</.form>
```

| Class | Applied When |
|-------|--------------|
| `phx-click-loading` | During click event |
| `phx-submit-loading` | During form submit |
| `phx-change-loading` | During form change |
| `phx-page-loading` | During navigation |

### Server-Pushed Events

```elixir
# Server: push event to client hooks
{:noreply, push_event(socket, "saved", %{id: 123})}
```

```javascript
// Client: handle in hook
this.handleEvent("saved", ({id}) => {
  this.el.classList.add("saved")
})
```

### Common Hook Patterns

```javascript
// Infinite scroll
Hooks.InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) this.pushEvent("load-more", {})
    })
    this.observer.observe(this.el)
  },
  destroyed() { this.observer.disconnect() }
}

// Copy to clipboard
Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      navigator.clipboard.writeText(this.el.dataset.value)
        .then(() => this.pushEvent("copied", {}))
    })
  }
}

// Flash auto-dismiss
Hooks.Flash = {
  mounted() {
    this.timer = setTimeout(() => {
      this.pushEvent("lv:clear-flash", {key: this.el.dataset.key})
    }, 5000)
  },
  destroyed() { clearTimeout(this.timer) }
}
```

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

### Colocated Hooks (v1.1+)

Write hook JS inline with your component — no separate files needed:

```elixir
alias Phoenix.LiveView.ColocatedHook

def phone_input(assigns) do
  ~H"""
  <input type="text" id={@id} value={@value} phx-hook=".PhoneFormat" />
  <script :type={ColocatedHook} name=".PhoneFormat">
    export default {
      mounted() {
        this.el.addEventListener("input", e => {
          let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
          if (match) { this.el.value = `${match[1]}-${match[2]}-${match[3]}` }
        })
      }
    }
  </script>
  """
end
```

**Key rules:**
- Hook names starting with `.` (dot) are auto-namespaced to the module at compile time
- Import in app.js: `import {hooks as colocatedHooks} from "phoenix-colocated/my_app"`
- Merge: `hooks: {...colocatedHooks, ...manualHooks}`
- Requires Phoenix 1.8+ and esbuild config updates
- Add `:phoenix_live_view` to compilers in mix.exs: `compilers: [:phoenix_live_view] ++ Mix.compilers()`

**esbuild config** (config/config.exs):
```elixir
args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js
  --external:/fonts/* --external:/images/* --alias:@=.),
env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
```

### JS.ignore_attributes (v1.1+)

Prevent LiveView from overwriting attributes managed by 3rd-party JS libraries:

```heex
<div id="chart" phx-hook="Chart" {@rest}
  phx-ignore-attributes={JS.ignore_attributes(["style", "width", "height"])}>
</div>
```

Useful when external JS (charts, maps, rich editors) modifies DOM attributes that LiveView would normally reset on patch.

### TypeScript Types (v1.1+)

```javascript
/** @type {import("phoenix_live_view").HooksOptions} */
let Hooks = {}
Hooks.MyHook = {
  mounted() { /* this.el, this.pushEvent etc. have proper types */ }
}
```

---

### Phoenix Channels (Non-LiveView Real-Time)

For real-time features outside LiveView:

```javascript
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: userToken}})
socket.connect()

let channel = socket.channel("room:lobby", {})
channel.join()
  .receive("ok", resp => console.log("Joined!", resp))
  .receive("error", resp => console.log("Failed", resp))

// Listen for events
channel.on("new_msg", payload => console.log("New:", payload.body))

// Push events
channel.push("new_msg", {body: "Hello!"})
  .receive("ok", resp => console.log("Sent"))
  .receive("error", resp => console.log("Error", resp))
  .receive("timeout", () => console.log("Timeout"))

// Lifecycle
channel.onError(() => console.log("Channel error"))
channel.onClose(() => console.log("Channel closed"))
channel.leave()
```

### Presence Tracking

```javascript
import {Presence} from "phoenix"

let presence = new Presence(channel)

presence.onSync(() => renderUsers(presence.list()))

presence.onJoin((id, current, newPres) => {
  if (!current) console.log("User joined:", id)
})

presence.onLeave((id, current, leftPres) => {
  if (current.metas.length === 0) console.log("User left:", id)
})

// List with custom selector
let users = presence.list((id, {metas: [first, ...rest]}) => {
  return {id, name: first.name, count: rest.length + 1}
})
```

---

### DOM Patching

```heex
<%# Stream: Efficient list updates %>
<div id="items" phx-update="stream">
  <div :for={{id, item} <- @streams.items} id={id}>{item.name}</div>
</div>

<%# Ignore: Never update this element (managed by JS) %>
<div id="static" phx-update="ignore">Content managed by JS</div>
```

**Lifecycle events:**
```javascript
window.addEventListener("phx:page-loading-start", info => { /* show spinner */ })
window.addEventListener("phx:page-loading-stop", info => { /* hide spinner */ })
element.addEventListener("phx:mounted", e => { /* element mounted */ })
element.addEventListener("phx:updated", e => { /* element updated */ })
```

### Debugging

```javascript
// Enable debug logging
let liveSocket = new LiveSocket("/live", Socket, {
  logger: (kind, msg, data) => console.log(`${kind}: ${msg}`, data)
})

// In browser console:
liveSocket.enableDebug()
liveSocket.enableLatencySim(1000)  // Add 1000ms latency
liveSocket.disableLatencySim()
```

---

### phx-* Attributes Quick Reference

**Event handlers:** `phx-click`, `phx-click-away`, `phx-blur`, `phx-focus`, `phx-keydown`, `phx-keyup`, `phx-key`, `phx-window-blur`, `phx-window-focus`, `phx-window-keydown`, `phx-window-keyup`, `phx-viewport-top`, `phx-viewport-bottom`

**Form:** `phx-change`, `phx-submit`, `phx-feedback-for`, `phx-disable-with`, `phx-trigger-action`, `phx-auto-recover`

**Modifiers:** `phx-value-*`, `phx-target`, `phx-debounce`, `phx-throttle`

**DOM control:** `phx-update` ("stream", "ignore"), `phx-hook`, `phx-mounted`, `phx-remove`

**Connection:** `phx-connected`, `phx-loading`, `phx-disconnected`
