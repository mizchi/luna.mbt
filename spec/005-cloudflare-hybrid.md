# Cloudflare Hybrid Static/Dynamic Routing

A hybrid design where static content is served at high speed from the CDN, and only dynamic routes are processed by the Worker.

## Overview

```
┌─────────────────────────────────────────────┐
│  Cloudflare CDN Edge                        │
│  (Static files: HTML, CSS, JS, images)      │
└─────────────────────┬───────────────────────┘
                      │ run_worker_first
                      ▼
┌─────────────────────────────────────────────┐
│  Cloudflare Worker (Sol)                    │
│  - API routes (/api/*)                      │
│  - ISR pages (/blog/:slug)                  │
│  - Auth-required pages (/admin/*)           │
└─────────────────────────────────────────────┘
```

## Route Analyzer

`@router.analyze_routes()` extracts dynamic routes from SolRoutes:

```moonbit
// Criteria for determining dynamic routes
// 1. API routes (Get, Post) -> always dynamic
// 2. ISR pages (revalidate != None) -> dynamic
// 3. Dynamic path params (:id, [slug]) -> dynamic
// 4. Catch-all routes ([...slug]) -> dynamic
// 5. Everything else -> static
```

## Usage

### 1. Route Definition

```moonbit
// routes.mbt
pub fn routes() -> Array[@router.SolRoutes] {
  [
    @router.with_mw([@mw.logger()], [
      // Static pages - served from CDN
      @router.page("/", home, title="Home"),
      @router.page("/about", about, title="About"),

      // ISR pages - processed by Worker
      @router.page("/blog/:slug", blog_post, title="Blog", revalidate=Some(60)),

      // API - processed by Worker
      @router.api_get("/api/users/:id", get_user),
      @router.api_post("/api/users", create_user),
    ]),
  ]
}
```

### 2. wrangler.json Generation

```moonbit
// Analyze and generate wrangler configuration
pub fn generate_deploy_config() -> String {
  @router.generate_wrangler_assets_config(routes(), "./dist")
}
```

### 3. Build Script

```bash
# moon build
moon build --target js

# Generate wrangler.json
node -e "
import { generate_deploy_config } from './dist/server.js';
import { writeFileSync } from 'node:fs';
writeFileSync('wrangler.json', JSON.stringify({
  name: 'my-site',
  main: './dist/worker.js',
  assets: JSON.parse(generate_deploy_config())
}, null, 2));
"
```

### 4. Generated wrangler.json

```json
{
  "name": "my-site",
  "main": "./dist/worker.js",
  "assets": {
    "directory": "./dist",
    "html_handling": "auto-trailing-slash",
    "not_found_handling": "single-page-application",
    "run_worker_first": [
      "/api/*",
      "/blog/*"
    ]
  }
}
```

## API Reference

### analyze_routes(routes)

Analyzes SolRoutes and returns the classification of each route.

```moonbit
pub fn analyze_routes(routes : Array[SolRoutes]) -> Array[AnalyzedRoute]

pub enum RouteKind {
  Static   // Static route - served from CDN
  Dynamic  // Dynamic route - processed by Worker
}

pub struct AnalyzedRoute {
  pattern : String    // URL pattern
  kind : RouteKind    // Classification
  reason : String     // Reason for classification
}
```

### extract_dynamic_patterns(routes)

Extracts dynamic route patterns in Cloudflare format.

```moonbit
pub fn extract_dynamic_patterns(routes : Array[SolRoutes]) -> Array[String]

// Conversion examples:
// /user/:id        -> /user/*
// /docs/[...slug]  -> /docs/*
// /api/health      -> /api/health
```

### generate_wrangler_assets_config(routes, output_dir)

Generates the assets configuration for wrangler.json.

```moonbit
pub fn generate_wrangler_assets_config(
  routes : Array[SolRoutes],
  output_dir : String,
) -> String
```

## Dynamic Route Classification Logic

| Route Type | Classification | Reason |
|-----------|----------------|--------|
| API (Get/Post) | Dynamic | Requires runtime processing |
| ISR (revalidate configured) | Dynamic | Requires background revalidation |
| Path params (`:id`, `[id]`) | Dynamic | Values unknown at build time |
| Catch-all (`[...slug]`) | Dynamic | Variable number of path segments |
| Static path | Static | Can be generated at build time |

## References

- [Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/)
- [run_worker_first Configuration](https://developers.cloudflare.com/workers/static-assets/routing/worker-script/)
