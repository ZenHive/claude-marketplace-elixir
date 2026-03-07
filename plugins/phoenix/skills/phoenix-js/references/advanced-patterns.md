# Advanced Phoenix JS Patterns

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
