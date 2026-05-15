// Tests for router helpers

// ============================================================================
// ApiResponse::to_json() Tests
// ============================================================================

///|
test "ApiResponse::Json returns the wrapped Json value directly" {
  let data : Json = { "hello": "world" }
  let result = ApiResponse::Json(data).to_json()
  assert_eq(result.stringify(), "{\"hello\":\"world\"}")
}

///|
test "ApiResponse::Json with array value" {
  let data : Json = [1, 2, 3]
  let result = ApiResponse::Json(data).to_json()
  assert_eq(result.stringify(), "[1,2,3]")
}

///|
test "ApiResponse::Redirect produces redirect and status fields" {
  let result = ApiResponse::Redirect("/home", 302).to_json()
  assert_true(result.stringify().contains("\"redirect\":\"/home\""))
  assert_true(result.stringify().contains("\"status\":302"))
}

///|
test "ApiResponse::NotFound produces error and status 404" {
  let result = ApiResponse::NotFound("Page not found").to_json()
  assert_true(result.stringify().contains("\"error\":\"Page not found\""))
  assert_true(result.stringify().contains("\"status\":404"))
}

///|
test "ApiResponse::Error produces error and custom status" {
  let result = ApiResponse::Error("Something went wrong", 500).to_json()
  assert_true(result.stringify().contains("\"status\":500"))
}

// ============================================================================
// ok() builder Tests
// ============================================================================

///|
test "ok() with single pair produces Json variant" {
  let resp = ok([("status", "ok".to_json())])
  let json = resp.to_json()
  assert_eq(json.stringify(), "{\"status\":\"ok\"}")
}

///|
test "ok() with multiple pairs" {
  let resp = ok([("id", (42 : Int).to_json()), ("name", "Alice".to_json())])
  let json = resp.to_json()
  match json {
    Object(m) => {
      assert_true(m.contains("id"))
      assert_true(m.contains("name"))
    }
    _ => fail("expected Object")
  }
}

///|
test "ok() with empty pairs produces empty object" {
  let resp = ok([])
  let json = resp.to_json()
  match json {
    Object(m) => assert_eq(m.length(), 0)
    _ => fail("expected empty object")
  }
}

// ============================================================================
// redirect_to() Tests
// ============================================================================

///|
test "redirect_to uses 302 by default" {
  let resp = redirect_to("/login")
  match resp {
    ApiResponse::Redirect(url, status) => {
      assert_eq(url, "/login")
      assert_eq(status, 302)
    }
    _ => fail("expected Redirect variant")
  }
}

///|
test "redirect_to accepts explicit status" {
  let resp = redirect_to("/home", status=301)
  match resp {
    ApiResponse::Redirect(url, status) => {
      assert_eq(url, "/home")
      assert_eq(status, 301)
    }
    _ => fail("expected Redirect variant")
  }
}

// ============================================================================
// redirect_permanent_to() Tests
// ============================================================================

///|
test "redirect_permanent_to uses status 301" {
  let resp = redirect_permanent_to("/new-location")
  match resp {
    ApiResponse::Redirect(url, status) => {
      assert_eq(url, "/new-location")
      assert_eq(status, 301)
    }
    _ => fail("expected Redirect variant")
  }
}

///|
test "redirect_permanent_to to_json matches expected shape" {
  let json = redirect_permanent_to("/permanent").to_json()
  assert_true(json.stringify().contains("\"redirect\":\"/permanent\""))
  assert_true(json.stringify().contains("\"status\":301"))
}

// ============================================================================
// not_found_response() Tests
// ============================================================================

///|
test "not_found_response uses default message" {
  let resp = not_found_response()
  match resp {
    ApiResponse::NotFound(msg) => assert_eq(msg, "Not found")
    _ => fail("expected NotFound variant")
  }
}

///|
test "not_found_response accepts custom message" {
  let resp = not_found_response(message="User not found")
  match resp {
    ApiResponse::NotFound(msg) => assert_eq(msg, "User not found")
    _ => fail("expected NotFound variant")
  }
}

///|
test "not_found_response to_json has status 404" {
  let json = not_found_response().to_json()
  assert_true(json.stringify().contains("\"error\":\"Not found\""))
  assert_true(json.stringify().contains("\"status\":404"))
}

// ============================================================================
// error_response() Tests
// ============================================================================

