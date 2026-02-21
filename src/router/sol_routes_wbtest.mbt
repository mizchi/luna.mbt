// Sol Routes internal tests

///|
test "compile simple sol page route" {
  async fn home_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("Home"))
  }

  let routes = [
    SolRoutes::Page(
      path="/",
      handler=PageHandler(home_handler),
      title="Home",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/")
  assert_eq(compiled[0].title, "Home")
  assert_true(compiled[0].kind is SolRouteKind::Page)
}

///|
test "compile sol layout with children" {
  async fn home_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("Dashboard"))
  }

  fn layout_handler(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  let routes = [
    SolRoutes::Layout(segment="/admin", layout=layout_handler, children=[
      SolRoutes::Page(
        path="/dashboard",
        handler=PageHandler(home_handler),
        title="Dashboard",
        meta=[],
        revalidate=None,
        cache=None,
      ),
    ]),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/admin/dashboard")
  assert_eq(compiled[0].layouts.length(), 1)
}

///|
test "compile sol api routes" {
  async fn get_handler(_props : PageProps) -> @js.Any {
    @js.any({ "status": "ok" })
  }

  async fn post_handler(_props : PageProps) -> @js.Any {
    @js.any({ "created": true })
  }

  let routes = [
    SolRoutes::Get(path="/api/users", handler=ApiHandler(get_handler)),
    SolRoutes::Post(path="/api/users", handler=ApiHandler(post_handler)),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 2)
  assert_eq(compiled[0].pattern, "/api/users")
  assert_true(compiled[0].kind is SolRouteKind::GetApi)
  assert_eq(compiled[1].pattern, "/api/users")
  assert_true(compiled[1].kind is SolRouteKind::PostApi)
}

///|
test "is_api_route_kind - returns true for API kinds" {
  assert_true(is_api_route_kind(SolRouteKind::GetApi))
  assert_true(is_api_route_kind(SolRouteKind::PostApi))
  assert_true(is_api_route_kind(SolRouteKind::PutApi))
  assert_true(is_api_route_kind(SolRouteKind::DeleteApi))
  assert_true(is_api_route_kind(SolRouteKind::PatchApi))
}

///|
test "is_api_route_kind - returns false for page kind" {
  assert_false(is_api_route_kind(SolRouteKind::Page))
}

///|
test "extract param names from sol routes" {
  async fn user_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("User"))
  }

  let routes = [
    SolRoutes::Page(
      path="/users/:userId/posts/:postId",
      handler=PageHandler(user_handler),
      title="User Post",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].param_names, ["userId", "postId"])
}

///|
test "page with no layout has empty layouts array" {
  async fn home_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("Home"))
  }

  let routes = [
    SolRoutes::Page(
      path="/",
      handler=PageHandler(home_handler),
      title="Home",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].layouts.length(), 0)
}

