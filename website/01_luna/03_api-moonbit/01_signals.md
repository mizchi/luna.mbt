---
title: Signals API
---

# Signals API

Signals are the foundation of Luna's reactivity system in MoonBit.

## Signal

Create a reactive signal that holds a value.

```moonbit
let count = Signal::new(0)

// Read value (tracks dependency)
let value = count.get()  // 0

// Set value
count.set(5)

// Update with function
count.update(fn(n) { n + 1 })

// Read without tracking
let peeked = count.peek()
```

### Constructor

```moonbit
fn Signal::new[T](value : T) -> Signal[T]
```

### Methods

| Method | Description |
|--------|-------------|
| `.get()` | Read value (tracks dependency) |
| `.set(value)` | Set new value |
| `.update(fn)` | Update based on current value |
| `.peek()` | Read without tracking |
| `.map(fn)` | Create derived signal |
| `.filter(fn)` | Filter values by predicate |
| `.filter_map(fn)` | Filter and map values |
| `.to_getter()` | Create read-only getter function |
| `.subscriber_count()` | Get number of subscribers |
| `.clear_subscribers()` | Remove all subscribers |

### Transformations

```moonbit
let count = Signal::new(5)

// Map to derived value
let doubled = count.map(fn(n) { n * 2 })
assert_eq(doubled(), 10)

// Filter values
let positive = count.filter(fn(n) { n > 0 })
assert_eq(positive.peek(), Some(5))

// Filter and map
let doubled_positive = count.filter_map(fn(n) {
  if n > 0 { Some(n * 2) } else { None }
})
```

## effect

Create a side effect that automatically tracks dependencies.

```moonbit
let name = Signal::new("Luna")

let dispose = effect(fn() {
  println("Hello, \{name.get()}!")
})
// Prints: Hello, Luna!

name.set("World")
// Prints: Hello, World!

dispose()  // Stop the effect
```

### Signature

```moonbit
fn effect(fn : () -> Unit) -> () -> Unit
```

### Variants

```moonbit
// Conditional effect - only runs when condition is true
let condition = Signal::new(false)
effect_when(fn() { condition.get() }, fn() {
  println("Condition is true!")
})

// One-time effect - runs once and disposes
effect_once(fn() {
  println("This runs only once")
})
```

## memo / computed

Create a cached computed value.

```moonbit
let count = Signal::new(2)
let doubled = memo(fn() { count.get() * 2 })

assert_eq(doubled(), 4)

count.set(3)
assert_eq(doubled(), 6)

// `computed` is an alias for `memo`
let tripled = computed(fn() { count.get() * 3 })
```

### Signature

```moonbit
fn memo[T](fn : () -> T) -> () -> T
fn computed[T](fn : () -> T) -> () -> T
```

## batch

Batch multiple signal updates to prevent redundant effect runs.

```moonbit
let a = Signal::new(0)
let b = Signal::new(0)

effect(fn() {
  println("Sum: \{a.get() + b.get()}")
})
// Prints: Sum: 0

batch(fn() {
  a.set(1)
  b.set(2)
  // Effect doesn't run during batch
})
// Prints: Sum: 3 (only once!)
```

### Batch Control

```moonbit
// Manual batch control
batch_start()
a.set(1)
b.set(2)
batch_end()  // Effects run here

// Check if currently batching
if is_batching() {
  println("Inside a batch")
}
```

## untracked

Read signals without creating a dependency.

```moonbit
let a = Signal::new(0)
let b = Signal::new(0)

effect(fn() {
  // Only tracks 'a', not 'b'
  let b_value = untracked(fn() { b.get() })
  println("\{a.get()}, \{b_value}")
})

a.set(1)  // Effect re-runs
b.set(1)  // Effect does NOT re-run
```

## on_cleanup

Register a cleanup function for the current effect.

```moonbit
let active = Signal::new(true)

effect(fn() {
  if active.get() {
    println("Starting...")
    on_cleanup(fn() {
      println("Cleaning up...")
    })
  }
})
```

### When Cleanup Runs

- Before the effect re-runs
- When the effect is disposed
- In reverse registration order (LIFO)

## Subscription API

### on / on_immediate

Subscribe to signal changes.

