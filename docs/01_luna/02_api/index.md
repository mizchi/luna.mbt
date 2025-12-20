---
title: API Reference
---

# API Reference

Complete API documentation for Luna.

## Choose Your Language

- [JavaScript/TypeScript](./js/) - Client-side API
- [MoonBit](./moonbit/) - Server-side API

## Overview

### JavaScript API

```typescript
// Signals
createSignal(value)      // Create reactive state
createEffect(fn)         // Create side effect
createMemo(fn)           // Create cached computation

// Islands
hydrate(name, Component) // Register island for hydration
hydrateWC(name, render)  // Register web component island
```

### MoonBit API

```moonbit
// Signals
signal(value)           // Create reactive state
effect(fn)              // Create side effect
memo(fn)                // Create cached computation

// Islands
island(name, render)    // Create island placeholder
wc_island(name, render) // Create web component island

// Rendering
render_to_string(node)  // Render node to HTML string
```
