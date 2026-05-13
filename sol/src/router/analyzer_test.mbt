///|
/// Tests for Route Analyzer
test "analyze_routes extracts API routes as dynamic" {
  let routes : Array[SolRoutes] = [
    SolRoutes::Get(
      path="/api/health",
      handler=ApiHandler(async fn(_) { ().to_json() }),
    ),
    SolRoutes::Post(
      path="/api/users",
      handler=ApiHandler(async fn(_) { ().to_json() }),
    ),
  ]
  let analyzed = analyze_routes(routes)
  inspect(analyzed.length(), content="2")
  inspect(analyzed[0].pattern, content="/api/health")
  inspect(analyzed[0].kind is Dynamic, content="true")
  inspect(analyzed[0].reason, content="API GET endpoint")
  inspect(analyzed[1].pattern, content="/api/users")
  inspect(analyzed[1].kind is Dynamic, content="true")
  inspect(analyzed[1].reason, content="API POST endpoint")
}

///|
test "analyze_routes classifies ISR pages as dynamic" {
  let routes : Array[SolRoutes] = [
    SolRoutes::Page(
      path="/blog",
      handler=PageHandler(async fn(_) {
        @server_dom.ServerNode::sync(@luna.text(""))
      }),
      title="Blog",
      meta=[],
      revalidate=Some(60),
      cache=None,
    ),
  ]
  let analyzed = analyze_routes(routes)
  inspect(analyzed.length(), content="1")
  inspect(analyzed[0].kind is Dynamic, content="true")
  inspect(analyzed[0].reason, content="ISR enabled (revalidate)")
}

///|
test "analyze_routes classifies static pages correctly" {
  let routes : Array[SolRoutes] = [
    SolRoutes::Page(
      path="/about",
      handler=PageHandler(async fn(_) {
        @server_dom.ServerNode::sync(@luna.text(""))
      }),
      title="About",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let analyzed = analyze_routes(routes)
  inspect(analyzed.length(), content="1")
  inspect(analyzed[0].kind is Static, content="true")
  inspect(analyzed[0].reason, content="Static page")
}

///|
test "analyze_routes classifies dynamic path params as dynamic" {
  let routes : Array[SolRoutes] = [
    SolRoutes::Page(
      path="/user/:id",
      handler=PageHandler(async fn(_) {
        @server_dom.ServerNode::sync(@luna.text(""))
      }),
      title="User",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
  let analyzed = analyze_routes(routes)
  inspect(analyzed.length(), content="1")
  inspect(analyzed[0].kind is Dynamic, content="true")
  inspect(analyzed[0].reason, content="Dynamic path parameter")
}
