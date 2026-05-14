///| TypeScript interface to Sol contract manifest converter.

///|
priv enum ContractTsError {
  ParseFailed(String)
  InterfaceNotFound(String)
  UnsupportedInterface(String, String)
  UnsupportedFieldName(String, String)
  DuplicateField(String, String)
  UnsupportedFieldType(String, String, String)
  InvalidComponentSpec(String)
  InvalidContractManifest
}

///|
priv struct TsComponentSpec {
  props_interface : String
  package_path : String
  import_alias : String?
  client_url : String?
}

///|
fn contract_manifest_from_ts_source(
  source : String,
  specs : Array[TsComponentSpec],
) -> Result[ContractManifest, ContractTsError] {
  let module_ = @ts_parser.Parser::from_source(source).parse_module() catch {
    e => return Err(ParseFailed("\{e}"))
  }
  let client_assets : Array[ContractClientAsset] = []
  let components : Array[ContractComponent] = []
  for spec in specs {
    let component = match contract_component_from_ts_interface(module_, spec) {
      Ok(component) => component
      Err(error) => return Err(error)
    }
    match spec.client_url {
      Some(url) => client_assets.push({ component: component.name, url })
      None => ()
    }
    components.push(component)
  }
  let manifest = { routes: [], actions: [], client_assets, components }
  if validate_contract_manifest(manifest) {
    Ok(manifest)
  } else {
    Err(InvalidContractManifest)
  }
}

///|
fn[FS : @env.FileSystem] load_contract_ts_manifest_with_fs(
  fs : FS,
  cwd : String,
  entries : Array[ContractTsConfig],
) -> Result[ContractManifest, String] {
  let client_assets : Array[ContractClientAsset] = []
  let components : Array[ContractComponent] = []
  for entry in entries {
    let input_path = resolve_contract_ts_input_path(cwd, entry.input)
    let source = fs.read_file_sync(input_path) catch {
      e => return Err("failed to read \{entry.input}: \{e}")
    }
    let manifest = match
      contract_manifest_from_ts_source(source, [
        {
          props_interface: entry.props_interface,
          package_path: entry.package_path,
          import_alias: entry.import_alias,
          client_url: entry.client_url,
        },
      ]) {
      Ok(manifest) => manifest
      Err(error) =>
        return Err(
          "failed to convert \{entry.input} \{entry.props_interface}: \{contract_ts_error_to_string(error)}",
        )
    }
    for asset in manifest.client_assets {
      client_assets.push(asset)
    }
    for component in manifest.components {
      components.push(component)
    }
  }
  let manifest = { routes: [], actions: [], client_assets, components }
  if validate_contract_manifest(manifest) {
    Ok(manifest)
  } else {
    Err("generated TypeScript contract manifest failed Sol validation")
  }
}

///|
fn resolve_contract_ts_input_path(cwd : String, input : String) -> String {
  if @path.isAbsolute(input) {
    input
  } else {
    @path.join2(cwd, input)
  }
}

///|
fn contract_manifest_json_from_ts_source(
  source : String,
  specs : Array[TsComponentSpec],
) -> Result[String, ContractTsError] {
  match contract_manifest_from_ts_source(source, specs) {
    Ok(manifest) => Ok(manifest.to_json().stringify())
    Err(error) => Err(error)
  }
}

///|
fn ContractManifest::to_json(self : ContractManifest) -> Json {
  let routes : Array[Json] = []
  for route in self.routes {
    routes.push({ "path": route.path.to_json() }.to_json())
  }
  let actions : Array[Json] = []
  for action in self.actions {
    actions.push(action.id.to_json())
  }
  let client_assets : Array[Json] = []
  for asset in self.client_assets {
    client_assets.push(asset.to_json())
  }
  let components : Array[Json] = []
  for component in self.components {
    components.push(component.to_json())
  }
  {
    "routes": routes.to_json(),
    "actions": actions.to_json(),
    "clientAssets": client_assets.to_json(),
    "components": components.to_json(),
  }.to_json()
}

///|
fn ContractClientAsset::to_json(self : ContractClientAsset) -> Json {
  { "component": self.component.to_json(), "url": self.url.to_json() }.to_json()
}

