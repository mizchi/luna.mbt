---
title: "Reactivity: Batch"
---

# Batch Updates

Batch multiple signal updates to avoid redundant effect executions.

## The Problem

Without batching, each update triggers effects immediately:

```moonbit
let a = signal(0)
let b = signal(0)

effect(fn() {
  println("Sum: " + (a.get() + b.get()).to_string())
})
// Prints: Sum: 0

a.set(1)
// Prints: Sum: 1

b.set(2)
// Prints: Sum: 3

// Effect ran 3 times total!
```

## The Solution

Use `batch` to defer effect execution:

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
// Prints: Sum: 3

// Effect ran only 2 times total!
```

## Nested Batches

Batches can be nested - effects run after the outermost batch:

```moonbit
batch(fn() {
  a.set(1)

  batch(fn() {
    b.set(2)
    c.set(3)
  })

  d.set(4)
})
// Effects run once here, after all updates
```

## Batch Return Values

Batch returns the value from the function:

```moonbit
let result = batch(fn() {
  a.set(1)
  b.set(2)
  a.get() + b.get()
})
// result = 3
```

## Common Use Cases

### Form Updates

```moonbit
fn update_form(name : String, email : String, age : Int) {
  batch(fn() {
    name_signal.set(name)
    email_signal.set(email)
    age_signal.set(age)
  })
}
```

### List Operations

```moonbit
fn add_items(items : Array[Item]) {
  batch(fn() {
    for item in items {
      item_list.update(fn(list) {
        list.push(item)
        list
      })
    }
  })
}
```

### State Reset

```moonbit
fn reset_state() {
  batch(fn() {
    count.set(0)
    name.set("")
    items.set([])
    error.set(None)
  })
}
```

## When to Use Batch

| Scenario | Use Batch? |
|----------|------------|
| Single update | No |
| Multiple related updates | Yes |
| Loop with updates | Yes |
| Independent updates | Optional |

## API Summary

| Function | Description |
|----------|-------------|
| `batch(fn)` | Execute function, defer effects until completion |

## Try It

Create a counter with:
1. `count` and `history` signals
2. An `increment` function that updates both
3. Use batch to update them together

## Next

Learn about [Untrack →](./reactivity_untrack)
