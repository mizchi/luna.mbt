// Hierarchical Manifest Generation
//
// Splits route manifest by first-level segments for lazy loading.

// =============================================================================
// Main Split Function
// =============================================================================

///|
/// Split a route manifest into hierarchical structure
/// Routes are grouped by first-level segment (e.g., /docs/*, /blog/*)
pub fn split_manifest(
  manifest : RouteManifest,
  configs : Map[String, PageConfig],
) -> (HierarchicalManifest, Map[String, SegmentManifest]) {
  // Classify routes by first segment
  let inline_routes : Map[String, Array[String]] = {}
  let by_segment : Map[String, Array[RouteEntry]] = {}
  for route in manifest.routes {
    let path = get_route_path(route)
    let segment = extract_first_segment(path)
    if segment.is_empty() {
      // Root level route - include inline
      inline_routes[path] = get_route_chunks(route)
    } else {
      // Segment route - group for split
      match by_segment.get(segment) {
        Some(arr) => arr.push(route)
        None => by_segment[segment] = [route]
      }
    }
  }

  // Build segment references and manifests
  let segments : Map[String, SegmentRef] = {}
  let segment_manifests : Map[String, SegmentManifest] = {}
  for segment, routes in by_segment {
    // Check if segment should be SPA (from page.json config)
    let config_key = segment
    let is_spa = match configs.get(config_key) {
      Some(cfg) => cfg.spa
      None => false
    }
    let fallback_behavior = match configs.get(config_key) {
      Some(cfg) =>
        match cfg.fallback_behavior {
          Some(fb) => fb
          None => "404"
        }
      None => "404"
    }

    // Create segment reference
    let seg_ref = SegmentRef::{
      path: "routes/" + segment + ".json",
      pattern: "/" + segment + "/*",
      spa: is_spa,
      preload: false,
    }
    segments[segment] = seg_ref

    // Create segment manifest
    let segment_routes : Map[String, Array[String]] = {}
    let dynamic_patterns : Array[DynamicPattern] = []
    for route in routes {
      let path = get_route_path(route)
      // Convert to relative path within segment
      let relative_path = extract_relative_path(path, segment)
      segment_routes[relative_path] = get_route_chunks(route)

      // Extract dynamic patterns
      match route {
        Dynamic(r) =>
          dynamic_patterns.push(DynamicPattern::{
            pattern: relative_path,
            regex: r.pattern,
            params: r.param_names,
            catch_all: r.catch_all is Some(_),
          })
        _ => ()
      }
    }
    let segment_manifest = SegmentManifest::{
      base: "/" + segment,
      routes: segment_routes,
      dynamic: dynamic_patterns,
      fallback: fallback_behavior,
    }
    segment_manifests[segment] = segment_manifest
  }

  // Build hierarchical manifest
  let hierarchical = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments,
    chunks: {}, // Filled by generator
    routes: inline_routes,
  }
  (hierarchical, segment_manifests)
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Get chunks for route (placeholder - filled by generator)
fn get_route_chunks(_route : RouteEntry) -> Array[String] {
  ["boot"] // Default chunk
}

///|
/// Extract first segment from path
/// /docs/guide/intro -> "docs"
/// /about/ -> "about"
/// /about -> "about"
/// / -> ""
pub fn extract_first_segment(path : String) -> String {
  if path.is_empty() || path == "/" {
    return ""
  }
  // Skip leading slash
  let start = if path.has_prefix("/") { 1 } else { 0 }
  // Find next slash after start
  let mut end = path.length()
  let mut char_idx = 0
  for c in path {
    if char_idx > start && c == '/' {
      end = char_idx
      break
    }
    char_idx = char_idx + 1
  }
  // Extract segment (excluding trailing slash if any)
  if end > start {
    @utils.extract_substring(path, start, end)
  } else {
    ""
  }
}

///|
/// Extract relative path within segment
/// /docs/guide/intro, "docs" -> /guide/intro
fn extract_relative_path(path : String, segment : String) -> String {
  let prefix = "/" + segment
  if path.has_prefix(prefix) {
    let rest = @utils.extract_substring(path, prefix.length(), path.length())
    if rest.is_empty() {
      "/"
    } else {
      rest
    }
  } else {
    path
  }
}

// =============================================================================
// Segment Detection
// =============================================================================

///|
/// Check if a path belongs to a specific segment
pub fn path_matches_segment(path : String, segment : String) -> Bool {
  path.has_prefix("/" + segment + "/") || path == "/" + segment
}

