---
title: Why Luna
---

# Why Luna?

Luna is not just another JavaScript framework. It's a fundamentally different approach to building web UIs.

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

## Tiny Runtime

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
