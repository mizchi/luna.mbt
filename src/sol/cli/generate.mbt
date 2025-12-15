///| sol generate command - Generate _gen and .sol directories from sol.config.json

///|
fn show_generate_help() -> Unit {
  let help =
    #|Usage: sol generate [options]
    #|
    #|Generate app/_gen (MoonBit) and .sol (JS) directories from sol.config.json
    #|
    #|Options:
    #|  -c, --config <path>  Config file path (default: sol.config.json)
    #|  -h, --help           Show help
  println(help)
}

// =============================================================================
// Config Types
// =============================================================================

///| Sol configuration
pub struct SolConfig {
  /// Component directories (SSR only)
  components : Array[String]
  /// Island directories (client hydration)
  islands : Array[String]
  /// Page directories
  pages : Array[String]
  /// Output directory for generated MoonBit files
  output : String
}

///| Parsed export entry from mbti
struct ExportEntry {
  /// Export name (function name)
  name : String
  /// Original function name in source module
  source_name : String
  /// Package path (e.g., "myproject/components")
  package_path : String
  /// Import alias (e.g., "components")
  import_alias : String
  /// Function signature (parameters and return type)
  signature : String
  /// Category: "component", "island", or "page"
  category : String
}

// =============================================================================
// Config Parser
// =============================================================================

///| Parse sol.config.json
pub fn parse_sol_config(json_str : String) -> SolConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    let components = parse_string_array(obj, "components")
    let islands = parse_string_array(obj, "islands")
    let pages = parse_string_array(obj, "pages")
    let output = match obj.get("output") {
      Some(String(s)) => s
      _ => "app/_gen"
    }
    Some(SolConfig::{ components, islands, pages, output })
  } catch {
    _ => None
  }
}

///| Parse string array from JSON object
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

