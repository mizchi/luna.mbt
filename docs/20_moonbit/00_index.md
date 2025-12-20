---
title: MoonBit
---

# Luna for MoonBit

Build server-rendered pages with fine-grained reactivity.

## Getting Started

Luna provides a reactive system for MoonBit that renders HTML on the server. Combined with client-side TypeScript islands, it enables the Islands Architecture pattern.

```moonbit
using @server_dom { div, p, button, text }
using @luna { signal }

fn counter(initial : Int) -> @luna.Node {
  let count = signal(initial)

  div([
    p([text("Count: " + count.get().to_string())]),
    button([text("Increment")]),
  ])
}
```

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Signals** | Reactive state primitives |
| **Effects** | Side effects that track dependencies |
| **Memos** | Cached computed values |
| **server_dom** | Server-side DOM element factories |
| **Islands** | Partially hydrated interactive components |

## Learn

### Tutorial

Step-by-step guide to Luna's reactive primitives and server rendering:

1. [Basics](./tutorial/introduction_basics) - Counter example
2. [Signals](./tutorial/introduction_signals) - Reactive state
3. [Effects](./tutorial/introduction_effects) - Side effects
4. [Islands](./tutorial/islands_basics) - Server-side island rendering

[Start the Tutorial &rarr;](./tutorial/)

### API Reference

- [Signals API](./api/signals) - signal, effect, memo
- [Islands API](./api/islands) - island, wc_island
- [Render API](./api/render) - render_to_string

## Installation

Add to your `moon.mod.json`:

```json
{
  "deps": {
    "mizchi/luna": "0.1.0"
  }
}
```

## Key Differences from TypeScript

| TypeScript | MoonBit |
|------------|---------|
| `createSignal(0)` | `signal(0)` |
| `count()` | `count.get()` |
| `setCount(5)` | `count.set(5)` |
| `setCount(c => c + 1)` | `count.update(n => n + 1)` |
| `createEffect(() => ...)` | `effect(() => ...)` |
| `createMemo(() => ...)` | `memo(() => ...)` |

## See Also

- [JavaScript Tutorial](/js/tutorial/) - Client-side hydration with TypeScript
- [Astra](/astra/) - Static Site Generator
- [Sol](/sol/) - SSR Framework
