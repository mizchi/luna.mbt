///| Route Definitions using SolRoutes

///|

///| This is the single source of truth for all routes.

///| Uses typed handlers instead of string-based component IDs.

///|
/// Application routes - defines all pages and API endpoints
/// Uses Layout to wrap all pages with shared navigation
/// Demonstrates middleware composition with Railway Oriented Programming
pub fn routes() -> Array[@sol.SolRoutes] {
  let bench_mode = is_bench_mode()
  let global_middleware = if bench_mode {
    [@mw.security_headers_relaxed()]
  } else {
    [@mw.security_headers_relaxed(), @mw.logger()]
  }
  let api_middleware = if bench_mode {
    [@mw.cors()]
  } else {
    [@mw.logger().then(@mw.cors())]
  }
  [
    // Apply security headers and logger middleware to all routes
    @sol.with_mw(global_middleware, [
      // Root layout - wraps all pages with navigation
      @sol.wrap("", @layout.root_layout, [
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
      ]),
      // API endpoints with CORS middleware
      // Using method-style composition: logger().then(cors())
      @sol.with_mw(api_middleware, [
        @sol.api_get("/api/health", api_health),
        // Benchmark API - lightweight endpoint for k6 runs
        @sol.api_get("/api/bench/ping", api_bench_ping),
        // Benchmark API - catch-all endpoint for routing benchmarks
        @sol.api_get("/api/bench/test/[...path]", api_bench_catch_all),
        // Middleware test API - returns info about current request
        @sol.api_get("/api/middleware-test", api_middleware_test),
        // Debug API - test catch-all params
        @sol.api_get("/api/test/[...path]", api_test_catch_all),
      ]),
    ]),
  ]
}

///|
extern "js" fn is_bench_mode() -> Bool =
  #| () => {
  #|   try {
  #|     return globalThis?.process?.env?.SOL_BENCH_MODE === "1"
  #|   } catch {
  #|     return false
  #|   }
  #| }

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
  .with_default_head(@layout.head())
}

// =============================================================================
// Page Handlers
// =============================================================================

///|
/// Home page - with counter client component (async server component)
async fn home(_props : @sol.PageProps) -> @server_dom.ServerNode {
  // Return an async ServerNode that can perform data fetching
  @server_dom.ServerNode::async_(fn() {
    // Generate a random number on the server side
    // This demonstrates async data fetching capability
    let server_random = generate_random_int(1, 1000)

    // Create props using generated types
    let counter_props : @types.CounterProps = { initial_count: server_random }
    let content = [
      h1([text("Welcome to Sol")]),
      p([text("A SSR-first web framework for MoonBit")]),
      p([
        text("Server-generated random number: "),
        span(style="font-weight: bold; color: #0066cc;", [
          text(server_random.to_string()),
        ]),
      ]),
      p(style="color: #666; font-size: 0.9em;", [
        text("(Refresh to see a new random number from the server)"),
      ]),
      @server_dom.client(@types.counter(counter_props), [
        div(class="counter", [
          span(class="count-display", [
            text(counter_props.initial_count.to_string()),
          ]),
          div(class="buttons", [
            button(class="dec", [text("-")]),
            button(class="inc", [text("+")]),
          ]),
        ]),
      ]),
    ]

    // Return content only - layout is applied by SolRoutes::Layout
    @luna.fragment(content)
  })
}

///|
/// Generate a random integer between min and max (inclusive)
fn generate_random_int(min : Int, max : Int) -> Int {
  let random = ffi_math_random()
  min + (random * (max - min + 1).to_double()).to_int()
}

///|
/// FFI for Math.random()
extern "js" fn ffi_math_random() -> Double =
  #| () => Math.random()

///|
/// About page - static content (sync server component)
async fn about(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("About")]),
    p([text("Built with MoonBit and Sol framework.")]),
    // luna/x/components — typed SSR-compatible UI components
    @alert_ui.alert(
      @alert_ui.Success,
      title="Type-Safe SSR",
      description="This alert is rendered on the server using luna/x/components with generic Node[E, String].",
    ),
    @alert_ui.alert(
      @alert_ui.Warning,
      title="Island Architecture",
      description="Interactive components hydrate on the client. Static components like this alert are SSR-only.",
    ),
  ]
  @sol.nodes(content)
}

