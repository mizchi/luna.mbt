///| Tests for route ownership manifest.

///|
test "route_ownership_manifest includes Sol page API raw and reserved ownership" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("admin"))
  }

  async fn api_handler(_props : PageProps) -> Json {
    { "ok": true }.to_json()
  }

  async fn raw_handler(_props : PageProps) -> @web_http.Response {
    @web_http.Response::text_("raw", 206)
  }

  let manifest = route_ownership_manifest(
    [
      page("/admin/:id", page_handler, styles=["./admin.css"]),
      api_post("/api/items", api_handler),
      raw_get("/media/:id", raw_handler),
    ],
    config=RouterConfig::default().with_client_script("./app.client.ts"),
  )

  assert_true(manifest.entries.length() >= 6)
  let page = manifest.match_path(
    "/admin/42",
    http_method=RouteManifestMethod::Get,
  )
  guard page is Some(page_entry) else { abort("expected page ownership entry") }
  assert_true(page_entry.owner is RouteManifestOwner::SolPage)
  assert_true(page_entry.match_kind is RouteManifestMatchKind::Pattern)
  assert_eq(page_entry.param_names, ["id"])

  let api = manifest.match_path(
    "/api/items",
    http_method=RouteManifestMethod::Post,
  )
  guard api is Some(api_entry) else { abort("expected api ownership entry") }
  assert_true(api_entry.owner is RouteManifestOwner::SolApi)

  let raw = manifest.match_path(
    "/media/a",
    http_method=RouteManifestMethod::Get,
  )
  guard raw is Some(raw_entry) else { abort("expected raw ownership entry") }
  assert_true(raw_entry.owner is RouteManifestOwner::Raw)

  let asset = manifest.match_path(
    "/static/admin.css",
    http_method=RouteManifestMethod::Get,
  )
  guard asset is Some(asset_entry) else {
    abort("expected static asset ownership entry")
  }
  assert_true(asset_entry.owner is RouteManifestOwner::StaticAsset)

  let reserved = manifest.match_path(
    "/_sol/defer/server-island",
    http_method=RouteManifestMethod::Post,
  )
  guard reserved is Some(reserved_entry) else {
    abort("expected reserved ownership entry")
  }
  assert_true(reserved_entry.owner is RouteManifestOwner::Reserved)
}

///|
test "route_ownership_manifest serializes stable json for host routers" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("home"))
  }

  let manifest = route_ownership_manifest([page("/", page_handler)])
  let json = manifest.to_json().stringify()
  assert_true(json.contains("\"owner\":\"sol-page\""))
  assert_true(json.contains("\"method\":\"GET\""))
  assert_true(json.contains("\"match\":\"exact\""))
  assert_true(json.contains("\"pattern\":\"/\""))
}

///|
test "api_client_manifest_json includes only Sol JSON API routes" {
  async fn page_handler(_props : PageProps) -> @server_dom.ServerNode {
    @server_dom.ServerNode::sync(@luna.text("home"))
  }

  async fn api_handler(_props : PageProps) -> Json {
    { "ok": true }.to_json()
  }

  async fn raw_handler(_props : PageProps) -> @web_http.Response {
    @web_http.Response::text_("raw", 200)
  }

  let manifest = route_ownership_manifest([
    page("/", page_handler),
    api_get("/api/health", api_handler),
    api_post("/api/items/:id", api_handler),
    raw_get("/api/raw", raw_handler),
  ])
  let json = manifest.api_client_manifest_json().stringify()
  assert_true(json.contains("\"name\":\"getApiHealth\""))
  assert_true(json.contains("\"name\":\"postApiItemsId\""))
  assert_true(json.contains("\"method\":\"GET\""))
  assert_true(json.contains("\"method\":\"POST\""))
  assert_true(json.contains("\"path\":\"/api/items/:id\""))
  assert_true(json.contains("\"params\":[\"id\"]"))
  assert_false(json.contains("/api/raw"))
}

///|
test "api_client_typescript generates fetch helpers with typed error shape" {
  async fn api_handler(_props : PageProps) -> Json {
    { "ok": true }.to_json()
  }

  let manifest = route_ownership_manifest([
    api_get("/api/health", api_handler),
    api_post("/api/items/:id", api_handler),
  ])
  let source = manifest.api_client_typescript()
  assert_true(source.contains("export type SolApiResult<T>"))
  assert_true(source.contains("export const api"))
  assert_true(source.contains("getApiHealth"))
  assert_true(source.contains("postApiItemsId"))
  assert_true(source.contains("params: { \"id\": string }"))
  assert_true(source.contains("fillSolApiPath(\"/api/items/:id\", params)"))
  assert_true(source.contains("method: \"POST\""))
  assert_true(source.contains("jsonHeaders(init)"))
}

///|
test "api_client_typescript quotes param names for file-system routes" {
  async fn api_handler(_props : PageProps) -> Json {
    { "ok": true }.to_json()
  }

  let manifest = route_ownership_manifest([
    api_get("/api/users/[user-id]", api_handler),
  ])
  let source = manifest.api_client_typescript()
  assert_true(source.contains("params: { \"user-id\": string }"))
  assert_true(source.contains("fillSolApiPath(\"/api/users/[user-id]\", params)"))
}

///|
test "api_client_typescript fills colon regex routes without leaving regex suffix" {
  async fn api_handler(_props : PageProps) -> Json {
    { "ok": true }.to_json()
  }

  let manifest = route_ownership_manifest([
    api_get("/api/:version{[0-9]+}/items/:id", api_handler),
  ])
  let source = manifest.api_client_typescript()
  assert_true(source.contains("params: { \"version\": string; \"id\": string }"))
  assert_true(
    source.contains(
      "fillSolApiPath(\"/api/:version{[0-9]+}/items/:id\", params)",
    ),
  )
  assert_true(
    source.contains(
      ".replace(/:([A-Za-z0-9_]+)(?:\\{[^/]+\\})?/g",
    ),
  )
}
