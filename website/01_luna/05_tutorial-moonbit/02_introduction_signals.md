---
title: "Introduction: Signals"
---

# Signals

Signals are reactive containers that hold values and notify subscribers when they change.

## Creating a Signal

```moonbit
using @luna { signal }

let count = signal(0)
```

## Reading Values

Use `.get()` to read the current value:

```moonbit
let count = signal(0)
let value = count.get()  // 0
```

## Setting Values

Use `.set()` to replace the value:

```moonbit
let count = signal(0)
count.set(5)
println(count.get())  // 5
```

## Updating Values

Use `.update()` to transform based on the current value:

```moonbit
let count = signal(0)
count.update(fn(n) { n + 1 })
println(count.get())  // 1

count.update(fn(n) { n * 2 })
println(count.get())  // 2
```

## Peeking Without Tracking

Use `.peek()` to read without creating a dependency:

```moonbit
let count = signal(0)

effect(fn() {
  // This effect won't re-run when count changes
  let value = count.peek()
  println("Peeked: " + value.to_string())
})
```

## Signals with Different Types

```moonbit
// String signal
let name = signal("Luna")
name.set("World")

// Boolean signal
let visible = signal(true)
visible.set(false)

// Struct signal
struct User {
  id : Int
  name : String
}

let user = signal(User { id: 1, name: "Alice" })
user.set(User { id: 2, name: "Bob" })
```

## Signal in Components

```moonbit
using @server_dom { div, p, text }
using @luna { signal }

fn greeting() -> @luna.Node {
  let name = signal("World")

  div([
    p([text("Hello, " + name.get() + "!")]),
  ])
}
```

## API Summary

| Method | Description |
|--------|-------------|
| `signal(value)` | Create a new signal |
| `.get()` | Read value (tracks dependency) |
| `.set(value)` | Set new value |
| `.update(fn)` | Update based on current value |
| `.peek()` | Read without tracking |

## TypeScript Comparison

| TypeScript | MoonBit |
|------------|---------|
| `const [count, setCount] = createSignal(0)` | `let count = signal(0)` |
| `count()` | `count.get()` |
| `setCount(5)` | `count.set(5)` |
| `setCount(c => c + 1)` | `count.update(fn(n) { n + 1 })` |

## Try It

Create a signal that:
1. Holds a username
2. Updates the username
3. Displays "Welcome, {username}!"

## Next

Learn about [Effects →](./introduction_effects)
