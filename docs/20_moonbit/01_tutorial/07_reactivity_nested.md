---
title: "Reactivity: Nested Effects"
---

# Nested Effects

Understanding how effects compose and clean up.

## Effects Can Contain Effects

```moonbit
using @luna { signal, effect, on_cleanup }

let show = signal(true)
let count = signal(0)

effect(fn() {
  if show.get() {
    println("Outer effect: showing")

    // Inner effect
    effect(fn() {
      println("Inner effect: count = " + count.get().to_string())
    })
  }
})
```

## Lifecycle of Nested Effects

```
show = true
├── Outer runs
│   └── Inner created, runs with count=0
│
count = 1
│   └── Inner re-runs with count=1
│
show = false
├── Outer re-runs
│   └── Inner is disposed (cleanup runs)
```

## Automatic Cleanup

Inner effects are automatically disposed when the outer effect re-runs:

```moonbit
let category = signal("books")
let search = signal("")

effect(fn() {
  let cat = category.get()
  println("Category: " + cat)

  // This inner effect is disposed when category changes
  effect(fn() {
    let query = search.get()
    println("Searching " + cat + " for: " + query)
  })
})
```

## Cleanup Order

Cleanup runs in reverse order (LIFO):

```moonbit
effect(fn() {
  println("Outer setup")
  on_cleanup(fn() { println("Outer cleanup") })

  effect(fn() {
    println("Inner setup")
    on_cleanup(fn() { println("Inner cleanup") })
  })
})
// Output:
// Outer setup
// Inner setup

// When re-running:
// Inner cleanup
// Outer cleanup
// Outer setup
// Inner setup
```

## Common Patterns

### Conditional Subscriptions

```moonbit
let enabled = signal(true)
let data = signal(0)

effect(fn() {
  if enabled.get() {
    effect(fn() {
      println("Data: " + data.get().to_string())
    })
  }
})

// Data changes are only tracked when enabled=true
```

### Dynamic Effect Count

```moonbit
let items = signal([1, 2, 3])

effect(fn() {
  for item in items.get() {
    effect(fn() {
      println("Item: " + item.to_string())
    })
  }
})

// Each item gets its own effect
// All are disposed when items changes
```

### Resource Per Item

```moonbit
let connections = signal(["ws://a", "ws://b"])

effect(fn() {
  for url in connections.get() {
    effect(fn() {
      println("Connecting to: " + url)
      on_cleanup(fn() {
        println("Disconnecting from: " + url)
      })
    })
  }
})
```

## Avoiding Deep Nesting

Deep nesting can be hard to follow. Consider extracting to functions:

```moonbit
// Instead of deep nesting
effect(fn() {
  effect(fn() {
    effect(fn() {
      // ...
    })
  })
})

// Extract to named effects
fn setup_outer() {
  effect(fn() {
    setup_inner()
  })
}

fn setup_inner() {
  effect(fn() {
    // ...
  })
}
```

## Root Effects

Use `create_root` for top-level effect management:

```moonbit
using @luna { create_root }

let dispose = create_root(fn(dispose) {
  effect(fn() {
    // This effect and all nested effects
    // can be disposed with dispose()
  })

  dispose  // Return dispose function
})

// Later: dispose all effects
dispose()
```

## Try It

Create a nested effect structure where:
1. Outer effect tracks a `tab` signal
2. Inner effect tracks content specific to that tab
3. Verify inner effect is disposed on tab change

## Next

Learn about [Show →](./flow_show)
