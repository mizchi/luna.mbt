---
title: Luna
---

# Luna Core

Luna is a reactive UI library with fine-grained reactivity and Islands Architecture.

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Signals** | Reactive state primitives |
| **Effects** | Side effects that track dependencies |
| **Memos** | Cached computed values |
| **Islands** | Partially hydrated interactive components |

## Sections

- [Why Luna](./why-luna/) - Design philosophy and advantages
- [API Reference](./api/) - Complete API documentation
- [Tutorial](./tutorial/) - Step-by-step learning guides
- [Deep Dive](./deep-dive/) - Advanced concepts and internals

## Quick Start

### JavaScript

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);
createEffect(() => console.log(count()));
setCount(1);
```

### MoonBit

```moonbit
using @luna { signal, effect }

let count = signal(0)
effect(fn() { println(count.get().to_string()) })
count.set(1)
```
