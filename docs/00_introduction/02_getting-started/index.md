---
title: Getting Started
---

# Getting Started

Get up and running with Luna in minutes.

## Choose Your Path

### JavaScript/TypeScript Developers

1. Install the package:

```bash
npm install @mizchi/luna
```

2. Start with the [JavaScript Tutorial](/luna/tutorial/js/)

### MoonBit Developers

1. Add to your `moon.mod.json`:

```json
{
  "deps": {
    "mizchi/luna": "0.1.0"
  }
}
```

2. Start with the [MoonBit Tutorial](/luna/tutorial/moonbit/)

## Quick Examples

### JavaScript

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [count, setCount] = createSignal(0);
createEffect(() => console.log(count()));
setCount(1);  // Logs: 1
```

### MoonBit

```moonbit
using @luna { signal, effect }

let count = signal(0)
effect(fn() { println(count.get().to_string()) })
count.set(1)  // Prints: 1
```

## Next Steps

- [Luna Core](/luna/) - Learn about signals, islands, and components
- [Astra](/astra/) - Build documentation sites
- [Sol](/sol/) - Build full-stack applications
