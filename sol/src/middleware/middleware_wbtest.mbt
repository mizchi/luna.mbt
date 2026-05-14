///|
using @test {assert_eq}

// Middleware unit tests

// ============================================================================
// Composition Tests
// ============================================================================

///|
test "identity middleware can be created" {
  let mw = identity()
  let _ = mw
}

///|
test "pipeline creates combined middleware" {
  let mw1 = identity()
  let mw2 = identity()
  let combined = pipeline([mw1, mw2])
  let _ = combined
}

///|
test "then_ composes two middlewares" {
  let mw1 = identity()
  let mw2 = identity()
  let combined = mw1 |> then_(mw2)
  let _ = combined
}

// ============================================================================
// Logger Config Tests
// ============================================================================

///|
test "LoggerConfig::default creates dev format" {
  let config = LoggerConfig::default()
  match config.format {
    LogFormat::Dev => ()
    _ => fail("expected Dev format")
  }
}

///|
test "LoggerConfig::json creates json format" {
  let config = LoggerConfig::json()
  match config.format {
    LogFormat::Json => ()
    _ => fail("expected Json format")
  }
}

///|
test "LoggerConfig::combined creates combined format" {
  let config = LoggerConfig::combined()
  match config.format {
    LogFormat::Combined => ()
    _ => fail("expected Combined format")
  }
}

///|
test "delegate_logger_handler supports dev format with skip paths" {
  let config = LoggerConfig::default().with_skip_paths(["/health"])
  assert_true(delegate_logger_handler(config) is Some(_))
}

///|
test "delegate_logger_handler does not support json format" {
  let config = LoggerConfig::json()
  assert_true(delegate_logger_handler(config) is None)
}

// ============================================================================
// CORS Config Tests
// ============================================================================

///|
test "CorsConfig::default creates permissive config" {
  let config = CorsConfig::default()
  match config.origin {
    CorsOrigin::All => ()
    _ => fail("expected All origin")
  }
  assert_true(config.methods.contains("GET"))
  assert_true(config.methods.contains("POST"))
}

///|
test "CorsConfig::strict creates restrictive config" {
  let config = CorsConfig::strict()
  match config.origin {
    CorsOrigin::List(_) => ()
    _ => fail("expected List origin")
  }
}

///|
test "CorsConfig::with_origin_single sets single origin" {
  let config = CorsConfig::default().with_origin_single("https://example.com")
  match config.origin {
    CorsOrigin::Single(o) => assert_eq(o, "https://example.com")
    _ => fail("expected Single origin")
  }
}

///|
test "CorsConfig::with_credentials enables credentials" {
  let config = CorsConfig::default().with_credentials()
  assert_true(config.credentials)
}

///|
test "static_mars_cors_handler returns handler for wildcard origin" {
  let config = CorsConfig::default()
  assert_true(static_mars_cors_handler(config) is Some(_))
}

///|
test "static_mars_cors_handler returns None for origin list" {
  let config = CorsConfig::default().with_origin(
    CorsOrigin::List(["https://example.com"]),
  )
  assert_true(static_mars_cors_handler(config) is None)
}

// ============================================================================
// CSRF Config Tests
// ============================================================================

///|
test "CsrfConfig::default creates strict config" {
  let config = CsrfConfig::default()
  assert_true(config.allowed_origins.is_empty())
  assert_true(config.check_fetch_metadata)
  assert_true(config.allow_no_origin)
}

///|
test "CsrfConfig::for_origin sets single origin" {
  let config = CsrfConfig::for_origin("https://example.com")
  assert_eq(config.allowed_origins.length(), 1)
  assert_true(config.allowed_origins.contains("https://example.com"))
}

///|
test "CsrfConfig::for_origins sets multiple origins" {
  let config = CsrfConfig::for_origins([
    "https://example.com", "https://api.example.com",
  ])
  assert_eq(config.allowed_origins.length(), 2)
}

