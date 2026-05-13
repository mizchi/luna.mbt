// Router internal tests

///|
test "extract_route_param_names - supports colon and bracket params" {
  let names = extract_route_param_names("/users/:id/posts/[postId]")
  inspect(names, content="[id, postId]")
}

///|
test "extract_route_param_names - supports regex and catch-all params" {
  let names = extract_route_param_names(
    "/api/:version{[0-9]+}/docs/[...slug]/[[...opt]]",
  )
  inspect(names, content="[version, slug, opt]")
}

///|
test "extract_route_param_names - deduplicates parameter names" {
  let names = extract_route_param_names("/a/:id/:id/[id]")
  inspect(names, content="[id]")
}

///|
test "resolve_router_config - uses override values when config is None" {
  let config = resolve_router_config(
    None,
    title_prefix="Prefix",
    default_title="Fallback",
    default_head="<meta name=\"x\" content=\"1\">",
    loader_url="/assets/loader.js",
    wc_loader_url="/assets/wc-loader.js",
  )
  assert_eq(config.title_prefix, "Prefix")
  assert_eq(config.default_title, "Fallback")
  assert_eq(config.default_head, "<meta name=\"x\" content=\"1\">")
  assert_eq(config.loader_url, "/assets/loader.js")
  assert_eq(config.wc_loader_url, "/assets/wc-loader.js")
  assert_eq(config.enable_preload, true)
}

///|
test "resolve_router_config - prefers explicit config when provided" {
  let provided = RouterConfig::default()
    .with_title_prefix("Cfg")
    .with_default_title("CfgTitle")
    .with_loader_url("/cfg/loader.js")
  let resolved = resolve_router_config(
    Some(provided),
    title_prefix="Ignored",
    default_title="Ignored",
  )
  assert_eq(resolved.title_prefix, "Cfg")
  assert_eq(resolved.default_title, "CfgTitle")
  assert_eq(resolved.loader_url, "/cfg/loader.js")
}

///|
test "RouterConfig - stores first-class style and client script assets" {
  let config = RouterConfig::default()
    .with_style("./app.css")
    .with_styles(["./shared.css", "/global.css"])
    .with_client_script("./client/app.ts")
    .with_client_scripts(["./client/retry.js"])
  assert_eq(config.styles, ["./app.css", "./shared.css", "/global.css"])
  assert_eq(config.client_scripts, ["./client/app.ts", "./client/retry.js"])
}

///|
test "render_asset_tags normalizes URLs escapes attributes and deduplicates" {
  let html = render_asset_tags(
    ["./app.css", "/static/app.css", "https://cdn.example/ui.css"],
    ["./client/app.ts", "./client/app.ts", "/ready.js?x=<tag>"],
  )
  assert_eq(
    html, "<link rel=\"stylesheet\" href=\"/static/app.css\"><link rel=\"stylesheet\" href=\"https://cdn.example/ui.css\"><script type=\"module\" src=\"/static/client/app.ts\"></script><script type=\"module\" src=\"/ready.js?x=&lt;tag&gt;\"></script>",
  )
}

///|
test "register_route_tree - treats Layout as path grouping" {
  let pages : Array[(String, String, String)] = []
  let gets : Array[(String, String)] = []
  let posts : Array[(String, String)] = []
  let routes = [
    @routes.Layout(segment="/admin", layout="admin-layout", children=[
      @routes.Page(path="/users", component="users-page", title="Users", meta=[]),
      @routes.Get(path="/health", handler="health-handler"),
    ]),
  ]
  register_route_tree(
    routes,
    "",
    fn(path, component, title) { pages.push((path, component, title)) },
    fn(path, handler) { gets.push((path, handler)) },
    fn(path, handler) { posts.push((path, handler)) },
  )
  assert_eq(pages.length(), 1)
  assert_eq(pages[0].0, "/admin/users")
  assert_eq(gets.length(), 1)
  assert_eq(gets[0].0, "/admin/health")
  assert_eq(posts.length(), 0)
}

///|
test "legacy_routes_to_sol_routes - keeps layout prefix and route kinds" {
  let legacy_routes = [
    @routes.Layout(segment="/admin", layout="ignored-layout", children=[
      @routes.Page(
        path="/dashboard",
        component="dashboard-component",
        title="Dashboard",
        meta=[("description", "admin dashboard")],
      ),
      @routes.Get(path="/stats", handler="get-stats"),
      @routes.Post(path="/stats", handler="post-stats"),
    ]),
  ]
  let page_resolver = fn(
    _component : String,
    _ctx : Ctx,
    _params : RouteParams,
  ) {
    Some(@server_dom.ServerNode::sync(@luna.text("ok")))
  }
  let api_resolver = fn(_handler : String, _ctx : Ctx, _params : RouteParams) {
    Some(@js.any({ "ok": true }))
  }
  let converted = legacy_routes_to_sol_routes(
    legacy_routes, page_resolver, api_resolver,
  )
  let compiled = compile_sol_routes(converted)
  assert_eq(compiled.length(), 3)
  assert_eq(compiled[0].pattern, "/admin/dashboard")
  assert_true(compiled[0].kind is SolRouteKind::Page)
  assert_eq(compiled[0].layouts.length(), 1)
  assert_eq(compiled[1].pattern, "/admin/stats")
  assert_true(compiled[1].kind is SolRouteKind::GetApi)
  assert_eq(compiled[2].pattern, "/admin/stats")
  assert_true(compiled[2].kind is SolRouteKind::PostApi)
}

