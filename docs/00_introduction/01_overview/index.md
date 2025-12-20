---
title: Overview
---

# Luna Ecosystem Overview

Luna is a suite of tools for building modern web applications with MoonBit and JavaScript. This documentation covers four interconnected projects.

## Why Luna?

Luna is not just another JavaScript framework. It's a fundamentally different approach to building web UIs.

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

### Tiny Runtime

| Framework | Minimum Runtime |
|-----------|----------------|
| **Luna** | **~3 KB** |
| Preact | ~4 KB |
| Solid | ~7 KB |
| Vue 3 | ~33 KB |
| React | ~42 KB |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Your Application                         │
├─────────────────────────────────────────────────────────────┤
│  Astra (SSG)          │  Sol (SSR Framework)                 │
│  Static docs sites    │  Full-stack apps with islands        │
├─────────────────────────────────────────────────────────────┤
│                       Luna (Core)                            │
│           Signals, Islands, Hydration, Components            │
├─────────────────────────────────────────────────────────────┤
│                      MoonBit / JavaScript                    │
└─────────────────────────────────────────────────────────────┘
```

## Projects

### Luna Core

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

1. Start with [JavaScript Tutorial](/js/tutorial/)
2. Learn [Signals](/js/api/signals) and [Islands](/js/api/islands)
3. Build a site with [Astra](/astra/) or app with [Sol](/sol/)

### For MoonBit Developers

1. Start with [MoonBit Tutorial](/moonbit/tutorial/)
2. Explore [MoonBit API Reference](/moonbit/api/)
3. Build server-side components with Sol

## Quick Start

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

- **Learning Luna?** → [JavaScript Tutorial](/js/tutorial/) or [MoonBit Tutorial](/moonbit/tutorial/)
- **Building docs?** → [Astra Quick Start](/astra/)
- **Building an app?** → [Sol Quick Start](/sol/)

## Status

> **Experimental** - All projects are under active development. APIs may change.

Built with [MoonBit](https://www.moonbitlang.com/) - a fast, safe language for cloud and edge computing.
