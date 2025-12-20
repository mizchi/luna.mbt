---
title: API Reference
---

# MoonBit API Reference

## Reactive Primitives

| Function | Description |
|----------|-------------|
| [`signal`](./signals#signal) | Create a reactive signal |
| [`effect`](./signals#effect) | Create a side effect |
| [`memo`](./signals#memo) | Create a cached computed value |
| [`batch`](./signals#batch) | Batch multiple updates |
| [`untrack`](./signals#untrack) | Run without tracking dependencies |
| [`on_cleanup`](./signals#on_cleanup) | Register cleanup in effect |

## Island Rendering

| Function | Description |
|----------|-------------|
| [`island`](./islands#island) | Create an island for hydration |
| [`wc_island`](./islands#wc_island) | Create a Web Component island |

## Server DOM Elements

| Function | Description |
|----------|-------------|
| [`div`, `p`, `span`, ...](./render#elements) | HTML element factories |
| [`text`](./render#text) | Create text node |
| [`attr`](./render#attr) | Create attribute |

## Rendering

| Function | Description |
|----------|-------------|
| [`render_to_string`](./render#render_to_string) | Render VNode to HTML string |

## Sections

- [Signals](./signals) - Reactive state management
- [Islands](./islands) - Server-side island rendering
- [Render](./render) - HTML rendering utilities
