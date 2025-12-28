---
title: "Lifecycle: onCleanup"
---

# onCleanup

Register cleanup functions to run when effects re-run or are disposed.

## Basic Usage

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

## When Cleanup Runs

### On Effect Re-run

```moonbit
let count = signal(0)

effect(fn() {
  let current = count.get()
  println("Setup for: " + current.to_string())

  on_cleanup(fn() {
    println("Cleanup for: " + current.to_string())
  })
})
// Prints: Setup for: 0

count.set(1)
// Prints: Cleanup for: 0
// Prints: Setup for: 1

count.set(2)
// Prints: Cleanup for: 1
// Prints: Setup for: 2
```

### On Effect Disposal

```moonbit
let dispose = effect(fn() {
  println("Running")

  on_cleanup(fn() {
    println("Disposed")
  })
})
// Prints: Running

dispose()
// Prints: Disposed
```

## Multiple Cleanups

You can register multiple cleanup functions:

```moonbit
effect(fn() {
  on_cleanup(fn() { println("Cleanup 1") })
  on_cleanup(fn() { println("Cleanup 2") })
  on_cleanup(fn() { println("Cleanup 3") })
})

// When effect re-runs or disposes:
// Prints: Cleanup 3
// Prints: Cleanup 2
// Prints: Cleanup 1
// (Reverse order - LIFO)
```

## Common Use Cases

### Timers (Conceptual)

Note: Server-side MoonBit doesn't have timers, but the pattern is useful for understanding:

```moonbit
// Conceptual example - for client-side understanding
effect(fn() {
  let interval = start_timer(1000)

  on_cleanup(fn() {
    stop_timer(interval)
  })
})
```

### Subscriptions

```moonbit
effect(fn() {
  let subscription = data_source.subscribe(fn(data) {
    println("Received: " + data.to_string())
  })

  on_cleanup(fn() {
    subscription.unsubscribe()
  })
})
```

### Resource Management

```moonbit
effect(fn() {
  let resource = acquire_resource()

  on_cleanup(fn() {
    release_resource(resource)
  })
})
```

## Cleanup in Nested Effects

Each effect level has its own cleanup scope:

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

// When outer re-runs:
// Inner cleanup
// Outer cleanup
// Outer setup
// Inner setup
```

## Client-Side Cleanup

For actual DOM cleanup, use TypeScript:

```typescript
// TypeScript (client-side)
import { onCleanup, createEffect } from '@luna_ui/luna';

function Timer() {
  createEffect(() => {
    const interval = setInterval(() => {
      console.log("tick");
    }, 1000);

    onCleanup(() => {
      clearInterval(interval);
    });
  });

  return <div>Timer running</div>;
}
```

## API Summary

| Function | Description |
|----------|-------------|
| `on_cleanup(fn)` | Register cleanup for current effect |

## Best Practices

1. **Always clean up resources** - Memory leaks are hard to debug
2. **Clean up in reverse order** - LIFO prevents dependency issues
3. **Keep cleanup simple** - Only release resources, don't add logic

```moonbit
// Good: Simple cleanup
on_cleanup(fn() {
  resource.close()
})

// Bad: Logic in cleanup
on_cleanup(fn() {
  if some_condition {
    do_something_complex()
  }
  resource.close()
})
```

## Try It

Create an effect that:
1. Tracks an `active` signal
2. Logs "Started" when active becomes true
3. Logs "Stopped" in cleanup when active becomes false

## Next

Learn about [Islands Basics →](./islands_basics)
