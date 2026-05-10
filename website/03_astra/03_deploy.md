---
title: Deploy
description: Ship the astra build output to GitHub Pages, Cloudflare, Vercel, Netlify
---

# Deploy

`astra build` produces a self-contained directory you can deploy to any static host. Setting `deploy` in `astra.config.json` makes Astra emit platform-specific configuration files alongside the HTML.

## Configuration

```json
{
  "deploy": "github-pages"
}
```

Then:

```sh
astra build --out ./dist
```

## Supported platforms

| Platform | `deploy` value | Generated files |
|----------|----------------|-----------------|
| Static (default) | `static` | None |
| Cloudflare Pages / Workers | `cloudflare` | `_routes.json` |
| GitHub Pages | `github-pages` or `github` | `.nojekyll`, `CNAME` (if set) |
| Vercel | `vercel` | `vercel.json` |
| Netlify | `netlify` | `_headers`, `_redirects` |
| Deno Deploy | `deno` | None — files served as-is |
| Node.js | `node` | None |

## GitHub Pages

```json
{
  "deploy": "github-pages",
  "base": "/my-repo/",
  "github": {
    "repo": "mizchi/my-repo",
    "branch": "gh-pages"
  }
}
```

`base` must match the repository path because GitHub Pages serves user/org sites under `/<repo>/`. The build emits `.nojekyll` so files starting with `_` (like `_astro` chunks) are not stripped.

## Cloudflare Pages

```json
{
  "deploy": "cloudflare",
  "base": "/"
}
```

Astra emits `_routes.json` so Cloudflare's edge runtime knows which paths are static vs dynamic. Custom Functions can live alongside the static output without conflict.

## Search index (pagefind)

Astra does not generate a search index by itself. Run pagefind against the build output if you need full-text search:

```sh
astra build --out ./dist
pnpm exec pagefind --site ./dist
```

The `dist/pagefind/` directory pagefind produces is what the bundled `<pagefind-ui>` component reads at runtime. The Luna documentation site does this in CI before deploying — see [`.github/workflows/deploy-website.yml`](https://github.com/mizchi/luna.mbt/blob/main/.github/workflows/deploy-website.yml) for the pattern.

## Verifying the build before deploy

`tests/integration/website-asset-integrity.test.js` in the Luna repo crawls every HTML file in the build output, parses local `src` / `href` references, and asserts each one exists. Running that test pattern against your own site catches broken asset links before the deploy.
