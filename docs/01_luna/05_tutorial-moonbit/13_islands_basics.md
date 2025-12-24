---
title: "Islands: Basics"
---

# Islands Basics

Server-side rendering of islands for partial hydration.

## What is an Island?

An island is a component that:
- Renders HTML on the server (MoonBit)
- Becomes interactive on the client (TypeScript)
- Only loads JavaScript for that specific component

```
┌─────────────────────────────────────┐
│  Header (static)       ← No JS      │
├─────────────────────────────────────┤
│  Article (static)      ← No JS      │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Comments Island    ← JS     │    │
│  └─────────────────────────────┘    │
│                                     │
│  Footer (static)       ← No JS      │
└─────────────────────────────────────┘
```

## Creating an Island

### Server Side (MoonBit)

```moonbit
using @server_dom { island, div, button, text }
using @luna { Load }

fn counter_island(initial : Int) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=initial.to_string(),
    trigger=Load,
    children=[
      div([
        button([text("Count: " + initial.to_string())])
      ])
    ],
  )
}
```

### HTML Output

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state="0"
  luna:client-trigger="load"
>
  <div>
    <button>Count: 0</button>
  </div>
</div>
```

### Client Side (TypeScript)

The client-side code hydrates the island:

```typescript
// counter.ts
import { createSignal, hydrate } from '@luna_ui/luna';

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

## Island Attributes

| Attribute | MoonBit Parameter | Description |
|-----------|-------------------|-------------|
| `luna:id` | `id` | Component identifier |
| `luna:url` | `url` | JavaScript module URL |
| `luna:state` | `state` | Serialized props (JSON) |
| `luna:client-trigger` | `trigger` | When to hydrate |

## Island Function Signature

```moonbit
fn island(
  id : String,
  url : String,
  state~ : String = "",
  trigger~ : Trigger = Load,
  children~ : Array[@luna.Node] = [],
) -> @luna.Node
```

## Multiple Islands

Each island is independent:

```moonbit
fn page() -> @luna.Node {
  div([
    header([text("My Page")]),

    // Search island - hydrates immediately
    search_island(),

    // Article - pure HTML, no JS
    article([text("Static content...")]),

    // Comments island - hydrates when visible
    comments_island(post_id=123),

    footer([text("Footer")]),
  ])
}
```

## Hydration Flow

```
Server (MoonBit)         Luna Loader          Island Component
     │                       │                       │
     │  Render HTML          │                       │
     │ ─────────────────>    │                       │
     │                       │                       │
     │  luna:id found        │                       │
     │                       │ Check trigger         │
     │                       │                       │
     │                       │ Load JS module        │
     │                       │─────────────────────> │
     │                       │                       │
     │                       │ Call hydrate()        │
     │                       │<───────────────────── │
     │                       │                       │
     │<──────────────────────│ Interactive!          │
```

## Benefits

| Metric | Traditional SPA | Islands |
|--------|----------------|---------|
| Initial JS | 100KB+ | ~3KB loader |
| TTI | Slow | Fast |
| LCP | Blocked by JS | Immediate |
| Interactivity | All or nothing | Progressive |

## When to Use Islands

**Use Islands for:**
- Interactive widgets (forms, search, comments)
- Components needing client state
- Dynamic content after load

**Don't use Islands for:**
- Static content (articles, headers)
- Content that doesn't need interactivity
- Server-only rendered pages

## Try It

Create an island for a "Like" button:
1. Server renders button with initial like count
2. Client hydrates to make it clickable
3. Clicking increments the count

## Next

Learn about [Islands State →](./islands_state)
