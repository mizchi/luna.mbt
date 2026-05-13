// Route Analyzer

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
      Put(path~, handler~) => {
        let _ = handler
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          kind: RouteKind::Dynamic,
          reason: "API PUT endpoint",
        })
      }
      Delete(path~, handler~) => {
        let _ = handler
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          kind: RouteKind::Dynamic,
          reason: "API DELETE endpoint",
        })
      }
      Patch(path~, handler~) => {
        let _ = handler
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          kind: RouteKind::Dynamic,
          reason: "API PATCH endpoint",
        })
      }
      WithMiddleware(middleware~, children~) => {
        let _ = middleware
        analyze_routes_inner(children, prefix, result)
      }
      WithAssets(styles~, scripts~, children~) => {
        let _ = (styles, scripts)
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
      !segment.has_prefix("[...") &&
      !segment.has_prefix("[[...") &&
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
