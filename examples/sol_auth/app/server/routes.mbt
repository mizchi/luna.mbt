///| Route Definitions using SolRoutes

///|

///| This is the single source of truth for all routes.

///| Uses typed handlers instead of string-based component IDs.

///|
/// Application routes - defines all pages and API endpoints
/// Uses Layout to wrap all pages with shared navigation
/// Demonstrates middleware composition with Railway Oriented Programming
pub fn routes() -> Array[@sol.SolRoutes] {
  [
    // Apply security headers and logger middleware to all routes
    @sol.with_mw(
      [@mw.security_headers_relaxed(), @mw.logger()],
      [
        // Root layout - wraps all pages with navigation
        @sol.wrap("", root_layout, [
          // Home page with counter island
          @sol.route("/", home, title="Home"),
          // About page (static, no hydration)
          @sol.route("/about", about, title="About"),
          // Contact form page with contact_form island
          @sol.route("/form", form_page, title="Contact Form"),
          // WC Counter page - Web Components based island
          @sol.route("/wc-counter", wc_counter, title="WC Counter"),
          // WC Multiple page - multiple instances of same component
          @sol.route("/wc-multiple", wc_multiple, title="WC Multiple"),
          // Docs page - catch-all route [...slug]
          @sol.route("/docs/[...slug]", docs_page, title="Documentation"),
          // Blog page - optional catch-all route [[...path]]
          @sol.route("/blog/[[...path]]", blog_page, title="Blog"),
          // Middleware test page
          @sol.route("/middleware-test", middleware_test, title="Middleware Test"),
          // Admin section - nested layout example
          @sol.wrap("/admin", admin_layout, [
            @sol.route("/", admin_home, title="Admin Dashboard"),
            @sol.route("/settings", admin_settings, title="Admin Settings"),
            @sol.route("/users", admin_users, title="Admin Users"),
          ]),
          // ================================================================
          // Authentication pages (requires dev-auth.ts server)
          // ================================================================
          @sol.route("/login", login_page, title="Login"),
          @sol.route("/profile", profile_page, title="Profile"),
          // ================================================================
          // User Namespace (/@user_id/page_id) - ISR enabled
          // ================================================================
          @sol.route("/@[user_id]", user_profile, title="User Profile", revalidate=Some(60)),
          @sol.route("/@[user_id]/[page_id]", user_page, title="User Page", revalidate=Some(60)),
        ]),
        // API endpoints with CORS middleware
        // Using method-style composition: logger().then(cors())
        @sol.with_mw(
          [@mw.logger().then(@mw.cors())],
          [
            @sol.api_get("/api/health", api_health),
            // Middleware test API - returns info about current request
            @sol.api_get("/api/middleware-test", api_middleware_test),
            // Debug API - test catch-all params
            @sol.api_get("/api/test/[...path]", api_test_catch_all),
          ],
        ),
      ],
    ),
  ]
}

///|
/// Debug API - returns catch-all params
async fn api_test_catch_all(props : @sol.PageProps) -> Json {
  let path = props.params.get_param("path").unwrap_or("(none)")
  let star = props.params.get_param("*").unwrap_or("(none)")
  let all_params = props.params.params.map(fn(p) { p.0 + "=" + p.1 }).join(",")
  @sol.ok([
    ("path", path.to_json()),
    ("star", star.to_json()),
    ("all_params", all_params.to_json()),
  ]).to_json()
}

///|
/// API handler: health check
async fn api_health(_props : @sol.PageProps) -> Json {
  @sol.ok([("status", "ok".to_json())]).to_json()
}

// ============================================================================
// Server Actions
// ============================================================================

///|
/// Contact form submission handler
/// Supports both JSON (JavaScript) and form-urlencoded (no-JS) submissions
let submit_contact_handler : @action.ActionHandler = @action.ActionHandler(async fn(
  ctx,
) {
  // Check Content-Type to determine how to parse
  let content_type = ctx.get_header("Content-Type").unwrap_or("")
  let is_form = content_type.contains("application/x-www-form-urlencoded")

  // Parse body based on content type
  let body = ctx.body
  let (name, email) = if is_form {
    // Parse URL-encoded form data
    let data = parse_form_urlencoded(body)
    (get_field(data, "name"), get_field(data, "email"))
  } else {
    // Parse JSON
    let data : @core.Any = parse_json(body)
    (get_field(data, "name"), get_field(data, "email"))
  }

  // Validate
  if name == "" {
    return @action.ActionResult::bad_request("Name is required")
  }
  if email == "" {
    return @action.ActionResult::bad_request("Email is required")
  }
  if !(email.contains("@")) {
    return @action.ActionResult::bad_request("Invalid email format")
  }

  // In a real app, you would save to database here
  // For demo, just return success

  // Different response for form vs AJAX
  if is_form {
    // Non-JS form submission: HTTP redirect to home page (302)
    @action.ActionResult::http_redirect("/")
  } else {
    // AJAX submission: return JSON
    @action.ActionResult::ok(
      @sol.json_obj([
        ("success", @core.any(true)),
        ("message", @core.any("Form submitted successfully!")),
        (
          "data",
          @sol.json_obj([("name", @core.any(name)), ("email", @core.any(email))]),
        ),
      ]),
    )
  }
})

///|
extern "js" fn parse_json(s : String) -> @core.Any =
  #| (s) => { try { return JSON.parse(s); } catch { return {}; } }

///|
extern "js" fn parse_form_urlencoded(s : String) -> @core.Any =
  #| (s) => Object.fromEntries(new URLSearchParams(s))

///|
extern "js" fn get_field(obj : @core.Any, field : String) -> String =
  #| (obj, field) => obj[field] || ""

///|
/// Create action registry for the application
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=[
    "http://localhost:3000", "http://localhost:3457", "http://localhost:9123",
  ]).register(
    @action.ActionDef::new("submit-contact", submit_contact_handler).with_require_json(
      false,
    ), // Allow form-urlencoded for progressive enhancement
  )
}

///|
/// API handler: middleware test - returns request info
async fn api_middleware_test(_props : @sol.PageProps) -> Json {
  @sol.ok([
    ("middleware", "logger >> cors".to_json()),
    ("timestamp", get_timestamp().to_json()),
    (
      "message",
      "Middleware is working! Check CORS headers in response.".to_json(),
    ),
  ]).to_json()
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
pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
  .with_root_template(ROOT)
  .with_default_head(head())
}

///|
/// Middleware Test Page
/// Demonstrates middleware functionality with Logger and CORS.
async fn middleware_test(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content : Array[@luna.Node[Unit, String]] = [
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
          text(
            "API responses should include Access-Control-Allow-Origin header",
          ),
        ]),
      ]),
    ]),
  ]
  @sol.nodes(content)
}
