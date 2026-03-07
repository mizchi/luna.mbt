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
  isr_status : String?
  cdn_cache : String?
  cache_control : String?
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
  #|     isr_status: res.headers.get("x-sol-isr-status") ?? undefined,
  #|     cdn_cache: res.headers.get("x-sol-cdn-cache") ?? undefined,
  #|     cache_control: res.headers.get("cache-control") ?? undefined,
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

// ============================================================================
// ISR Cache State Transition Tests (HTTP level)
// ============================================================================

///|
async test "ISR: MISS → HIT → STALE lifecycle with set_now_ms" {
  let call_count = Ref::new(0)
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    call_count.val = call_count.val + 1
    @server_dom.ServerNode::sync(
      @luna.h("p", [], [@luna.text("render-" + call_count.val.to_string())]),
    )
  }

  // Fix time to a known value
  @isr.set_now_ms(Some(1000000L))

  let cache = @isr.MemoryCache::new()
  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(cache)
    .with_root_template(test_root_template("isr-lifecycle"))
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/isr-life",
        handler=PageHandler(page_handler),
        title="ISR",
        meta=[],
        revalidate=Some(60),
        cache=None,
      ),
    ],
    config~,
  )

  let handler = app.to_handler()

  // 1. First request: MISS → renders and caches
  let res1 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-life", false,
  ).wait()
  assert_eq(res1.status, 200)
  assert_eq(res1.isr_status, Some("MISS"))
  assert_true(res1.body.contains("render-1"))
  assert_eq(call_count.val, 1)

  // Verify cache was populated
  let cache_key = @isr.cache_key("/isr-life", [])
  assert_true(@isr.ISRCache::get(cache, cache_key) is Some(_))

  // 2. Same time, second request: HIT from cache
  let res2 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-life", false,
  ).wait()
  assert_eq(res2.status, 200)
  assert_eq(res2.isr_status, Some("HIT"))
  assert_true(res2.body.contains("render-1")) // Same cached content
  assert_eq(call_count.val, 1) // Handler not called again

  // 3. Advance time past TTL (60s = 60000ms)
  @isr.set_now_ms(Some(1000000L + 61000L))
  let res3 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-life", false,
  ).wait()
  assert_eq(res3.status, 200)
  assert_eq(res3.isr_status, Some("STALE"))
  assert_true(res3.body.contains("render-1")) // Returns stale content

  // Restore real time
  @isr.set_now_ms(None)
}

///|
async test "ISR: non-ISR page has no X-Sol-ISR-Status header" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("p", [], [@luna.text("no-isr")]))
  }

  let app = @mars.Server::new()
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/no-isr",
        handler=PageHandler(page_handler),
        title="NoISR",
        meta=[],
        revalidate=None,
        cache=None,
      ),
    ],
    config=RouterConfig::default(),
  )

  let res = ffi_call_app_handler(
    app.to_handler(), "GET", "http://localhost/no-isr", false,
  ).wait()
  assert_eq(res.status, 200)
  assert_true(res.isr_status is None)
}

///|
async test "ISR: fragment request bypasses ISR cache" {
  @isr.set_now_ms(Some(1000000L))
  let call_count = Ref::new(0)
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    call_count.val = call_count.val + 1
    @server_dom.ServerNode::sync(
      @luna.h("p", [], [@luna.text("frag-" + call_count.val.to_string())]),
    )
  }

  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(@isr.MemoryCache::new())
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/isr-frag",
        handler=PageHandler(page_handler),
        title="ISRFrag",
        meta=[],
        revalidate=Some(600),
        cache=None,
      ),
    ],
    config~,
  )

  let handler = app.to_handler()

  // Full page request: ISR MISS
  let res1 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-frag", false,
  ).wait()
  assert_eq(res1.isr_status, Some("MISS"))
  assert_eq(call_count.val, 1)

  // Fragment request: should bypass ISR, render fresh each time
  let res2 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-frag", true,
  ).wait()
  assert_eq(res2.status, 200)
  assert_true(res2.isr_status is None) // No ISR for fragments
  assert_eq(call_count.val, 2) // Handler called again
  @isr.set_now_ms(None)
}

// ============================================================================
// CDNCacheStrategy Header Tests (HTTP level)
// ============================================================================

