// route_params internal tests

// ============================================================================
// RouteParams::require Tests
// ============================================================================

///|
test "RouteParams::require returns Ok for existing param" {
  let params : RouteParams = {
    params: [("id", "42")],
    query: [],
    path: "/users/42",
    is_fragment: false,
  }
  match params.require("id") {
    Ok(v) => assert_eq(v, "42")
    Err(_) => fail("expected Ok")
  }
}

///|
test "RouteParams::require returns Err for missing param" {
  let params = RouteParams::empty()
  match params.require("id") {
    Err(ApiResponse::Error(msg, 400)) =>
      assert_true(msg.contains("Missing required parameter"))
    _ => fail("expected Error 400")
  }
}

// ============================================================================
// RouteParams::optional Tests
// ============================================================================

///|
test "RouteParams::optional returns value when present" {
  let params : RouteParams = {
    params: [("sort", "name")],
    query: [],
    path: "/",
    is_fragment: false,
  }
  assert_eq(params.optional("sort", "id"), "name")
}

///|
test "RouteParams::optional returns default when absent" {
  let params = RouteParams::empty()
  assert_eq(params.optional("sort", "id"), "id")
}

// ============================================================================
// RouteParams::require_int Tests
// ============================================================================

///|
test "RouteParams::require_int returns Ok for valid integer" {
  let params : RouteParams = {
    params: [("id", "123")],
    query: [],
    path: "/",
    is_fragment: false,
  }
  match params.require_int("id") {
    Ok(v) => assert_eq(v, 123)
    Err(_) => fail("expected Ok")
  }
}

///|
test "RouteParams::require_int returns Err for non-integer" {
  let params : RouteParams = {
    params: [("id", "abc")],
    query: [],
    path: "/",
    is_fragment: false,
  }
  match params.require_int("id") {
    Err(ApiResponse::Error(msg, 400)) =>
      assert_true(msg.contains("Invalid integer parameter"))
    _ => fail("expected Error 400")
  }
}

///|
test "RouteParams::require_int returns Err for missing param" {
  let params = RouteParams::empty()
  match params.require_int("id") {
    Err(ApiResponse::Error(msg, 400)) =>
      assert_true(msg.contains("Missing required parameter"))
    _ => fail("expected Error 400")
  }
}

///|
test "RouteParams::require_int handles negative numbers" {
  let params : RouteParams = {
    params: [("offset", "-5")],
    query: [],
    path: "/",
    is_fragment: false,
  }
  match params.require_int("offset") {
    Ok(v) => assert_eq(v, -5)
    Err(_) => fail("expected Ok")
  }
}

///|
test "RouteParams::require_int handles zero" {
  let params : RouteParams = {
    params: [("page", "0")],
    query: [],
    path: "/",
    is_fragment: false,
  }
  match params.require_int("page") {
    Ok(v) => assert_eq(v, 0)
    Err(_) => fail("expected Ok")
  }
}

// ============================================================================
// RouteParams::require_query Tests
// ============================================================================

///|
test "RouteParams::require_query returns Ok for existing query" {
  let params : RouteParams = {
    params: [],
    query: [("q", "hello"), ("page", "1")],
    path: "/search",
    is_fragment: false,
  }
  match params.require_query("q") {
    Ok(v) => assert_eq(v, "hello")
    Err(_) => fail("expected Ok")
  }
  match params.require_query("page") {
    Ok(v) => assert_eq(v, "1")
    Err(_) => fail("expected Ok")
  }
}

///|
test "RouteParams::require_query returns Err for missing query" {
  let params = RouteParams::empty()
  match params.require_query("q") {
    Err(ApiResponse::Error(msg, 400)) =>
      assert_true(msg.contains("Missing required query parameter"))
    _ => fail("expected Error 400")
  }
}

// ============================================================================
// RouteParams::optional_query Tests
// ============================================================================

///|
test "RouteParams::optional_query returns value when present" {
  let params : RouteParams = {
    params: [],
    query: [("lang", "ja")],
    path: "/",
    is_fragment: false,
  }
  assert_eq(params.optional_query("lang", "en"), "ja")
}

///|
test "RouteParams::optional_query returns default when absent" {
  let params = RouteParams::empty()
  assert_eq(params.optional_query("lang", "en"), "en")
}
