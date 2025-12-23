// Security Headers Middleware
//
// Adds security headers to protect against common web attacks:
// - Clickjacking (X-Frame-Options, frame-ancestors)
// - MIME sniffing (X-Content-Type-Options)
// - XSS (Content-Security-Policy)
// - Spectre (Cross-Origin-Opener-Policy)
// - Information leakage (Referrer-Policy)
//
// Reference: OWASP Secure Headers Project
// https://owasp.org/www-project-secure-headers/

// ============================================================================
// Security Headers Configuration
// ============================================================================

///|
/// Security headers configuration
pub struct SecurityHeadersConfig {
  /// X-Frame-Options value (DENY, SAMEORIGIN)
  frame_options : String
  /// X-Content-Type-Options (nosniff)
  content_type_options : String
  /// Referrer-Policy value
  referrer_policy : String
  /// Cross-Origin-Opener-Policy value
  coop : String
  /// Cross-Origin-Embedder-Policy value
  coep : String
  /// Permissions-Policy directives
  permissions_policy : String
  /// Content-Security-Policy directives
  csp : String
  /// Cache-Control for HTML pages
  cache_control_html : String
  /// Cache-Control for static assets
  cache_control_static : String
}

///|
/// Default security headers configuration (strict)
pub fn SecurityHeadersConfig::default() -> SecurityHeadersConfig {
  {
    frame_options: "SAMEORIGIN",
    content_type_options: "nosniff",
    referrer_policy: "strict-origin-when-cross-origin",
    coop: "same-origin",
    coep: "require-corp",
    permissions_policy: "geolocation=(), microphone=(), camera=()",
    csp: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; object-src 'none'; frame-ancestors 'self'",
    cache_control_html: "no-cache, no-store, must-revalidate",
    cache_control_static: "public, max-age=31536000, immutable",
  }
}

///|
/// Relaxed configuration (for development or when strict CSP breaks things)
pub fn SecurityHeadersConfig::relaxed() -> SecurityHeadersConfig {
  {
    frame_options: "SAMEORIGIN",
    content_type_options: "nosniff",
    referrer_policy: "strict-origin-when-cross-origin",
    coop: "same-origin-allow-popups",
    coep: "unsafe-none",
    permissions_policy: "geolocation=(), microphone=(), camera=()",
    csp: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; object-src 'none'; frame-ancestors 'self'",
    cache_control_html: "private, no-cache",
    cache_control_static: "public, max-age=3600",
  }
}

///|
/// Set frame options
pub fn SecurityHeadersConfig::with_frame_options(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, frame_options: value }
}

///|
/// Set referrer policy
pub fn SecurityHeadersConfig::with_referrer_policy(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, referrer_policy: value }
}

///|
/// Set Cross-Origin-Opener-Policy
pub fn SecurityHeadersConfig::with_coop(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, coop: value }
}

///|
/// Set Cross-Origin-Embedder-Policy
pub fn SecurityHeadersConfig::with_coep(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, coep: value }
}

///|
/// Set Permissions-Policy
pub fn SecurityHeadersConfig::with_permissions_policy(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, permissions_policy: value }
}

///|
/// Set Content-Security-Policy
pub fn SecurityHeadersConfig::with_csp(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, csp: value }
}

///|
/// Set Cache-Control for HTML
pub fn SecurityHeadersConfig::with_cache_control_html(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, cache_control_html: value }
}

///|
/// Set Cache-Control for static assets
pub fn SecurityHeadersConfig::with_cache_control_static(
  self : SecurityHeadersConfig,
  value : String,
) -> SecurityHeadersConfig {
  { ..self, cache_control_static: value }
}

// ============================================================================
// Security Headers Middleware
// ============================================================================

///|
/// Create security headers middleware with default configuration
pub fn security_headers() -> Middleware {
  security_headers_with_config(SecurityHeadersConfig::default())
}

///|
/// Create security headers middleware with relaxed configuration
pub fn security_headers_relaxed() -> Middleware {
  security_headers_with_config(SecurityHeadersConfig::relaxed())
}

///|
/// Create security headers middleware with custom configuration
pub fn security_headers_with_config(config : SecurityHeadersConfig) -> Middleware {
  Middleware(async fn(ctx) {
    // Add security headers to context
    let new_ctx = ctx
      .add_header("X-Frame-Options", config.frame_options)
      .add_header("X-Content-Type-Options", config.content_type_options)
      .add_header("Referrer-Policy", config.referrer_policy)
      .add_header("Cross-Origin-Opener-Policy", config.coop)
      .add_header("Permissions-Policy", config.permissions_policy)
      .add_header("Content-Security-Policy", config.csp)

    // Add Cache-Control based on content type
    let path = ctx.request.path
    let cache_control = if is_static_asset(path) {
      config.cache_control_static
    } else {
      config.cache_control_html
    }
    let final_ctx = new_ctx.add_header("Cache-Control", cache_control)

    Continue(final_ctx)
  })
}

///|
/// Check if path is a static asset
fn is_static_asset(path : String) -> Bool {
  path.has_prefix("/static/") ||
    path.has_suffix(".js") ||
    path.has_suffix(".css") ||
    path.has_suffix(".png") ||
    path.has_suffix(".jpg") ||
    path.has_suffix(".svg") ||
    path.has_suffix(".woff") ||
    path.has_suffix(".woff2")
}

// ============================================================================
// Individual Header Middlewares
// ============================================================================

///|
/// Add X-Content-Type-Options: nosniff header
pub fn nosniff() -> Middleware {
  Middleware(async fn(ctx) {
    Continue(ctx.add_header("X-Content-Type-Options", "nosniff"))
  })
}

///|
/// Add X-Frame-Options header
pub fn frame_options(value : String) -> Middleware {
  Middleware(async fn(ctx) { Continue(ctx.add_header("X-Frame-Options", value)) })
}

///|
/// Add Content-Security-Policy header
pub fn csp(policy : String) -> Middleware {
  Middleware(async fn(ctx) {
    Continue(ctx.add_header("Content-Security-Policy", policy))
  })
}

///|
/// Add Referrer-Policy header
pub fn referrer_policy(value : String) -> Middleware {
  Middleware(async fn(ctx) {
    Continue(ctx.add_header("Referrer-Policy", value))
  })
}

///|
/// Add Cache-Control header
pub fn cache_control(value : String) -> Middleware {
  Middleware(async fn(ctx) { Continue(ctx.add_header("Cache-Control", value)) })
}
