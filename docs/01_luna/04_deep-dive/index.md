---
title: Deep Dive
---

# Deep Dive

Advanced concepts and internal architecture.

## Topics

### Reactivity System

Luna's reactivity is based on fine-grained signals:

```
Signal
  └── Subscribers (Effects, Memos)
        └── DOM Updates
```

When a signal changes:
1. All subscribers are notified
2. Effects run synchronously (batched)
3. DOM updates happen directly (no diffing)

### Hydration Strategies

Luna supports multiple hydration strategies:

| Strategy | When hydrates | Use case |
|----------|--------------|----------|
| `load` | Immediately | Critical interactions |
| `idle` | Browser idle | Secondary features |
| `visible` | In viewport | Below-the-fold content |
| `media` | Media query matches | Device-specific |

### Web Components Integration

Islands can be implemented as Web Components:

```typescript
hydrateWC("my-counter", (root, props, trigger) => {
  // root: ShadowRoot
  // props: Serialized props
  // trigger: Hydration trigger info
});
```

Benefits:
- Style encapsulation
- Native browser support
- Framework agnostic

### SSR and Serialization

Server-rendered HTML includes:
- Static markup
- Island placeholders (`<luna-island>`)
- Serialized props (base64 encoded)

The client loader:
1. Finds island placeholders
2. Deserializes props
3. Hydrates based on strategy
