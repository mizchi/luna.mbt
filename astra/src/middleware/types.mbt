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
}

///|
/// Return a Mars `Handler` that dispatches incoming requests through this
/// middleware. Mount it via `app.all("/*path", mw.handler())` (or any other
/// route shape) so that every URL hits `dispatch` below.
pub fn Middleware::handler(self : Middleware) -> @mars.Handler {
  @mars.handler(fn(ctx) { dispatch(self, ctx) })
}

///|
/// Page URLs known to this middleware. Phase B-1 returns only document
/// URLs; assets are added in Task 10 once the asset crawler lands.
pub fn Middleware::list_urls(self : Middleware) -> Array[String] {
  let urls : Array[String] = []
  for page in self.doc_tree.pages {
    urls.push(page.url_path)
  }
  urls
}
