///| Tests for Cloudflare adapter utilities.

///|
fn test_page(path : String, revalidate? : Int? = None) -> @router.SolRoutes {
  @router.SolRoutes::Page(
    path~,
    handler=@router.PageHandler(async fn(_) {
      @router.server_nodes([])
    }),
    title="",
    meta=[],
    revalidate~,
    cache=None,
  )
}

///|
fn test_get(path : String) -> @router.SolRoutes {
  @router.SolRoutes::Get(
    path~,
    handler=@router.ApiHandler(async fn(_) { Json::null() }),
  )
}

///|
test "route_pattern_to_worker_glob converts Sol params to Cloudflare wildcards" {
  assert_eq(route_pattern_to_worker_glob("/users/:id"), "/users/*")
  assert_eq(route_pattern_to_worker_glob("/docs/[...slug]"), "/docs/*")
  assert_eq(route_pattern_to_worker_glob("/docs/[[...path]]"), "/docs/*")
  assert_eq(route_pattern_to_worker_glob("/"), "/")
}

///|
test "extract_worker_first_patterns uses Sol route analysis without core owning Cloudflare conversion" {
  let routes : Array[@router.SolRoutes] = [
    test_page("/"),
    test_page("/blog/:slug", revalidate=Some(60)),
    test_get("/api/health"),
  ]
  let patterns = extract_worker_first_patterns(routes)
  assert_eq(patterns.length(), 2)
  assert_eq(patterns[0], "/api/health")
  assert_eq(patterns[1], "/blog/*")
}

///|
test "generate_wrangler_assets_config omits worker-first list for static-only routes" {
  let config = generate_wrangler_assets_config([test_page("/")], "./dist")
  assert_true(config.contains("\"directory\": \"./dist\""))
  assert_true(config.contains("\"not_found_handling\": \"404-page\""))
  assert_false(config.contains("run_worker_first"))
}

///|
test "generate_wrangler_assets_config includes worker-first list for hybrid routes" {
  let config = generate_wrangler_assets_config(
    [test_page("/"), test_get("/api/health")],
    "./dist",
  )
  assert_true(config.contains("\"run_worker_first\""))
  assert_true(config.contains("\"/api/health\""))
}
