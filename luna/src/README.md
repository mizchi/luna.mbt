# Luna Core

Core functionality of the Luna UI library. Platform-independent.

## Module Structure

| Submodule | Responsibility |
|-----------|----------------|
| `signal/` | Reactive primitives (Signal, Effect, Computed) |
| `render/` | VNode → HTML string rendering |
| `routes/` | Type-safe routing |
| `serialize/` | State serialization/deserialization |
| `vnode.mbt` | VNode type definitions |

## VNode

Virtual DOM node. Type parameter `E` represents the event type.

```moonbit
pub enum Node[E] {
  Element(VElement[E])      // HTML element
  Text(String)              // Static text
  DynamicText(() -> String) // Dynamic text
  Fragment(Array[Node[E]])  // Fragment
  Show(...)                 // Conditional rendering
  For(...)                  // List rendering
  Island(VIsland[E])        // Hydration boundary
  WcIsland(VWcIsland[E])    // Web Components Island
  Async(VAsync[E])          // Async node
  // ...
}
```

## Signal

Reactive value container.

```moonbit
let count = @signal.signal(0)
count.get()        // 0
count.set(1)       // Set value
count.update(fn(n) { n + 1 })  // Update function

// Derived value
let doubled = @signal.computed(fn() { count.get() * 2 })

// Side effects
@signal.effect(fn() {
  println(count.get())
})
```

## Attr

Attribute values. Supports static/dynamic/event handlers.

```moonbit
pub enum Attr[E] {
  VStatic(String)           // Static value
  VDynamic(() -> String)    // Signal-linked
  VHandler(EventHandler[E]) // Event handler
  VAction(String)           // Declarative action
}
```

## TriggerType

Hydration triggers.

```moonbit
pub enum TriggerType {
  Load      // On page load
  Idle      // On requestIdleCallback
  Visible   // On IntersectionObserver detection
  Media(String)  // On media query match
  None      // Manual trigger
}
```

## References

- [Signal Implementation](./signal/) - Reactive system details
- [Routes Implementation](./routes/) - Routing details
