// Tests for Manifest Adapter
//
// Tests for conversion between SolRoutes and RouteManifest

///|
fn make_test_node() -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(@luna.text("test"))
}

///|
fn make_test_handler() -> @router.PageHandler {
  @router.PageHandler(async fn(_props) { make_test_node() })
}

///|
fn make_test_api_handler() -> @router.ApiHandler {
  @router.ApiHandler(async fn(_props) { @js.any("{}") })
}

// =============================================================================
// sol_routes_to_manifest Tests
// =============================================================================

///|
test "sol_routes_to_manifest - empty routes" {
  let routes : Array[@router.SolRoutes] = []
  let manifest = @router.sol_routes_to_manifest(routes)
  inspect(manifest.routes.length(), content="0")
}

///|
test "sol_routes_to_manifest - single page route" {
  let handler = make_test_handler()
  let routes : Array[@router.SolRoutes] = [
    @router.SolRoutes::Page(
      path="/about",
      handler~,
      title="About",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let manifest = @router.sol_routes_to_manifest(routes)
  inspect(manifest.routes.length(), content="1")
  guard manifest.routes[0] is @sol_routes.Dynamic(entry) else {
    fail("Expected Dynamic route")
  }
  inspect(entry.path, content="/about")
  inspect(entry.mode == @sol_routes.RenderMode::Ssr, content="true")
}

///|
test "sol_routes_to_manifest - page with ISR revalidation" {
  let handler = make_test_handler()
  let routes : Array[@router.SolRoutes] = [
    @router.SolRoutes::Page(
      path="/blog/:slug",
      handler~,
      title="Blog",
      meta=[],
      revalidate=Some(3600),
      cache=None,
    ),
  ]
  let manifest = @router.sol_routes_to_manifest(routes)
  guard manifest.routes[0] is @sol_routes.Dynamic(entry) else {
    fail("Expected Dynamic route")
  }
  inspect(entry.path, content="/blog/:slug")
  inspect(entry.param_names, content="[\"slug\"]")
  guard entry.mode is @sol_routes.RenderMode::Isr(revalidate~) else {
    fail("Expected ISR mode")
  }
  inspect(revalidate, content="3600")
}

///|
test "sol_routes_to_manifest - API routes" {
  let handler = make_test_api_handler()
  let routes : Array[@router.SolRoutes] = [
    @router.SolRoutes::Get(path="/api/posts", handler~),
    @router.SolRoutes::Post(path="/api/posts", handler~),
  ]
  let manifest = @router.sol_routes_to_manifest(routes)
  inspect(manifest.routes.length(), content="2")

  // Check GET route
  guard manifest.routes[0] is @sol_routes.Api(get_entry) else {
    fail("Expected Api route for GET")
  }
  inspect(get_entry.path, content="/api/posts")
  inspect(get_entry.http_method == @sol_routes.HttpMethod::Get, content="true")

  // Check POST route
  guard manifest.routes[1] is @sol_routes.Api(post_entry) else {
    fail("Expected Api route for POST")
  }
  inspect(post_entry.http_method == @sol_routes.HttpMethod::Post, content="true")
}

///|
test "sol_routes_to_manifest - nested layout routes" {
  let handler = make_test_handler()
  let routes : Array[@router.SolRoutes] = [
    @router.SolRoutes::Layout(
      segment="/admin",
      layout=fn(_props, child) { child },
      children=[
        @router.SolRoutes::Page(
          path="/dashboard",
          handler~,
          title="Dashboard",
          meta=[],
          revalidate=None,
          cache=None,
        ),
        @router.SolRoutes::Page(
          path="/users",
          handler~,
          title="Users",
          meta=[],
          revalidate=None,
          cache=None,
        ),
      ],
    ),
  ]
  let manifest = @router.sol_routes_to_manifest(routes)
  inspect(manifest.routes.length(), content="2")

  // Verify paths are prefixed correctly
  guard manifest.routes[0] is @sol_routes.Dynamic(e1) else {
    fail("Expected Dynamic route")
  }
  guard manifest.routes[1] is @sol_routes.Dynamic(e2) else {
    fail("Expected Dynamic route")
  }
  inspect(e1.path, content="/admin/dashboard")
  inspect(e2.path, content="/admin/users")
}

///|
test "sol_routes_to_manifest - dynamic params extraction" {
  let handler = make_test_handler()
  let routes : Array[@router.SolRoutes] = [
    @router.SolRoutes::Page(
      path="/users/:id/posts/:postId",
      handler~,
      title="Post",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let manifest = @router.sol_routes_to_manifest(routes)
  guard manifest.routes[0] is @sol_routes.Dynamic(entry) else {
    fail("Expected Dynamic route")
  }
  inspect(entry.param_names, content="[\"id\", \"postId\"]")
  inspect(entry.pattern, content="^/users/([^/]+)/posts/([^/]+)$")
}

///|
test "sol_routes_to_manifest - catch-all route" {
  let handler = make_test_handler()
  let routes : Array[@router.SolRoutes] = [
    @router.SolRoutes::Page(
      path="/docs/[...path]",
      handler~,
      title="Docs",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let manifest = @router.sol_routes_to_manifest(routes)
  guard manifest.routes[0] is @sol_routes.Dynamic(entry) else {
    fail("Expected Dynamic route")
  }
  inspect(entry.path, content="/docs/[...path]")
  inspect(entry.catch_all is Some(_), content="true")
}

// =============================================================================
// manifest_to_sol_routes Tests
// =============================================================================

///|
test "manifest_to_sol_routes - with null factories" {
  let manifest = @sol_routes.RouteManifest::{
    routes: [
      @sol_routes.Static(
        @sol_routes.StaticRouteEntry::new(
          path="/about",
          source="about.md",
          output="about/index.html",
        ),
      ),
    ],
    fallback: @sol_routes.FallbackConfig::NotFound(path="/404.html"),
  }
  let page_factory = @router.null_page_factory()
  let api_factory = @router.null_api_factory()
  let routes = @router.manifest_to_sol_routes(manifest, page_factory, api_factory)
  // Null factory returns None for all entries
  inspect(routes.length(), content="0")
}

///|
test "manifest_to_sol_routes - with custom page factory" {
  let manifest = @sol_routes.RouteManifest::{
    routes: [
      @sol_routes.Static(
        @sol_routes.StaticRouteEntry::new(
          path="/about",
          source="about.md",
          output="about/index.html",
        ),
      ),
      @sol_routes.Dynamic(
        @sol_routes.DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=@sol_routes.RenderMode::Ssr,
        ),
      ),
    ],
    fallback: @sol_routes.FallbackConfig::NotFound(path="/404.html"),
  }

  // Create a factory that handles all routes
  let page_factory = @router.PageHandlerFactory(fn(_entry) {
    Some(make_test_handler())
  })
  let api_factory = @router.null_api_factory()
  let routes = @router.manifest_to_sol_routes(manifest, page_factory, api_factory)
  inspect(routes.length(), content="2")
}

// =============================================================================
// Factory Combinator Tests
// =============================================================================

///|
test "combine_page_factories - returns first matching handler" {
  let factory1 = @router.PageHandlerFactory(fn(entry) {
    if entry.path() == "/about" {
      Some(make_test_handler())
    } else {
      None
    }
  })
  let factory2 = @router.PageHandlerFactory(fn(_entry) {
    Some(make_test_handler())
  })
  let combined = @router.combine_page_factories([factory1, factory2])

  // Test with /about - should match factory1
  let about_entry = @sol_routes.RouteEntry::Static(
    @sol_routes.StaticRouteEntry::new(
      path="/about",
      source="about.md",
      output="about/index.html",
    ),
  )
  let about_result = (combined.0)(about_entry)
  inspect(about_result is Some(_), content="true")

  // Test with /other - should match factory2
  let other_entry = @sol_routes.RouteEntry::Static(
    @sol_routes.StaticRouteEntry::new(
      path="/other",
      source="other.md",
      output="other/index.html",
    ),
  )
  let other_result = (combined.0)(other_entry)
  inspect(other_result is Some(_), content="true")
}

///|
test "combine_api_factories - returns first matching handler" {
  let factory1 = @router.ApiHandlerFactory(fn(entry) {
    if entry.path() == "/api/v1" {
      Some(make_test_api_handler())
    } else {
      None
    }
  })
  let factory2 = @router.ApiHandlerFactory(fn(_entry) {
    Some(make_test_api_handler())
  })
  let combined = @router.combine_api_factories([factory1, factory2])

  // Test with /api/v1 - should match factory1
  let api_entry = @sol_routes.RouteEntry::Api(
    @sol_routes.ApiRouteEntry::new(
      path="/api/v1",
      pattern="^/api/v1$",
      http_method=@sol_routes.HttpMethod::Get,
      source="api/v1.mbt",
    ),
  )
  let result = (combined.0)(api_entry)
  inspect(result is Some(_), content="true")
}

///|
test "null_page_factory - always returns None" {
  let factory = @router.null_page_factory()
  let entry = @sol_routes.RouteEntry::Static(
    @sol_routes.StaticRouteEntry::new(
      path="/test",
      source="test.md",
      output="test/index.html",
    ),
  )
  let result = (factory.0)(entry)
  inspect(result is None, content="true")
}

///|
test "null_api_factory - always returns None" {
  let factory = @router.null_api_factory()
  let entry = @sol_routes.RouteEntry::Api(
    @sol_routes.ApiRouteEntry::new(
      path="/api/test",
      pattern="^/api/test$",
      http_method=@sol_routes.HttpMethod::Get,
      source="api/test.mbt",
    ),
  )
  let result = (factory.0)(entry)
  inspect(result is None, content="true")
}

// =============================================================================
// Mixed Static/Dynamic Manifest Conversion Tests
// =============================================================================

///|
test "manifest_to_sol_routes - preserves ISR revalidation" {
  let manifest = @sol_routes.RouteManifest::{
    routes: [
      @sol_routes.Dynamic(
        @sol_routes.DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=@sol_routes.RenderMode::Isr(revalidate=1800),
        ),
      ),
    ],
    fallback: @sol_routes.FallbackConfig::NotFound(path="/404.html"),
  }
  let page_factory = @router.PageHandlerFactory(fn(_entry) {
    Some(make_test_handler())
  })
  let routes = @router.manifest_to_sol_routes(
    manifest,
    page_factory,
    @router.null_api_factory(),
  )
  inspect(routes.length(), content="1")

  // Check the converted route has revalidate set
  guard routes[0] is @router.SolRoutes::Page(revalidate~, ..) else {
    fail("Expected Page route")
  }
  inspect(revalidate, content="Some(1800)")
}

///|
test "manifest_to_sol_routes - handles Component routes" {
  let manifest = @sol_routes.RouteManifest::{
    routes: [
      @sol_routes.Component(
        @sol_routes.ComponentRouteEntry::new(
          path="/counter",
          source="counter/",
          component_type=@sol_routes.ComponentType::SsrComponent,
          mode=@sol_routes.RenderMode::Ssr,
        ),
      ),
    ],
    fallback: @sol_routes.FallbackConfig::NotFound(path="/404.html"),
  }
  let page_factory = @router.PageHandlerFactory(fn(_entry) {
    Some(make_test_handler())
  })
  let routes = @router.manifest_to_sol_routes(
    manifest,
    page_factory,
    @router.null_api_factory(),
  )
  inspect(routes.length(), content="1")
}
