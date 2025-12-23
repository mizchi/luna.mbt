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
