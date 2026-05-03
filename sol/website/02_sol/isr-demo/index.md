---
title: ISR Demo
description: Incremental Static Regeneration demonstration
revalidate: 300
---

# ISR Demo

This page demonstrates **Incremental Static Regeneration (ISR)** in Sol.

## What is ISR?

ISR allows you to create or update static pages *after* you've built your site:

1. **Static at Build** - Pages are pre-rendered at build time
2. **Stale-While-Revalidate** - Serve stale content while regenerating
3. **Background Updates** - Content refreshes without user waiting

## This Page's Configuration

| Setting | Value |
|---------|-------|
| Revalidate | 300 seconds (5 minutes) |
| Type | Hot (frequently accessed) |

## Demo Pages

- [Hot Page](/sol/isr-demo/hot/) - TTL: 300s
- [Warm Page](/sol/isr-demo/warm/) - TTL: 120s
- [Cold Page](/sol/isr-demo/cold/) - TTL: 60s

## How It Works

```
Request → Cache Hit?
            ↓ Yes (Fresh) → Return cached HTML
            ↓ Yes (Stale) → Return cached HTML + Trigger revalidation
            ↓ No (Miss)   → Generate HTML + Cache
```