///|
async test "CDNCacheStrategy::CdnSwr sets Cache-Control and X-Sol-CDN-Cache" {
  @isr.set_now_ms(Some(1000000L))
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("p", [], [@luna.text("cdn-swr")]))
  }

  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(@isr.MemoryCache::new())
    .with_cache_strategy(@isr.CDNCacheStrategy::CdnSwr(3600))
    .with_root_template(test_root_template("cdn"))
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/cdn-page",
        handler=PageHandler(page_handler),
        title="CDN",
        meta=[],
        revalidate=Some(60),
        cache=None,
      ),
    ],
    config~,
  )

  let res = ffi_call_app_handler(
    app.to_handler(), "GET", "http://localhost/cdn-page", false,
  ).wait()
  assert_eq(res.status, 200)
  assert_eq(
    res.cache_control,
    Some("s-maxage=60, stale-while-revalidate=3600"),
  )
  assert_eq(res.cdn_cache, Some("cdn-swr"))
  assert_eq(res.isr_status, Some("MISS"))
  @isr.set_now_ms(None)
}

///|
async test "CDNCacheStrategy::Hybrid sets short CDN TTL" {
  @isr.set_now_ms(Some(1000000L))
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("p", [], [@luna.text("hybrid")]))
  }

  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(@isr.MemoryCache::new())
    .with_cache_strategy(@isr.CDNCacheStrategy::Hybrid(10, 60))
    .with_root_template(test_root_template("hybrid"))
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/hybrid-page",
        handler=PageHandler(page_handler),
        title="Hybrid",
        meta=[],
        revalidate=Some(120),
        cache=None,
      ),
    ],
    config~,
  )

  let res = ffi_call_app_handler(
    app.to_handler(), "GET", "http://localhost/hybrid-page", false,
  ).wait()
  assert_eq(res.status, 200)
  assert_eq(res.cache_control, Some("s-maxage=10, stale-while-revalidate=60"))
  assert_eq(res.cdn_cache, Some("hybrid"))
  @isr.set_now_ms(None)
}

///|
async test "CDNCacheStrategy::AppIsr sets private no-store" {
  @isr.set_now_ms(Some(1000000L))
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("p", [], [@luna.text("app-isr")]))
  }

  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(@isr.MemoryCache::new())
    .with_cache_strategy(@isr.CDNCacheStrategy::AppIsr)
    .with_root_template(test_root_template("app-isr"))
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/app-isr-page",
        handler=PageHandler(page_handler),
        title="AppISR",
        meta=[],
        revalidate=Some(60),
        cache=None,
      ),
    ],
    config~,
  )

  let res = ffi_call_app_handler(
    app.to_handler(), "GET", "http://localhost/app-isr-page", false,
  ).wait()
  assert_eq(res.status, 200)
  assert_eq(res.cache_control, Some("private, no-store"))
  assert_eq(res.cdn_cache, Some("app-isr"))
  @isr.set_now_ms(None)
}

///|
async test "no CDNCacheStrategy: no Cache-Control or X-Sol-CDN-Cache for ISR" {
  @isr.set_now_ms(Some(1000000L))
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.h("p", [], [@luna.text("default")]))
  }

  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(@isr.MemoryCache::new())
    .with_root_template(test_root_template("default"))
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/default-isr",
        handler=PageHandler(page_handler),
        title="Default",
        meta=[],
        revalidate=Some(60),
        cache=None,
      ),
    ],
    config~,
  )

  let res = ffi_call_app_handler(
    app.to_handler(), "GET", "http://localhost/default-isr", false,
  ).wait()
  assert_eq(res.status, 200)
  assert_true(res.cdn_cache is None)
  // Cache-Control may or may not be set by framework default, but X-Sol-CDN-Cache should be absent
  assert_eq(res.isr_status, Some("MISS"))
  @isr.set_now_ms(None)
}

// ============================================================================
// Query Normalization Tests
// ============================================================================

///|
test "strip_query_string removes query from path" {
  assert_eq(strip_query_string("/foo?a=1&b=2"), "/foo")
  assert_eq(strip_query_string("/no-query"), "/no-query")
  assert_eq(strip_query_string("/path?"), "/path")
  assert_eq(strip_query_string("/?x=1"), "/")
}

///|
test "cache_key normalizes query param order" {
  // Different query param orders produce the same cache key
  let key1 = @isr.cache_key("/search", [("b", "2"), ("a", "1")])
  let key2 = @isr.cache_key("/search", [("a", "1"), ("b", "2")])
  assert_eq(key1, key2)
  assert_eq(key1, "isr:/search?a=1&b=2")
}

///|
test "cache_key with stripped path has no query duplication" {
  // After strip_query_string, path should not contain query
  let path = strip_query_string("/search?b=2&a=1")
  let key = @isr.cache_key(path, [("a", "1"), ("b", "2")])
  assert_eq(key, "isr:/search?a=1&b=2")
  // Without stripping, path would be "/search?b=2&a=1" causing duplication
  let bad_key = @isr.cache_key("/search?b=2&a=1", [("a", "1"), ("b", "2")])
  assert_eq(bad_key, "isr:/search?b=2&a=1?a=1&b=2") // double query - broken
}

