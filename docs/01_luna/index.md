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

- [Why Luna](/luna/why-luna/) - Design philosophy and advantages
- [API: JavaScript](/luna/api-js/) - JavaScript API reference
- [API: MoonBit](/luna/api-moonbit/) - MoonBit API reference
- [Tutorial: JavaScript](/luna/tutorial-js/) - Step-by-step JS guide
- [Tutorial: MoonBit](/luna/tutorial-moonbit/) - Step-by-step MoonBit guide
- [Deep Dive](/luna/deep-dive/) - Advanced concepts and internals

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
