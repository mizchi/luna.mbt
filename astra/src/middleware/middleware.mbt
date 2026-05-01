// Public middleware entry point. `create` scans the docs directory through
// the existing sol/routes scanner, builds an astra `DocumentTree`, and
// returns a `Middleware` value ready to be mounted on a Mars server.

///|
/// Build a `Middleware` from an SSG config and a working directory.
///
/// `cwd` defaults to "." so callers can use the result directly with the
/// process working directory; pass an absolute path for deterministic
/// crawling in tests / build pipelines.
pub fn create(config : @astra.SsgConfig, cwd~ : String = ".") -> Middleware {
  let scanned = @routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )
  let (pages, _unresolved) = @routes.resolve_duplicate_pages(scanned)
  let doc_tree = @tree.build_document_tree(config, pages, cwd)
  { config, cwd, pages, doc_tree }
}

///|
/// Async dispatch: rejects non-GET/HEAD methods with 405, attempts to
/// resolve the request path against the document tree, and renders a
/// minimal HTML response on hit. Asset serving and full markdown→HTML
/// rendering arrive in Task 9 / Task 10; for now the handler proves the
/// wiring works end-to-end against a real Mars server.
fn dispatch(mw : Middleware, ctx : @mars.Context) -> Unit {
  match ctx.meth() {
    @http.RequestMethod::Get | @http.RequestMethod::Head => ()
    _ => {
      ctx.text("Method Not Allowed", status=405)
      return
    }
  }
  let path = normalize_path(ctx.path())
  match find_page(mw.doc_tree, path) {
    Some(page) => {
      let html = render_page(mw.config, mw.cwd, page)
      ctx.html(html)
    }
    None => ctx.text("Not Found", status=404)
  }
}

///|
/// Look up a page in the document tree by URL path. Returns `None` when
/// the path does not correspond to any scanned page.
fn find_page(
  tree : @astra.DocumentTree,
  path : String,
) -> @astra.PageInfo? {
  tree.get_page_by_url(path)
}

///|
/// Render a single page to HTML. Phase B-1 produces a minimal placeholder
/// that wraps the page title and URL; the full markdown→HTML pipeline
/// (markdown parse, syntax highlighting, theme HTML) lands in a later
/// task once the render package is exposed via the public surface.
fn render_page(
  _config : @astra.SsgConfig,
  _cwd : String,
  page : @astra.PageInfo,
) -> String {
  let title = if page.title.is_empty() { page.url_path } else { page.title }
  "<!doctype html><html><head><title>\{title}</title></head>" +
  "<body><h1>\{title}</h1><p>" +
  page.url_path +
  "</p></body></html>"
}

///|
/// Normalize an incoming URL path so it lines up with the page index in
/// the document tree. Trailing-slash URLs are mapped to the directory's
/// `index` entry.
fn normalize_path(p : String) -> String {
  if p.has_suffix("/") {
    p + "index"
  } else {
    p
  }
}
