///|
/// Tests for Route compilation
test "compile simple page routes" {
  let routes : Array[Route] = [
    Page(path="/", title="Home", meta=[]),
    Page(path="/about", title="About", meta=[]),
  ]
  let compiled = compile_routes(routes)
  assert_eq(compiled.length(), 2)
  assert_eq(compiled[0].pattern, "/")
  assert_eq(compiled[0].title, "Home")
  assert_eq(compiled[1].pattern, "/about")
  assert_eq(compiled[1].title, "About")
}

///|
test "compile nested path routes" {
  let routes : Array[Route] = [
    Path(
      "/api",
      [
        Get(path="/posts", title="", meta=[]),
        Post(path="/posts", title="", meta=[]),
      ],
      title="",
      meta=[],
    ),
  ]
  let compiled = compile_routes(routes)
  assert_eq(compiled.length(), 2)
  assert_eq(compiled[0].pattern, "/api/posts")
  assert_eq(compiled[0].kind, GetApi)
  assert_eq(compiled[1].pattern, "/api/posts")
  assert_eq(compiled[1].kind, PostApi)
}

///|
test "compile param routes" {
  let routes : Array[Route] = [
    Path(
      "/posts",
      [
        Param("id", key="id", title="", meta=[]),
        Page(path="", title="Post Detail", meta=[]),
      ],
      title="",
      meta=[],
    ),
  ]
  let compiled = compile_routes(routes)
  assert_eq(compiled.length(), 1)
  // パターンには :id プレースホルダーが含まれる
  assert_eq(compiled[0].pattern, "/posts/:id")
  assert_eq(compiled[0].param_names, ["id"])
  assert_eq(compiled[0].title, "Post Detail")
}

///|
test "compile deeply nested routes" {
  let routes : Array[Route] = [
    Path(
      "/api",
      [
        Path(
          "/v1",
          [
            Path(
              "/users",
              [
                Param("user_id", key="user_id", title="", meta=[]),
                Get(path="", title="", meta=[]),
                Path(
                  "/posts",
                  [
                    Param("post_id", key="post_id", title="", meta=[]),
                    Get(path="", title="", meta=[]),
                  ],
                  title="",
                  meta=[],
                ),
              ],
              title="",
              meta=[],
            ),
          ],
          title="",
          meta=[],
        ),
      ],
      title="",
      meta=[],
    ),
  ]
  let compiled = compile_routes(routes)
  assert_eq(compiled.length(), 2)
  // パターンには :param プレースホルダーが含まれる
  assert_eq(compiled[0].pattern, "/api/v1/users/:user_id")
  assert_eq(compiled[0].param_names, ["user_id"])
  assert_eq(compiled[1].pattern, "/api/v1/users/:user_id/posts/:post_id")
  assert_eq(compiled[1].param_names, ["user_id", "post_id"])
}

///|
test "normalize_path removes duplicate slashes" {
  assert_eq(normalize_path("//"), "/")
  assert_eq(normalize_path("/api//posts"), "/api/posts")
  assert_eq(normalize_path("/a///b"), "/a/b")
}

///|
test "normalize_path removes trailing slash" {
  assert_eq(normalize_path("/about/"), "/about")
  assert_eq(normalize_path("/api/posts/"), "/api/posts")
}

///|
test "normalize_path keeps root" {
  assert_eq(normalize_path("/"), "/")
  assert_eq(normalize_path(""), "/")
}

///|
test "RouteProps::get_param" {
  let props : RouteProps = {
    is_client: false,
    params: [("id", "123"), ("slug", "hello")],
    query: [],
    path: "/posts/123",
  }
  assert_eq(props.get_param("id"), Some("123"))
  assert_eq(props.get_param("slug"), Some("hello"))
  assert_eq(props.get_param("unknown"), None)
}

///|
test "RouteProps::get_query" {
  let props : RouteProps = {
    is_client: false,
    params: [],
    query: [("page", "2"), ("sort", "asc")],
    path: "/posts",
  }
  assert_eq(props.get_query("page"), Some("2"))
  assert_eq(props.get_query("sort"), Some("asc"))
  assert_eq(props.get_query("unknown"), None)
}

// =============================================================================
// URL Matching Tests
// =============================================================================

///|
test "parse_url without query" {
  let (path, query) = parse_url("/posts/123")
  assert_eq(path, "/posts/123")
  assert_eq(query.length(), 0)
}

///|
test "parse_url with query" {
  let (path, query) = parse_url("/posts?page=1&sort=asc")
  assert_eq(path, "/posts")
  assert_eq(query.length(), 2)
  assert_eq(query[0], ("page", "1"))
  assert_eq(query[1], ("sort", "asc"))
}

