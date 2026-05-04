# ADR-001: Fine-Grained Reactive Signal System

## Status

Accepted

## Context

UI frameworks need a way to track state changes and efficiently update the DOM. Traditional approaches include:

1. **Virtual DOM diffing** (React): Compare entire tree on every change
2. **Dirty checking** (Angular): Poll for changes periodically
3. **Fine-grained reactivity** (SolidJS, Svelte): Track dependencies at granular level

MoonBit's compile-to-WASM nature makes fine-grained reactivity attractive due to:
- Minimal runtime overhead
- Predictable performance characteristics
- No need for reconciliation algorithms

## Decision

Implement a fine-grained reactive system with three core primitives:

### 1. Signal[T] - Reactive State Container

```moonbit
pub fn signal[T](initial: T) -> Signal[T]
pub fn Signal::get(self) -> T
pub fn Signal::set(self, value: T) -> Unit
```

- Holds a value that can change over time
- Tracks subscribers automatically during reads
- Notifies subscribers on writes

### 2. Effect - Side Effect Runner

```moonbit
pub fn effect(fn: () -> Unit) -> EffectHandle
```

- Automatically re-runs when accessed signals change
- Used for DOM updates, logging, etc.
- Returns handle for cleanup/disposal

### 3. Memo[T] - Derived Computation

```moonbit
pub fn memo[T](fn: () -> T) -> Memo[T]
```

- Cached derived value
- Only recomputes when dependencies change
- Lazy evaluation on first access

### Dependency Tracking

Use a global context stack to track the currently executing computation:

```moonbit
priv let current_observer: Ref[Observer?] = Ref::new(None)
```

When a signal is read, it registers the current observer as a subscriber.

## Consequences

### Positive

- **Surgical updates**: Only affected DOM nodes update
- **No virtual DOM overhead**: Direct DOM manipulation
- **Predictable performance**: O(1) for signal updates
- **Memory efficient**: No tree diffing allocations

### Negative

- **Learning curve**: Different mental model from React
- **Debugging complexity**: Reactive graph can be hard to trace
- **Potential for memory leaks**: Must dispose effects properly

### Neutral

- Similar API to SolidJS, enabling knowledge transfer
- Requires discipline in component boundaries
