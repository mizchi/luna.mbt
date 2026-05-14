// Explicit Sol contract manifest support.
//
// This lets users provide route/action/client-asset contracts as data instead
// of making `sol generate` infer everything from routes.mbt source text.

///|
priv struct ContractRoute {
  path : String
  query : Array[RouteQuerySpec]
}

///|
priv struct ContractAction {
  id : String
  request_type : String?
  response_type : String?
  request_shape : ContractDataShape?
  response_shape : ContractDataShape?
}

///|
priv struct ContractApi {
  method_name : String
  path : String
  request_type : String?
  response_type : String?
  request_shape : ContractDataShape?
  response_shape : ContractDataShape?
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
  apis : Array[ContractApi]
  client_assets : Array[ContractClientAsset]
  components : Array[ContractComponent]
  contract_shapes : Array[ContractDataShape]
}

///|
fn ContractManifest::to_route_info(self : ContractManifest) -> RouteInfo {
  let route_paths : Array[String] = []
  for route in self.routes {
    if !route_paths.contains(route.path) {
      route_paths.push(route.path)
    }
  }
  let route_queries : Array[RouteQueryContract] = []
  for route in self.routes {
    if !route.query.is_empty() {
      route_queries.push({ path: route.path, query: route.query })
    }
  }
  let action_ids : Array[String] = []
  let action_contracts : Array[ActionTypeContract] = []
  for action in self.actions {
    if !action_ids.contains(action.id) {
      action_ids.push(action.id)
    }
    action_contracts.push({
      id: action.id,
      request_type: action.request_type,
      response_type: action.response_type,
    })
  }
  let api_contracts : Array[ApiTypeContract] = []
  for api in self.apis {
    api_contracts.push({
      method_name: api.method_name,
      path: api.path,
      request_type: api.request_type,
      response_type: api.response_type,
    })
  }
  {
    _page_components: [],
    _api_handlers: [],
    route_paths,
    route_queries,
    action_ids,
    action_contracts,
    api_contracts,
    contract_shapes: self.contract_shapes,
  }
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
    {
      routes: [],
      actions: [],
      apis: [],
      client_assets: assets,
      components: [],
      contract_shapes: [],
    } : ContractManifest).client_asset_url(component)
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
  let apis = match parse_contract_apis(obj) {
    Some(apis) => apis
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
  let contract_shapes = collect_contract_shapes(actions, apis)
  let manifest = {
    routes,
    actions,
    apis,
    client_assets,
    components,
    contract_shapes,
  }
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
    let (path, query) = match entry {
      String(s) => (s, [])
      Object(route_obj) => {
        let path = match @json_utils.extract_string_opt(route_obj, "path") {
          Some(s) => s
          None => return None
        }
        let query = match parse_contract_query_specs(route_obj) {
          Some(query) => query
          None => return None
        }
        (path, query)
      }
      _ => return None
    }
    if !path.is_empty() {
      result.push({ path, query })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn parse_contract_query_specs(
  obj : Map[String, Json],
) -> Array[RouteQuerySpec]? {
  let result : Array[RouteQuerySpec] = []
  let entries = match obj.get("query") {
    Some(Array(arr)) => arr
    Some(_) => return None
    None => []
  }
  for entry in entries {
    let (name, optional) = match entry {
      String(s) => (s, false)
      Object(query_obj) => {
        let name = match @json_utils.extract_string_opt(query_obj, "name") {
          Some(s) => s
          None => return None
        }
        let optional = @json_utils.extract_bool(query_obj, "optional", false)
        (name, optional)
      }
      _ => return None
    }
    if !name.is_empty() {
      result.push({ name, optional })
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
fn contract_data_shape_raw_definition(shape : ContractDataShape) -> String {
  let buf = StringBuilder::new()
  buf.write_string("pub(all) struct \{shape.name} {\n")
  for field in shape.fields {
    buf.write_string("  \{field.name} : \{field.type_name}\n")
  }
  buf.write_string("}")
  buf.to_string()
}

///|
fn parse_contract_data_shape(obj : Map[String, Json]) -> ContractDataShape? {
  let name = match extract_string_opt2(obj, "name", "type") {
    Some(s) => s
    None => return None
  }
  let fields = match parse_contract_props_fields(obj) {
    Some(fields) => fields
    None => return None
  }
  if name.is_empty() {
    None
  } else {
    Some({ name, fields })
  }
}

///|
fn parse_contract_data_shape_member(
  obj : Map[String, Json],
  key : String,
) -> Result[ContractDataShape?, Unit] {
  match obj.get(key) {
    Some(Object(shape_obj)) =>
      match parse_contract_data_shape(shape_obj) {
        Some(shape) => Ok(Some(shape))
        None => Err(())
      }
    Some(String(name)) => Ok(Some({ name, fields: [] }))
    Some(_) => Err(())
    None => Ok(None)
  }
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
    let (id, request_type, response_type, request_shape, response_shape) = match
      entry {
      String(s) => (s, None, None, None, None)
      Object(action_obj) => {
        let id = match @json_utils.extract_string_opt(action_obj, "id") {
          Some(s) => s
          None => return None
        }
        let request_shape = match
          parse_contract_data_shape_member(action_obj, "request") {
          Ok(shape) => shape
          Err(_) => return None
        }
        let response_shape = match
          parse_contract_data_shape_member(action_obj, "response") {
          Ok(shape) => shape
          Err(_) => return None
        }
        let request_type = request_shape.map(fn(shape) { shape.name })
        let response_type = response_shape.map(fn(shape) { shape.name })
        (id, request_type, response_type, request_shape, response_shape)
      }
      _ => return None
    }
    if !id.is_empty() {
      result.push({
        id,
        request_type,
        response_type,
        request_shape,
        response_shape,
      })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn parse_contract_apis(obj : Map[String, Json]) -> Array[ContractApi]? {
  let result : Array[ContractApi] = []
  let entries = match obj.get("apis") {
    Some(Array(arr)) => arr
    Some(_) => return None
    None => []
  }
  for entry in entries {
    guard entry is Object(api_obj) else { return None }
    let method_name = match @json_utils.extract_string_opt(api_obj, "method") {
      Some(s) => s
      None => return None
    }
    let path = match @json_utils.extract_string_opt(api_obj, "path") {
      Some(s) => s
      None => return None
    }
    let request_shape = match
      parse_contract_data_shape_member(api_obj, "request") {
      Ok(shape) => shape
      Err(_) => return None
    }
    let response_shape = match
      parse_contract_data_shape_member(api_obj, "response") {
      Ok(shape) => shape
      Err(_) => return None
    }
    let request_type = request_shape.map(fn(shape) { shape.name })
    let response_type = response_shape.map(fn(shape) { shape.name })
    if !method_name.is_empty() && !path.is_empty() {
      result.push({
        method_name,
        path,
        request_type,
        response_type,
        request_shape,
        response_shape,
      })
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn collect_contract_shapes(
  actions : Array[ContractAction],
  apis : Array[ContractApi],
) -> Array[ContractDataShape] {
  let shapes : Array[ContractDataShape] = []
  for action in actions {
    push_contract_shape(shapes, action.request_shape)
    push_contract_shape(shapes, action.response_shape)
  }
  for api in apis {
    push_contract_shape(shapes, api.request_shape)
    push_contract_shape(shapes, api.response_shape)
  }
  shapes
}

///|
fn push_contract_shape(
  shapes : Array[ContractDataShape],
  shape : ContractDataShape?,
) -> Unit {
  match shape {
    Some(shape) => shapes.push(shape)
    None => ()
  }
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
  let seen_apis : Array[String] = []
  let seen_shapes : Array[ContractDataShape] = []
  for route in manifest.routes {
    if !is_valid_route_path(route.path) || seen_routes.contains(route.path) {
      return false
    }
    let seen_query : Array[String] = []
    for query in route.query {
      if !is_safe_generated_string_literal(query.name) ||
        seen_query.contains(query.name) {
        return false
      }
      seen_query.push(query.name)
    }
    seen_routes.push(route.path)
  }
  for action in manifest.actions {
    if !is_valid_action_id(action.id) || seen_actions.contains(action.id) {
      return false
    }
    if !is_valid_contract_type_opt(action.request_type) ||
      !is_valid_contract_type_opt(action.response_type) {
      return false
    }
    seen_actions.push(action.id)
  }
  for api in manifest.apis {
    let key = api.method_name + " " + api.path
    if !is_valid_http_method(api.method_name) ||
      !is_valid_route_path(api.path) ||
      seen_apis.contains(key) ||
      !is_valid_contract_type_opt(api.request_type) ||
      !is_valid_contract_type_opt(api.response_type) {
      return false
    }
    seen_apis.push(key)
  }
  for shape in manifest.contract_shapes {
    if !is_valid_contract_shape(shape) {
      return false
    }
    match find_contract_shape(seen_shapes, shape.name) {
      Some(existing) =>
        if !contract_shape_equals(existing, shape) {
          return false
        }
      None => seen_shapes.push(shape)
    }
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
fn is_valid_contract_type_opt(type_name : String?) -> Bool {
  match type_name {
    Some(name) => is_valid_moonbit_type_identifier(name)
    None => true
  }
}

///|
fn is_valid_http_method(method_name : String) -> Bool {
  match method_name {
    "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "ANY" => true
    _ => false
  }
}

///|
fn is_valid_contract_shape(shape : ContractDataShape) -> Bool {
  if !is_valid_moonbit_type_identifier(shape.name) {
    return false
  }
  let seen_fields : Array[String] = []
  for field in shape.fields {
    if !is_valid_value_identifier(field.name) ||
      !is_valid_moonbit_type_expr(field.type_name) ||
      seen_fields.contains(field.name) {
      return false
    }
    seen_fields.push(field.name)
  }
  true
}

///|
fn find_contract_shape(
  shapes : Array[ContractDataShape],
  name : String,
) -> ContractDataShape? {
  for shape in shapes {
    if shape.name == name {
      return Some(shape)
    }
  }
  None
}

///|
fn contract_shape_equals(a : ContractDataShape, b : ContractDataShape) -> Bool {
  if a.name != b.name || a.fields.length() != b.fields.length() {
    return false
  }
  for i in 0..<a.fields.length() {
    if a.fields[i].name != b.fields[i].name ||
      a.fields[i].type_name != b.fields[i].type_name {
      return false
    }
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
