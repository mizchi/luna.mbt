// Route Conflict Detection
//
// Detects and reports conflicts in route definitions.

// =============================================================================
// Conflict Types
// =============================================================================

///|
/// Types of route conflicts that can be detected
pub(all) enum ConflictType {
  /// Same exact path defined by multiple sources
  DuplicatePath(path~ : String, sources~ : Array[String])
  /// Static path shadows a dynamic pattern (e.g., /blog/about shadows /blog/:slug)
  StaticShadowsDynamic(static_path~ : String, dynamic_pattern~ : String)
  /// Multiple catch-all routes at the same level
  MultipleCatchAll(paths~ : Array[String])
  /// Ambiguous dynamic patterns that could match the same paths
  AmbiguousDynamic(pattern1~ : String, pattern2~ : String)
}

// =============================================================================
// Conflict Detection
// =============================================================================

///|
/// Detect all conflicts in a route manifest
pub fn detect_conflicts(manifest : RouteManifest) -> Array[ConflictType] {
  let conflicts : Array[ConflictType] = []

  // Collect routes by type
  let static_paths : Map[String, Array[String]] = {}
  let dynamic_patterns : Array[(String, String, String)] = [] // (path, regex, source)
  let catch_all_by_parent : Map[String, Array[String]] = {}
  for route in manifest.routes {
    match route {
      Static(r) =>
        // Track static paths for duplicate detection
        match static_paths.get(r.path) {
          Some(sources) => sources.push(r.source)
          None => static_paths[r.path] = [r.source]
        }
      Dynamic(r) => {
        // Track dynamic patterns
        dynamic_patterns.push((r.path, r.pattern, r.source))

        // Track catch-all routes by parent path
        if r.catch_all is Some(_) {
          let parent = get_parent_path(r.path)
          match catch_all_by_parent.get(parent) {
            Some(paths) => paths.push(r.path)
            None => catch_all_by_parent[parent] = [r.path]
          }
        }
      }
      Component(r) =>
        // Component routes are treated like static for conflict detection
        match static_paths.get(r.path) {
          Some(sources) => sources.push(r.source)
          None => static_paths[r.path] = [r.source]
        }
      Api(_) => () // API routes don't conflict with page routes
    }
  }

  // Check for duplicate paths
  for path, sources in static_paths {
    if sources.length() > 1 {
      conflicts.push(ConflictType::DuplicatePath(path~, sources~))
    }
  }

  // Check for static paths shadowing dynamic patterns
  for static_path, _ in static_paths {
    for pattern_info in dynamic_patterns {
      let (pattern_path, regex, _) = pattern_info
      if static_path != pattern_path && matches_pattern(static_path, regex) {
        conflicts.push(
          ConflictType::StaticShadowsDynamic(
            static_path~,
            dynamic_pattern=pattern_path,
          ),
        )
      }
    }
  }

  // Check for multiple catch-all routes at same level
  for _parent, paths in catch_all_by_parent {
    if paths.length() > 1 {
      conflicts.push(ConflictType::MultipleCatchAll(paths~))
    }
  }

  // Check for ambiguous dynamic patterns
  for i = 0; i < dynamic_patterns.length(); i = i + 1 {
    for j = i + 1; j < dynamic_patterns.length(); j = j + 1 {
      let (p1, r1, _) = dynamic_patterns[i]
      let (p2, r2, _) = dynamic_patterns[j]
      if p1 != p2 && patterns_could_overlap(p1, p2, r1, r2) {
        conflicts.push(ConflictType::AmbiguousDynamic(pattern1=p1, pattern2=p2))
      }
    }
  }
  conflicts
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Check if a path matches a regex pattern
fn matches_pattern(_path : String, _regex : String) -> Bool {
  // Simplified pattern matching for common cases
  // In production, would use proper regex matching
  // For now, check if path could match the pattern structure
  false // Disabled for now - requires proper regex engine
}

///|
/// Check if two dynamic patterns could match overlapping paths
fn patterns_could_overlap(
  path1 : String,
  path2 : String,
  _regex1 : String,
  _regex2 : String,
) -> Bool {
  // Two patterns overlap if they have the same parent path
  // and both have dynamic segments at the same position
  let parent1 = get_parent_path(path1)
  let parent2 = get_parent_path(path2)
  parent1 == parent2
}

// =============================================================================
// Formatting
// =============================================================================

///|
/// Format conflict for display
pub fn ConflictType::to_string(self : ConflictType) -> String {
  match self {
    DuplicatePath(path~, sources~) => {
      let sources_str = sources.join(", ")
      "Duplicate path '" + path + "' defined by: " + sources_str
    }
    StaticShadowsDynamic(static_path~, dynamic_pattern~) =>
      "Static path '" +
      static_path +
      "' shadows dynamic pattern '" +
      dynamic_pattern +
      "'"
    MultipleCatchAll(paths~) => {
      let paths_str = paths.join(", ")
      "Multiple catch-all routes at same level: " + paths_str
    }
    AmbiguousDynamic(pattern1~, pattern2~) =>
      "Ambiguous dynamic patterns: '" + pattern1 + "' and '" + pattern2 + "'"
  }
}

///|
/// Check if conflict is an error (vs warning)
pub fn ConflictType::is_error(self : ConflictType) -> Bool {
  match self {
    DuplicatePath(..) | MultipleCatchAll(..) => true
    StaticShadowsDynamic(..) | AmbiguousDynamic(..) => false // Warnings
  }
}
