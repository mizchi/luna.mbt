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
/// Collect island exports from config
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
/// Generate client exports.mbt for islands
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
/// Generate client moon.pkg.json for islands
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
  buf.write_string("  _params : @router.RouteParams,\n")
  buf.write_string(") -> @luna.Node[Unit]? {\n")
  buf.write_string("  let props = @router.PageProps::from_ctx(ctx)\n")
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
  buf.write_string("  _params : @router.RouteParams,\n")
  buf.write_string(") -> @core.Any? {\n")
  buf.write_string("  let props = @router.PageProps::from_ctx(ctx)\n")
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
/// Generate island entry JS file
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
/// Generate rolldown.config.mjs
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
  // Run moon info to generate mbti files
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
  // Collect island exports
  let islands = collect_exports(cwd, config)
  println(@colorette.gray("  Found \{islands.length()} island exports"))
  // Create output directories
  let output_dir = @path.join2(cwd, config.output) // app/_gen
  let client_dir = @path.join2(output_dir, "client")
  let server_dir = @path.join2(output_dir, "server")
  let sol_dir = @path.join2(cwd, ".sol")
  let islands_dir = @path.join2(sol_dir, "islands")
  try {
    @fs.mkdirSync(client_dir, recursive=true)
    @fs.mkdirSync(server_dir, recursive=true)
    @fs.mkdirSync(islands_dir, recursive=true)
  } catch {
    e => {
      console_error(@colorette.red("Error creating directories: \{e}"))
      @process.exit(1)
    }
  }
  // Get routes package path from config
  let routes_pkg = get_routes_package_path(cwd, config.routes)
  // Generate client exports.mbt (re-exports hydrate functions)
  if not(islands.is_empty()) {
    let client_exports_mbt = generate_client_exports_mbt(islands)
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
    // Generate client moon.pkg.json
    let client_pkg = generate_client_pkg_json(islands)
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
  // Generate island entry files for rolldown
  if not(islands.is_empty()) {
    for entry in islands {
      let island_entry_content = generate_island_entry_js(entry)
      let island_entry_path = @path.join2(islands_dir, "\{entry.name}.js")
      @fs.writeFileSync(island_entry_path, @js.any(island_entry_content)) catch {
        e => {
          console_error(
            @colorette.red("Error writing island entry \{entry.name}.js: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
    println(
      @colorette.gray(
        "  Generated \{islands.length()} island entries in .sol/islands/",
      ),
    )
    // Generate rolldown.config.mjs
    let rolldown_config = generate_rolldown_config_new(islands)
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
