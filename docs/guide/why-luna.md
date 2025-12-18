---
title: Why Luna?
---

# Why Luna?

Luna is not just another JavaScript framework. It's a fundamentally different approach to building web UIs.

## Written in MoonBit, Not JavaScript

Luna is written in [MoonBit](https://www.moonbitlang.com/) - a new language designed for cloud and edge computing.

### Why This Matters

```
Traditional Framework:
  JavaScript → JavaScript Runtime → DOM

Luna:
  MoonBit → Native Binary (SSR)
         → JavaScript (Browser)
         → Wasm (Edge)
```

**Benefits:**

| Aspect | JavaScript Frameworks | Luna (MoonBit) |
|--------|----------------------|----------------|
| Type Safety | Runtime errors | Compile-time errors |
| SSR Performance | V8 overhead | Native speed |
| Bundle Size | Framework + App | Optimized output |
| Dead Code | Tree-shaking | Guaranteed elimination |

### Same Logic, Multiple Targets

```moonbit
// This signal code works everywhere
let count = @luna.signal(0)
let doubled = @luna.memo(fn() { count.get() * 2 })

@luna.effect(fn() {
  println("Count: \{count.get()}")
})
```

| Target | Use Case |
|--------|----------|
| **Native** | High-performance SSR server |
| **JavaScript** | Browser hydration |
| **Wasm** | Edge functions, Workers |
| **Wasm-GC** | Next-gen runtimes |

## True Fine-Grained Reactivity

Unlike Virtual DOM frameworks, Luna updates only what changed - at the DOM node level.

### Virtual DOM (React, Vue)

```
State Change
    ↓
Create New Virtual Tree
    ↓
Diff Old vs New Tree    ← O(n) comparison
    ↓
Patch Real DOM
```

### Fine-Grained (Luna, Solid)

```
Signal Change
    ↓
Direct DOM Update       ← O(1) targeted update
```

### Real Difference

```typescript
// Luna: Only this text node updates
<p>Count: {count()}</p>

// Virtual DOM: Entire component re-renders,
// then diffs to find the text change
```

**No wasted renders. No diffing overhead. Direct updates.**

## Island Architecture Done Right

Luna combines Islands with fine-grained reactivity - the best of both worlds.

### Islands (Astro, Fresh)

✅ Partial hydration
✅ Ship less JavaScript
❌ Often uses React/Vue inside islands (large runtime)

### Fine-Grained (Solid, Svelte)

✅ Minimal runtime
✅ Fast updates
❌ Full-page hydration

### Luna: Both

✅ Partial hydration
✅ Ship less JavaScript
✅ Minimal runtime (~1.6KB loader)
✅ Fast updates within islands

```html
<!-- Only this island loads JavaScript -->
<div luna:id="search" luna:client-trigger="visible">
  <!-- Fine-grained reactivity inside -->
</div>

<!-- Pure HTML, zero JavaScript -->
<article>...</article>
```

## Web Components Native

Luna embraces Web Components with Declarative Shadow DOM.

### Why Web Components?

| Feature | Custom Elements | Framework Components |
|---------|----------------|---------------------|
| Style Encapsulation | Built-in (Shadow DOM) | CSS-in-JS, modules |
| Interop | Works anywhere | Framework-specific |
| SSR | Declarative Shadow DOM | Varies |
| Standards | W3C Standard | Proprietary |

### Declarative Shadow DOM SSR

```html
<!-- Server-rendered with styles encapsulated -->
<wc-counter>
  <template shadowrootmode="open">
    <style>
      :host { display: block; }
      button { color: blue; }
    </style>
    <button>Count: 0</button>
  </template>
</wc-counter>
```

**No FOUC. No hydration mismatch. Styles work immediately.**

## Smart Hydration Triggers

Control exactly when and how components hydrate.

```html
<!-- Critical: hydrate immediately -->
<div luna:client-trigger="load">...</div>

<!-- Below fold: hydrate when visible -->
<div luna:client-trigger="visible">...</div>

<!-- Non-critical: hydrate when idle -->
<div luna:client-trigger="idle">...</div>

<!-- Responsive: hydrate on desktop only -->
<div luna:client-trigger="media:(min-width: 768px)">...</div>
```

### Comparison

| Framework | Hydration Control |
|-----------|------------------|
| React | All or nothing |
| Next.js | Per-page (partial with React Server Components) |
| Astro | Per-island, visible trigger |
| Qwik | Resumability (different model) |
| **Luna** | **Per-island, 4 trigger types, media queries** |

## Tiny Runtime

Luna's loader is incredibly small.

| Component | Size (minified) |
|-----------|-----------------|
| Hydration Loader | **~1.6 KB** |
| Island Runtime (IIFE) | **~3.2 KB** |
| WC Loader | **~1.7 KB** |

### Framework Comparison

| Framework | Minimum Runtime |
|-----------|----------------|
| **Luna** | **~3 KB** |
| Preact | ~4 KB |
| Solid | ~7 KB |
| Svelte | ~2 KB (but grows with components) |
| Vue 3 | ~33 KB |
| React | ~42 KB |

**Smaller runtime = Faster load = Better Core Web Vitals**

## SSR Performance

### Template Overhead

Shadow DOM template syntax has **near-zero overhead**:

| Operation | ops/sec | vs Plain HTML |
|-----------|---------|---------------|
| String concatenation | 25,450 | baseline |
| Shadow DOM syntax | 25,382 | **~0%** slower |
| Plain HTML syntax | 25,332 | ~0% slower |

### Fair Comparison

When comparing with proper escaping:

| Approach | ops/sec | Ratio |
|----------|---------|-------|
| Plain HTML (with escape) | 4,456 | baseline |
| Plain HTML (function components) | 4,359 | 1.02x slower |
| **WC SSR (full processing)** | **4,022** | **1.11x slower** |

Web Components SSR is only **~10% slower** than plain HTML.

## Optimization Tips

### 1. Use Appropriate Triggers

```html
<!-- Don't hydrate until visible -->
<div luna:client-trigger="visible">...</div>

<!-- Defer non-critical components -->
<div luna:client-trigger="idle">...</div>
```

### 2. Batch Signal Updates

```typescript
import { batch } from '@mizchi/luna';

// Bad: 3 effect runs
setA(1);
setB(2);
setC(3);

// Good: 1 effect run
batch(() => {
  setA(1);
  setB(2);
  setC(3);
});
```

### 3. Use Memos for Expensive Computations

```typescript
// Computed only when dependencies change
const filtered = createMemo(() =>
  items().filter(item => item.active)
);
```

## Type-Safe State Serialization

State flows from server to client with full type safety.

### MoonBit (Server)

```moonbit
pub struct CounterProps {
  initial : Int
  max : Int
} derive(ToJson, FromJson)

fn counter_island(props : CounterProps) -> @luna.Node[Unit] {
  @server_dom.island(
    id="counter",
    url="/static/counter.js",
    state=props.to_json().stringify(),  // Type-safe serialization
    children=[...],
  )
}
```

### TypeScript (Client)

```typescript
interface CounterProps {
  initial: number;
  max: number;
}

function Counter(props: CounterProps) {
  // props.initial and props.max are typed
  const [count, setCount] = createSignal(props.initial);
  // ...
}
```

**No `any`. No runtime surprises. Types flow end-to-end.**

## Summary

| Feature | Luna's Approach |
|---------|----------------|
| **Language** | MoonBit (compile to native/js/wasm) |
| **Reactivity** | Fine-grained (no Virtual DOM) |
| **Hydration** | Islands with smart triggers |
| **Components** | Web Components native |
| **Runtime** | ~3 KB total |
| **Types** | End-to-end type safety |

Luna is for developers who want:
- **Maximum performance** with minimal runtime
- **Partial hydration** without framework bloat
- **Type safety** from server to client
- **Web standards** over proprietary abstractions
