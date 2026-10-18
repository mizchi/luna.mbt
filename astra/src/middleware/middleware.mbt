// Public middleware entry point. `create` scans the docs directory through
// the existing sol/routes scanner, builds an astra `DocumentTree`, and
// returns a `Middleware` value ready to be mounted on a Mars server.

///|
/// Build a `Middleware` from an SSG config and a working directory.
///
/// `cwd` defaults to "." so callers can use the result directly with the
/// process working directory; pass an absolute path for deterministic
/// crawling in tests / build pipelines.
pub fn create(
  config : @astra.SsgConfig,
  cwd? : String = ".",
  minify_css? : Bool = false,
  highlighter? : @shiki.Highlighter? = None,
) -> Middleware {
  let scanned = @routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )
  let (pages, _unresolved) = @routes.resolve_duplicate_pages(scanned)
  let doc_tree = @tree.build_document_tree(config, pages, cwd)
  { config, cwd, pages, doc_tree, minify_css, highlighter, }
}

///|
/// A rendered HTTP-ish response. Returned by `Middleware::render_url`
/// so callers (in particular the static-build crawler) can produce the
/// same bytes as `dispatch` without instantiating a Mars `Server`.
pub(all) struct RenderedResponse {
  status : Int
  body : String
  content_type : String
}

///|
/// Render `url` directly through the middleware's render pipeline,
/// without going through a Mars `Server` or `@testing.invoke`. Asset
/// URLs win first (matching `dispatch`'s ordering); page URLs flow
/// through `render_page`; unknown URLs return a 404 with a plain-text
/// body. Component pages require `render_url_async`; this synchronous
/// entry point returns a render error for them.
pub fn Middleware::render_url(
  self : Middleware,
  url : String,
) -> RenderedResponse {
  match @assets.lookup_asset(url, self.config, minify=self.minify_css) {
    Some(asset) =>
      { status: 200, body: asset.body, content_type: asset.content_type, }
    None => {
      let path = normalize_path(url, self.config.trailing_slash)
      match find_page_meta(self.pages, path) {
        Some(page) => page_response(render_page(self, page))
        None =>
          {
            status: 404,
            body: "Not Found",
            content_type: "text/plain; charset=utf-8",
          }
      }
    }
  }
}

///|
/// Reject non-GET/HEAD methods with 405; otherwise delegate to
/// `render_url_async` and copy the rendered status / body / content-type onto
/// the Mars `Context`. `render_url_async` already handles asset-first
/// resolution and the page-vs-404 split, so this function stays thin —
/// the same body bytes the SSG build crawler writes to disk are what
/// the Mars handler returns over the wire.
async fn dispatch(mw : Middleware, ctx : @mars.Context) -> Unit {
  match ctx.meth() {
    @http.RequestMethod::Get | @http.RequestMethod::Head => ()
    _ => {
      ctx.text("Method Not Allowed", status=405)
      return
    }
  }
  let res = mw.render_url_async(ctx.path())
  // `set_header` before `text` so the explicit Content-Type wins over
  // mars's text-helper default (`text/plain`). The same rule applied in
  // the previous asset path; it now covers pages too.
  let content_type = res.content_type
    .replace_all(old="\r", new="")
    .replace_all(old="\n", new="")
  ctx.set_header("Content-Type", content_type)
  ctx.text(res.body, status=res.status)
}

///|
/// Render a URL with component SSR support. The synchronous API remains
/// available for callers rendering text pages and built-in assets.
pub async fn Middleware::render_url_async(
  self : Middleware,
  url : String,
) -> RenderedResponse {
  if @assets.lookup_asset(url, self.config, minify=self.minify_css)
    is Some(asset) {
    return { status: 200, body: asset.body, content_type: asset.content_type, }
  }
  let path = normalize_path(url, self.config.trailing_slash)
  guard find_page_meta(self.pages, path) is Some(page) else {
    return self.render_url(url)
  }
  let build_ctx : @astra.BuildContext = {
    config: self.config,
    pages: self.pages,
    sidebar: [],
    cwd: self.cwd,
    doc_tree: Some(self.doc_tree),
    is_dev: false,
  }
  page_response(
    @render.render_page_html_async(build_ctx, page, self.highlighter),
  )
}

///|
/// Look up a page's `PageMeta` (the renderer-friendly representation) by
/// URL path. Returns `None` when the path does not correspond to any
/// scanned page.
fn find_page_meta(
  pages : Array[@astra.PageMeta],
  path : String,
) -> @astra.PageMeta? {
  for page in pages {
    if page.url_path == path {
      return Some(page)
    }
  }
  None
}

///|
/// Render a single page to HTML by invoking the shared `render_page_html`
/// pipeline (markdown parse → VNode tree → string → optional syntax
/// highlighting). Errors are converted to HTTP 500 by `page_response`.
fn render_page(
  mw : Middleware,
  page : @astra.PageMeta,
) -> Result[String, String] {
  let build_ctx : @astra.BuildContext = {
    config: mw.config,
    pages: mw.pages,
    sidebar: [],
    cwd: mw.cwd,
    doc_tree: Some(mw.doc_tree),
    is_dev: false,
  }
  @render.render_page_html(build_ctx, page, mw.highlighter)
}

///|
/// Minimal HTML escape for the runtime error page. Not used for rendered
/// markdown content (that goes through the full luna VNode renderer).
fn escape_html(s : String) -> String {
  let mut out = ""
  for ch in s {
    out = out +
      (match ch {
        '&' => "&amp;"
        '<' => "&lt;"
        '>' => "&gt;"
        '"' => "&quot;"
        _ => ch.to_string()
      })
  }
  out
}

///|
/// Normalize an incoming URL path so it lines up with the URLs produced
/// by the routes scanner. The scanner's `trailing_slash` option controls
/// whether scanned page URLs end in `/`; the runtime middleware mirrors
/// that convention here so request paths match `page.url_path`.
fn normalize_path(p : String, trailing_slash : Bool) -> String {
  if trailing_slash {
    if p.is_empty() {
      "/"
    } else if p.has_suffix("/") {
      p
    } else {
      p + "/"
    }
  } else if p.length() > 1 && p.has_suffix("/") {
    p[:p.length() - 1].to_owned()
  } else if p.is_empty() {
    "/"
  } else {
    p
  }
}

///|
fn page_response(result : Result[String, String]) -> RenderedResponse {
  match result {
    Ok(html) =>
      { status: 200, body: html, content_type: "text/html; charset=utf-8", }
    Err(e) => {
      let body = "<!doctype html><html><head><title>Render error</title></head>" +
        "<body><h1>Render error</h1><pre>" +
        escape_html(e) +
        "</pre></body></html>"
      { status: 500, body, content_type: "text/html; charset=utf-8", }
    }
  }
}
