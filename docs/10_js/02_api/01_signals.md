---
title: Signals API
---

# Signals API

Signals are the foundation of Luna's reactivity system. They hold values and automatically track dependencies.

## createSignal

Create a reactive signal that holds a value.

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

### Signature

```typescript
function createSignal<T>(value: T): [Accessor<T>, Setter<T>];

type Accessor<T> = () => T;
type Setter<T> = (value: T | ((prev: T) => T)) => void;
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | `T` | Initial value |

### Returns

A tuple of `[accessor, setter]`:
- `accessor()` - Function to read the current value
- `setter(value)` - Function to update the value

## createEffect

Create a side effect that automatically tracks and re-runs when dependencies change.

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

### Signature

```typescript
function createEffect(fn: () => void): void;
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fn` | `() => void` | Effect function that tracks dependencies |

## createMemo

Create a cached computed value that updates when dependencies change.

```typescript
import { createSignal, createMemo } from '@mizchi/luna';

const [count, setCount] = createSignal(2);
const squared = createMemo(() => count() ** 2);

console.log(squared());  // 4

setCount(3);
console.log(squared());  // 9
```

### Signature

```typescript
function createMemo<T>(fn: () => T): Accessor<T>;
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fn` | `() => T` | Computation function |

### Returns

An accessor function that returns the cached value.

## batch

Batch multiple signal updates to avoid redundant effect runs.

```typescript
import { createSignal, createEffect, batch } from '@mizchi/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => {
  console.log(`a=${a()}, b=${b()}`);
});

batch(() => {
  setA(1);
  setB(2);
  // Effect only runs once after batch completes
});
```

### Signature

```typescript
function batch<T>(fn: () => T): T;
```

## untrack

Read signals without creating a dependency.

```typescript
import { createSignal, createEffect, untrack } from '@mizchi/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => {
  // Only tracks 'a', not 'b'
  console.log(a(), untrack(() => b()));
});
```

### Signature

```typescript
function untrack<T>(fn: () => T): T;
```

## onCleanup

Register a cleanup function that runs when an effect re-runs or a component unmounts.

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

### Signature

```typescript
function onCleanup(fn: () => void): void;
```

## onMount

Run code once when a component mounts to the DOM.

```typescript
import { onMount } from '@mizchi/luna';

function MyComponent() {
  onMount(() => {
    console.log("Component mounted!");
  });

  return <div>Hello</div>;
}
```

### Signature

```typescript
function onMount(fn: () => void): void;
```

## API Summary

| Function | Description |
|----------|-------------|
| `createSignal(value)` | Create a reactive signal |
| `createEffect(fn)` | Create a side effect |
| `createMemo(fn)` | Create a cached computed value |
| `batch(fn)` | Batch multiple updates |
| `untrack(fn)` | Run without tracking dependencies |
| `onCleanup(fn)` | Register cleanup in effect |
| `onMount(fn)` | Run code when component mounts |
