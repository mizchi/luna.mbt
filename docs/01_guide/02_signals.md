---
title: Signals
---

# Signals

Signals are the foundation of Luna's reactivity system. They hold values and automatically track dependencies.

## Creating Signals

```typescript
import { createSignal } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

// Read the value
console.log(count());  // 0

// Set a new value
setCount(5);
console.log(count());  // 5

// Update based on previous value
setCount(c => c + 1);
console.log(count());  // 6
```

## Effects

Effects run automatically when their dependencies change:

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [name, setName] = createSignal("Luna");

createEffect(() => {
  console.log(`Hello, ${name()}!`);
});
// Logs: Hello, Luna!

setName("World");
// Logs: Hello, World!
```

## Memos (Computed Values)

Memos cache computed values:

```typescript
import { createSignal, createMemo } from '@mizchi/luna';

const [count, setCount] = createSignal(2);
const squared = createMemo(() => count() ** 2);

console.log(squared());  // 4

setCount(3);
console.log(squared());  // 9
```

## Batching Updates

Batch multiple updates to avoid redundant effect runs:

```typescript
import { createSignal, batch } from '@mizchi/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

batch(() => {
  setA(1);
  setB(2);
  // Effect only runs once after batch completes
});
```

## Cleanup

Register cleanup functions inside effects:

```typescript
import { createSignal, createEffect, onCleanup } from '@mizchi/luna';

const [active, setActive] = createSignal(true);

createEffect(() => {
  if (active()) {
    const interval = setInterval(() => console.log("tick"), 1000);
    onCleanup(() => clearInterval(interval));
  }
});
```

## MoonBit API

```moonbit
// Create a signal
let count = @luna.signal(0)

// Read value
let value = count.get()

// Set value
count.set(5)

// Update with function
count.update(fn(n) { n + 1 })

// Peek without tracking
let peeked = count.peek()

// Create memo
let doubled = @luna.memo(fn() { count.get() * 2 })

// Create effect
let dispose = @luna.effect(fn() {
  println("Count: \{count.get()}")
  @luna.on_cleanup(fn() { println("Cleanup") })
})

// Dispose effect
dispose()
```

## API Reference

| Function | Description |
|----------|-------------|
| `createSignal(value)` | Create a reactive signal |
| `createEffect(fn)` | Create a side effect |
| `createMemo(fn)` | Create a cached computed value |
| `batch(fn)` | Batch multiple updates |
| `untrack(fn)` | Run without tracking dependencies |
| `onCleanup(fn)` | Register cleanup in effect |
