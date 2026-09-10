---
title: "API: JavaScript"
---

# JavaScript API Reference

Two pages covering the `@luna_ui/luna` npm package. Every example was executed
against the built `dist/` before being published here.

## Reactive primitives

| Function | Description |
|----------|-------------|
| [`createSignal`](./signals#createsignal) | Create a reactive signal |
| [`createEffect`](./signals#createeffect) | Side effect, deferred to a microtask |
| [`createRenderEffect`](./signals#createeffect) | Side effect, synchronous |
| [`createMemo`](./signals#creatememo) | Cached computed value |
| [`batch`](./signals#batch) | Batch multiple updates |
| [`untrack`](./signals#untrack) | Run without tracking dependencies |
| [`onCleanup`](./signals#oncleanup) | Register cleanup in an effect |
| [`onMount`](./signals#onmount) | Run once without tracking |
| [`on`](./signals#on) | Explicit dependency tracking, with `{ defer }` |
| [`createRoot`](./signals#createroot) | Reactive scope you can dispose |
| [Context API](./signals#context-api) | `createContext`, `provide`, `useContext` |
| [Resource API](./signals#resource-api) | `createResource`, `createDeferred` |
| [Store API](./signals#store-api) | `createStore`, `produce`, `reconcile` |
| [Utilities](./signals#utility-functions) | `mergeProps`, `splitProps` |

## Island hydration

| Export | Description |
|--------|-------------|
| [`export default function hydrate`](./islands#hydration-api) | Island module entry point invoked by the wc-loader |
| [`render(el, jsx)`](./islands#dom-utilities) | Render JSX into the element on hydration |
| [Triggers](./islands#hydration-triggers) | `load` / `idle` / `visible` / `media` / `none` |

## Control flow components

| Component | Description |
|-----------|-------------|
| [`Show`](./islands#control-flow-components) | Conditional rendering |
| [`For` / `Index`](./islands#control-flow-components) | List rendering by reference / by index |
| [`Switch` / `Match`](./islands#control-flow-components) | Multi-branch conditional |
| [`Portal`](./islands#control-flow-components) | Render to a different DOM location |
| [`Provider`](./islands#control-flow-components) | Provide context values |

`Portal` and `Provider` call their children, so those must be **functions**.

## Sections

- [Signals](./signals) — reactive state management
- [Islands](./islands) — partial hydration, control flow, DOM utilities
