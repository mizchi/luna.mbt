// Route Manifest - Implementation-independent route representation
//
// This module provides a unified intermediate representation for routes
// that can be used by both Astra (SSG) and Sol (SSR).

// =============================================================================
// Core Types
// =============================================================================

///|
/// The route manifest contains all routes and fallback configuration
pub(all) struct RouteManifest {
  /// All route entries
  routes : Array[RouteEntry]
  /// Fallback configuration for unmatched routes
  fallback : FallbackConfig
}

///|
/// Create an empty route manifest
pub fn RouteManifest::empty() -> RouteManifest {
  { routes: [], fallback: FallbackConfig::NotFound(path="/404.html") }
}

///|
/// A single route entry - can be static, dynamic, API, or component
pub(all) enum RouteEntry {
  /// Static page (HTML generated at build time)
  Static(StaticRouteEntry)
  /// Dynamic page (generated at request time)
  Dynamic(DynamicRouteEntry)
  /// API endpoint
  Api(ApiRouteEntry)
  /// SSR Component (moon.pkg.json directory with client/server)
  Component(ComponentRouteEntry)
}

// =============================================================================
// Static Route
// =============================================================================

///|
/// A static route that is pre-rendered at build time
pub(all) struct StaticRouteEntry {
  /// URL path (e.g., "/about")
  path : String
  /// Source file path relative to pages directory (e.g., "about/index.mbt")
  source : String
  /// Output file path (e.g., "about/index.html")
  output : String
  /// Layout identifier
  layout : String?
  /// Page title
  title : String?
  /// Page description
  description : String?
  /// Islands to hydrate on client
  islands : Array[String]
  /// Locale code
  locale : String
  /// Generated parameters for dynamic static pages
  generated_params : Array[Map[String, String]]
}

///|
/// Create a static route entry with minimal required fields
pub fn StaticRouteEntry::new(
  path~ : String,
  source~ : String,
  output~ : String,
) -> StaticRouteEntry {
  {
    path,
    source,
    output,
    layout: None,
    title: None,
    description: None,
    islands: [],
    locale: "en",
    generated_params: [],
  }
}

// =============================================================================
// Dynamic Route
// =============================================================================

///|
/// A dynamic route that is rendered at request time
pub(all) struct DynamicRouteEntry {
  /// Path pattern (e.g., "/blog/:slug")
  path : String
  /// Regex pattern for matching
  pattern : String
  /// Extracted parameter names
  param_names : Array[String]
  /// Source file path
  source : String
  /// Rendering mode (SSR or ISR)
  mode : RenderMode
  /// Layout identifier
  layout : String?
  /// Catch-all information if applicable
  catch_all : CatchAllInfo?
  /// Page title template
  title : String?
  /// Islands to hydrate
  islands : Array[String]
}

///|
/// Create a dynamic route entry
pub fn DynamicRouteEntry::new(
  path~ : String,
  pattern~ : String,
  param_names~ : Array[String],
  source~ : String,
  mode~ : RenderMode,
) -> DynamicRouteEntry {
  {
    path,
    pattern,
    param_names,
    source,
    mode,
    layout: None,
    catch_all: None,
    title: None,
    islands: [],
  }
}

///|
/// Information about catch-all segments
pub(all) struct CatchAllInfo {
  /// Parameter name
  name : String
  /// Whether it's optional (matches zero or more segments)
  optional : Bool
}

// =============================================================================
// API Route
// =============================================================================

///|
/// An API route endpoint
pub(all) struct ApiRouteEntry {
  /// Path pattern (e.g., "/api/posts/:id")
  path : String
  /// Regex pattern for matching
  pattern : String
  /// Extracted parameter names
  param_names : Array[String]
  /// HTTP method
  http_method : HttpMethod
  /// Source file path
  source : String
}

///|
/// Create an API route entry
pub fn ApiRouteEntry::new(
  path~ : String,
  pattern~ : String,
  http_method~ : HttpMethod,
  source~ : String,
) -> ApiRouteEntry {
  { path, pattern, param_names: [], http_method, source }
}

// =============================================================================
// Component Route (SSR + Hydration)
// =============================================================================

///|
/// Component type based on directory structure
pub(all) enum ComponentType {
  /// client/ + server/ → SSR + Hydration
  SsrComponent
  /// client/ only → Hydration only (no server-side HTML)
  ClientOnlyComponent
  /// server/ only → SSR only (no hydration)
  ServerOnlyComponent
} derive(Show)

///|
/// A component route entry for moon.pkg.json directories
pub(all) struct ComponentRouteEntry {
  /// URL path (e.g., "/counter")
  path : String
  /// Source directory path relative to pages (e.g., "counter/")
  source : String
  /// Component type (SSR, client-only, server-only)
  component_type : ComponentType
  /// Rendering mode
  mode : RenderMode
  /// Layout identifier
  layout : String?
  /// Props type name (e.g., "CounterProps")
  props_type : String?
  /// Client export function name (e.g., "counter")
  client_export : String?
  /// Server export function name (e.g., "render_ssr")
  server_export : String?
  /// Pre-generated static paths from staticParams
  static_paths : Array[StaticPathEntry]
  /// Islands to hydrate
  islands : Array[String]
}

