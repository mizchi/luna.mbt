---
title: Islands & Components API
---

# Islands & Components API

Islands enable partial hydration, and control flow components help build reactive UIs.

## Hydration API

### hydrate

Register a component for hydration.

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

### HTML Attributes

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

### hydrateWC

Register a Web Component for hydration with Shadow DOM.

```typescript
import { createSignal, hydrateWC } from '@mizchi/luna';

function Counter(props: { initial: number }) {
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

## Hydration Triggers

| Trigger | HTML Value | Description |
|---------|------------|-------------|
| Load | `load` | Immediately on page load |
| Idle | `idle` | When browser is idle |
| Visible | `visible` | When element enters viewport |
| Media | `media:(query)` | When media query matches |
| None | `none` | Manual trigger only |

### Manual Hydration

```typescript
// Trigger hydration programmatically
window.__LUNA_HYDRATE__?.("modal");
```

## Control Flow Components

SolidJS-compatible control flow components.

### For

Render a list of items.

```tsx
import { createSignal, For } from '@mizchi/luna';

const [items, setItems] = createSignal(['a', 'b', 'c']);

<For each={items}>
  {(item, index) => (
    <div>
      {index()}: {item}
    </div>
  )}
</For>
```

#### Signature

```typescript
interface ForProps<T, U extends Node> {
  each: Accessor<T[]> | T[];
  fallback?: Node;
  children: (item: T, index: Accessor<number>) => U;
}

function For<T, U extends Node>(props: ForProps<T, U>): Node;
```

### Index

Render a list with item getters (tracks by index, not reference).

```tsx
import { createSignal, Index } from '@mizchi/luna';

const [items, setItems] = createSignal(['a', 'b', 'c']);

<Index each={items}>
  {(itemGetter, index) => (
    <div>
      {index}: {itemGetter()}
    </div>
  )}
</Index>
```

**Difference from For:**
- `For` - item is direct value, index is accessor
- `Index` - item is accessor (getter), index is direct value

### Show

Conditional rendering.

```tsx
import { createSignal, Show } from '@mizchi/luna';

const [isVisible, setIsVisible] = createSignal(false);

<Show when={isVisible} fallback={<div>Hidden</div>}>
  <div>Visible!</div>
</Show>

// With function children (receives truthy value)
const [user, setUser] = createSignal<User | null>(null);

<Show when={user}>
  {(u) => <div>Hello, {u.name}</div>}
</Show>
```

#### Signature

```typescript
interface ShowProps<T> {
  when: T | Accessor<T>;
  fallback?: Node;
  children: Node | ((item: NonNullable<T>) => Node);
}

function Show<T>(props: ShowProps<T>): Node;
```

### Switch / Match

Multi-branch conditional rendering.

```tsx
import { createSignal, Switch, Match } from '@mizchi/luna';

const [status, setStatus] = createSignal<'loading' | 'success' | 'error'>('loading');

<Switch fallback={<div>Unknown</div>}>
  <Match when={() => status() === 'loading'}>
    <div>Loading...</div>
  </Match>
  <Match when={() => status() === 'success'}>
    <div>Success!</div>
  </Match>
  <Match when={() => status() === 'error'}>
    <div>Error!</div>
  </Match>
</Switch>
```

#### Signature

```typescript
interface MatchProps<T> {
  when: T | Accessor<T>;
  children: Node | ((item: NonNullable<T>) => Node);
}

interface SwitchProps {
  fallback?: Node;
  children: MatchResult<Node>[];
}

function Match<T>(props: MatchProps<T>): MatchResult<Node>;
function Switch(props: SwitchProps): Node;
```

### Portal

Render children to a different DOM location.

```tsx
import { Portal } from '@mizchi/luna';

// Render to document.body (default)
<Portal>
  <div class="modal">Modal content</div>
</Portal>

// Render to specific selector
<Portal mount="#modal-root">
  <div class="modal">Modal content</div>
</Portal>

// Render with Shadow DOM encapsulation
<Portal useShadow>
  <div>Encapsulated content</div>
</Portal>
```

#### Signature

```typescript
interface PortalProps {
  mount?: Element | string;  // Target element or CSS selector
  useShadow?: boolean;       // Use Shadow DOM
  children: Node | Node[] | (() => Node);
}

function Portal(props: PortalProps): Node;
```

#### Low-level APIs

```typescript
import { portalToBody, portalToSelector, portalWithShadow } from '@mizchi/luna';

// Portal to body
portalToBody([modalContent]);

// Portal to CSS selector
portalToSelector("#modal-root", [modalContent]);

// Portal with Shadow DOM
portalWithShadow([content]);
```

### Provider

Provide context values to descendants.

```tsx
import { createContext, useContext, Provider } from '@mizchi/luna';

const ThemeContext = createContext('light');

<Provider context={ThemeContext} value="dark">
  <App />
</Provider>

// Inside App or descendants:
const theme = useContext(ThemeContext);  // 'dark'
```

## DOM Utilities

### mount / render

Mount a component to a DOM element.

```typescript
import { mount, render, createElement, text } from '@mizchi/luna';

// Using mount
mount(document.getElementById('app'), <App />);

// Using render (same as mount)
render(document.getElementById('app'), myComponent);
```

### text / textDyn

Create text nodes.

```typescript
import { text, textDyn, createSignal } from '@mizchi/luna';

// Static text
const staticText = text("Hello");

// Dynamic text (reactive)
const [name, setName] = createSignal("Luna");
const dynamicText = textDyn(() => `Hello, ${name()}`);
```

### show

Conditional rendering helper.

```typescript
import { show, text, createSignal } from '@mizchi/luna';

const [visible, setVisible] = createSignal(true);

const node = show(
  visible,
  () => text("Visible!")
);
```

### forEach

Low-level list rendering.

```typescript
import { forEach, text, createSignal } from '@mizchi/luna';

const [items, setItems] = createSignal(['a', 'b', 'c']);

const list = forEach(
  items,
  (item, index) => text(`${index}: ${item}`)
);
```

### events

Create event handler maps with method chaining.

```typescript
import { events } from '@mizchi/luna';

const handlers = events()
  .click((e) => console.log('clicked'))
  .input((e) => console.log('input'))
  .keydown((e) => console.log('keydown'));
```

### useHost

Get the host element in a Web Component.

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

## API Summary

### Hydration

| Function | Description |
|----------|-------------|
| `hydrate(id, component)` | Register component for hydration |
| `hydrateWC(tagName, component)` | Register Web Component |
| `useHost()` | Get host element in WC |

### Control Flow

| Component | Description |
|-----------|-------------|
| `For` | List rendering by reference |
| `Index` | List rendering by index |
| `Show` | Conditional rendering |
| `Switch` / `Match` | Multi-branch conditional |
| `Portal` | Render to different location |
| `Provider` | Provide context values |

### DOM

| Function | Description |
|----------|-------------|
| `mount(el, node)` | Mount to element |
| `render(el, node)` | Render to element |
| `text(content)` | Static text node |
| `textDyn(getter)` | Dynamic text node |
| `show(cond, render)` | Conditional node |
| `forEach(items, render)` | List of nodes |
| `events()` | Event handler builder |