///|
test "split_string" {
  let parts = split_string("a/b/c", '/')
  assert_eq(parts, ["a", "b", "c"])
  let empty = split_string("", '/')
  assert_eq(empty, [""])
  let single = split_string("abc", '/')
  assert_eq(single, ["abc"])
}

///|
test "split_path" {
  let segments = split_path("/api/posts/123")
  assert_eq(segments, ["api", "posts", "123"])
  let root = split_path("/")
  assert_eq(root.length(), 0)
}

///|
test "match_route static path" {
  let routes : Array[Route] = [
    Page(path="/", title="Home", meta=[]),
    Page(path="/about", title="About", meta=[]),
  ]
  let compiled = compile_routes(routes)
  let result = match_route("/", compiled, false)
  assert_true(result is Some(_))
  assert_eq(result.unwrap().route.title, "Home")
  let result2 = match_route("/about", compiled, false)
  assert_true(result2 is Some(_))
  assert_eq(result2.unwrap().route.title, "About")
  let result3 = match_route("/unknown", compiled, false)
  assert_true(result3 is None)
}

///|
test "match_route with params" {
  let routes : Array[Route] = [
    Path(
      "/posts",
      [
        Param("id", key="id", title="", meta=[]),
        Page(path="", title="Post", meta=[]),
      ],
      title="",
      meta=[],
    ),
  ]
  let compiled = compile_routes(routes)
  let result = match_route("/posts/123", compiled, false)
  assert_true(result is Some(_))
  let m = result.unwrap()
  assert_eq(m.route.title, "Post")
  assert_eq(m.props.get_param("id"), Some("123"))
}

///|
test "match_route with query string" {
  let routes : Array[Route] = [Page(path="/search", title="Search", meta=[])]
  let compiled = compile_routes(routes)
  let result = match_route("/search?q=hello&page=2", compiled, false)
  assert_true(result is Some(_))
  let m = result.unwrap()
  assert_eq(m.props.path, "/search")
  assert_eq(m.props.get_query("q"), Some("hello"))
  assert_eq(m.props.get_query("page"), Some("2"))
}

///|
test "match_route is_client flag" {
  let routes : Array[Route] = [Page(path="/", title="Home", meta=[])]
  let compiled = compile_routes(routes)
  let server = match_route("/", compiled, false)
  assert_eq(server.unwrap().props.is_client, false)
  let client = match_route("/", compiled, true)
  assert_eq(client.unwrap().props.is_client, true)
}

///|
test "match_route deeply nested with params" {
  let routes : Array[Route] = [
    Path(
      "/api",
      [
        Path(
          "/v1",
          [
            Path(
              "/users",
              [
                Param("user_id", key="user_id", title="", meta=[]),
                Path(
                  "/posts",
                  [
                    Param("post_id", key="post_id", title="", meta=[]),
                    Get(path="", title="Get Post", meta=[]),
                  ],
                  title="",
                  meta=[],
                ),
              ],
              title="",
              meta=[],
            ),
          ],
          title="",
          meta=[],
        ),
      ],
      title="",
      meta=[],
    ),
  ]
  let compiled = compile_routes(routes)

  // パターンには :param プレースホルダーが含まれる
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/api/v1/users/:user_id/posts/:post_id")
  assert_eq(compiled[0].param_names, ["user_id", "post_id"])

  // URLマッチング
  let result = match_route("/api/v1/users/123/posts/456", compiled, false)
  assert_true(result is Some(_))
  let m = result.unwrap()
  assert_eq(m.route.title, "Get Post")
  assert_eq(m.props.get_param("user_id"), Some("123"))
  assert_eq(m.props.get_param("post_id"), Some("456"))
}

// =============================================================================
// ServerRouter Tests
// =============================================================================

///|
test "ServerRouter basic" {
  let routes : Array[Route] = [
    Page(path="/", title="Home", meta=[]),
    Page(path="/about", title="About", meta=[]),
    Path(
      "/posts",
      [
        Param("id", key="id", title="", meta=[]),
        Page(path="", title="Post Detail", meta=[]),
      ],
      title="",
      meta=[],
    ),
  ]
  let router = ServerRouter::new(routes)

  // ルート数
  assert_eq(router.length(), 3)

  // マッチング
  let home = router.match_url("/")
  assert_true(home is Some(_))
  assert_eq(home.unwrap().route.title, "Home")
  let about = router.match_url("/about")
  assert_true(about is Some(_))
  assert_eq(about.unwrap().route.title, "About")

  // 404
  let not_found = router.match_url("/not-exist")
  assert_true(not_found is None)
}

