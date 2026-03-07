# Phoenix Channels & Presence

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
