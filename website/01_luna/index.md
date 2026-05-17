---
title: Luna
---

# Luna

A fine-grained reactive UI primitive written in MoonBit, distributed as the `mizchi/luna` mooncake and the `@luna_ui/luna` npm package. The same runtime backs JSX components in TypeScript and direct VNode construction in MoonBit.

## What you get

- **Signals** — read / write / subscribe primitives with automatic dependency tracking. `effect`, `memo`, `batch`, `untracked`, `createRoot`, and per-owner cleanup are all there.
- **VNode + targeted DOM updates** — Luna builds a typed `Node[E]` tree on the server and binds it to live DOM on the client. Signal changes only re-run the nodes that depend on them; there is no full-tree diff.
- **Declarative Shadow DOM SSR** — server-rendered Web Components ship as `<wc-* luna:wc-url=… luna:wc-state=… luna:wc-trigger=…>` with an optional `<template shadowrootmode="open">` payload.
- **Islands loader (~1.1 KB)** — the shipped `wc-loader.js` (`@luna_ui/luna-loader`) scans `[luna:wc-url]`, dispatches by trigger (`load` / `idle` / `visible` / `media:(query)` / `none`), and calls the module's `export default function hydrate(element, state, name)`.
- **Two authoring surfaces** — write components in TypeScript with JSX (`@luna_ui/luna`) or in MoonBit (`@luna.h`, `@luna.signal`). The render pipeline is the same.

## 30-second counter

### TypeScript (JSX)

```typescript
import { createSignal, render } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

render(document.getElementById('app')!, () => (
  <button onClick={() => setCount(c => c + 1)}>
    Count: {count()}
  </button>
));
```

### MoonBit

```moonbit
let count = @luna.signal(0)
let on_inc = @luna.handler(fn(_) { count.set(count.get() + 1) })

let node : @luna.Node[Unit, String] = @luna.h(
  "button",
  [("onClick", @luna.attr_handler(on_inc))],
  [@luna.text_dyn(fn() { "Count: " + count.get().to_string() })],
)
```

## Islands at a glance

The server emits a regular Web Component element; the loader handles the rest. No `customElements.define()` registration is needed — the loader matches on `[luna:wc-url]`, not the tag's custom-element status.

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state='{"initial":0}'
  luna:wc-trigger="visible">
  <template shadowrootmode="open">
    <button>Count: 0</button>
  </template>
</wc-counter>
```

```typescript
// /static/wc-counter.js
import { createSignal, render } from '@luna_ui/luna';

export default function hydrate(element: Element, state: { initial: number }) {
  const [count, setCount] = createSignal(state.initial);
  render(element, () => (
    <button onClick={() => setCount(c => c + 1)}>Count: {count()}</button>
  ));
}
```

## Sibling packages

- [`@luna_ui/components`](https://www.npmjs.com/package/@luna_ui/components) — WAI-ARIA APG headless + styled components (tabs, dialog, slider, …)
- [`mizchi/sol`](../sol/) / [`@luna_ui/sol`](https://www.npmjs.com/package/@luna_ui/sol) — Mars-based SSR framework with file-based routes; emits Luna islands directly from typed `ComponentRef`s
- [`mizchi/astra`](../astra/) / [`@luna_ui/astra`](https://www.npmjs.com/package/@luna_ui/astra) — mountable static-site middleware on the same Mars runtime
- [`@luna_ui/luna-loader`](https://www.npmjs.com/package/@luna_ui/luna-loader) — the WC hydration loader as a standalone artifact (used by Sol and Astra automatically)
- [`@luna_ui/stella`](https://www.npmjs.com/package/@luna_ui/stella) — streaming / shard helpers for SSR Suspense

## Install

### MoonBit (mooncake)

```jsonc
// moon.mod.json
{ "deps": { "mizchi/luna": "0.23.0" } }
```

### TypeScript (npm)

```sh
pnpm add @luna_ui/luna
```

### Project scaffold

```sh
npx @luna_ui/luna new myapp        # TSX template
npx @luna_ui/luna new myapp --mbt  # MoonBit template
```

## Where to next

- [Quick Start](/luna/quick-start/) — first runnable page in under five minutes
- [Why Luna](/luna/why-luna/) — design positioning vs. React / Svelte / Solid
- [Tutorial: JavaScript](/luna/tutorial-js/) — signals → effects → islands, JSX surface
- [Tutorial: MoonBit](/luna/tutorial-moonbit/) — same path with `@luna.h` / `@luna.signal`
- [API Reference: JavaScript](/luna/api-js/) / [MoonBit](/luna/api-moonbit/)
- [Deep Dive](/luna/deep-dive/) — VNode representation, hydration internals, signal graph

The monorepo source is at [github.com/mizchi/luna.mbt](https://github.com/mizchi/luna.mbt).