///|
fn ContractComponent::to_json(self : ContractComponent) -> Json {
  {
    "name": self.name.to_json(),
    "package": self.package_path.to_json(),
    "importAlias": self.import_alias.to_json(),
    "props": self.props.to_json(),
  }.to_json()
}

///|
fn ContractProps::to_json(self : ContractProps) -> Json {
  let fields : Array[Json] = []
  for field in self.fields {
    fields.push(field.to_json())
  }
  { "name": self.name.to_json(), "fields": fields.to_json() }.to_json()
}

///|
fn ContractPropsField::to_json(self : ContractPropsField) -> Json {
  { "name": self.name.to_json(), "type": self.type_name.to_json() }.to_json()
}

///|
fn contract_component_from_ts_interface(
  module_ : @ts_ast.TsModule,
  spec : TsComponentSpec,
) -> Result[ContractComponent, ContractTsError] {
  if spec.props_interface.is_empty() {
    return Err(InvalidComponentSpec("props_interface is empty"))
  }
  if spec.package_path.is_empty() {
    return Err(InvalidComponentSpec("package_path is empty"))
  }
  if !is_valid_moonbit_type_identifier(spec.props_interface) {
    return Err(
      UnsupportedInterface(
        spec.props_interface,
        "props interface must be a MoonBit type identifier",
      ),
    )
  }
  let iface = match find_ts_interface(module_, spec.props_interface) {
    Some(iface) => iface
    None => return Err(InterfaceNotFound(spec.props_interface))
  }
  let props = match contract_props_from_ts_interface(iface) {
    Ok(props) => props
    Err(error) => return Err(error)
  }
  let name = extract_component_name_from_props(spec.props_interface)
  if !is_valid_component_identifier(name) {
    return Err(
      UnsupportedInterface(
        spec.props_interface,
        "derived component name is not a Sol component identifier",
      ),
    )
  }
  let import_alias = match spec.import_alias {
    Some(import_name) => import_name
    None => get_dir_name(spec.package_path)
  }
  Ok({ name, props, package_path: spec.package_path, import_alias })
}

///|
fn find_ts_interface(
  module_ : @ts_ast.TsModule,
  name : String,
) -> @ts_ast.TsInterface? {
  for iface in module_.interfaces {
    if iface.name == name {
      return Some(iface)
    }
  }
  None
}

///|
fn contract_props_from_ts_interface(
  iface : @ts_ast.TsInterface,
) -> Result[ContractProps, ContractTsError] {
  if iface.type_params.length() > 0 {
    return Err(UnsupportedInterface(iface.name, "generic interfaces"))
  }
  if iface.extends_names.length() > 0 {
    return Err(UnsupportedInterface(iface.name, "extends clauses"))
  }
  if iface.index_signatures.length() > 0 {
    return Err(UnsupportedInterface(iface.name, "index signatures"))
  }
  let fields : Array[ContractPropsField] = []
  let seen : Array[String] = []
  for item in iface.fields {
    let (field_name, type_) = item
    if !is_valid_value_identifier(field_name) {
      return Err(UnsupportedFieldName(iface.name, field_name))
    }
    if seen.contains(field_name) {
      return Err(DuplicateField(iface.name, field_name))
    }
    let type_name = match ts_type_to_moonbit_contract_type(type_) {
      Ok(type_name) => type_name
      Err(type_repr) =>
        return Err(UnsupportedFieldType(iface.name, field_name, type_repr))
    }
    seen.push(field_name)
    fields.push({ name: field_name, type_name })
  }
  Ok({ name: iface.name, fields })
}

