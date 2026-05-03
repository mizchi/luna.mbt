---
title: "Introduction: Memos"
---

# Memos

Memos are cached computed values that only recalculate when dependencies change.

## Creating a Memo

```moonbit
using @luna { signal, memo }

let count = signal(2)
let doubled = memo(fn() { count.get() * 2 })

println(doubled.get())  // 4

count.set(3)
println(doubled.get())  // 6
```

## Memos are Cached

Unlike regular functions, memos only recalculate when needed:

```moonbit
let count = signal(1)

let expensive = memo(fn() {
  println("Computing...")
  count.get() * 100
})

println(expensive.get())  // "Computing..." then "100"
println(expensive.get())  // Just "100" - cached!
println(expensive.get())  // Just "100" - still cached!

count.set(2)
println(expensive.get())  // "Computing..." then "200"
```

## Chaining Memos

Memos can depend on other memos:

```moonbit
let count = signal(2)
let doubled = memo(fn() { count.get() * 2 })
let quadrupled = memo(fn() { doubled.get() * 2 })

println(quadrupled.get())  // 8

count.set(3)
println(quadrupled.get())  // 12
```

## Memos in Effects

Effects can depend on memos:

```moonbit
let a = signal(2)
let b = signal(3)
let sum = memo(fn() { a.get() + b.get() })

effect(fn() {
  println("Sum: " + sum.get().to_string())
})
// Prints: Sum: 5

a.set(10)
// Prints: Sum: 13
```

## When to Use Memos

### Use Memos For

- Expensive calculations
- Derived values used in multiple places
- Filtering or transforming lists

```moonbit
let items = signal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

let even_items = memo(fn() {
  items.get().filter(fn(n) { n % 2 == 0 })
})

let even_count = memo(fn() {
  even_items.get().length()
})
```

### Don't Use Memos For

- Simple property access
- Values only used once

```moonbit
// Don't do this - overhead isn't worth it
let name_memo = memo(fn() { user.get().name })

// Just access directly
effect(fn() {
  println(user.get().name)
})
```

## Memos vs Effects

| Aspect | Memo | Effect |
|--------|------|--------|
| Returns | Value | Dispose function |
| Purpose | Compute derived values | Perform side effects |
| Re-runs | Only when dependencies change | When dependencies change |
| Caching | Yes | No |

```moonbit
// Memo: returns a value
let doubled = memo(fn() { count.get() * 2 })

// Effect: performs side effects
effect(fn() {
  println(count.get())  // Side effect: logging
})
```

## API Summary

| Function | Description |
|----------|-------------|
| `memo(fn)` | Create a cached computed value |
| `.get()` | Read the cached value |

## TypeScript Comparison

| TypeScript | MoonBit |
|------------|---------|
| `createMemo(() => count() * 2)` | `memo(fn() { count.get() * 2 })` |
| `doubled()` | `doubled.get()` |

## Try It

Create a shopping cart with:
1. An `items` signal (array of prices)
2. A `subtotal` memo (sum of prices)
3. A `tax` memo (10% of subtotal)
4. A `total` memo (subtotal + tax)

## Next

Learn about [Batch Updates →](./reactivity_batch)
