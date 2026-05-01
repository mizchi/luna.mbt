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
// to_cloudflare_pattern Tests
// ============================================================================

///|
test "to_cloudflare_pattern: static path unchanged" {
  assert_eq!(to_cloudflare_pattern("/users"), "/users")
}

///|
test "to_cloudflare_pattern: root path" {
  assert_eq!(to_cloudflare_pattern("/"), "/")
}

///|
test "to_cloudflare_pattern: colon param becomes wildcard" {
  assert_eq!(to_cloudflare_pattern("/users/:id"), "/users/*")
}

///|
test "to_cloudflare_pattern: multiple colon params become wildcards" {
  assert_eq!(
    to_cloudflare_pattern("/users/:userId/posts/:postId"),
    "/users/*/posts/*",
  )
}

///|
test "to_cloudflare_pattern: bracket param becomes wildcard" {
  assert_eq!(to_cloudflare_pattern("/users/[id]"), "/users/*")
}

///|
test "to_cloudflare_pattern: required catch-all becomes wildcard" {
  assert_eq!(to_cloudflare_pattern("/blog/[...slug]"), "/blog/*")
}

///|
test "to_cloudflare_pattern: optional catch-all becomes wildcard" {
  assert_eq!(to_cloudflare_pattern("/docs/[[...path]]"), "/docs/*")
}

///|
test "to_cloudflare_pattern: nested static segments preserved" {
  assert_eq!(
    to_cloudflare_pattern("/api/v1/users"),
    "/api/v1/users",
  )
}

///|
test "to_cloudflare_pattern: mixed static and dynamic segments" {
  assert_eq!(to_cloudflare_pattern("/api/:version/users"), "/api/*/users")
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

// ============================================================================
// extract_dynamic_patterns Tests
// ============================================================================

///|
test "extract_dynamic_patterns: returns empty for static-only routes" {
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
  let patterns = extract_dynamic_patterns(routes)
  assert_eq!(patterns.length(), 0)
}

///|
test "extract_dynamic_patterns: deduplicates identical patterns" {
  async fn get_handler(_props : PageProps) -> Json {
    Json::null()
  }

  async fn post_handler(_props : PageProps) -> Json {
    Json::null()
  }

  let routes = [
    SolRoutes::Get(path="/api/users", handler=ApiHandler(get_handler)),
    SolRoutes::Post(path="/api/users", handler=ApiHandler(post_handler)),
  ]
  let patterns = extract_dynamic_patterns(routes)
  assert_eq!(patterns.length(), 1)
  assert_eq!(patterns[0], "/api/users")
}

///|
test "extract_dynamic_patterns: returns sorted patterns" {
  async fn handler(_props : PageProps) -> Json {
    Json::null()
  }

  let routes = [
    SolRoutes::Get(path="/api/zebra", handler=ApiHandler(handler)),
    SolRoutes::Get(path="/api/alpha", handler=ApiHandler(handler)),
  ]
  let patterns = extract_dynamic_patterns(routes)
  assert_eq!(patterns.length(), 2)
  assert_eq!(patterns[0], "/api/alpha")
  assert_eq!(patterns[1], "/api/zebra")
}
