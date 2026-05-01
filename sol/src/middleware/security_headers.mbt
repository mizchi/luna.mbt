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
    csp: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; connect-src 'self' ws: wss:; object-src 'none'; frame-ancestors 'self'",
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
pub fn security_headers_with_config(
  config : SecurityHeadersConfig,
) -> Middleware {
  let mars_options = to_mars_secure_headers_options(config)
  let @mars.Handler(base_handler) = @mars_mw.secure_headers(
    options=mars_options,
  )
  Middleware(
    @mars.Handler(async fn(ctx) {
      base_handler(ctx)

      // Sol-specific headers not covered by mars secure_headers
      if !(config.coop.is_empty()) {
        ctx.set_header("Cross-Origin-Opener-Policy", config.coop)
      }
      if !(config.coep.is_empty()) {
        ctx.set_header("Cross-Origin-Embedder-Policy", config.coep)
      }

      // Add Cache-Control based on content type
      let path = ctx.path()
      let cache_control = if is_static_asset(path) {
        config.cache_control_static
      } else {
        config.cache_control_html
      }
      ctx.set_header("Cache-Control", cache_control)
      // Continue to next handler
    }),
  )
}

///|
fn to_mars_secure_headers_options(
  config : SecurityHeadersConfig,
) -> @mars_mw.SecureHeadersOptions {
  {
    hsts: true,
    hsts_max_age: 31536000,
    hsts_include_subdomains: true,
    no_sniff: config.content_type_options == "nosniff",
    frame_options: config.frame_options,
    xss_protection: true,
    csp: config.csp,
    referrer_policy: config.referrer_policy,
    permissions_policy: config.permissions_policy,
  }
}

///|
fn minimal_secure_headers_options() -> @mars_mw.SecureHeadersOptions {
  {
    hsts: false,
    hsts_max_age: 0,
    hsts_include_subdomains: false,
    no_sniff: false,
    frame_options: "",
    xss_protection: false,
    csp: "",
    referrer_policy: "",
    permissions_policy: "",
  }
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
  let options = { ..minimal_secure_headers_options(), no_sniff: true }
  Middleware(@mars_mw.secure_headers(options~))
}

///|
/// Add X-Frame-Options header
pub fn frame_options(value : String) -> Middleware {
  let options = { ..minimal_secure_headers_options(), frame_options: value }
  Middleware(@mars_mw.secure_headers(options~))
}

///|
/// Add Content-Security-Policy header
pub fn csp(policy : String) -> Middleware {
  let options = { ..minimal_secure_headers_options(), csp: policy }
  Middleware(@mars_mw.secure_headers(options~))
}

///|
/// Add Referrer-Policy header
pub fn referrer_policy(value : String) -> Middleware {
  let options = { ..minimal_secure_headers_options(), referrer_policy: value }
  Middleware(@mars_mw.secure_headers(options~))
}

///|
/// Add Cache-Control header
pub fn cache_control(value : String) -> Middleware {
  Middleware(
    @mars.Handler(async fn(ctx) { ctx.set_header("Cache-Control", value) }),
  )
}
