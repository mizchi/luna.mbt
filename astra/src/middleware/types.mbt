// Middleware types: a `Middleware` value bundles the SSG config, the
// scanned document tree, and exposes both a Mars `Handler` (for serving
// HTTP requests) and a `list_urls` accessor (used by the static-build
// crawler in Task 10).

///|
pub(all) struct Middleware {
  config : @astra.SsgConfig
  cwd : String
  pages : Array[@astra.PageMeta]
  doc_tree : @astra.DocumentTree
  // When true, the asset path runs CSS through `minify_css` so the
  // middleware-served body byte-matches the static-build output. Defaults
  // to `false` (dev mode); `build_to_disk` flips it on.
  minify_css : Bool
  // Optional Shiki highlighter for code-block syntax highlighting. None
  // skips the highlighter pass entirely (the dev-server default, since
  // initialising it costs startup time and per-request highlighting is
  // expensive). `build_to_disk` populates it so static dumps match the
  // SSG-style rendered output byte-for-byte (modulo deferred items).
  highlighter : @shiki.Highlighter?
}

///|
/// Return a Mars `Handler` that dispatches incoming requests through this
/// middleware. Mount it via `app.all("/*path", mw.handler())` (or any other
/// route shape) so that every URL hits `dispatch` below.
pub fn Middleware::handler(self : Middleware) -> @mars.Handler {
  @mars.handler(fn(ctx) { dispatch(self, ctx) })
}

///|
/// Page URLs and static asset URLs known to this middleware. The build
/// crawler walks this list to dump the dev-server output to disk; asset
/// URLs come from `@assets.list_asset_urls()` so the static dump stays
/// in lockstep with what `render_url` resolves to an asset.
pub fn Middleware::list_urls(self : Middleware) -> Array[String] {
  let urls : Array[String] = []
  for page in self.doc_tree.pages {
    urls.push(page.url_path)
  }
  for asset_url in @assets.list_asset_urls() {
    urls.push(asset_url)
  }
  urls
}

///|
/// Just the static-asset URLs this middleware serves. Exposed so the
/// build crawler can decide page vs asset routing by membership rather
/// than a fragile dot-in-segment heuristic (a page URL like
/// `/release/v1.0/` would otherwise be misclassified as an asset).
pub fn Middleware::asset_urls(_self : Middleware) -> Array[String] {
  @assets.list_asset_urls()
}
