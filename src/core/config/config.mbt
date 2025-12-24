// Luna Configuration (luna.config.json)
//
// Defines the configuration schema for luna.config.json files.

// =============================================================================
// Luna Config
// =============================================================================

///|
/// Project-level configuration from luna.config.json
pub(all) struct LunaConfig {
  /// Output mode: "static" | "hybrid" | "server"
  output : OutputMode
  /// Routing configuration
  routing : RoutingConfig
  /// Layouts directory
  layouts : String
  /// Public assets directory
  public_dir : String
  /// Output directory
  out_dir : String
  /// Build configuration
  build : BuildConfig
  /// Dev server configuration
  dev : DevConfig
  /// Navigation configuration
  navigation : NavigationConfig
  /// Performance configuration
  performance : PerformanceConfig
}

// =============================================================================
// Output Mode
// =============================================================================

///|
/// Output mode for the project
pub(all) enum OutputMode {
  /// Pure static site (no server needed)
  Static
  /// Hybrid: some static, some dynamic
  Hybrid
  /// Full server-side rendering
  Server
} derive(Eq, Show)

// =============================================================================
// Routing Config
// =============================================================================

///|
/// Routing configuration
pub(all) struct RoutingConfig {
  /// Routing mode: "file-based" | "explicit" | "hybrid"
  mode : RoutingMode
  /// Pages directory (for file-based routing)
  pages : String
  /// Explicit routes file (for explicit routing)
  explicit : String?
}

///|
/// Routing mode
pub(all) enum RoutingMode {
  /// File-based routing only
  FileBased
  /// Explicit routing only
  Explicit
  /// Both file-based and explicit (explicit takes priority)
  Hybrid
} derive(Eq, Show)

// =============================================================================
// Build Config
// =============================================================================

///|
/// Build configuration
pub(all) struct BuildConfig {
  /// Enable minification
  minify : Bool
  /// Generate source maps
  sourcemap : Bool
}

// =============================================================================
// Dev Config
// =============================================================================

///|
/// Development server configuration
pub(all) struct DevConfig {
  /// Port number
  port : Int
  /// Enable HMR (Hot Module Replacement)
  hmr : Bool
}

// =============================================================================
// Navigation Config
// =============================================================================

///|
/// Client navigation configuration
pub(all) struct NavigationConfig {
  /// Navigation strategy: "simple" | "hybrid" | "unified"
  strategy : NavigationStrategy
  /// Enable prefetch on link hover
  prefetch : Bool
  /// Enable scroll position restoration
  scroll_restoration : Bool
}

///|
/// Navigation strategy for client-side transitions
pub(all) enum NavigationStrategy {
  /// Simple: full page reload for cross-mode transitions
  Simple
  /// Hybrid: fetch + swap for static/SSR, reload for SPA boundaries
  Hybrid
  /// Unified: full SPA router managing all routes
  Unified
} derive(Eq, Show)

// =============================================================================
// Performance Config
// =============================================================================

///|
/// Performance optimization configuration
pub(all) struct PerformanceConfig {
  /// Inline JS if smaller than this threshold (bytes)
  inline_threshold : Int
  /// Prefetch strategy: "hover" | "visible" | "none"
  prefetch : PrefetchStrategy
  /// Enable lazy loading for islands by default
  lazy_islands : Bool
  /// Use <link rel="modulepreload">
  module_preload : Bool
  /// Bundler to use: "rolldown" | "esbuild"
  bundler : Bundler
}

///|
/// Prefetch strategy for links
pub(all) enum PrefetchStrategy {
  /// Prefetch on hover
  Hover
  /// Prefetch when visible in viewport
  Visible
  /// No prefetching
  None
} derive(Eq, Show)

///|
/// Bundler choice
pub(all) enum Bundler {
  Rolldown
  Esbuild
} derive(Eq, Show)

// =============================================================================
// Defaults
// =============================================================================

///|
/// Default luna config
pub fn LunaConfig::default() -> LunaConfig {
  {
    output: OutputMode::Static,
    routing: RoutingConfig::default(),
    layouts: "src/layouts",
    public_dir: "public",
    out_dir: "dist",
    build: BuildConfig::default(),
    dev: DevConfig::default(),
    navigation: NavigationConfig::default(),
    performance: PerformanceConfig::default(),
  }
}

///|
/// Default routing config
pub fn RoutingConfig::default() -> RoutingConfig {
  { mode: RoutingMode::FileBased, pages: "src/pages", explicit: None }
}

///|
/// Default build config
pub fn BuildConfig::default() -> BuildConfig {
  { minify: true, sourcemap: false }
}

///|
/// Default dev config
pub fn DevConfig::default() -> DevConfig {
  { port: 3000, hmr: true }
}

///|
/// Default navigation config
pub fn NavigationConfig::default() -> NavigationConfig {
  {
    strategy: NavigationStrategy::Simple,
    prefetch: true,
    scroll_restoration: true,
  }
}

///|
/// Default performance config
pub fn PerformanceConfig::default() -> PerformanceConfig {
  {
    inline_threshold: 1024,
    prefetch: PrefetchStrategy::Hover,
    lazy_islands: false,
    module_preload: true,
    bundler: Bundler::Rolldown,
  }
}

// =============================================================================
// Parsing
// =============================================================================

