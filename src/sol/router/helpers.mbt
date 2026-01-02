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
/// ```moonbit
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
) -> SolRoutes {
  SolRoutes::Page(
    path~,
    handler=PageHandler(handler),
    title~,
    meta~,
    revalidate~,
    cache~,
  )
}

///|
/// Create a GET API route
///
/// Example:
/// ```moonbit
/// api_get("/api/users/:id", get_user)
/// ```
pub fn api_get(
  path : String,
  handler : async (PageProps) -> @js.Any,
) -> SolRoutes {
  SolRoutes::Get(path~, handler=ApiHandler(handler))
}

///|
/// Create a POST API route
///
/// Example:
/// ```moonbit
/// api_post("/api/users", create_user)
/// ```
pub fn api_post(
  path : String,
  handler : async (PageProps) -> @js.Any,
) -> SolRoutes {
  SolRoutes::Post(path~, handler=ApiHandler(handler))
}

///|
/// Create a layout wrapper
///
/// Example:
/// ```moonbit
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
/// ```moonbit
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

// ============================================================================
// API Response Builder
// ============================================================================

///|
/// Type-safe API response enum
///
/// Use with `.to_json()` to convert to `@js.Any` for handler return.
pub(all) enum ApiResponse {
  /// JSON data response
  Json(@js.Any)
  /// Redirect response (url, status_code)
  Redirect(String, Int)
  /// Not found (404)
  NotFound(String)
  /// Error response (message, status_code)
  Error(String, Int)
}

///|
/// Convert ApiResponse to JSON for handler return
pub fn ApiResponse::to_json(self : ApiResponse) -> @js.Any {
  match self {
    Json(data) => data
    Redirect(url, status) =>
      ffi_json_obj([("redirect", @js.any(url)), ("status", @js.any(status))])
    NotFound(msg) =>
      ffi_json_obj([("error", @js.any(msg)), ("status", @js.any(404))])
    Error(msg, status) =>
      ffi_json_obj([("error", @js.any(msg)), ("status", @js.any(status))])
  }
}

///|
extern "js" fn ffi_json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any =
  #| (pairs) => Object.fromEntries(pairs.map(p => [p._0, p._1]))

///|
/// Create a JSON response from key-value pairs
///
/// Example:
/// ```moonbit
/// ok([("status", @js.any("success"))]).to_json()
/// ```
pub fn ok(pairs : Array[(String, @js.Any)]) -> ApiResponse {
  ApiResponse::Json(ffi_json_obj(pairs))
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
/// Extract a required path parameter
///
/// Returns error response if parameter is missing.
///
/// Example:
/// ```moonbit
/// match require(props, "id") {
///   Ok(id) => ok([("id", @js.any(id))]).to_json()
///   Err(err) => err.to_json()
/// }
/// ```
pub fn require(props : PageProps, name : String) -> Result[String, ApiResponse] {
  match props.get_param(name) {
    Some(v) => Ok(v)
    None => Err(bad_request("Missing required parameter: " + name))
  }
}

///|
/// Extract an optional path parameter with default value
pub fn optional(props : PageProps, name : String, default : String) -> String {
  props.get_param(name).unwrap_or(default)
}

///|
/// Extract and parse an integer parameter
///
/// Returns error response if parameter is missing or invalid.
pub fn require_int(
  props : PageProps,
  name : String,
) -> Result[Int, ApiResponse] {
  match props.get_param(name) {
    Some(v) => {
      let parsed = ffi_parse_int(v)
      if ffi_is_nan(parsed) {
        Err(bad_request("Invalid integer parameter: " + name))
      } else {
        Ok(parsed)
      }
    }
    None => Err(bad_request("Missing required parameter: " + name))
  }
}

///|
extern "js" fn ffi_parse_int(s : String) -> Int =
  #| (s) => parseInt(s, 10)

///|
extern "js" fn ffi_is_nan(n : Int) -> Bool =
  #| (n) => isNaN(n)

///|
/// Extract a required query parameter
pub fn require_query(
  props : PageProps,
  name : String,
) -> Result[String, ApiResponse] {
  match props.get_query(name) {
    Some(v) => Ok(v)
    None => Err(bad_request("Missing required query parameter: " + name))
  }
}

///|
/// Extract an optional query parameter with default value
pub fn optional_query(
  props : PageProps,
  name : String,
  default : String,
) -> String {
  props.get_query(name).unwrap_or(default)
}

// ============================================================================
// ServerNode Helpers
// ============================================================================

///|
/// Create a sync ServerNode from an array of nodes
///
/// Example:
/// ```moonbit
/// nodes([
///   @element.h1([@element.text("Hello")]),
///   @element.p([@element.text("World")]),
/// ])
/// ```
pub fn nodes(content : Array[@luna.Node[Unit]]) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(@luna.fragment(content))
}
