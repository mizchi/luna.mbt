---
title: Tutorial
---

# Luna Tutorial

Learn Luna step by step, from basic concepts to advanced patterns.

## Structure

This tutorial is organized into progressive sections:

### 1. [Introduction](./introduction_basics)

Start here. Learn the fundamentals of Luna's reactive system.

| Lesson | Topic |
|--------|-------|
| [Basics](./introduction_basics) | Your first Luna component |
| [Signals](./introduction_signals) | Reactive state management |
| [Effects](./introduction_effects) | Side effects and subscriptions |
| [Memos](./introduction_memos) | Computed/derived values |

### 2. [Reactivity](./reactivity_batch)

Deep dive into Luna's reactivity system.

| Lesson | Topic |
|--------|-------|
| [Batch](./reactivity_batch) | Batching multiple updates |
| [Untrack](./reactivity_untrack) | Opting out of tracking |
| [Nested Effects](./reactivity_nested) | Effect composition |

### 3. [Control Flow](./flow_show)

Conditional rendering and lists.

| Lesson | Topic |
|--------|-------|
| [Show](./flow_show) | Conditional rendering |
| [For](./flow_for) | List rendering |
| [Switch](./flow_switch) | Multiple conditions |

### 4. [Lifecycle](./lifecycle_onmount)

Component lifecycle management.

| Lesson | Topic |
|--------|-------|
| [onMount](./lifecycle_onmount) | Run code after mount |
| [onCleanup](./lifecycle_oncleanup) | Cleanup resources |

### 5. [Islands](./islands_basics)

Luna's partial hydration architecture.

| Lesson | Topic |
|--------|-------|
| [Basics](./islands_basics) | Creating your first Island |
| [Triggers](./islands_triggers) | Controlling hydration timing |
| [State](./islands_state) | Server-to-client state transfer |
| [Web Components](./islands_webcomponents) | Islands with Shadow DOM |

## Prerequisites

- Basic knowledge of HTML, CSS, and JavaScript/TypeScript
- Familiarity with component-based UI development

## Code Examples

Each lesson includes:

- **Explanation** - Concept overview
- **Code** - Working example in TypeScript and MoonBit
- **Try It** - Interactive playground (when available)

## API Reference

For complete API documentation, see:

- [Signals API](/guide/signals)
- [Islands API](/guide/islands)
- [Performance](/performance/)
