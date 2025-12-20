---
title: JavaScript
---

# Luna for JavaScript/TypeScript

Build interactive islands with fine-grained reactivity.

## Getting Started

Luna provides a minimal reactive runtime for client-side interactivity. Combined with server-rendered HTML, it enables the Islands Architecture pattern.

```typescript
import { createSignal, hydrate } from '@mizchi/luna';

function Counter(props: { initial: number }) {
  const [count, setCount] = createSignal(props.initial);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  );
}

hydrate("counter", Counter);
```

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Signals** | Reactive state primitives |
| **Effects** | Side effects that track dependencies |
| **Memos** | Cached computed values |
| **Islands** | Partially hydrated interactive components |

## Learn

### Tutorial

Step-by-step guide to Luna's reactive primitives and Islands:

1. [Basics](./tutorial/introduction_basics) - Counter example
2. [Signals](./tutorial/introduction_signals) - Reactive state
3. [Effects](./tutorial/introduction_effects) - Side effects
4. [Islands](./tutorial/islands_basics) - Partial hydration

[Start the Tutorial &rarr;](./tutorial/)

### API Reference

- [Signals API](./api/signals) - createSignal, createEffect, createMemo
- [Islands API](./api/islands) - hydrate, hydrateWC

## Installation

```bash
npm install @mizchi/luna
```

## See Also

- [MoonBit Tutorial](/moonbit/tutorial/) - Server-side rendering with MoonBit
- [Astra](/astra/) - Static Site Generator
- [Sol](/sol/) - SSR Framework
