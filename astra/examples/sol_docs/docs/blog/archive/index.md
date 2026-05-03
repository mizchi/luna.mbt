---
title: Blog Archive
description: Archived blog posts (rarely accessed)
revalidate: 60
---

# Blog Archive

This is a **cold** ISR page (TTL: 60 seconds).

## Cold Page Characteristics

- Rarely accessed (< 5% of traffic)
- Short TTL (1 minute)
- Content served stale, revalidated in background
- Lower priority for cache retention

## Archived Posts

- [Old Post 1: Legacy Features](/blog/archive/old-1/) - Deprecated guide
- [Old Post 2: Migration Guide](/blog/archive/old-2/) - Old migration docs
- [Old Post 3: Historical Notes](/blog/archive/old-3/) - Historical context

## ISR Status

| Property | Value |
|----------|-------|
| TTL | 60s (1 min) |
| Type | Cold |
| Traffic | ~5% |
| Strategy | Stale-While-Revalidate |
