// Manifest Adapter for Sol
//
// Converts between SolRoutes and RouteManifest

// =============================================================================
// SolRoutes to RouteManifest
// =============================================================================

///|
/// Convert SolRoutes array to RouteManifest
pub fn sol_routes_to_manifest(
  routes : Array[SolRoutes],
  base? : String = "",
) -> @core_routes.RouteManifest {
  let manifest_routes : Array[@core_routes.RouteEntry] = []
  collect_routes(routes, base, manifest_routes)
  @core_routes.RouteManifest::{
    routes: manifest_routes,
    fallback: @core_routes.FallbackConfig::NotFound(path="/404.html"),
  }
}

///|
/// Recursively collect routes from SolRoutes tree
fn collect_routes(
  routes : Array[SolRoutes],
  base : String,
  result : Array[@core_routes.RouteEntry],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, handler~, title~, meta~, revalidate~, cache~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let catch_all = extract_catch_all_info(full_path)

        // Determine render mode from revalidate
        let mode = match revalidate {
          Some(seconds) => @core_routes.RenderMode::Isr(revalidate=seconds)
          None => @core_routes.RenderMode::Ssr
        }

        // Create dynamic route entry
        let entry = @core_routes.RouteEntry::Dynamic(
          @core_routes.DynamicRouteEntry::{
            path: full_path,
            pattern,
            param_names,
            source: full_path, // For Sol, source is the path
            mode,
            layout: None,
            catch_all,
            title: Some(title),
            islands: [],
          },
        )
        result.push(entry)

        // Suppress unused warnings
        let _ = handler
        let _ = meta
        let _ = cache
      }
      Layout(segment~, layout~, children~) => {
        // Recurse into children with updated base path
        let new_base = manifest_normalize_path(base + segment)
        collect_routes(children, new_base, result)
        let _ = layout
      }
      Get(path~, handler~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let entry = @core_routes.RouteEntry::Api(
          @core_routes.ApiRouteEntry::{
            path: full_path,
            pattern,
            param_names,
            http_method: @core_routes.HttpMethod::Get,
            source: full_path,
          },
        )
        result.push(entry)
        let _ = handler
      }
      Post(path~, handler~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let entry = @core_routes.RouteEntry::Api(
          @core_routes.ApiRouteEntry::{
            path: full_path,
            pattern,
            param_names,
            http_method: @core_routes.HttpMethod::Post,
            source: full_path,
          },
        )
        result.push(entry)
        let _ = handler
      }
      WithMiddleware(middleware~, children~) => {
        // Middleware doesn't affect manifest, just recurse
        collect_routes(children, base, result)
        let _ = middleware
      }
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Normalize path for manifest (remove double slashes, ensure leading slash)
fn manifest_normalize_path(path : String) -> String {
  if path.is_empty() {
    "/"
  } else if path.has_prefix("/") {
    path
  } else {
    "/" + path
  }
}

///|
/// Extract regex pattern and parameter names from path
fn extract_route_pattern(path : String) -> (String, Array[String]) {
  let param_names : Array[String] = []
  let pattern = StringBuilder::new()
  pattern.write_string("^")

  let mut i = 0
  let len = path.length()

  while i < len {
    let ch = char_at(path, i)

    if ch == ':' {
      // Named parameter :name
      let param_start = i + 1
      let mut param_end = param_start
      while param_end < len && is_param_char(char_at(path, param_end)) {
        param_end = param_end + 1
      }
      let param_name = substring(path, param_start, param_end)
      param_names.push(param_name)
      pattern.write_string("([^/]+)")
      i = param_end
    } else if ch == '*' {
      // Catch-all
      param_names.push("*")
      pattern.write_string("(.*)")
      i = i + 1
    } else if ch == '[' {
      // Bracket syntax [param] or [...param]
      let (new_i, param_name, is_catch_all) = parse_bracket_param(path, i)
      param_names.push(param_name)
      if is_catch_all {
        pattern.write_string("(.*)")
      } else {
        pattern.write_string("([^/]+)")
      }
      i = new_i
    } else if ch == '.' || ch == '+' || ch == '?' || ch == '(' || ch == ')' {
      // Escape regex special chars
      pattern.write_char('\\')
      pattern.write_char(ch)
      i = i + 1
    } else {
      pattern.write_char(ch)
      i = i + 1
    }
  }

  pattern.write_char('$')
  (pattern.to_string(), param_names)
}

///|
/// Extract catch-all info from path
fn extract_catch_all_info(path : String) -> @core_routes.CatchAllInfo? {
  // Check for [...param] or [[...param]]
  if path.contains("[...") {
    let optional = path.contains("[[...")
    // Extract param name - simplified
    Some(@core_routes.CatchAllInfo::{ name: "path", optional })
  } else if path.contains("*") {
    Some(@core_routes.CatchAllInfo::{ name: "*", optional: false })
  } else {
    None
  }
}

///|
/// Parse bracket parameter [param], [...param], or [[...param]]
fn parse_bracket_param(path : String, start : Int) -> (Int, String, Bool) {
  let len = path.length()
  let mut i = start + 1 // Skip first [
  let mut is_optional = false
  let mut is_catch_all = false

  // Check for optional [[
  if i < len && char_at(path, i) == '[' {
    is_optional = true
    i = i + 1
  }

  // Check for catch-all ...
  if i + 2 < len &&
    char_at(path, i) == '.' &&
    char_at(path, i + 1) == '.' &&
    char_at(path, i + 2) == '.' {
    is_catch_all = true
    i = i + 3
  }

  // Extract parameter name
  let param_start = i
  while i < len && char_at(path, i) != ']' {
    i = i + 1
  }
  let param_name = substring(path, param_start, i)

  // Skip closing brackets
  if i < len && char_at(path, i) == ']' {
    i = i + 1
  }
  if is_optional && i < len && char_at(path, i) == ']' {
    i = i + 1
  }

  // Suppress unused
  let _ = is_optional

  (i, param_name, is_catch_all)
}

///|
/// Check if character is valid for parameter name
fn is_param_char(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '_'
}

///|
/// Get character at index (safe)
fn char_at(s : String, idx : Int) -> Char {
  if idx < 0 || idx >= s.length() {
    '\u0000'
  } else {
    let code = s.code_unit_at(idx).to_int()
    code.unsafe_to_char()
  }
}

///|
/// Extract substring
fn substring(s : String, start : Int, end : Int) -> String {
  @ssg.extract_substring(s, start, end)
}
