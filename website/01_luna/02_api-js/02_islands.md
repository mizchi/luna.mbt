---
title: Islands & Components API
---

# Islands & Components API

Islands enable partial hydration via Web Components, and control flow components help build reactive UIs.

## Hydration API

Luna hydrates a custom element that the server emits with `luna:wc-url` / `luna:wc-state` / `luna:wc-trigger` attributes. Declarative Shadow DOM is opt-in. The same triggers (`load` / `idle` / `visible` / `media` / `none`) apply.

### Island Module Contract

The module pointed to by `luna:wc-url` must export a `hydrate` function (named export or default). The wc-loader dynamically imports the module and calls:

```typescript
hydrate(element: Element, state: unknown, name: string): void | (() => void)
```

- `element` — the custom element instance (e.g. the `<wc-counter>` DOM node)
- `state` — the value parsed from `luna:wc-state` (JSON), or `{}` if absent
- `name` — the element's tag name (e.g. `"wc-counter"`)
- An optional cleanup function can be returned for HMR / teardown.

```typescript
import { createSignal, render } from '@luna_ui/luna';

interface CounterProps {
  initial: number;
}

export default function hydrate(element: Element, state: CounterProps) {
  const [count, setCount] = createSignal(state.initial);

  render(element, () => (
    <>
      <style>{`:host { display: block; }`}</style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  ));
}
```

### HTML Attributes

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state='{"initial":5}'
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <button>Count: 5</button>
  </template>
</wc-counter>
```

| Attribute | Description |
|-----------|-------------|
| `luna:wc-url` | JavaScript module URL |
| `luna:wc-state` | Serialized props (JSON) |
| `luna:wc-trigger` | When to hydrate |

Custom-element registration via `customElements.define()` is **not** required — the loader scans `[luna:wc-url]` regardless of whether the tag is a registered Custom Element. Declarative Shadow DOM (`<template shadowrootmode="open">`) is optional.

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
// Trigger hydration programmatically for a specific custom element name
window.__LUNA_WC_HYDRATE__?.(document.querySelector("my-modal"));
```

## Control Flow Components

SolidJS-compatible control flow components.

### For

Render a list of items.

```tsx
import { createSignal, For } from '@luna_ui/luna';

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
import { createSignal, Index } from '@luna_ui/luna';

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
import { createSignal, Show } from '@luna_ui/luna';

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
import { createSignal, Switch, Match } from '@luna_ui/luna';

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
import { Portal } from '@luna_ui/luna';

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
import { portalToBody, portalToSelector, portalWithShadow } from '@luna_ui/luna';

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
import { createContext, useContext, Provider } from '@luna_ui/luna';

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
import { mount, render, createElement, text } from '@luna_ui/luna';

// Using mount
mount(document.getElementById('app'), <App />);

// Using render (same as mount)
render(document.getElementById('app'), myComponent);
```

### text / textDyn

Create text nodes.

```typescript
import { text, textDyn, createSignal } from '@luna_ui/luna';

// Static text
const staticText = text("Hello");

// Dynamic text (reactive)
const [name, setName] = createSignal("Luna");
const dynamicText = textDyn(() => `Hello, ${name()}`);
```

### show

Conditional rendering helper.

```typescript
import { show, text, createSignal } from '@luna_ui/luna';

const [visible, setVisible] = createSignal(true);

const node = show(
  visible,
  () => text("Visible!")
);
```

### forEach

Low-level list rendering.

```typescript
import { forEach, text, createSignal } from '@luna_ui/luna';

const [items, setItems] = createSignal(['a', 'b', 'c']);

const list = forEach(
  items,
  (item, index) => text(`${index}: ${item}`)
);
```

### events

Create event handler maps with method chaining.

```typescript
import { events } from '@luna_ui/luna';

const handlers = events()
  .click((e) => console.log('clicked'))
  .input((e) => console.log('input'))
  .keydown((e) => console.log('keydown'));
```

### Host Element

Inside `hydrate`, the host element is the first argument (`element`). There is no separate `useHost` helper — operate on `element` directly.

```typescript
import { createSignal, render } from '@luna_ui/luna';

export default function hydrate(element: Element) {
  const [count, setCount] = createSignal(0);

  const handleClick = () => {
    setCount(c => c + 1);
    element.dispatchEvent(new CustomEvent('count-changed', {
      detail: { count: count() },
      bubbles: true,
    }));
  };

  render(element, () => <button onClick={handleClick}>Click ({count()})</button>);
}
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

| Export | Description |
|--------|-------------|
| `export default function hydrate(el, state, name)` | Island module entry point — loader calls this with the custom element, parsed JSON state, and tag name |
| `render(el, () => jsx)` | Render JSX into the element |

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
