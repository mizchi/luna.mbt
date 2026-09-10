---
title: Mount on Mars
description: Embed Astra as middleware in an existing Mars server
---

# Mount on Mars

The same `Middleware` instance that `astra build` crawls can be mounted on any
Mars server. This is how you ship documentation alongside a live MoonBit
application from one binary.

> This page is a `.mbt.md` file. Every ` ```mbt check ` block below is compiled
> by `moon check` and executed by `moon test`, so the snippets cannot drift
> away from the API they document.

## Minimal mount

```mbt check
///|
test "mount astra on a Mars server" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  // `to_handler()` turns the server into a request handler. How you then
  // listen is runtime-specific — see the note below.
  let _handler = app.to_handler()
}
```

Mars has no built-in `listen`: `Server::to_handler()` gives you an
`async (Request, Reader, ServerConnection) -> Unit`, and the runtime adapter
drives it. `astra dev` passes that handler to a Node FFI listener
(`astra/src/cli/dev.mbt`); on Cloudflare Workers you would use
`@adapters.cloudflare_handler(app, env)` instead.

`Middleware::handler()` returns a Mars `Handler` that responds to GET on every
page URL the document tree exposes plus every entry in
`Middleware::asset_urls()`. `Middleware::list_urls()` returns the union of
those — that is the same set the build crawler walks.

## Mounting under a path prefix

To embed docs under `/docs/*`, register the middleware on the prefix instead of
`/*`:

```mbt check
///|
test "mount astra under a path prefix" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/docs/*", mw.handler()) // astra-served docs
  let _handler = app.to_handler()
}
```

Configure `base: "/docs/"` in `astra.config.json` so links inside generated
HTML point at the prefixed paths instead of the root.

## What the middleware actually serves

For each request:

1. Look up the URL in the resolved page tree (`docs_dir` walk + i18n fallback).
2. If hit, render the Markdown / MDX through the cached document pipeline and
   return HTML.
3. Otherwise, check the asset list (`/assets/*.css`, `/scripts/*.js`, fonts,
   images). If hit, return the bundled bytes.
4. Otherwise, return 404.

There is no separate static-asset middleware to wire up. Everything astra needs
to render the docs is enumerated by `list_urls()` and served by `handler()`.

## Build parity

`astra build` is a thin loop over the same two methods — no server, no socket:

```mbt check
///|
test "build is a loop over list_urls and render_url" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  for url in mw.list_urls() {
    let res = mw.render_url(url)
    // `astra build` writes `res.body` to `<out>/<url>/index.html`.
    assert_true(res.status > 0)
    assert_true(res.content_type != "")
  }
}
```

This is why dev and build always agree. If you find a divergence, treat it as a
bug — see
[`astra/docs/parity-notes.md`](https://github.com/mizchi/luna.mbt/blob/main/astra/docs/parity-notes.md)
for known gaps (utility CSS extraction, sitemap generation, Cloudflare adapter
manifests).

## Hot reload

`astra dev` watches `docs_dir` and bumps the document tree's revision on
change. The middleware sees the new revision on the next request and
re-renders. There is no MoonBit recompile in the dev path — Markdown changes
are reflected as fast as the renderer runs.