///|
/// Parse luna.config.json content
pub fn parse_luna_config(json_str : String) -> LunaConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    parse_luna_config_object(obj)
  } catch {
    _ => None
  }
}

///|
/// Parse luna config from JSON object
fn parse_luna_config_object(obj : Map[String, Json]) -> LunaConfig? {
  let output = parse_output_mode(obj)
  let routing = parse_routing_config(obj)
  let layouts = @json_utils.extract_string(obj, "layouts", "src/layouts")
  let public_dir = @json_utils.extract_string(obj, "public", "public")
  let out_dir = @json_utils.extract_string(obj, "outDir", "dist")
  let build = parse_build_config(obj)
  let dev = parse_dev_config(obj)
  let navigation = parse_navigation_config(obj)
  let performance = parse_performance_config(obj)
  Some(LunaConfig::{
    output,
    routing,
    layouts,
    public_dir,
    out_dir,
    build,
    dev,
    navigation,
    performance,
  })
}

///|
fn parse_output_mode(obj : Map[String, Json]) -> OutputMode {
  match @json_utils.extract_string_opt(obj, "output") {
    Some("static") => OutputMode::Static
    Some("hybrid") => OutputMode::Hybrid
    Some("server") => OutputMode::Server
    _ => OutputMode::Static
  }
}

///|
fn parse_routing_config(obj : Map[String, Json]) -> RoutingConfig {
  match obj.get("routing") {
    Some(Object(routing_obj)) => {
      let mode = match @json_utils.extract_string_opt(routing_obj, "mode") {
        Some("file-based") => RoutingMode::FileBased
        Some("explicit") => RoutingMode::Explicit
        Some("hybrid") => RoutingMode::Hybrid
        _ => RoutingMode::FileBased
      }
      let pages = @json_utils.extract_string(routing_obj, "pages", "src/pages")
      let explicit = @json_utils.extract_string_opt(routing_obj, "explicit")
      RoutingConfig::{ mode, pages, explicit }
    }
    _ => RoutingConfig::default()
  }
}

///|
fn parse_build_config(obj : Map[String, Json]) -> BuildConfig {
  match obj.get("build") {
    Some(Object(build_obj)) => {
      let minify = @json_utils.extract_bool(build_obj, "minify", true)
      let sourcemap = @json_utils.extract_bool(build_obj, "sourcemap", false)
      BuildConfig::{ minify, sourcemap }
    }
    _ => BuildConfig::default()
  }
}

///|
fn parse_dev_config(obj : Map[String, Json]) -> DevConfig {
  match obj.get("dev") {
    Some(Object(dev_obj)) => {
      let port = @json_utils.extract_int(dev_obj, "port", 3000)
      let hmr = @json_utils.extract_bool(dev_obj, "hmr", true)
      DevConfig::{ port, hmr }
    }
    _ => DevConfig::default()
  }
}

///|
fn parse_navigation_config(obj : Map[String, Json]) -> NavigationConfig {
  match obj.get("navigation") {
    Some(Object(nav_obj)) => {
      let strategy = match @json_utils.extract_string_opt(nav_obj, "strategy") {
        Some("simple") => NavigationStrategy::Simple
        Some("hybrid") => NavigationStrategy::Hybrid
        Some("unified") => NavigationStrategy::Unified
        _ => NavigationStrategy::Simple
      }
      let prefetch = @json_utils.extract_bool(nav_obj, "prefetch", true)
      let scroll_restoration = @json_utils.extract_bool(
        nav_obj, "scrollRestoration", true,
      )
      NavigationConfig::{ strategy, prefetch, scroll_restoration }
    }
    _ => NavigationConfig::default()
  }
}

///|
fn parse_performance_config(obj : Map[String, Json]) -> PerformanceConfig {
  match obj.get("performance") {
    Some(Object(perf_obj)) => {
      let inline_threshold = @json_utils.extract_int(
        perf_obj, "inlineThreshold", 1024,
      )
      let prefetch = match @json_utils.extract_string_opt(perf_obj, "prefetch") {
        Some("hover") => PrefetchStrategy::Hover
        Some("visible") => PrefetchStrategy::Visible
        Some("none") => PrefetchStrategy::None
        _ => PrefetchStrategy::Hover
      }
      let lazy_islands = @json_utils.extract_bool(perf_obj, "lazyIslands", false)
      let module_preload = @json_utils.extract_bool(
        perf_obj, "modulePreload", true,
      )
      let bundler = match @json_utils.extract_string_opt(perf_obj, "bundler") {
        Some("esbuild") => Bundler::Esbuild
        _ => Bundler::Rolldown
      }
      PerformanceConfig::{
        inline_threshold,
        prefetch,
        lazy_islands,
        module_preload,
        bundler,
      }
    }
    _ => PerformanceConfig::default()
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Check if output mode requires a server
pub fn OutputMode::requires_server(self : OutputMode) -> Bool {
  match self {
    Static => false
    Hybrid | Server => true
  }
}

///|
/// Check if this is file-based routing
pub fn RoutingMode::is_file_based(self : RoutingMode) -> Bool {
  match self {
    FileBased | Hybrid => true
    Explicit => false
  }
}

///|
/// Check if this uses explicit routing
pub fn RoutingMode::is_explicit(self : RoutingMode) -> Bool {
  match self {
    Explicit | Hybrid => true
    FileBased => false
  }
}
