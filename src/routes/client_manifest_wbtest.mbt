// Whitebox tests for client_manifest.mbt private functions

// =============================================================================
// strip_trailing_slash Tests
// =============================================================================

///|
test "strip_trailing_slash - empty string" {
  assert_eq!(strip_trailing_slash(""), "")
}

///|
test "strip_trailing_slash - no trailing slash" {
  assert_eq!(strip_trailing_slash("counter"), "counter")
}

///|
test "strip_trailing_slash - single trailing slash" {
  assert_eq!(strip_trailing_slash("counter/"), "counter")
}

///|
test "strip_trailing_slash - path with segments and trailing slash" {
  assert_eq!(strip_trailing_slash("blog/posts/"), "blog/posts")
}

///|
test "strip_trailing_slash - just a slash" {
  assert_eq!(strip_trailing_slash("/"), "")
}

///|
test "strip_trailing_slash - slash only prefix no suffix" {
  assert_eq!(strip_trailing_slash("/about"), "/about")
}

// =============================================================================
// json_string Tests
// =============================================================================

///|
test "json_string - plain string" {
  assert_eq!(json_string("hello"), "\"hello\"")
}

///|
test "json_string - empty string" {
  assert_eq!(json_string(""), "\"\"")
}

///|
test "json_string - escapes double quote" {
  assert_eq!(json_string("say \"hi\""), "\"say \\\"hi\\\"\"")
}

///|
test "json_string - escapes backslash" {
  assert_eq!(json_string("a\\b"), "\"a\\\\b\"")
}

///|
test "json_string - escapes newline" {
  assert_eq!(json_string("line1\nline2"), "\"line1\\nline2\"")
}

///|
test "json_string - escapes carriage return" {
  assert_eq!(json_string("a\rb"), "\"a\\rb\"")
}

///|
test "json_string - escapes tab" {
  assert_eq!(json_string("a\tb"), "\"a\\tb\"")
}

///|
test "json_string - path string" {
  assert_eq!(json_string("/_luna/"), "\"/_luna/\"")
}

// =============================================================================
// get_static_route_chunks Tests
// =============================================================================

///|
test "get_static_route_chunks - no islands" {
  let route = StaticRouteEntry::new(
    path="/about",
    source="about.md",
    output="about.html",
  )
  let chunks = get_static_route_chunks(route)
  assert_eq!(chunks, ["boot"])
}

///|
test "get_static_route_chunks - with islands" {
  let route = StaticRouteEntry::{
    path: "/home",
    source: "home.md",
    output: "home.html",
    layout: None,
    title: None,
    description: None,
    islands: ["counter", "toggle"],
    locale: "en",
    generated_params: [],
  }
  let chunks = get_static_route_chunks(route)
  assert_true!(chunks.contains("boot"))
  assert_true!(chunks.contains("hydrate"))
  assert_true!(chunks.contains("signal"))
  assert_true!(chunks.contains("island-counter"))
  assert_true!(chunks.contains("island-toggle"))
}

///|
test "get_static_route_chunks - islands order: boot first" {
  let route = StaticRouteEntry::{
    path: "/page",
    source: "page.md",
    output: "page.html",
    layout: None,
    title: None,
    description: None,
    islands: ["widget"],
    locale: "en",
    generated_params: [],
  }
  let chunks = get_static_route_chunks(route)
  assert_eq!(chunks[0], "boot")
  assert_eq!(chunks[1], "hydrate")
  assert_eq!(chunks[2], "signal")
  assert_eq!(chunks[3], "island-widget")
}

// =============================================================================
// get_dynamic_route_chunks Tests
// =============================================================================

///|
test "get_dynamic_route_chunks - no islands SSR mode" {
  let route = DynamicRouteEntry::new(
    path="/blog/:slug",
    pattern="^/blog/([^/]+)$",
    param_names=["slug"],
    source="blog/[slug].md",
    mode=RenderMode::Ssr,
  )
  let chunks = get_dynamic_route_chunks(route)
  assert_eq!(chunks, ["boot"])
}

///|
test "get_dynamic_route_chunks - with islands" {
  let route = DynamicRouteEntry::{
    path: "/blog/:slug",
    pattern: "^/blog/([^/]+)$",
    param_names: ["slug"],
    source: "blog/[slug].md",
    mode: RenderMode::Ssr,
    layout: None,
    catch_all: None,
    title: None,
    islands: ["share-button"],
  }
  let chunks = get_dynamic_route_chunks(route)
  assert_true!(chunks.contains("boot"))
  assert_true!(chunks.contains("hydrate"))
  assert_true!(chunks.contains("signal"))
  assert_true!(chunks.contains("island-share-button"))
}

///|
test "get_dynamic_route_chunks - SPA mode no islands" {
  let route = DynamicRouteEntry::new(
    path="/app/:page",
    pattern="^/app/([^/]+)$",
    param_names=["page"],
    source="app/[page].md",
    mode=RenderMode::Spa,
  )
  let chunks = get_dynamic_route_chunks(route)
  assert_eq!(chunks, ["boot"])
}

