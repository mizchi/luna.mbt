---
title: "Lifecycle: onCleanup"
---

# onCleanup

Register cleanup functions to run when a component unmounts or an effect re-runs.

## Basic Usage

### TypeScript

```typescript
import { onCleanup } from '@mizchi/luna';

function Timer() {
  const [count, setCount] = createSignal(0);

  const interval = setInterval(() => {
    setCount(c => c + 1);
  }, 1000);

  // Cleanup when component unmounts
  onCleanup(() => {
    clearInterval(interval);
  });

  return <p>Count: {count()}</p>;
}
```

### MoonBit

```moonbit
///|
using @element { p, text_dyn, type DomNode }
using @luna { signal, on_cleanup }

fn timer() -> DomNode {
  let count = signal(0)

  // Start interval...

  on_cleanup(() => {
    // Clear interval when component unmounts
  })

  p([text_dyn(() => "Count: \{count.get()}")])
}
```

## When onCleanup Runs

### In Components

Runs when the component is removed from the DOM:

```typescript
function Parent() {
  const [show, setShow] = createSignal(true);

  return (
    <>
      <button onClick={() => setShow(s => !s)}>Toggle</button>
      <Show when={show()}>
        <Child />  {/* onCleanup runs when hidden */}
      </Show>
    </>
  );
}

function Child() {
  onCleanup(() => {
    console.log("Child unmounted!");
  });

  return <p>I'm here</p>;
}
```

### In Effects

Runs before the effect re-runs or when disposed:

```typescript
const [url, setUrl] = createSignal("/api/data");

createEffect(() => {
  const currentUrl = url();
  const controller = new AbortController();

  fetch(currentUrl, { signal: controller.signal })
    .then(res => res.json())
    .then(setData);

  // Cleanup runs when url changes (before next fetch)
  onCleanup(() => {
    controller.abort();
  });
});
```

## Common Use Cases

### Timers

```typescript
function Countdown(props) {
  const [remaining, setRemaining] = createSignal(props.seconds);

  const interval = setInterval(() => {
    setRemaining(r => {
      if (r <= 0) {
        clearInterval(interval);
        return 0;
      }
      return r - 1;
    });
  }, 1000);

  onCleanup(() => clearInterval(interval));

  return <p>{remaining()} seconds</p>;
}
```

### Event Listeners

```typescript
function WindowResize() {
  const [size, setSize] = createSignal({
    width: window.innerWidth,
    height: window.innerHeight,
  });

  const handler = () => {
    setSize({
      width: window.innerWidth,
      height: window.innerHeight,
    });
  };

  window.addEventListener("resize", handler);

  onCleanup(() => {
    window.removeEventListener("resize", handler);
  });

  return <p>Window: {size().width}x{size().height}</p>;
}
```

### Subscriptions

```typescript
function LiveData(props) {
  const [data, setData] = createSignal(null);

  const subscription = props.dataSource.subscribe(newData => {
    setData(newData);
  });

  onCleanup(() => {
    subscription.unsubscribe();
  });

  return <DataView data={data()} />;
}
```

### WebSocket Connections

```typescript
function Chat(props) {
  const [messages, setMessages] = createSignal([]);

  const ws = new WebSocket(`wss://chat.example.com/${props.room}`);

  ws.onmessage = (event) => {
    setMessages(prev => [...prev, JSON.parse(event.data)]);
  };

  onCleanup(() => {
    ws.close();
  });

  return (
    <For each={messages()}>
      {(msg) => <p>{msg.text}</p>}
    </For>
  );
}
```

### Animation Frames

```typescript
function Animation() {
  const [position, setPosition] = createSignal(0);
  let frameId;

  const animate = () => {
    setPosition(p => (p + 1) % 360);
    frameId = requestAnimationFrame(animate);
  };

  frameId = requestAnimationFrame(animate);

  onCleanup(() => {
    cancelAnimationFrame(frameId);
  });

  return (
    <div style={{ transform: `rotate(${position()}deg)` }}>
      Spinning
    </div>
  );
}
```

### Third-Party Libraries

```typescript
function Map(props) {
  let containerRef;
  let mapInstance;

  onMount(() => {
    mapInstance = new MapLibrary(containerRef, {
      center: props.center,
      zoom: props.zoom,
    });
  });

  onCleanup(() => {
    mapInstance?.destroy();
  });

  return <div ref={containerRef} class="map" />;
}
```

## Multiple Cleanups

You can register multiple cleanup functions:

```typescript
function Component() {
  const interval = setInterval(...);
  onCleanup(() => clearInterval(interval));

  const handler = () => {...};
  window.addEventListener("scroll", handler);
  onCleanup(() => window.removeEventListener("scroll", handler));

  const ws = new WebSocket(...);
  onCleanup(() => ws.close());

  return <div>...</div>;
}
```

They run in reverse order (LIFO):

```typescript
onCleanup(() => console.log("First registered, last to run"));
onCleanup(() => console.log("Second registered, second to run"));
onCleanup(() => console.log("Third registered, first to run"));
```

## Cleanup in Effects

Each effect run gets its own cleanup:

```typescript
const [id, setId] = createSignal(1);

createEffect(() => {
  const currentId = id();
  console.log(`Subscribing to ${currentId}`);

  onCleanup(() => {
    console.log(`Unsubscribing from ${currentId}`);
  });
});

// Initial: "Subscribing to 1"
setId(2);
// Output: "Unsubscribing from 1", "Subscribing to 2"
setId(3);
// Output: "Unsubscribing from 2", "Subscribing to 3"
```

## Common Mistakes

### Forgetting to Clean Up

```typescript
// Bad: memory leak!
function BadComponent() {
  setInterval(() => {
    console.log("Still running even after unmount!");
  }, 1000);

  return <div>...</div>;
}

// Good: proper cleanup
function GoodComponent() {
  const interval = setInterval(() => {
    console.log("Cleaned up on unmount");
  }, 1000);

  onCleanup(() => clearInterval(interval));

  return <div>...</div>;
}
```

## Try It

Create a component that:

1. Opens a WebSocket connection on mount
2. Displays received messages
3. Properly closes the connection on unmount

<details>
<summary>Solution</summary>

```typescript
function WebSocketDemo() {
  const [messages, setMessages] = createSignal([]);
  const [status, setStatus] = createSignal("connecting");

  let ws;

  onMount(() => {
    ws = new WebSocket("wss://echo.websocket.org");

    ws.onopen = () => {
      setStatus("connected");
    };

    ws.onmessage = (event) => {
      setMessages(prev => [...prev, event.data]);
    };

    ws.onerror = () => {
      setStatus("error");
    };

    ws.onclose = () => {
      setStatus("disconnected");
    };
  });

  onCleanup(() => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.close();
    }
  });

  const sendMessage = () => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send("Hello!");
    }
  };

  return (
    <div>
      <p>Status: {status()}</p>
      <button onClick={sendMessage} disabled={status() !== "connected"}>
        Send Hello
      </button>
      <ul>
        <For each={messages()}>
          {(msg) => <li>{msg}</li>}
        </For>
      </ul>
    </div>
  );
}
```

</details>

## Next

Learn about [Islands Architecture →](./islands_basics)