```moonbit
let sig = Signal::new(0)

// Subscribe to changes (not called with initial value)
let unsub = on(sig, fn(value) {
  println("Changed to: \{value}")
})

sig.set(1)  // Prints: Changed to: 1
sig.set(2)  // Prints: Changed to: 2
unsub()     // Unsubscribe
sig.set(3)  // Nothing printed

// Subscribe with immediate initial value
on_immediate(sig, fn(value) {
  println("Value: \{value}")
})
// Prints immediately: Value: 3
```

### watch / watch_immediate

Watch a computed expression for changes.

```moonbit
let sig = Signal::new(0)

// Watch for changes (with old value)
watch(fn() { sig.get() }, fn(new_val, old_val) {
  println("Changed from \{old_val} to \{new_val}")
})

sig.set(1)  // Prints: Changed from 0 to 1

// Watch with immediate call (old_val is None initially)
watch_immediate(fn() { sig.get() }, fn(new_val, old_val) {
  match old_val {
    Some(old) => println("Changed from \{old} to \{new_val}")
    None => println("Initial value: \{new_val}")
  }
})
```

### previous

Track the previous value of a signal.

```moonbit
let sig = Signal::new(1)
let prev = previous(sig)

assert_eq(prev(), None)  // No previous yet
sig.set(2)
assert_eq(prev(), Some(1))
sig.set(3)
assert_eq(prev(), Some(2))

// With initial previous value
let prev_with_init = previous_with_initial(sig, 0)
assert_eq(prev_with_init(), 3)  // Current previous
```

## Combinators

### combine

Combine multiple signals.

```moonbit
let a = Signal::new(1)
let b = Signal::new(2)
let c = Signal::new(3)

// Combine 2 signals
let sum2 = combine2(a, b, fn(x, y) { x + y })
assert_eq(sum2(), 3)

// Combine 3 signals
let sum3 = combine3(a, b, c, fn(x, y, z) { x + y + z })
assert_eq(sum3(), 6)

// Combine 4 signals available: combine4(a, b, c, d, fn)
```

### all / any

Boolean combinators for signal arrays.

```moonbit
let a = Signal::new(true)
let b = Signal::new(true)
let c = Signal::new(false)

// All true?
let all_true = all([a, b])
assert_eq(all_true(), true)

let all_true2 = all([a, b, c])
assert_eq(all_true2(), false)

// Any true?
let any_true = any([a, c])
assert_eq(any_true(), true)
```

### switch_

Select between signals based on condition.

```moonbit
let cond = Signal::new(true)
let on_true = Signal::new("yes")
let on_false = Signal::new("no")

let result = switch_(cond, on_true, on_false)
assert_eq(result(), "yes")

cond.set(false)
assert_eq(result(), "no")
```

### select

Select element from array by index.

```moonbit
let items = Signal::new([10, 20, 30, 40])
let index = Signal::new(1)

let selected = select(items, index)
assert_eq(selected(), Some(20))

index.set(5)  // Out of bounds
assert_eq(selected(), None)
```

### flatten

Flatten nested signals.

```moonbit
let inner = Signal::new(10)
let outer = Signal::new(inner)

let flattened = flatten(outer)
assert_eq(flattened(), 10)

inner.set(20)
assert_eq(flattened(), 20)

// Switching inner signal
let new_inner = Signal::new(30)
outer.set(new_inner)
assert_eq(flattened(), 30)
```

## Owner / Scope Management

### create_root

Create a root reactive scope that can dispose all nested effects.

```moonbit
let sig = Signal::new(0)
let effect_count = { val: 0 }

create_root(fn(dispose) {
  effect(fn() {
    let _ = sig.get()
    effect_count.val = effect_count.val + 1
  })

  sig.set(1)  // effect_count = 2
  dispose()   // Disposes all effects
})

sig.set(2)  // Effect does NOT run
```

### create_root_with_dispose

Returns both the result and dispose function.

```moonbit
let (result, dispose) = create_root_with_dispose(fn() {
  register_owner_cleanup(fn() { println("Cleanup!") })
  42
})
assert_eq(result, 42)
dispose()  // Prints: Cleanup!
```

### Owner utilities

```moonbit
// Check if inside an owner scope
assert_false(has_owner())  // false outside create_root

create_root(fn(_) {
  assert_true(has_owner())  // true inside

  // Get current owner
  let owner = get_owner()

  // Run code with saved owner later
  match owner {
    Some(o) => run_with_owner(o, fn() {
      // Has access to the owner's context
    })
    None => ()
  }
})
```

