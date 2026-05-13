// Sol Router Helpers
//
// Provides simplified APIs for defining routes, handling responses,
// and extracting parameters.

// ============================================================================
// Route Definition Helpers
// ============================================================================

///|
/// Create a page route with minimal boilerplate
///
/// Example:
/// ```moonbit nocheck
/// page("/", home, title="Home")
/// page("/blog/:slug", blog_post, title="Blog", revalidate=Some(60))
/// ```
pub fn page(
  path : String,
  handler : async (PageProps) -> @server_dom.ServerNode,
  title? : String = "",
  meta? : Array[(String, String)] = [],
  revalidate? : Int? = None,
  cache? : CacheStrategy? = None,
  styles? : Array[String] = [],
  scripts? : Array[String] = [],
) -> SolRoutes {
  let route = SolRoutes::Page(
    path~,
    handler=PageHandler(handler),
    title~,
    meta~,
    revalidate~,
    cache~,
  )
  if styles.is_empty() && scripts.is_empty() {
    route
  } else {
    SolRoutes::WithAssets(styles~, scripts~, children=[route])
  }
}

///|
fn[T : ToJson] make_api_handler(handler : async (PageProps) -> T) -> ApiHandler {
  ApiHandler(async fn(props) { handler(props).to_json() })
}

///|
/// Create a GET API route
///
/// Example:
/// ```moonbit nocheck
/// api_get("/api/users/:id", get_user)
/// ```
pub fn[T : ToJson] api_get(
  path : String,
  handler : async (PageProps) -> T,
) -> SolRoutes {
  SolRoutes::Get(path~, handler=make_api_handler(handler))
}

///|
/// Create a POST API route
///
/// Example:
/// ```moonbit nocheck
/// api_post("/api/users", create_user)
/// ```
pub fn[T : ToJson] api_post(
  path : String,
  handler : async (PageProps) -> T,
) -> SolRoutes {
  SolRoutes::Post(path~, handler=make_api_handler(handler))
}

///|
/// Create a PUT API route
pub fn[T : ToJson] api_put(
  path : String,
  handler : async (PageProps) -> T,
) -> SolRoutes {
  SolRoutes::Put(path~, handler=make_api_handler(handler))
}

///|
/// Create a DELETE API route
pub fn[T : ToJson] api_delete(
  path : String,
  handler : async (PageProps) -> T,
) -> SolRoutes {
  SolRoutes::Delete(path~, handler=make_api_handler(handler))
}

///|
/// Create a PATCH API route
pub fn[T : ToJson] api_patch(
  path : String,
  handler : async (PageProps) -> T,
) -> SolRoutes {
  SolRoutes::Patch(path~, handler=make_api_handler(handler))
}

