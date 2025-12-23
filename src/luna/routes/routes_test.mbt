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
    Routes::Page(path="/users/:id", component="user_detail", title="User", meta=[]),
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

// =============================================================================
// Catch-All Route Tests
// =============================================================================

///|
test "compile catch-all route [...slug]" {
  let routes = [
    Routes::Page(path="/docs/[...slug]", component="docs", title="Docs", meta=[]),
  ]
  let compiled = compile(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/docs/[...slug]")
  assert_true(compiled[0].catch_all is Some(_))
  let catch_all = compiled[0].catch_all.unwrap()
  assert_eq(catch_all.name, "slug")
  assert_eq(catch_all.optional, false)
}

///|
test "compile optional catch-all route [[...slug]]" {
  let routes = [
    Routes::Page(path="/blog/[[...path]]", component="blog", title="Blog", meta=[]),
  ]
  let compiled = compile(routes)
  assert_eq(compiled.length(), 1)
  assert_eq(compiled[0].pattern, "/blog/[[...path]]")
  assert_true(compiled[0].catch_all is Some(_))
  let catch_all = compiled[0].catch_all.unwrap()
  assert_eq(catch_all.name, "path")
  assert_eq(catch_all.optional, true)
}

///|
test "match_url catch-all single segment" {
  let routes = [
    Routes::Page(path="/docs/[...slug]", component="docs", title="Docs", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/docs/intro", compiled)
  assert_true(m is Some(_))
  let matched = m.unwrap()
  assert_eq(matched.component(), "docs")
  assert_eq(matched.get_param("slug"), Some("intro"))
}

///|
test "match_url catch-all multiple segments" {
  let routes = [
    Routes::Page(path="/docs/[...slug]", component="docs", title="Docs", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/docs/guide/getting-started/install", compiled)
  assert_true(m is Some(_))
  let matched = m.unwrap()
  assert_eq(matched.component(), "docs")
  assert_eq(matched.get_param("slug"), Some("guide/getting-started/install"))
}

///|
test "match_url required catch-all no segments fails" {
  let routes = [
    Routes::Page(path="/docs/[...slug]", component="docs", title="Docs", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/docs", compiled)
  assert_true(m is None)
}

///|
test "match_url optional catch-all no segments succeeds" {
  let routes = [
    Routes::Page(path="/blog/[[...path]]", component="blog", title="Blog", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/blog", compiled)
  assert_true(m is Some(_))
  let matched = m.unwrap()
  assert_eq(matched.component(), "blog")
  assert_eq(matched.get_param("path"), Some(""))
}

///|
test "match_url optional catch-all with segments" {
  let routes = [
    Routes::Page(path="/blog/[[...path]]", component="blog", title="Blog", meta=[]),
  ]
  let compiled = compile(routes)
  let m = match_url("/blog/2024/12/post", compiled)
  assert_true(m is Some(_))
  let matched = m.unwrap()
  assert_eq(matched.component(), "blog")
  assert_eq(matched.get_param("path"), Some("2024/12/post"))
}

///|
test "match_url catch-all with prefix param" {
  let routes = [
    Routes::Page(
      path="/user/:id/files/[...path]",
      component="user_files",
      title="Files",
      meta=[],
    ),
  ]
  let compiled = compile(routes)
  let m = match_url("/user/123/files/documents/report.pdf", compiled)
  assert_true(m is Some(_))
  let matched = m.unwrap()
  assert_eq(matched.component(), "user_files")
  assert_eq(matched.get_param("id"), Some("123"))
  assert_eq(matched.get_param("path"), Some("documents/report.pdf"))
}

///|
test "compile does not extract catch-all as regular param" {
  let routes = [
    Routes::Page(path="/docs/[...slug]", component="docs", title="Docs", meta=[]),
  ]
  let compiled = compile(routes)
  // param_names should not include catch-all
  assert_eq(compiled[0].param_names.length(), 0)
}

///|
test "compile mixed params and catch-all" {
  let routes = [
    Routes::Page(
      path="/org/:orgId/repo/:repoId/tree/[...path]",
      component="tree",
      title="Tree",
      meta=[],
    ),
  ]
  let compiled = compile(routes)
  assert_eq(compiled[0].param_names, ["orgId", "repoId"])
  assert_true(compiled[0].catch_all is Some(_))
  assert_eq(compiled[0].catch_all.unwrap().name, "path")
}
