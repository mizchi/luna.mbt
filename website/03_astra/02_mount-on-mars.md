---
title: Mount on Mars
description: Embed Astra as middleware in an existing Mars server
---

# Mount on Mars

The same `Middleware` instance that `astra build` crawls can be mounted on any Mars server. This is how you ship documentation alongside a live MoonBit application from one binary.

## Minimal mount

```moonbit
import "mizchi/astra" as astra
import "mizchi/astra/middleware" as middleware
import "mizchi/mars" as mars

async fn main {
  let cfg = @astra.SsgConfig::default()
  let mw  = @middleware.create(cfg, cwd=".")

  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  app.listen(port=3000)
}
```

`Middleware::handler()` returns a Mars `Handler` that responds to GET on every page URL the document tree exposes plus every entry in `@assets.list_asset_urls()`. `Middleware::list_urls()` returns the union of those — that is the same set the build crawler walks.

## Mounting under a path prefix

To embed docs under `/docs/*`, use Mars's path prefix routing instead of `/*`:

```moonbit
let app = @mars.Server::new()
app.all("/api/*", api_handler())          // your application
app.all("/docs/*", mw.handler())          // astra-served docs
app.listen(port=3000)
```

Configure `base: "/docs/"` in `astra.config.json` so links inside generated HTML point at the prefixed paths instead of the root.

## What the middleware actually serves

For each request:

1. Look up the URL in the resolved page tree (`docs_dir` walk + i18n fallback).
2. If hit, render the Markdown / MDX through the cached document pipeline and return HTML.
3. Otherwise, check the asset list (`/assets/*.css`, `/scripts/*.js`, fonts, images). If hit, return the bundled bytes.
4. Otherwise, return 404.

There is no separate static-asset middleware to wire up. Everything astra needs to render the docs is enumerated by `list_urls()` and served by `handler()`.

## Build parity

`astra build` is a thin loop:

```moonbit
for url in mw.list_urls() {
  let response = @testing.invoke(mw.handler(), path=url)
  write_to_disk(out, url, response.body)
}
```

This is why dev and build always agree. If you find a divergence, treat it as a bug — see [`astra/docs/parity-notes.md`](https://github.com/mizchi/luna.mbt/blob/main/astra/docs/parity-notes.md) for known gaps (utility CSS extraction, sitemap generation, Cloudflare adapter manifests).

## Hot reload

`astra dev` watches `docs_dir` and bumps the document tree's revision on change. The middleware sees the new revision on the next request and re-renders. There is no MoonBit recompile in the dev path — Markdown changes are reflected as fast as the renderer runs.
