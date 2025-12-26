---
title: FAQ
---

# Frequently Asked Questions

## General

### What is Luna?

Luna is a suite of tools for building modern web applications with MoonBit and JavaScript. It provides:

- **Luna UI** - Signals, Islands, and fine-grained reactivity
- **Astra** - Static Site Generator for documentation
- **Sol** - Full-stack SSR framework
- **Stella** - Development tools

### Why MoonBit?

MoonBit offers:
- Compile-time type safety (no runtime errors)
- Native speed for SSR (no V8 overhead)
- Guaranteed dead code elimination
- Small, optimized output

### Is Luna production-ready?

Luna is currently experimental. APIs may change. Use in production at your own discretion.

## Technical

### How does Luna compare to React?

| Aspect | React | Luna |
|--------|-------|------|
| Update Model | Virtual DOM diffing | Fine-grained signals |
| Hydration | Full page | Partial (islands) |
| Runtime Size | ~42KB | ~3KB |
| Language | JavaScript | MoonBit + JavaScript |

### What is Islands Architecture?

Islands Architecture is a pattern where most of the page is static HTML, with only interactive "islands" loading JavaScript. This results in:

- Faster initial page load
- Smaller JavaScript bundles
- Better performance on low-end devices

### Can I use Luna with existing frameworks?

Luna is designed as a standalone solution. However, you can embed Luna islands in any HTML page.

## Development

### How do I report bugs?

Open an issue on the GitHub repository.

### How do I contribute?

See the contributing guide in the repository.
