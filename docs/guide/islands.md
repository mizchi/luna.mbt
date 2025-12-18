---
title: Island Architecture
---

# Island Architecture

Islands enable partial hydration - only interactive components load JavaScript.

## The Problem

Traditional SPAs ship JavaScript for the entire page:

```
┌─────────────────────────────────────┐
│  Header (static)      ← JS loaded   │
├─────────────────────────────────────┤
│  Article (static)     ← JS loaded   │
│                                     │
│  Comments (interactive) ← JS needed │
│                                     │
│  Footer (static)      ← JS loaded   │
└─────────────────────────────────────┘
```

## The Solution

Islands only hydrate interactive components:

```
┌─────────────────────────────────────┐
│  Header (static)      ← No JS       │
├─────────────────────────────────────┤
│  Article (static)     ← No JS       │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Comments Island   ← JS      │    │
│  └─────────────────────────────┘    │
│                                     │
│  Footer (static)      ← No JS       │
└─────────────────────────────────────┘
```

## Hydration Triggers

Control when islands hydrate:

### `load` - Immediate

```html
<div luna:id="critical" luna:client-trigger="load">
  <!-- Hydrates immediately on page load -->
</div>
```

### `idle` - When Browser is Idle

```html
<div luna:id="analytics" luna:client-trigger="idle">
  <!-- Hydrates during requestIdleCallback -->
</div>
```

### `visible` - When Scrolled Into View

```html
<div luna:id="comments" luna:client-trigger="visible">
  <!-- Hydrates when IntersectionObserver fires -->
</div>
```

### `media` - When Media Query Matches

```html
<div luna:id="sidebar" luna:client-trigger="media:(min-width: 768px)">
  <!-- Hydrates only on desktop -->
</div>
```

## Creating Islands

### Server-Side (MoonBit)

```moonbit
fn comments_section(props : CommentsProps) -> @luna.Node[Unit] {
  @server_dom.island(
    id="comments",
    url="/static/comments.js",
    state=props.to_json().stringify(),
    trigger=@luna.Visible,
    children=[
      // SSR content shown before hydration
      @server_dom.div([@server_dom.text("Loading comments...")])
    ],
  )
}
```

### Client-Side (TypeScript)

```typescript
// comments.ts
import { createSignal, hydrate } from '@mizchi/luna';

interface CommentsProps {
  postId: string;
}

function Comments(props: CommentsProps) {
  const [comments, setComments] = createSignal([]);

  // Fetch comments on mount
  onMount(async () => {
    const data = await fetch(`/api/comments/${props.postId}`);
    setComments(await data.json());
  });

  return (
    <ul>
      <For each={comments}>
        {(comment) => <li>{comment.text}</li>}
      </For>
    </ul>
  );
}

// Register for hydration
hydrate("comments", Comments);
```

## Island State

Pass serialized state from server to client:

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state='{"count":5}'
  luna:client-trigger="load"
>
  <button>Count: 5</button>
</div>
```

The client receives the state:

```typescript
function Counter(props: { count: number }) {
  const [count, setCount] = createSignal(props.count);
  // Starts at 5, not 0
}
```

## Web Components Islands

Use Declarative Shadow DOM for style encapsulation:

```moonbit
@server_dom.wc_island(
  name="wc-counter",
  url="/static/wc-counter.js",
  styles=":host { display: block; }",
  state=props.to_json().stringify(),
  trigger=@luna.Load,
  children=[...],
)
```

Renders as:

```html
<wc-counter luna:wc-url="/static/wc-counter.js" luna:wc-state='{}'>
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <!-- SSR content -->
  </template>
</wc-counter>
```

## Best Practices

### 1. Identify Interactive Boundaries

Only wrap truly interactive sections:

```
✅ Search box → Island
✅ Comment form → Island
✅ Shopping cart → Island
❌ Navigation menu (static) → No island
❌ Article content → No island
```

### 2. Choose Appropriate Triggers

| Content | Trigger |
|---------|---------|
| Above the fold, critical | `load` |
| Below the fold | `visible` |
| Analytics, non-critical | `idle` |
| Desktop-only features | `media` |

### 3. Minimize Island Count

Fewer, larger islands are better than many small ones:

```
❌ 10 small islands → 10 script loads
✅ 2 larger islands → 2 script loads
```

### 4. Share Common Dependencies

Bundle shared code into a common chunk:

```javascript
// rolldown config
{
  output: {
    chunkFileNames: '_shared/[name]-[hash].js'
  }
}
```