///|
fn ts_type_to_moonbit_contract_type(
  type_ : @ts_ast.TsType,
) -> Result[String, String] {
  match @ts_checker.classify_optional_like_union(type_) {
    Some((inner, true)) =>
      return match ts_type_to_moonbit_contract_type(inner) {
        Ok(name) => Ok(name + "?")
        Err(type_repr) => Err(type_repr)
      }
    Some((inner, false)) => return ts_type_to_moonbit_contract_type(inner)
    None => ()
  }
  match type_ {
    @ts_ast.TsType::Number => Ok("Double")
    @ts_ast.TsType::Int => Ok("Int")
    @ts_ast.TsType::Boolean => Ok("Bool")
    @ts_ast.TsType::String_ => Ok("String")
    @ts_ast.TsType::Literal(_) => Ok("String")
    @ts_ast.TsType::NumberLiteral(_) => Ok("Double")
    @ts_ast.TsType::BooleanLiteral(_) => Ok("Bool")
    @ts_ast.TsType::Array(inner) =>
      match ts_type_to_moonbit_contract_type(inner) {
        Ok(inner_name) => Ok("Array[\{inner_name}]")
        Err(type_repr) => Err(type_repr)
      }
    @ts_ast.TsType::Applied("Array", [inner]) =>
      match ts_type_to_moonbit_contract_type(inner) {
        Ok(inner_name) => Ok("Array[\{inner_name}]")
        Err(type_repr) => Err(type_repr)
      }
    @ts_ast.TsType::Applied("ReadonlyArray", [inner]) =>
      match ts_type_to_moonbit_contract_type(inner) {
        Ok(inner_name) => Ok("Array[\{inner_name}]")
        Err(type_repr) => Err(type_repr)
      }
    _ => Err("\{type_}")
  }
}

///|
fn run_contract_ts_command(args : Array[String]) -> Unit {
  if args.length() == 0 ||
    has_contract_ts_flag(args, "--help") ||
    has_contract_ts_flag(args, "-h") {
    print_contract_ts_usage()
    return
  }
  let input = match read_contract_ts_flag(args, "--input") {
    Some(value) => value
    None => return contract_ts_fail("missing --input <file>")
  }
  let props = match read_contract_ts_flag(args, "--props") {
    Some(value) => value
    None => return contract_ts_fail("missing --props <InterfaceName>")
  }
  let package_path = match read_contract_ts_flag(args, "--package") {
    Some(value) => value
    None => return contract_ts_fail("missing --package <moonbit-package>")
  }
  let source = @fs.read_file_as_string(input, encoding="utf8") catch {
    e => return contract_ts_fail("failed to read \{input}: \{e}")
  }
  let result = contract_manifest_json_from_ts_source(source, [
    {
      props_interface: props,
      package_path,
      import_alias: read_contract_ts_flag(args, "--import-alias"),
      client_url: read_contract_ts_flag(args, "--client-url"),
    },
  ])
  match result {
    Ok(json) => println(json)
    Err(error) =>
      contract_ts_fail(
        "failed to convert \{props}: \{contract_ts_error_to_string(error)}",
      )
  }
}

///|
fn print_contract_ts_usage() -> Unit {
  println(
    "Usage: sol contract-ts --input <file> --props <InterfaceName> --package <moonbit-package> [--import-alias <alias>] [--client-url <url>]",
  )
}

///|
fn contract_ts_fail(message : String) -> Unit {
  @cli_common.console_error(@colorette.red("Error: \{message}"))
  @process.exit(1)
}

///|
fn has_contract_ts_flag(args : Array[String], flag : String) -> Bool {
  for arg in args {
    if arg == flag {
      return true
    }
  }
  false
}

///|
fn read_contract_ts_flag(args : Array[String], flag : String) -> String? {
  let prefix = flag + "="
  let mut idx = 0
  while idx < args.length() {
    let arg = args[idx]
    if arg == flag {
      if idx + 1 >= args.length() {
        return None
      }
      return Some(args[idx + 1])
    }
    if arg.has_prefix(prefix) {
      return Some(arg[prefix.length():].to_owned())
    }
    idx += 1
  }
  None
}

///|
fn contract_ts_error_to_string(error : ContractTsError) -> String {
  match error {
    ParseFailed(message) => "parse failed: \{message}"
    InterfaceNotFound(name) => "interface not found: \{name}"
    UnsupportedInterface(name, reason) =>
      "unsupported interface \{name}: \{reason}"
    UnsupportedFieldName(interface_name, field_name) =>
      "unsupported field name \{interface_name}.\{field_name}"
    DuplicateField(interface_name, field_name) =>
      "duplicate field \{interface_name}.\{field_name}"
    UnsupportedFieldType(interface_name, field_name, type_repr) =>
      "unsupported field type \{interface_name}.\{field_name}: \{type_repr}"
    InvalidComponentSpec(message) => "invalid component spec: \{message}"
    InvalidContractManifest => "generated manifest failed Sol validation"
  }
}
