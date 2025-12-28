---
title: Why Luna
---

# Why Luna?

Luna is not just another JavaScript framework. It's a fundamentally different approach to building web UIs, born from frustration with existing solutions.

## The Problem with Existing Frameworks

- **React** - Too large. The runtime overhead is unacceptable for performance-critical applications.
- **Qwik / Solid** - Compile-time expansion gets in the way. The magic makes debugging harder.
- **No WebComponents-first framework** - Existing frameworks treat Web Components as second-class citizens.

Luna addresses these gaps directly.

## Design Philosophy

### So Small That Compile-Time Optimization Is Unnecessary

| Framework | Bundle Size |
|-----------|-------------|
| **Luna** | **~6.7 KB** |
| Preact | ~20 KB |
| Solid | ~7 KB |
| Vue 3 | ~33 KB |
| React | ~42 KB |

Luna is intentionally minimal. When your framework is this small, you don't need sophisticated compile-time optimizations to achieve good performance. The overhead is already negligible.

### WebComponents First (World's First SSR + Hydration)

Luna is the **first framework to support WebComponents SSR + Hydration**.

- Native browser standards over framework abstractions
- Shadow DOM for style encapsulation
- Declarative Shadow DOM for server rendering
- Islands that work with any framework

### Runtime Performance That Matters

| Scenario | Luna | React |
|----------|------|-------|
| 100×100 DOM shooting game | **60 FPS** | 12 FPS |

Fine-grained reactivity without Virtual DOM diffing delivers **5x better performance** in real-world scenarios.

## Written in MoonBit

Luna is written in [MoonBit](https://www.moonbitlang.com/) - a language designed for cloud and edge computing.

| Aspect | JavaScript Frameworks | Luna (MoonBit) |
|--------|----------------------|----------------|
| Type Safety | Runtime errors | Compile-time errors |
| SSR Performance | V8 overhead | Native speed |
| Bundle Size | Framework + App | Optimized output |
| Dead Code | Tree-shaking | Guaranteed elimination |

## Fine-Grained Reactivity

Unlike Virtual DOM frameworks, Luna updates only what changed - at the DOM node level.

```
Virtual DOM: State → Create Tree → Diff → Patch (O(n))
Luna:        Signal → Direct DOM Update (O(1))
```

## Islands + Fine-Grained

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
│                       Luna (Core)                            │
│           Signals, Islands, Hydration, Components            │
├─────────────────────────────────────────────────────────────┤
│                      MoonBit / JavaScript                    │
└─────────────────────────────────────────────────────────────┘
```
