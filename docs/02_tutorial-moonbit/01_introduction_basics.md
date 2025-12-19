---
title: "Introduction: Basics"
---

# Basics

Welcome to Luna! Let's build your first reactive component.

## What is Luna?

Luna is a fine-grained reactive UI framework. Unlike Virtual DOM frameworks that re-render entire component trees, Luna updates only the exact DOM nodes that need to change.

```
Virtual DOM:  State → Render → Diff → Patch
Luna:         State → Direct Update
```

## Your First Component

Here's a simple counter:

### TypeScript

```typescript
import { createSignal } from '@mizchi/luna';

function Counter() {
  // Create reactive state
  const [count, setCount] = createSignal(0);

  return (
    <div>
      <p>Count: {count()}</p>
      <button onClick={() => setCount(c => c + 1)}>
        Increment
      </button>
    </div>
  );
}
```

### MoonBit

```moonbit
///|
using @element {
  div, p, button, text, text_dyn, events,
  type DomNode,
}
using @luna { signal }

fn counter() -> DomNode {
  // Create reactive state
  let count = signal(0)

  div([
    p([text_dyn(() => "Count: " + count.get().to_string())]),
    button(
      on=events().click(_ => count.update(n => n + 1)),
      [text("Increment")],
    ),
  ])
}
```

The `using` declaration imports specific items into the local scope, allowing cleaner DSL-style code without module prefixes.

## Key Concepts

### 1. Signals Hold State

```typescript
const [value, setValue] = createSignal(initialValue);
```

- `value()` - Read the current value (getter)
- `setValue(newValue)` - Set a new value (setter)

### 2. Reading Creates Dependencies

When you call `count()` inside JSX or an effect, Luna tracks that as a dependency. When `count` changes, only those specific parts update.

```typescript
// This text node subscribes to count
<p>Count: {count()}</p>
```

### 3. No Re-renders

Unlike React, the component function runs **once**. Only the reactive parts update:

```typescript
function Counter() {
  console.log("This runs once!");  // Not on every update

  const [count, setCount] = createSignal(0);

  return <p>Count: {count()}</p>;  // Only this text updates
}
```

## Try It

Modify the counter to:

1. Add a "Decrement" button
2. Add a "Reset" button that sets count to 0
3. Display whether the count is even or odd

<details>
<summary>Solution</summary>

```typescript
function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <div>
      <p>Count: {count()}</p>
      <p>{count() % 2 === 0 ? "Even" : "Odd"}</p>
      <button onClick={() => setCount(c => c + 1)}>+</button>
      <button onClick={() => setCount(c => c - 1)}>-</button>
      <button onClick={() => setCount(0)}>Reset</button>
    </div>
  );
}
```

</details>

## Next

Learn more about [Signals →](./introduction_signals)
