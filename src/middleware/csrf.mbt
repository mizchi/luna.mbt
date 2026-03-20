// CSRF Protection Middleware
//
// Modern CSRF protection based on:
// - Origin header validation (primary defense)
// - Fetch Metadata validation (Sec-Fetch-* headers)
// - Content-Type validation (for JSON APIs)
//
// Reference: https://blog.jxck.io/entries/2024-04-26/csrf.html
//
// Design principles:
// 1. Origin validation is the essential defense
// 2. SameSite Cookie is a secondary effect, not primary
// 3. Fetch Metadata provides additional context
// 4. CSRF tokens are optional second layer

// ============================================================================
// CSRF Configuration
// ============================================================================

///|
/// CSRF protection configuration
pub struct CsrfConfig {
  /// Allowed origins (required for cross-origin requests)
  allowed_origins : Array[String]
  /// Whether to check Fetch Metadata headers
  check_fetch_metadata : Bool
  /// Expected Content-Type for API requests (e.g., "application/json")
  expected_content_type : String?
  /// Whether to allow requests without Origin header (same-origin)
  allow_no_origin : Bool
  /// Custom error message
  error_message : String
}

///|
/// Default CSRF configuration (strict)
pub fn CsrfConfig::default() -> CsrfConfig {
  {
    allowed_origins: [],
    check_fetch_metadata: true,
    expected_content_type: None,
    allow_no_origin: true, // Same-origin requests don't send Origin
    error_message: "Forbidden",
  }
}

///|
/// Create config for single origin
pub fn CsrfConfig::for_origin(origin : String) -> CsrfConfig {
  { ..CsrfConfig::default(), allowed_origins: [origin] }
}

///|
/// Create config for multiple origins
pub fn CsrfConfig::for_origins(origins : Array[String]) -> CsrfConfig {
  { ..CsrfConfig::default(), allowed_origins: origins }
}

///|
/// Set allowed origins
pub fn CsrfConfig::with_origins(
  self : CsrfConfig,
  origins : Array[String],
) -> CsrfConfig {
  { ..self, allowed_origins: origins }
}

///|
/// Add single allowed origin
pub fn CsrfConfig::with_origin(
  self : CsrfConfig,
  origin : String,
) -> CsrfConfig {
  let origins = self.allowed_origins.copy()
  origins.push(origin)
  { ..self, allowed_origins: origins }
}

///|
/// Enable/disable Fetch Metadata check
pub fn CsrfConfig::with_fetch_metadata(
  self : CsrfConfig,
  enabled : Bool,
) -> CsrfConfig {
  { ..self, check_fetch_metadata: enabled }
}

///|
/// Set expected Content-Type
pub fn CsrfConfig::with_content_type(
  self : CsrfConfig,
  content_type : String,
) -> CsrfConfig {
  { ..self, expected_content_type: Some(content_type) }
}

///|
/// Set JSON Content-Type requirement
pub fn CsrfConfig::require_json(self : CsrfConfig) -> CsrfConfig {
  self.with_content_type("application/json")
}

///|
/// Set custom error message
pub fn CsrfConfig::with_error_message(
  self : CsrfConfig,
  message : String,
) -> CsrfConfig {
  { ..self, error_message: message }
}

// ============================================================================
// CSRF Result Types
// ============================================================================

///|
/// CSRF validation result
pub enum CsrfResult {
  /// Validation passed
  Valid
  /// Origin header missing but allowed (same-origin)
  ValidNoOrigin
  /// Origin header valid
  ValidOrigin(String)
  /// Validation failed with reason
  Invalid(CsrfError)
}

///|
/// CSRF validation error types
pub enum CsrfError {
  /// Origin header missing and not allowed
  MissingOrigin
  /// Origin not in allowed list
  InvalidOrigin(String)
  /// Sec-Fetch-Site indicates cross-site
  CrossSiteFetch
  /// Sec-Fetch-Mode indicates unsafe mode
  UnsafeFetchMode
  /// Content-Type mismatch
  InvalidContentType(String)
}

///|
pub fn CsrfError::to_string(self : CsrfError) -> String {
  match self {
    MissingOrigin => "Missing Origin header"
    InvalidOrigin(origin) => "Invalid Origin: \{origin}"
    CrossSiteFetch => "Cross-site fetch not allowed"
    UnsafeFetchMode => "Unsafe fetch mode"
    InvalidContentType(ct) => "Invalid Content-Type: \{ct}"
  }
}