///|
test "CsrfConfig::with_origin adds origin" {
  let config = CsrfConfig::default().with_origin("https://example.com")
  assert_eq(config.allowed_origins.length(), 1)
}

///|
test "CsrfConfig::require_json sets content type" {
  let config = CsrfConfig::default().require_json()
  match config.expected_content_type {
    Some(ct) => assert_eq(ct, "application/json")
    None => fail("expected content type")
  }
}

///|
test "CsrfConfig::with_fetch_metadata toggles check" {
  let config = CsrfConfig::default().with_fetch_metadata(false)
  assert_false(config.check_fetch_metadata)
}

// ============================================================================
// CSRF Middleware Creation Tests
// ============================================================================

///|
test "csrf middleware can be created" {
  let mw = csrf_for_origin("https://example.com")
  let _ = mw
}

///|
test "csrf middleware can be composed" {
  let mw = then(csrf_for_origin("https://example.com"), identity())
  let _ = mw
}

///|
test "validate_origin_middleware can be created" {
  let mw = validate_origin_middleware(["https://example.com"])
  let _ = mw
}

///|
test "fetch_metadata middleware can be created" {
  let mw = fetch_metadata()
  let _ = mw
}

///|
test "require_json_content_type middleware can be created" {
  let mw = require_json_content_type()
  let _ = mw
}

// ============================================================================
// CSRF Error Tests
// ============================================================================

///|
test "CsrfError::MissingOrigin formats correctly" {
  let err = CsrfError::MissingOrigin
  assert_eq(err.to_string(), "Missing Origin header")
}

///|
test "CsrfError::InvalidOrigin formats correctly" {
  let err = CsrfError::InvalidOrigin("https://evil.com")
  assert_eq(err.to_string(), "Invalid Origin: https://evil.com")
}

///|
test "CsrfError::CrossSiteFetch formats correctly" {
  let err = CsrfError::CrossSiteFetch
  assert_eq(err.to_string(), "Cross-site fetch not allowed")
}

///|
test "CsrfError::UnsafeFetchMode formats correctly" {
  let err = CsrfError::UnsafeFetchMode
  assert_eq(err.to_string(), "Unsafe fetch mode")
}

///|
test "CsrfError::InvalidContentType formats correctly" {
  let err = CsrfError::InvalidContentType("text/html")
  assert_eq(err.to_string(), "Invalid Content-Type: text/html")
}

// ============================================================================
// CSRF Result Tests
// ============================================================================

///|
test "CsrfResult::Valid matches correctly" {
  let result : CsrfResult = Valid
  match result {
    Valid => ()
    _ => fail("expected Valid")
  }
}

///|
test "CsrfResult::ValidNoOrigin matches correctly" {
  let result : CsrfResult = ValidNoOrigin
  match result {
    ValidNoOrigin => ()
    _ => fail("expected ValidNoOrigin")
  }
}

///|
test "CsrfResult::ValidOrigin matches correctly" {
  let result : CsrfResult = ValidOrigin("https://example.com")
  match result {
    ValidOrigin(o) => assert_eq(o, "https://example.com")
    _ => fail("expected ValidOrigin")
  }
}

///|
test "CsrfResult::Invalid matches correctly" {
  let result : CsrfResult = Invalid(CsrfError::MissingOrigin)
  match result {
    Invalid(MissingOrigin) => ()
    _ => fail("expected Invalid(MissingOrigin)")
  }
}

// ============================================================================
// CSRF URL Parsing Tests
// ============================================================================

///|
test "extract_origin_from_url with path" {
  let origin = extract_origin_from_url("http://localhost:9123/form")
  match origin {
    Some(o) => assert_eq(o, "http://localhost:9123")
    None => fail("expected Some origin")
  }
}

///|
test "extract_origin_from_url without path" {
  let origin = extract_origin_from_url("http://localhost:9123")
  match origin {
    Some(o) => assert_eq(o, "http://localhost:9123")
    None => fail("expected Some origin")
  }
}

