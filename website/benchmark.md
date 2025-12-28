---
title: Benchmark Report
---

# Luna Benchmark Report

Comparison benchmark results: Luna vs React vs Preact.

## TL;DR - Luna's Strengths

| Metric | Luna | Note |
|--------|------|------|
| **Bundle Size** | 9.4 KB (gzip) | 1/6 of React |
| **SSR Performance** | 12,800 pages/sec | 1000-item list |
| **Signal Update** | 11M ops/sec | Fine-Grained Reactivity |
| **Partial Update** | 4.5M ops/sec | Direct DOM update |

## Bundle Size Comparison

| Library | Minified | Gzip | vs React |
|---------|----------|------|----------|
| React 19 + ReactDOM | 193 KB | 60 KB | - |
| **Luna** | **33 KB** | **9.4 KB** | **6x smaller** |
| Preact 10 + hooks | 13 KB | 5.4 KB | 15x smaller |

**Luna is 1/6 the size of React**. Larger than Preact, but includes Signal, SSR, and Island Architecture as a full-stack framework.

## Runtime Performance

Benchmark results in jsdom environment (vitest bench).

### Initial Mount (2,500 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 981 | 1x |
| React | 123 | 8x slower |
| Luna | 67 | 14.6x slower |

### Reactive State Mount (2,500 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 61 | 1x |
| React | 42 | 1.4x slower |
| Luna | 42 | 1.5x slower |

### State Update (2,500 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 12,523 | 1x |
| React | 119 | 105x slower |
| Luna | 111 | 113x slower |

> Note: Preact's extremely fast update may be due to state change batching.

### Large Grid (5,000 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 387 | 1x |
| React | 53 | 7.3x slower |
| Luna | 29 | 13.3x slower |

### List Operations (Add 100 items)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 2,876 | 1x |
| React | 65 | 44x slower |
| Luna | 72 | 40x slower |

## Analysis

### Current Status

Luna is currently **slower than React/Preact in raw speed**. This is due to:

1. **MoonBit → JS compilation**: Generated JS code has room for optimization compared to hand-written code
2. **Fine-Grained Reactivity overhead**: Dependency tracking cost per element
3. **Early development stage**: Optimization work is still in progress

### Luna's Value Proposition

Speed isn't everything. Luna provides these values:

| Feature | Luna | React | Preact |
|---------|------|-------|--------|
| **Island Architecture** | ✅ Built-in | ❌ | ❌ |
| **Fine-Grained Reactivity** | ✅ | ❌ (VDOM) | ❌ (VDOM) |
| **SSR** | ✅ Native | Requires Next.js etc. | ✅ preact-render-to-string |
| **Hydration Strategies** | ✅ load/idle/visible/media | ❌ | ❌ |
| **Type Safety** | ✅ MoonBit | TypeScript | TypeScript |
| **Multi-target** | ✅ js/native/wasm | JS only | JS only |

### Future Optimization Opportunities

1. **wasm-gc target**: MoonBit can compile to wasm-gc, potentially faster than JS in the future
2. **Compiler optimization**: Automatic speedup through MoonBit compiler improvements
3. **DOM operation optimization**: Current implementation has room for improvement

## Benchmark Environment

- Node.js v24 + jsdom
- Vitest 4.0.15
- macOS Darwin 24.5.0

## Running Benchmarks

```bash
cd luna.mbt
npx vitest bench js/luna/benches/grid.bench.ts --run
```

## Luna's Strengths - MoonBit Benchmarks

Internal MoonBit benchmark results for Luna. These demonstrate Luna's architectural strengths.

### SSR (Server-Side Rendering)

| Test | Time | ops/sec |
|------|------|---------|
| Simple element | 0.13 µs | 7.7M |
| 10 item list | 0.83 µs | 1.2M |
| 100 item list | 8.12 µs | 123K |
| **1000 item list** | **78 µs** | **12.8K** |
| 10 card page | 5.95 µs | 168K |
| 50 card page | 28.5 µs | 35K |
| 100 card page | 58.4 µs | 17K |

**SSR performance is extremely fast** - Can generate a 1000-element list in 78µs.

### Signal (Fine-Grained Reactivity)

| Operation | Time | ops/sec |
|-----------|------|---------|
| Signal::new | ~0.36 µs/100 | 280K |
| Signal::get | 0.28 µs/1000 | 3.6M |
| **Signal::set** | **0.09 µs** | **11M** |
| Memo cached read | 0.28 µs/1000 | 3.6M |
| Memo recompute | 0.63 µs | 1.6M |
| Effect rerun | ~1 µs | 1M |
| Batch 100 updates | 5 µs | 200K |

**Signal updates at 11M ops/sec** - Orders of magnitude faster than React's setState.

### DOM Updates (Fine-Grained)

| Operation | Time | ops/sec |
|-----------|------|---------|
| **Text update** | **0.22 µs** | **4.5M** |
| Attr update | 0.39 µs | 2.6M |
| Show toggle | 2.56 µs | 390K |
| Deep update (5 levels) | 0.37 µs | 2.7M |

**Partial updates at 4.5M ops/sec** - Direct DOM updates without VDOM diffing.

### Why Luna is Slower in VDOM Benchmarks

Luna is slower than Preact in grid benchmarks (updating all 2,500 cells), because:

1. **Full element updates are not Luna's target use case**
   - Fine-Grained Reactivity assumes "update only parts"
   - Updating all 2,500 cells every time suits VDOM

2. **Luna's design philosophy**
   - Only changed Signals update the DOM
   - 1 cell update = 0.22µs (no VDOM diff needed)

3. **In real apps, Luna excels when**
   - Most UIs involve partial updates
   - Island Architecture distributes initialization cost

## Conclusion

### When Luna is a Good Fit

- ✅ Need **SSR + selective hydration**
- ✅ Want **Island Architecture** for partial hydration
- ✅ **Frequent partial updates** (reactive dashboards, etc.)
- ✅ **Small bundle size** matters (1/6 of React)
- ✅ Want type-safe UI with MoonBit
- ✅ Looking ahead to wasm-gc support

### When Luna is Not a Good Fit

- ❌ **Mass element updates** (game frame updates, etc.)
- ❌ Need React/Preact ecosystem (existing libraries)

### Comparison Summary

| Aspect | Luna | Preact | React |
|--------|------|--------|-------|
| Bundle Size | ⭐⭐⭐ 9KB | ⭐⭐⭐⭐ 5KB | ⭐ 60KB |
| Full Update | ⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| Partial Update | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| SSR | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Island Architecture | ⭐⭐⭐⭐ Built-in | ❌ | ❌ |
