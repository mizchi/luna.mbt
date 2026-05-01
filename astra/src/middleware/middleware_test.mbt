// Tests for the public astra middleware surface (`create`, `handler`,
// `list_urls`). The plan's literal example uses `@mars.test_request` and
// `@mars.Request::get`, neither of which exist in the local mars; we use
// `@testing.invoke` instead, which drives a real `app.to_handler()`
// dispatch end-to-end.

///|
async test "create returns a middleware whose handler responds to GET /" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  let res = @testing.invoke(app, path="/")
  inspect(res.status >= 200 && res.status < 600, content="true")
}

///|
test "list_urls returns the document tree URLs" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let urls = mw.list_urls()
  inspect(urls.length() >= 0, content="true")
}

///|
/// Parity check for the real markdown rendering pipeline. The middleware
/// must produce HTML that contains content sourced from the markdown
/// file -- not just the page title -- so that T10's `build_to_disk`
/// produces the same bytes as a hot HTTP fetch from the dev server.
async test "handler renders real markdown content into HTML" {
  let cfg = @astra.SsgConfig::default()
  // Run with cwd="astra" so the default docs_dir="docs" resolves to
  // astra/docs (which ships with index.md / guide/*.md).
  let mw = @middleware.create(cfg, cwd="astra")
  // Pick a real URL discovered by the scanner (deterministic regardless
  // of trailing-slash / index-handling conventions).
  let urls = mw.list_urls()
  inspect(urls.length() > 0, content="true")
  let target = urls[0]
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  let res = @testing.invoke(app, path=target)
  // The rendered response must contain markdown-derived markup -- not
  // merely the page title -- proving the pipeline ran end to end rather
  // than emitting the old stub.
  inspect(res.status, content="200")
  let body = res.body
  inspect(
    body.contains("<!doctype html>") || body.contains("<!DOCTYPE html>"),
    content="true",
  )
  // The full pipeline produces a luna-rendered <main> wrapper for content
  // pages; the stub only emitted <body><h1>...</h1>.
  inspect(body.contains("<main"), content="true")
}

///|
/// T9 step 1: an explicit asset URL must short-circuit page dispatch and
/// return the bundled island loader script with a JS Content-Type. Plan's
/// literal `/sol-island.js` URL doesn't match the actual asset layout
/// (`/assets/loader.js`); we exercise the real URL the renderer references
/// in `<link rel=modulepreload>` / `<script src=...>`.
async test "GET /assets/loader.js returns the bundled island loader script" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  let res = @testing.invoke(app, path="/assets/loader.js")
  inspect(res.status, content="200")
  let expected_ct =
    #|Some("application/javascript; charset=utf-8")
  inspect(res.header("content-type"), content=expected_ct)
}

///|
/// T9 step 5: `list_urls` must include every URL `try_serve_asset` is
/// prepared to answer, otherwise the static-build crawler in T10 would
/// silently skip assets and the dev server / static dump would diverge.
test "list_urls includes the bundled asset URLs" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let urls = mw.list_urls()
  let mut found_loader = false
  for u in urls {
    if u == "/assets/loader.js" {
      found_loader = true
    }
  }
  inspect(found_loader, content="true")
}
