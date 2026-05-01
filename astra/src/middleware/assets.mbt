// Asset serving for the astra middleware.
//
// Sits in front of the page-dispatch path: if the incoming request URL
// matches one of the static assets exposed by `mizchi/astra/assets`, we
// write the asset body straight to the response (with the right MIME type)
// and return `true` so `dispatch` short-circuits before touching the page
// table. Otherwise, callers fall through to regular page rendering.

///|
/// Try to handle the request as a static asset. Returns `true` when the
/// asset was served (the response has been sent), `false` when the URL is
/// not part of the asset surface and dispatch should continue.
fn try_serve_asset(mw : Middleware, ctx : @mars.Context) -> Bool {
  match @assets.lookup_asset(ctx.path(), mw.config) {
    Some(asset) => {
      // mars's `text` helper sets `Content-Type: text/plain` by default; we
      // override via `set_header` first and rely on `merge_headers`'s rule
      // that user-set headers take precedence over per-helper defaults.
      ctx.set_header("Content-Type", asset.content_type)
      ctx.text(asset.body)
      true
    }
    None => false
  }
}
