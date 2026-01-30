// Island Collector - Collect island exports and Props types

// =============================================================================
// Export Types
// =============================================================================

///|
/// Exported function with signature
pub(all) struct FuncExport {
  name : String
  signature : String
  package_path : String
  import_alias : String
  source_pattern : String // The island pattern from config (e.g., "app/client")
}

///|
/// Exported struct definition (Props types)
pub(all) struct StructExport {
  name : String
  raw_definition : String
  package_path : String
  import_alias : String
}

// =============================================================================
// Island Name Utilities
// =============================================================================

///|
/// Extract clean island name from export name
/// Removes "island_client_" or "island_" prefix
pub fn extract_island_name(name : String) -> String {
  if name.has_prefix("island_client_") {
    name.substring(start=14)
  } else if name.has_prefix("island_") {
    name.substring(start=7)
  } else {
    name
  }
}

///|
/// Generate import alias from package path
pub fn generate_import_alias(
  package_path : String,
  category : String,
) -> String {
  // e.g., "myproject/islands/counter" -> "island_counter"
  // e.g., "myproject/pages/home" -> "page_home"
  // e.g., "myproject/components" -> "components"
  let parts = package_path.split("/").to_array()
  if parts.length() == 0 {
    return "unknown"
  }
  let last = parts[parts.length() - 1].to_string()
  match category {
    "island" => "island_\{last}"
    "page" => "page_\{last}"
    _ => last
  }
}

///|
/// Generate export name
pub fn generate_export_name(
  fn_name : String,
  import_alias : String,
  category : String,
) -> String {
  match category {
    "island" =>
      // hydrate -> hydrate_counter
      if fn_name == "hydrate" {
        import_alias // island_counter
      } else {
        "\{import_alias}_\{fn_name}"
      }
    "page" =>
      // page -> page_home
      if fn_name == "page" {
        import_alias // page_home
      } else {
        "\{import_alias}_\{fn_name}"
      }
    _ => fn_name
  }
}

// =============================================================================
// Function Collection
// =============================================================================

///|
/// Collect all pub functions from island directories
fn collect_island_functions(
  cwd : String,
  config : SolConfig,
) -> Array[FuncExport] {
  let exports : Array[FuncExport] = []
  let island_files = find_mbti_files(cwd, config.islands)
  for tuple in island_files {
    let (source_pattern, _dir_path, content) = tuple
    guard extract_package_path(content) is Some(pkg_path) else { continue }
    // Use last part of package path as alias
    let parts = pkg_path.split("/").to_array()
    let import_alias = if parts.length() > 0 {
      parts[parts.length() - 1].to_string()
    } else {
      "unknown"
    }
    let funcs = parse_mbti(content)
    for func in funcs {
      let (name, sig) = func
      exports.push(FuncExport::{
        name,
        signature: sig,
        package_path: pkg_path,
        import_alias,
        source_pattern,
      })
    }
  }
  exports
}

// =============================================================================
// Struct Collection
// =============================================================================

///|
/// Collect Props struct definitions from island source files (.mbt)
/// This parses source directly, not mbti, to avoid circular dependency
fn collect_island_structs_from_source(
  cwd : String,
  config : SolConfig,
) -> Array[StructExport] {
  let fs = @fs_adapter.NodeFsAdapter::new()
  collect_island_structs_from_source_with_fs(fs, cwd, config)
}

///|
fn[FS : @env.FileSystem] collect_island_structs_from_source_with_fs(
  fs : FS,
  cwd : String,
  config : SolConfig,
) -> Array[StructExport] {
  let exports : Array[StructExport] = []
  for pattern in config.islands {
    let base_path = @path.join2(cwd, pattern)
    // List all .mbt files in the directory
    if fs.exists_sync(base_path) {
      try {
        let entries = fs.readdir_sync(base_path)
        for entry in entries {
          if entry.has_suffix(".mbt") && not(entry.has_suffix("_test.mbt")) {
            let file_path = @path.join2(base_path, entry)
            let content = fs.read_file_sync(file_path)
            // Parse struct definitions from source
            let structs = @parser.parse_struct_defs(content, entry)
            let props_structs = @parser.get_props_structs(structs)
            // Get package info from moon.pkg
            let pkg_path = @path.join2(base_path, "moon.pkg")
            let import_alias = get_dir_name(base_path)
            for s in props_structs {
              exports.push(StructExport::{
                name: s.name,
                raw_definition: s.raw_definition,
                package_path: pattern, // Will be resolved later
                import_alias,
              })
            }
            let _ = pkg_path
          }
        }
      } catch {
        _ => ()
      }
    }
  }
  exports
}

///|
/// Extract component name from Props type name
/// e.g., "CounterProps" -> "counter", "MyWidgetProps" -> "my_widget"
pub fn extract_component_name_from_props(props_name : String) -> String {
  // Remove "Props" suffix
  let name = if props_name.has_suffix("Props") {
    props_name.substring(end=props_name.length() - 5)
  } else {
    props_name
  }
  // Convert PascalCase to snake_case
  let buf = StringBuilder::new()
  let chars = name.to_array()
  for i, c in chars {
    if c >= 'A' && c <= 'Z' {
      if i > 0 {
        buf.write_char('_')
      }
      // Convert to lowercase
      buf.write_char(Char::from_int(c.to_int() + 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Check if component is a Web Component (Wc prefix in Props name or wc_ prefix in component name)
pub fn is_web_component(component_name : String) -> Bool {
  component_name.has_prefix("wc_")
}

///|
/// Read exports from moon.pkg or moon.pkg.json (for user-managed exports mode)
/// Tries moon.pkg.json first (legacy JSON format), then falls back to moon.pkg
/// Note: Currently only JSON format is parsed; new moon.pkg format requires TOML-like parser
fn read_exports_from_pkg(island_dir : String) -> Array[String] {
  let fs = @fs_adapter.NodeFsAdapter::new()
  read_exports_from_pkg_with_fs(fs, island_dir)
}

///|
fn[FS : @env.FileSystem] read_exports_from_pkg_with_fs(
  fs : FS,
  island_dir : String,
) -> Array[String] {
  // Try moon.pkg.json first (legacy JSON format)
  let pkg_json_path = @path.join2(island_dir, "moon.pkg.json")
  let content : String = fs.read_file_sync(pkg_json_path) catch {
    // If moon.pkg.json doesn't exist, try moon.pkg (new format)
    // Note: For now, we only parse JSON format
    _ => return []
  }
  let json = @json.parse(content.view()) catch { _ => return [] }
  guard json is Object(obj) else { return [] }
  match obj.get("link") {
    Some(Object(link)) =>
      match link.get("js") {
        Some(Object(js)) =>
          match js.get("exports") {
            Some(Array(exports)) => {
              let result : Array[String] = []
              for e in exports {
                guard e is String(s) else { continue }
                result.push(s)
              }
              result
            }
            _ => []
          }
        _ => []
      }
    _ => []
  }
}

///|
/// Generate FuncExport from export name (for user-managed exports mode)
/// Derives Props type from function name using convention:
/// counter -> CounterProps, contact_form -> ContactFormProps
fn func_export_from_name(name : String, source_pattern : String) -> FuncExport {
  // Convert snake_case to PascalCase for Props type
  let props_type = snake_to_pascal(name) + "Props"
  FuncExport::{
    name,
    signature: "(\{props_type}) -> DomNode", // Assumed signature
    package_path: source_pattern,
    import_alias: get_dir_name(source_pattern),
    source_pattern,
  }
}