///| Parse mbti imports to build alias mapping
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
        let after_first = trimmed.unsafe_substring(start=1, end=trimmed.length())
        match after_first.find("\"") {
          Some(end_quote) => {
            let pkg_path = after_first.unsafe_substring(
              start=0,
              end=end_quote,
            )
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

///| Rewrite type references from mbti format to exports format
pub fn rewrite_type_refs(sig : String, _imports : Map[String, String]) -> String {
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

///| Parse mbti file and extract pub fn declarations
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

///| Find mbti files in directories matching glob patterns
fn find_mbti_files(
  cwd : String,
  patterns : Array[String]
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

///| Extract package path from mbti content
pub fn extract_package_path(mbti_content : String) -> String? {
  let lines = mbti_content.split("\n").to_array()
  for line in lines {
    let line_str = line.to_string()
    let trimmed = line_str.trim_start(" \t").to_string()
    if trimmed.has_prefix("package \"") {
      let start = 9 // len of 'package "'
      let after_prefix = trimmed.unsafe_substring(
        start~,
        end=trimmed.length(),
      )
      match after_prefix.find("\"") {
        Some(end_quote) =>
          return Some(
            trimmed.unsafe_substring(start~, end=end_quote + start),
          )
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
///| Removes "island_client_" or "island_" prefix
pub fn extract_island_name(name : String) -> String {
  if name.has_prefix("island_client_") {
    name.substring(start=14)
  } else if name.has_prefix("island_") {
    name.substring(start=7)
  } else {
    name
  }
}

///| Generate import alias from package path
pub fn generate_import_alias(package_path : String, category : String) -> String {
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

///| Generate export name
pub fn generate_export_name(
  fn_name : String,
  import_alias : String,
  category : String
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

///| Collect all export entries from config
fn collect_exports(cwd : String, config : SolConfig) -> Array[ExportEntry] {
  let entries : Array[ExportEntry] = []
  // Components
  let comp_files = find_mbti_files(cwd, config.components)
  for pair in comp_files {
    let (dir_path, content) = pair
    let _ = dir_path
    guard extract_package_path(content) is Some(pkg_path) else { continue }
    let import_alias = generate_import_alias(pkg_path, "component")
    let funcs = parse_mbti(content)
    for func in funcs {
      let (name, sig) = func
      entries.push(
        ExportEntry::{
          name,
          source_name: name,
          package_path: pkg_path,
          import_alias,
          signature: sig,
          category: "component",
        },
      )
    }
  }
  // Islands
  let island_files = find_mbti_files(cwd, config.islands)
  for pair in island_files {
    let (dir_path, content) = pair
    let _ = dir_path
    guard extract_package_path(content) is Some(pkg_path) else { continue }
    let import_alias = generate_import_alias(pkg_path, "island")
    let funcs = parse_mbti(content)
    for func in funcs {
      let (name, sig) = func
      let export_name = generate_export_name(name, import_alias, "island")
      entries.push(
        ExportEntry::{
          name: export_name,
          source_name: name,
          package_path: pkg_path,
          import_alias,
          signature: sig,
          category: "island",
        },
      )
    }
  }
  // Pages
  let page_files = find_mbti_files(cwd, config.pages)
  for pair in page_files {
    let (dir_path, content) = pair
    let _ = dir_path
    guard extract_package_path(content) is Some(pkg_path) else { continue }
    let import_alias = generate_import_alias(pkg_path, "page")
    let funcs = parse_mbti(content)
    for func in funcs {
      let (name, sig) = func
      let export_name = generate_export_name(name, import_alias, "page")
      entries.push(
        ExportEntry::{
          name: export_name,
          source_name: name,
          package_path: pkg_path,
          import_alias,
          signature: sig,
          category: "page",
        },
      )
    }
  }
  entries
}

///| Split parameters respecting nested brackets
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

///| Find matching closing paren position
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

///| Generate parameter names for signature
pub fn generate_params_with_names(signature : String) -> (String, String) {
  // signature: "(Type1, Type2) -> RetType" or "() -> RetType"
  // Returns: (signature_with_names, call_args)
  // e.g., "(String, Int) -> Unit" => ("(p0 : String, p1 : Int) -> Unit", "(p0, p1)")
  match signature.find("(") {
    None => (signature, "()")
    Some(paren_start) => {
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
}

///| Generate exports.mbt content for a specific target (client or server)
fn generate_exports_mbt(
  entries : Array[ExportEntry],
  target : String
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated - \{target} exports\n")
  buf.write_string("///| Generated by: sol generate\n\n")
  // Filter and group by category
  let components : Array[ExportEntry] = []
  let islands : Array[ExportEntry] = []
  let pages : Array[ExportEntry] = []
  for entry in entries {
    match entry.category {
      "component" => components.push(entry)
      "island" => islands.push(entry)
      "page" => pages.push(entry)
      _ => ()
    }
  }
  // Components (both client and server)
  if not(components.is_empty()) {
    buf.write_string("// ============================================\n")
    buf.write_string("// Components\n")
    buf.write_string("// ============================================\n\n")
    for entry in components {
      let (sig_with_names, call_args) = generate_params_with_names(
        entry.signature,
      )
      buf.write_string("///|\n")
      buf.write_string("pub fn \{entry.name}\{sig_with_names} {\n")
      buf.write_string("  @\{entry.import_alias}.\{entry.source_name}\{call_args}\n")
      buf.write_string("}\n\n")
    }
  }
  // Islands (client only)
  if target == "client" && not(islands.is_empty()) {
    buf.write_string("// ============================================\n")
    buf.write_string("// Islands (Hydration)\n")
    buf.write_string("// ============================================\n\n")
    for entry in islands {
      let (sig_with_names, call_args) = generate_params_with_names(
        entry.signature,
      )
      buf.write_string("///|\n")
      buf.write_string("pub fn \{entry.name}\{sig_with_names} {\n")
      buf.write_string("  @\{entry.import_alias}.\{entry.source_name}\{call_args}\n")
      buf.write_string("}\n\n")
    }
  }
  // Pages (server only)
  if target == "server" && not(pages.is_empty()) {
    buf.write_string("// ============================================\n")
    buf.write_string("// Pages\n")
    buf.write_string("// ============================================\n\n")
    for entry in pages {
      let (sig_with_names, call_args) = generate_params_with_names(
        entry.signature,
      )
      buf.write_string("///|\n")
      buf.write_string("pub fn \{entry.name}\{sig_with_names} {\n")
      buf.write_string("  @\{entry.import_alias}.\{entry.source_name}\{call_args}\n")
      buf.write_string("}\n\n")
    }
  }
  buf.to_string()
}

///| Check if signature uses @luna types
pub fn uses_luna_types(signature : String) -> Bool {
  signature.contains("@luna.")
}

///| Check if signature uses @js types
pub fn uses_js_types(signature : String) -> Bool {
  signature.contains("@js.")
}

///| Check if signature uses @signal types
pub fn uses_signal_types(signature : String) -> Bool {
  signature.contains("@signal.")
}

///| Check if signature uses @hono types
pub fn uses_hono_types(signature : String) -> Bool {
  signature.contains("@hono.")
}

///| Generate moon.pkg.json content for exports
fn generate_moon_pkg_json(entries : Array[ExportEntry], target : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"import\": [\n")
  // Collect unique imports based on target
  let imports : Map[String, String] = {}
  // Track which type packages are needed
  let mut needs_luna = false
  let mut needs_js = false
  let mut needs_signal = false
  let mut needs_hono = false
  for entry in entries {
    // Filter by target
    let should_include = match (target, entry.category) {
      ("client", "component") => true
      ("client", "island") => true
      ("server", "component") => true
      ("server", "page") => true
      _ => false
    }
    if should_include {
      imports[entry.import_alias] = entry.package_path
      // Check signature for type dependencies
      if uses_luna_types(entry.signature) {
        needs_luna = true
      }
      if uses_js_types(entry.signature) {
        needs_js = true
      }
      if uses_signal_types(entry.signature) {
        needs_signal = true
      }
      if uses_hono_types(entry.signature) {
        needs_hono = true
      }
    }
  }
  // Add type packages only if needed
  if needs_luna {
    imports["luna"] = "mizchi/luna/core"
  }
  if needs_js {
    imports["js"] = "mizchi/js/core"
  }
  if needs_signal {
    imports["signal"] = "mizchi/luna/core/signal"
  }
  // Add hono for server if needed
  if target == "server" && needs_hono {
    imports["hono"] = "mizchi/npm_typed/hono"
  }
  let import_entries : Array[(String, String)] = []
  for k, v in imports {
    import_entries.push((k, v))
  }
  for i, pair in import_entries {
    let (alias_name, path) = pair
    buf.write_string(
      "    { \"path\": \"\{path}\", \"alias\": \"\{alias_name}\" }",
    )
    if i < import_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  ],\n")
  buf.write_string("  \"link\": {\n")
  buf.write_string("    \"js\": {\n")
  buf.write_string("      \"exports\": [\n")
  // Filter exports by target
  let filtered_entries : Array[ExportEntry] = []
  for entry in entries {
    let should_include = match (target, entry.category) {
      ("client", "component") => true
      ("client", "island") => true
      ("server", "component") => true
      ("server", "page") => true
      _ => false
    }
    if should_include {
      filtered_entries.push(entry)
    }
  }
  for i, entry in filtered_entries {
    buf.write_string("        \"\{entry.name}\"")
    if i < filtered_entries.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("      ],\n")
  buf.write_string("      \"format\": \"esm\"\n")
  buf.write_string("    }\n")
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

///| Generate chunk JS file content (for .sol/chunks/)
fn generate_chunk_js(export_name : String, target : String) -> String {
  "export { \{export_name} } from \"../../target/js/release/build/_gen/\{target}/exports.js\";\n"
}

///| Generate individual island entry file (for .sol/islands/)
///| This creates a separate entry point for each island for code splitting
fn generate_island_entry(entry : ExportEntry) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Individual island entry for: \{entry.name}\n")
  buf.write_string("// Generated by: sol generate\n\n")
  // Import from the compiled MoonBit output
  // Path is relative from .sol/islands/ to project root's target/
  // MoonBit outputs as client.js (package name), not exports.js
  buf.write_string(
    "import { \{entry.name} } from '../../target/js/release/build/_gen/client/client.js';\n\n",
  )
  // Extract the hydrate function name (remove island_client_ prefix)
  let export_name = extract_island_name(entry.name)
  // Export both the original and the shortened name
  buf.write_string("export { \{entry.name} };\n")
  buf.write_string("export const \{export_name} = \{entry.name};\n")
  buf.write_string("export default \{entry.name};\n")
  buf.to_string()
}

///| Generate rolldown config content (dynamic based on islands)
fn generate_rolldown_config(islands : Array[ExportEntry]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("import { defineConfig } from 'rolldown';\n\n")
  buf.write_string("export default defineConfig({\n")
  buf.write_string("  input: {\n")
  // Add each island as a separate entry point
  for i, entry in islands {
    let island_name = extract_island_name(entry.name)
    buf.write_string("    '\{island_name}': './.sol/islands/\{entry.name}.js'")
    if i < islands.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  },\n")
  buf.write_string("  output: {\n")
  buf.write_string("    dir: './static',\n")
  buf.write_string("    format: 'esm',\n")
  buf.write_string("    entryFileNames: '[name].js',\n")
  buf.write_string("    chunkFileNames: '_shared/[name]-[hash].js',\n")
  buf.write_string("  },\n")
  buf.write_string("});\n")
  buf.to_string()
}

///| Generate entry.client.js content
fn generate_client_js(islands : Array[ExportEntry]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Client entry point - dynamic imports for islands\n")
  buf.write_string("// Generated by: sol generate\n\n")
  buf.write_string("const islands = {\n")
  for i, entry in islands {
    // Extract island name from export name
    let island_name = extract_island_name(entry.name)
    buf.write_string(
      "  \{island_name}: () => import('./chunks/\{entry.name}.js').then(m => m.\{entry.name})",
    )
    if i < islands.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("};\n\n")
  buf.write_string("export async function hydrateIslands() {\n")
  buf.write_string(
    "  const islandElements = document.querySelectorAll('[data-island]');\n",
  )
  buf.write_string("  for (const el of islandElements) {\n")
  buf.write_string("    const islandType = el.dataset.island;\n")
  buf.write_string(
    "    const state = el.dataset.state ? JSON.parse(el.dataset.state) : {};\n",
  )
  buf.write_string("    const id = el.dataset.id || islandType;\n")
  buf.write_string("    if (islands[islandType]) {\n")
  buf.write_string("      const hydrateFn = await islands[islandType]();\n")
  buf.write_string("      hydrateFn(el, state, id);\n")
  buf.write_string("    } else {\n")
  buf.write_string(
    "      console.warn(`Unknown island type: ${islandType}`);\n",
  )
  buf.write_string("    }\n")
  buf.write_string("  }\n")
  buf.write_string("}\n\n")
  buf.write_string("if (typeof window !== 'undefined') {\n")
  buf.write_string("  if (document.readyState === 'loading') {\n")
  buf.write_string(
    "    document.addEventListener('DOMContentLoaded', hydrateIslands);\n",
  )
  buf.write_string("  } else {\n")
  buf.write_string("    hydrateIslands();\n")
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

///| Generate Luna loader compatible client entry
fn generate_luna_client_entry(islands : Array[ExportEntry]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Luna loader compatible client entry\n")
  buf.write_string("// Generated by: sol generate\n\n")
  buf.write_string(
    "import * as exports from '../target/js/release/build/_gen/client/client.js';\n\n",
  )
  // Export each island hydrate function
  for entry in islands {
    let export_name = extract_island_name(entry.name)
    buf.write_string("export const \{export_name} = exports.\{entry.name};\n")
  }
  // Export first island as default (for Luna loader)
  if not(islands.is_empty()) {
    let export_name = extract_island_name(islands[0].name)
    buf.write_string("\nexport default \{export_name};\n")
  }
  buf.to_string()
}

///| Generate entry.server.js content
fn generate_server_js(
  components : Array[ExportEntry],
  pages : Array[ExportEntry]
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Server entry point\n")
  buf.write_string("// Generated by: sol generate\n\n")
  // Import components
  for entry in components {
    buf.write_string(
      "import { \{entry.name} } from './chunks/\{entry.name}.js';\n",
    )
  }
  // Import pages
  for entry in pages {
    buf.write_string(
      "import { \{entry.name} } from './chunks/\{entry.name}.js';\n",
    )
  }
  buf.write_string("\n// Re-export for SSR\n")
  buf.write_string("export {\n")
  let all_exports : Array[String] = []
  for entry in components {
    all_exports.push(entry.name)
  }
  for entry in pages {
    all_exports.push(entry.name)
  }
  for i, name in all_exports {
    buf.write_string("  \{name}")
    if i < all_exports.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("};\n")
  buf.to_string()
}

// =============================================================================
// Main Generate Command
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
  let config_content : String = try {
    @fs.readFileSync(full_config_path).to_string()
  } catch {
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
  println(@colorette.cyan("Generating app/_gen and .sol directories..."))
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
  // Collect exports
  let entries = collect_exports(cwd, config)
  if entries.is_empty() {
    console_error(
      @colorette.yellow("Warning: No exports found. Check your config paths."),
    )
    return
  }
  println(@colorette.gray("  Found \{entries.length()} exports"))
  // Create output directories
  let output_dir = @path.join2(cwd, config.output) // app/_gen
  let client_dir = @path.join2(output_dir, "client")
  let server_dir = @path.join2(output_dir, "server")
  let sol_dir = @path.join2(cwd, ".sol")
  let chunks_dir = @path.join2(sol_dir, "chunks")
  let islands_dir = @path.join2(sol_dir, "islands")
  try {
    @fs.mkdirSync(client_dir, recursive=true)
    @fs.mkdirSync(server_dir, recursive=true)
    @fs.mkdirSync(chunks_dir, recursive=true)
    @fs.mkdirSync(islands_dir, recursive=true)
  } catch {
    e => {
      console_error(@colorette.red("Error creating directories: \{e}"))
      @process.exit(1)
    }
  }
  // Separate entries by category
  let components : Array[ExportEntry] = []
  let islands : Array[ExportEntry] = []
  let pages : Array[ExportEntry] = []
  for entry in entries {
    match entry.category {
      "component" => components.push(entry)
      "island" => islands.push(entry)
      "page" => pages.push(entry)
      _ => ()
    }
  }
  // Generate client exports.mbt
  let client_exports_mbt = generate_exports_mbt(entries, "client")
  let client_exports_path = @path.join2(client_dir, "exports.mbt")
  try {
    @fs.writeFileSync(client_exports_path, @js.any(client_exports_mbt))
    println(@colorette.gray("  Generated _gen/client/exports.mbt"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing client/exports.mbt: \{e}"))
      @process.exit(1)
    }
  }
  // Generate client moon.pkg.json
  let client_moon_pkg = generate_moon_pkg_json(entries, "client")
  let client_pkg_path = @path.join2(client_dir, "moon.pkg.json")
  try {
    @fs.writeFileSync(client_pkg_path, @js.any(client_moon_pkg))
    println(@colorette.gray("  Generated _gen/client/moon.pkg.json"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing client/moon.pkg.json: \{e}"))
      @process.exit(1)
    }
  }
  // Generate server exports.mbt
  let server_exports_mbt = generate_exports_mbt(entries, "server")
  let server_exports_path = @path.join2(server_dir, "exports.mbt")
  try {
    @fs.writeFileSync(server_exports_path, @js.any(server_exports_mbt))
    println(@colorette.gray("  Generated _gen/server/exports.mbt"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing server/exports.mbt: \{e}"))
      @process.exit(1)
    }
  }
  // Generate server moon.pkg.json
  let server_moon_pkg = generate_moon_pkg_json(entries, "server")
  let server_pkg_path = @path.join2(server_dir, "moon.pkg.json")
  try {
    @fs.writeFileSync(server_pkg_path, @js.any(server_moon_pkg))
    println(@colorette.gray("  Generated _gen/server/moon.pkg.json"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing server/moon.pkg.json: \{e}"))
      @process.exit(1)
    }
  }
  // Generate chunk files in .sol/chunks/
  // Client chunks (components + islands)
  for entry in components {
    let chunk_content = generate_chunk_js(entry.name, "client")
    let chunk_path = @path.join2(chunks_dir, "\{entry.name}.js")
    try {
      @fs.writeFileSync(chunk_path, @js.any(chunk_content))
    } catch {
      e => {
        console_error(
          @colorette.red("Error writing chunk \{entry.name}.js: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  for entry in islands {
    let chunk_content = generate_chunk_js(entry.name, "client")
    let chunk_path = @path.join2(chunks_dir, "\{entry.name}.js")
    try {
      @fs.writeFileSync(chunk_path, @js.any(chunk_content))
    } catch {
      e => {
        console_error(
          @colorette.red("Error writing chunk \{entry.name}.js: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  // Server chunks (components + pages) - use server exports
  for entry in pages {
    let chunk_content = generate_chunk_js(entry.name, "server")
    let chunk_path = @path.join2(chunks_dir, "\{entry.name}.js")
    try {
      @fs.writeFileSync(chunk_path, @js.any(chunk_content))
    } catch {
      e => {
        console_error(
          @colorette.red("Error writing chunk \{entry.name}.js: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  let chunk_count = components.length() + islands.length() + pages.length()
  println(@colorette.gray("  Generated \{chunk_count} chunk files in .sol/chunks/"))
  // Generate individual island entry files (for code splitting)
  if not(islands.is_empty()) {
    for entry in islands {
      let island_entry_content = generate_island_entry(entry)
      let island_entry_path = @path.join2(islands_dir, "\{entry.name}.js")
      try {
        @fs.writeFileSync(island_entry_path, @js.any(island_entry_content))
      } catch {
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
    // Generate rolldown.config.mjs (dynamic based on islands)
    let rolldown_config = generate_rolldown_config(islands)
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
    // Generate island manifest for programmatic build
    let manifest_entries : Array[(String, String)] = []
    for entry in islands {
      let island_name = extract_island_name(entry.name)
      manifest_entries.push((island_name, "./.sol/islands/\{entry.name}.js"))
    }
    let manifest_json = @sol.generate_island_manifest(manifest_entries, "./static")
    let manifest_path = @path.join2(sol_dir, "manifest.json")
    try {
      @fs.writeFileSync(manifest_path, @js.any(manifest_json))
      println(@colorette.gray("  Generated .sol/manifest.json"))
    } catch {
      e => {
        console_error(@colorette.red("Error writing manifest.json: \{e}"))
        @process.exit(1)
      }
    }
  }
  // Generate entry.client.js (data-island style - legacy)
  if not(islands.is_empty()) {
    let client_js = generate_client_js(islands)
    let client_path = @path.join2(sol_dir, "entry.client.js")
    try {
      @fs.writeFileSync(client_path, @js.any(client_js))
      println(@colorette.gray("  Generated .sol/entry.client.js"))
    } catch {
      e => {
        console_error(@colorette.red("Error writing entry.client.js: \{e}"))
        @process.exit(1)
      }
    }
    // Generate Luna loader compatible entry (ln:* style)
    let luna_client_js = generate_luna_client_entry(islands)
    let luna_client_path = @path.join2(sol_dir, "luna-client-entry.js")
    try {
      @fs.writeFileSync(luna_client_path, @js.any(luna_client_js))
      println(@colorette.gray("  Generated .sol/luna-client-entry.js"))
    } catch {
      e => {
        console_error(@colorette.red("Error writing luna-client-entry.js: \{e}"))
        @process.exit(1)
      }
    }
  }
  // Generate entry.server.js
  let server_js = generate_server_js(components, pages)
  let server_path = @path.join2(sol_dir, "entry.server.js")
  try {
    @fs.writeFileSync(server_path, @js.any(server_js))
    println(@colorette.gray("  Generated .sol/entry.server.js"))
  } catch {
    e => {
      console_error(@colorette.red("Error writing entry.server.js: \{e}"))
      @process.exit(1)
    }
  }
  println(@colorette.green("✓ Generation complete"))
}