///|
test "error_response uses status 500 by default" {
  let resp = error_response("Internal failure")
  match resp {
    ApiResponse::Error(msg, status) => {
      assert_eq(msg, "Internal failure")
      assert_eq(status, 500)
    }
    _ => fail("expected Error variant")
  }
}

///|
test "error_response accepts custom status" {
  let resp = error_response("Service unavailable", status=503)
  match resp {
    ApiResponse::Error(msg, status) => {
      assert_eq(msg, "Service unavailable")
      assert_eq(status, 503)
    }
    _ => fail("expected Error variant")
  }
}

///|
test "error_response to_json has correct fields" {
  let json = error_response("oops", status=503).to_json()
  assert_true(json.stringify().contains("\"error\":\"oops\""))
  assert_true(json.stringify().contains("\"status\":503"))
}

// ============================================================================
// bad_request() Tests
// ============================================================================

///|
test "bad_request produces Error variant with status 400" {
  let resp = bad_request("Missing field")
  match resp {
    ApiResponse::Error(msg, status) => {
      assert_eq(msg, "Missing field")
      assert_eq(status, 400)
    }
    _ => fail("expected Error variant")
  }
}

///|
test "bad_request to_json" {
  let json = bad_request("invalid input").to_json()
  assert_true(json.stringify().contains("\"error\":\"invalid input\""))
  assert_true(json.stringify().contains("\"status\":400"))
}

// ============================================================================
// unauthorized() Tests
// ============================================================================

///|
test "unauthorized uses default message and status 401" {
  let resp = unauthorized()
  match resp {
    ApiResponse::Error(msg, status) => {
      assert_eq(msg, "Unauthorized")
      assert_eq(status, 401)
    }
    _ => fail("expected Error variant")
  }
}

///|
test "unauthorized accepts custom message" {
  let resp = unauthorized(message="Token expired")
  match resp {
    ApiResponse::Error(msg, status) => {
      assert_eq(msg, "Token expired")
      assert_eq(status, 401)
    }
    _ => fail("expected Error variant")
  }
}

///|
test "unauthorized to_json" {
  let json = unauthorized().to_json()
  assert_true(json.stringify().contains("\"error\":\"Unauthorized\""))
  assert_true(json.stringify().contains("\"status\":401"))
}

// ============================================================================
// forbidden() Tests
// ============================================================================

///|
test "forbidden uses default message and status 403" {
  let resp = forbidden()
  match resp {
    ApiResponse::Error(msg, status) => {
      assert_eq(msg, "Forbidden")
      assert_eq(status, 403)
    }
    _ => fail("expected Error variant")
  }
}

///|
test "forbidden accepts custom message" {
  let resp = forbidden(message="Admin only")
  match resp {
    ApiResponse::Error(msg, status) => {
      assert_eq(msg, "Admin only")
      assert_eq(status, 403)
    }
    _ => fail("expected Error variant")
  }
}

///|
test "forbidden to_json" {
  let json = forbidden().to_json()
  assert_true(json.stringify().contains("\"error\":\"Forbidden\""))
  assert_true(json.stringify().contains("\"status\":403"))
}

// ============================================================================
// Route helper: page() Tests
// ============================================================================

///|
test "page() returns SolRoutes::Page with correct path" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let route = page("/about", handler)
  match route {
    SolRoutes::Page(path~, ..) => assert_eq(path, "/about")
    _ => fail("expected Page variant")
  }
}

///|
test "page() stores the title" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let route = page("/", handler, title="Home")
  match route {
    SolRoutes::Page(title~, ..) => assert_eq(title, "Home")
    _ => fail("expected Page variant")
  }
}

///|
test "page() default title is empty string" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let route = page("/", handler)
  match route {
    SolRoutes::Page(title~, ..) => assert_eq(title, "")
    _ => fail("expected Page variant")
  }
}

///|
test "page() default revalidate is None" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let route = page("/", handler)
  match route {
    SolRoutes::Page(revalidate~, ..) => assert_true(revalidate is None)
    _ => fail("expected Page variant")
  }
}

///|
test "page() stores revalidate interval" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let route = page("/", handler, revalidate=Some(60))
  match route {
    SolRoutes::Page(revalidate~, ..) => assert_eq(revalidate, Some(60))
    _ => fail("expected Page variant")
  }
}