///|
/// Create a layout wrapper
///
/// Example:
/// ```moonbit nocheck
/// wrap("/admin", admin_layout, [
///   page("/", admin_dashboard),
///   page("/settings", admin_settings),
/// ])
/// ```
pub fn wrap(
  segment : String,
  layout : (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  children : Array[SolRoutes],
) -> SolRoutes {
  SolRoutes::Layout(segment~, layout~, children~)
}

///|
/// Apply middleware to a group of routes
///
/// Example:
/// ```moonbit nocheck
/// with_mw([@mw.logger(), @mw.cors()], [
///   api_get("/api/data", get_data),
/// ])
/// ```
pub fn with_mw(
  middleware : Array[@middleware.Middleware],
  children : Array[SolRoutes],
) -> SolRoutes {
  SolRoutes::WithMiddleware(middleware~, children~)
}

///|
/// Attach stylesheet and client script assets to a route group.
pub fn assets(
  children : Array[SolRoutes],
  styles? : Array[String] = [],
  scripts? : Array[String] = [],
) -> SolRoutes {
  SolRoutes::WithAssets(styles~, scripts~, children~)
}

// ============================================================================
// API Response Builder
// ============================================================================

///|
/// Type-safe API response enum
///
/// Use with `.to_json()` to convert to `Json` for handler return.
pub(all) enum ApiResponse {
  /// JSON data response
  Json(Json)
  /// Redirect response (url, status_code)
  Redirect(String, Int)
  /// Not found (404)
  NotFound(String)
  /// Error response (message, status_code)
  Error(String, Int)
}

///|
/// Convert ApiResponse to Json for handler return
pub fn ApiResponse::to_json(self : ApiResponse) -> Json {
  match self {
    Json(data) => data
    Redirect(url, status) =>
      { "redirect": url.to_json(), "status": status.to_json() }
    NotFound(msg) => { "error": msg.to_json(), "status": (404 : Int).to_json() }
    Error(msg, status) => { "error": msg.to_json(), "status": status.to_json() }
  }
}

///|
/// Create a JSON response from key-value pairs
///
/// Example:
/// ```moonbit nocheck
/// ok([("status", "ok".to_json())]).to_json()
/// ```
pub fn ok(pairs : Array[(String, Json)]) -> ApiResponse {
  let obj : Map[String, Json] = {}
  for pair in pairs {
    obj[pair.0] = pair.1
  }
  ApiResponse::Json(obj.to_json())
}

///|
/// Create a redirect response (default 302)
pub fn redirect_to(url : String, status? : Int = 302) -> ApiResponse {
  ApiResponse::Redirect(url, status)
}

///|
/// Create a permanent redirect (301)
pub fn redirect_permanent_to(url : String) -> ApiResponse {
  ApiResponse::Redirect(url, 301)
}

///|
/// Create a 404 not found response
pub fn not_found_response(message? : String = "Not found") -> ApiResponse {
  ApiResponse::NotFound(message)
}

///|
/// Create an error response
pub fn error_response(message : String, status? : Int = 500) -> ApiResponse {
  ApiResponse::Error(message, status)
}

///|
/// Create a bad request (400) response
pub fn bad_request(message : String) -> ApiResponse {
  ApiResponse::Error(message, 400)
}

///|
/// Create an unauthorized (401) response
pub fn unauthorized(message? : String = "Unauthorized") -> ApiResponse {
  ApiResponse::Error(message, 401)
}

///|
/// Create a forbidden (403) response
pub fn forbidden(message? : String = "Forbidden") -> ApiResponse {
  ApiResponse::Error(message, 403)
}

// ============================================================================
// Parameter Extraction Helpers
// ============================================================================

///|
/// Extract a required path parameter (delegates to RouteParams)
pub fn require(props : PageProps, name : String) -> Result[String, ApiResponse] {
  props.params.require(name)
}

///|
/// Extract an optional path parameter with default value (delegates to RouteParams)
pub fn optional(props : PageProps, name : String, default : String) -> String {
  props.params.optional(name, default)
}

///|
/// Extract and parse an integer parameter (delegates to RouteParams)
pub fn require_int(
  props : PageProps,
  name : String,
) -> Result[Int, ApiResponse] {
  props.params.require_int(name)
}

///|
/// Extract a required query parameter (delegates to RouteParams)
pub fn require_query(
  props : PageProps,
  name : String,
) -> Result[String, ApiResponse] {
  props.params.require_query(name)
}

///|
/// Extract an optional query parameter with default value (delegates to RouteParams)
pub fn optional_query(
  props : PageProps,
  name : String,
  default : String,
) -> String {
  props.params.optional_query(name, default)
}

// ============================================================================
// ServerNode Helpers
// ============================================================================

///|
/// Create a sync ServerNode from an array of nodes
///
/// Example:
/// ```moonbit nocheck
/// nodes([
///   @element.h1([@element.text("Hello")]),
///   @element.p([@element.text("World")]),
/// ])
/// ```
pub fn nodes(
  content : Array[@luna.Node[Unit, String]],
) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// Create a ServerNode group from server components.
pub fn server_nodes(
  children : Array[@server_dom.ServerNode],
) -> @server_dom.ServerNode {
  @server_dom.ServerNode::group(children)
}

///|
/// Attach a component-local stylesheet to a node.
pub fn with_style(
  style : String,
  content : @luna.Node[Unit, String],
) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(content).with_style(style)
}

///|
/// Attach a component-local client script to a node.
pub fn with_script(
  script : String,
  content : @luna.Node[Unit, String],
) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(content).with_script(script)
}

///|
/// Attach component-local stylesheet and client script assets to a node.
pub fn with_assets(
  content : @luna.Node[Unit, String],
  styles? : Array[String] = [],
  scripts? : Array[String] = [],
) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(content).with_assets(styles~, scripts~)
}
