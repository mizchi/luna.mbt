// Manifest Merge Utilities
//
// Merges explicit and file-based route definitions

// =============================================================================
// Manifest Merging
// =============================================================================

///|
/// Merge two manifests - explicit routes take precedence over file-based
pub fn merge_manifests(
  explicit : RouteManifest,
  file_based : RouteManifest,
) -> RouteManifest {
  // Build set of paths from explicit routes
  let explicit_paths : Map[String, Bool] = {}
  for route in explicit.routes {
    let path = get_route_path(route)
    explicit_paths[path] = true
  }

  // Collect routes - start with explicit routes
  let merged_routes : Array[RouteEntry] = []

  // Add all explicit routes
  for route in explicit.routes {
    merged_routes.push(route)
  }

  // Add file-based routes that don't conflict
  for route in file_based.routes {
    let path = get_route_path(route)
    if not(explicit_paths.contains(path)) {
      merged_routes.push(route)
    }
  }

  // Use explicit fallback if defined, otherwise file-based
  let fallback = match explicit.fallback {
    FallbackConfig::NotFound(path="/404.html") => file_based.fallback
    _ => explicit.fallback
  }
  RouteManifest::{ routes: merged_routes, fallback }
}

///|
/// Merge multiple manifests in order (later takes precedence)
pub fn merge_all_manifests(manifests : Array[RouteManifest]) -> RouteManifest {
  if manifests.is_empty() {
    return RouteManifest::empty()
  }
  let mut result = manifests[0]
  let mut i = 1
  while i < manifests.length() {
    result = merge_manifests(manifests[i], result)
    i = i + 1
  }
  result
}

// =============================================================================
// Route Filtering
// =============================================================================

///|
/// Filter routes by render mode
pub fn filter_by_mode(
  manifest : RouteManifest,
  mode : RenderMode,
) -> RouteManifest {
  let filtered : Array[RouteEntry] = []
  for route in manifest.routes {
    match route {
      RouteEntry::Static(_) =>
        // Static routes always match if mode is SSG-like
        match mode {
          RenderMode::Ssr | RenderMode::Isr(_) => ()
          RenderMode::Spa => filtered.push(route)
        }
      RouteEntry::Dynamic(entry) =>
        if modes_compatible(entry.mode, mode) {
          filtered.push(route)
        }
      RouteEntry::Api(_) =>
        // API routes are always included
        filtered.push(route)
      RouteEntry::Component(entry) =>
        // Component routes are filtered by mode
        if modes_compatible(entry.mode, mode) {
          filtered.push(route)
        }
    }
  }
  RouteManifest::{ routes: filtered, fallback: manifest.fallback }
}

///|
/// Get only static routes
pub fn get_static_routes(manifest : RouteManifest) -> Array[StaticRouteEntry] {
  let result : Array[StaticRouteEntry] = []
  for route in manifest.routes {
    match route {
      RouteEntry::Static(entry) => result.push(entry)
      _ => ()
    }
  }
  result
}

///|
/// Get only dynamic routes
pub fn get_dynamic_routes(manifest : RouteManifest) -> Array[DynamicRouteEntry] {
  let result : Array[DynamicRouteEntry] = []
  for route in manifest.routes {
    match route {
      RouteEntry::Dynamic(entry) => result.push(entry)
      _ => ()
    }
  }
  result
}

///|
/// Get only API routes
pub fn get_api_routes(manifest : RouteManifest) -> Array[ApiRouteEntry] {
  let result : Array[ApiRouteEntry] = []
  for route in manifest.routes {
    match route {
      RouteEntry::Api(entry) => result.push(entry)
      _ => ()
    }
  }
  result
}

// =============================================================================
// Route Lookup
// =============================================================================

///|
/// Find a route by exact path match
pub fn find_route(manifest : RouteManifest, path : String) -> RouteEntry? {
  for route in manifest.routes {
    if get_route_path(route) == path {
      return Some(route)
    }
  }
  None
}

///|
/// Find a static route by path
pub fn find_static_route(
  manifest : RouteManifest,
  path : String,
) -> StaticRouteEntry? {
  for route in manifest.routes {
    match route {
      RouteEntry::Static(entry) => if entry.path == path { return Some(entry) }
      _ => ()
    }
  }
  None
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Extract path from any route entry
pub fn get_route_path(route : RouteEntry) -> String {
  match route {
    RouteEntry::Static(entry) => entry.path
    RouteEntry::Dynamic(entry) => entry.path
    RouteEntry::Api(entry) => entry.path
    RouteEntry::Component(entry) => entry.path
  }
}

///|
/// Check if two render modes are compatible
fn modes_compatible(a : RenderMode, b : RenderMode) -> Bool {
  match (a, b) {
    (RenderMode::Ssr, RenderMode::Ssr) => true
    (RenderMode::Isr(_), RenderMode::Isr(_)) => true
    (RenderMode::Spa, RenderMode::Spa) => true
    (RenderMode::Ssr, RenderMode::Isr(_)) => true
    (RenderMode::Isr(_), RenderMode::Ssr) => true
    _ => false
  }
}