///|
test "extract_origin_from_url with long path" {
  let origin = extract_origin_from_url(
    "http://localhost:9123/../../attacker.com",
  )
  match origin {
    Some(o) => assert_eq(o, "http://localhost:9123")
    None => fail("expected Some origin")
  }
}

///|
test "extract_origin_from_url invalid URL" {
  let origin = extract_origin_from_url("invalid-url")
  match origin {
    None => ()
    Some(_) => fail("expected None for invalid URL")
  }
}

///|
test "is_referer_allowed with valid referer" {
  let allowed = ["http://localhost:9123", "http://localhost:3000"]
  let result = is_referer_allowed("http://localhost:9123/form", allowed)
  assert_true(result)
}

///|
test "is_referer_allowed with invalid referer" {
  let allowed = ["http://localhost:9123", "http://localhost:3000"]
  let result = is_referer_allowed("http://attacker.com/form", allowed)
  assert_false(result)
}

///|
test "is_referer_allowed with prefix attack" {
  let allowed = ["http://localhost:9123"]
  let result = is_referer_allowed(
    "http://localhost:9123.attacker.com/form", allowed,
  )
  assert_false(result)
}

// ============================================================================
// Security Headers Config Tests
// ============================================================================

///|
test "SecurityHeadersConfig::default creates strict config" {
  let config = SecurityHeadersConfig::default()
  assert_eq(config.frame_options, "SAMEORIGIN")
  assert_eq(config.content_type_options, "nosniff")
}

///|
test "SecurityHeadersConfig::relaxed creates relaxed config" {
  let config = SecurityHeadersConfig::relaxed()
  assert_eq(config.coop, "same-origin-allow-popups")
  assert_eq(config.coep, "unsafe-none")
}

///|
test "security_headers middleware can be created" {
  let mw = security_headers()
  let _ = mw
}

///|
test "minimal_secure_headers_options disables all optional headers" {
  let opts = minimal_secure_headers_options()
  assert_false(opts.hsts)
  assert_eq(opts.hsts_max_age, 0)
  assert_false(opts.hsts_include_subdomains)
  assert_false(opts.no_sniff)
  assert_eq(opts.frame_options, "")
  assert_false(opts.xss_protection)
  assert_eq(opts.csp, "")
  assert_eq(opts.referrer_policy, "")
  assert_eq(opts.permissions_policy, "")
}

///|
test "nosniff middleware can be created" {
  let mw = nosniff()
  let _ = mw
}

///|
test "frame_options middleware can be created" {
  let mw = frame_options("DENY")
  let _ = mw
}

///|
test "csp middleware can be created" {
  let mw = csp("default-src 'self'")
  let _ = mw
}

// ============================================================================
// Helper function tests
// ============================================================================

///|
test "is_safe_method returns true for GET" {
  assert_true(is_safe_method("GET"))
}

///|
test "is_safe_method returns true for HEAD" {
  assert_true(is_safe_method("HEAD"))
}

///|
test "is_safe_method returns true for OPTIONS" {
  assert_true(is_safe_method("OPTIONS"))
}

///|
test "is_safe_method returns false for POST" {
  assert_false(is_safe_method("POST"))
}

///|
test "is_safe_method returns false for PUT" {
  assert_false(is_safe_method("PUT"))
}

///|
test "is_safe_method returns false for DELETE" {
  assert_false(is_safe_method("DELETE"))
}

// ============================================================================
// CORS resolve_response_origin Tests
// ============================================================================

///|
test "resolve_response_origin with All allows any origin" {
  let result = resolve_response_origin("https://anything.com", CorsOrigin::All)
  match result {
    Some(o) => assert_eq(o, "*")
    None => fail("expected Some")
  }
}

