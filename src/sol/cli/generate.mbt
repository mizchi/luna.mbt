///| sol generate command - Generate __gen__ and .sol directories from sol.config.json

///|
fn show_generate_help() -> Unit {
  let help =
    #|Usage: sol generate [options]
    #|
    #|Generate app/__gen__ (MoonBit) and .sol (JS) directories from sol.config.json
    #|
    #|Options:
    #|  -c, --config <path>  Config file path (default: sol.config.json)
    #|  -h, --help           Show help
  println(help)
}

// =============================================================================
// Config Types
// =============================================================================

///|
/// Sol configuration (new architecture)
pub struct SolConfig {
  /// Island directories (client hydration)
  islands : Array[String]
  /// Routes directory (contains routes.mbt)
  routes : String
  /// Output directory for generated MoonBit files
  output : String
}

///|
/// Parsed export entry from mbti
struct ExportEntry {
  /// Export name (function name)
  name : String
  /// Original function name in source module
  source_name : String
  /// Package path (e.g., "myproject/components")
  package_path : String
  /// Import alias (e.g., "components")
  import_alias : String
}

// =============================================================================
// Config Parser
// =============================================================================

///|
/// Parse sol.config.json
pub fn parse_sol_config(json_str : String) -> SolConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    let islands = parse_string_array(obj, "islands")
    let routes = match obj.get("routes") {
      Some(String(s)) => s
      _ => "app/routes"
    }
    let output = match obj.get("output") {
      Some(String(s)) => s
      _ => "app/__gen__"
    }
    Some(SolConfig::{ islands, routes, output })
  } catch {
    _ => None
  }
}

///|
/// Parse string array from JSON object
fn parse_string_array(obj : Map[String, Json], key : String) -> Array[String] {
  match obj.get(key) {
    Some(Array(arr)) => {
      let result : Array[String] = []
      for item in arr {
        guard item is String(s) else { continue }
        result.push(s)
      }
      result
    }
    _ => []
  }
}

///|
/// Get project name from moon.mod.json
fn get_project_name(cwd : String) -> String {
  let mod_path = @path.join2(cwd, "moon.mod.json")
  if not(@fs.existsSync(mod_path)) {
    return "unknown"
  }
  try {
    let content = @fs.readFileSync(mod_path).to_string()
    let json = @json.parse(content.view())
    guard json is Object(obj) else { return "unknown" }
    match obj.get("name") {
      Some(String(name)) => name
      _ => "unknown"
    }
  } catch {
    _ => "unknown"
  }
}

// =============================================================================
// MBTI Parser
// =============================================================================

///|
/// Parse mbti imports to build alias mapping
pub fn parse_mbti_imports(content : String) -> Map[String, String] {
  // Returns: Map[alias -> package_path]
  let result : Map[String, String] = {}
  let lines = content.split("\n").to_array()
  let mut in_import = false
  for line in lines {
    let line_str = line.to_string()
    let trimmed = line_str.trim_space().to_string()
    if trimmed == "import(" {
      in_import = true
      continue
    }
    if in_import {
      if trimmed == ")" {
        in_import = false
        continue
      }
      // Parse: "package/path" or "package/path" as alias
      if trimmed.has_prefix("\"") {
        // Find second quote
        let after_first = trimmed.unsafe_substring(
          start=1,
          end=trimmed.length(),
        )
        match after_first.find("\"") {
          Some(end_quote) => {
            let pkg_path = after_first.unsafe_substring(start=0, end=end_quote)
            // Extract alias (last part of path)
            let parts = pkg_path.split("/").to_array()
            if parts.length() > 0 {
              let alias_part = parts[parts.length() - 1].to_string()
              result[alias_part] = pkg_path
            }
          }
          None => ()
        }
      }
    }
  }
  result
}

///|
/// Rewrite type references from mbti format to exports format
pub fn rewrite_type_refs(
  sig : String,
  _imports : Map[String, String],
) -> String {
  // mbti uses @alias.Type where alias is the last part of package path
  // We need to map to the correct alias in exports module
  // Use known type patterns for robust mapping
  let mut result = sig
  // Luna types - always rewrite @core.Node/Attr/VNode to @luna
  result = result.replace_all(old="@core.Node", new="@luna.Node")
  result = result.replace_all(old="@core.Attr", new="@luna.Attr")
  result = result.replace_all(old="@core.VNode", new="@luna.VNode")
  // JS types - always rewrite @core.Any to @js
  result = result.replace_all(old="@core.Any", new="@js.Any")
  result
}

///|
/// Parse mbti file and extract pub fn declarations
pub fn parse_mbti(content : String) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  let imports = parse_mbti_imports(content)
  let lines = content.split("\n").to_array()
  for line in lines {
    let line_str = line.to_string()
    let trimmed = line_str.trim_start(" \t").to_string()
    // Look for "pub fn name(...) -> RetType"
    if trimmed.has_prefix("pub fn ") {
      let rest = trimmed.unsafe_substring(start=7, end=trimmed.length()) // After "pub fn "
      // Find function name (up to first '(')
      match rest.find("(") {
        Some(paren_idx) => {
          let name = rest.unsafe_substring(start=0, end=paren_idx)
          // Get signature (from '(' to end of line)
          let sig = rest.unsafe_substring(start=paren_idx, end=rest.length())
          // Rewrite type references
          let rewritten_sig = rewrite_type_refs(sig, imports)
          result.push((name, rewritten_sig))
        }
        None => ()
      }
    }
  }
  result
}

