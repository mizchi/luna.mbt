///| Whitebox tests for explicit Sol contract manifests

///|
fn sample_contract_manifest_json() -> String {
  (
    #|{
    #|  "routes": [
    #|    { "path": "/api/items/:id" },
    #|    "/about"
    #|  ],
    #|  "actions": [
    #|    { "id": "submit-contact" },
    #|    "delete-todo"
    #|  ],
    #|  "clientAssets": [
    #|    { "component": "counter", "url": "/assets/counter.abc123.js" }
    #|  ]
    #|}
  )
}

///|
test "parse_contract_manifest_json: routes actions and client assets" {
  let manifest = parse_contract_manifest_json(sample_contract_manifest_json())
  assert_true(manifest.is_some())
  let m = manifest.unwrap()
  assert_eq(m.routes.length(), 2)
  assert_eq(m.routes[0].path, "/api/items/:id")
  assert_eq(m.routes[1].path, "/about")
  assert_eq(m.actions.length(), 2)
  assert_eq(m.actions[0].id, "submit-contact")
  assert_eq(m.actions[1].id, "delete-todo")
  assert_eq(m.client_assets.length(), 1)
  assert_eq(m.client_assets[0].component, "counter")
  assert_eq(m.client_assets[0].url, "/assets/counter.abc123.js")
}

///|
test "ContractManifest::to_route_info: feeds type generator without route source scanning" {
  let manifest = parse_contract_manifest_json(sample_contract_manifest_json()).unwrap()
  let info = manifest.to_route_info()
  assert_eq(info.route_paths.length(), 2)
  assert_eq(info.route_paths[0], "/api/items/:id")
  assert_eq(info.action_ids.length(), 2)
  assert_eq(info.action_ids[0], "submit-contact")
  assert_eq(info.action_ids[1], "delete-todo")
}

///|
test "ContractManifest::client_asset_url: resolves component url" {
  let manifest = parse_contract_manifest_json(sample_contract_manifest_json()).unwrap()
  assert_eq(
    manifest.client_asset_url("counter"),
    Some("/assets/counter.abc123.js"),
  )
  assert_eq(manifest.client_asset_url("missing"), None)
}
