// Tests for Manifest Merge Utilities

// =============================================================================
// merge_manifests Tests
// =============================================================================

///|
test "merge_manifests - empty manifests" {
  let explicit = RouteManifest::empty()
  let file_based = RouteManifest::empty()
  let merged = merge_manifests(explicit, file_based)
  inspect(merged.routes.length(), content="0")
}

///|
test "merge_manifests - only explicit routes" {
  let explicit = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let file_based = RouteManifest::empty()
  let merged = merge_manifests(explicit, file_based)
  inspect(merged.routes.length(), content="1")
  inspect(merged.routes[0].path(), content="/about")
}

///|
test "merge_manifests - only file_based routes" {
  let explicit = RouteManifest::empty()
  let file_based = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/guide/intro",
          source="guide/intro.md",
          output="guide/intro.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let merged = merge_manifests(explicit, file_based)
  inspect(merged.routes.length(), content="1")
  inspect(merged.routes[0].path(), content="/guide/intro")
}

///|
test "merge_manifests - explicit takes precedence" {
  let explicit = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="custom-about.md",
          output="about.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let file_based = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.md",
          output="about/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/guide",
          source="guide.md",
          output="guide/index.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let merged = merge_manifests(explicit, file_based)
  inspect(merged.routes.length(), content="2")
  // First route should be the explicit one
  guard merged.routes[0] is Static(entry) else { fail("Expected Static") }
  inspect(entry.source, content="custom-about.md")
}

///|
test "merge_manifests - explicit fallback takes precedence" {
  let explicit = RouteManifest::{
    routes: [],
    fallback: FallbackConfig::Spa(entry="/index.html"),
  }
  let file_based = RouteManifest::{
    routes: [],
    fallback: FallbackConfig::NotFound(path="/custom-404.html"),
  }
  let merged = merge_manifests(explicit, file_based)
  inspect(merged.fallback.is_spa(), content="true")
}

///|
test "merge_manifests - default fallback uses file_based" {
  let explicit = RouteManifest::{
    routes: [],
    fallback: FallbackConfig::NotFound(path="/404.html"), // default
  }
  let file_based = RouteManifest::{
    routes: [],
    fallback: FallbackConfig::Spa(entry="/spa.html"),
  }
  let merged = merge_manifests(explicit, file_based)
  inspect(merged.fallback.is_spa(), content="true")
}

// =============================================================================
// merge_all_manifests Tests
// =============================================================================

///|
test "merge_all_manifests - empty array" {
  let manifests : Array[RouteManifest] = []
  let result = merge_all_manifests(manifests)
  inspect(result.routes.length(), content="0")
}

///|
test "merge_all_manifests - single manifest" {
  let manifests = [
    RouteManifest::{
      routes: [
        Static(StaticRouteEntry::new(path="/", source="index.md", output="index.html")),
      ],
      fallback: FallbackConfig::default(),
    },
  ]
  let result = merge_all_manifests(manifests)
  inspect(result.routes.length(), content="1")
}

///|
test "merge_all_manifests - multiple manifests" {
  let manifests = [
    RouteManifest::{
      routes: [
        Static(StaticRouteEntry::new(path="/a", source="a.md", output="a.html")),
      ],
      fallback: FallbackConfig::default(),
    },
    RouteManifest::{
      routes: [
        Static(StaticRouteEntry::new(path="/b", source="b.md", output="b.html")),
      ],
      fallback: FallbackConfig::default(),
    },
    RouteManifest::{
      routes: [
        Static(StaticRouteEntry::new(path="/c", source="c.md", output="c.html")),
      ],
      fallback: FallbackConfig::default(),
    },
  ]
  let result = merge_all_manifests(manifests)
  inspect(result.routes.length(), content="3")
}

// =============================================================================
// filter_by_mode Tests
// =============================================================================

