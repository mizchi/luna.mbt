---
title: "Islands: Web Components"
---

# Web Components Islands

Combine Islands with Web Components for style encapsulation and interoperability.

## Why Web Components?

Web Components provide:

| Feature | Benefit |
|---------|---------|
| Shadow DOM | Style encapsulation |
| Custom Elements | Standard API |
| Declarative Shadow DOM | SSR support |
| Interoperability | Works anywhere |

## Creating a Web Component Island

### Server Side (MoonBit)

```moonbit
///|
using @server_dom { wc_island, button, text, type Node }
using @luna { Load }

fn counter_wc(initial : Int) -> Node {
  wc_island(
    name="wc-counter",           // Custom element name
    url="/static/wc-counter.js",
    state=initial.to_string(),
    trigger=Load,
    styles=":host { display: block; padding: 16px; }
            button { background: blue; color: white; }",
    children=[
      button([text("Count: \{initial}")])
    ],
  )
}
```

### HTML Output

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <style>
      :host { display: block; padding: 16px; }
      button { background: blue; color: white; }
    </style>
    <button>Count: 0</button>
  </template>
</wc-counter>
```

### Client Side (TypeScript)

```typescript
// wc-counter.ts
import { createSignal, hydrateWC } from '@mizchi/luna';

interface CounterProps {
  initial: number;
}

function Counter(props: CounterProps) {
  const [count, setCount] = createSignal(props.initial);

  return (
    <>
      <style>
        {`:host { display: block; padding: 16px; }
          button { background: blue; color: white; }`}
      </style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  );
}

// Register as Web Component
hydrateWC("wc-counter", Counter);
```

## Declarative Shadow DOM

Luna uses Declarative Shadow DOM for SSR:

```html
<my-component>
  <template shadowrootmode="open">
    <style>/* Scoped styles */</style>
    <!-- Shadow DOM content -->
  </template>
</my-component>
```

**Benefits:**
- Styles apply immediately (no FOUC)
- No JavaScript needed for initial render
- Content visible before hydration

## Style Encapsulation

Styles inside Shadow DOM are scoped:

```css
/* These only affect the component */
:host {
  display: block;
  border: 1px solid #ccc;
}

button {
  /* Won't affect buttons outside */
  background: blue;
}

/* Style from outside */
::slotted(*) {
  /* Styles for slotted content */
}
```

### Global Styles

To use global styles, adopt stylesheets:

```typescript
// In your component
const globalSheet = new CSSStyleSheet();
globalSheet.replaceSync(document.querySelector('style#global').textContent);

class MyComponent extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this.shadowRoot.adoptedStyleSheets = [globalSheet];
  }
}
```

## Slots

Pass content into Web Components:

### Server

```moonbit
///|
using @server_dom { wc_island, slot_ }

wc_island(
  name="wc-card",
  children=[
    slot_(),              // Default slot
    slot_(name="footer"), // Named slot
  ],
)
```

### Usage

```html
<wc-card>
  <p>Card content goes in default slot</p>
  <footer slot="footer">Footer content</footer>
</wc-card>
```

## WC vs Regular Islands

| Aspect | Regular Island | WC Island |
|--------|---------------|-----------|
| Styles | Global CSS | Scoped (Shadow DOM) |
| Element | `<div>` | Custom element |
| SSR | `innerHTML` | Declarative Shadow DOM |
| Slots | Not supported | Supported |
| Outside styling | Easy | Requires CSS parts |

### When to Use Web Components

**Use WC Islands for:**
- Components needing style isolation
- Reusable across different projects
- Components with slots
- Design system components

**Use Regular Islands for:**
- Simple interactive widgets
- Components that need global styles
- Quick prototyping

## CSS Parts

Expose style hooks for outside customization:

```typescript
// In your component
<button part="button">Click me</button>
```

```css
/* From outside */
wc-counter::part(button) {
  background: red;  /* Override internal style */
}
```

## Events

Dispatch custom events from Web Components:

```typescript
function Counter() {
  const host = useHost();  // Get the custom element

  const handleClick = () => {
    setCount(c => c + 1);

    // Dispatch custom event
    host.dispatchEvent(new CustomEvent('count-changed', {
      detail: { count: count() },
      bubbles: true,
    }));
  };

  return <button onClick={handleClick}>Count: {count()}</button>;
}
```

```html
<wc-counter oncount-changed="handleCountChange(event)"></wc-counter>
```

## Common Patterns

### Card Component

```moonbit
///|
using @server_dom { wc_island, slot_ }

