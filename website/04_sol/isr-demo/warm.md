---
title: Warm ISR Page
description: Moderately accessed page with medium TTL
revalidate: 120
---

# Warm ISR Page

This is a **warm** page with `revalidate: 120` (2 minutes).

## Characteristics

- Moderate traffic (15% of requests)
- Balanced TTL for freshness vs performance
- Good for content that updates occasionally
- Typical for category pages, tutorials

## Cache Behavior

```
0s    → Fresh (just generated)
119s  → Fresh (within TTL)
120s  → Stale (triggers revalidation)
121s  → Fresh (if revalidation completed)
```

## Use Cases

- Tutorial pages
- API reference pages
- Category listings
- News articles (after initial spike)