///|
test "resolve_response_origin with Single matches exact origin" {
  let result = resolve_response_origin(
    "https://example.com",
    CorsOrigin::Single("https://example.com"),
  )
  match result {
    Some(o) => assert_eq(o, "https://example.com")
    None => fail("expected Some")
  }
}

///|
test "resolve_response_origin with Single rejects mismatched origin" {
  let result = resolve_response_origin(
    "https://evil.com",
    CorsOrigin::Single("https://example.com"),
  )
  assert_true(result is None)
}

///|
test "resolve_response_origin with List matches included origin" {
  let result = resolve_response_origin(
    "https://app.example.com",
    CorsOrigin::List(["https://example.com", "https://app.example.com"]),
  )
  match result {
    Some(o) => assert_eq(o, "https://app.example.com")
    None => fail("expected Some")
  }
}

///|
test "resolve_response_origin with List rejects unlisted origin" {
  let result = resolve_response_origin(
    "https://evil.com",
    CorsOrigin::List(["https://example.com"]),
  )
  assert_true(result is None)
}

///|
test "resolve_response_origin with Dynamic allows matching origin" {
  let result = resolve_response_origin(
    "https://sub.example.com",
    CorsOrigin::Dynamic(fn(o) { o.has_suffix(".example.com") }),
  )
  match result {
    Some(o) => assert_eq(o, "https://sub.example.com")
    None => fail("expected Some")
  }
}

///|
test "resolve_response_origin with Dynamic rejects non-matching origin" {
  let result = resolve_response_origin(
    "https://evil.com",
    CorsOrigin::Dynamic(fn(o) { o.has_suffix(".example.com") }),
  )
  assert_true(result is None)
}

// ============================================================================
// CORS to_mars_cors_options Tests
// ============================================================================

///|
test "to_mars_cors_options maps origin" {
  let config = CorsConfig::default()
  let opts = to_mars_cors_options(config, "https://example.com")
  assert_eq(opts.origin, "https://example.com")
}

///|
test "to_mars_cors_options maps methods" {
  let config = CorsConfig::default().with_methods(["GET", "POST"])
  let opts = to_mars_cors_options(config, "*")
  assert_eq(opts.methods.length(), 2)
  assert_true(opts.methods.contains("GET"))
}

///|
test "to_mars_cors_options maps allowed_headers" {
  let config = CorsConfig::default().with_allowed_headers(["X-Custom"])
  let opts = to_mars_cors_options(config, "*")
  assert_true(opts.allowed_headers.contains("X-Custom"))
}

///|
test "to_mars_cors_options maps exposed_headers" {
  let config = CorsConfig::default().with_exposed_headers(["X-Total"])
  let opts = to_mars_cors_options(config, "*")
  assert_true(opts.exposed_headers.contains("X-Total"))
}

///|
test "to_mars_cors_options maps credentials" {
  let config = CorsConfig::default().with_credentials()
  let opts = to_mars_cors_options(config, "*")
  assert_true(opts.credentials)
}

///|
test "to_mars_cors_options maps max_age Some to int" {
  let config = CorsConfig::default().with_max_age(3600)
  let opts = to_mars_cors_options(config, "*")
  assert_eq(opts.max_age, 3600)
}

///|
test "to_mars_cors_options maps max_age None to zero" {
  let config = CorsConfig::strict()
  let opts = to_mars_cors_options(config, "*")
  assert_eq(opts.max_age, 0)
}

// ============================================================================
// CorsConfig builder Tests
// ============================================================================

///|
test "CorsConfig::with_methods sets methods" {
  let config = CorsConfig::default().with_methods(["GET", "HEAD"])
  assert_eq(config.methods.length(), 2)
}

///|
test "CorsConfig::with_allowed_headers sets headers" {
  let config = CorsConfig::default().with_allowed_headers(["Authorization"])
  assert_eq(config.allowed_headers.length(), 1)
}