///|
/// Find mbti files in directories matching glob patterns
fn find_mbti_files(
  cwd : String,
  patterns : Array[String],
) -> Array[(String, String)] {
  // Returns: Array of (dir_path, mbti_content)
  let result : Array[(String, String)] = []
  for pattern in patterns {
    let base_path = @path.join2(cwd, pattern)
    // Check if pattern ends with /* (directory glob)
    if pattern.has_suffix("/*") {
      // List subdirectories
      let parent = base_path.substring(end=base_path.length() - 2)
      if @fs.existsSync(parent) {
        try {
          let entries = @fs.readdirSync(parent)
          for entry in entries {
            let entry_path = @path.join2(parent, entry)
            let mbti_path = @path.join2(entry_path, "pkg.generated.mbti")
            if @fs.existsSync(mbti_path) {
              let content = @fs.readFileSync(mbti_path).to_string()
              result.push((entry_path, content))
            }
          }
        } catch {
          _ => ()
        }
      }
    } else {
      // Direct directory
      let mbti_path = @path.join2(base_path, "pkg.generated.mbti")
      if @fs.existsSync(mbti_path) {
        try {
          let content = @fs.readFileSync(mbti_path).to_string()
          result.push((base_path, content))
        } catch {
          _ => ()
        }
      }
    }
  }
  result
}

///|
/// Extract package path from mbti content
pub fn extract_package_path(mbti_content : String) -> String? {
  let lines = mbti_content.split("\n").to_array()
  for line in lines {
    let line_str = line.to_string()
    let trimmed = line_str.trim_start(" \t").to_string()
    if trimmed.has_prefix("package \"") {
      let start = 9 // len of 'package "'
      let after_prefix = trimmed.unsafe_substring(start~, end=trimmed.length())
      match after_prefix.find("\"") {
        Some(end_quote) =>
          return Some(trimmed.unsafe_substring(start~, end=end_quote + start))
        None => ()
      }
    }
  }
  None
}

// =============================================================================
// Code Generators
// =============================================================================

///| Extract clean island name from export name

///|
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

///|
/// Exported function with signature
pub(all) struct FuncExport {
  name : String
  signature : String
  package_path : String
  import_alias : String
}

///|
/// Exported struct definition (Props types)
pub(all) struct StructExport {
  name : String
  raw_definition : String
  package_path : String
  import_alias : String
}

///|
/// Collect all pub functions from island directories
fn collect_island_functions(
  cwd : String,
  config : SolConfig,
) -> Array[FuncExport] {
  let exports : Array[FuncExport] = []
  let island_files = find_mbti_files(cwd, config.islands)
  for pair in island_files {
    let (dir_path, content) = pair
    let _ = dir_path
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
      })
    }
  }
  exports
}

