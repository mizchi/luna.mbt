// Tests for Dynamic Routes - SSR, SPA, and Hybrid Rendering Modes
//
// Tests for dynamic route configuration, render modes, and navigation strategies.
// Covers SSR-only, SPA-only, ISR, and hybrid rendering patterns.

// =============================================================================
// RenderMode Basic Tests
// =============================================================================

///|
test "RenderMode::Ssr - server-side rendering" {
  let mode = RenderMode::Ssr
  inspect(mode == RenderMode::Ssr, content="true")
  inspect(mode.requires_server(), content="true")
}

///|
test "RenderMode::Spa - client-side only" {
  let mode = RenderMode::Spa
  inspect(mode == RenderMode::Spa, content="true")
  inspect(mode.requires_server(), content="false")
}

///|
test "RenderMode::Isr - with revalidation" {
  let mode = RenderMode::Isr(revalidate=60)
  inspect(mode.requires_server(), content="true")
  guard mode.revalidate_seconds() is Some(sec) else {
    fail("Expected Some revalidate seconds")
  }
  inspect(sec, content="60")
}

///|
test "RenderMode - equality comparison" {
  inspect(RenderMode::Ssr == RenderMode::Ssr, content="true")
  inspect(RenderMode::Spa == RenderMode::Spa, content="true")
  inspect(
    RenderMode::Isr(revalidate=60) == RenderMode::Isr(revalidate=60),
    content="true",
  )
  inspect(RenderMode::Ssr == RenderMode::Spa, content="false")
  inspect(
    RenderMode::Isr(revalidate=60) == RenderMode::Isr(revalidate=120),
    content="false",
  )
}

///|
test "RenderMode - Show implementation" {
  let ssr = RenderMode::Ssr
  let spa = RenderMode::Spa
  let isr = RenderMode::Isr(revalidate=300)
  inspect(ssr.to_string().contains("Ssr"), content="true")
  inspect(spa.to_string().contains("Spa"), content="true")
  inspect(isr.to_string().contains("Isr"), content="true")
}

// =============================================================================
// FallbackConfig Tests
// =============================================================================

///|
test "FallbackConfig::NotFound - 404 page" {
  let fallback = FallbackConfig::NotFound(path="/404.html")
  inspect(fallback.is_spa(), content="false")
  inspect(fallback.spa_entry() is None, content="true")
}

///|
test "FallbackConfig::Spa - full SPA mode" {
  let fallback = FallbackConfig::Spa(entry="/index.html")
  inspect(fallback.is_spa(), content="true")
  guard fallback.spa_entry() is Some(entry) else { fail("Expected Some entry") }
  inspect(entry, content="/index.html")
}

///|
test "FallbackConfig::SpaPrefix - prefix-limited SPA" {
  let fallback = FallbackConfig::SpaPrefix(
    prefix="/app/",
    entry="/app/index.html",
  )
  inspect(fallback.is_spa(), content="true")
  guard fallback.spa_entry() is Some(entry) else { fail("Expected Some entry") }
  inspect(entry, content="/app/index.html")
}

// =============================================================================
// DynamicRouteEntry Tests
// =============================================================================

///|
test "DynamicRouteEntry - basic dynamic route" {
  let route = DynamicRouteEntry::{
    path: "/blog/:slug",
    pattern: "^/blog/([^/]+)$",
    param_names: ["slug"],
    source: "blog/[slug]/page.tsx",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: None,
    title: Some("Blog - :slug"),
    islands: [],
  }
  inspect(route.path, content="/blog/:slug")
  inspect(route.param_names[0], content="slug")
  inspect(route.mode == RenderMode::Ssr, content="true")
}

///|
test "DynamicRouteEntry - ISR mode with revalidation" {
  let route = DynamicRouteEntry::{
    path: "/products/:id",
    pattern: "^/products/([^/]+)$",
    param_names: ["id"],
    source: "products/[id]/page.tsx",
    mode: RenderMode::Isr(revalidate=300),
    layout: Some("shop-layout"),
    catch_all: None,
    title: Some("Product :id"),
    islands: ["add-to-cart", "product-gallery"],
  }
  inspect(route.mode.requires_server(), content="true")
  guard route.mode.revalidate_seconds() is Some(sec) else {
    fail("Expected ISR revalidate")
  }
  inspect(sec, content="300")
  inspect(route.islands.length(), content="2")
}

