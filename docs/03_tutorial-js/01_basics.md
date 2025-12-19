---
title: "Basics"
---

# Basics

Learn the core concepts of Luna's reactivity system in JavaScript.

## Signals

Signals are reactive containers that hold values and notify subscribers when they change.

```typescript
import { createSignal } from '@mizchi/luna';

// Create a signal with initial value
const [count, setCount] = createSignal(0);

// Read the current value
console.log(count()); // 0

// Update the value
setCount(5);
console.log(count()); // 5

// Update based on previous value
setCount(c => c + 1);
console.log(count()); // 6
```

## Effects

Effects run side effects when their dependencies change.

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [name, setName] = createSignal("World");

// This effect runs whenever `name` changes
createEffect(() => {
  console.log(`Hello, ${name()}!`);
});
// Logs: Hello, World!

setName("Luna");
// Logs: Hello, Luna!
```

## Memos

Memos are computed values that cache their results.

```typescript
import { createSignal, createMemo } from '@mizchi/luna';

const [firstName, setFirstName] = createSignal("Luna");
const [lastName, setLastName] = createSignal("UI");

// Memo only recomputes when dependencies change
const fullName = createMemo(() => `${firstName()} ${lastName()}`);

console.log(fullName()); // "Luna UI"

setFirstName("Sol");
console.log(fullName()); // "Sol UI"
```

## Cleanup

Clean up resources when effects re-run or components unmount.

```typescript
import { createSignal, createEffect, onCleanup } from '@mizchi/luna';

const [active, setActive] = createSignal(true);

createEffect(() => {
  if (active()) {
    const timer = setInterval(() => console.log("tick"), 1000);

    // Cleanup runs before the effect re-runs
    onCleanup(() => {
      clearInterval(timer);
      console.log("cleaned up");
    });
  }
});

// Later: stop the timer
setActive(false);
// Logs: cleaned up
```

## Batch Updates

Group multiple updates into a single reactive flush.

```typescript
import { createSignal, createEffect, batch } from '@mizchi/luna';

const [a, setA] = createSignal(1);
const [b, setB] = createSignal(2);

createEffect(() => {
  console.log(`a=${a()}, b=${b()}`);
});
// Logs: a=1, b=2

// Without batch: effect runs twice
setA(10);  // Logs: a=10, b=2
setB(20);  // Logs: a=10, b=20

// With batch: effect runs once
batch(() => {
  setA(100);
  setB(200);
});
// Logs: a=100, b=200
```

## Next Steps

- [Components](/tutorial-js/components) - Build reactive UI components
- [Islands](/tutorial-js/islands) - Partial hydration patterns