// =============================================================================
// get_component_route_chunks Tests
// =============================================================================

///|
test "get_component_route_chunks - SsrComponent with trailing slash source" {
  let route = ComponentRouteEntry::new(
    path="/counter",
    source="counter/",
    component_type=ComponentType::SsrComponent,
    mode=RenderMode::Ssr,
  )
  let chunks = get_component_route_chunks(route)
  assert_true!(chunks.contains("boot"))
  assert_true!(chunks.contains("hydrate"))
  assert_true!(chunks.contains("signal"))
  assert_true!(chunks.contains("island-counter"))
}

///|
test "get_component_route_chunks - SsrComponent source without trailing slash" {
  let route = ComponentRouteEntry::new(
    path="/widget",
    source="widget",
    component_type=ComponentType::SsrComponent,
    mode=RenderMode::Ssr,
  )
  let chunks = get_component_route_chunks(route)
  assert_true!(chunks.contains("island-widget"))
}

///|
test "get_component_route_chunks - ServerOnlyComponent does not hydrate" {
  let route = ComponentRouteEntry::new(
    path="/server-only",
    source="server_only/",
    component_type=ComponentType::ServerOnlyComponent,
    mode=RenderMode::Ssr,
  )
  let chunks = get_component_route_chunks(route)
  assert_true!(chunks.contains("boot"))
  assert_true!(not(chunks.contains("hydrate")))
  assert_true!(not(chunks.contains("signal")))
}

///|
test "get_component_route_chunks - ClientOnlyComponent hydrates" {
  let route = ComponentRouteEntry::new(
    path="/client",
    source="client_comp/",
    component_type=ComponentType::ClientOnlyComponent,
    mode=RenderMode::Ssr,
  )
  let chunks = get_component_route_chunks(route)
  assert_true!(chunks.contains("hydrate"))
  assert_true!(chunks.contains("island-client_comp"))
}

///|
test "get_component_route_chunks - additional islands not duplicated" {
  let route = ComponentRouteEntry::{
    path: "/counter",
    source: "counter/",
    component_type: ComponentType::SsrComponent,
    mode: RenderMode::Ssr,
    layout: None,
    props_type: None,
    client_export: None,
    server_export: None,
    static_paths: [],
    islands: ["counter"],
  }
  let chunks = get_component_route_chunks(route)
  // "island-counter" should appear only once
  let mut count = 0
  for chunk in chunks {
    if chunk == "island-counter" {
      count = count + 1
    }
  }
  assert_eq!(count, 1)
}

///|
test "get_component_route_chunks - extra island added once" {
  let route = ComponentRouteEntry::{
    path: "/counter",
    source: "counter/",
    component_type: ComponentType::SsrComponent,
    mode: RenderMode::Ssr,
    layout: None,
    props_type: None,
    client_export: None,
    server_export: None,
    static_paths: [],
    islands: ["extra-widget"],
  }
  let chunks = get_component_route_chunks(route)
  assert_true!(chunks.contains("island-counter"))
  assert_true!(chunks.contains("island-extra-widget"))
}

// =============================================================================
// analyze_route_chunks Tests
// =============================================================================

///|
test "analyze_route_chunks - Static entry" {
  let entry = RouteEntry::Static(
    StaticRouteEntry::new(
      path="/about",
      source="about.md",
      output="about.html",
    ),
  )
  let (path, chunks) = analyze_route_chunks(entry)
  assert_eq!(path, "/about")
  assert_true!(chunks.contains("boot"))
}

///|
test "analyze_route_chunks - Dynamic entry" {
  let entry = RouteEntry::Dynamic(
    DynamicRouteEntry::new(
      path="/blog/:id",
      pattern="^/blog/([^/]+)$",
      param_names=["id"],
      source="blog/[id].md",
      mode=RenderMode::Ssr,
    ),
  )
  let (path, chunks) = analyze_route_chunks(entry)
  assert_eq!(path, "/blog/:id")
  assert_true!(chunks.contains("boot"))
}

///|
test "analyze_route_chunks - Component entry" {
  let entry = RouteEntry::Component(
    ComponentRouteEntry::new(
      path="/app",
      source="app/",
      component_type=ComponentType::SsrComponent,
      mode=RenderMode::Ssr,
    ),
  )
  let (path, chunks) = analyze_route_chunks(entry)
  assert_eq!(path, "/app")
  assert_true!(chunks.contains("boot"))
}

///|
test "analyze_route_chunks - Api entry returns empty" {
  let entry = RouteEntry::Api(
    ApiRouteEntry::new(
      path="/api/data",
      pattern="^/api/data$",
      http_method=HttpMethod::Get,
      source="api/data.mbt",
    ),
  )
  let (path, chunks) = analyze_route_chunks(entry)
  assert_eq!(path, "")
  assert_eq!(chunks, [])
}