///|
test "DynamicRouteEntry - SPA mode (client-only)" {
  let route = DynamicRouteEntry::{
    path: "/app/:section",
    pattern: "^/app/([^/]+)$",
    param_names: ["section"],
    source: "app/[section]/page.tsx",
    mode: RenderMode::Spa,
    layout: Some("app-layout"),
    catch_all: None,
    title: None,
    islands: [],
  }
  inspect(route.mode == RenderMode::Spa, content="true")
  inspect(route.mode.requires_server(), content="false")
}

///|
test "DynamicRouteEntry - catch-all route" {
  let route = DynamicRouteEntry::{
    path: "/docs/[...slug]",
    pattern: "^/docs/(.+)$",
    param_names: ["slug"],
    source: "docs/[...slug]/page.tsx",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: Some(CatchAllInfo::{ name: "slug", optional: false }),
    title: Some("Documentation"),
    islands: ["toc", "code-block"],
  }
  guard route.catch_all is Some(info) else { fail("Expected catch-all info") }
  inspect(info.name, content="slug")
  inspect(info.optional, content="false")
}

///|
test "DynamicRouteEntry - optional catch-all route" {
  let route = DynamicRouteEntry::{
    path: "/wiki/[[...path]]",
    pattern: "^/wiki(?:/(.*))?$",
    param_names: ["path"],
    source: "wiki/[[...path]]/page.tsx",
    mode: RenderMode::Spa,
    layout: None,
    catch_all: Some(CatchAllInfo::{ name: "path", optional: true }),
    title: None,
    islands: [],
  }
  guard route.catch_all is Some(info) else { fail("Expected catch-all info") }
  inspect(info.optional, content="true")
}

// =============================================================================
// Complete SPA Pattern Tests
// =============================================================================

///|
test "Complete SPA - all routes as SPA" {
  let manifest = RouteManifest::{
    routes: [
      RouteEntry::Dynamic(DynamicRouteEntry::{
        path: "/app/:page",
        pattern: "^/app/([^/]+)$",
        param_names: ["page"],
        source: "app/[page]/page.tsx",
        mode: RenderMode::Spa,
        layout: None,
        catch_all: None,
        title: None,
        islands: [],
      }),
    ],
    fallback: FallbackConfig::Spa(entry="/app/index.html"),
  }
  // All unmatched routes go to SPA entry
  inspect(manifest.fallback.is_spa(), content="true")
}

///|
test "Complete SPA - no server rendering" {
  // SPA mode routes don't require server
  let spa_route = DynamicRouteEntry::{
    path: "/dashboard/:view",
    pattern: "^/dashboard/([^/]+)$",
    param_names: ["view"],
    source: "dashboard/[view]/page.tsx",
    mode: RenderMode::Spa,
    layout: None,
    catch_all: None,
    title: None,
    islands: [],
  }
  inspect(spa_route.mode.requires_server(), content="false")
  // SPA routes have no islands (all client-side)
  inspect(spa_route.islands.length(), content="0")
}

///|
test "Complete SPA - fallback entry configuration" {
  // In SPA mode, fallback serves the SPA shell
  let fallback = FallbackConfig::Spa(entry="/index.html")
  guard fallback.spa_entry() is Some(entry) else { fail("Expected SPA entry") }
  inspect(entry, content="/index.html")
}

// =============================================================================
// SSR-Only Pattern Tests
// =============================================================================

