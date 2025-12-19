---
title: "Islands: Basics"
---

# Islands Basics

Islands Architecture enables partial hydration - only interactive parts of your page load JavaScript.

## The Problem

Traditional SPAs send JavaScript for the entire page:

```
┌─────────────────────────────────────┐
│  Header (static)       ← JS loaded  │
├─────────────────────────────────────┤
│  Article (static)      ← JS loaded  │
│                                     │
│  Comments (interactive)← JS needed  │
│                                     │
│  Footer (static)       ← JS loaded  │
└─────────────────────────────────────┘
```

Result: Large bundle, slow load, wasted resources.

## The Solution

Islands hydrate only interactive components:

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

Result: Minimal JavaScript, fast load, great Core Web Vitals.

## Creating an Island

### 1. Server Side (MoonBit)

Create an island that renders on the server:

```moonbit
///|
using @server_dom { island, button, text, type Node }
using @luna { Load }

fn counter_island(initial : Int) -> Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=initial.to_string(),
    trigger=Load,
    children=[
      // SSR content shown before hydration
      button([text("Count: \{initial}")])
    ],
  )
}
```

### 2. Client Side (TypeScript)

Create the interactive component:

```typescript
// counter.ts
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

// Register for hydration
hydrate("counter", Counter);
```

### 3. HTML Output

The server renders:

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state="0"
  luna:client-trigger="load"
>
  <button>Count: 0</button>
</div>
```

### 4. Hydration

1. Page loads with server-rendered HTML (instant display)
2. Luna loader detects `luna:id` elements
3. Based on trigger, loads `/static/counter.js`
4. JavaScript takes over, element becomes interactive

## Island Attributes

| Attribute | Purpose |
|-----------|---------|
| `luna:id` | Component identifier for hydration |
| `luna:url` | URL to load component JavaScript |
| `luna:state` | Serialized props (JSON) |
| `luna:client-trigger` | When to hydrate |

## How Hydration Works

```
Server HTML          Luna Loader           Island Component
     │                    │                       │
     │  luna:id found     │                       │
     │ ──────────────────>│                       │
     │                    │                       │
     │                    │ Check trigger         │
     │                    │ (load/idle/visible)   │
     │                    │                       │
     │                    │ Load JS module        │
     │                    │─────────────────────> │
     │                    │                       │
     │                    │ Call hydrate()        │
     │                    │<───────────────────── │
     │                    │                       │
     │<───────────────────│ Take over DOM         │
     │   Interactive!     │                       │
```

## Multiple Islands

Each island is independent:

```moonbit
///|
using @server_dom { div, h1, article, p, footer, text, type Node }

fn page() -> Node {
  div([
    h1([text("My Page")]),

    // Search island - hydrates immediately
    search_island(),

    // Article - pure HTML, no JS
    article([
      p([text("Static content...")])
    ]),

    // Comments island - hydrates when visible
    comments_island(post_id),

    // Footer - pure HTML
    footer([...]),
  ])
}
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

Think about a typical blog page. Which parts would you make into islands?

<details>
<summary>Answer</summary>

```
Blog Page Structure:
├── Header           → Static (no island)
├── Navigation       → Static (no island)
├── Article          → Static (no island)
├── Share Buttons    → Island (click tracking)
├── Comments Form    → Island (form submission)
├── Comments List    → Island (live updates)
├── Related Posts    → Static (no island)
└── Footer           → Static (no island)

Only 3 islands needed for full interactivity!
```

</details>

## Next

Learn about [Hydration Triggers →](./islands_triggers)