///|
/// A static path entry generated from staticParams
pub(all) struct StaticPathEntry {
  /// Parameter values (e.g., {"id": "1", "name": "foo"})
  params : Map[String, String]
  /// Output file path (e.g., "counter/1/index.html")
  output : String
}

///|
/// Create a component route entry
pub fn ComponentRouteEntry::new(
  path~ : String,
  source~ : String,
  component_type~ : ComponentType,
  mode~ : RenderMode,
) -> ComponentRouteEntry {
  {
    path,
    source,
    component_type,
    mode,
    layout: None,
    props_type: None,
    client_export: None,
    server_export: None,
    static_paths: [],
    islands: [],
  }
}

///|
/// Create a static path entry
pub fn StaticPathEntry::new(
  params~ : Map[String, String],
  output~ : String,
) -> StaticPathEntry {
  { params, output }
}

///|
/// Check if this component can be server-rendered
pub fn ComponentType::can_ssr(self : ComponentType) -> Bool {
  match self {
    SsrComponent | ServerOnlyComponent => true
    ClientOnlyComponent => false
  }
}

///|
/// Check if this component can be hydrated
pub fn ComponentType::can_hydrate(self : ComponentType) -> Bool {
  match self {
    SsrComponent | ClientOnlyComponent => true
    ServerOnlyComponent => false
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Get the path from a route entry
pub fn RouteEntry::path(self : RouteEntry) -> String {
  match self {
    Static(r) => r.path
    Dynamic(r) => r.path
    Api(r) => r.path
    Component(r) => r.path
  }
}

///|
/// Get the source from a route entry
pub fn RouteEntry::source(self : RouteEntry) -> String {
  match self {
    Static(r) => r.source
    Dynamic(r) => r.source
    Api(r) => r.source
    Component(r) => r.source
  }
}

///|
/// Check if this is a static route
pub fn RouteEntry::is_static(self : RouteEntry) -> Bool {
  match self {
    Static(_) => true
    _ => false
  }
}

///|
/// Check if this is a dynamic route
pub fn RouteEntry::is_dynamic(self : RouteEntry) -> Bool {
  match self {
    Dynamic(_) => true
    _ => false
  }
}

///|
/// Check if this is an API route
pub fn RouteEntry::is_api(self : RouteEntry) -> Bool {
  match self {
    Api(_) => true
    _ => false
  }
}

///|
/// Check if this is a component route
pub fn RouteEntry::is_component(self : RouteEntry) -> Bool {
  match self {
    Component(_) => true
    _ => false
  }
}

// =============================================================================
// Hierarchical Manifest Types (v2)
// =============================================================================

///|
/// Hierarchical manifest for lazy loading route definitions by segment
pub(all) struct HierarchicalManifest {
  /// Manifest version (2 for hierarchical)
  version : Int
  /// Base path for chunk loading (e.g., "/_luna/")
  base : String
  /// Segment references for lazy loading
  segments : Map[String, SegmentRef]
  /// Global chunk mappings
  chunks : Map[String, String]
  /// Inline routes for root-level pages
  routes : Map[String, Array[String]]
}

///|
/// Reference to a segment manifest for lazy loading
pub(all) struct SegmentRef {
  /// Path to the segment manifest file (e.g., "routes/docs.json")
  path : String
  /// URL pattern for matching (e.g., "/docs/*")
  pattern : String
  /// Whether this segment enables SPA mode
  spa : Bool
  /// Whether to preload this segment
  preload : Bool
}

///|
/// Segment manifest containing routes for a specific path prefix
pub(all) struct SegmentManifest {
  /// Base path for this segment (e.g., "/docs")
  base : String
  /// Routes within this segment
  routes : Map[String, Array[String]]
  /// Dynamic route patterns
  dynamic : Array[DynamicPattern]
  /// Fallback behavior ("spa" or "404")
  fallback : String
}

///|
/// Dynamic route pattern for client-side matching
pub(all) struct DynamicPattern {
  /// Path pattern (e.g., "/:slug")
  pattern : String
  /// Regex for matching (e.g., "^/blog/([^/]+)$")
  regex : String
  /// Parameter names extracted from pattern
  params : Array[String]
  /// Whether this is a catch-all pattern
  catch_all : Bool
}

///|
/// Create an empty hierarchical manifest
pub fn HierarchicalManifest::empty() -> HierarchicalManifest {
  { version: 2, base: "/_luna/", segments: {}, chunks: {}, routes: {} }
}

///|
/// Create a new hierarchical manifest
pub fn HierarchicalManifest::new(
  base? : String = "/_luna/",
) -> HierarchicalManifest {
  { version: 2, base, segments: {}, chunks: {}, routes: {} }
}

///|
/// Create a segment reference
pub fn SegmentRef::new(
  path~ : String,
  pattern~ : String,
  spa? : Bool = false,
  preload? : Bool = false,
) -> SegmentRef {
  { path, pattern, spa, preload }
}

///|
/// Create an empty segment manifest
pub fn SegmentManifest::empty(base : String) -> SegmentManifest {
  { base, routes: {}, dynamic: [], fallback: "404" }
}

///|
/// Create a dynamic pattern
pub fn DynamicPattern::new(
  pattern~ : String,
  regex~ : String,
  params~ : Array[String],
  catch_all? : Bool = false,
) -> DynamicPattern {
  { pattern, regex, params, catch_all }
}