///|
/// Collect Props struct definitions from island source files (.mbt)
/// This parses source directly, not mbti, to avoid circular dependency
fn collect_island_structs_from_source(
  cwd : String,
  config : SolConfig,
) -> Array[StructExport] {
  let exports : Array[StructExport] = []
  for pattern in config.islands {
    let base_path = @path.join2(cwd, pattern)
    // List all .mbt files in the directory
    if @fs.existsSync(base_path) {
      try {
        let entries = @fs.readdirSync(base_path)
        for entry in entries {
          if entry.has_suffix(".mbt") && not(entry.has_suffix("_test.mbt")) {
            let file_path = @path.join2(base_path, entry)
            let content = @fs.readFileSync(file_path).to_string()
            // Parse struct definitions from source
            let structs = @mbti_utils.parse_struct_defs(content, entry)
            let props_structs = @mbti_utils.get_props_structs(structs)
            // Get package info from moon.pkg.json
            let pkg_json_path = @path.join2(base_path, "moon.pkg.json")
            let import_alias = get_dir_name(base_path)
            for s in props_structs {
              exports.push(StructExport::{
                name: s.name,
                raw_definition: s.raw_definition,
                package_path: pattern, // Will be resolved later
                import_alias,
              })
            }
            let _ = pkg_json_path

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
/// Get directory name from path
fn get_dir_name(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() > 0 {
    parts[parts.length() - 1].to_string()
  } else {
    "unknown"
  }
}

///|
/// Collect Props struct definitions from island directories (from mbti)
fn collect_island_structs(
  cwd : String,
  config : SolConfig,
) -> Array[StructExport] {
  let exports : Array[StructExport] = []
  let island_files = find_mbti_files(cwd, config.islands)
  for pair in island_files {
    let (dir_path, content) = pair
    let _ = dir_path
    guard extract_package_path(content) is Some(pkg_path) else { continue }
    // Use last part of package path as alias
    let parts = pkg_path.split("/").to_array()
    let import_alias = if parts.length() > 0 {
      parts[parts.length() - 1].to_string()
    } else {
      "unknown"
    }
    // Parse struct definitions using mbti_utils (simple string parsing)
    let structs = @mbti_utils.parse_struct_defs(content, "pkg.generated.mbti")
    let props_structs = @mbti_utils.get_props_structs(structs)
    for s in props_structs {
      exports.push(StructExport::{
        name: s.name,
        raw_definition: s.raw_definition,
        package_path: pkg_path,
        import_alias,
      })
    }
  }
  exports
}

///|
/// Generate types.mbt content with all Props struct definitions
fn generate_types_mbt(structs : Array[StructExport]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated types for island props\n")
  buf.write_string("///| Re-exports Props structs from client packages\n\n")
  for s in structs {
    buf.write_string("///| Props type from @\{s.import_alias}\n")
    // Check if raw_definition already has derive
    if s.raw_definition.contains("derive(") {
      buf.write_string(s.raw_definition)
      buf.write_string("\n\n")
    } else {
      buf.write_string(s.raw_definition)
      buf.write_string(" derive(ToJson, FromJson)\n\n")
    }
  }
  buf.to_string()
}

///|
/// Generate types/moon.pkg.json
fn generate_types_pkg_json(
  structs : Array[StructExport],
  project_name : String,
) -> String {
  let _ = project_name
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"supported-targets\": [\"js\"],\n")
  // No imports needed - @json is part of standard library
  buf.write_string("  \"link\": {\n")
  buf.write_string("    \"js\": {\n")
  // Export all struct names
  let struct_names : Array[String] = structs.map(fn(s) { s.name })
  let exports_str = struct_names.map(fn(n) { "\"\{n}\"" }).join(", ")
  buf.write_string("      \"exports\": [\{exports_str}],\n")
  buf.write_string("      \"format\": \"esm\"\n")
  buf.write_string("    }\n")
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Collect island exports from config (legacy, for hydrate_* pattern)
fn collect_exports(cwd : String, config : SolConfig) -> Array[ExportEntry] {
  let entries : Array[ExportEntry] = []
  // Islands only (new architecture)
  let island_files = find_mbti_files(cwd, config.islands)
  for pair in island_files {
    let (dir_path, content) = pair
    let _ = dir_path
    guard extract_package_path(content) is Some(pkg_path) else { continue }
    let import_alias = generate_import_alias(pkg_path, "island")
    let funcs = parse_mbti(content)
    for func in funcs {
      let (name, _sig) = func
      // Only include hydrate_* functions
      if name.has_prefix("hydrate_") {
        let export_name = name // Keep original name
        entries.push(ExportEntry::{
          name: export_name,
          source_name: name,
          package_path: pkg_path,
          import_alias,
        })
      }
    }
  }
  entries
}

///|
/// Split parameters respecting nested brackets
pub fn split_params(params_str : String) -> Array[String] {
  let result : Array[String] = []
  let current = StringBuilder::new()
  let mut depth = 0
  for char in params_str {
    match char {
      '(' | '[' | '{' => {
        depth += 1
        current.write_char(char)
      }
      ')' | ']' | '}' => {
        depth -= 1
        current.write_char(char)
      }
      ',' =>
        if depth == 0 {
          let s = current.to_string().trim_space().to_string()
          if not(s.is_empty()) {
            result.push(s)
          }
          current.reset()
        } else {
          current.write_char(char)
        }
      _ => current.write_char(char)
    }
  }
  // Add last param
  let s = current.to_string().trim_space().to_string()
  if not(s.is_empty()) {
    result.push(s)
  }
  result
}

///|
/// Find matching closing paren position
pub fn find_matching_paren(s : String, start : Int) -> Int? {
  let mut depth = 0
  let chars = s.to_array()
  for i = start; i < chars.length(); i = i + 1 {
    match chars[i] {
      '(' => depth += 1
      ')' => {
        depth -= 1
        if depth == 0 {
          return Some(i)
        }
      }
      _ => ()
    }
  }
  None
}

///|
/// Generate parameter names for signature
pub fn generate_params_with_names(signature : String) -> (String, String) {
  // signature: "(Type1, Type2) -> RetType" or "() -> RetType"
  // Returns: (signature_with_names, call_args)
  // e.g., "(String, Int) -> Unit" => ("(p0 : String, p1 : Int) -> Unit", "(p0, p1)")
  match signature.find("(") {
    None => (signature, "()")
    Some(paren_start) =>
      match find_matching_paren(signature, paren_start) {
        None => (signature, "()")
        Some(paren_end) => {
          let params_str = signature.unsafe_substring(
            start=paren_start + 1,
            end=paren_end,
          )
          if params_str.trim_space().to_string().is_empty() {
            // No params: () -> RetType
            (signature, "()")
          } else {
            // Parse params and add names (respecting nested brackets)
            let params = split_params(params_str)
            let named_params = StringBuilder::new()
            let call_args = StringBuilder::new()
            named_params.write_string("(")
            call_args.write_string("(")
            for i, param_str in params {
              if i > 0 {
                named_params.write_string(", ")
                call_args.write_string(", ")
              }
              named_params.write_string("p\{i} : \{param_str}")
              call_args.write_string("p\{i}")
            }
            named_params.write_string(")")
            call_args.write_string(")")
            // Add return type
            let ret_type = signature.unsafe_substring(
              start=paren_end + 1,
              end=signature.length(),
            )
            named_params.write_string(ret_type)
            (named_params.to_string(), call_args.to_string())
          }
        }
      }
  }
}

///|
/// Check if signature uses @luna types
pub fn uses_luna_types(signature : String) -> Bool {
  signature.contains("@luna.")
}

///|
/// Check if signature uses @js types
pub fn uses_js_types(signature : String) -> Bool {
  signature.contains("@js.")
}

///|
/// Check if signature uses @signal types
pub fn uses_signal_types(signature : String) -> Bool {
  signature.contains("@signal.")
}

///|
/// Check if signature uses @hono types
pub fn uses_hono_types(signature : String) -> Bool {
  signature.contains("@hono.")
}

// =============================================================================
// New Architecture: Client/Server Generation
// =============================================================================

///|
/// Rewrite types in signature to use fully qualified names
/// All types are qualified with @import_alias
fn rewrite_signature_types(
  sig : String,
  import_alias : String,
  _props_names : Array[String],
) -> String {
  let result = sig
  // Rewrite @xxx.Type patterns - keep them as is (they reference imported packages)
  // Rewrite bare types (like CounterProps) to @import_alias.Type
  let chars = result.to_array()
  let new_buf = StringBuilder::new()
  let word_buf = StringBuilder::new()
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c >= 'A' && c <= 'Z' {
      // Start of potential type name
      word_buf.write_char(c)
      i += 1
      while i < chars.length() {
        let nc = chars[i]
        if (nc >= 'a' && nc <= 'z') ||
          (nc >= 'A' && nc <= 'Z') ||
          (nc >= '0' && nc <= '9') ||
          nc == '_' {
          word_buf.write_char(nc)
          i += 1
        } else {
          break
        }
      }
      let word = word_buf.to_string()
      word_buf.reset()
      // Check if it's a known primitive type
      let primitives = [
        "Int", "String", "Bool", "Unit", "Float", "Double", "Byte", "Char", "Array",
        "Self",
      ]
      let is_primitive = primitives.contains(word)
      // Check if this type is already qualified with @xxx. pattern
      // by checking if previous char is '.' (from @package.Type)
      let prev_str = new_buf.to_string()
      let already_qualified = prev_str.has_suffix(".")
      if is_primitive || already_qualified {
        new_buf.write_string(word)
      } else {
        // All types use import alias (client's own types)
        new_buf.write_string("@\{import_alias}.\{word}")
      }
    } else {
      new_buf.write_char(c)
      i += 1
    }
  }
  new_buf.to_string()
}

///|
/// Generate client exports.mbt for islands (new architecture - all pub fns)
fn generate_client_exports_mbt_v2(
  funcs : Array[FuncExport],
  props_names : Array[String],
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated client exports\n")
  buf.write_string("///| Re-exports all public functions from app/client/*\n\n")
  for func in funcs {
    // Use "app_" prefix to match moon.pkg.json import alias
    let prefixed_alias = "app_\{func.import_alias}"
    let rewritten_sig = rewrite_signature_types(
      func.signature,
      prefixed_alias,
      props_names,
    )
    let (sig_with_names, call_args) = generate_params_with_names(rewritten_sig)
    buf.write_string("///| Re-export \{func.name} from @\{prefixed_alias}\n")
    buf.write_string("pub fn \{func.name}\{sig_with_names} {\n")
    buf.write_string("  @\{prefixed_alias}.\{func.name}\{call_args}\n")
    buf.write_string("}\n\n")
    // Generate hydrate wrapper if function takes Props and returns DomNode
    let props_type = extract_props_type(func.signature, prefixed_alias)
    if props_type.length() > 0 && func.signature.contains("DomNode") {
      // Get the qualified props type name
      let qualified_props = "@\{prefixed_alias}.\{props_type}"
      buf.write_string(
        "///| Hydrate wrapper for \{func.name} - called by ln-loader\n",
      )
      buf.write_string(
        "pub fn hydrate_\{func.name}(element : @js.Any, state : @js.Any, _id : String) -> Unit {\n",
      )
      buf.write_string("  let jsdom_el : @js_dom.Element = element.cast()\n")
      buf.write_string("  let el = @element.DomElement::from_jsdom(jsdom_el)\n")
      buf.write_string(
        "  // state is already a JS object from JSON.parse in loader\n",
      )
      buf.write_string("  // Convert to Json then parse to Props\n")
      buf.write_string("  let json = @mbtconv.to_json(state)\n")
      buf.write_string(
        "  let props : \{qualified_props} = try { @json.from_json(json) } catch { _ => return }\n",
      )
      buf.write_string("  let node = \{func.name}(props)\n")
      buf.write_string("  @element.render(el, node)\n")
      buf.write_string("}\n\n")
    }
  }
  buf.to_string()
}

///|
/// Extract Props type from signature like "(CounterProps) -> DomNode"
fn extract_props_type(sig : String, _alias : String) -> String {
  // Look for pattern: (SomeProps) -> ...
  match sig.find("(") {
    None => ""
    Some(start) =>
      match sig.find(")") {
        None => ""
        Some(end) => {
          let inner = sig.substring(start=start + 1, end~)
          if inner.contains("Props") {
            inner.trim_space().to_string()
          } else {
            ""
          }
        }
      }
  }
}

///|
/// Generate client exports.mbt for islands (legacy)
fn generate_client_exports_mbt(islands : Array[ExportEntry]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated client exports\n")
  buf.write_string("///| Re-exports hydration functions from app/client/*\n\n")
  for entry in islands {
    buf.write_string("///| Re-export \{entry.name}\n")
    buf.write_string(
      "pub fn \{entry.name}(element : @js.Any, state : @js.Any, id : String) -> Unit {\n",
    )
    buf.write_string(
      "  @\{entry.import_alias}.\{entry.source_name}(element, state, id)\n",
    )
    buf.write_string("}\n\n")
  }
  buf.to_string()
}

///|
/// Extract package aliases used in signatures (patterns like @xxx.)
fn extract_used_packages(funcs : Array[FuncExport]) -> Array[String] {
  let used : Map[String, Bool] = {}
  for func in funcs {
    let sig = func.signature
    // Find @xxx. patterns
    let chars = sig.to_array()
    let mut i = 0
    while i < chars.length() {
      if chars[i] == '@' {
        i += 1
        let alias_buf = StringBuilder::new()
        while i < chars.length() {
          let c = chars[i]
          if (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') ||
            c == '_' {
            alias_buf.write_char(c)
            i += 1
          } else {
            break
          }
        }
        let alias_str = alias_buf.to_string()
        if not(alias_str.is_empty()) {
          used[alias_str] = true
        }
      } else {
        i += 1
      }
    }
  }
  used.keys().to_array()
}

///|
/// Map common aliases to their full package paths
fn alias_to_package_path(pkg_alias : String) -> String? {
  match pkg_alias {
    "element" => Some("mizchi/luna/platform/dom/element")
    "signal" => Some("mizchi/luna/core/signal")
    "luna" => Some("mizchi/luna/core")
    "js" => Some("mizchi/js/core")
    _ => None
  }
}

///|
/// Generate client moon.pkg.json for islands (new architecture - all pub fns)
fn generate_client_pkg_json_v2(funcs : Array[FuncExport]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"supported-targets\": [\"js\"],\n")
  buf.write_string("  \"import\": [\n")
  // Collect unique imports from function packages
  // Use "app_" prefix to avoid alias collision with __gen__/client package itself
  let seen : Map[String, Bool] = {}
  let imports : Array[(String, String)] = []
  for func in funcs {
    if not(seen.contains(func.package_path)) {
      seen[func.package_path] = true
      // Add "app_" prefix to avoid collision with __gen__/client's default alias
      let alias = "app_\{func.import_alias}"
      imports.push((func.package_path, alias))
    }
  }
  // Also add packages used in signatures
  let used_packages = extract_used_packages(funcs)
  for pkg_alias in used_packages {
    match alias_to_package_path(pkg_alias) {
      Some(pkg_path) =>
        if not(seen.contains(pkg_path)) {
          seen[pkg_path] = true
          imports.push((pkg_path, pkg_alias))
        }
      None => ()
    }
  }
  // Always add @js for hydrate wrapper
  let js_path = "mizchi/js/core"
  if not(seen.contains(js_path)) {
    seen[js_path] = true
    imports.push((js_path, "js"))
  }
  // Always add @mbtconv for JS <-> MoonBit Json conversion
  let mbtconv_path = "mizchi/js/mbtconv"
  if not(seen.contains(mbtconv_path)) {
    seen[mbtconv_path] = true
    imports.push((mbtconv_path, "mbtconv"))
  }
  // Always add @js_dom for DOM element types
  let js_dom_path = "mizchi/js/browser/dom"
  if not(seen.contains(js_dom_path)) {
    seen[js_dom_path] = true
    imports.push((js_dom_path, "js_dom"))
  }
  for i, imp in imports {
    let (pkg_path, pkg_alias) = imp
    if i > 0 {
      buf.write_string(",\n")
    }
    buf.write_string(
      "    { \"path\": \"\{pkg_path}\", \"alias\": \"\{pkg_alias}\" }",
    )
  }
  buf.write_string("\n  ],\n")
  buf.write_string("  \"link\": {\n")
  buf.write_string("    \"js\": {\n")
  buf.write_string("      \"exports\": [")
  // Collect function names and hydrate function names
  for i, func in funcs {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string("\"\{func.name}\"")
    // Add hydrate_<func_name> for functions with Props -> DomNode signature
    if func.signature.contains("Props") && func.signature.contains("DomNode") {
      buf.write_string(", \"hydrate_\{func.name}\"")
    }
  }
  buf.write_string("],\n")
  buf.write_string("      \"format\": \"esm\"\n")
  buf.write_string("    }\n")
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Generate client moon.pkg.json for islands (legacy)
fn generate_client_pkg_json(islands : Array[ExportEntry]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"supported-targets\": [\"js\"],\n")
  buf.write_string("  \"import\": [\n")
  // Collect unique imports
  let seen : Map[String, Bool] = {}
  let mut first = true
  for entry in islands {
    if not(seen.contains(entry.package_path)) {
      seen[entry.package_path] = true
      if not(first) {
        buf.write_string(",\n")
      }
      buf.write_string(
        "    { \"path\": \"\{entry.package_path}\", \"alias\": \"\{entry.import_alias}\" }",
      )
      first = false
    }
  }
  buf.write_string(",\n")
  buf.write_string("    { \"path\": \"mizchi/js/core\", \"alias\": \"js\" }\n")
  buf.write_string("  ],\n")
  buf.write_string("  \"link\": {\n")
  buf.write_string("    \"js\": {\n")
  buf.write_string("      \"exports\": [")
  for i, entry in islands {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string("\"\{entry.name}\"")
  }
  buf.write_string("],\n")
  buf.write_string("      \"format\": \"esm\"\n")
  buf.write_string("    }\n")
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Generate server main.mbt
fn generate_server_main_mbt(routes_pkg : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated server entry point\n")
  buf.write_string("///| Generated by: sol generate\n")
  buf.write_string("///|\n")
  buf.write_string(
    "///| DO NOT EDIT - This file is auto-generated from server/routes.mbt\n\n",
  )
  buf.write_string("///| Configure the application using shared routes\n")
  buf.write_string("fn configure_app(app : @sol.App) -> @sol.App {\n")
  buf.write_string("  // Get routes and config from server/routes.mbt\n")
  buf.write_string("  let routes = @app_server.routes()\n")
  buf.write_string("  let config = @app_server.config()\n\n")
  buf.write_string("  // Register routes with resolvers\n")
  buf.write_string("  let app = @router.register_routes(\n")
  buf.write_string("    app,\n")
  buf.write_string("    routes,\n")
  buf.write_string("    resolve_page,\n")
  buf.write_string("    resolve_api,\n")
  buf.write_string("    config=config,\n")
  buf.write_string("  )\n\n")
  buf.write_string("  // Serve static files\n")
  buf.write_string("  @sol.serve_static(app)\n")
  buf.write_string("}\n\n")
  buf.write_string("///| Resolve page component by ID\n")
  buf.write_string("fn resolve_page(\n")
  buf.write_string("  id : String,\n")
  buf.write_string("  ctx : @router.Ctx,\n")
  buf.write_string("  params : @router.RouteParams,\n")
  buf.write_string(") -> @luna.Node[Unit]? {\n")
  buf.write_string("  let props = @router.PageProps::from_ctx_with_params(ctx, params)\n")
  buf.write_string("  match id {\n")
  buf.write_string("    \"home\" => Some(@app_server.home(props))\n")
  buf.write_string("    \"about\" => Some(@app_server.about(props))\n")
  buf.write_string("    _ => None\n")
  buf.write_string("  }\n")
  buf.write_string("}\n\n")
  buf.write_string("///| Resolve API handler by ID\n")
  buf.write_string("fn resolve_api(\n")
  buf.write_string("  id : String,\n")
  buf.write_string("  ctx : @router.Ctx,\n")
  buf.write_string("  params : @router.RouteParams,\n")
  buf.write_string(") -> @core.Any? {\n")
  buf.write_string("  let props = @router.PageProps::from_ctx_with_params(ctx, params)\n")
  buf.write_string("  match id {\n")
  buf.write_string("    \"health\" => Some(@app_server.api_health(props))\n")
  buf.write_string("    _ => None\n")
  buf.write_string("  }\n")
  buf.write_string("}\n\n")
  buf.write_string("///|\n")
  buf.write_string("fn main {\n")
  buf.write_string("  @sol.run(configure_app)\n")
  buf.write_string("}\n")
  let _ = routes_pkg
  buf.to_string()
}

///|
/// Generate server moon.pkg.json
fn generate_server_pkg_json(routes_pkg : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"supported-targets\": [\"js\"],\n")
  buf.write_string("  \"is-main\": true,\n")
  buf.write_string("  \"import\": [\n")
  buf.write_string(
    "    { \"path\": \"mizchi/luna/sol\", \"alias\": \"sol\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"mizchi/luna/sol/router\", \"alias\": \"router\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"mizchi/luna/core\", \"alias\": \"luna\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"mizchi/js/core\", \"alias\": \"core\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"\{routes_pkg}\", \"alias\": \"app_server\" }\n",
  )
  buf.write_string("  ]\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Generate client entry JS file (new architecture)
fn generate_island_entry_js_v2(
  func : FuncExport,
  include_hydrate : Bool,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Client entry for: \{func.name}\n")
  buf.write_string("// Generated by: sol generate\n\n")
  if include_hydrate {
    buf.write_string(
      "import { \{func.name}, hydrate_\{func.name} as hydrate } from '../../target/js/release/build/__gen__/client/client.js';\n\n",
    )
    buf.write_string("export { \{func.name}, hydrate };\n")
    buf.write_string("export default hydrate;\n")
  } else {
    buf.write_string(
      "import { \{func.name} } from '../../target/js/release/build/__gen__/client/client.js';\n\n",
    )
    buf.write_string("export { \{func.name} };\n")
    buf.write_string("export default \{func.name};\n")
  }
  buf.to_string()
}

///|
/// Generate rolldown.config.mjs (new architecture)
fn generate_rolldown_config_v2(funcs : Array[FuncExport]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("import { defineConfig } from 'rolldown';\n\n")
  buf.write_string("export default defineConfig({\n")
  buf.write_string("  input: {\n")
  for i, func in funcs {
    buf.write_string("    '\{func.name}': './.sol/client/\{func.name}.js'")
    if i < funcs.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")
  buf.write_string("  output: {\n")
  buf.write_string("    dir: './.sol/static',\n")
  buf.write_string("    format: 'esm',\n")
  buf.write_string("    entryFileNames: '[name].js',\n")
  buf.write_string("    chunkFileNames: '_shared/[name]-[hash].js',\n")
  buf.write_string("  },\n")
  buf.write_string("});\n")
  buf.to_string()
}

///|
/// Generate island entry JS file (legacy)
fn generate_island_entry_js(entry : ExportEntry) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Island entry for: \{entry.name}\n")
  buf.write_string("// Generated by: sol generate\n\n")
  buf.write_string(
    "import { \{entry.name} } from '../../target/js/release/build/__gen__/client/client.js';\n\n",
  )
  buf.write_string("export { \{entry.name} };\n")
  buf.write_string("export default \{entry.name};\n")
  buf.to_string()
}

///|
/// Generate rolldown.config.mjs (legacy)
fn generate_rolldown_config_new(islands : Array[ExportEntry]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("import { defineConfig } from 'rolldown';\n\n")
  buf.write_string("export default defineConfig({\n")
  buf.write_string("  input: {\n")
  for i, entry in islands {
    buf.write_string("    '\{entry.name}': './.sol/islands/\{entry.name}.js'")
    if i < islands.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")
  buf.write_string("  output: {\n")
  buf.write_string("    dir: './.sol/static',\n")
  buf.write_string("    format: 'esm',\n")
  buf.write_string("    entryFileNames: '[name].js',\n")
  buf.write_string("    chunkFileNames: '_shared/[name]-[hash].js',\n")
  buf.write_string("  },\n")
  buf.write_string("});\n")
  buf.to_string()
}

///|
/// Generate .sol/server/main.js entry point
fn generate_sol_server_main_js(routes_pkg : String) -> String {
  let _ = routes_pkg
  let buf = StringBuilder::new()
  buf.write_string("// Server entry point\n")
  buf.write_string("// Generated by: sol generate\n\n")
  buf.write_string("// Re-export the server module\n")
  buf.write_string(
    "export * from '../../target/js/release/build/__gen__/server/server.js';\n",
  )
  buf.to_string()
}

// =============================================================================
// Main Generate Command (New Architecture)
// =============================================================================

///|
fn run_generate_command(args : Array[String]) -> Unit {
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(
        key="config",
        short="c",
        multiple=false,
        default=Some("sol.config.json"),
      ),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  if result.values.contains("help") && result.values["help"].cast() {
    show_generate_help()
    return
  }
  let config_path : String = if result.values.contains("config") {
    result.values["config"].cast()
  } else {
    "sol.config.json"
  }
  let cwd = @process.cwd()
  // Read config file
  let full_config_path = @path.join2(cwd, config_path)
  if not(@fs.existsSync(full_config_path)) {
    console_error(
      @colorette.red("Error: Config file not found: \{config_path}"),
    )
    @process.exit(1)
  }
  let config_content : String = @fs.readFileSync(full_config_path).to_string() catch {
    e => {
      console_error(@colorette.red("Error reading config: \{e}"))
      @process.exit(1)
      "" // unreachable
    }
  }
  guard parse_sol_config(config_content) is Some(config) else {
    console_error(@colorette.red("Error: Invalid config file format"))
    @process.exit(1)
  }
  println(@colorette.cyan("Generating app/__gen__ and .sol directories..."))
  // Create output directories first (needed for types)
  let output_dir = @path.join2(cwd, config.output) // app/__gen__
  let types_dir = @path.join2(output_dir, "types")
  @fs.mkdirSync(types_dir, recursive=true) catch {
    e => {
      console_error(@colorette.red("Error creating types directory: \{e}"))
      @process.exit(1)
    }
  }
  // Step 1: Parse source files to extract Props structs (before moon info)
  println(@colorette.gray("  Parsing source files for Props types..."))
  let source_structs = collect_island_structs_from_source(cwd, config)
  println(
    @colorette.gray(
      "  Found \{source_structs.length()} Props types from source",
    ),
  )
  // Step 2: Generate types package from source (so moon info can resolve imports)
  let project_name = get_project_name(cwd)
  if not(source_structs.is_empty()) {
    let types_mbt_content = generate_types_mbt(source_structs)
    let types_pkg_content = generate_types_pkg_json(
      source_structs, project_name,
    )
    let types_mbt_path = @path.join2(types_dir, "types.mbt")
    let types_pkg_path = @path.join2(types_dir, "moon.pkg.json")
    try {
      @fs.writeFileSync(types_mbt_path, @js.any(types_mbt_content))
      @fs.writeFileSync(types_pkg_path, @js.any(types_pkg_content))
      println(@colorette.gray("  Generated __gen__/types/ from source"))
    } catch {
      e => {
        console_error(@colorette.red("Error writing types package: \{e}"))
        @process.exit(1)
      }
    }
  } else {
    // Create empty stub if no Props found
    let stub_types_mbt_path = @path.join2(types_dir, "types.mbt")
    let stub_types_pkg_path = @path.join2(types_dir, "moon.pkg.json")
    if not(@fs.existsSync(stub_types_mbt_path)) {
      try {
        @fs.writeFileSync(
          stub_types_mbt_path,
          @js.any("///| No Props types found\n"),
        )
        @fs.writeFileSync(
          stub_types_pkg_path,
          @js.any("{\n  \"supported-targets\": [\"js\"]\n}\n"),
        )
      } catch {
        e => {
          console_error(@colorette.red("Error writing stub types: \{e}"))
          @process.exit(1)
        }
      }
    }
  }
  // Step 3: Run moon info to generate mbti files
  println(@colorette.gray("  Running moon info..."))
  try {
    let info_result = @child_process.spawnSync(
      "moon",
      args=["info", "--target", "js"],
      stdio="inherit",
    )
    if info_result.status() != Some(0) {
      console_error(@colorette.red("moon info failed"))
      @process.exit(1)
    }
  } catch {
    e => {
      console_error(@colorette.red("Error running moon info: \{e}"))
      @process.exit(1)
    }
  }
  // Collect all pub functions from island directories (using mbti)
  let funcs = collect_island_functions(cwd, config)
  println(@colorette.gray("  Found \{funcs.length()} island exports"))
  // Props names from source structs (already collected)
  let props_names : Array[String] = source_structs.map(fn(s) { s.name })
  // Create remaining output directories (types_dir already created above)
  let client_dir = @path.join2(output_dir, "client")
  let server_dir = @path.join2(output_dir, "server")
  let sol_dir = @path.join2(cwd, ".sol")
  let sol_client_dir = @path.join2(sol_dir, "client")
  let sol_server_dir = @path.join2(sol_dir, "server")
  try {
    @fs.mkdirSync(client_dir, recursive=true)
    @fs.mkdirSync(server_dir, recursive=true)
    @fs.mkdirSync(sol_client_dir, recursive=true)
    @fs.mkdirSync(sol_server_dir, recursive=true)
  } catch {
    e => {
      console_error(@colorette.red("Error creating directories: \{e}"))
      @process.exit(1)
    }
  }
  // Get routes package path from config
  let routes_pkg = get_routes_package_path(cwd, config.routes)
  // Note: types package already generated from source in Step 2
  // Generate client exports.mbt (re-exports all pub functions)
  if not(funcs.is_empty()) {
    let client_exports_mbt = generate_client_exports_mbt_v2(funcs, props_names)
    let client_exports_path = @path.join2(client_dir, "exports.mbt")
    try {
      @fs.writeFileSync(client_exports_path, @js.any(client_exports_mbt))
      println(@colorette.gray("  Generated __gen__/client/exports.mbt"))
    } catch {
      e => {
        console_error(@colorette.red("Error writing client/exports.mbt: \{e}"))
        @process.exit(1)
      }
    }
    // Generate client moon.pkg.json with link.js.exports
    let client_pkg = generate_client_pkg_json_v2(funcs)
    let client_pkg_path = @path.join2(client_dir, "moon.pkg.json")
    try {
      @fs.writeFileSync(client_pkg_path, @js.any(client_pkg))
      println(@colorette.gray("  Generated __gen__/client/moon.pkg.json"))
    } catch {
      e => {
        console_error(
          @colorette.red("Error writing client/moon.pkg.json: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  // Generate server main.mbt
  let server_main = generate_server_main_mbt(routes_pkg)
  let server_main_path = @path.join2(server_dir, "main.mbt")
  try {
    @fs.writeFileSync(server_main_path, @js.any(server_main))
    println(@colorette.gray("  Generated __gen__/server/main.mbt"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing server/main.mbt: \{e}"))
      @process.exit(1)
    }
  }
  // Generate server moon.pkg.json
  let server_pkg = generate_server_pkg_json(routes_pkg)
  let server_pkg_path = @path.join2(server_dir, "moon.pkg.json")
  try {
    @fs.writeFileSync(server_pkg_path, @js.any(server_pkg))
    println(@colorette.gray("  Generated __gen__/server/moon.pkg.json"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing server/moon.pkg.json: \{e}"))
      @process.exit(1)
    }
  }
  // Generate client JS entry files in .sol/client/
  if not(funcs.is_empty()) {
    for func in funcs {
      // Check if this function has Props -> DomNode signature (needs hydrate)
      let include_hydrate = func.signature.contains("Props") &&
        func.signature.contains("DomNode")
      let island_entry_content = generate_island_entry_js_v2(
        func, include_hydrate,
      )
      let island_entry_path = @path.join2(sol_client_dir, "\{func.name}.js")
      @fs.writeFileSync(island_entry_path, @js.any(island_entry_content)) catch {
        e => {
          console_error(
            @colorette.red("Error writing client entry \{func.name}.js: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
    println(
      @colorette.gray(
        "  Generated \{funcs.length()} client entries in .sol/client/",
      ),
    )
    // Generate rolldown.config.mjs
    let rolldown_config = generate_rolldown_config_v2(funcs)
    let rolldown_path = @path.join2(cwd, "rolldown.config.mjs")
    try {
      @fs.writeFileSync(rolldown_path, @js.any(rolldown_config))
      println(@colorette.gray("  Generated rolldown.config.mjs"))
    } catch {
      e => {
        console_error(@colorette.red("Error writing rolldown.config.mjs: \{e}"))
        @process.exit(1)
      }
    }
  }
  // Generate .sol/server/main.js (server entry point)
  let server_main_js = generate_sol_server_main_js(routes_pkg)
  let server_main_js_path = @path.join2(sol_server_dir, "main.js")
  try {
    @fs.writeFileSync(server_main_js_path, @js.any(server_main_js))
    println(@colorette.gray("  Generated .sol/server/main.js"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing .sol/server/main.js: \{e}"))
      @process.exit(1)
    }
  }
  println(@colorette.green("✓ Generation complete"))
}

///|
/// Get routes package path from moon.mod.json
fn get_routes_package_path(cwd : String, routes_dir : String) -> String {
  // Read moon.mod.json to get package name
  let mod_path = @path.join2(cwd, "moon.mod.json")
  if @fs.existsSync(mod_path) {
    try {
      let content = @fs.readFileSync(mod_path).to_string()
      let json = @json.parse(content.view())
      guard json is Object(obj) else { return "\{routes_dir}" }
      guard obj.get("name") is Some(String(pkg_name)) else {
        return "\{routes_dir}"
      }
      // Convert app/routes -> myproject/routes
      let routes_suffix = routes_dir.replace(old="app/", new="")
      return "\{pkg_name}/\{routes_suffix}"
    } catch {
      _ => ()
    }
  }
  // Fallback
  routes_dir
}
