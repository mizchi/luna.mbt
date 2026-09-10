---
title: "API: MoonBit"
---

# MoonBit API Reference

Four pages, one per package you import. Every signature on them is checked
against the generated `.mbti` interfaces in this repository, and the Client DOM
page goes further: it is a `.mbt.md`, so its samples are compiled by
`moon check` and run by `moon test`.

| Page | Package | Alias |
|------|---------|-------|
| [Signals](./signals) | `mizchi/luna/js/resource` | `@resource` |
| [Islands](./islands) | `mizchi/sol` + `mizchi/luna` | `@sol`, `@luna` |
| [Render](./render) | `mizchi/luna/dom/static` | `@server_dom` |
| [Client DOM](./client-dom) | `mizchi/luna/dom` | `@element` |

## Reactive primitives

| Function | Description |
|----------|-------------|
| [`signal`](./signals#signal) | Create a reactive signal |
| [`effect`](./signals#effect) | Create a side effect |
| [`memo` / `computed`](./signals#memo-computed) | Cached computed value (identity cutoff) |
| [`memo_eq`](./signals#memo-eq) | Cached computed value (`Eq` cutoff) |
| [`batch`](./signals#batch) | Batch multiple updates |
| [`untracked`](./signals#untracked) | Run without tracking dependencies |
| [`on_cleanup`](./signals#on-cleanup) | Register cleanup in an effect |
| [Subscription API](./signals#subscription-api) | `on`, `watch`, `previous` |
| [Combinators](./signals#combinators) | `combine2/3/4`, `all`, `any`, `switch_`, `select`, `flatten` |
| [Owner / scope](./signals#owner-scope-management) | `create_root`, `get_owner`, `on_mount` |
| [Context API](./signals#context-api) | `create_context`, `provide`, `use_context` |
| [Resource API](./signals#resource-api) | Async state with loading / error |

## Island rendering

| Function | Description |
|----------|-------------|
| [`@sol.island`](./islands#island-componentref-based-recommended) | Island from a typed `ComponentRef` (recommended) |
| [`@sol.island_raw`](./islands#island-raw-string-based-low-level) | Island from raw strings (low level) |
| [`@luna.wc_island`](./islands#web-components-island-low-level) | Web Component island (low level) |
| [`Trigger`](./islands#trigger) | When hydration happens |

## Client-side rendering

| Function | Description |
|----------|-------------|
| [`render_to`](./client-dom#mounting-a-tree) | Clear an element, then mount a node |
| [`mount_to`](./client-dom#mounting-a-tree) | Append a node to an element |
| [`events`](./client-dom#event-handlers) | Chain typed event handlers onto an element |
| [`portal_to_body` / `portal_to`](./client-dom#portals) | Render children elsewhere in the document |
| [Differences from JS](./client-dom#differences-from-the-javascript-api) | What the JavaScript API accepts that MoonBit does not need |

## Server-side rendering

| Function | Description |
|----------|-------------|
| [`render`](./render#render) | Render a node tree to an HTML string |
| [`render_document`](./render#render-document) | Render with a DOCTYPE |
| [`render_with_preloads`](./render#render-with-preloads) | Render + island preload URLs |
| [`document`](./render#document) | Build a full document node |
| [`div`, `p`, `span`, …](./render#element-helpers) | HTML element helpers |
| [`text`](./render#text) | Text node (escaped) |
| [`attr`](./render#attr) | Attribute value |
| [The node type](./render#low-level-the-node-type) | `Node[E, A]`, `Attr[E, A]`, `render_to_string` |

## Sections

- [Signals](./signals) — reactive state management
- [Islands](./islands) — server-side island rendering and hydration triggers
- [Render](./render) — SSR element helpers and the renderer
- [Client DOM](./client-dom) — mounting, events, portals and context in the browser
