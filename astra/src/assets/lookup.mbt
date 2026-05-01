// Asset URL → body lookup. Used by the astra middleware to serve static
// assets (the bundled island loader, Sol's default CSS, the Shiki theme,
// the GitHub-markdown stylesheet) directly from request paths instead of
// requiring a prior `copy_static_assets` build step.
//
// The set of paths recognised here mirrors what `copy_static_assets`
// writes to disk under `<output_dir>/assets/`, so a hot middleware fetch
// and a static-build dump produce equivalent bytes for the same URL.

///|
/// A single asset response: the bytes to write back and the MIME type the
/// middleware should advertise via `Content-Type`. Body is `String` because
/// every recognised asset today is a UTF-8 text resource (JS / CSS).
pub(all) struct Asset {
  body : String
  content_type : String
}

///|
/// Look up a static asset by request path. Returns `None` for paths that
/// are not part of astra's built-in asset surface; callers fall through to
/// regular page dispatch in that case.
///
/// This is the public counterpart to `copy_static_assets` in the render
/// package: serving the same URL via this function and via a static build
/// must yield equivalent bytes for the same SSG config.
pub fn lookup_asset(path : String) -> Asset? {
  match path {
    "/assets/loader.js" =>
      Some({ body: get_island_loader_js(), content_type: js_content_type() })
    "/assets/style.css" =>
      Some({
        body: get_main_css(),
        content_type: css_content_type(),
      })
    "/assets/markdown.css" | "/assets/github-markdown.css" =>
      Some({
        body: get_github_markdown_css(),
        content_type: css_content_type(),
      })
    _ => None
  }
}

///|
/// URLs every `lookup_asset` recognises. Used by `Middleware::list_urls`
/// so the build crawler can dump assets alongside pages, and by parity
/// tests asserting the dev server and the static dump cover the same
/// surface.
pub fn list_asset_urls() -> Array[String] {
  ["/assets/loader.js", "/assets/style.css", "/assets/github-markdown.css"]
}

///|
fn js_content_type() -> String {
  "application/javascript; charset=utf-8"
}

///|
fn css_content_type() -> String {
  "text/css; charset=utf-8"
}
