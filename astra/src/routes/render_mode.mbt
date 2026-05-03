// Render Mode and Configuration Types
//
// Defines rendering modes and fallback configurations for routes.

// =============================================================================
// Render Mode
// =============================================================================

///|
/// Rendering mode for dynamic routes
pub(all) enum RenderMode {
  /// Server-side rendering (rendered on each request)
  Ssr
  /// Incremental Static Regeneration (cached with revalidation)
  Isr(revalidate~ : Int)
  /// SPA mode (client-side only)
  Spa
} derive(Eq, Show)

///|
/// Default render mode is SSR
pub fn RenderMode::default() -> RenderMode {
  RenderMode::Ssr
}

///|
/// Check if this mode requires a server
pub fn RenderMode::requires_server(self : RenderMode) -> Bool {
  match self {
    Ssr => true
    Isr(_) => true
    Spa => false
  }
}

///|
/// Get revalidation time if ISR mode
pub fn RenderMode::revalidate_seconds(self : RenderMode) -> Int? {
  match self {
    Isr(revalidate~) => Some(revalidate)
    _ => None
  }
}

// =============================================================================
// Fallback Configuration
// =============================================================================

///|
/// Fallback configuration for unmatched routes
pub(all) enum FallbackConfig {
  /// Return 404 page
  NotFound(path~ : String)
  /// Fallback to SPA entry point
  Spa(entry~ : String)
  /// Fallback to SPA for specific prefix only
  SpaPrefix(prefix~ : String, entry~ : String)
} derive(Eq, Show)

///|
/// Default fallback is 404
pub fn FallbackConfig::default() -> FallbackConfig {
  FallbackConfig::NotFound(path="/404.html")
}

///|
/// Check if this fallback is SPA-based
pub fn FallbackConfig::is_spa(self : FallbackConfig) -> Bool {
  match self {
    NotFound(_) => false
    Spa(_) => true
    SpaPrefix(_) => true
  }
}

///|
/// Get the entry point for SPA fallbacks
pub fn FallbackConfig::spa_entry(self : FallbackConfig) -> String? {
  match self {
    NotFound(_) => None
    Spa(entry~) => Some(entry)
    SpaPrefix(entry~, ..) => Some(entry)
  }
}

// =============================================================================
// HTTP Method
// =============================================================================

///|
/// HTTP methods for API routes
pub(all) enum HttpMethod {
  Get
  Post
  Put
  Delete
  Patch
  All
} derive(Eq, Show)

///|
/// Convert HTTP method to string
pub fn HttpMethod::to_string(self : HttpMethod) -> String {
  match self {
    Get => "GET"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Patch => "PATCH"
    All => "ALL"
  }
}

///|
/// Parse HTTP method from string
pub fn HttpMethod::from_string(s : String) -> HttpMethod? {
  match s.to_upper() {
    "GET" => Some(HttpMethod::Get)
    "POST" => Some(HttpMethod::Post)
    "PUT" => Some(HttpMethod::Put)
    "DELETE" => Some(HttpMethod::Delete)
    "PATCH" => Some(HttpMethod::Patch)
    "ALL" => Some(HttpMethod::All)
    _ => None
  }
}

// =============================================================================
// File Type
// =============================================================================

///|
/// Supported file types for pages
pub(all) enum FileType {
  /// MoonBit source file (.mbt)
  MoonBit
  /// Markdown file (.md)
  Markdown
  /// MDX file (.mdx)
  Mdx
  /// HTML file (.html)
  Html
  /// Unknown file type
  Unknown
} derive(Eq, Show)

///|
/// Detect file type from extension
pub fn FileType::from_extension(ext : String) -> FileType {
  match ext.to_lower() {
    ".mbt" => FileType::MoonBit
    ".md" => FileType::Markdown
    ".mdx" => FileType::Mdx
    ".html" | ".htm" => FileType::Html
    _ => FileType::Unknown
  }
}

///|
/// Check if this file type is renderable as a page
pub fn FileType::is_page(self : FileType) -> Bool {
  match self {
    MoonBit => true
    Markdown => true
    Mdx => true
    Html => true
    Unknown => false
  }
}
