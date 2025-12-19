---
title: "Reactivity: Batch"
---

# Batch Updates

Batch multiple signal updates to trigger effects only once.

## The Problem

Without batching, each signal update triggers effects immediately:

```typescript
const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

createEffect(() => {
  console.log(`Name: ${firstName()} ${lastName()}`);
});

// Two separate updates = two effect runs
setFirstName("Jane");  // Effect runs: "Jane Doe"
setLastName("Smith");  // Effect runs: "Jane Smith"
```

This can cause:
- Unnecessary re-renders
- Inconsistent intermediate states
- Performance issues

## Using Batch

### TypeScript

```typescript
import { createSignal, createEffect, batch } from '@mizchi/luna';

const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

createEffect(() => {
  console.log(`Name: ${firstName()} ${lastName()}`);
});

// Batched = one effect run
batch(() => {
  setFirstName("Jane");
  setLastName("Smith");
});
// Effect runs once: "Jane Smith"
```

### MoonBit

```moonbit
///|
using @luna { signal, effect, batch }

let first_name = signal("John")
let last_name = signal("Doe")

let _ = effect(() => {
  println("Name: \{first_name.get()} \{last_name.get()}")
})

// Batched = one effect run
batch(() => {
  first_name.set("Jane")
  last_name.set("Smith")
})
// Prints once: "Name: Jane Smith"
```

## When to Use Batch

### Multiple Related Updates

```typescript
const [user, setUser] = createSignal(null);
const [loading, setLoading] = createSignal(true);
const [error, setError] = createSignal(null);

async function fetchUser() {
  setLoading(true);

  try {
    const data = await api.getUser();

    // Update all at once
    batch(() => {
      setUser(data);
      setLoading(false);
      setError(null);
    });
  } catch (e) {
    batch(() => {
      setUser(null);
      setLoading(false);
      setError(e.message);
    });
  }
}
```

### Form Updates

```typescript
const [form, setForm] = createSignal({
  name: "",
  email: "",
  phone: "",
});

function resetForm() {
  batch(() => {
    setName("");
    setEmail("");
    setPhone("");
  });
}
```

### State Machines

```typescript
const [status, setStatus] = createSignal("idle");
const [data, setData] = createSignal(null);
const [progress, setProgress] = createSignal(0);

function startDownload() {
  batch(() => {
    setStatus("downloading");
    setData(null);
    setProgress(0);
  });
}
```

## Batch is Synchronous

Batch executes synchronously and returns after all updates:

```typescript
const [count, setCount] = createSignal(0);

batch(() => {
  setCount(1);
  setCount(2);
  setCount(3);
});

console.log(count());  // 3 (immediately after batch)
```

## Nested Batches

Nested batches are flattened - effects run after the outermost batch:

```typescript
const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => console.log(a(), b()));

batch(() => {
  setA(1);

  batch(() => {
    setB(2);  // Still inside outer batch
  });

  setA(3);
});
// Effect runs once: 3, 2
```

## Batch with Return Value

Batch returns the value from its callback:

```typescript
const result = batch(() => {
  setA(1);
  setB(2);
  return a() + b();
});

console.log(result);  // 3
```

## Common Mistakes

### Async Inside Batch

Batch only affects synchronous code:

```typescript
// Wrong: async breaks batch
batch(async () => {
  setLoading(true);
  const data = await fetch(...);  // Batch ends here!
  setData(data);                   // Not batched
  setLoading(false);               // Not batched
});

// Correct: batch after async
async function load() {
  setLoading(true);
  const data = await fetch(...);

  batch(() => {
    setData(data);
    setLoading(false);
  });
}
```

## Try It

Create a color mixer with RGB sliders that only updates the preview once when all sliders change:

<details>
<summary>Solution</summary>

```typescript
const [r, setR] = createSignal(128);
const [g, setG] = createSignal(128);
const [b, setB] = createSignal(128);

const color = createMemo(() => `rgb(${r()}, ${g()}, ${b()})`);

createEffect(() => {
  console.log("Color updated:", color());
});

function setPreset(preset) {
  batch(() => {
    setR(preset.r);
    setG(preset.g);
    setB(preset.b);
  });
}

// Usage
setPreset({ r: 255, g: 0, b: 0 });  // One effect run
```

</details>

## Next

Learn about [Untrack →](./reactivity_untrack)
