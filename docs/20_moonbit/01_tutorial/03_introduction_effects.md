---
title: "Introduction: Effects"
---

# Effects

Effects are functions that run automatically when their dependencies change.

## Creating an Effect

```moonbit
using @luna { signal, effect }

let count = signal(0)

let dispose = effect(fn() {
  println("Count: " + count.get().to_string())
})
// Prints: Count: 0

count.set(1)
// Prints: Count: 1
```

## Automatic Dependency Tracking

Effects track any signals accessed inside them:

```moonbit
let a = signal(1)
let b = signal(2)

effect(fn() {
  // Tracks both 'a' and 'b'
  println("Sum: " + (a.get() + b.get()).to_string())
})
// Prints: Sum: 3

a.set(10)
// Prints: Sum: 12

b.set(20)
// Prints: Sum: 30
```

## Disposing Effects

Effects return a dispose function:

```moonbit
let count = signal(0)

let dispose = effect(fn() {
  println("Count: " + count.get().to_string())
})
// Prints: Count: 0

count.set(1)
// Prints: Count: 1

dispose()  // Stop the effect

count.set(2)
// Nothing printed - effect is disposed
```

## Conditional Dependencies

Dependencies are tracked dynamically:

```moonbit
let show_details = signal(false)
let name = signal("Luna")
let details = signal("A reactive UI library")

effect(fn() {
  if show_details.get() {
    // 'details' is only tracked when show_details is true
    println(name.get() + ": " + details.get())
  } else {
    println(name.get())
  }
})
// Prints: Luna

details.set("Updated details")
// Nothing printed - 'details' isn't tracked yet

show_details.set(true)
// Prints: Luna: Updated details

details.set("New details")
// Prints: Luna: New details
```

## Effects with Cleanup

Use `on_cleanup` to register cleanup functions:

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
// Prints: Starting...

active.set(false)
// Prints: Cleaning up...
```

## Nested Signal Access

```moonbit
struct User {
  name : String
  active : Bool
}

let user = signal(User { name: "Alice", active: true })

effect(fn() {
  let u = user.get()
  if u.active {
    println("Active user: " + u.name)
  }
})
```

## API Summary

| Function | Description |
|----------|-------------|
| `effect(fn)` | Create an effect, returns dispose function |
| `on_cleanup(fn)` | Register cleanup for current effect |

## Common Patterns

### Logging

```moonbit
let count = signal(0)

effect(fn() {
  println("Debug: count = " + count.get().to_string())
})
```

### Derived State

```moonbit
let items = signal([1, 2, 3, 4, 5])
let count = signal(0)

effect(fn() {
  count.set(items.get().length())
})
```

## Try It

Create an effect that:
1. Tracks a `temperature` signal
2. Prints "Cold" if below 10, "Warm" if above
3. Uses cleanup to log when the effect re-runs

## Next

Learn about [Memos →](./introduction_memos)
