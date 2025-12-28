// Client Manifest - chunk loading manifest for client-side routing
//
// This module provides ChunkManifest type and conversion from RouteManifest.
// Output format matches the TypeScript interface in js/loader/src/boot/loader.ts

// =============================================================================
// ChunkManifest Type
// =============================================================================

///|
/// Client-side chunk manifest for dynamic loading
/// Maps route paths to required chunk names
pub(all) struct ChunkManifest {
  /// Map of route paths to required chunks
  routes : Map[String, Array[String]]
  /// Map of chunk names to their hashed file paths
  chunks : Map[String, String]
  /// Base path for chunk loading (default: "/_luna/")
  base : String
}

///|
/// Create an empty chunk manifest
pub fn ChunkManifest::empty() -> ChunkManifest {
  { routes: {}, chunks: {}, base: "/_luna/" }
}

///|
/// Create a new chunk manifest with the given base path
pub fn ChunkManifest::new(base? : String = "/_luna/") -> ChunkManifest {
  { routes: {}, chunks: {}, base }
}

// =============================================================================
// Conversion from RouteManifest
// =============================================================================

///|
/// Convert RouteManifest to ChunkManifest
/// Analyzes routes and determines which chunks each path needs
pub fn route_manifest_to_chunk_manifest(
  manifest : RouteManifest,
  chunk_hashes? : Map[String, String] = {},
) -> ChunkManifest {
  let routes : Map[String, Array[String]] = {}
  let chunks : Map[String, String] = {}

  // Copy chunk hashes
  for key, value in chunk_hashes {
    chunks[key] = value
  }

  // Process each route entry
  for entry in manifest.routes {
    let (path, required_chunks) = analyze_route_chunks(entry)
    if not(required_chunks.is_empty()) {
      routes[path] = required_chunks
    }
  }

  // Add default chunks for fallback pattern
  if not(routes.contains("*")) {
    routes["*"] = ["boot"]
  }
  ChunkManifest::{ routes, chunks, base: "/_luna/" }
}

///|
/// Analyze a route entry and determine required chunks
fn analyze_route_chunks(entry : RouteEntry) -> (String, Array[String]) {
  match entry {
    Static(route) => {
      let chunks = get_static_route_chunks(route)
      (route.path, chunks)
    }
    Dynamic(route) => {
      let chunks = get_dynamic_route_chunks(route)
      (route.path, chunks)
    }
    Component(route) => {
      let chunks = get_component_route_chunks(route)
      (route.path, chunks)
    }
    Api(_) =>
      // API routes don't need client chunks
      ("", [])
  }
}

///|
/// Get chunks for static route
fn get_static_route_chunks(route : StaticRouteEntry) -> Array[String] {
  let chunks : Array[String] = ["boot"]

  // Add hydration if has islands
  if not(route.islands.is_empty()) {
    chunks.push("hydrate")
    chunks.push("signal")

    // Add island-specific chunks
    for island in route.islands {
      chunks.push("island-" + island)
    }
  }
  chunks
}

///|
/// Get chunks for dynamic route
fn get_dynamic_route_chunks(route : DynamicRouteEntry) -> Array[String] {
  let chunks : Array[String] = ["boot"]

  // Dynamic routes typically need hydration
  if not(route.islands.is_empty()) {
    chunks.push("hydrate")
    chunks.push("signal")
    for island in route.islands {
      chunks.push("island-" + island)
    }
  }

  // SSR routes may need additional runtime
  match route.mode {
    Ssr | Isr(_) | Spa =>
      // Could add router-hybrid for navigation
      ()
  }
  chunks
}

///|
/// Get chunks for component route
fn get_component_route_chunks(route : ComponentRouteEntry) -> Array[String] {
  let chunks : Array[String] = ["boot"]

  // Check if hydration is needed
  if route.component_type.can_hydrate() {
    chunks.push("hydrate")
    chunks.push("signal")

    // Add island chunk for this component
    // Convert source path to island name (e.g., "counter/" -> "counter")
    let island_name = strip_trailing_slash(route.source)
    chunks.push("island-" + island_name)
  }

  // Add any additional islands
  for island in route.islands {
    let island_chunk = "island-" + island
    if not(chunks.contains(island_chunk)) {
      chunks.push(island_chunk)
    }
  }
  chunks
}

// =============================================================================
// JSON Serialization
// =============================================================================

///|
/// Serialize ChunkManifest to JSON string
pub fn ChunkManifest::to_json(self : ChunkManifest) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")

  // routes
  buf.write_string("  \"routes\": {\n")
  let route_entries = self.routes.iter().collect()
  for i, entry in route_entries {
    let (path, chunks) = entry
    buf.write_string("    ")
    buf.write_string(json_string(path))
    buf.write_string(": [")
    for j, chunk in chunks {
      buf.write_string(json_string(chunk))
      if j < chunks.length() - 1 {
        buf.write_string(", ")
      }
    }
    buf.write_string("]")
    if i < route_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")

  // chunks
  buf.write_string("  \"chunks\": {\n")
  let chunk_entries = self.chunks.iter().collect()
  for i, entry in chunk_entries {
    let (name, hash_path) = entry
    buf.write_string("    ")
    buf.write_string(json_string(name))
    buf.write_string(": ")
    buf.write_string(json_string(hash_path))
    if i < chunk_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")

  // base
  buf.write_string("  \"base\": ")
  buf.write_string(json_string(self.base))
  buf.write_string("\n")
  buf.write_string("}")
  buf.to_string()
}

///|
/// Strip trailing slash from path
fn strip_trailing_slash(path : String) -> String {
  if path.is_empty() {
    return ""
  }
  if path.has_suffix("/") {
    let len = path.length()
    let buf = StringBuilder::new()
    let mut idx = 0
    for c in path {
      if idx < len - 1 {
        buf.write_char(c)
      }
      idx = idx + 1
    }
    buf.to_string()
  } else {
    path
  }
}

///|
/// Escape string for JSON
fn json_string(s : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("\"")
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(c)
    }
  }
  buf.write_string("\"")
  buf.to_string()
}

