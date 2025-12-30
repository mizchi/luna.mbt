---
title: Deep Dive
---

# Deep Dive

Advanced concepts, internal architecture, and performance optimization.

## Design Decisions

### Why No Compile-Time Optimization?

Many modern frameworks (Svelte, Solid, Qwik) rely heavily on compile-time transformations:

| Framework | Approach | Trade-off |
|-----------|----------|-----------|
| Svelte | Compiles to imperative code | Magic syntax, harder debugging |
| Solid | JSX transformation | Build complexity |
| Qwik | Resumability via code splitting | Complex mental model |
| **Luna** | **Minimal runtime, no magic** | **What you write is what runs** |

Luna takes a different approach: **make the runtime so small that optimization becomes unnecessary**.

At ~6.7KB total, Luna's overhead is already negligible. This means:
- No build-time surprises
- Easier debugging (code behaves as written)
- Simpler mental model
- Works with any bundler

### WebComponents SSR: World's First Implementation

Luna is the first framework to support full WebComponents SSR + Hydration using Declarative Shadow DOM:

```html
<!-- Server-rendered output -->
<my-counter luna:client-trigger="visible">
  <template shadowrootmode="open">
    <style>button { color: blue; }</style>
    <button>Count: 0</button>
  </template>
</my-counter>
```

The key insight: Declarative Shadow DOM (`<template shadowrootmode="open">`) allows Shadow DOM to be serialized as HTML. Combined with Luna's hydration system, this enables:

- **SSR with encapsulated styles** - No FOUC (Flash of Unstyled Content)
- **Progressive enhancement** - Content visible before JS loads
- **Framework agnostic** - Islands work with any frontend code

---

## Reactivity System

Luna's reactivity is based on fine-grained signals:

```
Signal
  └── Subscribers (Effects, Memos)
        └── DOM Updates
```

When a signal changes:
1. All subscribers are notified
2. Effects run synchronously (batched)
3. DOM updates happen directly (no diffing)

### Signal Implementation

Signals are implemented as observable values with automatic dependency tracking:

```moonbit
// Create a signal
let count = @signal.signal(0)

// Read (and track dependency)
count.get()  // Returns 0, tracks this read

// Write (and notify subscribers)
count.set(1)  // Notifies all effects

// Update (read + write)
count.update(fn(n) { n + 1 })
```

### Fine-Grained vs Coarse-Grained

Luna uses fine-grained signals (individual signals per field) rather than coarse-grained stores with selectors:

| Pattern | Performance | Use Case |
|---------|-------------|----------|
| Fine-grained | **21-104x faster** | Recommended for all cases |
| Coarse (select) | Slow | Removed from API |

**Why fine-grained wins:**

```moonbit
// Fine-grained: Updating count only triggers count watchers
let count = @signal.signal(0)
let name = @signal.signal("test")
count.set(1)  // Only count effects run

// Coarse (removed): Every update triggers all selectors
let state = signal({ count: 0, name: "test" })
state.set({ ...state, count: 1 })  // All selectors re-evaluate
```

### Performance Characteristics

| Operation | Complexity |
|-----------|------------|
| Signal read | O(1) |
| Signal write | O(subscribers) |
| DOM update | O(1) per affected node |

Compare to Virtual DOM:
- React: O(n) tree diff on every render
- Luna: O(1) direct updates

This is why Luna achieves 60 FPS where React achieves 12 FPS on the same workload.

---

## VNode Architecture

Luna uses a virtual node representation for SSR:

```moonbit
pub enum Node[E] {
  Element(VElement[E])      // HTML element
  Text(String)              // Static text
  DynamicText(() -> String) // Reactive text
  Fragment(Array[Node[E]])  // Fragment
  Show(...)                 // Conditional rendering
  For(...)                  // List rendering
  Island(VIsland[E])        // Hydration boundary
  WcIsland(VWcIsland[E])    // Web Components Island
  Async(VAsync[E])          // Async node
}
```

### Attribute Types

```moonbit
pub enum Attr[E] {
  VStatic(String)           // Static value
  VDynamic(() -> String)    // Signal-connected
  VHandler(EventHandler[E]) // Event handler
  VAction(String)           // Declarative action
}
```

### Trigger Types

Hydration can be triggered in different ways:

```moonbit
pub enum TriggerType {
  Load      // On page load
  Idle      // requestIdleCallback
  Visible   // IntersectionObserver
  Media(String)  // Media query match
  None      // Manual trigger
}
```

---

## Performance Optimization

### The 10,000 Cell Problem

When rendering large numbers of elements (e.g., 100x100 grid), naive approaches fail:

| Approach | Frame Time | FPS |
|----------|-----------|-----|
| Individual `attr_dynamic` | 76ms | 13 |
| Single effect | ~10ms | 100 |
| Dirty tracking | 0.7ms | **1400** |

### Anti-Pattern: Individual Dynamic Attributes

```moonbit
// BAD: Creates 10,000 effects
@dom.for_each(
  fn() { indices },
  fn(i, _) {
    @dom.div(
      class_dyn=fn() { cell_class(get_cell(i)) },  // Effect per cell!
      [],
    )
  },
)
```

**Problem:** 10,000 independent effects. Every signal update re-runs all.

### Pattern 1: Single Effect with Batch Update

```moonbit
// BETTER: One effect for all cells
let cell_elements : Array[@js_dom.Element] = []

let _ = @signal.effect(fn() {
  let state = state_sig.get()
  for i = 0; i < cell_elements.length(); i = i + 1 {
    cell_elements[i].setClassName(cell_class(get_cell(i, state)))
  }
})

@dom.for_each(
  fn() { indices },
  fn(_, _) {
    @dom.div(
      class="cell",
      ref_=fn(el) { cell_elements.push(el) },
      [],
    )
  },
)
```

