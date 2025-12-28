---
title: Deploy Adapters
description: Configure deployment for various hosting platforms
---

# Deploy Adapters

Astra automatically generates platform-specific configuration files based on your deploy target. This ensures optimal performance and compatibility with each hosting provider.

## Configuration

Set the `deploy` field in `sol.config.json`:

```json
{
  "deploy": "github-pages"
}
```

## Supported Platforms

| Platform | Value | Generated Files |
|----------|-------|-----------------|
| Static (default) | `static` | None |
| Cloudflare Pages | `cloudflare` | `_routes.json` |
| GitHub Pages | `github-pages` or `github` | `.nojekyll`, `CNAME` |
| Vercel | `vercel` | `vercel.json` |
| Netlify | `netlify` | `_headers`, `_redirects` |
| Deno Deploy | `deno` | None (static files served automatically) |
| Node.js | `node` | None |

## Platform Details

### Cloudflare Pages

Generates `_routes.json` to control which routes are handled by Workers vs static assets.

```json
{
  "deploy": "cloudflare"
}
```

**Generated file** (`_routes.json`):
```json
{
  "version": 1,
  "include": ["/api/*"],
  "exclude": ["/*"]
}
```

Dynamic routes (using `_param_` directories) are automatically added to the `include` array for Worker fallback.

### GitHub Pages

Generates `.nojekyll` to disable Jekyll processing (required for `_luna/` directory) and optionally `CNAME` for custom domains.

```json
{
  "deploy": "github-pages",
  "ogp": {
    "siteUrl": "https://docs.example.com"
  }
}
```

**Generated files**:
- `.nojekyll` - Empty file to disable Jekyll
- `CNAME` - Custom domain (extracted from `ogp.siteUrl`)

### Vercel

Generates `vercel.json` with optimized settings for static sites.

```json
{
  "deploy": "vercel"
}
```

**Generated file** (`vercel.json`):
```json
{
  "trailingSlash": true,
  "cleanUrls": true,
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

Features:
- `trailingSlash` - Matches Astra's URL convention
- `cleanUrls` - Removes `.html` extension
- Cache headers for assets and `_luna/` directory
- SPA fallback rewrite (when `navigation.spa: true`)

### Netlify

Generates `_headers` and `_redirects` files.

```json
{
  "deploy": "netlify"
}
```

**Generated files**:

`_headers`:
```
/assets/*
  Cache-Control: public, max-age=31536000, immutable

/_luna/*
  Cache-Control: public, max-age=31536000, immutable

/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
```

`_redirects`:
```
# SPA fallback (when navigation.spa is true)
/*  /404.html  200

# Or standard 404 fallback
/*  /404.html  404
```

### Deno Deploy

No configuration files needed for static sites. Deno Deploy serves static files automatically.

```json
{
  "deploy": "deno"
}
```

Simply upload your `dist/` directory to Deno Deploy.

## SPA Mode Integration

When SPA navigation is enabled, deploy adapters automatically configure fallback routing:

```json
{
  "navigation": {
    "spa": true
  },
  "deploy": "vercel"
}
```

This adds appropriate rewrite rules to serve `404.html` with a 200 status for client-side routing.

## Custom Domain (GitHub Pages)

To set a custom domain for GitHub Pages, configure `ogp.siteUrl`:

```json
{
  "deploy": "github-pages",
  "ogp": {
    "siteUrl": "https://docs.example.com"
  }
}
```

This generates a `CNAME` file with `docs.example.com`.