///|
test "ServerRouter resolve returns RouterContext" {
  let routes : Array[Route] = [
    Page(path="/", title="Home", meta=[("description", "Home page")]),
    Path(
      "/posts",
      [
        Param("id", key="id", title="", meta=[]),
        Page(path="", title="Post", meta=[]),
      ],
      title="",
      meta=[],
    ),
  ]
  let router = ServerRouter::new(routes)

  // Home
  let ctx = router.resolve("/")
  assert_true(ctx is Some(_))
  let home_ctx = ctx.unwrap()
  assert_eq(home_ctx.path, "/")
  assert_eq(home_ctx.route_meta.title, "Home")
  assert_eq(home_ctx.kind, Page)

  // Post with param
  let post_ctx = router.resolve("/posts/123")
  assert_true(post_ctx is Some(_))
  let p = post_ctx.unwrap()
  assert_eq(p.path, "/posts/123")
  assert_eq(p.get_param("id"), Some("123"))

  // 404
  let not_found = router.resolve("/not-exist")
  assert_true(not_found is None)
}

///|
test "ServerRouter with query params" {
  let routes : Array[Route] = [Page(path="/search", title="Search", meta=[])]
  let router = ServerRouter::new(routes)
  let ctx = router.resolve("/search?q=hello&page=2")
  assert_true(ctx is Some(_))
  let c = ctx.unwrap()
  assert_eq(c.path, "/search")
  assert_eq(c.get_query("q"), Some("hello"))
  assert_eq(c.get_query("page"), Some("2"))
}

///|
test "RouterContext::not_found" {
  let ctx = RouterContext::not_found("/some/path")
  assert_eq(ctx.path, "/some/path")
  assert_eq(ctx.route_meta.title, "Not Found")
  assert_eq(ctx.params.length(), 0)
}

// =============================================================================
// SSR-Specific Tests
// =============================================================================

///|
test "ServerRouter API routes GET/POST distinction" {
  let routes : Array[Route] = [
    Path(
      "/api",
      [
        Get(path="/users", title="Get Users", meta=[]),
        Post(path="/users", title="Create User", meta=[]),
        Path(
          "/users",
          [
            Param("id", key="id", title="", meta=[]),
            Get(path="", title="Get User", meta=[]),
            Post(path="", title="Update User", meta=[]),
          ],
          title="",
          meta=[],
        ),
      ],
      title="",
      meta=[],
    ),
  ]
  let router = ServerRouter::new(routes)

  // 同じパスでも kind で区別される
  let routes_list = router.get_routes()
  assert_eq(routes_list.length(), 4)

  // GET /api/users
  let get_users = routes_list[0]
  assert_eq(get_users.pattern, "/api/users")
  assert_eq(get_users.kind, GetApi)
  assert_eq(get_users.title, "Get Users")

  // POST /api/users
  let post_users = routes_list[1]
  assert_eq(post_users.pattern, "/api/users")
  assert_eq(post_users.kind, PostApi)
  assert_eq(post_users.title, "Create User")
}

///|
test "ServerRouter meta information preserved" {
  let routes : Array[Route] = [
    Page(path="/", title="Home", meta=[
      ("description", "Welcome to our site"),
      ("og:title", "Home Page"),
    ]),
    Page(path="/about", title="About Us", meta=[
      ("description", "About our company"),
      ("robots", "index,follow"),
    ]),
  ]
  let router = ServerRouter::new(routes)
  let home = router.resolve("/")
  guard home is Some(ctx) else { fail("Expected Some") }
  assert_eq(ctx.route_meta.title, "Home")
  assert_eq(ctx.route_meta.meta.length(), 2)
  assert_eq(ctx.route_meta.meta[0], ("description", "Welcome to our site"))
  assert_eq(ctx.route_meta.meta[1], ("og:title", "Home Page"))
  let about = router.resolve("/about")
  guard about is Some(ctx2) else { fail("Expected Some") }
  assert_eq(ctx2.route_meta.meta.length(), 2)
  assert_eq(ctx2.route_meta.meta[0], ("description", "About our company"))
}

///|
test "ServerRouter from_compiled" {
  let routes : Array[Route] = [
    Page(path="/", title="Home", meta=[]),
    Page(path="/about", title="About", meta=[]),
  ]
  let compiled = compile_routes(routes)

  // コンパイル済みルートから作成
  let router = ServerRouter::from_compiled(compiled)
  assert_eq(router.length(), 2)
  let home = router.resolve("/")
  guard home is Some(ctx) else { fail("Expected Some") }
  assert_eq(ctx.route_meta.title, "Home")
}