///|
/// Contact form page - with contact_form client component (sync server component)
async fn form_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  // Create props using generated types
  // Use Server Action endpoint instead of API endpoint
  let form_props : @types.ContactFormProps = {
    initial_name: "",
    initial_email: "",
  }
  let content = [
    h1([text("Contact Form")]),
    p([text("A demo of data binding and form submission")]),
    @server_dom.client(@types.contact_form(form_props), [
      // SSR placeholder matching client component structure
      form(
        class="contact-form",
        action=@action.action_url(@types.action_submit_contact()),
        http_method="POST",
        [
          div(class="form-group", [
            label(for_="name", [text("Name:")]),
            input(
              type_="text",
              id="name",
              name="name",
              placeholder="Enter your name",
              value=form_props.initial_name,
            ),
          ]),
          div(class="form-group", [
            label(for_="email", [text("Email:")]),
            input(
              type_="email",
              id="email",
              name="email",
              placeholder="Enter your email",
              value=form_props.initial_email,
            ),
          ]),
          div(class="form-preview", [
            span([text("Preview: ")]),
            span(class="preview-name", [text(form_props.initial_name)]),
            span([text(" <")]),
            span(class="preview-email", [text(form_props.initial_email)]),
            span([text(">")]),
          ]),
          div(class="form-actions", [
            button(attrs=[("type", @luna.attr_static("submit"))], [
              text("Submit"),
            ]),
          ]),
          div(
            class="form-result",
            attrs=[("data-testid", @luna.attr_static("form-result"))],
            [text("")],
          ),
        ],
      ),
    ]),
  ]

  // Return content only - layout is applied by SolRoutes::Layout
  @sol.nodes(content)
}