wc_island(
  name="wc-card",
  styles="
    :host {
      display: block;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      padding: 16px;
    }
    ::slotted(h2) {
      margin-top: 0;
    }
  ",
  children=[
    slot_(),
  ],
)
```

### Modal Component

```moonbit
///|
using @server_dom { wc_island, div, slot_ }
using @luna { None }

wc_island(
  name="wc-modal",
  trigger=None,  // Open manually
  styles="
    :host {
      position: fixed;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      background: rgba(0,0,0,0.5);
    }
    .modal {
      background: white;
      padding: 24px;
      border-radius: 8px;
    }
  ",
  children=[
    div(class_="modal", [slot_()])
  ],
)
```

### Tab Component

```moonbit
///|
using @server_dom { wc_island }

wc_island(
  name="wc-tabs",
  styles="
    :host { display: block; }
    .tabs { display: flex; border-bottom: 1px solid #ccc; }
    .tab { padding: 8px 16px; cursor: pointer; }
    .tab.active { border-bottom: 2px solid blue; }
  ",
  children=[...],
)
```

## Try It

Design a Web Component island for a notification toast:

<details>
<summary>Solution</summary>

**Server (MoonBit):**

```moonbit
///|
using @server_dom { wc_island, span, button, text, type Node }
using @luna { Load }

pub struct ToastProps {
  message : String
  type_ : String  // "success" | "error" | "info"
} derive(ToJson, FromJson)

fn toast_wc(props : ToastProps) -> Node {
  wc_island(
    name="wc-toast",
    url="/static/wc-toast.js",
    state=props.to_json().stringify(),
    trigger=Load,
    styles="
      :host {
        position: fixed;
        bottom: 24px;
        right: 24px;
        padding: 16px 24px;
        border-radius: 8px;
        color: white;
        animation: slide-in 0.3s ease;
      }
      :host(.success) { background: #22c55e; }
      :host(.error) { background: #ef4444; }
      :host(.info) { background: #3b82f6; }
      button {
        background: none;
        border: none;
        color: white;
        cursor: pointer;
        margin-left: 16px;
      }
      @keyframes slide-in {
        from { transform: translateX(100%); }
        to { transform: translateX(0); }
      }
    ",
    children=[
      span([text(props.message)]),
      button([text("×")]),
    ],
  )
}
```

**Client (TypeScript):**

```typescript
interface ToastProps {
  message: string;
  type: "success" | "error" | "info";
}

function Toast(props: ToastProps) {
  const [visible, setVisible] = createSignal(true);
  const host = useHost();

  onMount(() => {
    host.classList.add(props.type);

    // Auto-dismiss after 5 seconds
    const timeout = setTimeout(() => setVisible(false), 5000);
    onCleanup(() => clearTimeout(timeout));
  });

  const dismiss = () => {
    setVisible(false);
    host.remove();
  };

  return (
    <Show when={visible()}>
      <span>{props.message}</span>
      <button onClick={dismiss}>×</button>
    </Show>
  );
}

hydrateWC("wc-toast", Toast);
```

</details>

## Summary

You've completed the Luna tutorial! You now know:

- **Signals** for reactive state
- **Effects** for side effects
- **Memos** for computed values
- **Control Flow** for conditional/list rendering
- **Lifecycle** for mount/cleanup
- **Islands** for partial hydration
- **Web Components** for encapsulation

## Next Steps

- Read the [API Reference](/guide/signals)
- Check [Performance Tips](/performance/)
- Explore [Examples](https://github.com/example/luna/examples)
