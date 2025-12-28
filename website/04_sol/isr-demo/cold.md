---
title: Cold ISR Page
description: Rarely accessed page with short TTL
revalidate: 60
---

# Cold ISR Page

This is a **cold** page with `revalidate: 60` (1 minute).

## Characteristics

- Low traffic (5% of requests)
- Short TTL ensures freshness when accessed
- Content often served stale then revalidated
- Good for long-tail content

## Cache Behavior

```
0s    → Fresh (just generated)
59s   → Fresh (within TTL)
60s   → Stale (triggers revalidation)
61s   → Fresh (if revalidation completed)
```

## Stale-While-Revalidate

When a cold page is accessed after TTL:

1. User gets stale content instantly (no waiting)
2. Background revalidation starts
3. Next user gets fresh content

This pattern is ideal for rarely-accessed pages where freshness isn't critical.

## Use Cases

- Archive pages
- Old blog posts
- Legacy documentation
- Deep-linked reference pages
