// Sol Routes - Server-side route definitions with typed handlers
//
// This is a Sol-specific route type that directly takes handler functions
// instead of component ID strings. For server-side rendering only.

// ============================================================================
// ISR In-Flight Deduplication
// ============================================================================

///|
/// Tracks cache keys with in-flight STALE revalidation to prevent duplicate renders.
let isr_in_flight : Ref[Set[String]] = Ref::new(Set::new())

// ============================================================================
// Handler Types
// ============================================================================

///|
/// Page handler type - async function that receives PageProps and returns ServerNode
pub(all) struct PageHandler(async (PageProps) -> @server_dom.ServerNode)

///|
/// API handler type - async function that receives PageProps and returns Json response.
/// Uses MoonBit's built-in Json type for wasm/native compatibility.
pub(all) struct ApiHandler(async (PageProps) -> Json)

// ============================================================================
// Cache Strategy
// ============================================================================

///|
/// Cache strategy for CSR navigation
/// Controls how the client handles navigation to the same page
pub(all) enum CacheStrategy {
  /// Always fetch from server (default)
  /// Each navigation triggers a fresh server request
  AlwaysFetch
  /// Stale-While-Revalidate
  /// Shows cached content immediately, then fetches and updates in background
  StaleWhileRevalidate
} derive(Eq, Show)

///|
/// Default cache strategy is AlwaysFetch
pub fn CacheStrategy::default() -> CacheStrategy {
  CacheStrategy::AlwaysFetch
}

// ============================================================================
// Sol Routes Definition
// ============================================================================

///|
/// Sol route definition with typed handlers
pub(all) enum SolRoutes {
  /// Page route with async handler
  /// - path: URL pattern (e.g., "/", "/user/:id")
  /// - handler: Async function that returns ServerNode
  /// - title: Page title
  /// - meta: Meta information
  /// - revalidate: ISR revalidation interval in seconds (None = no caching)
  /// - cache: CSR cache strategy (default: AlwaysFetch)
  Page(
    path~ : String,
    handler~ : PageHandler,
    title~ : String,
    meta~ : Array[(String, String)],
    revalidate~ : Int?,
    cache~ : CacheStrategy?
  )
  /// Layout wrapper for nested routes
  /// - segment: Path segment (e.g., "/admin")
  /// - layout: Layout handler that wraps children
  /// - children: Nested routes
  Layout(
    segment~ : String,
    layout~ : (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
    children~ : Array[SolRoutes]
  )
  /// GET API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Get(path~ : String, handler~ : ApiHandler)
  /// POST API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Post(path~ : String, handler~ : ApiHandler)
  /// PUT API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Put(path~ : String, handler~ : ApiHandler)
  /// DELETE API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Delete(path~ : String, handler~ : ApiHandler)
  /// PATCH API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Patch(path~ : String, handler~ : ApiHandler)
  /// Middleware wrapper for route groups
  /// - middleware: Array of middlewares to apply
  /// - children: Nested routes
  WithMiddleware(
    middleware~ : Array[@middleware.Middleware],
    children~ : Array[SolRoutes]
  )
  /// Asset wrapper for route groups
  /// - styles: CSS assets to inject for children
  /// - scripts: client module scripts to inject for children
  /// - children: Nested routes
  WithAssets(
    styles~ : Array[String],
    scripts~ : Array[String],
    children~ : Array[SolRoutes]
  )
}

// ============================================================================
// Compiled Routes
// ============================================================================

///|
/// Catch-all parameter info
pub(all) struct CatchAllInfo {
  /// Parameter name (e.g., "slug")
  name : String
  /// Whether it's optional ([[...slug]] = true)
  optional : Bool
}

///|
/// Compiled route for efficient matching
pub struct CompiledSolRoute {
  /// Full path pattern
  pattern : String
  /// Parameter names extracted from path
  param_names : Array[String]
  /// Page handler (if page route)
  page_handler : PageHandler?
  /// API handler (if API route)
  api_handler : ApiHandler?
  /// Layout handlers (from outermost to innermost)
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ]
  /// Middleware chain (from outermost to innermost)
  middlewares : Array[@middleware.Middleware]
  /// Route kind
  kind : SolRouteKind
  /// Page title (raw)
  title : String
  /// Meta information (raw)
  meta : Array[(String, String)]
  /// Catch-all parameter info (for [...slug] or [[...slug]])
  catch_all : CatchAllInfo?
  /// ISR revalidation interval in seconds (None = no caching)
  revalidate : Int?
  /// CSR cache strategy
  cache_strategy : CacheStrategy
  /// Pre-rendered meta HTML (computed once at route registration)
  rendered_meta : String
  /// Stylesheet assets inherited by this route
  styles : Array[String]
  /// Client module script assets inherited by this route
  scripts : Array[String]
}

///|
/// Route kind
pub enum SolRouteKind {
  Page
  GetApi
  PostApi
  PutApi
  DeleteApi
  PatchApi
} derive(Eq, Show)

// ============================================================================
// Static Directory (SSG Integration)
// ============================================================================

///|
/// Configuration for static directory generation (minimal, backend-independent)
pub(all) struct StaticDirConfig {
  /// Internationalization configuration
  i18n : @astra.I18nConfig
  /// Navigation configuration (SPA, View Transitions, Keyboard)
  navigation : @astra.NavigationConfig
  /// Directories to exclude from scanning
  exclude : Array[String]
  /// Use trailing slash in URLs
  trailing_slash : Bool
}

///|
/// Default static directory configuration
pub fn StaticDirConfig::default() -> StaticDirConfig {
  {
    i18n: @astra.I18nConfig::default(),
    navigation: @astra.NavigationConfig::default(),
    exclude: [],
    trailing_slash: true,
  }
}

///|
/// Static directory route definition
pub(all) struct StaticDir {
  /// URL path prefix (e.g., "/docs")
  path_prefix : String
  /// Source directory containing markdown files (e.g., "docs")
  source_dir : String
  /// Section title
  title : String
  /// SSG configuration
  config : StaticDirConfig
}

///|
/// Log server error to stderr without exposing details to client.
fn log_server_error(context : String, err : Error) -> Unit {
  ffi_console_error("[sol] \{context}: \{err}")
}
