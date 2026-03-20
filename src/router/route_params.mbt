// Router request/route parameter types and extraction

///|
/// Mars app type alias
pub type App = @mars.Server

///|
/// Mars context type alias
pub type Ctx = @mars.Context

///|
/// Route parameters extracted from URL
pub struct RouteParams {
  /// Path parameters (e.g., {:id} -> [("id", "123")])
  params : Array[(String, String)]
  /// Query parameters
  query : Array[(String, String)]
  /// Full path
  path : String
  /// Whether this is a fragment request (CSR navigation)
  is_fragment : Bool
}

///|
/// Create empty route params
pub fn RouteParams::empty() -> RouteParams {
  { params: [], query: [], path: "", is_fragment: false }
}

///|
/// Get path parameter by name
pub fn RouteParams::get_param(self : RouteParams, key : String) -> String? {
  self.params
  .iter()
  .find_first(fn(pair) { pair.0 == key })
  .map(fn(pair) { pair.1 })
}

///|
/// Get query parameter by name
pub fn RouteParams::get_query(self : RouteParams, key : String) -> String? {
  self.query
  .iter()
  .find_first(fn(pair) { pair.0 == key })
  .map(fn(pair) { pair.1 })
}

///|
/// Extract a required path parameter, returning ApiResponse error if missing
pub fn RouteParams::require(
  self : RouteParams,
  name : String,
) -> Result[String, ApiResponse] {
  match self.get_param(name) {
    Some(v) => Ok(v)
    None => Err(ApiResponse::Error("Missing required parameter: " + name, 400))
  }
}

///|
/// Extract an optional path parameter with default value
pub fn RouteParams::optional(
  self : RouteParams,
  name : String,
  default : String,
) -> String {
  self.get_param(name).unwrap_or(default)
}

///|
/// Extract and parse an integer path parameter
pub fn RouteParams::require_int(
  self : RouteParams,
  name : String,
) -> Result[Int, ApiResponse] {
  match self.get_param(name) {
    Some(v) =>
      try {
        Ok(@strconv.parse_int!(v))
      } catch {
        _ =>
          Err(ApiResponse::Error("Invalid integer parameter: " + name, 400))
      }
    None =>
      Err(ApiResponse::Error("Missing required parameter: " + name, 400))
  }
}

///|
/// Extract a required query parameter
pub fn RouteParams::require_query(
  self : RouteParams,
  name : String,
) -> Result[String, ApiResponse] {
  match self.get_query(name) {
    Some(v) => Ok(v)
    None =>
      Err(
        ApiResponse::Error("Missing required query parameter: " + name, 400),
      )
  }
}

///|
/// Extract an optional query parameter with default value
pub fn RouteParams::optional_query(
  self : RouteParams,
  name : String,
  default : String,
) -> String {
  self.get_query(name).unwrap_or(default)
}

///|
/// Props passed to page components
pub struct PageProps {
  /// Request context (Hono Context)
  /// Internal context storage. Use PageProps methods instead of direct access.
  /// Request-specific accessors return None during ISR renders.
  priv ctx : Ctx
  /// Route parameters (path params, query params)
  params : RouteParams
  /// Whether this is a fragment request (CSR navigation)
  /// When true, page should return content without layout wrapper
  is_fragment : Bool
  /// Whether this render is for ISR caching.
  /// When true, the rendered HTML will be shared across all users.
  /// Do NOT access ctx headers (Authorization, Cookie, etc.) in this mode.
  is_isr_render : Bool
}

///|
/// Create PageProps from context and pre-extracted params
/// Use this when params are already extracted by the router
pub fn PageProps::from_ctx_with_params(
  ctx : Ctx,
  params : RouteParams,
) -> PageProps {
  { ctx, params, is_fragment: params.is_fragment, is_isr_render: false }
}

///|
/// Get path parameter by name (convenience method)
pub fn PageProps::get_param(self : PageProps, key : String) -> String? {
  self.params.get_param(key)
}

///|
/// Get query parameter by name (convenience method)
pub fn PageProps::get_query(self : PageProps, key : String) -> String? {
  self.params.get_query(key)
}

///|
/// Get pathname group from URLPatternResult (convenience method)
pub fn PageProps::get_pathname_group(
  self : PageProps,
  name : String,
) -> String? {
  self.params.get_pathname_group(name)
}

///|
/// Get search group from URLPatternResult (convenience method)
pub fn PageProps::get_search_group(self : PageProps, name : String) -> String? {
  self.params.get_search_group(name)
}

///|
/// Get the full path
pub fn PageProps::path(self : PageProps) -> String {
  self.params.path
}

///|
/// Get request header.
/// Returns None during ISR render to avoid leaking request-specific data.
pub fn PageProps::header(self : PageProps, name : String) -> String? {
  if self.is_isr_render {
    None
  } else {
    self.ctx.header(name)
  }
}

///|
/// Get raw request header.
/// Returns None during ISR render to avoid leaking request-specific data.
pub fn PageProps::raw_header(self : PageProps, name : String) -> String? {
  if self.is_isr_render {
    None
  } else {
    self.ctx.raw_header(name)
  }
}

///|
/// Get cookie value by name.
/// Returns None during ISR render to avoid leaking request-specific data.
pub fn PageProps::cookie(self : PageProps, name : String) -> String? {
  if self.is_isr_render {
    None
  } else {
    self.ctx.cookie(name)
  }
}

