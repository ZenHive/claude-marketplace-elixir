# phx-* Attributes Quick Reference

## Event Handlers

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

## Form Attributes

| Attribute | Description |
|-----------|-------------|
| `phx-change` | Handle form input changes |
| `phx-submit` | Handle form submission |
| `phx-feedback-for` | Show errors after field interaction |
| `phx-disable-with` | Button text during submission |
| `phx-trigger-action` | Submit form via HTTP after event |
| `phx-auto-recover` | Control form recovery behavior |

## Event Modifiers

| Attribute | Description |
|-----------|-------------|
| `phx-value-*` | Pass values to event handler |
| `phx-target` | Target specific LiveView/Component |
| `phx-debounce` | Debounce events (ms or "blur") |
| `phx-throttle` | Throttle events (ms) |

## DOM Control

| Attribute | Description |
|-----------|-------------|
| `phx-update` | Control DOM patching ("stream", "ignore") |
| `phx-hook` | Attach JavaScript hook |
| `phx-mounted` | JS commands on mount |
| `phx-remove` | JS commands on remove |

## Connection Lifecycle

| Attribute | Description |
|-----------|-------------|
| `phx-connected` | Class added when connected |
| `phx-loading` | Class added during loading |
| `phx-disconnected` | Element shown when disconnected |

## Loading State Classes

Applied automatically during server round-trips:

| Class | Applied When |
|-------|--------------|
| `phx-click-loading` | During click event |
| `phx-submit-loading` | During form submit |
| `phx-change-loading` | During form change |
| `phx-page-loading` | During navigation |