///|
test "CorsConfig::with_exposed_headers sets headers" {
  let config = CorsConfig::default().with_exposed_headers(["X-Request-Id"])
  assert_true(config.exposed_headers.contains("X-Request-Id"))
}

///|
test "CorsConfig::with_max_age sets age" {
  let config = CorsConfig::default().with_max_age(7200)
  assert_eq(config.max_age, Some(7200))
}

// ============================================================================
// CORS factory Tests
// ============================================================================

///|
test "cors() factory creates middleware" {
  let mw = cors()
  let _ = mw
}

///|
test "cors_with_config() for All origin creates middleware" {
  let mw = cors_with_config(CorsConfig::default())
  let _ = mw
}

///|
test "cors_with_config() for Single origin creates middleware" {
  let mw = cors_with_config(
    CorsConfig::default().with_origin_single("https://example.com"),
  )
  let _ = mw
}

///|
test "cors_with_config() for List origin creates middleware" {
  let mw = cors_with_config(
    CorsConfig::default().with_origin(CorsOrigin::List(["https://a.com"])),
  )
  let _ = mw
}

///|
test "cors_with_config() for Dynamic origin creates middleware" {
  let mw = cors_with_config(
    CorsConfig::default().with_origin(CorsOrigin::Dynamic(fn(_o) { true })),
  )
  let _ = mw
}

// ============================================================================
// SecurityHeadersConfig builder Tests
// ============================================================================

///|
test "SecurityHeadersConfig::with_frame_options sets value" {
  let config = SecurityHeadersConfig::default().with_frame_options("DENY")
  assert_eq(config.frame_options, "DENY")
}

///|
test "SecurityHeadersConfig::with_referrer_policy sets value" {
  let config = SecurityHeadersConfig::default().with_referrer_policy(
    "no-referrer",
  )
  assert_eq(config.referrer_policy, "no-referrer")
}

///|
test "SecurityHeadersConfig::with_coop sets value" {
  let config = SecurityHeadersConfig::default().with_coop(
    "same-origin-allow-popups",
  )
  assert_eq(config.coop, "same-origin-allow-popups")
}

///|
test "SecurityHeadersConfig::with_coep sets value" {
  let config = SecurityHeadersConfig::default().with_coep("unsafe-none")
  assert_eq(config.coep, "unsafe-none")
}

///|
test "SecurityHeadersConfig::with_permissions_policy sets value" {
  let config = SecurityHeadersConfig::default().with_permissions_policy(
    "geolocation=()",
  )
  assert_eq(config.permissions_policy, "geolocation=()")
}

///|
test "SecurityHeadersConfig::with_csp sets value" {
  let config = SecurityHeadersConfig::default().with_csp("default-src 'none'")
  assert_eq(config.csp, "default-src 'none'")
}

///|
test "SecurityHeadersConfig::with_cache_control_html sets value" {
  let config = SecurityHeadersConfig::default().with_cache_control_html(
    "private, no-cache",
  )
  assert_eq(config.cache_control_html, "private, no-cache")
}

///|
test "SecurityHeadersConfig::with_cache_control_static sets value" {
  let config = SecurityHeadersConfig::default().with_cache_control_static(
    "public, max-age=3600",
  )
  assert_eq(config.cache_control_static, "public, max-age=3600")
}

// ============================================================================
// to_mars_secure_headers_options Tests
// ============================================================================

///|
test "to_mars_secure_headers_options maps frame_options" {
  let config = SecurityHeadersConfig::default().with_frame_options("DENY")
  let opts = to_mars_secure_headers_options(config)
  assert_eq(opts.frame_options, "DENY")
}

///|
test "to_mars_secure_headers_options maps referrer_policy" {
  let config = SecurityHeadersConfig::default().with_referrer_policy(
    "no-referrer",
  )
  let opts = to_mars_secure_headers_options(config)
  assert_eq(opts.referrer_policy, "no-referrer")
}