///|
/// Parse request body as JSON.
/// Returns None during ISR render to avoid caching request-specific bodies.
pub async fn PageProps::body_json(self : PageProps) -> Json? {
  if self.is_isr_render {
    None
  } else {
    self.ctx.body_json()
  }
}

///|
/// Parse request body as a typed struct via FromJson.
/// Returns Err(ApiResponse) on parse failure (400 Bad Request).
pub async fn[T : @json.FromJson] PageProps::body_as(
  self : PageProps,
) -> Result[T, ApiResponse] {
  match self.body_json() {
    None => Err(bad_request("Missing or unreadable request body"))
    Some(json) =>
      try {
        Ok(@json.from_json(json))
      } catch {
        e => Err(bad_request("Invalid request body: " + e.to_string()))
      }
  }
}

///|
/// Set response header.
pub fn PageProps::set_header(
  self : PageProps,
  name : String,
  value : String,
) -> Unit {
  if self.is_isr_render {
    ()
  } else {
    self.ctx.set_header(name, value)
  }
}

///|
/// Send a text response.
/// No-op during ISR render to keep shared HTML generation side-effect free.
pub fn PageProps::text(self : PageProps, body : String, status? : Int) -> Unit {
  if self.is_isr_render {
    ()
  } else {
    match status {
      Some(code) => self.ctx.text(body, status=code)
      None => self.ctx.text(body)
    }
  }
}

///|
/// Send an HTML response.
/// No-op during ISR render to keep shared HTML generation side-effect free.
pub fn PageProps::html(self : PageProps, body : String, status? : Int) -> Unit {
  if self.is_isr_render {
    ()
  } else {
    match status {
      Some(code) => self.ctx.html(body, status=code)
      None => self.ctx.html(body)
    }
  }
}

///|
/// Set response status code.
/// No-op during ISR render to keep shared HTML generation side-effect free.
pub fn PageProps::set_status(self : PageProps, status : Int) -> Unit {
  if self.is_isr_render {
    ()
  } else {
    self.ctx.set_status(status)
  }
}

///|
/// Extract route parameters from Mars context
fn extract_route_params(
  c : Ctx,
  is_fragment? : Bool = false,
  param_names? : Array[String] = [],
) -> RouteParams {
  let raw_path = c.path()
  // Use Mars public API (`Context::param`) to extract known route params.
  let params = param_names.filter_map(fn(name) {
    c.param(name).map(fn(value) { (name, value) })
  })

  // Get query params and strip query from path
  let (path, query) = match raw_path.find("?") {
    Some(_) => (strip_query_string(raw_path), c.queries().to_array())
    None => (raw_path, [])
  }

  { params, query, path, is_fragment }
}

///|
/// Remove query string from path (everything after first '?')
fn strip_query_string(path : String) -> String {
  match path.find("?") {
    Some(idx) => path.substring(end=idx)
    None => path
  }
}

///|
/// Extract parameter names from a route path pattern for use with Mars/Hono param().
/// Handles colon params (`:id`, `:version{[0-9]+}`), bracket params (`[id]`),
/// catch-all params (`[...slug]`), and optional catch-all params (`[[...slug]]`).
/// Deduplicates names and strips regex suffixes from colon params.
///
/// Note: This is distinct from `extract_param_names` in `sol_routes.mbt`, which
/// excludes catch-all params and does not handle regex suffixes. Use this function
/// when registering legacy routes via Mars/Hono; use `extract_param_names` for
/// the newer SolRoutes compilation pipeline.
fn extract_route_param_names(path : String) -> Array[String] {
  let names : Array[String] = []
  path
  .split("/")
  .filter_map(fn(seg) { segment_to_param_name(seg.to_string()) })
  .each(fn(name) {
    if not(name.is_empty()) && not(names.contains(name)) {
      names.push(name)
    }
  })
  names
}

///|
fn segment_to_param_name(segment : String) -> String? {
  if segment.has_prefix(":") && segment.length() > 1 {
    let raw = segment[1:].to_string() catch { _ => return None }
    let end = find_route_param_end(raw)
    let name = raw[:end].to_string() catch { _ => return None }
    if name.is_empty() {
      None
    } else {
      Some(name)
    }
  } else if segment.has_prefix("[[...") &&
    segment.has_suffix("]]") &&
    segment.length() > 7 {
    let name = segment[5:segment.length() - 2].to_string() catch {
      _ => return None
    }
    if name.is_empty() {
      None
    } else {
      Some(name)
    }
  } else if segment.has_prefix("[...") &&
    segment.has_suffix("]") &&
    segment.length() > 5 {
    let name = segment[4:segment.length() - 1].to_string() catch {
      _ => return None
    }
    if name.is_empty() {
      None
    } else {
      Some(name)
    }
  } else if segment.has_prefix("[") &&
    segment.has_suffix("]") &&
    segment.length() > 2 {
    let name = segment[1:segment.length() - 1].to_string() catch {
      _ => return None
    }
    if name.is_empty() {
      None
    } else {
      Some(name)
    }
  } else {
    None
  }
}

///|
fn find_route_param_end(raw : String) -> Int {
  for i in 0..<raw.length() {
    let ch = raw[i]
    if ch == '{' || ch == '?' {
      return i
    }
  }
  raw.length()
}
