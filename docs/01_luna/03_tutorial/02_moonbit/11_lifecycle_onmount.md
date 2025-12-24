---
title: "Lifecycle: onMount"
---

# onMount

Run code when a component is mounted to the DOM.

## Understanding Mount in MoonBit

In Luna's architecture:
- **Server (MoonBit)**: Renders HTML strings, no DOM access
- **Client (TypeScript)**: Has DOM access, handles mount lifecycle

For server-side MoonBit code, "mount" happens when the HTML is generated. For actual DOM mount events, use client-side TypeScript.

## Server-Side Initialization

On the server, you can initialize state during render:

```moonbit
using @server_dom { div, text }
using @luna { signal }

fn component_with_init() -> @luna.Node {
  // This runs during render (server-side "mount")
  let data = load_initial_data()
  let count = signal(data.initial_count)

  div([
    text("Initial: " + count.get().to_string())
  ])
}
```

## Effect as Mount

Effects run immediately after creation, similar to mount:

```moonbit
using @luna { signal, effect }

fn component() -> @luna.Node {
  let status = signal("initializing")

  // This runs right after creation
  effect(fn() {
    println("Component initialized")
    status.set("ready")
  })

  div([text("Status: " + status.get())])
}
```

## One-Time Setup

For one-time initialization, use a flag:

```moonbit
let initialized = signal(false)

fn setup_once() {
  if not(initialized.get()) {
    initialized.set(true)
    // One-time setup code
    println("Setup complete")
  }
}
```

## Client-Side Mount

For actual DOM mount, the client-side TypeScript handles it:

```typescript
// TypeScript (client-side)
import { onMount } from '@luna_ui/luna';

function Counter(props) {
  onMount(() => {
    console.log("Component mounted to DOM!");

    // DOM access available here
    document.title = "Counter";
  });

  return <button>Count</button>;
}
```

## Passing Mount Data from Server

Serialize data for client-side mount:

```moonbit
using @server_dom { island }
using @luna { Load }

struct InitData {
  user_id : Int
  preferences : Preferences
} derive(ToJson)

fn user_component(data : InitData) -> @luna.Node {
  island(
    id="user",
    url="/static/user.js",
    state=data.to_json().stringify(),  // Client receives this on mount
    trigger=Load,
    children=[...],
  )
}
```

## Common Patterns

### Lazy Initialization

```moonbit
fn lazy_component() -> @luna.Node {
  let data = signal(None)

  // Simulate lazy loading
  effect(fn() {
    if data.get().is_none() {
      let loaded = fetch_data()
      data.set(Some(loaded))
    }
  })

  match data.get() {
    Some(d) => render_data(d)
    None => div([text("Loading...")])
  }
}
```

### Derived Initial State

```moonbit
fn derived_component(items : Array[Item]) -> @luna.Node {
  // Calculate derived state at mount
  let total = items.fold(0, fn(sum, item) { sum + item.value })
  let average = total / items.length()

  div([
    p([text("Total: " + total.to_string())]),
    p([text("Average: " + average.to_string())]),
  ])
}
```

## Server vs Client Lifecycle

| Event | Server (MoonBit) | Client (TypeScript) |
|-------|------------------|---------------------|
| Component created | Render function runs | Component function runs |
| DOM attached | N/A | `onMount` callback |
| Signal changed | N/A | Effects re-run |
| Component removed | N/A | `onCleanup` callback |

## Try It

Create a component that:
1. Initializes with data from a parameter
2. Logs when the effect first runs
3. Passes initialization data to an island for client mount

## Next

Learn about [onCleanup →](./lifecycle_oncleanup)