// ============================================================================
// CSRF Middleware
// ============================================================================

///|
/// Create CSRF protection middleware with default config
/// Note: You must configure allowed origins for this to work properly
pub fn csrf() -> Middleware {
  csrf_with_config(CsrfConfig::default())
}

///|
/// Create CSRF protection middleware for single origin
pub fn csrf_for_origin(origin : String) -> Middleware {
  csrf_with_config(CsrfConfig::for_origin(origin))
}

///|
/// Create CSRF protection middleware with custom config
pub fn csrf_with_config(config : CsrfConfig) -> Middleware {
  Middleware(
    @mars.Handler(async fn(ctx) {
      // Skip safe methods (GET, HEAD, OPTIONS)
      if is_safe_method(ctx.meth().to_string()) {
        return // Continue
      }

      // Validate CSRF
      match validate_csrf(ctx, config) {
        Valid | ValidNoOrigin | ValidOrigin(_) => () // Continue
        Invalid(error) => {
          // Log error internally (don't expose details to client)
          let _ = error.to_string()
          ctx.text(config.error_message, status=403)
        }
      }
    }),
  )
}

// ============================================================================
// Validation Logic
// ============================================================================

///|
/// Validate CSRF protection (delegates to pure functions)
fn validate_csrf(ctx : Ctx, config : CsrfConfig) -> CsrfResult {
  let origin = ctx.header("Origin")
  let referer = ctx.header("Referer")
  let sec_fetch_site = ctx.header("Sec-Fetch-Site")
  let content_type = ctx.header("Content-Type")
  validate_csrf_pure(
    origin~,
    referer~,
    sec_fetch_site~,
    content_type~,
    config~,
  )
}

///|
/// Pure CSRF validation — no IO dependencies, fully testable
fn validate_csrf_pure(
  origin~ : String?,
  referer~ : String?,
  sec_fetch_site~ : String?,
  content_type~ : String?,
  config~ : CsrfConfig,
) -> CsrfResult {
  // Layer 1: Origin header validation (most important)
  let origin_result = validate_origin_pure(
    origin~,
    referer~,
    allowed_origins=config.allowed_origins,
    allow_no_origin=config.allow_no_origin,
  )
  match origin_result {
    Invalid(_) as err => return err
    _ => ()
  }

  // Layer 2: Fetch Metadata validation (if enabled)
  if config.check_fetch_metadata {
    let fetch_result = validate_fetch_metadata_pure(sec_fetch_site)
    match fetch_result {
      Invalid(_) as err => return err
      _ => ()
    }
  }

  // Layer 3: Content-Type validation (if configured)
  match config.expected_content_type {
    Some(expected) => {
      let ct_result = validate_content_type_pure(content_type, expected)
      match ct_result {
        Invalid(_) as err => return err
        _ => ()
      }
    }
    None => ()
  }
  origin_result
}

///|
/// Pure Origin validation — testable without Ctx
fn validate_origin_pure(
  origin~ : String?,
  referer~ : String?,
  allowed_origins~ : Array[String],
  allow_no_origin~ : Bool,
) -> CsrfResult {
  match origin {
    None =>
      if allow_no_origin {
        match referer {
          Some(referer) =>
            if is_referer_allowed(referer, allowed_origins) {
              ValidNoOrigin
            } else if allowed_origins.is_empty() {
              ValidNoOrigin
            } else {
              Invalid(InvalidOrigin(referer))
            }
          None => ValidNoOrigin
        }
      } else {
        Invalid(MissingOrigin)
      }
    Some(origin) =>
      if allowed_origins.is_empty() {
        Invalid(InvalidOrigin(origin))
      } else if allowed_origins.contains(origin) {
        ValidOrigin(origin)
      } else {
        Invalid(InvalidOrigin(origin))
      }
  }
}

///|
/// Check if Referer matches any allowed origin
/// SECURITY: Extract origin from Referer URL and compare exactly
/// (Previous implementation used has_prefix which was vulnerable to
///  attacks like http://allowed-origin.attacker.com)
pub fn is_referer_allowed(
  referer : String,
  allowed_origins : Array[String],
) -> Bool {
  // Extract origin from Referer URL
  // Referer format: scheme://host[:port]/path
  let referer_origin = extract_origin_from_url(referer)
  match referer_origin {
    Some(origin) => allowed_origins.contains(origin)
    None => false
  }
}

