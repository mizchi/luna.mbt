---
title: "Introduction: Basics"
---

# Your First Luna Component

Let's build a simple counter to understand Luna's core concepts.

## A Counter in MoonBit

```moonbit
using @server_dom { div, p, button, text }
using @luna { signal }

fn counter() -> @luna.Node {
  let count = signal(0)

  div([
    p([text("Count: " + count.get().to_string())]),
    button([text("Increment")]),
  ])
}
```

## Breaking It Down

### 1. Imports

```moonbit
using @server_dom { div, p, button, text }
using @luna { signal }
```

- `@server_dom` provides HTML element factories for server-side rendering
- `@luna` provides reactive primitives like `signal`

### 2. Create Reactive State

```moonbit
let count = signal(0)
```

`signal(0)` creates a reactive value that:
- Starts at `0`
- Can be read with `.get()`
- Can be updated with `.set()` or `.update()`

### 3. Build the DOM

```moonbit
div([
  p([text("Count: " + count.get().to_string())]),
  button([text("Increment")]),
])
```

Elements are created with factory functions:
- `div([...])` creates a `<div>` with children
- `text("...")` creates a text node

## Rendering to HTML

To render the component:

```moonbit
fn main {
  let node = counter()
  let html = @renderer.render_to_string(node)
  println(html)
}
```

Output:

```html
<div><p>Count: 0</p><button>Increment</button></div>
```

## Server-Side vs Client-Side

In Luna's Islands Architecture:

| Where | What |
|-------|------|
| Server (MoonBit) | Renders initial HTML |
| Client (TypeScript) | Adds interactivity via hydration |

The MoonBit code above renders the initial HTML. For the button to actually increment the counter, you need a client-side TypeScript component that hydrates the island.

## Complete Example with Island

```moonbit
using @server_dom { island, div, p, button, text }
using @luna { signal, Load }

fn counter_island(initial : Int) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=initial.to_string(),
    trigger=Load,
    children=[
      div([
        p([text("Count: " + initial.to_string())]),
        button([text("Increment")]),
      ])
    ],
  )
}
```

This renders HTML with hydration attributes:

```html
<div luna:id="counter" luna:url="/static/counter.js" luna:state="0" luna:client-trigger="load">
  <div><p>Count: 0</p><button>Increment</button></div>
</div>
```

The client-side TypeScript code then hydrates this element. See [Islands Basics](./islands_basics) for details.

## Try It

1. Create a component that shows "Hello, Luna!"
2. Add a signal for a name and display "Hello, {name}!"

## Next

Learn about [Signals →](./introduction_signals)
