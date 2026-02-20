// Router internal tests

///|
test "extract_route_param_names - supports colon and bracket params" {
  let names = extract_route_param_names("/users/:id/posts/[postId]")
  inspect(names, content="[\"id\", \"postId\"]")
}

///|
test "extract_route_param_names - supports regex and catch-all params" {
  let names = extract_route_param_names(
    "/api/:version{[0-9]+}/docs/[...slug]/[[...opt]]",
  )
  inspect(names, content="[\"version\", \"slug\", \"opt\"]")
}

///|
test "extract_route_param_names - deduplicates parameter names" {
  let names = extract_route_param_names("/a/:id/:id/[id]")
  inspect(names, content="[\"id\"]")
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