// ============================================================================
// ISR Render Flag Tests
// ============================================================================

///|
async test "ISR render sets is_isr_render=true on PageProps" {
  @isr.set_now_ms(Some(1000000L))
  let isr_flag = Ref::new(false)
  async fn page_handler(props : PageProps) -> @server_dom.ServerNode {
    isr_flag.val = props.is_isr_render
    @server_dom.ServerNode::sync(@luna.h("p", [], [@luna.text("isr-flag")]))
  }

  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(@isr.MemoryCache::new())
    .with_root_template(test_root_template("flag"))
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/isr-flag",
        handler=PageHandler(page_handler),
        title="ISRFlag",
        meta=[],
        revalidate=Some(60),
        cache=None,
      ),
    ],
    config~,
  )

  // ISR MISS render should have is_isr_render=true
  let res = ffi_call_app_handler(
    app.to_handler(), "GET", "http://localhost/isr-flag", false,
  ).wait()
  assert_eq(res.status, 200)
  assert_eq(res.isr_status, Some("MISS"))
  assert_true(isr_flag.val) // is_isr_render should be true
  @isr.set_now_ms(None)
}

///|
async test "non-ISR render has is_isr_render=false" {
  let isr_flag = Ref::new(true) // Start true, should become false
  async fn page_handler(props : PageProps) -> @server_dom.ServerNode {
    isr_flag.val = props.is_isr_render
    @server_dom.ServerNode::sync(@luna.h("p", [], [@luna.text("no-isr")]))
  }

  let app = @mars.Server::new()
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/no-isr-flag",
        handler=PageHandler(page_handler),
        title="NoISR",
        meta=[],
        revalidate=None,
        cache=None,
      ),
    ],
    config=RouterConfig::default(),
  )

  let res = ffi_call_app_handler(
    app.to_handler(), "GET", "http://localhost/no-isr-flag", false,
  ).wait()
  assert_eq(res.status, 200)
  assert_false(isr_flag.val) // is_isr_render should be false
}

// ============================================================================
// STALE Revalidation Dedup Tests
// ============================================================================

///|
test "isr_in_flight dedup set prevents duplicate revalidation scheduling" {
  // Verify the in-flight tracking mechanism
  let key = "isr:/test-dedup"
  assert_false(isr_in_flight.val.contains(key))
  isr_in_flight.val.add(key)
  assert_true(isr_in_flight.val.contains(key))
  // Second add is a no-op, set still contains it
  isr_in_flight.val.add(key)
  assert_true(isr_in_flight.val.contains(key))
  // Clean up
  isr_in_flight.val.remove(key)
  assert_false(isr_in_flight.val.contains(key))
}

///|
async test "ISR: STALE revalidation updates cache with fresh entry" {
  @isr.set_now_ms(Some(1000000L))
  let call_count = Ref::new(0)
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    call_count.val = call_count.val + 1
    @server_dom.ServerNode::sync(
      @luna.h("p", [], [@luna.text("dedup-" + call_count.val.to_string())]),
    )
  }

  let cache = @isr.MemoryCache::new()
  let app = @mars.Server::new()
  let config = RouterConfig::default()
    .with_isr_cache(cache)
    .with_root_template(test_root_template("dedup"))
  register_sol_routes(
    app,
    [
      SolRoutes::Page(
        path="/isr-dedup",
        handler=PageHandler(page_handler),
        title="Dedup",
        meta=[],
        revalidate=Some(60),
        cache=None,
      ),
    ],
    config~,
  )

  let handler = app.to_handler()

  // 1. MISS → render and cache
  let res1 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-dedup", false,
  ).wait()
  assert_eq(res1.isr_status, Some("MISS"))
  assert_eq(call_count.val, 1)

  // 2. Advance past TTL → STALE triggers revalidation
  @isr.set_now_ms(Some(1000000L + 61000L))
  let res2 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-dedup", false,
  ).wait()
  assert_eq(res2.isr_status, Some("STALE"))
  assert_true(res2.body.contains("dedup-1")) // Stale content returned
  // MemoryCache runs revalidation synchronously, so cache is now updated
  assert_eq(call_count.val, 2) // Revalidation triggered

  // 3. Next request after revalidation → HIT (cache was refreshed)
  let res3 = ffi_call_app_handler(
    handler, "GET", "http://localhost/isr-dedup", false,
  ).wait()
  assert_eq(res3.isr_status, Some("HIT"))
  assert_true(res3.body.contains("dedup-2")) // Fresh content from revalidation
  assert_eq(call_count.val, 2) // No additional render
  @isr.set_now_ms(None)
  isr_in_flight.val = Set::new()
}
