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
priv struct ContractPropsField {
  name : String
  type_name : String
}

///|
priv struct ContractProps {
  name : String
  fields : Array[ContractPropsField]
}

///|
priv struct ContractComponent {
  name : String
  props : ContractProps
  package_path : String
  import_alias : String
}

///|
priv struct ContractManifest {
  routes : Array[ContractRoute]
  actions : Array[ContractAction]
  client_assets : Array[ContractClientAsset]
  components : Array[ContractComponent]
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
fn ContractManifest::to_struct_exports(
  self : ContractManifest,
) -> Array[StructExport] {
  let result : Array[StructExport] = []
  for component in self.components {
    let _component_name = component.name
    result.push({
      name: component.props.name,
      raw_definition: contract_props_raw_definition(component.props),
      package_path: component.package_path,
      import_alias: component.import_alias,
    })
  }
  result
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
  (
    { routes: [], actions: [], client_assets: assets, components: [] } :
    ContractManifest).client_asset_url(component)
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
  let routes = match parse_contract_routes(obj) {
    Some(routes) => routes
    None => return None
  }
  let actions = match parse_contract_actions(obj) {
    Some(actions) => actions
    None => return None
  }
  let client_assets = match parse_contract_client_assets(obj) {
    Some(client_assets) => client_assets
    None => return None
  }
  let components = match parse_contract_components(obj) {
    Some(components) => components
    None => return None
  }
  let manifest = { routes, actions, client_assets, components }
  if validate_contract_manifest(manifest) {
    Some(manifest)
  } else {
    None
  }
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
fn parse_contract_routes(obj : Map[String, Json]) -> Array[ContractRoute]? {
  let result : Array[ContractRoute] = []
  let entries = match obj.get("routes") {
    Some(Array(arr)) => arr
    Some(_) => return None
    None => []
  }
  for entry in entries {
    let path = match entry {
      String(s) => s
      Object(route_obj) =>
        match @json_utils.extract_string_opt(route_obj, "path") {
          Some(s) => s
          None => return None
        }
      _ => return None
    }
    if !path.is_empty() {
      result.push({ path, })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn parse_contract_components(
  obj : Map[String, Json],
) -> Array[ContractComponent]? {
  let result : Array[ContractComponent] = []
  let entries = match obj.get("components") {
    Some(Array(arr)) => arr
    Some(_) => return None
    None => []
  }
  for entry in entries {
    guard entry is Object(component_obj) else { return None }
    let name = match extract_string_opt2(component_obj, "name", "component") {
      Some(s) => s
      None => return None
    }
    guard component_obj.get("props") is Some(Object(props_obj)) else {
      return None
    }
    let props = match parse_contract_props(name, props_obj) {
      Some(props) => props
      None => return None
    }
    let package_path = match
      extract_string_opt3(
        component_obj, "package", "packagePath", "package_path",
      ) {
      Some(s) => s
      None => return None
    }
    let import_alias = match
      extract_string_opt2(component_obj, "importAlias", "import_alias") {
      Some(s) => s
      None => get_dir_name(package_path)
    }
    if !name.is_empty() && !package_path.is_empty() && !props.name.is_empty() {
      result.push({ name, props, package_path, import_alias })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn parse_contract_props(
  component_name : String,
  obj : Map[String, Json],
) -> ContractProps? {
  let name = match extract_string_opt2(obj, "name", "type") {
    Some(s) => s
    None => snake_to_pascal(component_name) + "Props"
  }
  if name.is_empty() {
    return None
  }
  let fields = match parse_contract_props_fields(obj) {
    Some(fields) => fields
    None => return None
  }
  Some({ name, fields })
}

///|
fn parse_contract_props_fields(
  obj : Map[String, Json],
) -> Array[ContractPropsField]? {
  let result : Array[ContractPropsField] = []
  let fields = match obj.get("fields") {
    Some(Array(arr)) => arr
    Some(_) => return None
    None => []
  }
  for field in fields {
    guard field is Object(field_obj) else { return None }
    let name = match @json_utils.extract_string_opt(field_obj, "name") {
      Some(s) => s
      None => return None
    }
    let type_name = match
      extract_string_opt3(field_obj, "type", "typeName", "type_name") {
      Some(s) => s
      None => return None
    }
    if !name.is_empty() && !type_name.is_empty() {
      result.push({ name, type_name })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn contract_props_raw_definition(props : ContractProps) -> String {
  let buf = StringBuilder::new()
  buf.write_string("pub(all) struct \{props.name} {\n")
  for field in props.fields {
    buf.write_string("  \{field.name} : \{field.type_name}\n")
  }
  buf.write_string("}")
  buf.to_string()
}

///|
fn extract_string_opt2(
  obj : Map[String, Json],
  key1 : String,
  key2 : String,
) -> String? {
  match @json_utils.extract_string_opt(obj, key1) {
    Some(s) => Some(s)
    None => @json_utils.extract_string_opt(obj, key2)
  }
}

///|
fn extract_string_opt3(
  obj : Map[String, Json],
  key1 : String,
  key2 : String,
  key3 : String,
) -> String? {
  match extract_string_opt2(obj, key1, key2) {
    Some(s) => Some(s)
    None => @json_utils.extract_string_opt(obj, key3)
  }
}

///|
fn parse_contract_actions(obj : Map[String, Json]) -> Array[ContractAction]? {
  let result : Array[ContractAction] = []
  let entries = match obj.get("actions") {
    Some(Array(arr)) => arr
    Some(_) => return None
    None => []
  }
  for entry in entries {
    let id = match entry {
      String(s) => s
      Object(action_obj) =>
        match @json_utils.extract_string_opt(action_obj, "id") {
          Some(s) => s
          None => return None
        }
      _ => return None
    }
    if !id.is_empty() {
      result.push({ id, })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn parse_contract_client_assets(
  obj : Map[String, Json],
) -> Array[ContractClientAsset]? {
  let result : Array[ContractClientAsset] = []
  let entries = match obj.get("clientAssets") {
    Some(Array(arr)) => arr
    Some(_) => return None
    _ =>
      match obj.get("client_assets") {
        Some(Array(arr)) => arr
        Some(_) => return None
        None => []
      }
  }
  for entry in entries {
    guard entry is Object(asset_obj) else { return None }
    let component = match
      @json_utils.extract_string_opt(asset_obj, "component") {
      Some(s) => s
      None => return None
    }
    let url = match @json_utils.extract_string_opt(asset_obj, "url") {
      Some(s) => s
      None => return None
    }
    if !component.is_empty() && !url.is_empty() {
      result.push({ component, url })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn validate_contract_manifest(manifest : ContractManifest) -> Bool {
  let seen_props : Array[String] = []
  let seen_components : Array[String] = []
  let seen_assets : Array[String] = []
  let seen_routes : Array[String] = []
  let seen_actions : Array[String] = []
  for route in manifest.routes {
    if !is_valid_route_path(route.path) || seen_routes.contains(route.path) {
      return false
    }
    seen_routes.push(route.path)
  }
  for action in manifest.actions {
    if !is_valid_action_id(action.id) || seen_actions.contains(action.id) {
      return false
    }
    seen_actions.push(action.id)
  }
  for asset in manifest.client_assets {
    if !is_valid_component_identifier(asset.component) ||
      !is_safe_generated_string_literal(asset.url) ||
      seen_assets.contains(asset.component) {
      return false
    }
    seen_assets.push(asset.component)
  }
  for component in manifest.components {
    if !is_valid_component_identifier(component.name) ||
      !is_valid_moonbit_type_identifier(component.props.name) ||
      seen_components.contains(component.name) ||
      seen_props.contains(component.props.name) {
      return false
    }
    let derived_component_name = extract_component_name_from_props(
      component.props.name,
    )
    if component.name != derived_component_name {
      return false
    }
    for field in component.props.fields {
      if !is_valid_value_identifier(field.name) ||
        !is_valid_moonbit_type_expr(field.type_name) {
        return false
      }
    }
    seen_components.push(component.name)
    seen_props.push(component.props.name)
  }
  true
}

///|
fn is_safe_generated_string_literal(value : String) -> Bool {
  if value.is_empty() {
    return false
  }
  for c in value.to_array() {
    let code = c.to_int()
    if code < 32 || code == 34 || code == 92 {
      return false
    }
  }
  true
}

///|
fn is_valid_route_path(path : String) -> Bool {
  path.has_prefix("/") && is_safe_generated_string_literal(path)
}

///|
fn is_valid_action_id(id : String) -> Bool {
  if id.is_empty() {
    return false
  }
  for c in id.to_array() {
    if is_ascii_lower(c) ||
      is_ascii_digit_char(c) ||
      c == '_' ||
      c == '-' ||
      c == ':' ||
      c == '/' ||
      c == '.' {
      ()
    } else {
      return false
    }
  }
  true
}

///|
fn is_ascii_lower(c : Char) -> Bool {
  c >= 'a' && c <= 'z'
}

///|
fn is_ascii_upper(c : Char) -> Bool {
  c >= 'A' && c <= 'Z'
}

///|
fn is_ascii_digit_char(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_identifier_tail(c : Char) -> Bool {
  is_ascii_lower(c) || is_ascii_upper(c) || is_ascii_digit_char(c) || c == '_'
}

///|
fn is_valid_value_identifier(name : String) -> Bool {
  if name.is_empty() {
    return false
  }
  let chars = name.to_array()
  let first = chars[0]
  if !(is_ascii_lower(first) || first == '_') {
    return false
  }
  for c in chars {
    if !is_identifier_tail(c) {
      return false
    }
  }
  true
}

///|
fn is_valid_component_identifier(name : String) -> Bool {
  if name.is_empty() {
    return false
  }
  let chars = name.to_array()
  if !is_ascii_lower(chars[0]) {
    return false
  }
  for c in chars {
    if !is_identifier_tail(c) {
      return false
    }
  }
  true
}

///|
fn is_valid_moonbit_type_identifier(name : String) -> Bool {
  if name.is_empty() {
    return false
  }
  let chars = name.to_array()
  if !is_ascii_upper(chars[0]) {
    return false
  }
  for c in chars {
    if !is_identifier_tail(c) {
      return false
    }
  }
  true
}

///|
fn is_valid_moonbit_type_expr(type_name : String) -> Bool {
  if type_name.is_blank() {
    return false
  }
  let mut bracket_depth = 0
  for c in type_name.to_array() {
    if c == '[' {
      bracket_depth += 1
    } else if c == ']' {
      bracket_depth -= 1
      if bracket_depth < 0 {
        return false
      }
    } else if is_identifier_tail(c) ||
      c == '@' ||
      c == '.' ||
      c == '?' ||
      c == ',' ||
      c == ' ' {
      ()
    } else {
      return false
    }
  }
  bracket_depth == 0
}
