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
              revalidate=None,
            ),
            // About page (static, no hydration)
            @router.SolRoutes::Page(
              path="/about",
              handler=@router.PageHandler(about),
              title="About",
              meta=[],
              revalidate=None,
            ),
            // Contact form page with contact_form island
            @router.SolRoutes::Page(
              path="/form",
              handler=@router.PageHandler(form_page),
              title="Contact Form",
              meta=[],
              revalidate=None,
            ),
            // WC Counter page - Web Components based island
            @router.SolRoutes::Page(
              path="/wc-counter",
              handler=@router.PageHandler(wc_counter),
              title="WC Counter",
              meta=[],
              revalidate=None,
            ),
            // WC Multiple page - multiple instances of same component
            @router.SolRoutes::Page(
              path="/wc-multiple",
              handler=@router.PageHandler(wc_multiple),
              title="WC Multiple",
              meta=[],
              revalidate=None,
            ),
            // Docs page - catch-all route [...slug]
            @router.SolRoutes::Page(
              path="/docs/[...slug]",
              handler=@router.PageHandler(docs_page),
              title="Documentation",
              meta=[],
              revalidate=None,
            ),
            // Blog page - optional catch-all route [[...path]]
            @router.SolRoutes::Page(
              path="/blog/[[...path]]",
              handler=@router.PageHandler(blog_page),
              title="Blog",
              meta=[],
              revalidate=None,
            ),
            // Middleware test page
            @router.SolRoutes::Page(
              path="/middleware-test",
              handler=@router.PageHandler(middleware_test),
              title="Middleware Test",
              meta=[],
              revalidate=None,
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
            // Middleware test API - returns info about current request
            @router.SolRoutes::Get(
              path="/api/middleware-test",
              handler=@router.ApiHandler(api_middleware_test),
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
/// API handler: middleware test - returns request info
async fn api_middleware_test(_props : @router.PageProps) -> @core.Any {
  @sol.json_obj([
    ("middleware", @core.any("logger >> cors")),
    ("timestamp", @core.any(get_timestamp())),
    ("message", @core.any("Middleware is working! Check CORS headers in response.")),
  ])
}

///|
extern "js" fn get_timestamp() -> String =
  #| () => new Date().toISOString()

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
///| Middleware Test Page

///|

///| Demonstrates middleware functionality with Logger and CORS.

///|
/// Middleware test page - shows middleware information
async fn middleware_test(_props : @router.PageProps) -> @server_dom.ServerNode {
  let content : Array[@luna.Node[Unit]] = [
    h1([text("Middleware Test")]),
    p([text("This page tests middleware functionality.")]),
    div([
      h2([text("Middleware Stack")]),
      ul([
        li([text("Logger - logs requests to console")]),
        li([text("CORS - adds cross-origin headers to API responses")]),
      ]),
    ]),
    div([
      h2([text("Test API Endpoints")]),
      ul([
        li([
          a(href="/api/middleware-test", [text("/api/middleware-test")]),
          text(" - Returns middleware info with CORS headers"),
        ]),
        li([
          a(href="/api/health", [text("/api/health")]),
          text(" - Health check endpoint"),
        ]),
      ]),
    ]),
    div([
      h2([text("Expected Behavior")]),
      ul([
        li([text("Check server console for request logs")]),
        li([
          text("API responses should include Access-Control-Allow-Origin header"),
        ]),
      ]),
    ]),
  ]

  @server_dom.ServerNode::sync(@luna.fragment(content))
}
