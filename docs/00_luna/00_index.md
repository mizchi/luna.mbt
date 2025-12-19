---
title: Luna
---

# Luna

Luna is a reactive UI library for MoonBit and JavaScript with fine-grained reactivity and Island Architecture.

## Core Concepts

### [Why Luna?](/luna/why-luna/)

Learn about Luna's philosophy, performance characteristics, and how it compares to other frameworks.

- Minimal runtime (~1.6KB loader)
- Fine-grained reactivity without Virtual DOM
- Island Architecture for optimal performance

### [Signals](/luna/signals/)

Signals are the foundation of Luna's reactivity system. Learn how to create and use reactive primitives.

- `createSignal` - Create reactive values
- `createEffect` - React to signal changes
- `createMemo` - Compute derived values

### [Islands](/luna/islands/)

Island Architecture enables partial hydration, shipping JavaScript only where needed.

- Static content stays static
- Interactive components hydrate independently
- Multiple trigger strategies (load, idle, visible, media)

## Quick Links

- [Tutorial (MoonBit)](/tutorial-moonbit/) - Learn Luna with MoonBit
- [Tutorial (JavaScript)](/tutorial-js/) - Learn Luna with JavaScript
- [Astra SSG](/astra/) - Static site generator
- [Sol Framework](/sol/) - Full-stack SSR framework
