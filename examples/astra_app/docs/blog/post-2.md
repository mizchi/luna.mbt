---
title: "Post 2: Advanced Topics"
description: Advanced guide post
revalidate: 120
---

# Advanced Topics

This is a **warm** ISR page (TTL: 120 seconds).

## Signals Deep Dive

Understanding how signals work under the hood.

```moonbit
let count = signal(0)
effect(fn() {
  println("Count: " + count.get().to_string())
})
```

## Performance Optimization

Tips for optimizing your Luna application.

## ISR Characteristics

| Property | Value |
|----------|-------|
| TTL | 120s (2 min) |
| Type | Warm |
| Access Pattern | Moderate traffic |
