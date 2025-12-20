---
title: Islands API
---

# Islands API

Islands enable partial hydration - only interactive components load JavaScript.

## hydrate

Register a component for hydration. When Luna's loader finds an element with matching `luna:id`, it will hydrate it with your component.

```typescript
import { createSignal, hydrate } from '@mizchi/luna';

interface CounterProps {
  initial: number;
}

function Counter(props: CounterProps) {
  const [count, setCount] = createSignal(props.initial);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  );
}

hydrate("counter", Counter);
```

### Signature

```typescript
function hydrate<P>(id: string, component: (props: P) => JSX.Element): void;
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | `string` | Island ID matching `luna:id` attribute |
| `component` | `(props: P) => JSX.Element` | Component function |

### HTML Attributes

The server renders HTML with these attributes:

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state='{"initial":5}'
  luna:client-trigger="load"
>
  <button>Count: 5</button>
</div>
```

| Attribute | Description |
|-----------|-------------|
| `luna:id` | Component identifier |
| `luna:url` | JavaScript module URL |
| `luna:state` | Serialized props (JSON) |
| `luna:client-trigger` | When to hydrate |

## hydrateWC

Register a Web Component for hydration. Use this for components that need Shadow DOM encapsulation.

```typescript
import { createSignal, hydrateWC } from '@mizchi/luna';

interface CounterProps {
  initial: number;
}

function Counter(props: CounterProps) {
  const [count, setCount] = createSignal(props.initial);

  return (
    <>
      <style>{`:host { display: block; }`}</style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  );
}

hydrateWC("wc-counter", Counter);
```

### Signature

```typescript
function hydrateWC<P>(tagName: string, component: (props: P) => JSX.Element): void;
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `tagName` | `string` | Custom element tag name |
| `component` | `(props: P) => JSX.Element` | Component function |

### HTML Attributes

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state='{"initial":5}'
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <button>Count: 5</button>
  </template>
</wc-counter>
```

| Attribute | Description |
|-----------|-------------|
| `luna:wc-url` | JavaScript module URL |
| `luna:wc-state` | Serialized props (JSON) |
| `luna:wc-trigger` | When to hydrate |

## Hydration Triggers

Control when islands become interactive:

| Trigger | HTML Value | Description |
|---------|------------|-------------|
| Load | `load` | Immediately on page load |
| Idle | `idle` | When browser is idle (`requestIdleCallback`) |
| Visible | `visible` | When element enters viewport (`IntersectionObserver`) |
| Media | `media:(query)` | When media query matches |
| None | `none` | Manual trigger only |

### Examples

```html
<!-- Immediate -->
<div luna:id="search" luna:client-trigger="load">...</div>

<!-- When idle -->
<div luna:id="analytics" luna:client-trigger="idle">...</div>

<!-- When visible -->
<div luna:id="comments" luna:client-trigger="visible">...</div>

<!-- Desktop only -->
<div luna:id="sidebar" luna:client-trigger="media:(min-width: 768px)">...</div>

<!-- Manual -->
<div luna:id="modal" luna:client-trigger="none">...</div>
```

### Manual Hydration

For `none` trigger, hydrate programmatically:

```typescript
// Trigger hydration manually
window.__LUNA_HYDRATE__?.("modal");
```

## useHost

Get the host element in a Web Component. Useful for dispatching custom events.

```typescript
import { useHost, hydrateWC } from '@mizchi/luna';

function Counter() {
  const host = useHost();

  const handleClick = () => {
    host.dispatchEvent(new CustomEvent('count-changed', {
      detail: { count: count() },
      bubbles: true,
    }));
  };

  return <button onClick={handleClick}>Click</button>;
}

hydrateWC("wc-counter", Counter);
```

### Signature

```typescript
function useHost(): HTMLElement;
```

## Best Practices

### Choose Appropriate Triggers

| Content | Recommended Trigger |
|---------|---------------------|
| Above the fold, critical | `load` |
| Below the fold | `visible` |
| Analytics, non-critical | `idle` |
| Desktop-only features | `media` |
| User-triggered (modals) | `none` |

### Minimize Island Count

Fewer, larger islands are better than many small ones:

```
10 small islands = 10 script loads
2 larger islands = 2 script loads
```

### Keep State Minimal

Only serialize what's needed:

```typescript
// Good - minimal state
interface Props {
  userId: number;
  displayName: string;
}

// Bad - too much data
interface Props {
  user: FullUserObject;
  allSettings: CompleteSettings;
}
```
