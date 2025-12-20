---
title: Tutorial
---

# Tutorial

Learn Luna step by step.

## Choose Your Path

### [JavaScript/TypeScript Tutorial](./js/)

For frontend developers building interactive islands:

1. Basics - Counter example
2. Signals - Reactive state
3. Effects - Side effects
4. Islands - Partial hydration

### [MoonBit Tutorial](./moonbit/)

For MoonBit developers building server-rendered pages:

1. Basics - Counter example
2. Signals - Reactive state
3. Effects - Side effects
4. Islands - Server-side island rendering

## Comparison

| Concept | JavaScript | MoonBit |
|---------|------------|---------|
| Create signal | `createSignal(0)` | `signal(0)` |
| Read signal | `count()` | `count.get()` |
| Write signal | `setCount(5)` | `count.set(5)` |
| Update signal | `setCount(c => c + 1)` | `count.update(n => n + 1)` |
| Effect | `createEffect(() => ...)` | `effect(() => ...)` |
| Memo | `createMemo(() => ...)` | `memo(() => ...)` |