///|
test "page with single layout (root only)" {
  async fn home_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("Home"))
  }

  fn root_layout(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  let routes = [
    SolRoutes::Layout(segment="", layout=root_layout, children=[
      SolRoutes::Page(
        path="/",
        handler=PageHandler(home_handler),
        title="Home",
        meta=[],
        revalidate=None,
        cache=None,
      ),
    ]),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/")
  assert_eq(compiled[0].layouts.length(), 1)
}

///|
test "page with nested layouts (root + admin)" {
  async fn admin_home_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("Admin Home"))
  }

  fn root_layout(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  fn admin_layout(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  let routes = [
    SolRoutes::Layout(segment="", layout=root_layout, children=[
      SolRoutes::Layout(segment="/admin", layout=admin_layout, children=[
        SolRoutes::Page(
          path="/",
          handler=PageHandler(admin_home_handler),
          title="Admin",
          meta=[],
          revalidate=None,
          cache=None,
        ),
      ]),
    ]),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/admin")
  assert_eq(compiled[0].layouts.length(), 2)
}

///|
test "page with deeply nested layouts (3 levels)" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("Deep"))
  }

  fn layout1(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  fn layout2(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  fn layout3(
    _props : PageProps,
    children : @server_dom.ServerNode,
  ) -> @server_dom.ServerNode raise _ {
    children
  }

  let routes = [
    SolRoutes::Layout(segment="", layout=layout1, children=[
      SolRoutes::Layout(segment="/a", layout=layout2, children=[
        SolRoutes::Layout(segment="/b", layout=layout3, children=[
          SolRoutes::Page(
            path="/c",
            handler=PageHandler(page_handler),
            title="Deep Page",
            meta=[],
            revalidate=None,
            cache=None,
          ),
        ]),
      ]),
    ]),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/a/b/c")
  assert_eq(compiled[0].layouts.length(), 3)
}

///|
test "render_meta_tags escapes meta values" {
  let html = render_meta_tags([
    ("description", "A < B & \"quoted\""),
    ("og:title", "Tom's blog"),
  ])
  assert_true(html.contains("<meta name=\"description\""))
  assert_true(html.contains("content=\"A &lt; B &amp; &quot;quoted&quot;\""))
  assert_true(html.contains("content=\"Tom&#39;s blog\""))
}

///|
test "build_page_head appends meta tags to default head" {
  let head = build_page_head("<meta charset=\"utf-8\">", [
    ("description", "Hello"),
  ])
  assert_true(head.contains("<meta charset=\"utf-8\">"))
  assert_true(head.contains("<meta name=\"description\" content=\"Hello\">"))
}

///|
test "should_use_streaming skips ISR routes with cache" {
  let cfg = RouterConfig::default().with_streaming_ssr()
  let cfg_isr = cfg.with_isr_cache(@isr.MemoryCache::new())
  assert_true(should_use_streaming(cfg, false, None))
  assert_false(should_use_streaming(cfg, true, None))
  assert_false(should_use_streaming(cfg_isr, false, Some(60)))
}

///|
test "cache_strategy_to_header_value uses stable wire values" {
  assert_eq(
    cache_strategy_to_header_value(CacheStrategy::AlwaysFetch),
    "always-fetch",
  )
  assert_eq(
    cache_strategy_to_header_value(CacheStrategy::StaleWhileRevalidate),
    "stale-while-revalidate",
  )
}

///|
extern "js" fn ffi_stream_to_text(stream : @js.Any) -> @js.Promise[String] =
  #| (stream) => new Response(stream).text()

///|
async test "create_streaming_response_with_async wraps body with header/footer" {
  let header = "<!doctype html><html><body><header>H</header>"
  let footer = "<footer>F</footer></body></html>"
  let shell : @luna.Node[Unit, String] = @luna.h("main", [], [
    @luna.text("Hello Stream"),
  ])
  let stream = create_streaming_response_with_async(header, footer, shell)
  let html = ffi_stream_to_text(stream).wait()
  assert_true(html.has_prefix(header))
  assert_true(html.contains("<main>Hello Stream</main>"))
  assert_true(html.has_suffix(footer))
}

///|
struct TestHttpResponse {
  status : Int
  body : String
  content_type : String?
  fragment_response : String?
  cache_strategy : String?
  no_sniff : String?
  x_custom : String?
}

///|
extern "js" fn ffi_call_app_handler(
  handler : @mars.AppHandler,
  meth : String,
  url : String,
  fragment : Bool,
) -> @js_async.Promise[TestHttpResponse] =
  #| async (handler, meth, url, fragment) => {
  #|   const headers = {};
  #|   if (fragment) headers["X-Sol-Fragment"] = "true";
  #|   const req = new Request(url, { method: meth, headers });
  #|   const res = await handler(req);
  #|   return {
  #|     status: res.status,
  #|     body: await res.text(),
  #|     content_type: res.headers.get("content-type") ?? undefined,
  #|     fragment_response: res.headers.get("x-sol-fragment-response") ?? undefined,
  #|     cache_strategy: res.headers.get("x-sol-cache-strategy") ?? undefined,
  #|     no_sniff: res.headers.get("x-content-type-options") ?? undefined,
  #|     x_custom: res.headers.get("x-custom") ?? undefined,
  #|   };
  #| }

///|
fn test_root_template(marker : String) -> String {
  "<!DOCTYPE html><html><head><title>__LUNA_TITLE__</title>__LUNA_PRELOAD____LUNA_HEAD__</head><body><div id=\"" +
  marker +
  "\">__LUNA_MAIN__</div></body></html>"
}

///|
async test "register_sol_routes uses streaming response for full page" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("main", [], [@luna.text("streaming")]))
  }

  let app = @mars.Server::new()
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/",
        handler=PageHandler(page_handler),
        title="Home",
        meta=[],
        revalidate=None,
        cache=None,
      ),
    ],
    config=RouterConfig::default()
      .with_streaming_ssr()
      .with_loader_url("/assets/loader.mjs")
      .with_root_template(test_root_template("custom-root")),
  )

  let res = ffi_call_app_handler(
    app.to_handler(),
    "GET",
    "http://localhost/",
    false,
  ).wait()
  assert_eq(res.status, 200)
  assert_true(res.body.contains("custom-root"))
  assert_false(res.body.contains("<div id=\"app\">"))
  assert_true(
    res.body.contains(
      "<script type=\"module\" src=\"/assets/loader.mjs\"></script>",
    ),
  )
  assert_eq(res.cache_strategy, Some("always-fetch"))
}

