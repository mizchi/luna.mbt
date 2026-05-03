// Tests for SSG + Dynamic Route Coexistence
//
// Verifies that RouteManifest can handle mixed Static and Dynamic routes

// =============================================================================
// RouteManifest Mixed Routes Tests
// =============================================================================

///|
test "RouteManifest - can contain both Static and Dynamic routes" {
  let manifest = RouteManifest::{
    routes: [
      // Static routes (SSG)
      Static(
        StaticRouteEntry::new(path="/", source="index.md", output="index.html"),
      ),
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.md",
          output="about/index.html",
        ),
      ),
      // Dynamic routes (SSR)
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
      // Dynamic routes (ISR)
      Dynamic(
        DynamicRouteEntry::new(
          path="/docs/:...path",
          pattern="^/docs/(.*)$",
          param_names=["path"],
          source="docs/[...path].md",
          mode=RenderMode::Isr(revalidate=3600),
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  // Verify route counts
  let static_count = manifest.routes.filter(fn(r) { r.is_static() }).length()
  let dynamic_count = manifest.routes.filter(fn(r) { r.is_dynamic() }).length()
  inspect(static_count, content="2")
  inspect(dynamic_count, content="2")
  inspect(manifest.routes.length(), content="4")
}

///|
test "RouteEntry::is_static - correctly identifies static routes" {
  let static_entry : RouteEntry = Static(
    StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
  )
  let dynamic_entry : RouteEntry = Dynamic(
    DynamicRouteEntry::new(
      path="/blog/:slug",
      pattern="^/blog/([^/]+)$",
      param_names=["slug"],
      source="blog/[slug].md",
      mode=RenderMode::Ssr,
    ),
  )
  inspect(static_entry.is_static(), content="true")
  inspect(static_entry.is_dynamic(), content="false")
  inspect(dynamic_entry.is_static(), content="false")
  inspect(dynamic_entry.is_dynamic(), content="true")
}

///|
test "RouteEntry::path - returns path for all route types" {
  let static_entry : RouteEntry = Static(
    StaticRouteEntry::new(path="/about", source="about.md", output="about.html"),
  )
  let dynamic_entry : RouteEntry = Dynamic(
    DynamicRouteEntry::new(
      path="/blog/:slug",
      pattern="^/blog/([^/]+)$",
      param_names=["slug"],
      source="blog/[slug].md",
      mode=RenderMode::Ssr,
    ),
  )
  let api_entry : RouteEntry = Api(
    ApiRouteEntry::new(
      path="/api/posts",
      pattern="^/api/posts$",
      http_method=HttpMethod::Get,
      source="api/posts.mbt",
    ),
  )
  inspect(static_entry.path(), content="/about")
  inspect(dynamic_entry.path(), content="/blog/:slug")
  inspect(api_entry.path(), content="/api/posts")
}

// =============================================================================
// RenderMode Tests
// =============================================================================

///|
test "RenderMode - SSR mode" {
  let mode = RenderMode::Ssr
  inspect(mode.requires_server(), content="true")
  inspect(mode.revalidate_seconds(), content="None")
}

///|
test "RenderMode - ISR mode with revalidation" {
  let mode = RenderMode::Isr(revalidate=3600)
  inspect(mode.requires_server(), content="true")
  inspect(mode.revalidate_seconds(), content="Some(3600)")
}

///|
test "RenderMode - SPA mode" {
  let mode = RenderMode::Spa
  inspect(mode.requires_server(), content="false")
  inspect(mode.revalidate_seconds(), content="None")
}

///|
test "RenderMode::default - returns SSR" {
  let mode = RenderMode::default()
  inspect(mode == RenderMode::Ssr, content="true")
}

// =============================================================================
// Mixed Manifest Scenarios
// =============================================================================

///|
test "Mixed manifest - documentation site scenario" {
  // Simulates a typical documentation site with:
  // - Static pages for main content
  // - Dynamic routes for blog posts
  // - ISR routes for API-backed content
  let manifest = RouteManifest::{
    routes: [
      // Home and static pages
      Static(
        StaticRouteEntry::new(path="/", source="index.md", output="index.html"),
      ),
      Static(
        StaticRouteEntry::new(
          path="/guide/intro",
          source="guide/intro.md",
          output="guide/intro/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/guide/setup",
          source="guide/setup.md",
          output="guide/setup/index.html",
        ),
      ),
      // Dynamic blog (SSR - always fresh)
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
      // API reference (ISR - cached for 1 hour)
      Dynamic(
        DynamicRouteEntry::new(
          path="/api-ref/:module",
          pattern="^/api-ref/([^/]+)$",
          param_names=["module"],
          source="api-ref/[module].md",
          mode=RenderMode::Isr(revalidate=3600),
        ),
      ),
      // API endpoints
      Api(
        ApiRouteEntry::new(
          path="/api/search",
          pattern="^/api/search$",
          http_method=HttpMethod::Get,
          source="api/search.mbt",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  // Count by type
  let static_routes = manifest.routes.filter(fn(r) { r.is_static() })
  let dynamic_routes = manifest.routes.filter(fn(r) { r.is_dynamic() })
  let api_routes = manifest.routes.filter(fn(r) { r.is_api() })
  inspect(static_routes.length(), content="3")
  inspect(dynamic_routes.length(), content="2")
  inspect(api_routes.length(), content="1")

  // Verify ISR route
  let isr_routes = dynamic_routes.filter(fn(r) {
    match r {
      Dynamic(e) =>
        match e.mode {
          Isr(_) => true
          _ => false
        }
      _ => false
    }
  })
  inspect(isr_routes.length(), content="1")
}

///|
test "Mixed manifest - e-commerce scenario with catch-all" {
  // Simulates an e-commerce site with:
  // - Static category pages
  // - Dynamic product pages (ISR)
  // - Catch-all for legacy URLs
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.md", output="index.html"),
      ),
      Static(
        StaticRouteEntry::new(
          path="/categories",
          source="categories.md",
          output="categories/index.html",
        ),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/products/:id",
          pattern="^/products/([^/]+)$",
          param_names=["id"],
          source="products/[id].md",
          mode=RenderMode::Isr(revalidate=300), // 5 minutes
        ),
      ),
      Dynamic(DynamicRouteEntry::{
        path: "/legacy/:...path",
        pattern: "^/legacy/(.*)$",
        param_names: ["path"],
        source: "legacy/[...path].md",
        mode: RenderMode::Ssr,
        layout: None,
        catch_all: Some(CatchAllInfo::{ name: "path", optional: false }),
        title: None,
        islands: [],
      }),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  // Verify catch-all route exists
  let catch_all_routes = manifest.routes.filter(fn(r) {
    match r {
      Dynamic(e) => e.catch_all is Some(_)
      _ => false
    }
  })
  inspect(catch_all_routes.length(), content="1")

  // Verify ISR revalidation time
  let product_route = manifest.routes
    .iter()
    .find_first(fn(r) { r.path() == "/products/:id" })
  guard product_route is Some(Dynamic(entry)) else {
    fail("Expected Dynamic route for /products/:id")
  }
  inspect(entry.mode.revalidate_seconds(), content="Some(300)")
}

// =============================================================================
// FallbackConfig Tests
// =============================================================================

///|
test "FallbackConfig - NotFound" {
  let config = FallbackConfig::NotFound(path="/404.html")
  inspect(config.is_spa(), content="false")
  inspect(config.spa_entry(), content="None")
}

///|
test "FallbackConfig - SPA" {
  let config = FallbackConfig::Spa(entry="/index.html")
  inspect(config.is_spa(), content="true")
  inspect(config.spa_entry(), content="Some(\"/index.html\")")
}

///|
test "FallbackConfig - SpaPrefix" {
  let config = FallbackConfig::SpaPrefix(prefix="/app", entry="/app/index.html")
  inspect(config.is_spa(), content="true")
  inspect(config.spa_entry(), content="Some(\"/app/index.html\")")
}

// =============================================================================
// Pattern Extraction Integration
// =============================================================================

///|
test "extract_url_pattern - static path" {
  let (pattern, params) = extract_url_pattern("/about")
  inspect(pattern, content="^/about$")
  inspect(params.length(), content="0")
}

///|
test "extract_url_pattern - single dynamic segment" {
  let (pattern, params) = extract_url_pattern("/blog/:slug")
  inspect(pattern, content="^/blog/([^/]+)$")
  inspect(params, content="[\"slug\"]")
}

///|
test "extract_url_pattern - multiple dynamic segments" {
  let (pattern, params) = extract_url_pattern("/users/:id/posts/:postId")
  inspect(pattern, content="^/users/([^/]+)/posts/([^/]+)$")
  inspect(params, content="[\"id\", \"postId\"]")
}

///|
test "extract_url_pattern - Next.js style brackets" {
  let (pattern, params) = extract_url_pattern("/blog/[slug]")
  inspect(pattern, content="^/blog/([^/]+)$")
  inspect(params, content="[\"slug\"]")
}

///|
test "extract_url_pattern - catch-all pattern" {
  let (pattern, params) = extract_url_pattern("/docs/[...path]")
  inspect(pattern, content="^/docs/(.*)$")
  inspect(params, content="[\"path\"]")
}

// =============================================================================
// Static and Dynamic Coexistence Edge Cases
// =============================================================================

///|
test "Static and Dynamic can coexist in same manifest" {
  // When /blog/about exists as static and /blog/:slug as dynamic,
  // both routes can coexist in the manifest
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/blog/about",
          source="blog/about.md",
          output="blog/about/index.html",
        ),
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
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  // Both routes exist in the manifest
  inspect(manifest.routes.length(), content="2")
  // Static and dynamic routes have different paths
  let static_route = manifest.routes[0]
  let dynamic_route = manifest.routes[1]
  inspect(static_route.path(), content="/blog/about")
  inspect(dynamic_route.path(), content="/blog/:slug")
  inspect(static_route.is_static(), content="true")
  inspect(dynamic_route.is_dynamic(), content="true")
}

///|
test "Multiple RenderModes in same manifest" {
  let manifest = RouteManifest::{
    routes: [
      // Static (build-time)
      Static(
        StaticRouteEntry::new(path="/", source="index.md", output="index.html"),
      ),
      // SSR (per-request)
      Dynamic(
        DynamicRouteEntry::new(
          path="/live/:id",
          pattern="^/live/([^/]+)$",
          param_names=["id"],
          source="live/[id].md",
          mode=RenderMode::Ssr,
        ),
      ),
      // ISR (cached)
      Dynamic(
        DynamicRouteEntry::new(
          path="/cached/:id",
          pattern="^/cached/([^/]+)$",
          param_names=["id"],
          source="cached/[id].md",
          mode=RenderMode::Isr(revalidate=60),
        ),
      ),
      // SPA (client-only)
      Dynamic(
        DynamicRouteEntry::new(
          path="/app/:...path",
          pattern="^/app/(.*)$",
          param_names=["path"],
          source="app/[...path].md",
          mode=RenderMode::Spa,
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  // Count by render mode
  let ssr_count = manifest.routes
    .filter(fn(r) {
      match r {
        Dynamic(e) => e.mode == RenderMode::Ssr
        _ => false
      }
    })
    .length()
  let isr_count = manifest.routes
    .filter(fn(r) {
      match r {
        Dynamic(e) =>
          match e.mode {
            Isr(_) => true
            _ => false
          }
        _ => false
      }
    })
    .length()
  let spa_count = manifest.routes
    .filter(fn(r) {
      match r {
        Dynamic(e) => e.mode == RenderMode::Spa
        _ => false
      }
    })
    .length()
  inspect(ssr_count, content="1")
  inspect(isr_count, content="1")
  inspect(spa_count, content="1")
}

///|
test "ComponentRouteEntry coexists with Static and Dynamic" {
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
      Component(
        ComponentRouteEntry::new(
          path="/counter",
          source="counter/",
          component_type=ComponentType::SsrComponent,
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  inspect(manifest.routes.filter(fn(r) { r.is_static() }).length(), content="1")
  inspect(
    manifest.routes.filter(fn(r) { r.is_dynamic() }).length(),
    content="1",
  )
  inspect(
    manifest.routes.filter(fn(r) { r.is_component() }).length(),
    content="1",
  )
}
