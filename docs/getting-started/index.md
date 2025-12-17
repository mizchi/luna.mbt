---
title: Getting Started
---

# Getting Started

Learn how to install Luna and create your first component.

## Installation

### npm (for JavaScript/TypeScript)

```bash
npm install @mizchi/luna
```

### MoonBit

Add to your `moon.mod.json`:

```json
{
  "deps": {
    "mizchi/luna": "0.1.0"
  }
}
```

## Your First Component

### With TypeScript/JSX

```tsx
import { createSignal } from '@mizchi/luna';

function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <div>
      <p>Count: {count()}</p>
      <button onClick={() => setCount(c => c + 1)}>
        Increment
      </button>
    </div>
  );
}
```

### With MoonBit

```moonbit
fn counter() -> @element.DomNode {
  let count = @luna.signal(0)

  @element.div([
    @element.p([@element.text_dyn(fn() { "Count: \{count.get()}" })]),
    @element.button(
      on=@element.events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
      [@element.text("Increment")],
    ),
  ])
}
```

## Next Steps

- [Signals](/guide/signals) - Learn about reactive primitives
- [Components](/guide/components) - Build reusable components
- [Islands](/guide/islands) - Partial hydration patterns