///|
/// Get all unique first-level segments from routes
pub fn get_all_segments(manifest : RouteManifest) -> Array[String] {
  let segments : Map[String, Bool] = {}
  for route in manifest.routes {
    let path = get_route_path(route)
    let segment = extract_first_segment(path)
    if not(segment.is_empty()) {
      segments[segment] = true
    }
  }
  segments.keys().collect()
}

// =============================================================================
// Chunk Resolution
// =============================================================================

///|
/// Resolve chunks for a path using hierarchical manifest
/// Returns None if segment needs to be loaded
pub fn resolve_chunks_inline(
  manifest : HierarchicalManifest,
  path : String,
) -> Array[String]? {
  // Try inline routes first
  match manifest.routes.get(path) {
    Some(chunks) => Some(chunks)
    None => {
      // Try with trailing slash
      let with_slash = if path.has_suffix("/") { path } else { path + "/" }
      let without_slash = path.trim_end(chars="/").to_string()
      match manifest.routes.get(with_slash) {
        Some(chunks) => Some(chunks)
        None =>
          match manifest.routes.get(without_slash) {
            Some(chunks) => Some(chunks)
            None => None // Needs segment manifest
          }
      }
    }
  }
}

///|
/// Find segment reference for a path
pub fn find_segment_ref(
  manifest : HierarchicalManifest,
  path : String,
) -> (String, SegmentRef)? {
  let segment = extract_first_segment(path)
  if segment.is_empty() {
    return None
  }
  match manifest.segments.get(segment) {
    Some(seg_ref) => Some((segment, seg_ref))
    None => None
  }
}

///|
/// Match path against segment's dynamic patterns
pub fn match_dynamic_pattern(
  manifest : SegmentManifest,
  path : String,
) -> (DynamicPattern, Map[String, String])? {
  // Convert full path to relative
  let relative = if path.has_prefix(manifest.base) {
    @utils.extract_substring(path, manifest.base.length(), path.length())
  } else {
    path
  }
  let relative_path = if relative.is_empty() { "/" } else { relative }
  for pattern in manifest.dynamic {
    match try_match_pattern(relative_path, pattern) {
      Some(params) => return Some((pattern, params))
      None => continue
    }
  }
  None
}

///|
/// Try to match a path against a dynamic pattern
fn try_match_pattern(
  path : String,
  pattern : DynamicPattern,
) -> Map[String, String]? {
  // Simple pattern matching for common cases
  // Full regex matching would be done on client side
  let pattern_parts = split_path(pattern.pattern)
  let path_parts = split_path(path)
  if pattern.catch_all {
    // Catch-all: match if prefix matches
    if path_parts.length() < pattern_parts.length() - 1 {
      return None
    }
    // Match up to catch-all segment
    for i = 0; i < pattern_parts.length() - 1; i = i + 1 {
      if pattern_parts[i] != path_parts[i] {
        return None
      }
    }
    // Extract catch-all value
    let params : Map[String, String] = {}
    if pattern.params.length() > 0 {
      let catch_all_value = join_path_parts(
        path_parts,
        pattern_parts.length() - 1,
      )
      params[pattern.params[0]] = catch_all_value
    }
    return Some(params)
  }

  // Regular dynamic pattern
  if path_parts.length() != pattern_parts.length() {
    return None
  }
  let params : Map[String, String] = {}
  let mut param_idx = 0
  for i = 0; i < pattern_parts.length(); i = i + 1 {
    let pp = pattern_parts[i]
    let pt = path_parts[i]
    if pp.has_prefix(":") {
      // Dynamic segment
      if param_idx < pattern.params.length() {
        params[pattern.params[param_idx]] = pt
        param_idx = param_idx + 1
      }
    } else if pp != pt {
      return None
    }
  }
  Some(params)
}

///|
/// Split path into segments
fn split_path(path : String) -> Array[String] {
  let parts : Array[String] = []
  let buf = StringBuilder::new()
  for c in path {
    if c == '/' {
      let s = buf.to_string()
      if not(s.is_empty()) {
        parts.push(s)
      }
      buf.reset()
    } else {
      buf.write_char(c)
    }
  }
  let last = buf.to_string()
  if not(last.is_empty()) {
    parts.push(last)
  }
  parts
}

///|
/// Join path parts from index
fn join_path_parts(parts : Array[String], from_index : Int) -> String {
  let buf = StringBuilder::new()
  for i = from_index; i < parts.length(); i = i + 1 {
    if i > from_index {
      buf.write_char('/')
    }
    buf.write_string(parts[i])
  }
  buf.to_string()
}
