//

///|
/// Routes tests - cross-platform (js, wasm-gc, native)
test "compile simple page route" {
  let routes = [
    Routes::Page(path="/", component="home", title="Home", meta=[]),
    Routes::Page(path="/about", component="about", title="About", meta=[]),
  ]
  let compiled = compile(routes)
  assert_eq(compiled.length(), 2)
  assert_eq(compiled[0].pattern, "/")
  assert_eq(compiled[0].component, "home")
  assert_eq(compiled[1].pattern, "/about")
  assert_eq(compiled[1].component, "about")
}

///|
test "compile with layout" {
  let routes = [
    Routes::Layout(segment="/api", layout="api_layout", children=[
      Routes::Page(path="/users", component="users", title="Users", meta=[]),
      Routes::Page(path="/posts", component="posts", title="Posts", meta=[]),
    ]),
  ]
  let compiled = compile(routes)
  assert_eq(compiled.length(), 2)
  assert_eq(compiled[0].pattern, "/api/users")
  assert_eq(compiled[0].layouts, ["api_layout"])
  assert_eq(compiled[1].pattern, "/api/posts")
}

///|
test "compile with param in path" {
  let routes = [
    Routes::Page(
      path="/users/:id",
      component="user_detail",
      title="User",
      meta=[],
    ),
  ]
  let compiled = compile(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/users/:id")
  assert_eq(compiled[0].param_names, ["id"])
}

///|
test "compile with multiple params" {
  let routes = [
    Routes::Page(
      path="/users/:userId/posts/:postId",
      component="user_post",
      title="Post",
      meta=[],
    ),
  ]
  let compiled = compile(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/users/:userId/posts/:postId")
  assert_eq(compiled[0].param_names, ["userId", "postId"])
}

///|
test "match_url simple" {
  let routes = [
    Routes::Page(path="/", component="home", title="Home", meta=[]),
    Routes::Page(path="/about", component="about", title="About", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/about", compiled)
  assert_true(m is Some(_))
  assert_eq(m.unwrap().component(), "about")
}

///|
test "match_url with param" {
  let routes = [
    Routes::Page(path="/items/:id", component="item", title="Item", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/items/123", compiled)
  assert_true(m is Some(_))
  let matched = m.unwrap()
  assert_eq(matched.component(), "item")
  assert_eq(matched.get_param("id"), Some("123"))
}

///|
test "match_url with query" {
  let routes = [
    Routes::Page(path="/search", component="search", title="Search", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/search?q=hello&page=1", compiled)
  assert_true(m is Some(_))
  let matched = m.unwrap()
  assert_eq(matched.get_query("q"), Some("hello"))
  assert_eq(matched.get_query("page"), Some("1"))
}

///|
test "match_url no match" {
  let routes = [
    Routes::Page(path="/home", component="home", title="Home", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/notfound", compiled)
  assert_true(m is None)
}

///|
test "compile with nested layout" {
  let routes = [
    Routes::Layout(segment="/admin", layout="admin_layout", children=[
      Routes::Page(
        path="/dashboard",
        component="dashboard",
        title="Dashboard",
        meta=[],
      ),
    ]),
  ]
  let compiled = compile(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/admin/dashboard")
  assert_eq(compiled[0].layouts, ["admin_layout"])
}

///|
test "RoutesKind via match result" {
  let routes = [
    Routes::Page(path="/page", component="page", title="Page", meta=[]),
    Routes::Get(path="/api/data", handler="get_data"),
  ]
  let compiled = compile(routes)
  let page_match = match_url("/page", compiled).unwrap()
  let api_match = match_url("/api/data", compiled).unwrap()
  assert_true(page_match.kind() is Page)
  assert_true(api_match.kind() is GetApi)
}