### Pattern 2: Dirty Tracking (Recommended)

```moonbit
// BEST: Only update changed cells
let cell_elements : Array[@js_dom.Element] = []
let prev_cell_types : Array[Int] = []

let _ = @signal.effect(fn() {
  let state = state_sig.get()
  for i = 0; i < cell_elements.length(); i = i + 1 {
    let cell_type = get_cell(i, state)
    // Only update if changed
    if cell_type != prev_cell_types[i] {
      prev_cell_types[i] = cell_type
      cell_elements[i].setClassName(cell_class(cell_type))
    }
  }
})
```

**Result:** 0.7ms/frame - 100x faster than naive approach.

### Optimization Principles

1. **Minimize effect count** - One effect updating many elements beats many effects updating one element each

2. **Hold DOM references** - Use `ref_` to get element references, update directly in effects

3. **Dirty tracking** - Track previous state, only update DOM when values change

4. **FFI for hot paths** - Use JavaScript FFI for performance-critical operations

```moonbit
// Slow: MoonBit to_int()
let x = pos.to_int()

// Fast: JS FFI with bitwise
extern "js" fn to_int_fast(x : Double) -> Int =
  #| (x) => x | 0
```

---

## Hydration Strategies

Luna supports multiple hydration strategies:

| Strategy | When | Use Case |
|----------|------|----------|
| `load` | Immediately | Critical interactions |
| `idle` | Browser idle | Secondary features |
| `visible` | In viewport | Below-the-fold |
| `media` | Query matches | Device-specific |

### Island Attributes

Server-rendered HTML includes hydration metadata:

```html
<div luna:id="counter"
     luna:url="/static/counter.js"
     luna:state='{"count":0}'
     luna:client-trigger="visible">
  <!-- SSR content -->
</div>
```

| Attribute | Purpose |
|-----------|---------|
| `luna:id` | Component identifier |
| `luna:url` | JavaScript module URL |
| `luna:state` | Serialized initial state |
| `luna:client-trigger` | Hydration strategy |

### Hydration Process

1. **Loader initialization** - Small (~1.6KB) loader script runs
2. **Island detection** - Find elements with `luna:id`
3. **Strategy evaluation** - Check trigger conditions
4. **Module loading** - Dynamic import of island code
5. **State deserialization** - Parse `luna:state`
6. **Hydration** - Attach reactivity to existing DOM

### Web Components Integration

Islands can be implemented as Web Components:

```typescript
hydrateWC("my-counter", (root, props, trigger) => {
  // root: ShadowRoot (existing from SSR)
  // props: Serialized props
  // trigger: Hydration trigger info
});
```

Benefits:
- Style encapsulation via Shadow DOM
- Native browser support
- Framework agnostic islands

---

## State Management Patterns

### 1. Individual Signals (Simple State)

```moonbit
let count = @signal.signal(0)
let name = @signal.signal("")
```

Best for 2-5 independent fields.

### 2. SplitStore (Structured State)

```moonbit
struct AppState {
  count : @signal.Signal[Int]
  user : @signal.Signal[User?]
}

fn AppState::new() -> AppState {
  {
    count: @signal.signal(0),
    user: @signal.signal(None)
  }
}
```

Best for typed state with explicit structure.

### 3. Context API (Dependency Injection)

```moonbit
let theme_ctx = create_context("light")

provide(theme_ctx, "dark", fn() {
  let theme = use_context(theme_ctx)  // "dark"
  render_child()
})
```

Best for theming, i18n, global settings.

---

## MoonBit Architecture

Luna is implemented in MoonBit with multi-target support:

| Target | Signal | Render | DOM |
|--------|:------:|:------:|:---:|
| JavaScript | ✅ | ✅ | ✅ |
| Native | ✅ | ✅ | - |
| Wasm | ✅ | ✅ | - |
| Wasm-GC | ✅ | ✅ | - |

### Module Structure

```
src/luna/
├── signal/      # Reactive primitives (all targets)
├── render/      # VNode → HTML string (all targets)
├── routes/      # Type-safe routing
├── serialize/   # State serialization
└── vnode.mbt    # VNode types

src/platform/
├── dom/         # Browser DOM operations (JS only)
└── js_dom/      # JavaScript DOM FFI
```

### Why MoonBit?

| Aspect | JavaScript | MoonBit |
|--------|------------|---------|
| Type Safety | Runtime errors | Compile-time |
| Dead Code | Tree-shaking | Guaranteed elimination |
| SSR Speed | V8 overhead | Native speed |
| Bundle Size | Framework + App | Optimized output |

---

## Debugging Tips

### 1. Effect Tracking

```moonbit
@signal.effect(fn() {
  println("Effect running")
  let val = some_signal.get()
  println("Read value: " + val.to_string())
})
```

### 2. Signal Inspection

```typescript
// In browser console
window.__LUNA_DEBUG__ = true;
```

### 3. Hydration Debugging

Check network tab for island module loading. Verify `luna:*` attributes in Elements panel.

### 4. Performance Profiling

Use browser DevTools Performance tab. Look for:
- Effect execution time
- DOM update frequency
- Module load timing

---

## See Also

- [Signals API](/luna/api-js/signals/) - JavaScript signal reference
- [Islands API](/luna/api-js/islands/) - Island configuration
- [Stella](/stella/) - Web Components builder
