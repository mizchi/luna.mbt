---
title: Astra
description: Mountable Mars middleware for static-site generation in MoonBit
---

# Astra

> **Experimental**: Astra is under active development. APIs may change.

Astra is a mountable [Mars](https://mooncakes.io/docs/mizchi/mars/) middleware for static-site generation in MoonBit. It renders Markdown / MDX documentation pages on request and serves bundled assets (loader runtime, default CSS, Shiki syntax highlighting). Pair it with the `astra` CLI to dump the same output as a static tree (`astra build`) or serve it from a dev server (`astra dev`).

## What makes Astra different

The middleware and the static dump go through the **same** `Middleware::handler()`. The build crawler calls `@testing.invoke(handler, path=url)` for each entry the middleware exposes and writes the response body to disk. So if a page renders correctly via `astra dev`, it is also correct in the static dump — there is no second renderer to keep in sync.

That property gives Astra two postures:

- **Library**: mount on any Mars server alongside your application routes. The same MoonBit app can serve a `/docs/*` documentation tree and live API endpoints from one binary.
- **Static site**: skip the server entirely. `astra build --out ./dist` produces a self-contained directory you can ship to GitHub Pages, Cloudflare, Vercel, or any static host.

## When to choose Astra over Sol

| Need | Reach for |
|------|-----------|
| Docs / blog with mostly static content | **Astra** |
| Embedded docs alongside an existing Mars app | **Astra** (mounted as middleware) |
| Full SSR app with file-based routing, API routes, server actions | [**Sol**](/sol/) |
| Both, in one repository | Sol with Astra mounted under `/docs/*` |

Astra has no edge to Sol — `deps: mars + markdown + luna`. Sol pulls Astra in for its docs surface but the inverse is not true.

## Sections

- [Getting Started](/astra/getting-started/) — install, first project, first build
- [Mount on Mars](/astra/mount-on-mars/) — embed Astra in an existing Mars server
- [Deploy](/astra/deploy/) — GitHub Pages, Cloudflare, Vercel, Netlify

## Install

Library:

```jsonc
// moon.mod.json
{
  "deps": {
    "mizchi/astra": "0.20.0",
    "mizchi/mars": "0.3.10",
    "mizchi/luna": "0.20.0"
  }
}
```

CLI:

```sh
moon install mizchi/astra/cmd/astra   # → $MOON_HOME/bin/astra
# or via npm if you have node but not moon
pnpm add -g @luna_ui/astra
```

## Quick taste

```bash
mkdir docs && echo "# Hello Astra" > docs/index.md
astra build --out ./dist
# dist/index.html now renders the page
```

A full working example with i18n, MDX, blog, and components lives at [`astra/examples/sol_docs/`](https://github.com/mizchi/luna.mbt/tree/main/astra/examples/sol_docs) in the source repository.
