---
title: "Islands: Basics"
---

# Islands Basics

Islands Architecture enables partial hydration — only interactive parts of your page load JavaScript.

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

### 1. Server-Rendered HTML

The server renders an island as a custom element with `luna:wc-*` attributes:

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <button>Count: 0</button>
  </template>
</wc-counter>
```

> For server-side rendering with MoonBit, see the [MoonBit Tutorial](/luna/tutorial-moonbit/).

### 2. Client Side (TypeScript)

Create the interactive component:

```typescript
// wc-counter.ts
import { createSignal, hydrateWC } from '@luna_ui/luna';

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

// Register for hydration
hydrateWC("wc-counter", Counter);
```

### 3. Hydration

1. Page loads with server-rendered HTML (instant display)
2. Luna loader scans for `[luna:wc-url]` elements
3. Based on trigger, loads `/static/wc-counter.js`
4. JavaScript takes over, element becomes interactive

## Island Attributes

| Attribute | Purpose |
|-----------|---------|
| `luna:wc-url` | URL to load component JavaScript |
| `luna:wc-state` | Serialized props (JSON) |
| `luna:wc-trigger` | When to hydrate |

`customElements.define()` is **not** required — the loader picks up any element with `luna:wc-url`, regardless of whether the tag is a registered Custom Element.

## How Hydration Works

```
Server HTML          Luna Loader           Island Component
     │                    │                       │
     │  luna:wc-url found │                       │
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

Each island is independent. A typical page structure:

```html
<div>
  <h1>My Page</h1>

  <!-- Search island - hydrates immediately -->
  <wc-search luna:wc-url="/wc-search.js" luna:wc-trigger="load">...</wc-search>

  <!-- Article - pure HTML, no JS -->
  <article>
    <p>Static content...</p>
  </article>

  <!-- Comments island - hydrates when visible -->
  <wc-comments luna:wc-url="/wc-comments.js" luna:wc-trigger="visible">...</wc-comments>

  <!-- Footer - pure HTML -->
  <footer>...</footer>
</div>
```

## Benefits

| Metric | Traditional SPA | Islands |
|--------|----------------|---------|
| Initial JS | 100KB+ | ~2KB loader |
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
