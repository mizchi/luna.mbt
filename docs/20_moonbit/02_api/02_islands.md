---
title: Islands API
---

# Islands API

Server-side island rendering for partial hydration.

## island

Create an island element for client-side hydration.

```moonbit
using @server_dom { island, div, button, text }
using @luna { Load }

fn counter_island(initial : Int) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=initial.to_string(),
    trigger=Load,
    children=[
      div([button([text("Count: " + initial.to_string())])])
    ],
  )
}
```

### Signature

```moonbit
fn island(
  id : String,
  url : String,
  state~ : String = "",
  trigger~ : Trigger = Load,
  children~ : Array[@luna.Node] = [],
) -> @luna.Node
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | `String` | Component identifier (matches `luna:id`) |
| `url` | `String` | JavaScript module URL |
| `state` | `String` | Serialized props (JSON) |
| `trigger` | `Trigger` | When to hydrate |
| `children` | `Array[Node]` | Server-rendered content |

### HTML Output

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state="0"
  luna:client-trigger="load"
>
  <div><button>Count: 0</button></div>
</div>
```

## wc_island

Create a Web Component island with Shadow DOM.

```moonbit
using @server_dom { wc_island, button, text }
using @luna { Load }

fn counter_wc(initial : Int) -> @luna.Node {
  wc_island(
    name="wc-counter",
    url="/static/wc-counter.js",
    state=initial.to_string(),
    trigger=Load,
    styles=":host { display: block; }",
    children=[
      button([text("Count: " + initial.to_string())])
    ],
  )
}
```

### Signature

```moonbit
fn wc_island(
  name : String,
  url : String,
  state~ : String = "",
  trigger~ : Trigger = Load,
  styles~ : String = "",
  children~ : Array[@luna.Node] = [],
) -> @luna.Node
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `String` | Custom element tag name |
| `url` | `String` | JavaScript module URL |
| `state` | `String` | Serialized props (JSON) |
| `trigger` | `Trigger` | When to hydrate |
| `styles` | `String` | Scoped CSS for Shadow DOM |
| `children` | `Array[Node]` | Server-rendered content |

### HTML Output

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <button>Count: 0</button>
  </template>
</wc-counter>
```

## Trigger

Enum for hydration timing.

```moonbit
enum Trigger {
  Load      // Immediately on page load
  Idle      // When browser is idle
  Visible   // When element enters viewport
  Media(String)  // When media query matches
  None      // Manual trigger only
}
```

### Values

| Value | HTML Output | Description |
|-------|-------------|-------------|
| `Load` | `load` | Immediate hydration |
| `Idle` | `idle` | `requestIdleCallback` |
| `Visible` | `visible` | `IntersectionObserver` |
| `Media(query)` | `media:(query)` | Media query match |
| `None` | `none` | Manual via `__LUNA_HYDRATE__` |

### Examples

```moonbit
// Immediate
trigger=Load

// When browser is idle
trigger=Idle

// When scrolled into view
trigger=Visible

// Desktop only
trigger=Media("(min-width: 768px)")

// Manual
trigger=None
```

## slot_

Create a slot element for Web Components.

```moonbit
using @server_dom { wc_island, slot_ }

wc_island(
  name="wc-card",
  children=[
    slot_(),                    // Default slot
    slot_(name="header"),       // Named slot
    slot_(name="footer"),       // Named slot
  ],
)
```

### Signature

```moonbit
fn slot_(name~ : String = "") -> @luna.Node
```

### HTML Output

```html
<slot></slot>
<slot name="header"></slot>
<slot name="footer"></slot>
```

## Serializing State

Use `derive(ToJson)` for automatic serialization:

```moonbit
struct CounterState {
  initial : Int
  max : Int
} derive(ToJson, FromJson)

fn counter_island(state : CounterState) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=state.to_json().stringify(),
    trigger=Load,
    children=[...],
  )
}
```

## API Summary

| Function | Description |
|----------|-------------|
| `island(...)` | Create standard island |
| `wc_island(...)` | Create Web Component island |
| `slot_(name~)` | Create slot element |

| Trigger | When |
|---------|------|
| `Load` | Page load |
| `Idle` | Browser idle |
| `Visible` | In viewport |
| `Media(query)` | Media query matches |
| `None` | Manual |
