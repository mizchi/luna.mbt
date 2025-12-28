---
title: ISR (Incremental Static Regeneration)
description: Stale-While-Revalidate caching for dynamic content freshness
---

# ISR (Incremental Static Regeneration)

ISR enables static pages to be updated after deployment without rebuilding the entire site.

## Overview

ISR combines the benefits of static generation with dynamic content freshness:

1. **Static at Build** - Pages are pre-rendered at build time
2. **Cached Serving** - Requests served from cache with minimal latency
3. **Background Revalidation** - Stale content triggers async regeneration
4. **No Rebuild Required** - Content updates without full site rebuild

## How It Works

```
Request → Cache Check
            ↓
      ┌─────┴─────┐
      │           │
   Fresh?      Stale?      Miss?
      │           │           │
   Return     Return +     Generate
   cached     schedule      + cache
              revalidate
```

### Cache States

| State | Condition | Behavior |
|-------|-----------|----------|
| **Fresh** | `now < generated_at + TTL` | Return cached immediately |
| **Stale** | `now >= generated_at + TTL` | Return cached + revalidate in background |
| **Miss** | No cache entry | Generate, cache, return |

## Configuration

### Frontmatter

Enable ISR for a page by adding `revalidate` to frontmatter:

```markdown
---
title: My Page
revalidate: 60
---

# Content here
```

The `revalidate` value is in **seconds**.

### TTL Guidelines

| Content Type | Recommended TTL | Example |
|-------------|-----------------|---------|
| **Hot** (high traffic) | 300-600s | Homepage, popular posts |
| **Warm** (moderate) | 60-300s | Tutorials, API docs |
| **Cold** (low traffic) | 30-60s | Archive, old posts |
| **Real-time** | 0 | Always regenerate |

## Build Output

When pages have `revalidate` set, Astra generates an ISR manifest:

```
dist/
└── _luna/
    └── isr.json
```

### Manifest Format

```json
{
  "version": 1,
  "pages": {
    "/blog/": {
      "revalidate": 300,
      "renderer": "markdown",
      "source": "blog/index.md"
    },
    "/blog/post-1/": {
      "revalidate": 120,
      "renderer": "markdown",
      "source": "blog/post-1.md"
    }
  }
}
```

## Runtime Behavior

### Sol Server Integration

Sol automatically loads the ISR manifest and handles caching:

```moonbit
// Initialize ISR handler
let handler = init_isr(dist_dir)

// Handle request
let (html, needs_revalidation) = handler.handle(path)

if needs_revalidation {
  schedule_revalidation(path)
}
```

### Cache Key Format

Cache keys include path and query parameters:

```
isr:/blog/                     # Simple path
isr:/search/?q=luna&sort=date  # With sorted query params
```

Query parameters are sorted alphabetically for consistent cache keys.

## Performance

ISR is optimized for high throughput:

| Operation | Throughput | Latency |
|-----------|------------|---------|
| Cache read | ~6.7M ops/sec | 0.15μs |
| Cache write | ~2.7M ops/sec | 0.36μs |
| Status check | ~4.4M ops/sec | 0.23μs |
| Full handle | ~2.4M req/sec | 0.41μs |

The cache overhead is negligible compared to network I/O.

## Example: Blog with Tiered TTLs

```
docs/
├── blog/
│   ├── index.md           # revalidate: 300 (hot)
│   ├── post-1.md          # revalidate: 120 (warm)
│   ├── post-2.md          # revalidate: 120 (warm)
│   └── archive/
│       ├── index.md       # revalidate: 60 (cold)
│       └── old-post.md    # revalidate: 60 (cold)
```

### Traffic Pattern Simulation

With 50,000 pages following the 80/20 rule:

| Tier | Pages | TTL | Traffic Share |
|------|-------|-----|---------------|
| Hot | 100 | 300s | 80% |
| Warm | 900 | 120s | 15% |
| Cold | 49,000 | 60s | 5% |

Hot pages stay fresh due to frequent access. Cold pages serve stale content briefly then revalidate.

## Stale-While-Revalidate Pattern

ISR implements the SWR pattern:

1. **User A** requests stale page → Gets stale content immediately (no wait)
2. **Background** regeneration starts
3. **User B** requests same page → Gets fresh content

This ensures users never wait for regeneration.

## Deployment Considerations

### Cloudflare Workers

ISR works with Cloudflare's edge caching:

```json
{
  "deploy": "cloudflare"
}
```

The ISR handler integrates with `waitUntil` for background revalidation.

### Memory Cache

For development and single-instance deployments:

```moonbit
let cache = MemoryCache::new()
```

Note: Memory cache is lost on restart. For production, use distributed cache.

## API Reference

### Frontmatter Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `revalidate` | `Int` | None | TTL in seconds (0 = always stale) |

### ISRHandler

```moonbit
// Create handler
fn ISRHandler::new(cache, manifest, dist_dir) -> ISRHandler

// Handle request - returns (html?, needs_revalidation)
fn handle(path: String) -> (String?, Bool)

// Update cache after revalidation
fn update_cache(path: String, html: String) -> Unit
```

### CacheEntry

```moonbit
struct CacheEntry {
  html: String         // Cached HTML content
  generated_at: Int64  // Unix timestamp (ms)
  revalidate: Int      // TTL in seconds
}
```

### CacheStatus

```moonbit
enum CacheStatus {
  Fresh  // Within TTL
  Stale  // Past TTL but content available
  Miss   // No cached content
}
```

## Best Practices

1. **Use appropriate TTLs** - Match TTL to content update frequency
2. **Monitor cache hit rates** - Adjust TTLs based on actual usage
3. **Handle errors gracefully** - Serve stale content on regeneration failure
4. **Consider traffic patterns** - Hot pages benefit most from longer TTLs
5. **Test with realistic data** - Simulate production traffic patterns

## Limitations

- Memory cache doesn't persist across restarts
- Revalidation requires server-side execution
- Query parameter variations create separate cache entries
- Path matching is case-sensitive and exact (trailing slash matters)
