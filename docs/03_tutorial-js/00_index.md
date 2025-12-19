---
title: Tutorial (JavaScript)
---

# Tutorial (JavaScript)

Learn Luna UI with JavaScript/TypeScript.

## Getting Started

```bash
npm install @mizchi/luna
```

## Basic Usage

```typescript
import { createSignal, createEffect, createMemo } from '@mizchi/luna';

// Create a reactive signal
const [count, setCount] = createSignal(0);

// Create a computed value
const doubled = createMemo(() => count() * 2);

// React to changes
createEffect(() => {
  console.log(`Count: ${count()}, Doubled: ${doubled()}`);
});

// Update the signal
setCount(1);      // Logs: Count: 1, Doubled: 2
setCount(c => c + 1);  // Logs: Count: 2, Doubled: 4
```

## Topics

- [Basics](/tutorial-js/basics) - Signals, effects, and memos
- [Components](/tutorial-js/components) - Building UI components
- [Islands](/tutorial-js/islands) - Partial hydration

## See Also

- [MoonBit Tutorial](/tutorial-moonbit/) - For MoonBit developers
- [API Reference](/api/) - Full API documentation
