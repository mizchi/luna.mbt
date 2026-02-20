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
  /// URLPatternResult for advanced pattern matching (optional)
  url_pattern_result : @url.URLPatternResult?
}

///|
/// Create empty route params
pub fn RouteParams::empty() -> RouteParams {
  {
    params: [],
    query: [],
    path: "",
    is_fragment: false,
    url_pattern_result: None,
  }
}

///|
/// Get path parameter by name
pub fn RouteParams::get_param(self : RouteParams, key : String) -> String? {
  for pair in self.params {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get query parameter by name
pub fn RouteParams::get_query(self : RouteParams, key : String) -> String? {
  for pair in self.query {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get pathname group from URLPatternResult
/// Returns None if URLPatternResult is not available or group doesn't exist
pub fn RouteParams::get_pathname_group(
  self : RouteParams,
  name : String,
) -> String? {
  match self.url_pattern_result {
    Some(result) => {
      let value = result.pathname.groups[name]
      if @js.is_nullish(value) {
        None
      } else {
        Some(@js.identity(value))
      }
    }
    None => None
  }
}

///|
/// Get search group from URLPatternResult
/// Returns None if URLPatternResult is not available or group doesn't exist
pub fn RouteParams::get_search_group(
  self : RouteParams,
  name : String,
) -> String? {
  match self.url_pattern_result {
    Some(result) => {
      let value = result.search.groups[name]
      if @js.is_nullish(value) {
        None
      } else {
        Some(@js.identity(value))
      }
    }
    None => None
  }
}

///|
/// Props passed to page components
pub struct PageProps {
  /// Request context (Hono Context)
  ctx : Ctx
  /// Route parameters (path params, query params)
  params : RouteParams
  /// Whether this is a fragment request (CSR navigation)
  /// When true, page should return content without layout wrapper
  is_fragment : Bool
}

///|
/// Create PageProps from context
pub fn PageProps::from_ctx(ctx : Ctx) -> PageProps {
  let params = extract_route_params(ctx)
  { ctx, params, is_fragment: false }
}

///|
/// Create PageProps for fragment request
pub fn PageProps::from_ctx_fragment(ctx : Ctx) -> PageProps {
  let params = extract_route_params(ctx)
  { ctx, params, is_fragment: true }
}

///|
/// Create PageProps from context and pre-extracted params
/// Use this when params are already extracted by the router
pub fn PageProps::from_ctx_with_params(
  ctx : Ctx,
  params : RouteParams,
) -> PageProps {
  { ctx, params, is_fragment: params.is_fragment }
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
/// Extract route parameters from Mars context
fn extract_route_params(
  c : Ctx,
  is_fragment? : Bool = false,
  param_names? : Array[String] = [],
) -> RouteParams {
  let path = c.path()
  let params : Array[(String, String)] = []
  // Use Mars public API (`Context::param`) to extract known route params.
  for name in param_names {
    match c.param(name) {
      Some(value) => params.push((name, value))
      None => ()
    }
  }

  // Get query params
  let query : Array[(String, String)] = []
  if has_query_string(path) {
    for entry in c.queries() {
      query.push((entry.0, entry.1))
    }
  }

  { params, query, path, is_fragment, url_pattern_result: None }
}

///|
fn has_query_string(path : String) -> Bool {
  for c in path {
    if c == '?' {
      return true
    }
  }
  false
}

///|
fn extract_route_param_names(path : String) -> Array[String] {
  let names : Array[String] = []
  for segment_view in path.split("/") {
    let segment = segment_view.to_string()
    let name_opt = segment_to_param_name(segment)
    match name_opt {
      Some(name) =>
        if not(name.is_empty()) && not(names.contains(name)) {
          names.push(name)
        }
      None => ()
    }
  }
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
