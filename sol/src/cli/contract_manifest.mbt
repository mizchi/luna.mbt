// Explicit Sol contract manifest support.
//
// This lets users provide route/action/client-asset contracts as data instead
// of making `sol generate` infer everything from routes.mbt source text.

///|
priv struct ContractRoute {
  path : String
}

///|
priv struct ContractAction {
  id : String
}

///|
priv struct ContractClientAsset {
  component : String
  url : String
}

///|
priv struct ContractManifest {
  routes : Array[ContractRoute]
  actions : Array[ContractAction]
  client_assets : Array[ContractClientAsset]
}

///|
fn ContractManifest::to_route_info(self : ContractManifest) -> RouteInfo {
  let route_paths : Array[String] = []
  for route in self.routes {
    if !route_paths.contains(route.path) {
      route_paths.push(route.path)
    }
  }
  let action_ids : Array[String] = []
  for action in self.actions {
    if !action_ids.contains(action.id) {
      action_ids.push(action.id)
    }
  }
  { _page_components: [], _api_handlers: [], route_paths, action_ids }
}

///|
fn ContractManifest::client_asset_url(
  self : ContractManifest,
  component : String,
) -> String? {
  for asset in self.client_assets {
    if asset.component == component {
      return Some(asset.url)
    }
  }
  None
}

///|
fn contract_client_asset_url(
  assets : Array[ContractClientAsset],
  component : String,
) -> String? {
  ({ routes: [], actions: [], client_assets: assets } : ContractManifest).client_asset_url(
    component,
  )
}

///|
fn contract_client_assets_has(
  assets : Array[ContractClientAsset],
  component : String,
) -> Bool {
  contract_client_asset_url(assets, component).is_some()
}

///|
fn parse_contract_manifest_json(json_str : String) -> ContractManifest? {
  let json : Json = @json.parse(json_str) catch { _ => return None }
  guard json is Object(obj) else { return None }
  Some({
    routes: parse_contract_routes(obj),
    actions: parse_contract_actions(obj),
    client_assets: parse_contract_client_assets(obj),
  })
}

///|
fn[FS : @env.FileSystem] load_contract_manifest_with_fs(
  fs : FS,
  cwd : String,
  manifest_path : String,
) -> ContractManifest? {
  let full_path = if manifest_path.has_prefix("/") {
    manifest_path
  } else {
    @path.join2(cwd, manifest_path)
  }
  let content = fs.read_file_sync(full_path) catch { _ => return None }
  parse_contract_manifest_json(content)
}

///|
fn parse_contract_routes(obj : Map[String, Json]) -> Array[ContractRoute] {
  let result : Array[ContractRoute] = []
  let entries = match obj.get("routes") {
    Some(Array(arr)) => arr
    _ => []
  }
  for entry in entries {
    let path = match entry {
      String(s) => s
      Object(route_obj) =>
        match @json_utils.extract_string_opt(route_obj, "path") {
          Some(s) => s
          None => continue
        }
      _ => continue
    }
    if !path.is_empty() {
      result.push({ path, })
    }
  }
  result
}

///|
fn parse_contract_actions(obj : Map[String, Json]) -> Array[ContractAction] {
  let result : Array[ContractAction] = []
  let entries = match obj.get("actions") {
    Some(Array(arr)) => arr
    _ => []
  }
  for entry in entries {
    let id = match entry {
      String(s) => s
      Object(action_obj) =>
        match @json_utils.extract_string_opt(action_obj, "id") {
          Some(s) => s
          None => continue
        }
      _ => continue
    }
    if !id.is_empty() {
      result.push({ id, })
    }
  }
  result
}

///|
fn parse_contract_client_assets(
  obj : Map[String, Json],
) -> Array[ContractClientAsset] {
  let result : Array[ContractClientAsset] = []
  let entries = match obj.get("clientAssets") {
    Some(Array(arr)) => arr
    _ =>
      match obj.get("client_assets") {
        Some(Array(arr)) => arr
        _ => []
      }
  }
  for entry in entries {
    guard entry is Object(asset_obj) else { continue }
    let component = match
      @json_utils.extract_string_opt(asset_obj, "component") {
      Some(s) => s
      None => continue
    }
    let url = match @json_utils.extract_string_opt(asset_obj, "url") {
      Some(s) => s
      None => continue
    }
    if !component.is_empty() && !url.is_empty() {
      result.push({ component, url })
    }
  }
  result
}
