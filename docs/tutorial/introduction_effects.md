---
title: "Introduction: Effects"
---

# Effects

Effects are functions that run automatically when their dependencies change.

## Creating Effects

### TypeScript

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  console.log("Count is:", count());
});

// Logs: "Count is: 0"

setCount(1);
// Logs: "Count is: 1"

setCount(2);
// Logs: "Count is: 2"
```

### MoonBit

```moonbit
let count = @luna.signal(0)

@luna.effect(fn() {
  println("Count is: \{count.get()}")
})

// Prints: "Count is: 0"

count.set(1)
// Prints: "Count is: 1"
```

## Automatic Dependency Tracking

Effects automatically track which signals they read:

```typescript
const [a, setA] = createSignal(1);
const [b, setB] = createSignal(2);

createEffect(() => {
  console.log("a:", a());  // Only tracks `a`
});

setA(10);  // Effect runs
setB(20);  // Effect does NOT run (b is not tracked)
```

## Conditional Dependencies

Dependencies are tracked dynamically based on execution path:

```typescript
const [showDetails, setShowDetails] = createSignal(false);
const [name, setName] = createSignal("Luna");
const [details, setDetails] = createSignal("A UI framework");

createEffect(() => {
  console.log("Name:", name());

  if (showDetails()) {
    console.log("Details:", details());  // Only tracked when showDetails is true
  }
});

setDetails("New details");  // Effect does NOT run (not currently tracked)

setShowDetails(true);       // Effect runs, now tracks `details`

setDetails("Updated");      // Effect runs (now tracked)
```

## Side Effects

Effects are perfect for side effects like:

### DOM Manipulation

```typescript
const [title, setTitle] = createSignal("My App");

createEffect(() => {
  document.title = title();  // Updates document title reactively
});
```

### Logging

```typescript
const [user, setUser] = createSignal(null);

createEffect(() => {
  if (user()) {
    console.log("User logged in:", user().name);
  }
});
```

### API Calls

```typescript
const [searchTerm, setSearchTerm] = createSignal("");

createEffect(() => {
  const term = searchTerm();
  if (term.length > 2) {
    fetch(`/api/search?q=${term}`)
      .then(res => res.json())
      .then(data => setResults(data));
  }
});
```

## Effect Return Value

Effects can return a dispose function:

```typescript
const dispose = createEffect(() => {
  console.log("Running");
});

// Later: stop the effect
dispose();
```

```moonbit
let dispose = @luna.effect(fn() {
  println("Running")
})

// Later: stop the effect
dispose()
```

## Cleanup (onCleanup)

Register cleanup functions inside effects:

```typescript
import { createSignal, createEffect, onCleanup } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  const interval = setInterval(() => {
    console.log("Count:", count());
  }, 1000);

  // Cleanup runs before effect re-runs or when disposed
  onCleanup(() => {
    clearInterval(interval);
  });
});
```

```moonbit
let count = @luna.signal(0)

@luna.effect(fn() {
  // Setup interval...

  @luna.on_cleanup(fn() {
    // Clear interval when effect re-runs or disposes
  })
})
```

## Common Patterns

### Debounced Effect

```typescript
const [search, setSearch] = createSignal("");

createEffect(() => {
  const term = search();

  const timeout = setTimeout(() => {
    fetchResults(term);
  }, 300);

  onCleanup(() => clearTimeout(timeout));
});
```

### Event Listeners

```typescript
const [element, setElement] = createSignal(null);

createEffect(() => {
  const el = element();
  if (!el) return;

  const handler = () => console.log("Clicked!");
  el.addEventListener("click", handler);

  onCleanup(() => {
    el.removeEventListener("click", handler);
  });
});
```

## Try It

Create an effect that:

1. Tracks a `count` signal
2. Logs the count every second while running
3. Cleans up properly when count changes

<details>
<summary>Solution</summary>

```typescript
const [count, setCount] = createSignal(0);

createEffect(() => {
  const currentCount = count();

  const interval = setInterval(() => {
    console.log("Current count:", currentCount);
  }, 1000);

  onCleanup(() => {
    console.log("Cleaning up for count:", currentCount);
    clearInterval(interval);
  });
});
```

</details>

## Next

Learn about [Memos →](./introduction_memos)
