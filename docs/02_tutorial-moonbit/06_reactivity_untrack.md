---
title: "Reactivity: Untrack"
---

# Untrack

Read signals without creating dependencies.

## The Problem

Sometimes you need to read a signal's value without subscribing to its changes:

```typescript
const [count, setCount] = createSignal(0);
const [multiplier, setMultiplier] = createSignal(2);

createEffect(() => {
  // This effect runs when EITHER count OR multiplier changes
  console.log(count() * multiplier());
});
```

But what if you only want to react to `count` changes?

## Using Untrack

### TypeScript

```typescript
import { createSignal, createEffect, untrack } from '@mizchi/luna';

const [count, setCount] = createSignal(0);
const [multiplier, setMultiplier] = createSignal(2);

createEffect(() => {
  // Only tracks `count`, not `multiplier`
  const mult = untrack(() => multiplier());
  console.log(count() * mult);
});

setCount(5);        // Effect runs: 10
setMultiplier(3);   // Effect does NOT run
setCount(6);        // Effect runs: 18 (uses current multiplier)
```

### MoonBit

```moonbit
///|
using @luna { signal, effect, untrack }

let count = signal(0)
let multiplier = signal(2)

let _ = effect(() => {
  // Only tracks `count`, not `multiplier`
  let mult = untrack(() => multiplier.get())
  println("\{count.get() * mult}")
})
```

## Untrack vs Peek

Both read without tracking, but:

| Method | Scope | Use Case |
|--------|-------|----------|
| `peek()` | Single signal | Quick access to one signal |
| `untrack()` | Any code block | Multiple operations, function calls |

```typescript
const [a, setA] = createSignal(1);
const [b, setB] = createSignal(2);

createEffect(() => {
  // peek: single signal
  const valA = a.peek();

  // untrack: multiple operations
  const sum = untrack(() => a() + b());
});
```

## Common Use Cases

### Logging Without Subscribing

```typescript
const [user, setUser] = createSignal(null);

createEffect(() => {
  const u = user();
  if (u) {
    // Log other state without subscribing
    untrack(() => {
      console.log("User logged in:", u.name);
      console.log("Current page:", page());
      console.log("Session:", session());
    });
  }
});
```

### Conditional Initial Values

```typescript
const [items, setItems] = createSignal([]);
const [defaultSort, setDefaultSort] = createSignal("name");

createEffect(() => {
  const newItems = items();

  // Use default sort only for initial value, don't track it
  const sortBy = untrack(() => defaultSort());

  displaySorted(newItems, sortBy);
});
```

### Comparing Values

```typescript
const [current, setCurrent] = createSignal(0);
const [previous, setPrevious] = createSignal(0);

createEffect(() => {
  const curr = current();

  // Compare with previous without tracking it
  const prev = untrack(() => previous());

  if (curr !== prev) {
    console.log(`Changed from ${prev} to ${curr}`);
    setPrevious(curr);
  }
});
```

### Event Handlers

```typescript
const [count, setCount] = createSignal(0);
const [step, setStep] = createSignal(1);

function Counter() {
  return (
    <button onClick={() => {
      // Read step without tracking (we're not in a reactive context anyway,
      // but untrack makes intent clear)
      const s = untrack(() => step());
      setCount(c => c + s);
    }}>
      +{step()}
    </button>
  );
}
```

## Untrack Entire Functions

Wrap function calls that shouldn't create dependencies:

```typescript
function getConfig() {
  return {
    theme: theme(),
    lang: language(),
    debug: debugMode(),
  };
}

createEffect(() => {
  const data = fetchData();

  // getConfig reads signals, but we don't want to track them
  const config = untrack(() => getConfig());

  process(data, config);
});
```

## Untrack in Memos

Control which dependencies trigger recomputation:

```typescript
const [items, setItems] = createSignal([]);
const [sortBy, setSortBy] = createSignal("name");
const [filterText, setFilterText] = createSignal("");

// Only recompute when items or filterText change, not sortBy
const filtered = createMemo(() => {
  const sort = untrack(() => sortBy());

  return items()
    .filter(i => i.name.includes(filterText()))
    .sort((a, b) => a[sort].localeCompare(b[sort]));
});
```

## Try It

Create an effect that logs when `count` changes, including the current `timestamp` signal value, but only re-runs when `count` changes:

<details>
<summary>Solution</summary>

```typescript
const [count, setCount] = createSignal(0);
const [timestamp, setTimestamp] = createSignal(Date.now());

// Update timestamp periodically
setInterval(() => setTimestamp(Date.now()), 1000);

createEffect(() => {
  const c = count();
  const ts = untrack(() => timestamp());

  console.log(`Count: ${c} at ${new Date(ts).toISOString()}`);
});

// Effect only runs when count changes, not every second
```

</details>

## Next

Learn about [Nested Effects →](./reactivity_nested)