///|
test "to_mars_secure_headers_options maps csp" {
  let config = SecurityHeadersConfig::default().with_csp("default-src 'none'")
  let opts = to_mars_secure_headers_options(config)
  assert_eq(opts.csp, "default-src 'none'")
}

///|
test "to_mars_secure_headers_options sets no_sniff true when nosniff" {
  let config = SecurityHeadersConfig::default()
  let opts = to_mars_secure_headers_options(config)
  assert_true(opts.no_sniff)
}

///|
test "to_mars_secure_headers_options enables hsts" {
  let config = SecurityHeadersConfig::default()
  let opts = to_mars_secure_headers_options(config)
  assert_true(opts.hsts)
  assert_eq(opts.hsts_max_age, 31536000)
  assert_true(opts.hsts_include_subdomains)
}

///|
test "to_mars_secure_headers_options enables xss_protection" {
  let config = SecurityHeadersConfig::default()
  let opts = to_mars_secure_headers_options(config)
  assert_true(opts.xss_protection)
}

// ============================================================================
// is_static_asset Tests
// ============================================================================

///|
test "is_static_asset returns true for /static/ prefix" {
  assert_true(is_static_asset("/static/app.js"))
}

///|
test "is_static_asset returns true for .js suffix" {
  assert_true(is_static_asset("/assets/main.js"))
}

///|
test "is_static_asset returns true for .css suffix" {
  assert_true(is_static_asset("/styles/main.css"))
}

///|
test "is_static_asset returns true for .png suffix" {
  assert_true(is_static_asset("/images/logo.png"))
}

///|
test "is_static_asset returns true for .jpg suffix" {
  assert_true(is_static_asset("/images/photo.jpg"))
}

///|
test "is_static_asset returns true for .svg suffix" {
  assert_true(is_static_asset("/icons/icon.svg"))
}

///|
test "is_static_asset returns true for .woff suffix" {
  assert_true(is_static_asset("/fonts/font.woff"))
}

///|
test "is_static_asset returns true for .woff2 suffix" {
  assert_true(is_static_asset("/fonts/font.woff2"))
}

///|
test "is_static_asset returns false for HTML page" {
  assert_false(is_static_asset("/index.html"))
}

///|
test "is_static_asset returns false for API path" {
  assert_false(is_static_asset("/api/users"))
}

///|
test "is_static_asset returns false for root path" {
  assert_false(is_static_asset("/"))
}

// ============================================================================
// Security Headers factory Tests
// ============================================================================

///|
test "security_headers_relaxed() factory creates middleware" {
  let mw = security_headers_relaxed()
  let _ = mw
}

///|
test "referrer_policy() factory creates middleware" {
  let mw = referrer_policy("no-referrer")
  let _ = mw
}

///|
test "cache_control() factory creates middleware" {
  let mw = cache_control("no-store")
  let _ = mw
}

// ============================================================================
// CSRF Pure Validation Tests
// ============================================================================

///|
test "validate_origin_pure: valid origin in allowed list" {
  let result = validate_origin_pure(
    origin=Some("https://example.com"),
    referer=None,
    allowed_origins=["https://example.com"],
    allow_no_origin=true,
  )
  match result {
    ValidOrigin(o) => assert_eq(o, "https://example.com")
    _ => fail("expected ValidOrigin")
  }
}

///|
test "validate_origin_pure: origin not in allowed list" {
  let result = validate_origin_pure(
    origin=Some("https://evil.com"),
    referer=None,
    allowed_origins=["https://example.com"],
    allow_no_origin=true,
  )
  assert_true(result is Invalid(_))
}

///|
test "validate_origin_pure: origin with empty allowed list" {
  let result = validate_origin_pure(
    origin=Some("https://example.com"),
    referer=None,
    allowed_origins=[],
    allow_no_origin=true,
  )
  match result {
    Invalid(InvalidOrigin(_)) => ()
    _ => fail("expected Invalid")
  }
}

