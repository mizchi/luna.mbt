///| Route Definitions using SolRoutes

///|

///| This is the single source of truth for all routes.

///| Uses typed handlers instead of string-based component IDs.

///|
/// Application routes - defines all pages and API endpoints
/// Uses Layout to wrap all pages with shared navigation
/// Demonstrates middleware composition with Railway Oriented Programming
pub fn routes() -> Array[@router.SolRoutes] {
  [
    // Apply logger middleware to all routes
    @router.SolRoutes::WithMiddleware(
      middleware=[@mw.logger()],
      children=[
        // Root layout - wraps all pages with navigation
        @router.SolRoutes::Layout(
          segment="",
          layout=root_layout,
          children=[
            // Home page with counter island
            @router.SolRoutes::Page(
              path="/",
              handler=@router.PageHandler(home),
              title="Home",
              meta=[],
            ),
            // About page (static, no hydration)
            @router.SolRoutes::Page(
              path="/about",
              handler=@router.PageHandler(about),
              title="About",
              meta=[],
            ),
            // Contact form page with contact_form island
            @router.SolRoutes::Page(
              path="/form",
              handler=@router.PageHandler(form_page),
              title="Contact Form",
              meta=[],
            ),
            // WC Counter page - Web Components based island
            @router.SolRoutes::Page(
              path="/wc-counter",
              handler=@router.PageHandler(wc_counter),
              title="WC Counter",
              meta=[],
            ),
            // WC Multiple page - multiple instances of same component
            @router.SolRoutes::Page(
              path="/wc-multiple",
              handler=@router.PageHandler(wc_multiple),
              title="WC Multiple",
              meta=[],
            ),
            // Docs page - catch-all route [...slug]
            @router.SolRoutes::Page(
              path="/docs/[...slug]",
              handler=@router.PageHandler(docs_page),
              title="Documentation",
              meta=[],
            ),
            // Blog page - optional catch-all route [[...path]]
            @router.SolRoutes::Page(
              path="/blog/[[...path]]",
              handler=@router.PageHandler(blog_page),
              title="Blog",
              meta=[],
            ),
          ],
        ),
        // API endpoints with CORS middleware
        // Using method-style composition: logger().then(cors())
        @router.SolRoutes::WithMiddleware(
          middleware=[@mw.logger().then(@mw.cors())],
          children=[
            @router.SolRoutes::Get(
              path="/api/health",
              handler=@router.ApiHandler(api_health),
            ),
            // Debug API - test catch-all params
            @router.SolRoutes::Get(
              path="/api/test/[...path]",
              handler=@router.ApiHandler(api_test_catch_all),
            ),
          ],
        ),
      ],
    ),
  ]
}

///|
/// Debug API - returns catch-all params
async fn api_test_catch_all(props : @router.PageProps) -> @core.Any {
  let path = props.params.get_param("path").unwrap_or("(none)")
  let star = props.params.get_param("*").unwrap_or("(none)")
  let all_params = props.params.params
    .map(fn(p) { p.0 + "=" + p.1 })
    .join(",")
  @sol.json_obj([
    ("path", @core.any(path)),
    ("star", @core.any(star)),
    ("all_params", @core.any(all_params)),
  ])
}

///|
/// API handler: health check
async fn api_health(_props : @router.PageProps) -> @core.Any {
  @sol.json_obj([("status", @core.any("ok"))])
}

///|
/// Root HTML template - customize the document structure
// Available placeholders:
// - __LUNA_TITLE__ : Page title
// - __LUNA_PRELOAD__ : Modulepreload tags
// - __LUNA_HEAD__ : Custom head HTML (styles, meta, etc.)
// - __LUNA_MAIN__ : Main content

const ROOT : String =
  #|<!DOCTYPE html>
  #|<html lang="en">
  #|<head>
  #|  <meta charset="UTF-8">
  #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  #|  <title>__LUNA_TITLE__</title>
  #|  __LUNA_PRELOAD__
  #|  __LUNA_HEAD__
  #|</head>
  #|<body>
  #|  <div id="__sol__">__LUNA_MAIN__</div>
  #|</body>
  #|</html>

///|
/// Router configuration
pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
  .with_root_template(ROOT)
  .with_default_head(head())
  .with_loader_url("/static/loader.js")
}