///|
test "page() wraps route-level style and script assets" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let route = page("/", handler, styles=["./home.css"], scripts=[
    "./home.client.ts",
  ])
  match route {
    SolRoutes::WithAssets(styles~, scripts~, children~) => {
      assert_eq(styles, ["./home.css"])
      assert_eq(scripts, ["./home.client.ts"])
      assert_eq(children.length(), 1)
    }
    _ => fail("expected WithAssets variant")
  }
}

// ============================================================================
// Route helper: api_*() Tests
// ============================================================================

///|
fn empty_json() -> Json {
  let obj : Map[String, Json] = {}
  obj.to_json()
}

///|
test "api_get() returns SolRoutes::Get with correct path" {
  async fn handler(_props : PageProps) -> Json {
    empty_json()
  }

  let route = api_get("/api/users/:id", handler)
  match route {
    SolRoutes::Get(path~, ..) => assert_eq(path, "/api/users/:id")
    _ => fail("expected Get variant")
  }
}

///|
test "api_post() returns SolRoutes::Post with correct path" {
  async fn handler(_props : PageProps) -> Json {
    empty_json()
  }

  let route = api_post("/api/create", handler)
  match route {
    SolRoutes::Post(path~, ..) => assert_eq(path, "/api/create")
    _ => fail("expected Post variant")
  }
}

///|
test "api_put() returns SolRoutes::Put with correct path" {
  async fn handler(_props : PageProps) -> Json {
    empty_json()
  }

  let route = api_put("/api/update", handler)
  match route {
    SolRoutes::Put(path~, ..) => assert_eq(path, "/api/update")
    _ => fail("expected Put variant")
  }
}

///|
test "api_delete() returns SolRoutes::Delete with correct path" {
  async fn handler(_props : PageProps) -> Json {
    empty_json()
  }

  let route = api_delete("/api/remove/:id", handler)
  match route {
    SolRoutes::Delete(path~, ..) => assert_eq(path, "/api/remove/:id")
    _ => fail("expected Delete variant")
  }
}

///|
test "api_patch() returns SolRoutes::Patch with correct path" {
  async fn handler(_props : PageProps) -> Json {
    empty_json()
  }

  let route = api_patch("/api/partial/:id", handler)
  match route {
    SolRoutes::Patch(path~, ..) => assert_eq(path, "/api/partial/:id")
    _ => fail("expected Patch variant")
  }
}

// ============================================================================
// wrap() Tests
// ============================================================================

///|
test "wrap() returns SolRoutes::Layout with segment" {
  fn layout_fn(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  let route = wrap("/admin", layout_fn, [])
  match route {
    SolRoutes::Layout(segment~, ..) => assert_eq(segment, "/admin")
    _ => fail("expected Layout variant")
  }
}

///|
test "wrap() stores children count" {
  fn layout_fn(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  async fn handler(_props : PageProps) -> Json {
    empty_json()
  }

  let route = wrap("/api", layout_fn, [api_get("/data", handler)])
  match route {
    SolRoutes::Layout(children~, ..) => assert_eq(children.length(), 1)
    _ => fail("expected Layout variant")
  }
}

// ============================================================================
// with_mw() Tests
// ============================================================================

///|
test "with_mw() returns SolRoutes::WithMiddleware" {
  let route = with_mw([], [])
  assert_true(route is SolRoutes::WithMiddleware(_))
}

///|
test "with_mw() stores children" {
  async fn handler(_props : PageProps) -> Json {
    empty_json()
  }

  let route = with_mw([], [api_get("/a", handler), api_post("/b", handler)])
  match route {
    SolRoutes::WithMiddleware(children~, ..) => assert_eq(children.length(), 2)
    _ => fail("expected WithMiddleware variant")
  }
}

///|
test "with_style() attaches component-local CSS to a ServerNode" {
  let node = with_style(
    "./upload_panel.css",
    @luna.h("section", [], [@luna.text("Upload")]),
  )
  let assets = node.declared_assets()
  assert_eq(assets.styles, ["./upload_panel.css"])
  assert_eq(assets.scripts.length(), 0)
}

///|
test "server_nodes() composes component ServerNodes and keeps assets ordered" {
  let node = server_nodes([
    with_style("./a.css", @luna.text("A")),
    with_style("./b.css", @luna.text("B")),
  ])
  assert_eq(node.declared_assets().styles, ["./a.css", "./b.css"])
}