///|
test "validate_origin_pure: no origin with allow_no_origin" {
  let result = validate_origin_pure(
    origin=None,
    referer=None,
    allowed_origins=[],
    allow_no_origin=true,
  )
  assert_true(result is ValidNoOrigin)
}

///|
test "validate_origin_pure: no origin without allow_no_origin" {
  let result = validate_origin_pure(
    origin=None,
    referer=None,
    allowed_origins=[],
    allow_no_origin=false,
  )
  assert_true(result is Invalid(_))
}

///|
test "validate_origin_pure: no origin with valid referer" {
  let result = validate_origin_pure(
    origin=None,
    referer=Some("https://example.com/page"),
    allowed_origins=["https://example.com"],
    allow_no_origin=true,
  )
  assert_true(result is ValidNoOrigin)
}

///|
test "validate_origin_pure: no origin with invalid referer" {
  let result = validate_origin_pure(
    origin=None,
    referer=Some("https://evil.com/page"),
    allowed_origins=["https://example.com"],
    allow_no_origin=true,
  )
  assert_true(result is Invalid(_))
}

///|
test "validate_origin_pure: no origin with referer and empty allowed list" {
  let result = validate_origin_pure(
    origin=None,
    referer=Some("https://something.com/page"),
    allowed_origins=[],
    allow_no_origin=true,
  )
  assert_true(result is ValidNoOrigin)
}

// ============================================================================
// Fetch Metadata Pure Validation Tests
// ============================================================================

///|
test "validate_fetch_metadata_pure: cross-site rejected" {
  let result = validate_fetch_metadata_pure(Some("cross-site"))
  assert_true(result is Invalid(CrossSiteFetch))
}

///|
test "validate_fetch_metadata_pure: same-origin allowed" {
  let result = validate_fetch_metadata_pure(Some("same-origin"))
  assert_true(result is Valid)
}

///|
test "validate_fetch_metadata_pure: same-site allowed" {
  let result = validate_fetch_metadata_pure(Some("same-site"))
  assert_true(result is Valid)
}

///|
test "validate_fetch_metadata_pure: none allowed" {
  let result = validate_fetch_metadata_pure(Some("none"))
  assert_true(result is Valid)
}

///|
test "validate_fetch_metadata_pure: missing header allowed" {
  let result = validate_fetch_metadata_pure(None)
  assert_true(result is Valid)
}

///|
test "validate_fetch_metadata_pure: unknown value allowed (forward compat)" {
  let result = validate_fetch_metadata_pure(Some("future-value"))
  assert_true(result is Valid)
}

// ============================================================================
// Content-Type Pure Validation Tests
// ============================================================================

///|
test "validate_content_type_pure: exact match" {
  let result = validate_content_type_pure(
    Some("application/json"),
    "application/json",
  )
  assert_true(result is Valid)
}

///|
test "validate_content_type_pure: with charset suffix" {
  let result = validate_content_type_pure(
    Some("application/json; charset=utf-8"),
    "application/json",
  )
  assert_true(result is Valid)
}

///|
test "validate_content_type_pure: mismatch" {
  let result = validate_content_type_pure(Some("text/html"), "application/json")
  match result {
    Invalid(InvalidContentType(ct)) => assert_eq(ct, "text/html")
    _ => fail("expected InvalidContentType")
  }
}

///|
test "validate_content_type_pure: missing header" {
  let result = validate_content_type_pure(None, "application/json")
  match result {
    Invalid(InvalidContentType(ct)) => assert_eq(ct, "(none)")
    _ => fail("expected InvalidContentType")
  }
}

// ============================================================================
// Full CSRF Pure Validation Tests
// ============================================================================

///|
test "validate_csrf_pure: valid same-origin POST" {
  let config = CsrfConfig::for_origin("https://example.com")
  let result = validate_csrf_pure(
    origin=Some("https://example.com"),
    referer=None,
    sec_fetch_site=Some("same-origin"),
    content_type=None,
    config~,
  )
  assert_true(result is ValidOrigin(_))
}

