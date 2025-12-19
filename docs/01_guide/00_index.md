---
title: Guide
---

# Luna Guide

Welcome to the Luna UI guide. This section covers the core concepts and features of Luna.

## Core Concepts

### [Why Luna?](/guide/why-luna)

Learn about Luna's philosophy, performance characteristics, and how it compares to other frameworks.

- Minimal runtime (~1.6KB loader)
- Fine-grained reactivity without Virtual DOM
- Island Architecture for optimal performance

### [Signals](/guide/signals)

Signals are the foundation of Luna's reactivity system. Learn how to create and use reactive primitives.

- `createSignal` - Create reactive values
- `createEffect` - React to signal changes
- `createMemo` - Compute derived values

### [Islands](/guide/islands)

Island Architecture enables partial hydration, shipping JavaScript only where needed.

- Static content stays static
- Interactive components hydrate independently
- Multiple trigger strategies (load, idle, visible, media)

## Quick Links

- [Getting Started](/getting-started/) - Installation and first steps
- [Tutorial](/tutorial/) - Interactive learning path
- [Performance](/performance/) - Benchmarks and optimization tips