///|
test "ServerRouter trailing slash normalization" {
  let routes : Array[Route] = [
    Page(path="/about", title="About", meta=[]),
    Page(path="/contact", title="Contact", meta=[]),
  ]
  let router = ServerRouter::new(routes)

  // 末尾スラッシュあり/なしの両方でマッチ
  let about1 = router.resolve("/about")
  guard about1 is Some(ctx1) else { fail("Expected Some") }
  assert_eq(ctx1.route_meta.title, "About")
  let about2 = router.resolve("/about/")
  guard about2 is Some(ctx2) else { fail("Expected Some") }
  assert_eq(ctx2.route_meta.title, "About")
}

///|
test "ServerRouter multiple params in path" {
  let routes : Array[Route] = [
    Path(
      "/users",
      [
        Param("user_id", key="user_id", title="", meta=[]),
        Path(
          "/posts",
          [
            Param("post_id", key="post_id", title="", meta=[]),
            Path(
              "/comments",
              [
                Param("comment_id", key="comment_id", title="", meta=[]),
                Page(path="", title="Comment Detail", meta=[]),
              ],
              title="",
              meta=[],
            ),
          ],
          title="",
          meta=[],
        ),
      ],
      title="",
      meta=[],
    ),
  ]
  let router = ServerRouter::new(routes)
  let ctx = router.resolve("/users/1/posts/2/comments/3")
  guard ctx is Some(c) else { fail("Expected Some") }
  assert_eq(c.get_param("user_id"), Some("1"))
  assert_eq(c.get_param("post_id"), Some("2"))
  assert_eq(c.get_param("comment_id"), Some("3"))
  assert_eq(c.route_meta.title, "Comment Detail")
}

///|
test "ServerRouter RouteKind in context" {
  let routes : Array[Route] = [
    Page(path="/", title="Home", meta=[]),
    Get(path="/api/data", title="Get Data", meta=[]),
    Post(path="/api/data", title="Post Data", meta=[]),
  ]
  let router = ServerRouter::new(routes)
  let page = router.resolve("/")
  guard page is Some(p) else { fail("Expected Some") }
  assert_eq(p.kind, Page)

  // Note: match_url returns first match, GET comes before POST in compilation
  let api = router.match_url("/api/data")
  guard api is Some(a) else { fail("Expected Some") }
  assert_eq(a.route.kind, GetApi)
}

///|
test "ServerRouter empty path segment handling" {
  let routes : Array[Route] = [
    Path(
      "/api",
      [
        Path(
          "/v1",
          [Page(path="/health", title="Health Check", meta=[])],
          title="",
          meta=[],
        ),
      ],
      title="",
      meta=[],
    ),
  ]
  let router = ServerRouter::new(routes)

  // 正常なパス
  let health = router.resolve("/api/v1/health")
  guard health is Some(h) else { fail("Expected Some") }
  assert_eq(h.route_meta.title, "Health Check")

  // 重複スラッシュがあっても正規化される
  let health2 = router.resolve("/api//v1/health")
  guard health2 is Some(h2) else { fail("Expected Some") }
  assert_eq(h2.route_meta.title, "Health Check")
}

///|
test "ServerRouter query string edge cases" {
  let routes : Array[Route] = [Page(path="/search", title="Search", meta=[])]
  let router = ServerRouter::new(routes)

  // 空のクエリパラメータ
  let empty_value = router.resolve("/search?q=")
  guard empty_value is Some(ev) else { fail("Expected Some") }
  assert_eq(ev.get_query("q"), Some(""))

  // クエリなしの?
  let empty_query = router.resolve("/search?")
  guard empty_query is Some(eq) else { fail("Expected Some") }
  assert_eq(eq.path, "/search")

  // 複数の同名パラメータ（最初のものが取得される）
  let multi = router.resolve("/search?q=first&q=second")
  guard multi is Some(m) else { fail("Expected Some") }
  assert_eq(m.get_query("q"), Some("first"))
}

///|
test "RouterContext::new with defaults" {
  let ctx = RouterContext::new(path="/test")
  assert_eq(ctx.path, "/test")
  assert_eq(ctx.params.length(), 0)
  assert_eq(ctx.query.length(), 0)
  assert_eq(ctx.route_meta.title, "")
  assert_eq(ctx.kind, Page)
}

///|
test "RouterContext::new with all params" {
  let ctx = RouterContext::new(
    path="/users/123",
    params=[("id", "123")],
    query=[("page", "1")],
    route_meta={ title: "User Detail", meta: [("robots", "noindex")] },
    kind=Page,
  )
  assert_eq(ctx.path, "/users/123")
  assert_eq(ctx.get_param("id"), Some("123"))
  assert_eq(ctx.get_query("page"), Some("1"))
  assert_eq(ctx.route_meta.title, "User Detail")
}