///|
test "validate_csrf_pure: cross-origin blocked by origin check" {
  let config = CsrfConfig::for_origin("https://example.com")
  let result = validate_csrf_pure(
    origin=Some("https://evil.com"),
    referer=None,
    sec_fetch_site=None,
    content_type=None,
    config~,
  )
  assert_true(result is Invalid(_))
}

///|
test "validate_csrf_pure: cross-site fetch metadata blocks" {
  let config = CsrfConfig::default().with_origin("https://example.com")
  let result = validate_csrf_pure(
    origin=Some("https://example.com"),
    referer=None,
    sec_fetch_site=Some("cross-site"),
    content_type=None,
    config~,
  )
  assert_true(result is Invalid(CrossSiteFetch))
}

///|
test "validate_csrf_pure: content-type check blocks wrong type" {
  let config = CsrfConfig::for_origin("https://example.com").require_json()
  let result = validate_csrf_pure(
    origin=Some("https://example.com"),
    referer=None,
    sec_fetch_site=Some("same-origin"),
    content_type=Some("text/plain"),
    config~,
  )
  assert_true(result is Invalid(InvalidContentType(_)))
}

///|
test "validate_csrf_pure: all checks pass" {
  let config = CsrfConfig::for_origin("https://example.com").require_json()
  let result = validate_csrf_pure(
    origin=Some("https://example.com"),
    referer=None,
    sec_fetch_site=Some("same-origin"),
    content_type=Some("application/json"),
    config~,
  )
  assert_true(result is ValidOrigin(_))
}

///|
test "validate_csrf_pure: fetch metadata disabled skips check" {
  let config = CsrfConfig::for_origin("https://example.com").with_fetch_metadata(
    false,
  )
  let result = validate_csrf_pure(
    origin=Some("https://example.com"),
    referer=None,
    sec_fetch_site=Some("cross-site"),
    content_type=None,
    config~,
  )
  assert_true(result is ValidOrigin(_))
}

// ============================================================================
// Logger Pure Format Tests
// ============================================================================

///|
test "format_dev_pure formats method and path" {
  assert_eq(format_dev_pure("GET", "/api/users"), "GET /api/users")
}

///|
test "format_dev_pure with POST" {
  assert_eq(format_dev_pure("POST", "/api/data"), "POST /api/data")
}

///|
test "format_combined_pure formats all fields" {
  let result = format_combined_pure(
    "GET", "/index.html", "Mozilla/5.0", "https://example.com", "2024-01-01T00:00:00.000Z",
  )
  assert_true(result.contains("GET /index.html"))
  assert_true(result.contains("Mozilla/5.0"))
  assert_true(result.contains("https://example.com"))
  assert_true(result.contains("2024-01-01"))
}

///|
test "format_combined_pure with missing user-agent and referer" {
  let result = format_combined_pure(
    "POST", "/api", "-", "-", "2024-01-01T00:00:00.000Z",
  )
  assert_true(result.contains("POST /api"))
  assert_true(result.contains("\"-\""))
}

///|
test "format_json_pure produces valid JSON structure" {
  let result = format_json_pure("DELETE", "/api/item/1", "2024-06-15T12:00:00Z")
  assert_true(result.contains("\"method\":\"DELETE\""))
  assert_true(result.contains("\"path\":\"/api/item/1\""))
  assert_true(result.contains("\"timestamp\":\"2024-06-15T12:00:00Z\""))
}

///|
test "format_json_pure with GET" {
  let result = format_json_pure("GET", "/", "2024-01-01T00:00:00Z")
  assert_eq(
    result, "{\"method\":\"GET\",\"path\":\"/\",\"timestamp\":\"2024-01-01T00:00:00Z\"}",
  )
}