///|
/// Extract origin (scheme://host[:port]) from a URL
/// Returns None if URL is malformed
pub fn extract_origin_from_url(url : String) -> String? {
  // Find scheme separator
  let scheme_sep = match url.find("://") {
    Some(idx) => idx
    None => return None
  }

  // Find path separator after scheme
  let after_scheme = scheme_sep + 3
  guard after_scheme < url.length() else { return None }

  // Find end of host:port (first "/" after scheme://)
  let rest = url.unsafe_substring(start=after_scheme, end=url.length())
  let origin = match rest.find("/") {
    Some(path_sep) => url.unsafe_substring(start=0, end=after_scheme + path_sep)
    None => url // No path - entire URL is the origin
  }
  Some(origin)
}

///|
/// Validate Fetch Metadata headers (delegates to pure function)
fn validate_fetch_metadata(ctx : Ctx) -> CsrfResult {
  validate_fetch_metadata_pure(ctx.header("Sec-Fetch-Site"))
}

///|
/// Pure Fetch Metadata validation — testable without Ctx
fn validate_fetch_metadata_pure(sec_fetch_site : String?) -> CsrfResult {
  match sec_fetch_site {
    Some("cross-site") => Invalid(CrossSiteFetch)
    Some("same-origin") | Some("same-site") | Some("none") => Valid
    None => Valid
    Some(_) => Valid
  }
}

///|
/// Validate Content-Type header (delegates to pure function)
fn validate_content_type(ctx : Ctx, expected : String) -> CsrfResult {
  validate_content_type_pure(ctx.header("Content-Type"), expected)
}

///|
/// Pure Content-Type validation — testable without Ctx
fn validate_content_type_pure(
  content_type : String?,
  expected : String,
) -> CsrfResult {
  match content_type {
    Some(ct) =>
      if ct.has_prefix(expected) {
        Valid
      } else {
        Invalid(InvalidContentType(ct))
      }
    None => Invalid(InvalidContentType("(none)"))
  }
}

// ============================================================================
// Origin Validation Middleware (Standalone)
// ============================================================================

///|
/// Simple Origin-only validation middleware
/// Use this for simpler use cases where Fetch Metadata isn't needed
pub fn validate_origin_middleware(
  allowed_origins : Array[String],
) -> Middleware {
  Middleware(
    @mars.Handler(async fn(ctx) {
      // Skip safe methods
      if is_safe_method(ctx.meth().to_string()) {
        return // Continue
      }
      let origin = ctx.header("Origin")
      match origin {
        None => () // No Origin = same-origin, allow (continue)
        Some(o) =>
          if allowed_origins.contains(o) {
            () // Continue
          } else {
            ctx.text("Forbidden", status=403)
          }
      }
    }),
  )
}

// ============================================================================
// Fetch Metadata Middleware (Standalone)
// ============================================================================

///|
/// Fetch Metadata validation middleware
/// Blocks requests with Sec-Fetch-Site: cross-site
pub fn fetch_metadata() -> Middleware {
  Middleware(
    @mars.Handler(async fn(ctx) {
      // Skip safe methods
      if is_safe_method(ctx.meth().to_string()) {
        return // Continue
      }
      match validate_fetch_metadata(ctx) {
        Valid | ValidNoOrigin | ValidOrigin(_) => () // Continue
        Invalid(_) => ctx.text("Forbidden", status=403)
      }
    }),
  )
}

// ============================================================================
// Content-Type Middleware (Standalone)
// ============================================================================

///|
/// Require specific Content-Type for mutations
pub fn require_content_type(content_type : String) -> Middleware {
  Middleware(
    @mars.Handler(async fn(ctx) {
      // Skip safe methods
      if is_safe_method(ctx.meth().to_string()) {
        return // Continue
      }
      match validate_content_type(ctx, content_type) {
        Valid | ValidNoOrigin | ValidOrigin(_) => () // Continue
        Invalid(_) => ctx.text("Invalid Content-Type", status=400)
      }
    }),
  )
}

///|
/// Require JSON Content-Type for mutations
pub fn require_json_content_type() -> Middleware {
  require_content_type("application/json")
}
