---
title: Signals API
---

# Signals API

Signals are the foundation of Luna's reactivity system. The API is compatible with SolidJS.

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
function createEffect(fn: () => void): () => void;
```

Returns a dispose function to stop the effect.

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

## batch

Batch multiple signal updates to avoid redundant effect runs.

```typescript
import { createSignal, createEffect, batch } from '@mizchi/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => {
  console.log(`a=${a()}, b=${b()}`);
});
// Logs: a=0, b=0

batch(() => {
  setA(1);
  setB(2);
  // Effect doesn't run during batch
});
// Logs: a=1, b=2 (only once!)
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

setA(1);  // Effect re-runs
setB(1);  // Effect does NOT re-run
```

## onCleanup

Register a cleanup function that runs before an effect re-runs or when disposed.

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

## onMount

Run code once without tracking dependencies (like a mount lifecycle).

```typescript
import { createSignal, onMount } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

onMount(() => {
  console.log(count());  // Does NOT create dependency
  console.log("Mounted!");
});

setCount(1);  // onMount does NOT re-run
```

## on

Explicit dependency tracking helper (SolidJS-style).

```typescript
import { createSignal, createEffect, on } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

// Track single dependency
createEffect(on(count, (value, prev) => {
  console.log(`Changed from ${prev} to ${value}`);
}));

// Track multiple dependencies
const [a, setA] = createSignal(1);
const [b, setB] = createSignal(2);

createEffect(on([a, b], ([aVal, bVal], prev) => {
  console.log(`a=${aVal}, b=${bVal}`);
}));

// Defer option - skip initial run
createEffect(on(count, (value) => {
  console.log(`Count changed to ${value}`);
}, { defer: true }));  // Won't run immediately
```

### Signature

```typescript
function on<T, U>(
  deps: Accessor<T>,
  fn: (input: T, prevInput: T | undefined) => U,
  options?: { defer?: boolean }
): () => U | undefined;

// Multiple dependencies
function on<T extends readonly Accessor<any>[], U>(
  deps: T,
  fn: (input: [...], prevInput: [...] | undefined) => U,
  options?: { defer?: boolean }
): () => U | undefined;
```

## createRoot

Create a reactive scope that can dispose all nested effects.

```typescript
import { createSignal, createEffect, createRoot } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

createRoot((dispose) => {
  createEffect(() => {
    console.log(`Count: ${count()}`);
  });

  setCount(1);  // Effect runs
  dispose();    // Disposes all effects
});

setCount(2);  // Effect does NOT run
```

## Owner Utilities

```typescript
import { createRoot, getOwner, runWithOwner, hasOwner } from '@mizchi/luna';

// Check if inside an owner scope
console.log(hasOwner());  // false outside createRoot

createRoot(() => {
  console.log(hasOwner());  // true inside

  const owner = getOwner();

  // Later, run code with saved owner context
  setTimeout(() => {
    runWithOwner(owner, () => {
      // Has access to the owner's reactive context
    });
  }, 1000);
});
```

## Context API

Provide and consume values through the component tree.

```typescript
import { createContext, useContext, provide, Provider } from '@mizchi/luna';

// Create context with default value
const ThemeContext = createContext('light');

// Use context value
const theme = useContext(ThemeContext);  // 'light'

// Provide value with function scope
const result = provide(ThemeContext, 'dark', () => {
  return useContext(ThemeContext);  // 'dark'
});

// Or use Provider component
<Provider context={ThemeContext} value="dark">
  <App />
</Provider>
```

## Resource API

Handle async operations with loading/error states.

```typescript
import { createResource, createDeferred } from '@mizchi/luna';

// Create resource with fetcher
const [data, { refetch }] = createResource((resolve, reject) => {
  fetch('/api/data')
    .then(r => r.json())
    .then(resolve)
    .catch(e => reject(e.message));
});

// Access resource
data();         // value or undefined
data.loading;   // boolean
data.error;     // string or undefined
data.state;     // 'unresolved' | 'pending' | 'ready' | 'errored'
data.latest;    // last successful value

// Refetch
refetch();

// Manual control with deferred
const [resource, resolve, reject] = createDeferred<number>();
// Later...
resolve(42);
// Or...
reject("Failed!");
```

## Store API

Create reactive stores with nested property tracking.

```typescript
import { createStore, produce, reconcile } from '@mizchi/luna';

const [state, setState] = createStore({
  count: 0,
  user: { name: "John", age: 30 }
});

// Read (reactive)
state.count;
state.user.name;

// Update by path
setState("count", 1);
setState("user", "name", "Jane");

// Functional update
setState("count", c => c + 1);

// Object merge at path
setState("user", { name: "Jane", age: 25 });

// Immer-style mutations with produce
setState("user", produce(user => {
  user.name = "Alice";
  user.age = 28;
}));

// Replace entire value with reconcile
setState("items", reconcile(newItems));
```

## Utility Functions

### mergeProps

Merge multiple props objects.

```typescript
import { mergeProps } from '@mizchi/luna';

const defaults = { color: 'blue', size: 'medium' };
const props = { color: 'red' };

const merged = mergeProps(defaults, props);
// { color: 'red', size: 'medium' }

// Event handlers are merged (both run)
const a = { onClick: () => console.log('a') };
const b = { onClick: () => console.log('b') };
mergeProps(a, b).onClick();  // Logs: 'a', 'b'

// Classes are concatenated
mergeProps({ class: 'foo' }, { class: 'bar' });
// { class: 'foo bar' }
```

### splitProps

Split props into groups.

```typescript
import { splitProps } from '@mizchi/luna';

const props = { a: 1, b: 2, c: 3, d: 4 };

const [local, others] = splitProps(props, ['a', 'b']);
// local = { a: 1, b: 2 }
// others = { c: 3, d: 4 }

// Multiple groups
const [group1, group2, rest] = splitProps(props, ['a'], ['b', 'c']);
// group1 = { a: 1 }
// group2 = { b: 2, c: 3 }
// rest = { d: 4 }
```

## API Summary

### Core Reactivity

| Function | Description |
|----------|-------------|
| `createSignal(value)` | Create a reactive signal |
| `createEffect(fn)` | Create a side effect |
| `createMemo(fn)` | Create a cached computed value |
| `batch(fn)` | Batch multiple updates |
| `untrack(fn)` | Run without tracking dependencies |
| `onCleanup(fn)` | Register cleanup in effect |
| `onMount(fn)` | Run once without tracking |
| `on(deps, fn, opts)` | Explicit dependency tracking |

### Scope Management

| Function | Description |
|----------|-------------|
| `createRoot(fn)` | Create reactive scope |
| `getOwner()` | Get current owner |
| `runWithOwner(owner, fn)` | Run with owner context |
| `hasOwner()` | Check if has owner |

### Context

| Function | Description |
|----------|-------------|
| `createContext(default)` | Create context |
| `useContext(ctx)` | Use context value |
| `provide(ctx, value, fn)` | Provide context in scope |

### Async

| Function | Description |
|----------|-------------|
| `createResource(fetcher)` | Create async resource |
| `createDeferred()` | Create manual resource |

### Store

| Function | Description |
|----------|-------------|
| `createStore(value)` | Create reactive store |
| `produce(fn)` | Immer-style mutations |
| `reconcile(value)` | Replace value |

### Utilities

| Function | Description |
|----------|-------------|
| `mergeProps(...sources)` | Merge props objects |
| `splitProps(props, keys...)` | Split props into groups |
