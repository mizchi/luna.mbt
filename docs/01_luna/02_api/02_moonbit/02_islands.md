---
title: Islands API
---

# Islands API

Server-side island rendering for partial hydration.

## island

Create an island element for client-side hydration.

```moonbit
fn counter_island(initial : Int) -> @luna.Node {
  @luna.island(
    "counter",
    "/components/counter.js",
    initial.to_string(),
    [@element.div([@element.button([@element.text("Count: \{initial}")])])],
    trigger=@luna.Load,
  )
}
```

### Signature

```moonbit
fn island(
  id : String,
  url : String,
  state : String,
  children : Array[@luna.Node],
  trigger~ : Trigger = Load,
) -> @luna.Node
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | `String` | Component identifier (matches `luna:id`) |
| `url` | `String` | JavaScript module URL |
| `state` | `String` | Serialized props (JSON) |
| `children` | `Array[Node]` | Server-rendered content |
| `trigger` | `Trigger` | When to hydrate (default: `Load`) |

### HTML Output

```html
<div
  luna:id="counter"
  luna:url="/components/counter.js"
  luna:state="0"
  luna:client-trigger="load"
>
  <div><button>Count: 0</button></div>
</div>
```

### Example with Visible Trigger

```moonbit
// Lazy-loaded island - hydrates when scrolled into view
let lazy = @luna.island(
  "lazy",
  "/components/lazy.js",
  "{}",
  [@element.text("Lazy content")],
  trigger=@luna.Visible,
)
// Output: luna:client-trigger="visible"
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
| `@luna.Load` | `load` | Immediate hydration |
| `@luna.Idle` | `idle` | `requestIdleCallback` |
| `@luna.Visible` | `visible` | `IntersectionObserver` |
| `@luna.Media(query)` | `media:(query)` | Media query match |
| `@luna.None` | `none` | Manual via `__LUNA_HYDRATE__` |

### Examples

```moonbit
// Immediate (default)
trigger=@luna.Load

// When browser is idle
trigger=@luna.Idle

// When scrolled into view
trigger=@luna.Visible

// Desktop only
trigger=@luna.Media("(min-width: 768px)")

// Manual trigger
trigger=@luna.None
```

## render_with_preloads

Render and collect island URLs for preloading.

```moonbit
let node = @element.div([
  @luna.island("a", "/a.js", "{}", [@element.text("A")]),
  @luna.island("b", "/b.js", "{}", [@element.text("B")]),
])

let result = render_with_preloads(node)
// result.html contains the rendered HTML
// result.preload_urls = ["/a.js", "/b.js"]
```

### Use for Link Preloading

```moonbit
// Generate preload links for all islands
let preload_links = result.preload_urls.map(fn(url) {
  @element.link(rel="modulepreload", href=url)
})
```

## wc_island

Create a Web Component island with Shadow DOM.

```moonbit
fn counter_wc(initial : Int) -> @luna.Node {
  @luna.wc_island(
    name="wc-counter",
    url="/static/wc-counter.js",
    state=initial.to_string(),
    trigger=@luna.Load,
    styles=":host { display: block; }",
    children=[
      @element.button([@element.text("Count: \{initial}")])
    ],
  )
}
```

### Signature

```moonbit
fn wc_island(
  name~ : String,
  url~ : String,
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

## slot_

Create a slot element for Web Components.

```moonbit
@luna.wc_island(
  name="wc-card",
  children=[
    @element.slot_(),                    // Default slot
    @element.slot_(name="header"),       // Named slot
    @element.slot_(name="footer"),       // Named slot
  ],
)
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
  @luna.island(
    "counter",
    "/static/counter.js",
    state.to_json().stringify(),
    [@element.div([@element.text("Loading...")])],
    trigger=@luna.Load,
  )
}
```

## Client-Side Hydration

The island loader (`@mizchi/luna-loader`) handles hydration on the client:

```html
<!-- Add to your page -->
<script type="module">
import { setupHydration } from '@mizchi/luna-loader';
setupHydration();
</script>
```

### Hydration Process

1. Loader scans for elements with `luna:id` or `luna:wc-*` attributes
2. Based on trigger, it:
   - `load`: Immediately imports the module
   - `idle`: Uses `requestIdleCallback`
   - `visible`: Uses `IntersectionObserver`
   - `media`: Uses `matchMedia`
3. Module's default export receives the element and parsed state

### Island Module Structure

```javascript
// /components/counter.js
export default function hydrate(element, state) {
  // state is parsed from luna:state
  const count = state.initial || 0;

  // Set up reactivity
  element.querySelector('button').onclick = () => {
    // Update logic
  };
}
```

## API Summary

| Function | Description |
|----------|-------------|
| `@luna.island(id, url, state, children, trigger~)` | Create standard island |
| `@luna.wc_island(...)` | Create Web Component island |
| `@element.slot_(name~)` | Create slot element |
| `render_with_preloads(node)` | Render and collect preload URLs |

| Trigger | When |
|---------|------|
| `@luna.Load` | Page load (default) |
| `@luna.Idle` | Browser idle |
| `@luna.Visible` | In viewport |
| `@luna.Media(query)` | Media query matches |
| `@luna.None` | Manual |
