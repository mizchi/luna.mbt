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
fn CsrfError::to_string(self : CsrfError) -> String {
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
  Middleware(async fn(ctx) {
    // Skip safe methods (GET, HEAD, OPTIONS)
    if is_safe_method(ctx.request.http_method) {
      return Continue(ctx)
    }

    // Validate CSRF
    match validate_csrf(ctx.request, config) {
      Valid | ValidNoOrigin | ValidOrigin(_) => Continue(ctx)
      Invalid(error) => {
        // Log error internally (don't expose details to client)
        let _ = error.to_string()
        Halt(MwResponse::forbidden(message=config.error_message))
      }
    }
  })
}

// ============================================================================
// Validation Logic
// ============================================================================

///|
/// Check if HTTP method is safe (no side effects)
fn is_safe_method(http_method : String) -> Bool {
  match http_method {
    "GET" | "HEAD" | "OPTIONS" => true
    _ => false
  }
}

///|
/// Validate CSRF protection
fn validate_csrf(request : MwRequest, config : CsrfConfig) -> CsrfResult {
  // Layer 1: Origin header validation (most important)
  let origin_result = validate_origin(request, config)
  match origin_result {
    Invalid(_) as err => return err
    _ => ()
  }

  // Layer 2: Fetch Metadata validation (if enabled)
  if config.check_fetch_metadata {
    let fetch_result = validate_fetch_metadata(request)
    match fetch_result {
      Invalid(_) as err => return err
      _ => ()
    }
  }

  // Layer 3: Content-Type validation (if configured)
  match config.expected_content_type {
    Some(expected) => {
      let ct_result = validate_content_type(request, expected)
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
/// Validate Origin header
fn validate_origin(request : MwRequest, config : CsrfConfig) -> CsrfResult {
  let origin = request.get_header("Origin")
  match origin {
    None =>
      // No Origin header - could be same-origin request
      // Check Referer as fallback
      if config.allow_no_origin {
        // Optionally validate Referer
        match request.get_header("Referer") {
          Some(referer) =>
            // Referer present - validate it matches allowed origins
            if is_referer_allowed(referer, config.allowed_origins) {
              ValidNoOrigin
            } else if config.allowed_origins.is_empty() {
              // No origins configured - allow same-origin
              ValidNoOrigin
            } else {
              Invalid(InvalidOrigin(referer))
            }
          None =>
            // No Origin and no Referer - likely same-origin
            ValidNoOrigin
        }
      } else {
        Invalid(MissingOrigin)
      }
    Some(origin) =>
      // Origin present - validate against allowed list
      if config.allowed_origins.is_empty() {
        // No allowed origins configured - reject all cross-origin
        Invalid(InvalidOrigin(origin))
      } else if config.allowed_origins.contains(origin) {
        ValidOrigin(origin)
      } else {
        Invalid(InvalidOrigin(origin))
      }
  }
}

///|
/// Check if Referer matches any allowed origin
fn is_referer_allowed(
  referer : String,
  allowed_origins : Array[String],
) -> Bool {
  for origin in allowed_origins {
    if referer.has_prefix(origin) {
      return true
    }
  }
  false
}

///|
/// Validate Fetch Metadata headers
fn validate_fetch_metadata(request : MwRequest) -> CsrfResult {
  // Sec-Fetch-Site: cross-site | same-origin | same-site | none
  let sec_fetch_site = request.get_header("Sec-Fetch-Site")
  match sec_fetch_site {
    Some("cross-site") =>
      // Cross-site requests are not allowed for mutations
      Invalid(CrossSiteFetch)
    Some("same-origin") | Some("same-site") | Some("none") =>
      // same-origin: Same origin
      // same-site: Same site (subdomain)
      // none: Direct navigation (bookmark, URL bar)
      Valid
    None =>
      // Header not present (older browsers) - rely on Origin validation
      Valid
    Some(_) =>
      // Unknown value - allow (forward compatible)
      Valid
  }
}

///|
/// Validate Content-Type header
fn validate_content_type(request : MwRequest, expected : String) -> CsrfResult {
  let content_type = request.get_header("Content-Type")
  match content_type {
    Some(ct) =>
      // Check if Content-Type starts with expected value
      // (handles charset suffix like "application/json; charset=utf-8")
      if ct.has_prefix(expected) {
        Valid
      } else {
        Invalid(InvalidContentType(ct))
      }
    None =>
      // No Content-Type - might be empty body
      // For strict APIs, this should be rejected
      Invalid(InvalidContentType("(none)"))
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
  Middleware(async fn(ctx) {
    // Skip safe methods
    if is_safe_method(ctx.request.http_method) {
      return Continue(ctx)
    }
    let origin = ctx.request.get_header("Origin")
    match origin {
      None =>
        // No Origin = same-origin, allow
        Continue(ctx)
      Some(o) =>
        if allowed_origins.contains(o) {
          Continue(ctx)
        } else {
          Halt(MwResponse::forbidden())
        }
    }
  })
}

// ============================================================================
// Fetch Metadata Middleware (Standalone)
// ============================================================================

///|
/// Fetch Metadata validation middleware
/// Blocks requests with Sec-Fetch-Site: cross-site
pub fn fetch_metadata() -> Middleware {
  Middleware(async fn(ctx) {
    // Skip safe methods
    if is_safe_method(ctx.request.http_method) {
      return Continue(ctx)
    }
    match validate_fetch_metadata(ctx.request) {
      Valid | ValidNoOrigin | ValidOrigin(_) => Continue(ctx)
      Invalid(_) => Halt(MwResponse::forbidden())
    }
  })
}

// ============================================================================
// Content-Type Middleware (Standalone)
// ============================================================================

///|
/// Require specific Content-Type for mutations
pub fn require_content_type(content_type : String) -> Middleware {
  Middleware(async fn(ctx) {
    // Skip safe methods
    if is_safe_method(ctx.request.http_method) {
      return Continue(ctx)
    }
    match validate_content_type(ctx.request, content_type) {
      Valid | ValidNoOrigin | ValidOrigin(_) => Continue(ctx)
      Invalid(_) =>
        Halt(MwResponse::bad_request(message="Invalid Content-Type"))
    }
  })
}

///|
/// Require JSON Content-Type for mutations
pub fn require_json_content_type() -> Middleware {
  require_content_type("application/json")
}
