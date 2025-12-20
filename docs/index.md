---
title: "Luna UI"
layout: home
---

# Luna UI

A blazing-fast reactive UI framework written in MoonBit

Fine-grained reactivity meets Island Architecture. Ship less JavaScript, load faster.

---

## Why Luna?

### Minimal Runtime, Maximum Performance

| Component | Size |
|-----------|------|
| Hydration Loader | **~1.6 KB** |
| Island Runtime | **~3.2 KB** |
| No Virtual DOM diffing overhead | |

Luna's Island Architecture means you only ship JavaScript for interactive components. Static content stays static.

### Fine-Grained Reactivity

No virtual DOM. No diffing. Direct DOM updates at the signal level.

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

// Only this text node updates - nothing else
createEffect(() => console.log(count()));

setCount(1);  // Logs: 1
setCount(c => c + 1);  // Logs: 2
```

### Island Architecture

Partial hydration with smart loading strategies:

| Trigger | When |
|---------|------|
| `load` | Immediately on page load |
| `idle` | During browser idle time |
| `visible` | When scrolled into view |
| `media` | When media query matches |

```html
<!-- Only this island ships JavaScript -->
<div luna:id="counter" luna:client-trigger="visible">
  <button>Count: 0</button>
</div>
<!-- Everything else is pure HTML -->
```

### SSR Performance

Near-zero overhead for Shadow DOM SSR:

| Operation | Overhead |
|-----------|----------|
| Shadow DOM template syntax | **~0%** vs Plain HTML |
| Hydration update | **~12%** slower |
| adoptable Stylesheets | **8.4x faster** |

The bottleneck is attribute escaping, not the template format.

---

## Multi-Target Architecture

Write once, run anywhere:

| Target | Signal | Render | DOM |
|--------|:------:|:------:|:---:|
| JavaScript | ✅ | ✅ | ✅ |
| Native | ✅ | ✅ | - |
| Wasm | ✅ | ✅ | - |
| Wasm-GC | ✅ | ✅ | - |

Core reactivity works on all MoonBit targets. Use native for SSR, JavaScript for the browser.

---

## Quick Start

### Install

```bash
npm install @mizchi/luna
```

### Create a Component

```tsx
import { createSignal } from '@mizchi/luna';

function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  );
}
```

### Use with MoonBit

```moonbit
let count = @luna.signal(0)
let doubled = @luna.memo(fn() { count.get() * 2 })

@luna.effect(fn() {
  println("Count: \{count.get()}, Doubled: \{doubled()}")
})

count.set(5)  // Prints: Count: 5, Doubled: 10
```

---

## Philosophy

1. **Ship Less JavaScript** - Static content shouldn't cost runtime
2. **Fine-Grained Updates** - Update only what changed, at the DOM level
3. **Progressive Enhancement** - Works without JavaScript, enhances with it
4. **Type Safety** - MoonBit's type system catches errors at compile time

---

## Learn More

- [JavaScript Tutorial](/js/tutorial/) - Get started with TypeScript/JavaScript
- [MoonBit Tutorial](/moonbit/tutorial/) - Server-side rendering with MoonBit
- [Astra](/astra/) - Static site generator for documentation
- [Sol](/sol/) - Full-stack SSR framework

---

## Status

> **Experimental** - Luna is under active development. APIs may change.

Built with [MoonBit](https://www.moonbitlang.com/) - a fast, safe language designed for cloud and edge computing.

[GitHub](https://github.com/aspect-build/aspect-cli) | [npm](https://www.npmjs.com/package/@mizchi/luna)
