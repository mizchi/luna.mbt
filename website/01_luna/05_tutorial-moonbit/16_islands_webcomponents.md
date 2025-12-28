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

### MoonBit (Server)

```moonbit
using @server_dom { wc_island, button, text }
using @luna { Load }

fn counter_wc(initial : Int) -> @luna.Node {
  wc_island(
    name="wc-counter",
    url="/static/wc-counter.js",
    state=initial.to_string(),
    trigger=Load,
    styles=":host { display: block; padding: 16px; }
            button { background: blue; color: white; }",
    children=[
      button([text("Count: " + initial.to_string())])
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

### TypeScript (Client)

```typescript
import { createSignal, hydrateWC } from '@luna_ui/luna';

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

hydrateWC("wc-counter", Counter);
```

## wc_island Function

```moonbit
fn wc_island(
  name : String,              // Custom element tag name
  url : String,               // JavaScript module URL
  state~ : String = "",       // Serialized props
  trigger~ : Trigger = Load,  // Hydration trigger
  styles~ : String = "",      // Scoped CSS
  children~ : Array[@luna.Node] = [],
) -> @luna.Node
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

```moonbit
wc_island(
  name="wc-card",
  styles="
    :host {
      display: block;
      border: 1px solid #ccc;
    }
    button {
      /* Won't affect buttons outside */
      background: blue;
    }
    ::slotted(*) {
      /* Styles for slotted content */
    }
  ",
  children=[...],
)
```

## Slots

Pass content into Web Components:

```moonbit
using @server_dom { wc_island, slot_ }

wc_island(
  name="wc-card",
  children=[
    slot_(),              // Default slot
    slot_(name="footer"), // Named slot
  ],
)
```

Usage:

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

## Common Patterns

### Card Component

```moonbit
wc_island(
  name="wc-card",
  styles="
    :host {
      display: block;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      padding: 16px;
    }
  ",
  children=[slot_()],
)
```

### Modal Component

```moonbit
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

## CSS Parts

Expose style hooks for outside customization:

```typescript
// In your component
<button part="button">Click me</button>
```

```css
/* From outside */
wc-counter::part(button) {
  background: red;
}
```

## Summary

You've completed the Luna MoonBit tutorial! You now know:

- **Signals** for reactive state
- **Effects** for side effects
- **Memos** for computed values
- **Control Flow** for conditional/list rendering
- **Lifecycle** for setup/cleanup
- **Islands** for server-side rendering
- **Web Components** for encapsulation

## Next Steps

- Read the [MoonBit API Reference](/luna/api-moonbit/)
- Read the [JavaScript Tutorial](/luna/tutorial-js/) for client-side hydration
- Explore [Sol](/sol/) for full SSR framework