///|
async test "register_sol_routes uses fragment response when X-Sol-Fragment is set" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("main", [], [@luna.text("fragment")]))
  }

  let app = @mars.Server::new()
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/",
        handler=PageHandler(page_handler),
        title="Home",
        meta=[],
        revalidate=None,
        cache=None,
      ),
    ],
    config=RouterConfig::default().with_streaming_ssr(),
  )

  let res = ffi_call_app_handler(
    app.to_handler(),
    "GET",
    "http://localhost/",
    true,
  ).wait()
  assert_eq(res.status, 200)
  assert_true(res.body.contains("<template data-sol-outlet=\"main\">"))
  assert_true(res.body.contains("<template data-sol-title>"))
  assert_false(res.body.contains("<!DOCTYPE html>"))
  assert_eq(res.fragment_response, Some("true"))
}

///|
async test "register_sol_routes skips streaming for ISR route with cache" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("main", [], [@luna.text("isr")]))
  }

  let app = @mars.Server::new()
  let marker = "isr-root"
  let config = RouterConfig::default()
    .with_streaming_ssr()
    .with_loader_url("/assets/loader.mjs")
    .with_root_template(test_root_template(marker))
    .with_isr_cache(@isr.MemoryCache::new())
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/",
        handler=PageHandler(page_handler),
        title="Home",
        meta=[],
        revalidate=Some(60),
        cache=None,
      ),
    ],
    config~,
  )

  let res = ffi_call_app_handler(
    app.to_handler(),
    "GET",
    "http://localhost/",
    false,
  ).wait()
  assert_eq(res.status, 200)
  assert_true(res.body.contains("id=\"\{marker}\""))
  assert_false(res.body.contains("<div id=\"app\">"))
  assert_eq(res.cache_strategy, Some("always-fetch"))
}

///|
async test "register_sol_routes keeps API resolver custom headers" {
  async fn api_handler(props : PageProps) -> @js.Any {
    props.ctx.set_header("X-Custom", "from-api")
    @js_any.json_obj([("ok", @js.any(true))])
  }

  let app = @mars.Server::new()
  register_sol_routes(
    app,
    [SolRoutes::Get(path="/api/custom-header", handler=ApiHandler(api_handler))],
    config=RouterConfig::default(),
  )

  let res = ffi_call_app_handler(
    app.to_handler(),
    "GET",
    "http://localhost/api/custom-header",
    false,
  ).wait()
  assert_eq(res.status, 200)
  assert_eq(res.content_type, Some("application/json"))
  assert_eq(res.no_sniff, Some("nosniff"))
  assert_eq(res.x_custom, Some("from-api"))
}
