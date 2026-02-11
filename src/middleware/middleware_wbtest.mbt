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