///|
test "filter_by_mode - API routes always included" {
  let manifest = RouteManifest::{
    routes: [
      Api(
        ApiRouteEntry::new(
          path="/api/test",
          pattern="^/api/test$",
          http_method=HttpMethod::Get,
          source="api.mbt",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let filtered = filter_by_mode(manifest, RenderMode::Ssr)
  inspect(filtered.routes.length(), content="1")
  let filtered_spa = filter_by_mode(manifest, RenderMode::Spa)
  inspect(filtered_spa.routes.length(), content="1")
}

///|
test "filter_by_mode - static routes in SPA mode" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let filtered = filter_by_mode(manifest, RenderMode::Spa)
  inspect(filtered.routes.length(), content="1")
}

///|
test "filter_by_mode - dynamic SSR routes" {
  let manifest = RouteManifest::{
    routes: [
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let filtered = filter_by_mode(manifest, RenderMode::Ssr)
  inspect(filtered.routes.length(), content="1")
}

///|
test "filter_by_mode - preserves fallback" {
  let manifest = RouteManifest::{
    routes: [],
    fallback: FallbackConfig::Spa(entry="/index.html"),
  }
  let filtered = filter_by_mode(manifest, RenderMode::Ssr)
  inspect(filtered.fallback.is_spa(), content="true")
}

// =============================================================================
// get_static_routes Tests
// =============================================================================

///|
test "get_static_routes - mixed manifest" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.md", output="index.html"),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.md",
          output="about.html",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let statics = get_static_routes(manifest)
  inspect(statics.length(), content="2")
  inspect(statics[0].path, content="/")
  inspect(statics[1].path, content="/about")
}

///|
test "get_static_routes - empty when no static routes" {
  let manifest = RouteManifest::{
    routes: [
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let statics = get_static_routes(manifest)
  inspect(statics.length(), content="0")
}

// =============================================================================
// get_dynamic_routes Tests
// =============================================================================

///|
test "get_dynamic_routes - mixed manifest" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.md", output="index.html"),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/users/:id",
          pattern="^/users/([^/]+)$",
          param_names=["id"],
          source="users/[id].md",
          mode=RenderMode::Isr(revalidate=3600),
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let dynamics = get_dynamic_routes(manifest)
  inspect(dynamics.length(), content="2")
  inspect(dynamics[0].path, content="/blog/:slug")
  inspect(dynamics[1].path, content="/users/:id")
}

// =============================================================================
// get_api_routes Tests
// =============================================================================

///|
test "get_api_routes - mixed manifest" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.md", output="index.html"),
      ),
      Api(
        ApiRouteEntry::new(
          path="/api/posts",
          pattern="^/api/posts$",
          http_method=HttpMethod::Get,
          source="api/posts.mbt",
        ),
      ),
      Api(
        ApiRouteEntry::new(
          path="/api/posts",
          pattern="^/api/posts$",
          http_method=HttpMethod::Post,
          source="api/posts.mbt",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let apis = get_api_routes(manifest)
  inspect(apis.length(), content="2")
  inspect(apis[0].http_method, content="Get")
  inspect(apis[1].http_method, content="Post")
}

// =============================================================================
// find_route Tests
// =============================================================================

///|
test "find_route - finds existing route" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
      ),
      Static(
        StaticRouteEntry::new(
          path="/guide/intro",
          source="guide/intro.md",
          output="guide/intro.html",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let result = find_route(manifest, "/about")
  inspect(result is Some(_), content="true")
  guard result is Some(route) else { fail("Expected Some") }
  inspect(route.path(), content="/about")
}

///|
test "find_route - returns None for non-existent route" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let result = find_route(manifest, "/not-found")
  inspect(result is None, content="true")
}

///|
test "find_route - works with different route types" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
      Api(
        ApiRouteEntry::new(
          path="/api/posts",
          pattern="^/api/posts$",
          http_method=HttpMethod::Get,
          source="api/posts.mbt",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let static_result = find_route(manifest, "/about")
  inspect(static_result is Some(_), content="true")
  let dynamic_result = find_route(manifest, "/blog/:slug")
  inspect(dynamic_result is Some(_), content="true")
  let api_result = find_route(manifest, "/api/posts")
  inspect(api_result is Some(_), content="true")
}

// =============================================================================
// find_static_route Tests
// =============================================================================

///|
test "find_static_route - finds static route" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let result = find_static_route(manifest, "/about")
  inspect(result is Some(_), content="true")
  guard result is Some(entry) else { fail("Expected Some") }
  inspect(entry.source, content="about.md")
}

///|
test "find_static_route - ignores dynamic routes" {
  let manifest = RouteManifest::{
    routes: [
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let result = find_static_route(manifest, "/blog/:slug")
  inspect(result is None, content="true")
}

// =============================================================================
// get_route_path Tests
// =============================================================================

///|
test "get_route_path - all route types" {
  let static_route : RouteEntry = Static(
    StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
  )
  let dynamic_route : RouteEntry = Dynamic(
    DynamicRouteEntry::new(
      path="/blog/:slug",
      pattern="^/blog/([^/]+)$",
      param_names=["slug"],
      source="blog/[slug].md",
      mode=RenderMode::Ssr,
    ),
  )
  let api_route : RouteEntry = Api(
    ApiRouteEntry::new(
      path="/api/posts",
      pattern="^/api/posts$",
      http_method=HttpMethod::Get,
      source="api/posts.mbt",
    ),
  )
  let component_route : RouteEntry = Component(
    ComponentRouteEntry::new(
      path="/counter",
      source="counter/",
      component_type=ComponentType::SsrComponent,
      mode=RenderMode::Ssr,
    ),
  )
  inspect(get_route_path(static_route), content="/about")
  inspect(get_route_path(dynamic_route), content="/blog/:slug")
  inspect(get_route_path(api_route), content="/api/posts")
  inspect(get_route_path(component_route), content="/counter")
}