### on_mount

Run code once without tracking dependencies (like SolidJS onMount).

```moonbit
let sig = Signal::new(0)

create_root(fn(_) {
  on_mount(fn() {
    let _ = sig.get()  // Does NOT create dependency
    println("Mounted!")
  })
})

sig.set(1)  // on_mount does NOT re-run
```

## Context API

Provide and consume values through the component tree.

```moonbit
// Create a context with default value
let theme_ctx = create_context("light")

// Use context (returns default if not provided)
assert_eq(use_context(theme_ctx), "light")

// Provide context value in scope
let result = provide(theme_ctx, "dark", fn() {
  use_context(theme_ctx)  // "dark"
})
assert_eq(result, "dark")

// Nested provides
provide(theme_ctx, "outer", fn() {
  println(use_context(theme_ctx))  // "outer"
  provide(theme_ctx, "inner", fn() {
    println(use_context(theme_ctx))  // "inner"
  })
  println(use_context(theme_ctx))  // "outer" again
})
```

## Resource API

Handle async operations with loading/error states.

### Pre-resolved / Pre-rejected

```moonbit
// Create pre-resolved resource
let res = resource_resolved(42)
assert_true(res.is_success())
assert_eq(res.value(), Some(42))

// Create pre-rejected resource
let err_res : Resource[Int] = resource_rejected("error")
assert_true(err_res.is_failure())
assert_eq(err_res.error(), Some("error"))
```

### Deferred (Manual Control)

```moonbit
let (res, resolve, reject) : (Resource[Int], (Int) -> Unit, (String) -> Unit) = deferred()

assert_true(res.is_pending())

resolve(100)
assert_true(res.is_success())
assert_eq(res.value(), Some(100))

// Or reject:
// reject("Failed!")
// assert_true(res.is_failure())

// Refetch resets to pending
res.refetch()
assert_true(res.is_pending())
```

### Resource Methods

| Method | Description |
|--------|-------------|
| `.is_pending()` | True if loading |
| `.is_success()` | True if resolved |
| `.is_failure()` | True if rejected |
| `.value()` | Get resolved value (Option) |
| `.error()` | Get error message (Option) |
| `.peek()` | Get state without tracking |
| `.refetch()` | Reset to pending |

## API Summary

### Core

| Function | Description |
|----------|-------------|
| `Signal::new(value)` | Create a reactive signal |
| `effect(fn)` | Create side effect, returns dispose |
| `effect_when(cond, fn)` | Conditional effect |
| `effect_once(fn)` | One-time effect |
| `memo(fn)` / `computed(fn)` | Create cached computed |
| `batch(fn)` | Batch updates |
| `untracked(fn)` | Run without tracking |
| `on_cleanup(fn)` | Register cleanup |

### Subscription

| Function | Description |
|----------|-------------|
| `on(signal, fn)` | Subscribe to changes |
| `on_immediate(signal, fn)` | Subscribe with initial call |
| `watch(getter, callback)` | Watch computed value |
| `watch_immediate(getter, callback)` | Watch with initial call |
| `previous(signal)` | Track previous value |

### Combinators

| Function | Description |
|----------|-------------|
| `combine2/3/4(signals, fn)` | Combine signals |
| `all(signals)` | All true |
| `any(signals)` | Any true |
| `switch_(cond, a, b)` | Conditional select |
| `select(items, index)` | Index-based select |
| `flatten(nested)` | Flatten nested signal |

### Owner/Context

| Function | Description |
|----------|-------------|
| `create_root(fn)` | Create reactive scope |
| `create_root_with_dispose(fn)` | Returns (result, dispose) |
| `get_owner()` | Get current owner |
| `run_with_owner(owner, fn)` | Run with owner |
| `has_owner()` | Check if has owner |
| `on_mount(fn)` | Run once without tracking |
| `create_context(default)` | Create context |
| `use_context(ctx)` | Use context value |
| `provide(ctx, value, fn)` | Provide context |

### Resource

| Function | Description |
|----------|-------------|
| `resource_resolved(value)` | Pre-resolved resource |
| `resource_rejected(error)` | Pre-rejected resource |
| `deferred()` | Manual resource control |
