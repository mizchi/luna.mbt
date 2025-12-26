---
title: Overview
---

# Luna Ecosystem Overview

Luna is a suite of tools for building modern web applications with MoonBit and JavaScript. This documentation covers four interconnected projects.

## Why Luna?

Luna was born from frustration with existing solutions:

- **React** - Too large for performance-critical applications
- **Qwik / Solid** - Compile-time expansion gets in the way of debugging
- **No WebComponents-first framework existed** - Until now

## Design Philosophy

### So Small That Compile-Time Optimization Is Unnecessary

| Framework | Bundle Size |
|-----------|-------------|
| **Luna** | **~6.7 KB** |
| Preact | ~20 KB |
| Solid | ~7 KB |
| Vue 3 | ~33 KB |
| React | ~42 KB |

Luna is intentionally minimal. The framework overhead is negligible, making compile-time optimizations unnecessary.

### WebComponents First (World's First SSR + Hydration)

Luna is the **first framework to support WebComponents SSR + Hydration**.

- Native browser standards over framework abstractions
- Shadow DOM for style encapsulation
- Declarative Shadow DOM for server rendering

### Runtime Performance

| Scenario | Luna | React |
|----------|------|-------|
| 100×100 DOM shooting game | **60 FPS** | 12 FPS |

Fine-grained reactivity delivers **5x better performance** in real-world scenarios.

### Written in MoonBit

Luna is written in [MoonBit](https://www.moonbitlang.com/) - a language designed for cloud and edge computing.

| Aspect | JavaScript Frameworks | Luna (MoonBit) |
|--------|----------------------|----------------|
| Type Safety | Runtime errors | Compile-time errors |
| SSR Performance | V8 overhead | Native speed |
| Bundle Size | Framework + App | Optimized output |
| Dead Code | Tree-shaking | Guaranteed elimination |

### Fine-Grained Reactivity

Unlike Virtual DOM frameworks, Luna updates only what changed - at the DOM node level.

```
Virtual DOM: State → Create Tree → Diff → Patch (O(n))
Luna:        Signal → Direct DOM Update (O(1))
```

### Islands + Fine-Grained

Luna combines Islands Architecture with fine-grained reactivity:

- **Partial hydration** - Only interactive parts load JavaScript
- **Minimal runtime** - ~3KB loader
- **Fast updates** - Direct DOM manipulation within islands

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Your Application                         │
├─────────────────────────────────────────────────────────────┤
│  Astra (SSG)          │  Sol (SSR Framework)                 │
│  Static docs sites    │  Full-stack apps with islands        │
├─────────────────────────────────────────────────────────────┤
│                       Luna UI                                 │
│           Signals, Islands, Hydration, Components            │
├─────────────────────────────────────────────────────────────┤
│                      MoonBit / JavaScript                    │
└─────────────────────────────────────────────────────────────┘
```

## Projects

### Luna UI

The foundation of everything. Luna provides:

- **Signals** - Fine-grained reactive primitives
- **Islands** - Partial hydration for optimal performance
- **Components** - Web Components with declarative syntax
- **Hydration** - Smart loading strategies (load, idle, visible, media)

### [Astra](/astra/) - Static Site Generator

Build documentation sites and blogs from Markdown. Features:

- Markdown with frontmatter support
- Auto-generated navigation and sidebar
- i18n (internationalization) support
- Syntax highlighting with Shiki
- SPA navigation with View Transitions

This documentation site is built with Astra.

### [Sol](/sol/) - Full-Stack Framework

Server-side rendering framework with Hono integration:

- Island Architecture for SSR + partial hydration
- File-based routing
- Edge-ready deployment
- State serialization and resumption

### [Stella](/stella/) - Dev Tools

Development utilities and experimental features:

- Development server with hot reload
- Build tools integration
- Testing utilities

## Learning Paths

### For JavaScript/TypeScript Developers

1. Start with [JavaScript Tutorial](/luna/tutorial-js/)
2. Learn [Signals](/luna/api-js/signals) and [Islands](/luna/api-js/islands)
3. Build a site with [Astra](/astra/) or app with [Sol](/sol/)

### For MoonBit Developers

1. Start with [MoonBit Tutorial](/luna/tutorial-moonbit/)
2. Explore [MoonBit API Reference](/luna/api-moonbit/)
3. Build server-side components with Sol

## Quick Start

### JavaScript

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

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

## Quick Comparison

| Feature | Astra | Sol |
|---------|-------|-----|
| Use Case | Documentation, blogs | Web applications |
| Rendering | Static (build-time) | Dynamic (request-time) |
| Routing | File-based | File-based + API routes |
| Islands | Markdown embedded | Component-based |
| Deployment | Static hosting | Edge runtime / Node.js |

## Getting Started

Choose based on your needs:

- **Learning Luna?** → [JavaScript Tutorial](/luna/tutorial-js/) or [MoonBit Tutorial](/luna/tutorial-moonbit/)
- **Building docs?** → [Astra Quick Start](/astra/)
- **Building an app?** → [Sol Quick Start](/sol/)

## Status

> **Experimental** - All projects are under active development. APIs may change.

Built with [MoonBit](https://www.moonbitlang.com/) - a fast, safe language for cloud and edge computing.
