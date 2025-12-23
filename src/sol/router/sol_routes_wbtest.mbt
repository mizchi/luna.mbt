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
    ),
  ]
  let compiled = compile_sol_routes(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].param_names, ["userId", "postId"])
}
