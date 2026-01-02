// Route Analyzer
//
// Analyzes SolRoutes to extract dynamic routes for Cloudflare Workers
// run_worker_first configuration.

// ============================================================================
// Route Classification
// ============================================================================

///|
/// Classification of a route for static/dynamic handling
pub(all) enum RouteKind {
  /// Static route - can be pre-rendered at build time
  Static
  /// Dynamic route - requires worker handling at runtime
  Dynamic
}

///|
/// Analyzed route information
pub(all) struct AnalyzedRoute {
  /// URL pattern (e.g., "/api/users/:id")
  pattern : String
  /// Whether this route is dynamic
  kind : RouteKind
  /// Reason for classification
  reason : String
}

// ============================================================================
// Route Analysis
// ============================================================================

///|
/// Analyze SolRoutes and extract all routes with their classification
pub fn analyze_routes(routes : Array[SolRoutes]) -> Array[AnalyzedRoute] {
  let result : Array[AnalyzedRoute] = []
  analyze_routes_inner(routes, "", result)
  result
}

///|
fn analyze_routes_inner(
  routes : Array[SolRoutes],
  prefix : String,
  result : Array[AnalyzedRoute],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, handler~, title~, meta~, revalidate~, cache~) => {
        let _ = (handler, title, meta, cache)
        let full_path = normalize_path(prefix + path)
        let (kind, reason) = classify_page_route(full_path, revalidate)
        result.push({ pattern: full_path, kind, reason })
      }
      Layout(segment~, layout~, children~) => {
        let _ = layout
        let new_prefix = normalize_path(prefix + segment)
        analyze_routes_inner(children, new_prefix, result)
      }
      Get(path~, handler~) => {
        let _ = handler
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          kind: RouteKind::Dynamic,
          reason: "API GET endpoint",
        })
      }
      Post(path~, handler~) => {
        let _ = handler
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          kind: RouteKind::Dynamic,
          reason: "API POST endpoint",
        })
      }
      WithMiddleware(middleware~, children~) => {
        let _ = middleware
        analyze_routes_inner(children, prefix, result)
      }
    }
  }
}

///|
/// Classify a page route as static or dynamic
fn classify_page_route(path : String, revalidate : Int?) -> (RouteKind, String) {
  // ISR routes are dynamic (need worker for revalidation)
  if revalidate is Some(_) {
    return (RouteKind::Dynamic, "ISR enabled (revalidate)")
  }

  // Routes with path parameters are dynamic
  // Unless they have staticParams (handled at build time)
  if has_dynamic_segment(path) {
    return (RouteKind::Dynamic, "Dynamic path parameter")
  }

  // Catch-all routes are dynamic
  if has_catch_all(path) {
    return (RouteKind::Dynamic, "Catch-all route")
  }

  // Static route
  (RouteKind::Static, "Static page")
}

///|
/// Check if path contains dynamic segments (:id, [id])
fn has_dynamic_segment(path : String) -> Bool {
  let segments = path.split("/")
  for segment in segments {
    if segment.has_prefix(":") {
      return true
    }
    if segment.has_prefix("[") &&
      not(segment.has_prefix("[...")) &&
      not(segment.has_prefix("[[...")) &&
      segment.has_suffix("]") {
      return true
    }
  }
  false
}

///|
/// Check if path contains catch-all segments ([...slug], [[...slug]])
fn has_catch_all(path : String) -> Bool {
  path.contains("[...") || path.contains("[[...")
}

// ============================================================================
// Cloudflare Configuration Generation
// ============================================================================

///|
/// Extract dynamic route patterns for run_worker_first
pub fn extract_dynamic_patterns(routes : Array[SolRoutes]) -> Array[String] {
  let analyzed = analyze_routes(routes)
  let patterns : Array[String] = []

  for route in analyzed {
    if route.kind is Dynamic {
      // Convert to glob pattern for Cloudflare
      let pattern = to_cloudflare_pattern(route.pattern)
      if not(patterns.contains(pattern)) {
        patterns.push(pattern)
      }
    }
  }

  // Sort for consistency
  patterns.sort_by(fn(a, b) { a.compare(b) })
  patterns
}

///|
/// Convert Sol route pattern to Cloudflare glob pattern
fn to_cloudflare_pattern(path : String) -> String {
  let result = StringBuilder::new()
  let segments = path.split("/")
  let mut first = true

  for segment in segments {
    if segment.is_empty() {
      continue
    }
    if not(first) {
      result.write_string("/")
    }
    first = false

    if segment.has_prefix(":") {
      // :id -> * (single segment wildcard)
      result.write_string("*")
    } else if segment.has_prefix("[[...") && segment.has_suffix("]]") {
      // [[...slug]] -> * (optional catch-all)
      result.write_string("*")
    } else if segment.has_prefix("[...") && segment.has_suffix("]") {
      // [...slug] -> * (required catch-all)
      result.write_string("*")
    } else if segment.has_prefix("[") && segment.has_suffix("]") {
      // [id] -> * (single segment)
      result.write_string("*")
    } else {
      result.write_string(segment.to_string())
    }
  }

  "/" + result.to_string()
}

///|
/// Generate wrangler.json assets config fragment
pub fn generate_wrangler_assets_config(
  routes : Array[SolRoutes],
  output_dir : String,
) -> String {
  let patterns = extract_dynamic_patterns(routes)

  if patterns.is_empty() {
    // Pure static site
    return "{\n  \"directory\": \"\{output_dir}\",\n  \"html_handling\": \"auto-trailing-slash\",\n  \"not_found_handling\": \"404-page\"\n}"
  }

  // Site with dynamic routes
  let patterns_json = StringBuilder::new()
  patterns_json.write_string("[")
  for i, pattern in patterns {
    if i > 0 {
      patterns_json.write_string(", ")
    }
    patterns_json.write_string("\"")
    patterns_json.write_string(pattern)
    patterns_json.write_string("\"")
  }
  patterns_json.write_string("]")

  "{\n  \"directory\": \"\{output_dir}\",\n  \"html_handling\": \"auto-trailing-slash\",\n  \"not_found_handling\": \"single-page-application\",\n  \"run_worker_first\": \{patterns_json.to_string()}\n}"
}
