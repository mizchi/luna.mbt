---
title: "Lifecycle: onMount"
---

# onMount

Run code once when a component is mounted to the DOM.

## Basic Usage

### TypeScript

```typescript
import { onMount } from '@mizchi/luna';

function MyComponent() {
  onMount(() => {
    console.log("Component mounted!");
  });

  return <div>Hello</div>;
}
```

### MoonBit

```moonbit
///|
using @element { div, text, type DomNode }
using @luna { on_mount }

fn my_component() -> DomNode {
  on_mount(() => println("Component mounted!"))

  div([text("Hello")])
}
```

## When onMount Runs

- After the component's DOM is created
- After initial render is complete
- Only once per component instance
- Before any effects run

```typescript
function Component() {
  console.log("1. Component function runs");

  onMount(() => {
    console.log("3. onMount runs");
  });

  createEffect(() => {
    console.log("4. Effect runs");
  });

  console.log("2. Before return");

  return <div>Content</div>;
}

// Output order:
// 1. Component function runs
// 2. Before return
// 3. onMount runs
// 4. Effect runs
```

## Common Use Cases

### DOM Access

Access DOM elements after they're created:

```typescript
function AutoFocus() {
  let inputRef;

  onMount(() => {
    inputRef.focus();
  });

  return <input ref={inputRef} />;
}
```

### Fetching Data

Load initial data when component mounts:

```typescript
function UserProfile(props) {
  const [user, setUser] = createSignal(null);
  const [loading, setLoading] = createSignal(true);

  onMount(async () => {
    const data = await fetch(`/api/users/${props.id}`);
    setUser(await data.json());
    setLoading(false);
  });

  return (
    <Show when={!loading()} fallback={<Spinner />}>
      <div>{user()?.name}</div>
    </Show>
  );
}
```

### Third-Party Libraries

Initialize libraries that need DOM elements:

```typescript
function Chart(props) {
  let containerRef;

  onMount(() => {
    // Initialize chart library after DOM is ready
    const chart = new ChartLibrary(containerRef, {
      data: props.data,
      type: props.type,
    });

    onCleanup(() => {
      chart.destroy();
    });
  });

  return <div ref={containerRef} class="chart-container" />;
}
```

### Event Listeners

Add global event listeners:

```typescript
function KeyboardHandler() {
  onMount(() => {
    const handler = (e) => {
      if (e.key === "Escape") {
        closeModal();
      }
    };

    document.addEventListener("keydown", handler);

    onCleanup(() => {
      document.removeEventListener("keydown", handler);
    });
  });

  return <div>Press Escape to close</div>;
}
```

### Measuring DOM

Get element dimensions:

```typescript
function ResponsiveBox() {
  let boxRef;
  const [size, setSize] = createSignal({ width: 0, height: 0 });

  onMount(() => {
    const rect = boxRef.getBoundingClientRect();
    setSize({ width: rect.width, height: rect.height });

    const observer = new ResizeObserver(entries => {
      const { width, height } = entries[0].contentRect;
      setSize({ width, height });
    });

    observer.observe(boxRef);

    onCleanup(() => observer.disconnect());
  });

  return (
    <div ref={boxRef}>
      Size: {size().width}x{size().height}
    </div>
  );
}
```

## onMount vs createEffect

| Aspect | onMount | createEffect |
|--------|---------|--------------|
| Runs | Once | On every dependency change |
| Tracks dependencies | No | Yes |
| Use for | Setup, initialization | Reactive side effects |

```typescript
// onMount: run once
onMount(() => {
  initializeLibrary();
});

// createEffect: run on changes
createEffect(() => {
  updateLibrary(data());  // Re-runs when data changes
});
```

## Async onMount

onMount can be async:

```typescript
onMount(async () => {
  const response = await fetch("/api/data");
  const data = await response.json();
  setData(data);
});
```

Note: The component won't wait for the async function to complete before rendering.

## Multiple onMount

You can have multiple onMount calls:

```typescript
function Component() {
  onMount(() => console.log("First mount handler"));
  onMount(() => console.log("Second mount handler"));

  // Both run in order
  return <div>Content</div>;
}
```

## Try It

Create a component that:

1. Fetches user data on mount
2. Auto-focuses an input field
3. Logs when mounted

<details>
<summary>Solution</summary>

```typescript
function UserForm(props) {
  let nameInput;
  const [user, setUser] = createSignal(null);
  const [loading, setLoading] = createSignal(true);

  onMount(() => {
    console.log("UserForm mounted");
  });

  onMount(async () => {
    const response = await fetch(`/api/users/${props.userId}`);
    setUser(await response.json());
    setLoading(false);
  });

  onMount(() => {
    // Focus after a brief delay to ensure DOM is ready
    setTimeout(() => nameInput?.focus(), 0);
  });

  return (
    <Show when={!loading()} fallback={<p>Loading...</p>}>
      <form>
        <input
          ref={nameInput}
          value={user()?.name || ""}
          placeholder="Name"
        />
      </form>
    </Show>
  );
}
```

</details>

## Next

Learn about [onCleanup →](./lifecycle_oncleanup)
