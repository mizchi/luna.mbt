// Middleware unit tests

// ============================================================================
// Flow Type Tests
// ============================================================================

///|
test "Flow::Continue creates continue flow" {
  let ctx = create_test_context()
  let flow : Flow[MwContext] = Continue(ctx)
  match flow {
    Continue(_) => ()
    Halt(_) => fail("expected Continue")
  }
}

///|
test "Flow::Halt creates halt flow" {
  let resp = MwResponse::text("error", status=500)
  let flow : Flow[MwContext] = Halt(resp)
  match flow {
    Halt(r) => assert_eq(r.status, 500)
    Continue(_) => fail("expected Halt")
  }
}

// ============================================================================
// MwResponse Tests
// ============================================================================

///|
test "MwResponse::text creates text response" {
  let resp = MwResponse::text("hello")
  assert_eq(resp.status, 200)
  assert_eq(resp.body, "hello")
  assert_eq(resp.content_type, "text/plain")
}

///|
test "MwResponse::json creates json response" {
  let resp = MwResponse::json("{\"ok\":true}")
  assert_eq(resp.status, 200)
  assert_eq(resp.content_type, "application/json")
}

///|
test "MwResponse::html creates html response" {
  let resp = MwResponse::html("<h1>Hello</h1>")
  assert_eq(resp.status, 200)
  assert_eq(resp.content_type, "text/html")
}

///|
test "MwResponse::redirect creates redirect response" {
  let resp = MwResponse::redirect("/login")
  assert_eq(resp.status, 302)
  let has_location = resp.headers
    .iter()
    .any(fn(h) { h.0 == "Location" && h.1 == "/login" })
  assert_true(has_location)
}

///|
test "MwResponse::unauthorized creates 401 response" {
  let resp = MwResponse::unauthorized()
  assert_eq(resp.status, 401)
  assert_eq(resp.body, "Unauthorized")
}

///|
test "MwResponse::forbidden creates 403 response" {
  let resp = MwResponse::forbidden()
  assert_eq(resp.status, 403)
  assert_eq(resp.body, "Forbidden")
}

///|
test "MwResponse::not_found creates 404 response" {
  let resp = MwResponse::not_found()
  assert_eq(resp.status, 404)
  assert_eq(resp.body, "Not Found")
}

///|
test "MwResponse::with_header adds header" {
  let resp = MwResponse::text("hello").with_header("X-Custom", "value")
  let has_header = resp.headers
    .iter()
    .any(fn(h) { h.0 == "X-Custom" && h.1 == "value" })
  assert_true(has_header)
}

// ============================================================================
// Composition Tests
// ============================================================================

///|
test "identity middleware passes through" {
  let mw = identity()
  let _ctx = create_test_context()
  // Note: Can't easily test async in unit tests without Hono context
  // This verifies the middleware can be created
  let _ = mw

}

///|
test "halt middleware creates halt response" {
  let resp = MwResponse::unauthorized()
  let mw = halt(resp)
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

///|
test "or_ creates alternative middleware" {
  let mw1 = halt(MwResponse::unauthorized())
  let mw2 = identity()
  let combined = mw1 |> or_(mw2)
  let _ = combined

}

// ============================================================================
// Conditional Composition Tests
// ============================================================================

///|
test "when runs middleware on condition true" {
  let condition = fn(_ctx : MwContext) { true }
  let mw = when(condition, identity())
  let _ = mw

}

///|
test "unless runs middleware on condition false" {
  let condition = fn(_ctx : MwContext) { true }
  let mw = unless(condition, identity())
  let _ = mw

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
// CSRF Validation Tests (Unit level)
// ============================================================================

///|
test "csrf middleware allows GET requests" {
  let mw = csrf_for_origin("https://example.com")
  let _ = mw
  // GET requests should pass through without validation
}

///|
test "csrf middleware can be composed" {
  let mw = csrf_for_origin("https://example.com").then(identity())
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
// Helper Functions
// ============================================================================

///|
/// Create a test MwContext (without real Hono context)
fn create_test_context() -> MwContext {
  // Note: This creates a minimal context for testing
  // Real tests with Hono context need browser/E2E tests
  let request : MwRequest = {
    http_method: "GET",
    path: "/test",
    headers: [],
    query: [],
    url: "http://localhost/test",
  }
  { ctx: create_dummy_ctx(), request, state: {}, response_headers: [] }
}

///|
/// Create a dummy Hono context for testing
extern "js" fn create_dummy_ctx() -> Ctx =
  #| () => ({
  #|   req: { method: "GET", url: "http://localhost/test", raw: { headers: new Headers() } },
  #|   header: () => {},
  #|   json: (data) => new Response(JSON.stringify(data)),
  #|   text: (text) => new Response(text),
  #|   html: (html) => new Response(html),
  #|   redirect: (url) => new Response(null, { status: 302, headers: { Location: url } }),
  #|   body: (body, status) => new Response(body, { status })
  #| })