// =============================================================================
// Hierarchical Manifest Serialization (v2)
// =============================================================================

///|
/// Serialize HierarchicalManifest to JSON string
pub fn HierarchicalManifest::to_json(self : HierarchicalManifest) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")

  // version
  buf.write_string("  \"version\": ")
  buf.write_string(self.version.to_string())
  buf.write_string(",\n")

  // base
  buf.write_string("  \"base\": ")
  buf.write_string(json_string(self.base))
  buf.write_string(",\n")

  // segments
  buf.write_string("  \"segments\": {\n")
  let segment_entries = self.segments.iter().collect()
  for i, entry in segment_entries {
    let (name, seg_ref) = entry
    buf.write_string("    ")
    buf.write_string(json_string(name))
    buf.write_string(": ")
    buf.write_string(seg_ref.to_json())
    if i < segment_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")

  // chunks
  buf.write_string("  \"chunks\": {\n")
  let chunk_entries = self.chunks.iter().collect()
  for i, entry in chunk_entries {
    let (name, path) = entry
    buf.write_string("    ")
    buf.write_string(json_string(name))
    buf.write_string(": ")
    buf.write_string(json_string(path))
    if i < chunk_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")

  // routes (inline)
  buf.write_string("  \"routes\": {\n")
  let route_entries = self.routes.iter().collect()
  for i, entry in route_entries {
    let (path, chunks) = entry
    buf.write_string("    ")
    buf.write_string(json_string(path))
    buf.write_string(": [")
    for j, chunk in chunks {
      buf.write_string(json_string(chunk))
      if j < chunks.length() - 1 {
        buf.write_string(", ")
      }
    }
    buf.write_string("]")
    if i < route_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  }\n")
  buf.write_string("}")
  buf.to_string()
}

///|
/// Serialize SegmentRef to JSON string
pub fn SegmentRef::to_json(self : SegmentRef) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{")
  buf.write_string("\"path\": ")
  buf.write_string(json_string(self.path))
  buf.write_string(", \"pattern\": ")
  buf.write_string(json_string(self.pattern))
  if self.spa {
    buf.write_string(", \"spa\": true")
  }
  if self.preload {
    buf.write_string(", \"preload\": true")
  }
  buf.write_string("}")
  buf.to_string()
}

///|
/// Serialize SegmentManifest to JSON string
pub fn SegmentManifest::to_json(self : SegmentManifest) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")

  // base
  buf.write_string("  \"base\": ")
  buf.write_string(json_string(self.base))
  buf.write_string(",\n")

  // routes
  buf.write_string("  \"routes\": {\n")
  let route_entries = self.routes.iter().collect()
  for i, entry in route_entries {
    let (path, chunks) = entry
    buf.write_string("    ")
    buf.write_string(json_string(path))
    buf.write_string(": [")
    for j, chunk in chunks {
      buf.write_string(json_string(chunk))
      if j < chunks.length() - 1 {
        buf.write_string(", ")
      }
    }
    buf.write_string("]")
    if i < route_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")

  // dynamic
  buf.write_string("  \"dynamic\": [\n")
  for i, pattern in self.dynamic {
    buf.write_string("    ")
    buf.write_string(pattern.to_json())
    if i < self.dynamic.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  ],\n")

  // fallback
  buf.write_string("  \"fallback\": ")
  buf.write_string(json_string(self.fallback))
  buf.write_string("\n")
  buf.write_string("}")
  buf.to_string()
}

///|
/// Serialize DynamicPattern to JSON string
pub fn DynamicPattern::to_json(self : DynamicPattern) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{")
  buf.write_string("\"pattern\": ")
  buf.write_string(json_string(self.pattern))
  buf.write_string(", \"regex\": ")
  buf.write_string(json_string(self.regex))
  buf.write_string(", \"params\": [")
  for i, param in self.params {
    buf.write_string(json_string(param))
    if i < self.params.length() - 1 {
      buf.write_string(", ")
    }
  }
  buf.write_string("]")
  if self.catch_all {
    buf.write_string(", \"catchAll\": true")
  }
  buf.write_string("}")
  buf.to_string()
}

// =============================================================================
// Helper for Building Manifest
// =============================================================================

///|
/// Build a complete chunk manifest from route manifest and build info
pub fn build_chunk_manifest(
  route_manifest : RouteManifest,
  chunk_files? : Array[(String, String)] = [],
  base? : String = "/_luna/",
) -> ChunkManifest {
  let chunk_hashes : Map[String, String] = {}

  // Register chunk file mappings
  for pair in chunk_files {
    let (name, file_path) = pair
    chunk_hashes[name] = file_path
  }
  let manifest = route_manifest_to_chunk_manifest(route_manifest, chunk_hashes~)
  ChunkManifest::{ ..manifest, base, }
}
