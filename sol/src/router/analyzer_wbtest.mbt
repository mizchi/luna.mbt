// Tests for analyzer.mbt pure functions

// ============================================================================
// has_dynamic_segment Tests
// ============================================================================

///|
test "has_dynamic_segment: colon param returns true" {
  assert_true!(has_dynamic_segment("/users/:id"))
}

///|
test "has_dynamic_segment: multiple colon params returns true" {
  assert_true!(has_dynamic_segment("/users/:userId/posts/:postId"))
}

///|
test "has_dynamic_segment: colon at root level returns true" {
  assert_true!(has_dynamic_segment("/:id"))
}

///|
test "has_dynamic_segment: bracket param returns true" {
  assert_true!(has_dynamic_segment("/users/[id]"))
}

///|
test "has_dynamic_segment: bracket param in middle returns true" {
  assert_true!(has_dynamic_segment("/users/[id]/posts"))
}

///|
test "has_dynamic_segment: static path returns false" {
  assert_false!(has_dynamic_segment("/users"))
}

///|
test "has_dynamic_segment: root path returns false" {
  assert_false!(has_dynamic_segment("/"))
}

///|
test "has_dynamic_segment: static nested path returns false" {
  assert_false!(has_dynamic_segment("/users/profile/settings"))
}

///|
test "has_dynamic_segment: catch-all [...slug] returns false (not dynamic param)" {
  assert_false!(has_dynamic_segment("/blog/[...slug]"))
}

///|
test "has_dynamic_segment: optional catch-all [[...slug]] returns false" {
  assert_false!(has_dynamic_segment("/blog/[[...slug]]"))
}

///|
test "has_dynamic_segment: empty path returns false" {
  assert_false!(has_dynamic_segment(""))
}

// ============================================================================
// has_catch_all Tests
// ============================================================================

///|
test "has_catch_all: required catch-all [...slug] returns true" {
  assert_true!(has_catch_all("/blog/[...slug]"))
}

///|
test "has_catch_all: optional catch-all [[...slug]] returns true" {
  assert_true!(has_catch_all("/docs/[[...path]]"))
}

///|
test "has_catch_all: catch-all at root returns true" {
  assert_true!(has_catch_all("/[...all]"))
}

///|
test "has_catch_all: static path returns false" {
  assert_false!(has_catch_all("/users"))
}

///|
test "has_catch_all: colon param returns false" {
  assert_false!(has_catch_all("/users/:id"))
}

///|
test "has_catch_all: bracket param returns false" {
  assert_false!(has_catch_all("/users/[id]"))
}

///|
test "has_catch_all: empty path returns false" {
  assert_false!(has_catch_all(""))
}

///|
test "has_catch_all: root path returns false" {
  assert_false!(has_catch_all("/"))
}

// ============================================================================
// analyze_routes Tests
// ============================================================================

///|
test "analyze_routes: static page route classified as Static" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("home"))
  }

  let routes = [
    SolRoutes::Page(
      path="/",
      handler=PageHandler(handler),
      title="Home",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_eq!(analyzed[0].pattern, "/")
  assert_true!(analyzed[0].kind is RouteKind::Static)
}

///|
test "analyze_routes: dynamic page route classified as Dynamic" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("user"))
  }

  let routes = [
    SolRoutes::Page(
      path="/users/:id",
      handler=PageHandler(handler),
      title="User",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "Dynamic path parameter")
}

///|
test "analyze_routes: ISR page classified as Dynamic" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("isr"))
  }

  let routes = [
    SolRoutes::Page(
      path="/blog",
      handler=PageHandler(handler),
      title="Blog",
      meta=[],
      revalidate=Some(60),
      cache=None,
    ),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "ISR enabled (revalidate)")
}

///|
test "analyze_routes: catch-all page classified as Dynamic" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("catch"))
  }

  let routes = [
    SolRoutes::Page(
      path="/docs/[...slug]",
      handler=PageHandler(handler),
      title="Docs",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "Catch-all route")
}

///|
test "analyze_routes: GET endpoint classified as Dynamic" {
  async fn handler(_props : PageProps) -> Json {
    Json::null()
  }

  let routes = [
    SolRoutes::Get(path="/api/users", handler=ApiHandler(handler)),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "API GET endpoint")
}

///|
test "analyze_routes: POST endpoint classified as Dynamic" {
  async fn handler(_props : PageProps) -> Json {
    Json::null()
  }

  let routes = [
    SolRoutes::Post(path="/api/users", handler=ApiHandler(handler)),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "API POST endpoint")
}

///|
test "analyze_routes: PUT endpoint classified as Dynamic" {
  async fn handler(_props : PageProps) -> Json {
    Json::null()
  }

  let routes = [
    SolRoutes::Put(path="/api/users/:id", handler=ApiHandler(handler)),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "API PUT endpoint")
}

///|
test "analyze_routes: DELETE endpoint classified as Dynamic" {
  async fn handler(_props : PageProps) -> Json {
    Json::null()
  }

  let routes = [
    SolRoutes::Delete(path="/api/users/:id", handler=ApiHandler(handler)),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "API DELETE endpoint")
}

///|
test "analyze_routes: PATCH endpoint classified as Dynamic" {
  async fn handler(_props : PageProps) -> Json {
    Json::null()
  }

  let routes = [
    SolRoutes::Patch(path="/api/users/:id", handler=ApiHandler(handler)),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_true!(analyzed[0].kind is RouteKind::Dynamic)
  assert_eq!(analyzed[0].reason, "API PATCH endpoint")
}

///|
test "analyze_routes: Layout children get full path prefix" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("admin"))
  }

  fn layout_fn(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  let routes = [
    SolRoutes::Layout(segment="/admin", layout=layout_fn, children=[
      SolRoutes::Page(
        path="/dashboard",
        handler=PageHandler(handler),
        title="Dashboard",
        meta=[],
        revalidate=None,
        cache=None,
      ),
    ]),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_eq!(analyzed[0].pattern, "/admin/dashboard")
  assert_true!(analyzed[0].kind is RouteKind::Static)
}

///|
test "analyze_routes: WithMiddleware transparent to children" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("page"))
  }

  let routes = [
    SolRoutes::WithMiddleware(
      middleware=[],
      children=[
        SolRoutes::Page(
          path="/protected",
          handler=PageHandler(handler),
          title="Protected",
          meta=[],
          revalidate=None,
          cache=None,
        ),
      ],
    ),
  ]
  let analyzed = analyze_routes(routes)
  assert_eq!(analyzed.length(), 1)
  assert_eq!(analyzed[0].pattern, "/protected")
}
