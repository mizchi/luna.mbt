---
title: Hot ISR Page
description: Frequently accessed page with long TTL
revalidate: 300
---

# Hot ISR Page

This is a **hot** page with `revalidate: 300` (5 minutes).

## Characteristics

- High traffic (80% of requests)
- Long TTL keeps content cached
- Less revalidation overhead
- Best for index pages, popular content

## Cache Behavior

```
0s    → Fresh (just generated)
299s  → Fresh (within TTL)
300s  → Stale (triggers revalidation)
301s  → Fresh (if revalidation completed)
```

## Use Cases

- Homepage
- Popular blog posts
- Documentation index pages
- High-traffic landing pages
