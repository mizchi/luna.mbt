---
title: Performance
---

# Performance

Luna is designed for minimal runtime overhead and maximum performance.

## Bundle Size

| Component | Size (minified) |
|-----------|-----------------|
| Hydration Loader | **~1.6 KB** |
| Island Runtime (IIFE) | **~3.2 KB** |
| WC Loader | **~1.7 KB** |

Compare to popular frameworks:

| Framework | Runtime Size |
|-----------|-------------|
| **Luna** | **~3 KB** |
| Preact | ~4 KB |
| Solid.js | ~7 KB |
| Vue 3 | ~33 KB |
| React | ~42 KB |

## SSR Benchmarks

### Template Overhead

Shadow DOM template syntax has **near-zero overhead**:

| Operation | ops/sec | vs Plain HTML |
|-----------|---------|---------------|
| String concatenation | 25,450 | baseline |
| Shadow DOM syntax | 25,382 | **~0%** slower |
| Plain HTML syntax | 25,332 | ~0% slower |

The template format is not the bottleneck.

### Real Bottlenecks

| Operation | ops/sec | Overhead |
|-----------|---------|----------|
| Plain concat | 25,450 | baseline |
| JSON.stringify | 2,181 | 12x slower |
| escapeAttr | 396 | **64x slower** |

Attribute escaping dominates SSR time, not template generation.

### Fair Comparison

When comparing with proper escaping:

| Approach | ops/sec | Ratio |
|----------|---------|-------|
| Plain HTML (with escape) | 4,456 | baseline |
| Plain HTML (function components) | 4,359 | 1.02x slower |
| **WC SSR (full processing)** | **4,022** | **1.11x slower** |

Web Components SSR is only **~10% slower** than plain HTML.

## DOM Performance

### Initial Render

| Method | ops/sec | Notes |
|--------|---------|-------|
| createElement | 608,134 | Direct DOM API |
| attachShadow + innerHTML | 171,214 | Shadow Root |
| Plain innerHTML | 170,044 | Parse required |
| Declarative Shadow DOM | 66,810 | Template parse |

### Updates

| Operation | Overhead |
|-----------|----------|
| textContent update | ~12% slower |
| DOM Parts batch | 1.38x faster |
| Adoptable Stylesheets | **8.4x faster** |

## Optimization Tips

### 1. Use Appropriate Triggers

```html
<!-- Don't hydrate until visible -->
<div luna:trigger="visible">...</div>

<!-- Defer non-critical components -->
<div luna:trigger="idle">...</div>
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

### 4. Minimize Reactive Scope

```typescript
// Bad: entire list re-renders
createEffect(() => {
  renderList(items());
});

// Good: only changed items update
<For each={items}>
  {(item) => <Item data={item} />}
</For>
```

## Benchmark Environment

- Vitest 2.1.9 (Browser Mode)
- Playwright (Chromium, Firefox, WebKit)
- Node.js v20+
- MoonBit 0.1.x
