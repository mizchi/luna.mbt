---
title: "Reactivity: Untrack"
---

# Untrack

Read signals without creating dependencies.

## The Problem

By default, any signal read inside an effect creates a dependency:

```moonbit
let count = signal(0)
let multiplier = signal(2)

effect(fn() {
  // This effect re-runs when EITHER signal changes
  println((count.get() * multiplier.get()).to_string())
})
```

## The Solution

Use `untrack` to read without tracking:

```moonbit
using @luna { signal, effect, untrack }

let count = signal(0)
let multiplier = signal(2)

effect(fn() {
  // Only re-runs when count changes
  let mult = untrack(fn() { multiplier.get() })
  println((count.get() * mult).to_string())
})
```

## Using peek()

Signals also have a `.peek()` method:

```moonbit
let count = signal(0)
let multiplier = signal(2)

effect(fn() {
  // Only re-runs when count changes
  println((count.get() * multiplier.peek()).to_string())
})
```

## untrack vs peek

| Method | Use Case |
|--------|----------|
| `untrack(fn)` | Untrack multiple reads or complex expressions |
| `.peek()` | Untrack a single signal read |

```moonbit
// Use peek for single signal
let value = count.peek()

// Use untrack for multiple signals
let result = untrack(fn() {
  a.get() + b.get() + c.get()
})
```

## Common Use Cases

### Logging Without Re-triggering

```moonbit
effect(fn() {
  let value = count.get()

  // Log debug info without tracking
  let debug = untrack(fn() {
    "Count=" + count.peek().to_string() +
    " at " + timestamp.peek()
  })
  println(debug)
})
```

### Conditional Logic

```moonbit
effect(fn() {
  let value = count.get()

  // Check config without tracking it
  if untrack(fn() { config.get().verbose }) {
    println("Verbose: " + value.to_string())
  }
})
```

### Comparison with Previous Value

```moonbit
let count = signal(0)
let prev = signal(0)

effect(fn() {
  let current = count.get()
  let previous = prev.peek()  // Don't track prev

  if current != previous {
    println("Changed from " + previous.to_string() + " to " + current.to_string())
    prev.set(current)
  }
})
```

## Caution

Overusing untrack can lead to stale data:

```moonbit
// Dangerous: display won't update when user changes
effect(fn() {
  let id = user_id.get()
  let user = untrack(fn() { users.get()[id] })  // Won't update!
  display_user(user)
})
```

## API Summary

| Function | Description |
|----------|-------------|
| `untrack(fn)` | Execute function without tracking |
| `.peek()` | Read signal without tracking |

## Try It

Create an effect that:
1. Tracks a `query` signal for search
2. Uses `limit` without tracking (config value)
3. Logs results

## Next

Learn about [Nested Effects →](./reactivity_nested)
