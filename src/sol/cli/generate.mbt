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
  /// Auto-generate exports in island moon.pkg.json (default: true)
  client_auto_exports : Bool
}

///|
/// Route information extracted from routes.mbt
struct RouteInfo {
  /// Page component IDs (from Island and Page routes)
  page_components : Array[String]
  /// API handler IDs (from Get, Post, etc. routes)
  api_handlers : Array[String]
}

// =============================================================================
// Routes Parser
// =============================================================================

///|
/// Parse routes.mbt and extract component/handler names
fn parse_routes_file(routes_path : String) -> RouteInfo {
  let page_components : Array[String] = []
  let api_handlers : Array[String] = []

  if not(@fs.existsSync(routes_path)) {
    return RouteInfo::{ page_components, api_handlers }
  }

  let content = try { @fs.readFileSync(routes_path).to_string() } catch { _ => return RouteInfo::{ page_components, api_handlers } }

  // Find all component="..." values (for Page and Island routes)
  // These appear on their own lines in multi-line route definitions
  let mut search_pos = 0
  while search_pos < content.length() {
    let remaining = content.unsafe_substring(start=search_pos, end=content.length())
    match remaining.find("component=\"") {
      Some(start) => {
        let after_key = remaining.unsafe_substring(start=start + 11, end=remaining.length())
        match after_key.find("\"") {
          Some(end_idx) => {
            let component = after_key.unsafe_substring(start=0, end=end_idx)
            if not(page_components.contains(component)) {
              page_components.push(component)
            }
            search_pos = search_pos + start + 11 + end_idx + 1
          }
          None => {
            search_pos = search_pos + start + 11
          }
        }
      }
      None => break
    }
  }

  // Find all handler="..." values (for API routes)
  search_pos = 0
  while search_pos < content.length() {
    let remaining = content.unsafe_substring(start=search_pos, end=content.length())
    match remaining.find("handler=\"") {
      Some(start) => {
        let after_key = remaining.unsafe_substring(start=start + 9, end=remaining.length())
        match after_key.find("\"") {
          Some(end_idx) => {
            let handler = after_key.unsafe_substring(start=0, end=end_idx)
            if not(api_handlers.contains(handler)) {
              api_handlers.push(handler)
            }
            search_pos = search_pos + start + 9 + end_idx + 1
          }
          None => {
            search_pos = search_pos + start + 9
          }
        }
      }
      None => break
    }
  }

  RouteInfo::{ page_components, api_handlers }
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
    let client_auto_exports = match obj.get("client_auto_exports") {
      Some(True) => true
      Some(False) => false
      _ => true // default: true
    }
    Some(SolConfig::{ islands, routes, output, client_auto_exports })
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
) -> Array[(String, String, String)] {
  // Returns: Array of (pattern, dir_path, mbti_content)
  let result : Array[(String, String, String)] = []
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
              // For glob patterns, use the actual subdirectory as the pattern
              let sub_pattern = pattern.substring(end=pattern.length() - 2) + "/" + entry.to_string()
              result.push((sub_pattern, entry_path, content))
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
          result.push((pattern, base_path, content))
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
/// Generate types.mbt content with all Props struct definitions and ComponentRef factory functions
fn generate_types_mbt(structs : Array[StructExport]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated types for island props\n")
  buf.write_string("///| Re-exports Props structs from client packages\n\n")

  // Generate struct definitions
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

  // Generate ComponentRef factory functions
  if not(structs.is_empty()) {
    buf.write_string("// =============================================================================\n")
    buf.write_string("// ComponentRef Factory Functions\n")
    buf.write_string("// =============================================================================\n\n")
  }

  for s in structs {
    let component_name = extract_component_name_from_props(s.name)
    let url = "/static/\{component_name}.js"
    let is_wc = is_web_component(component_name)

    buf.write_string("///|\n")
    buf.write_string("///| Create ComponentRef for \{component_name} component\n")
    buf.write_string("pub fn \{component_name}(\n")
    buf.write_string("  props : \{s.name},\n")
    buf.write_string("  trigger~ : @luna.Trigger = @luna.Load,\n")
    buf.write_string(") -> @luna.ComponentRef[\{s.name}] {\n")
    buf.write_string("  { url: \"\{url}\", props, wc: \{is_wc}, trigger }\n")
    buf.write_string("}\n\n")
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
  // Import @luna for ComponentRef type
  buf.write_string("  \"import\": [\n")
  buf.write_string("    { \"path\": \"mizchi/luna/core\", \"alias\": \"luna\" }\n")
  buf.write_string("  ],\n")
  buf.write_string("  \"link\": {\n")
  buf.write_string("    \"js\": {\n")
  // Export all struct names and factory functions
  let exports : Array[String] = []
  for s in structs {
    exports.push(s.name)
    // Add factory function name (derived from Props name)
    let fn_name = extract_component_name_from_props(s.name)
    exports.push(fn_name)
  }
  let exports_str = exports.map(fn(n) { "\"\{n}\"" }).join(", ")
  buf.write_string("      \"exports\": [\{exports_str}],\n")
  buf.write_string("      \"format\": \"esm\"\n")
  buf.write_string("    }\n")
  buf.write_string("  },\n")
  buf.write_string("  \"warn-list\": \"-29\"\n")
  buf.write_string("}\n")
  buf.to_string()
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
/// Generate hydrate functions only (for __gen__.mbt in island directory)
/// Unlike generate_client_exports_mbt_v2, this generates hydrate_* functions
/// that call the original functions directly (same package, no re-export needed)
fn generate_hydrate_mbt(funcs : Array[FuncExport]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated hydrate functions\n")
  buf.write_string("///| DO NOT EDIT - regenerated by sol generate\n\n")
  for func in funcs {
    // Check if function takes Props and returns DomNode or Node
    let props_type = extract_props_type(func.signature, "")
    let returns_dom_node = func.signature.contains("DomNode")
    let returns_vnode = func.signature.contains("Node[")
    if props_type.length() > 0 && (returns_dom_node || returns_vnode) {
      buf.write_string(
        "///| Hydrate wrapper for \{func.name} - called by ln-loader and wc-loader\n",
      )
      buf.write_string(
        "///| Auto-detects WC mode (shadowRoot) vs Luna mode (direct render)\n",
      )
      buf.write_string(
        "pub fn hydrate_\{func.name}(element : @js.Any, state : @js.Any, _id : String) -> Unit {\n",
      )
      buf.write_string("  let jsdom_el : @js_dom.Element = element.cast()\n")
      buf.write_string(
        "  // state is already a JS object from JSON.parse in loader\n",
      )
      buf.write_string("  // Convert to Json then parse to Props\n")
      buf.write_string("  let json = @mbtconv.to_json(state)\n")
      buf.write_string(
        "  let props : \{props_type} = try { @json.from_json(json) } catch { _ => return }\n",
      )
      buf.write_string("  let node = \{func.name}(props)\n")
      buf.write_string("  // Auto-detect WC (shadowRoot) vs Luna mode\n")
      if returns_dom_node {
        buf.write_string("  @wc.hydrate_auto_dom(jsdom_el, node)\n")
      } else {
        buf.write_string("  @wc.hydrate_auto(jsdom_el, node)\n")
      }
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
/// Required imports for hydrate functions
let hydrate_required_imports : Array[(String, String)] = [
  ("mizchi/js/core", "js"),
  ("mizchi/js/mbtconv", "mbtconv"),
  ("mizchi/js/browser/dom", "js_dom"),
  ("mizchi/luna/platform/dom", "wc"),
]

///|
/// Update island moon.pkg.json with exports and required imports
/// This modifies the existing moon.pkg.json to add link.js.exports
fn update_island_pkg_json(
  pkg_json_path : String,
  exports : Array[String],
) -> Unit {
  // Read existing moon.pkg.json
  let content : String = try {
    @fs.readFileSync(pkg_json_path).to_string()
  } catch {
    _ => return // File doesn't exist, skip
  }
  // Parse JSON
  let json = try { @json.parse(content.view()) } catch { _ => return }
  guard json is Object(obj) else { return }
  // Get existing imports
  let existing_imports : Array[Json] = match obj.get("import") {
    Some(Array(arr)) => arr
    _ => []
  }
  // Check which required imports are missing
  let existing_paths : Map[String, Bool] = {}
  for imp in existing_imports {
    guard imp is Object(imp_obj) else { continue }
    match imp_obj.get("path") {
      Some(String(path)) => existing_paths[path] = true
      _ => ()
    }
  }
  // Add missing required imports
  let new_imports : Array[Json] = existing_imports.copy()
  for item in hydrate_required_imports {
    let (path, pkg_alias) = item
    if not(existing_paths.contains(path)) {
      let imp_obj : Map[String, Json] = {}
      imp_obj["path"] = Json::string(path)
      imp_obj["alias"] = Json::string(pkg_alias)
      new_imports.push(Json::object(imp_obj))
    }
  }
  // Build new JSON object
  let new_obj : Map[String, Json] = {}
  // Copy supported-targets
  match obj.get("supported-targets") {
    Some(targets) => new_obj["supported-targets"] = targets
    None => new_obj["supported-targets"] = Json::array([Json::string("js")])
  }
  // Set updated imports
  new_obj["import"] = Json::array(new_imports)
  // Set link.js.exports
  let exports_json : Array[Json] = exports.map(fn(s) { Json::string(s) })
  let js_link : Map[String, Json] = {}
  js_link["exports"] = Json::array(exports_json)
  js_link["format"] = Json::string("esm")
  let link : Map[String, Json] = {}
  link["js"] = Json::object(js_link)
  new_obj["link"] = Json::object(link)
  // Write back
  let output = format_pkg_json(new_obj)
  try {
    @fs.writeFileSync(pkg_json_path, @js.any(output))
  } catch {
    _ => ()
  }
}

///|
/// Format moon.pkg.json with proper indentation
fn format_pkg_json(obj : Map[String, Json]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  let mut first = true
  // supported-targets
  match obj.get("supported-targets") {
    Some(Array(targets)) => {
      if not(first) {
        buf.write_string(",\n")
      }
      first = false
      buf.write_string("  \"supported-targets\": [")
      for i, t in targets {
        if i > 0 {
          buf.write_string(", ")
        }
        guard t is String(s) else { continue }
        buf.write_string("\"\{s}\"")
      }
      buf.write_string("]")
    }
    _ => ()
  }
  // import
  match obj.get("import") {
    Some(Array(imports)) => {
      if not(first) {
        buf.write_string(",\n")
      }
      first = false
      buf.write_string("  \"import\": [\n")
      for i, imp in imports {
        if i > 0 {
          buf.write_string(",\n")
        }
        guard imp is Object(imp_obj) else { continue }
        let path = match imp_obj.get("path") {
          Some(String(s)) => s
          _ => continue
        }
        let pkg_alias = match imp_obj.get("alias") {
          Some(String(s)) => s
          _ => continue
        }
        buf.write_string(
          "    { \"path\": \"\{path}\", \"alias\": \"\{pkg_alias}\" }",
        )
      }
      buf.write_string("\n  ]")
    }
    _ => ()
  }
  // link
  match obj.get("link") {
    Some(Object(link)) => {
      if not(first) {
        buf.write_string(",\n")
      }
      buf.write_string("  \"link\": {\n")
      buf.write_string("    \"js\": {\n")
      match link.get("js") {
        Some(Object(js_obj)) => {
          match js_obj.get("exports") {
            Some(Array(exports)) => {
              buf.write_string("      \"exports\": [")
              for i, exp in exports {
                if i > 0 {
                  buf.write_string(", ")
                }
                guard exp is String(s) else { continue }
                buf.write_string("\"\{s}\"")
              }
              buf.write_string("],\n")
            }
            _ => ()
          }
          match js_obj.get("format") {
            Some(String(fmt)) => buf.write_string("      \"format\": \"\{fmt}\"\n")
            _ => buf.write_string("      \"format\": \"esm\"\n")
          }
        }
        _ => ()
      }
      buf.write_string("    }\n")
      buf.write_string("  }")
    }
    _ => ()
  }
  buf.write_string("\n}\n")
  buf.to_string()
}

///|
/// Generate server main.mbt
fn generate_server_main_mbt(routes_pkg : String, route_info : RouteInfo) -> String {
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
  buf.write_string("  // Register routes with resolvers (supports async server components)\n")
  buf.write_string("  let app = @router.register_server_routes(\n")
  buf.write_string("    app,\n")
  buf.write_string("    routes,\n")
  buf.write_string("    resolve_page,\n")
  buf.write_string("    resolve_api,\n")
  buf.write_string("    config=config,\n")
  buf.write_string("  )\n\n")
  buf.write_string("  // Serve static files\n")
  buf.write_string("  @sol.serve_static(app)\n")
  buf.write_string("}\n\n")
  buf.write_string("///| Resolve page component by ID (returns ServerNode for async support)\n")
  buf.write_string("fn resolve_page(\n")
  buf.write_string("  id : String,\n")
  buf.write_string("  ctx : @router.Ctx,\n")
  buf.write_string("  params : @router.RouteParams,\n")
  buf.write_string(") -> @server_dom.ServerNode? {\n")
  buf.write_string("  let props = @router.PageProps::from_ctx_with_params(ctx, params)\n")
  buf.write_string("  match id {\n")
  // Generate match cases for each page component
  for component in route_info.page_components {
    buf.write_string("    \"\{component}\" => Some(@app_server.\{component}(props))\n")
  }
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
  // Generate match cases for each API handler
  for handler in route_info.api_handlers {
    buf.write_string("    \"\{handler}\" => Some(@app_server.api_\{handler}(props))\n")
  }
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
    "    { \"path\": \"mizchi/luna/platform/server_dom\", \"alias\": \"server_dom\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"mizchi/js/core\", \"alias\": \"core\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"\{routes_pkg}\", \"alias\": \"app_server\" }\n",
  )
  buf.write_string("  ],\n")
  buf.write_string("  \"warn-list\": \"-29\"\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Generate client entry JS file (new architecture)
/// Path: .sol/{mode}/client/{name}.js -> ../../../target/js/release/build/__gen__/client/client.js
fn generate_island_entry_js_v2(
  func : FuncExport,
  include_hydrate : Bool,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Client entry for: \{func.name}\n")
  buf.write_string("// Generated by: sol generate\n\n")
  // Path from .sol/{mode}/client/ to target/ is ../../../target/
  if include_hydrate {
    buf.write_string(
      "import { \{func.name}, hydrate_\{func.name} as hydrate } from '../../../target/js/release/build/__gen__/client/client.js';\n\n",
    )
    buf.write_string("export { \{func.name}, hydrate };\n")
    buf.write_string("export default hydrate;\n")
  } else {
    buf.write_string(
      "import { \{func.name} } from '../../../target/js/release/build/__gen__/client/client.js';\n\n",
    )
    buf.write_string("export { \{func.name} };\n")
    buf.write_string("export default \{func.name};\n")
  }
  buf.to_string()
}

///|
/// Generate island manifest JSON (for programmatic rolldown build)
fn generate_island_manifest_json(funcs : Array[FuncExport], mode : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"output_dir\": \"./.sol/\{mode}/static\",\n")
  buf.write_string("  \"islands\": [\n")
  for i, func in funcs {
    buf.write_string("    { \"name\": \"\{func.name}\", \"entry_path\": \"./.sol/\{mode}/client/\{func.name}.js\" }")
    if i < funcs.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  ]\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Generate .sol/{mode}/server/main.js entry point
/// Path: .sol/{mode}/server/main.js -> ../../../target/js/release/build/__gen__/server/server.js
fn generate_sol_server_main_js(routes_pkg : String) -> String {
  let _ = routes_pkg
  let buf = StringBuilder::new()
  buf.write_string("// Server entry point\n")
  buf.write_string("// Generated by: sol generate\n\n")
  buf.write_string("// Re-export the server module\n")
  buf.write_string(
    "export * from '../../../target/js/release/build/__gen__/server/server.js';\n",
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
      @util.String(
        key="mode",
        short="m",
        multiple=false,
        default=Some("prod"),
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
  let mode : String = if result.values.contains("mode") {
    result.values["mode"].cast()
  } else {
    "prod"
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
          @js.any("{\n  \"supported-targets\": [\"js\"],\n  \"warn-list\": \"-29\"\n}\n"),
        )
      } catch {
        e => {
          console_error(@colorette.red("Error writing stub types: \{e}"))
          @process.exit(1)
        }
      }
    }
  }
  // Step 2.5: Pre-create server moon.pkg.json with warn-list (before moon info)
  // This ensures warnings are suppressed during moon info
  let server_dir = @path.join2(output_dir, "server")
  @fs.mkdirSync(server_dir, recursive=true) catch {
    e => {
      console_error(@colorette.red("Error creating server directory: \{e}"))
      @process.exit(1)
    }
  }
  let routes_pkg = get_routes_package_path(cwd, config.routes)
  let server_pkg = generate_server_pkg_json(routes_pkg)
  let server_pkg_path = @path.join2(server_dir, "moon.pkg.json")
  @fs.writeFileSync(server_pkg_path, @js.any(server_pkg)) catch {
    e => {
      console_error(@colorette.red("Error writing server/moon.pkg.json: \{e}"))
      @process.exit(1)
    }
  }
  // Create stub main.mbt so is-main: true doesn't fail
  let stub_main_path = @path.join2(server_dir, "main.mbt")
  @fs.writeFileSync(stub_main_path, @js.any("///| Stub - will be replaced\nfn main { () }\n")) catch {
    e => {
      console_error(@colorette.red("Error writing stub main.mbt: \{e}"))
      @process.exit(1)
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
  // Create remaining output directories (types_dir and server_dir already created above)
  // Use mode-specific .sol directory: .sol/dev or .sol/prod
  let sol_dir = @path.join2(@path.join2(cwd, ".sol"), mode)
  let sol_client_dir = @path.join2(sol_dir, "client")
  let sol_server_dir = @path.join2(sol_dir, "server")
  try {
    @fs.mkdirSync(sol_client_dir, recursive=true)
    @fs.mkdirSync(sol_server_dir, recursive=true)
  } catch {
    e => {
      console_error(@colorette.red("Error creating directories: \{e}"))
      @process.exit(1)
    }
  }
  // Generate hydrate functions and update moon.pkg.json in each island directory
  if config.client_auto_exports && not(funcs.is_empty()) {
    // Group functions by source_pattern
    let patterns_seen : Map[String, Bool] = {}
    for f in funcs {
      patterns_seen[f.source_pattern] = true
    }
    for island_pattern in patterns_seen.keys() {
      let island_dir = @path.join2(cwd, island_pattern)
      // Filter functions for this island
      let island_funcs = funcs.filter(fn(f) { f.source_pattern == island_pattern })
      if island_funcs.is_empty() {
        continue
      }
      // Generate __gen__.mbt
      let hydrate_content = generate_hydrate_mbt(island_funcs)
      let hydrate_path = @path.join2(island_dir, "__gen__.mbt")
      try {
        @fs.writeFileSync(hydrate_path, @js.any(hydrate_content))
        println(@colorette.gray("  Generated \{island_pattern}/__gen__.mbt"))
      } catch {
        e => {
          console_error(@colorette.red("Error writing __gen__.mbt: \{e}"))
          @process.exit(1)
        }
      }
      // Collect export names (original functions + hydrate functions)
      let export_names : Array[String] = []
      for f in island_funcs {
        export_names.push(f.name)
        // Add hydrate_<name> if it's a Props -> DomNode function
        let props_type = extract_props_type(f.signature, "")
        let returns_dom_node = f.signature.contains("DomNode")
        let returns_vnode = f.signature.contains("Node[")
        if props_type.length() > 0 && (returns_dom_node || returns_vnode) {
          export_names.push("hydrate_\{f.name}")
        }
      }
      // Update moon.pkg.json
      let pkg_json_path = @path.join2(island_dir, "moon.pkg.json")
      update_island_pkg_json(pkg_json_path, export_names)
      println(@colorette.gray("  Updated \{island_pattern}/moon.pkg.json"))
    }
  }
  // Parse routes.mbt to extract component/handler info
  let routes_file_path = @path.join2(@path.join2(cwd, config.routes), "routes.mbt")
  let route_info = parse_routes_file(routes_file_path)
  // Generate server main.mbt
  let server_main = generate_server_main_mbt(routes_pkg, route_info)
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
  // Note: server/moon.pkg.json already generated before moon info (with warn-list)
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
        "  Generated \{funcs.length()} client entries in .sol/\{mode}/client/",
      ),
    )
    // Generate island manifest JSON for programmatic rolldown build
    let manifest_content = generate_island_manifest_json(funcs, mode)
    let manifest_path = @path.join2(sol_dir, "manifest.json")
    try {
      @fs.writeFileSync(manifest_path, @js.any(manifest_content))
      println(@colorette.gray("  Generated .sol/\{mode}/manifest.json"))
    } catch {
      e => {
        console_error(@colorette.red("Error writing manifest.json: \{e}"))
        @process.exit(1)
      }
    }
  }
  // Generate .sol/{mode}/server/main.js (server entry point)
  let server_main_js = generate_sol_server_main_js(routes_pkg)
  let server_main_js_path = @path.join2(sol_server_dir, "main.js")
  try {
    @fs.writeFileSync(server_main_js_path, @js.any(server_main_js))
    println(@colorette.gray("  Generated .sol/\{mode}/server/main.js"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing .sol/\{mode}/server/main.js: \{e}"))
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