// ============================================================================
// format_title Tests
// ============================================================================

///|
test "format_title: empty title uses default" {
  let result = format_title(
    "",
    title_prefix="Prefix",
    default_title="Default Title",
  )
  assert_eq(result, "Default Title")
}

///|
test "format_title: title with empty prefix returns title" {
  let result = format_title("About", title_prefix="", default_title="Default")
  assert_eq(result, "About")
}

///|
test "format_title: title with prefix joins with separator" {
  let result = format_title(
    "About",
    title_prefix="MySite",
    default_title="Default",
  )
  assert_eq(result, "MySite - About")
}

///|
test "format_title: both empty returns default" {
  let result = format_title("", title_prefix="", default_title="Fallback")
  assert_eq(result, "Fallback")
}

// ============================================================================
// render_meta_tags Tests
// ============================================================================

///|
test "render_meta_tags: empty array returns empty string" {
  let result = render_meta_tags([])
  assert_eq(result, "")
}

///|
test "render_meta_tags: single meta tag" {
  let result = render_meta_tags([("description", "Hello World")])
  assert_eq(result, "<meta name=\"description\" content=\"Hello World\">")
}

///|
test "render_meta_tags: multiple meta tags" {
  let result = render_meta_tags([("description", "Test"), ("author", "Mizchi")])
  assert_true(result.contains("<meta name=\"description\" content=\"Test\">"))
  assert_true(result.contains("<meta name=\"author\" content=\"Mizchi\">"))
}

// ============================================================================
// rendered_meta pre-computation Tests
// ============================================================================

///|
test "compiled route pre-computes rendered_meta for page routes" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let routes = [page("/about", handler, meta=[("description", "About page")])]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(
    compiled[0].rendered_meta,
    "<meta name=\"description\" content=\"About page\">",
  )
}

///|
test "compiled route has empty rendered_meta for API routes" {
  async fn handler(_props : PageProps) -> Json {
    {}.to_json()
  }

  let routes = [api_get("/api/test", handler)]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].rendered_meta, "")
}

// ============================================================================
// collect_preload_urls Tests
// ============================================================================

///|
test "collect_preload_urls: empty inputs" {
  let result = collect_preload_urls([], [], None)
  assert_eq(result.length(), 0)
}

///|
test "collect_preload_urls: libs only" {
  let result = collect_preload_urls(
    ["/lib/react.js", "/lib/signals.js"],
    [],
    None,
  )
  assert_eq(result.length(), 2)
  assert_eq(result[0], "/lib/react.js")
}

///|
test "collect_preload_urls: islands without manifest" {
  let result = collect_preload_urls(
    [],
    ["/static/counter.js", "/static/form.js"],
    None,
  )
  assert_eq(result.length(), 2)
  assert_eq(result[0], "/static/counter.js")
}

///|
test "collect_preload_urls: libs before islands" {
  let result = collect_preload_urls(
    ["/lib/runtime.js"],
    ["/static/counter.js"],
    None,
  )
  assert_eq(result.length(), 2)
  assert_eq(result[0], "/lib/runtime.js")
  assert_eq(result[1], "/static/counter.js")
}

///|
test "collect_preload_urls: deduplicates URLs" {
  let result = collect_preload_urls(
    ["/lib/shared.js"],
    ["/lib/shared.js", "/static/counter.js"],
    None,
  )
  assert_eq(result.length(), 2)
  assert_eq(result[0], "/lib/shared.js")
  assert_eq(result[1], "/static/counter.js")
}

///|
test "collect_preload_urls: with chunk manifest adds dependencies" {
  let manifest = ChunkManifest::new("/static/")
  manifest.add(
    "counter.js",
    ChunkManifestEntry::new("counter.js", ["_shared/signals.js"]),
  )
  let result = collect_preload_urls([], ["/static/counter.js"], Some(manifest))
  // Should have chunk dep first, then island
  assert_true(result.contains("/static/_shared/signals.js"))
  assert_true(result.contains("/static/counter.js"))
}

///|
test "collect_preload_urls: manifest deduplicates chunks with libs" {
  let manifest = ChunkManifest::new("/static/")
  manifest.add(
    "counter.js",
    ChunkManifestEntry::new("counter.js", ["_shared/lib.js"]),
  )
  let result = collect_preload_urls(
    ["/static/_shared/lib.js"],
    ["/static/counter.js"],
    Some(manifest),
  )
  // lib.js already in preload_libs, should not duplicate
  let lib_count = result
    .iter()
    .filter(fn(u) { u == "/static/_shared/lib.js" })
    .fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(lib_count, 1)
}

///|
test "compiled route rendered_meta matches render_meta_tags output" {
  async fn handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text(""))
  }

  let meta : Array[(String, String)] = [
    ("description", "Test"),
    ("og:title", "Title"),
  ]
  let routes = [page("/test", handler, meta~)]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled[0].rendered_meta, render_meta_tags(meta))
}
