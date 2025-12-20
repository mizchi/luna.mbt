---
title: API Reference
---

# JavaScript API Reference

## Reactive Primitives

| Function | Description |
|----------|-------------|
| [`createSignal`](./signals#createsignal) | Create a reactive signal |
| [`createEffect`](./signals#createeffect) | Create a side effect |
| [`createMemo`](./signals#creatememo) | Create a cached computed value |
| [`batch`](./signals#batch) | Batch multiple updates |
| [`untrack`](./signals#untrack) | Run without tracking dependencies |
| [`onCleanup`](./signals#oncleanup) | Register cleanup in effect |
| [`onMount`](./signals#onmount) | Run code when component mounts |

## Island Hydration

| Function | Description |
|----------|-------------|
| [`hydrate`](./islands#hydrate) | Hydrate a standard island |
| [`hydrateWC`](./islands#hydratewc) | Hydrate a Web Component island |

## Control Flow Components

| Component | Description |
|-----------|-------------|
| `Show` | Conditional rendering |
| `For` | List rendering |
| `Switch` / `Match` | Multi-condition rendering |

## Sections

- [Signals](./signals) - Reactive state management
- [Islands](./islands) - Partial hydration API