///|
test "SSR-only - all routes server-rendered" {
  let manifest = RouteManifest::{
    routes: [
      RouteEntry::Dynamic(DynamicRouteEntry::{
        path: "/blog/:slug",
        pattern: "^/blog/([^/]+)$",
        param_names: ["slug"],
        source: "blog/[slug]/page.tsx",
        mode: RenderMode::Ssr,
        layout: None,
        catch_all: None,
        title: Some("Blog"),
        islands: [], // No client-side islands
      }),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  // Fallback is 404, not SPA
  inspect(manifest.fallback.is_spa(), content="false")
}

///|
test "SSR-only - requires server for every request" {
  let ssr_route = DynamicRouteEntry::{
    path: "/user/:id",
    pattern: "^/user/([^/]+)$",
    param_names: ["id"],
    source: "user/[id]/page.tsx",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: None,
    title: Some("User Profile"),
    islands: [],
  }
  inspect(ssr_route.mode.requires_server(), content="true")
  inspect(ssr_route.mode.revalidate_seconds() is None, content="true")
}

///|
test "SSR-only - 404 fallback" {
  // SSR-only uses 404 fallback instead of SPA
  let fallback = FallbackConfig::NotFound(path="/404.html")
  inspect(fallback.is_spa(), content="false")
  inspect(fallback.spa_entry() is None, content="true")
}

///|
test "SSR-only - multiple dynamic segments" {
  // SSR-only routes can have multiple dynamic segments
  let route = DynamicRouteEntry::{
    path: "/user/:userId/post/:postId",
    pattern: "^/user/([^/]+)/post/([^/]+)$",
    param_names: ["userId", "postId"],
    source: "user/[userId]/post/[postId]/page.tsx",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: None,
    title: None,
    islands: [],
  }
  inspect(route.param_names.length(), content="2")
}

// =============================================================================
// Hybrid Pattern Tests (SSR + SPA)
// =============================================================================

///|
test "Hybrid - SSR with client islands" {
  let hybrid_route = DynamicRouteEntry::{
    path: "/shop/:category",
    pattern: "^/shop/([^/]+)$",
    param_names: ["category"],
    source: "shop/[category]/page.tsx",
    mode: RenderMode::Ssr,
    layout: Some("shop-layout"),
    catch_all: None,
    title: Some("Shop - :category"),
    islands: ["product-filter", "add-to-cart", "wishlist"],
  }
  // SSR for initial render
  inspect(hybrid_route.mode.requires_server(), content="true")
  // Client islands for interactivity
  inspect(hybrid_route.islands.length(), content="3")
}

///|
test "Hybrid - SPA for some routes, SSR for others" {
  let manifest = RouteManifest::{
    routes: [
      // SSR route for SEO-important content
      RouteEntry::Dynamic(DynamicRouteEntry::{
        path: "/blog/:slug",
        pattern: "^/blog/([^/]+)$",
        param_names: ["slug"],
        source: "blog/[slug]/page.tsx",
        mode: RenderMode::Ssr,
        layout: None,
        catch_all: None,
        title: Some("Blog"),
        islands: ["comments"],
      }),
      // SPA route for app section
      RouteEntry::Dynamic(DynamicRouteEntry::{
        path: "/app/:section",
        pattern: "^/app/([^/]+)$",
        param_names: ["section"],
        source: "app/[section]/page.tsx",
        mode: RenderMode::Spa,
        layout: None,
        catch_all: None,
        title: None,
        islands: [],
      }),
    ],
    fallback: FallbackConfig::SpaPrefix(prefix="/app/", entry="/app/index.html"),
  }
  inspect(manifest.routes.length(), content="2")
  // Fallback only applies to /app/ prefix
  inspect(manifest.fallback.is_spa(), content="true")
}

///|
test "Hybrid - ISR for product pages, SSR for dynamic" {
  let routes = [
    // ISR for product pages (cache with revalidation)
    DynamicRouteEntry::{
      path: "/products/:id",
      pattern: "^/products/([^/]+)$",
      param_names: ["id"],
      source: "products/[id]/page.tsx",
      mode: RenderMode::Isr(revalidate=60),
      layout: None,
      catch_all: None,
      title: None,
      islands: ["buy-button"],
    },
    // SSR for user-specific content
    DynamicRouteEntry::{
      path: "/cart",
      pattern: "^/cart$",
      param_names: [],
      source: "cart/page.tsx",
      mode: RenderMode::Ssr,
      layout: None,
      catch_all: None,
      title: None,
      islands: ["cart-items", "checkout-form"],
    },
  ]
  // Products use ISR
  guard routes[0].mode.revalidate_seconds() is Some(sec) else {
    fail("Expected ISR for products")
  }
  inspect(sec, content="60")
  // Cart uses SSR (no caching for user data)
  inspect(routes[1].mode == RenderMode::Ssr, content="true")
}

// =============================================================================
// ComponentType Tests
// =============================================================================

///|
test "ComponentType::SsrComponent - full hydration" {
  let comp_type = ComponentType::SsrComponent
  // SSR + hydration: server renders, client hydrates
  match comp_type {
    ComponentType::SsrComponent => inspect(true, content="true")
    _ => fail("Expected SsrComponent")
  }
}

///|
test "ComponentType::ClientOnlyComponent - no SSR" {
  let comp_type = ComponentType::ClientOnlyComponent
  // Client-only: placeholder on server, full render on client
  match comp_type {
    ComponentType::ClientOnlyComponent => inspect(true, content="true")
    _ => fail("Expected ClientOnlyComponent")
  }
}

///|
test "ComponentType::ServerOnlyComponent - no hydration" {
  let comp_type = ComponentType::ServerOnlyComponent
  // Server-only: SSR but no client JS
  match comp_type {
    ComponentType::ServerOnlyComponent => inspect(true, content="true")
    _ => fail("Expected ServerOnlyComponent")
  }
}

// =============================================================================
// ComponentRouteEntry Tests
// =============================================================================

///|
test "ComponentRouteEntry - SSR with hydration" {
  let route = ComponentRouteEntry::{
    path: "/counter/:initial",
    source: "components/counter",
    component_type: ComponentType::SsrComponent,
    mode: RenderMode::Ssr,
    layout: None,
    props_type: Some("CounterProps"),
    client_export: Some("Counter"),
    server_export: Some("render_ssr"),
    static_paths: [],
    islands: ["counter"],
  }
  inspect(route.component_type is ComponentType::SsrComponent, content="true")
  guard route.props_type is Some(pt) else { fail("Expected props_type") }
  inspect(pt, content="CounterProps")
}

///|
test "ComponentRouteEntry - client-only React component" {
  let route = ComponentRouteEntry::{
    path: "/chart/:type",
    source: "components/chart",
    component_type: ComponentType::ClientOnlyComponent,
    mode: RenderMode::Spa,
    layout: None,
    props_type: Some("ChartProps"),
    client_export: Some("Chart"),
    server_export: None, // No server export
    static_paths: [],
    islands: [],
  }
  inspect(
    route.component_type is ComponentType::ClientOnlyComponent,
    content="true",
  )
  inspect(route.server_export is None, content="true")
}

///|
test "ComponentRouteEntry - server-only (no hydration)" {
  let route = ComponentRouteEntry::{
    path: "/email/:template",
    source: "components/email-template",
    component_type: ComponentType::ServerOnlyComponent,
    mode: RenderMode::Ssr,
    layout: None,
    props_type: Some("EmailProps"),
    client_export: None, // No client export
    server_export: Some("render"),
    static_paths: [],
    islands: [], // No islands needed
  }
  inspect(
    route.component_type is ComponentType::ServerOnlyComponent,
    content="true",
  )
  inspect(route.client_export is None, content="true")
  inspect(route.islands.length(), content="0")
}

// =============================================================================
// Static Paths with Dynamic Routes Tests
// =============================================================================

///|
test "ComponentRouteEntry - static paths for ISG" {
  let route = ComponentRouteEntry::{
    path: "/blog/:slug",
    source: "components/blog-post",
    component_type: ComponentType::SsrComponent,
    mode: RenderMode::Isr(revalidate=3600),
    layout: None,
    props_type: Some("BlogPostProps"),
    client_export: Some("BlogPost"),
    server_export: Some("render_ssr"),
    static_paths: [
      StaticPathEntry::{
        params: { "slug": "hello-world" },
        output: "blog/hello-world/index.html",
      },
      StaticPathEntry::{
        params: { "slug": "getting-started" },
        output: "blog/getting-started/index.html",
      },
      StaticPathEntry::{
        params: { "slug": "advanced-topics" },
        output: "blog/advanced-topics/index.html",
      },
    ],
    islands: ["comments", "share-buttons"],
  }
  inspect(route.static_paths.length(), content="3")
  inspect(
    route.static_paths[0].params.get("slug"),
    content="Some(\"hello-world\")",
  )
}

// =============================================================================
// Fallback Configuration Tests
// =============================================================================

///|
test "FallbackConfig - SPA entry with prefix" {
  let fallback = FallbackConfig::SpaPrefix(
    prefix="/app/",
    entry="/app/shell.html",
  )
  inspect(fallback.is_spa(), content="true")
  guard fallback.spa_entry() is Some(entry) else { fail("Expected SPA entry") }
  inspect(entry, content="/app/shell.html")
}

///|
test "FallbackConfig - NotFound with custom path" {
  let fallback = FallbackConfig::NotFound(path="/custom-404.html")
  inspect(fallback.is_spa(), content="false")
}

///|
test "FallbackConfig - SPA for entire app" {
  let fallback = FallbackConfig::Spa(entry="/index.html")
  inspect(fallback.is_spa(), content="true")
  guard fallback.spa_entry() is Some(entry) else { fail("Expected SPA entry") }
  inspect(entry, content="/index.html")
}

///|
test "RenderMode - ISR revalidation times" {
  // Various revalidation times for different use cases
  let short = RenderMode::Isr(revalidate=60) // 1 minute
  let medium = RenderMode::Isr(revalidate=300) // 5 minutes
  let long = RenderMode::Isr(revalidate=3600) // 1 hour
  guard short.revalidate_seconds() is Some(s1) else { fail("Expected Some") }
  guard medium.revalidate_seconds() is Some(s2) else { fail("Expected Some") }
  guard long.revalidate_seconds() is Some(s3) else { fail("Expected Some") }
  inspect(s1, content="60")
  inspect(s2, content="300")
  inspect(s3, content="3600")
}

// =============================================================================
// RouteManifest Pattern Tests
// =============================================================================

///|
test "RouteManifest - static and dynamic routes" {
  let manifest = RouteManifest::{
    routes: [
      RouteEntry::Static(StaticRouteEntry::{
        path: "/",
        source: "index.md",
        output: "index.html",
        layout: None,
        title: Some("Home"),
        description: None,
        islands: [],
        locale: "en",
        generated_params: [],
      }),
      RouteEntry::Dynamic(DynamicRouteEntry::{
        path: "/blog/:slug",
        pattern: "^/blog/([^/]+)$",
        param_names: ["slug"],
        source: "blog/[slug]/page.tsx",
        mode: RenderMode::Isr(revalidate=60),
        layout: None,
        catch_all: None,
        title: Some("Blog"),
        islands: [],
      }),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  inspect(manifest.routes.length(), content="2")
}

///|
test "RouteManifest - API routes with dynamic paths" {
  let manifest = RouteManifest::{
    routes: [
      RouteEntry::Api(ApiRouteEntry::{
        path: "/api/users/:id",
        pattern: "^/api/users/([^/]+)$",
        param_names: ["id"],
        http_method: HttpMethod::Get,
        source: "api/users/[id].ts",
      }),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  guard manifest.routes[0] is RouteEntry::Api(api) else {
    fail("Expected Api route")
  }
  inspect(api.http_method == HttpMethod::Get, content="true")
}

// =============================================================================
// Mixed Framework Dynamic Routes Tests
// =============================================================================

///|
test "Mixed frameworks - React SSR route" {
  let route = DynamicRouteEntry::{
    path: "/dashboard/:view",
    pattern: "^/dashboard/([^/]+)$",
    param_names: ["view"],
    source: "dashboard/[view]/page.tsx",
    mode: RenderMode::Ssr,
    layout: Some("dashboard-layout"),
    catch_all: None,
    title: Some("Dashboard - :view"),
    islands: ["react-chart", "react-table"],
  }
  // React islands in SSR route
  inspect(route.islands.length(), content="2")
  inspect(route.islands[0], content="react-chart")
}

///|
test "Mixed frameworks - Preact lightweight islands" {
  let route = DynamicRouteEntry::{
    path: "/widgets/:type",
    pattern: "^/widgets/([^/]+)$",
    param_names: ["type"],
    source: "widgets/[type]/page.tsx",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: None,
    title: None,
    islands: ["preact-counter", "preact-toggle"],
  }
  // Preact islands (lightweight)
  inspect(route.islands.length(), content="2")
}

///|
test "Mixed frameworks - Luna WASM islands" {
  let route = DynamicRouteEntry::{
    path: "/compute/:task",
    pattern: "^/compute/([^/]+)$",
    param_names: ["task"],
    source: "compute/[task]/page.tsx",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: None,
    title: None,
    islands: ["luna-wasm-processor"],
  }
  // Luna islands for heavy computation
  inspect(route.islands[0], content="luna-wasm-processor")
}

// =============================================================================
// HttpMethod Tests
// =============================================================================

///|
test "HttpMethod - all HTTP methods" {
  let methods = [
    HttpMethod::Get,
    HttpMethod::Post,
    HttpMethod::Put,
    HttpMethod::Delete,
    HttpMethod::Patch,
    HttpMethod::All,
  ]
  inspect(methods.length(), content="6")
}

///|
test "HttpMethod - equality comparison" {
  inspect(HttpMethod::Get == HttpMethod::Get, content="true")
  inspect(HttpMethod::Post == HttpMethod::Post, content="true")
  inspect(HttpMethod::Get == HttpMethod::Post, content="false")
}

// =============================================================================
// Pattern Extraction Tests
// =============================================================================

///|
test "Pattern - Express style :param" {
  let path = "/blog/:slug"
  let (pattern, params) = extract_url_pattern(path)
  inspect(pattern.contains("([^/]+)"), content="true")
  inspect(params[0], content="slug")
}

///|
test "Pattern - Next.js style [param]" {
  let path = "/blog/[slug]"
  let (pattern, params) = extract_url_pattern(path)
  inspect(pattern.contains("([^/]+)"), content="true")
  inspect(params[0], content="slug")
}

///|
test "Pattern - multiple params" {
  let path = "/user/:id/posts/:postId"
  let (_, params) = extract_url_pattern(path)
  inspect(params.length(), content="2")
  inspect(params[0], content="id")
  inspect(params[1], content="postId")
}

///|
test "Pattern - catch-all extraction" {
  let path = "/docs/[...slug]"
  guard extract_catch_all(path) is Some(info) else {
    fail("Expected catch-all")
  }
  inspect(info.name, content="slug")
  inspect(info.optional, content="false")
}

///|
test "Pattern - optional catch-all extraction" {
  let path = "/wiki/[[...path]]"
  guard extract_catch_all(path) is Some(info) else {
    fail("Expected catch-all")
  }
  inspect(info.name, content="path")
  inspect(info.optional, content="true")
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "Edge case - empty islands array" {
  let route = DynamicRouteEntry::{
    path: "/static/:page",
    pattern: "^/static/([^/]+)$",
    param_names: ["page"],
    source: "static/[page]/page.md",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: None,
    title: None,
    islands: [], // No interactivity
  }
  inspect(route.islands.length(), content="0")
}

///|
test "Edge case - ISR with 0 revalidation" {
  let mode = RenderMode::Isr(revalidate=0)
  // 0 means cache forever (no revalidation)
  guard mode.revalidate_seconds() is Some(sec) else { fail("Expected Some") }
  inspect(sec, content="0")
}

///|
test "Edge case - deeply nested dynamic segments" {
  let path = "/org/:orgId/team/:teamId/project/:projectId"
  let (_, params) = extract_url_pattern(path)
  inspect(params.length(), content="3")
  inspect(params[0], content="orgId")
  inspect(params[1], content="teamId")
  inspect(params[2], content="projectId")
}
