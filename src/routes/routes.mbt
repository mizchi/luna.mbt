// Routes - Core route definitions (target-independent)
//
// This module provides the fundamental route definition types and
// matching logic that works across all targets (js, wasm-gc, native).
//

///|
/// Route definition - flat structure (supports URLPattern syntax)
pub(all) enum Routes {
  /// Server component page
  /// - path: path (e.g., "/", "/about", "/user/:id")
  ///   Dynamic parameters can be defined using URLPattern syntax
  /// - component: component ID (resolved by resolver)
  /// - title: page title
  /// - meta: meta information
  Page(
    path~ : String,
    component~ : String,
    title~ : String,
    meta~ : Array[(String, String)]
  )
  /// Path group (common prefix + layout)
  /// - segment: path segment (e.g., "/user", "/api")
  /// - children: child routes
  /// - layout: layout component ID
  Layout(segment~ : String, children~ : Array[Routes], layout~ : String)
  /// API route (GET)
  Get(path~ : String, handler~ : String)
  /// API route (POST)
  Post(path~ : String, handler~ : String)
}

///|
/// Compiled route (for matching)
pub struct CompiledRoutes {
  /// Full path pattern
  pattern : String
  /// List of parameter names (ordered)
  param_names : Array[String]
  /// Component ID
  component : String
  /// Applied layout IDs (in nested order)
  layouts : Array[String]
  /// Route kind
  kind : RoutesKind
  /// Title
  title : String
  /// Meta information
  meta : Array[(String, String)]
  /// Catch-all parameter info (trailing [...slug] or [[...slug]])
  catch_all : CatchAllInfo?
}

///|
/// Catch-all parameter info
pub(all) struct CatchAllInfo {
  /// Parameter name (e.g., "slug")
  name : String
  /// Whether optional ([[...slug]] is true)
  optional : Bool
}

///|
/// Route kind
pub enum RoutesKind {
  /// Server component page
  Page
  /// GET API
  GetApi
  /// POST API
  PostApi
} derive(Eq, Show)

///|
/// Match result
pub struct RoutesMatch {
  route : CompiledRoutes
  params : Array[(String, String)]
  query : Array[(String, String)]
  path : String
}
