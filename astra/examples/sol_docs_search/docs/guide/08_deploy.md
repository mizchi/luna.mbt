---
title: Deploy
description: Pushing the combined Astra + PageFind output to Cloudflare Pages, GitHub Pages, or any static host.
---

<search-box></search-box>

# Deploy

Because `dist/` is a plain tree of files after the build, you can host it on anything that speaks HTTP. This page covers the most common targets.

## Cloudflare Pages

The `astra.config.json` in this example sets `"deploy": "cloudflare"`, which tweaks a few build-time defaults (asset hashing, trailing-slash behaviour) to match what Cloudflare Pages expects.

Push to a Git remote, then in the Cloudflare dashboard:

1. Connect the repository.
2. Set the build command to `pnpm build`.
3. Set the build output directory to `astra/examples/sol_docs_search/dist` (or the appropriate path inside your repo).
4. Set the Node.js version to 20+.

Cloudflare Pages caches `node_modules/` and `~/.local/share/pnpm/store/` automatically, so subsequent builds are fast.

The `pagefind/` directory is served as static assets without any extra config.

## GitHub Pages

GitHub Pages serves static files from a branch or directory. The workflow:

```yaml
name: deploy
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: pnpm install
      - run: pnpm build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: astra/examples/sol_docs_search/dist
  deploy:
    needs: build
    permissions:
      pages: write
      id-token: write
    runs-on: ubuntu-latest
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

GitHub Pages serves under a sub-path (e.g. `https://user.github.io/repo/`). Set `"base_url": "/repo/"` in `astra.config.json` so internal links resolve. PageFind respects `base_url` — links it generates in results are rewritten relative to it.

## Cloudflare Workers (with assets binding)

If you want SSR alongside the static index (e.g. server-rendered route handlers from the same MoonBit module), see the `sol_adapter_cloudflare` package. The static assets including `pagefind/` are served by the `ASSETS` binding, and request URLs not matching a static file fall through to the worker.

## Plain HTTP server

For a local preview that mirrors what the deploy looks like:

```sh
pnpm dlx http-server dist -p 5560
```

The `--cors` flag is useful if you want to embed the docs in another origin. For production, prefer a real static host with HTTP/2 and proper cache headers — PageFind's chunked index benefits enormously from HTTP/2 multiplexing.

## Cache headers

PageFind's index files are content-addressed (`fragment/en_abc123.pf_fragment`) so they are safe to cache for a long time. Set:

```
Cache-Control: public, max-age=31536000, immutable
```

on `dist/pagefind/fragment/*` and `dist/pagefind/index/*`. The top-level `dist/pagefind/pagefind.js` should have a shorter TTL since it gets re-emitted on every build.
