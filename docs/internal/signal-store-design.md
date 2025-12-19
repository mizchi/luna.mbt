# Signal Store Design Decision

Date: 2025-12-19

## Summary

Fine-grained reactive signals (individual signals per field) vs coarse-grained signals with selectors.

**Decision: Fine-grained signals (SplitStore pattern) are 21-104x faster. Removed `select` API in favor of individual signals.**

## Background

SolidJS uses two patterns for state management:
1. `createSignal` - individual reactive values
2. `createStore` - nested reactive objects with path-based updates

The question was whether to implement selector-based derived signals (`signal.select(fn)`) or fine-grained individual signals for each field.

## Benchmark Results

### Test Setup

```moonbit
// Coarse-grained: One signal for entire state, with selectors
struct BenchState { count: Int, name: String }
let state = signal({ count: 0, name: "test" })
let count = state.select(fn(s) { s.count })  // Derived signal

// Fine-grained: Individual signals per field
let count = signal(0)
let name = signal("test")
```

### Performance Comparison

| Scenario | Coarse (select) | Fine-grained (split) | Speedup |
|----------|-----------------|----------------------|---------|
| 2 fields - read (1000 ops) | 2.35µs | 0.11µs | 21x |
| 2 fields - update (100 ops) | 5.21µs | 0.09µs | 58x |
| Effect on field1, update field2 | 7.27µs | 0.07µs | **104x** |
| 10 fields, update 1 field | 32.15µs | 0.31µs | 104x |

### Key Finding

The critical difference is in the "effect on field1, update field2" scenario:

- **Coarse (select)**: Every update triggers all selectors to re-evaluate, even if the selected value hasn't changed. With 10 selectors watching different fields, updating one field causes 10 selector evaluations.

- **Fine-grained (split)**: Each signal is independent. Updating `count` only notifies effects watching `count`, not effects watching `name`.

## Removed APIs

```moonbit
// REMOVED - These were inefficient
pub fn[T, A : Eq] Signal::select(self, selector: (T) -> A) -> () -> A
pub fn[T, A : Eq, B : Eq] select2(s1, s2, f) -> () -> (A, B)
pub fn[T, A : Eq, B : Eq, C : Eq] select3(s1, s2, s3, f) -> () -> (A, B, C)
```

## Removed Aliases

```moonbit
// REMOVED - Unnecessary wrappers around signal/memo
pub struct Atom[T] { sig: Signal[T] }
pub fn atom(initial) -> Atom[T]  // Same as signal()
pub fn derived_atom(compute) -> () -> T  // Same as memo()
```

## Recommended Patterns

### 1. SplitStore (Best Performance)

```moonbit
struct ReactiveState {
  count : Signal[Int]
  name : Signal[String]
}

fn ReactiveState::new(count: Int, name: String) -> ReactiveState {
  { count: signal(count), name: signal(name) }
}

// Usage
let state = ReactiveState::new(0, "hello")
state.count.set(10)  // Only triggers count watchers
```

### 2. LensStore (Type-safe field access)

```moonbit
let store = LensStore::new({ count: 0, name: "test" })
let count_lens = Lens::new(
  fn(s) { s.count },
  fn(s, v) { { count: v, name: s.name } }
)
let (count_sig, set_count) = store.focus(count_lens)
```

### 3. Context API (Parent-child value sharing)

```moonbit
// Already implemented in provider.mbt
let theme_ctx = create_context("light")

provide(theme_ctx, "dark", fn() {
  let theme = use_context(theme_ctx)  // Returns "dark"
  render_child()
})
```

## Architecture Decision

### Why not keep `select` as an option?

1. **Performance trap**: Users might use it thinking it's equivalent, but it's 100x slower
2. **Mental model**: Fine-grained signals are simpler to understand
3. **Code size**: Removing unused code reduces bundle size

### When to use each pattern

| Pattern | Use Case |
|---------|----------|
| Individual signals | Simple state (2-5 fields) |
| SplitStore struct | Typed state with explicit structure |
| LensStore | Complex nested state with computed views |
| Context | Dependency injection, theming, i18n |

## Files Changed

- `src/core/signal/signal.mbt` - Removed select, select2, select3
- `src/core/signal/store.mbt` - Removed Atom, derived_atom
- `src/core/signal/store_test.mbt` - Updated tests
- `src/core/signal/store_bench.mbt` - Updated benchmarks
- `src/examples/spa/main.mbt` - Removed atom_example

## Related

- [SolidJS Stores](https://www.solidjs.com/tutorial/stores_createstore)
- [SolidJS Context](https://www.solidjs.com/tutorial/stores_context)
