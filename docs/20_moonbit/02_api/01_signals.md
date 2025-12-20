---
title: Signals API
---

# Signals API

Signals are the foundation of Luna's reactivity system in MoonBit.

## signal

Create a reactive signal that holds a value.

```moonbit
using @luna { signal }

let count = signal(0)

// Read value
let value = count.get()  // 0

// Set value
count.set(5)

// Update with function
count.update(fn(n) { n + 1 })

// Read without tracking
let peeked = count.peek()
```

### Signature

```moonbit
fn signal[T](value : T) -> Signal[T]
```

### Signal Methods

| Method | Description |
|--------|-------------|
| `.get()` | Read value (tracks dependency) |
| `.set(value)` | Set new value |
| `.update(fn)` | Update based on current value |
| `.peek()` | Read without tracking |

## effect

Create a side effect that automatically tracks dependencies.

```moonbit
using @luna { signal, effect }

let name = signal("Luna")

let dispose = effect(fn() {
  println("Hello, " + name.get() + "!")
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

### Returns

A dispose function that stops the effect.

## memo

Create a cached computed value.

```moonbit
using @luna { signal, memo }

let count = signal(2)
let doubled = memo(fn() { count.get() * 2 })

println(doubled.get())  // 4

count.set(3)
println(doubled.get())  // 6
```

### Signature

```moonbit
fn memo[T](fn : () -> T) -> Memo[T]
```

### Memo Methods

| Method | Description |
|--------|-------------|
| `.get()` | Read cached value (tracks dependency) |

## batch

Batch multiple signal updates.

```moonbit
using @luna { signal, effect, batch }

let a = signal(0)
let b = signal(0)

effect(fn() {
  println("Sum: " + (a.get() + b.get()).to_string())
})
// Prints: Sum: 0

batch(fn() {
  a.set(1)
  b.set(2)
})
// Prints: Sum: 3 (only once!)
```

### Signature

```moonbit
fn batch[T](fn : () -> T) -> T
```

## untrack

Read signals without creating a dependency.

```moonbit
using @luna { signal, effect, untrack }

let a = signal(0)
let b = signal(0)

effect(fn() {
  // Only tracks 'a', not 'b'
  let b_value = untrack(fn() { b.get() })
  println(a.get().to_string() + ", " + b_value.to_string())
})
```

### Signature

```moonbit
fn untrack[T](fn : () -> T) -> T
```

## on_cleanup

Register a cleanup function for the current effect.

```moonbit
using @luna { signal, effect, on_cleanup }

let active = signal(true)

effect(fn() {
  if active.get() {
    println("Starting...")

    on_cleanup(fn() {
      println("Cleaning up...")
    })
  }
})
```

### Signature

```moonbit
fn on_cleanup(fn : () -> Unit) -> Unit
```

### When Cleanup Runs

- Before the effect re-runs
- When the effect is disposed
- In reverse registration order (LIFO)

## create_root

Create a root reactive scope.

```moonbit
using @luna { create_root, signal, effect }

let dispose = create_root(fn(dispose) {
  let count = signal(0)

  effect(fn() {
    println("Count: " + count.get().to_string())
  })

  dispose
})

// Later: dispose all effects
dispose()
```

### Signature

```moonbit
fn create_root[T](fn : (() -> Unit) -> T) -> T
```

## API Summary

| Function | Description |
|----------|-------------|
| `signal(value)` | Create a reactive signal |
| `effect(fn)` | Create a side effect, returns dispose |
| `memo(fn)` | Create a cached computed value |
| `batch(fn)` | Batch multiple updates |
| `untrack(fn)` | Run without tracking dependencies |
| `on_cleanup(fn)` | Register cleanup in effect |
| `create_root(fn)` | Create a root reactive scope |