///|
/// WC Counter Page Server Component
/// Uses wc_island() to embed a Web Components based counter.
/// Demonstrates Declarative Shadow DOM SSR with unified hydration.
/// CSS is defined in app/client/wc_counter.mbt and shared between SSR and hydration.
async fn wc_counter(_props : @sol.PageProps) -> @server_dom.ServerNode {
  // Create props using WcCounterProps from client module
  let counter_props : @client.WcCounterProps = { initial_count: 0 }
  let state_json = counter_props.to_json().stringify()

  // CSS is imported from client module - shared between SSR and hydration
  let counter_styles = @client.wc_counter_css
  let content = [
    h1([text("Web Components Counter")]),
    p([text("This counter uses Declarative Shadow DOM for SSR.")]),
    p([
      text(
        "CSS is defined in app/client/wc_counter.mbt and shared between SSR and hydration.",
      ),
    ]),
    p([
      text(
        "Inspect the element to see <template shadowrootmode=\"open\"> with <style>.",
      ),
    ]),
    // WcIsland with Declarative Shadow DOM
    // Uses wc_counter.js generated from app/client/wc_counter.mbt
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js", // WC-specific component
      [
        div(class="counter", [
          span(class="count-display", [
            text(counter_props.initial_count.to_string()),
          ]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=counter_styles,
      state=state_json,
      trigger=@luna.TriggerType::Load,
    ),
    h2([text("How it works")]),
    p([
      text(
        "The WcIsland generates a custom element with Declarative Shadow DOM:",
      ),
    ]),
    div(
      class="code-block",
      style="background: #f5f5f5; padding: 1rem; border-radius: 4px; font-family: monospace; white-space: pre; overflow-x: auto;",
      [
        text("<wc-counter data-wc-url=\"...\" data-state=\"...\">\\n"),
        text("  <template shadowrootmode=\"open\">\\n"),
        text("    <style>:host { ... }</style>\\n"),
        text("    <div class=\"counter\">...</div>\\n"),
        text("  </template>\\n"),
        text("</wc-counter>"),
      ],
    ),
  ]

  // Return content only - layout is applied by SolRoutes::Layout
  @sol.nodes(content)
}

///|
fn docs_links_section() -> @luna.Node[Unit, String] {
  div([
    h2([text("Available Docs")]),
    ul([
      li([sol_link(href="/docs/intro", [text("Introduction")])]),
      li([sol_link(href="/docs/getting-started", [text("Getting Started")])]),
      li([sol_link(href="/docs/api/overview", [text("API Overview")])]),
    ]),
  ])
}

///|
fn blog_recent_posts_section() -> @luna.Node[Unit, String] {
  div([
    h2([text("Recent Posts")]),
    ul([
      li([sol_link(href="/blog/hello-world", [text("Hello World")])]),
      li([sol_link(href="/blog/moonbit-guide", [text("MoonBit Guide")])]),
      li([sol_link(href="/blog/2024/recap", [text("2024 Recap")])]),
    ]),
  ])
}

///|
/// WC Multiple page - demonstrates multiple instances of the same Web Component
async fn wc_multiple(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("Multiple WC Counters")]),
    p([text("Multiple instances of the same Web Component on one page.")]),
    // Multiple instances with different initial values
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js",
      [
        div(class="counter", [
          span(class="count-display", [text("0")]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=@client.wc_counter_css,
      state="{\"initial_count\":0}",
      trigger=@luna.TriggerType::Load,
    ),
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js",
      [
        div(class="counter", [
          span(class="count-display", [text("10")]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=@client.wc_counter_css,
      state="{\"initial_count\":10}",
      trigger=@luna.TriggerType::Load,
    ),
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js",
      [
        div(class="counter", [
          span(class="count-display", [text("100")]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=@client.wc_counter_css,
      state="{\"initial_count\":100}",
      trigger=@luna.TriggerType::Load,
    ),
  ]
  @sol.nodes(content)
}

///|
/// Docs page - catch-all route handler for /docs/[...slug]
async fn docs_page(props : @sol.PageProps) -> @server_dom.ServerNode {
  let slug = match @types.params_docs_slug(props) {
    Ok(p) => p.slug
    Err(_) => "index"
  }
  let content = [
    h1([text("Documentation")]),
    p([text("Current path: /docs/" + slug)]),
    docs_links_section(),
  ]
  @sol.nodes(content)
}

///|
/// Blog page - optional catch-all route handler for /blog/[[...path]]
async fn blog_page(props : @sol.PageProps) -> @server_dom.ServerNode {
  let path = match @types.params_blog_path(props) {
    Ok(p) => p.path.unwrap_or("")
    Err(_) => ""
  }
  let title = if path == "" { "Blog Home" } else { "Blog: " + path }
  let content = [
    h1([text(title)]),
    p([
      text(if path == "" { "Welcome to the blog!" } else { "Viewing: " + path }),
    ]),
    blog_recent_posts_section(),
  ]
  @sol.nodes(content)
}

///|
/// Admin layout - wraps admin pages with sidebar navigation
pub fn admin_layout(
  _props : @sol.PageProps,
  content : @server_dom.ServerNode,
) -> @server_dom.ServerNode raise Error {
  @server_dom.ServerNode::async_(async fn() {
    let inner = content.resolve()
    div(class="admin-container", [
      div(class="admin-sidebar", [
        h3([text("Admin")]),
        ul([
          li([sol_link(href="/admin", [text("Dashboard")])]),
          li([sol_link(href="/admin/settings", [text("Settings")])]),
          li([sol_link(href="/admin/users", [text("Users")])]),
        ]),
      ]),
      div(class="admin-content", [inner]),
    ])
  })
}

///|
/// Admin home page - dashboard
async fn admin_home(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("Admin Dashboard")]),
    p([text("Welcome to the admin panel.")]),
    div(class="admin-stats", [
      div(class="stat-card", [
        h4([text("Users")]),
        div(class="stat-value", [text("42")]),
      ]),
      div(class="stat-card", [
        h4([text("Posts")]),
        div(class="stat-value", [text("128")]),
      ]),
      div(class="stat-card", [
        h4([text("Views")]),
        div(class="stat-value", [text("1.2k")]),
      ]),
    ]),
  ]
  @sol.nodes(content)
}

///|
/// Admin settings page
async fn admin_settings(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("Admin Settings")]),
    div(class="settings-section", [
      div(class="setting-item", [
        label(for_="site-name", [text("Site Name")]),
        input(type_="text", id="site-name", value="Sol App"),
      ]),
      div(class="setting-item", [
        label(for_="contact-email", [text("Contact Email")]),
        input(type_="email", id="contact-email", value="admin@example.com"),
      ]),
    ]),
  ]
  @sol.nodes(content)
}

///|
/// Admin users page
async fn admin_users(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("User Management")]),
    div(class="users-list", [
      div(class="user-row user-header", [
        span(class="user-cell", [text("Name")]),
        span(class="user-cell", [text("Email")]),
        span(class="user-cell", [text("Role")]),
      ]),
      div(class="user-row", [
        span(class="user-cell", [text("Alice")]),
        span(class="user-cell", [text("alice@example.com")]),
        span(class="user-cell", [text("Admin")]),
      ]),
      div(class="user-row", [
        span(class="user-cell", [text("Bob")]),
        span(class="user-cell", [text("bob@example.com")]),
        span(class="user-cell", [text("User")]),
      ]),
      div(class="user-row", [
        span(class="user-cell", [text("Charlie")]),
        span(class="user-cell", [text("charlie@example.com")]),
        span(class="user-cell", [text("User")]),
      ]),
    ]),
  ]
  @sol.nodes(content)
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

// =============================================================================
// API Handlers
// =============================================================================

///|
/// Debug API - returns catch-all params
async fn api_test_catch_all(props : @sol.PageProps) -> Json {
  let path = match @types.params_api_test_path(props) {
    Ok(p) => p.path
    Err(_) => "(none)"
  }
  let all_params = props.params.params.map(fn(p) { p.0 + "=" + p.1 }).join(",")
  @sol.ok([("path", path.to_json()), ("all_params", all_params.to_json())]).to_json()
}

///|
/// API handler: health check
async fn api_health(_props : @sol.PageProps) -> Json {
  @sol.ok([("status", "ok".to_json())]).to_json()
}

///|
/// API handler: benchmark ping (lightweight)
async fn api_bench_ping(_props : @sol.PageProps) -> Json {
  @sol.ok([("ok", true.to_json())]).to_json()
}

///|
/// API handler: benchmark catch-all (lightweight)
async fn api_bench_catch_all(props : @sol.PageProps) -> Json {
  let path = match @types.params_api_bench_test_path(props) {
    Ok(p) => p.path
    Err(_) => "(none)"
  }
  @sol.ok([("path", path.to_json())]).to_json()
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

// ============================================================================
// Server Actions
// ============================================================================

///|
priv struct ContactSubmitRequest {
  name : String
  email : String
} derive(FromJson)

///|
priv struct ContactSubmitData {
  name : String
  email : String
} derive(ToJson)

///|
priv struct ContactSubmitResponse {
  success : Bool
  message : String
  data : ContactSubmitData
} derive(ToJson)

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
    let req : ContactSubmitRequest = match ctx.decode_json() {
      Some(req) => req
      None => return @action.ActionResult::bad_request("Invalid JSON payload")
    }
    (req.name, req.email)
  }

  // Validate
  if name == "" {
    return @action.ActionResult::bad_request("Name is required")
  }
  if email == "" {
    return @action.ActionResult::bad_request("Email is required")
  }
  if !email.contains("@") {
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
    @action.ActionResult::json(ContactSubmitResponse::{
      success: true,
      message: "Form submitted successfully!",
      data: ContactSubmitData::{ name, email },
    })
  }
})

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
    @action.ActionDef::from_key(
      @types.action_submit_contact(),
      submit_contact_handler,
    ).with_require_json(false), // Allow form-urlencoded for progressive enhancement
  )
}
