// sol generate command - Generate __gen__ and .sol directories from sol.config.json
//

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
/// Supported server runtimes
pub enum ServerRuntime {
  RuntimeNode // @hono/node-server (default)
  RuntimeCloudflare // Cloudflare Workers (export default app)
  RuntimeDeno // Deno.serve
  RuntimeBun // Bun.serve
} derive(Eq, Show)

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
  /// Server runtime (node, cloudflare, deno, bun)
  runtime : ServerRuntime
  /// Static directories for SSG (markdown -> HTML)
  static_dirs : Array[StaticDirEntry]
}

///|
/// Static directory configuration entry
pub struct StaticDirEntry {
  /// URL path prefix (e.g., "/docs")
  path_prefix : String
  /// Source directory containing markdown files (e.g., "docs")
  source_dir : String
  /// Section title
  title : String
  /// Navigation items for this section
  nav : Array[@ssg.NavItem]
  /// Sidebar configuration ("auto" or manual)
  sidebar : @ssg.SidebarConfig
  /// Internationalization configuration
  i18n : @ssg.I18nConfig
  /// Navigation config (SPA, View Transitions)
  navigation : @ssg.NavigationConfig
  /// Directories to exclude
  exclude : Array[String]
  /// Use trailing slash
  trailing_slash : Bool
  /// Theme configuration
  theme : @ssg.ThemeConfig
  /// OGP configuration
  ogp : @ssg.OgpConfig
  /// Raw OGP meta tags text (optional)
  ogp_text : String?
  /// Custom HTML snippets to inject at end of <head>
  head_snippets : Array[String]
  /// Custom HTML snippets to inject before </body>
  body_snippets : Array[String]
  /// Custom HTML snippets to inject before </body> (production only)
  prod_body_snippets : Array[String]
}

///|
/// Default static directory entry
pub fn StaticDirEntry::default(
  path_prefix : String,
  source_dir : String,
  title : String,
) -> StaticDirEntry {
  {
    path_prefix,
    source_dir,
    title,
    nav: [],
    sidebar: @ssg.SidebarConfig::Auto,
    i18n: @ssg.I18nConfig::default(),
    navigation: @ssg.NavigationConfig::default(),
    exclude: [],
    trailing_slash: true,
    theme: @ssg.ThemeConfig::default(),
    ogp: @ssg.OgpConfig::default(),
    ogp_text: None,
    head_snippets: [],
    body_snippets: [],
    prod_body_snippets: [],
  }
}

///|
/// Route information extracted from routes.mbt
/// Note: Fields prefixed with _ are for future use
struct RouteInfo {
  /// Page component IDs (from Island and Page routes)
  _page_components : Array[String]
  /// API handler IDs (from Get, Post, etc. routes)
  _api_handlers : Array[String]
}

// =============================================================================
// Routes Parser
// =============================================================================

///|
/// Parse routes.mbt and extract component/handler names
fn parse_routes_file(routes_path : String) -> RouteInfo {
  let fs = @fs_adapter.NodeFsAdapter::new()
  parse_routes_file_with_fs(fs, routes_path)
}

///|
fn[FS : @env.FileSystem] parse_routes_file_with_fs(
  fs : FS,
  routes_path : String,
) -> RouteInfo {
  let page_components : Array[String] = []
  let api_handlers : Array[String] = []
  if not(fs.exists_sync(routes_path)) {
    return RouteInfo::{
      _page_components: page_components,
      _api_handlers: api_handlers,
    }
  }
  let content = fs.read_file_sync(routes_path) catch {
    _ =>
      return RouteInfo::{
        _page_components: page_components,
        _api_handlers: api_handlers,
      }
  }

  // Find all component="..." values (for Page and Island routes)
  // These appear on their own lines in multi-line route definitions
  let mut search_pos = 0
  while search_pos < content.length() {
    let remaining = content.unsafe_substring(
      start=search_pos,
      end=content.length(),
    )
    match remaining.find("component=\"") {
      Some(start) => {
        let after_key = remaining.unsafe_substring(
          start=start + 11,
          end=remaining.length(),
        )
        match after_key.find("\"") {
          Some(end_idx) => {
            let component = after_key.unsafe_substring(start=0, end=end_idx)
            if not(page_components.contains(component)) {
              page_components.push(component)
            }
            search_pos = search_pos + start + 11 + end_idx + 1
          }
          None => search_pos = search_pos + start + 11
        }
      }
      None => break
    }
  }

  // Find all handler="..." values (for API routes)
  search_pos = 0
  while search_pos < content.length() {
    let remaining = content.unsafe_substring(
      start=search_pos,
      end=content.length(),
    )
    match remaining.find("handler=\"") {
      Some(start) => {
        let after_key = remaining.unsafe_substring(
          start=start + 9,
          end=remaining.length(),
        )
        match after_key.find("\"") {
          Some(end_idx) => {
            let handler = after_key.unsafe_substring(start=0, end=end_idx)
            if not(api_handlers.contains(handler)) {
              api_handlers.push(handler)
            }
            search_pos = search_pos + start + 9 + end_idx + 1
          }
          None => search_pos = search_pos + start + 9
        }
      }
      None => break
    }
  }
  RouteInfo::{ _page_components: page_components, _api_handlers: api_handlers }
}

// =============================================================================
// Config Parser
// =============================================================================

///|
/// Parse runtime string to ServerRuntime enum
pub fn parse_runtime(s : String) -> ServerRuntime {
  match s.to_lower() {
    "cloudflare" | "cf" | "workers" => RuntimeCloudflare
    "deno" => RuntimeDeno
    "bun" => RuntimeBun
    _ => RuntimeNode // default
  }
}

///|
/// Parse sol.config.json
pub fn parse_sol_config(json_str : String) -> SolConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    let islands = @json_utils.extract_string_array(obj, "islands")
    let routes = @json_utils.extract_string(obj, "routes", "app/routes")
    let output = @json_utils.extract_string(obj, "output", "app/__gen__")
    let client_auto_exports = @json_utils.extract_bool(
      obj, "client_auto_exports", true,
    )
    let runtime = match @json_utils.extract_string_opt(obj, "runtime") {
      Some(s) => parse_runtime(s)
      None => RuntimeNode
    }
    let static_dirs = parse_static_dirs(obj)
    Some(SolConfig::{
      islands,
      routes,
      output,
      client_auto_exports,
      runtime,
      static_dirs,
    })
  } catch {
    _ => None
  }
}

///|
/// Parse staticDirs array from config
fn parse_static_dirs(obj : Map[String, Json]) -> Array[StaticDirEntry] {
  let result : Array[StaticDirEntry] = []
  match obj.get("staticDirs") {
    Some(Array(arr)) =>
      for item in arr {
        if item is Object(item_obj) {
          match parse_static_dir_entry(item_obj) {
            Some(entry) => result.push(entry)
            None => continue
          }
        }
      }
    _ => ()
  }
  result
}

///|
/// Parse single static directory entry
fn parse_static_dir_entry(obj : Map[String, Json]) -> StaticDirEntry? {
  let path_prefix = match @json_utils.extract_string_opt(obj, "path_prefix") {
    Some(v) => v
    None => return None
  }
  let source_dir = match @json_utils.extract_string_opt(obj, "source_dir") {
    Some(v) => v
    None => return None
  }
  let title = @json_utils.extract_string(obj, "title", "Documentation")
  let nav = parse_nav_items(obj)
  let sidebar = parse_sidebar_config(obj)
  let i18n = parse_i18n_config(obj)
  let navigation = parse_navigation_config(obj)
  let exclude = @json_utils.extract_string_array(obj, "exclude")
  let trailing_slash = @json_utils.extract_bool(obj, "trailing_slash", true)
  let theme = parse_theme_config(obj)
  let ogp = parse_ogp_config(obj)
  let ogp_text = @json_utils.extract_string_opt(obj, "ogpText")
  let head_snippets = @json_utils.extract_string_array(obj, "headSnippets")
  let body_snippets = @json_utils.extract_string_array(obj, "bodySnippets")
  let prod_body_snippets = @json_utils.extract_string_array(
    obj, "prodBodySnippets",
  )
  Some(StaticDirEntry::{
    path_prefix,
    source_dir,
    title,
    nav,
    sidebar,
    i18n,
    navigation,
    exclude,
    trailing_slash,
    theme,
    ogp,
    ogp_text,
    head_snippets,
    body_snippets,
    prod_body_snippets,
  })
}

///|
/// Parse navigation items array
fn parse_nav_items(obj : Map[String, Json]) -> Array[@ssg.NavItem] {
  let result : Array[@ssg.NavItem] = []
  match obj.get("nav") {
    Some(Array(arr)) =>
      for item in arr {
        if item is Object(item_obj) {
          let text = @json_utils.extract_string(item_obj, "text", "")
          let link = @json_utils.extract_string(item_obj, "link", "")
          if not(text.is_empty()) && not(link.is_empty()) {
            result.push(@ssg.NavItem::new(text, link))
          }
        }
      }
    _ => ()
  }
  result
}

///|
/// Parse sidebar configuration
fn parse_sidebar_config(obj : Map[String, Json]) -> @ssg.SidebarConfig {
  match obj.get("sidebar") {
    Some(String("auto")) => @ssg.SidebarConfig::Auto
    Some(String("Auto")) => @ssg.SidebarConfig::Auto
    Some(Array(_)) =>
      // TODO: Parse manual sidebar groups
      @ssg.SidebarConfig::Auto
    _ => @ssg.SidebarConfig::Auto
  }
}

///|
/// Parse i18n configuration
fn parse_i18n_config(obj : Map[String, Json]) -> @ssg.I18nConfig {
  match obj.get("i18n") {
    Some(Object(i18n_obj)) => {
      let default_locale = @json_utils.extract_string(
        i18n_obj, "default_locale", "en",
      )
      let locales : Array[@ssg.LocaleConfig] = []
      match i18n_obj.get("locales") {
        Some(Array(arr)) =>
          for item in arr {
            if item is Object(locale_obj) {
              let code = @json_utils.extract_string(locale_obj, "code", "en")
              let label = @json_utils.extract_string(locale_obj, "label", code)
              let path = @json_utils.extract_string(locale_obj, "path", "")
              locales.push(@ssg.LocaleConfig::{ code, label, path })
            }
          }
        _ => ()
      }
      if locales.is_empty() {
        locales.push(@ssg.LocaleConfig::{
          code: "en",
          label: "English",
          path: "",
        })
      }
      @ssg.I18nConfig::{ default_locale, locales }
    }
    _ => @ssg.I18nConfig::default()
  }
}

///|
/// Parse navigation config
fn parse_navigation_config(obj : Map[String, Json]) -> @ssg.NavigationConfig {
  match obj.get("navigation") {
    Some(Object(nav_obj)) => {
      let spa = @json_utils.extract_bool(nav_obj, "spa", false)
      let view_transitions = @json_utils.extract_bool(
        nav_obj, "view_transitions", true,
      )
      let keyboard = @json_utils.extract_bool(nav_obj, "keyboard", true)
      @ssg.NavigationConfig::{ spa, view_transitions, keyboard }
    }
    _ => @ssg.NavigationConfig::default()
  }
}

///|
/// Parse theme configuration
fn parse_theme_config(obj : Map[String, Json]) -> @ssg.ThemeConfig {
  match obj.get("theme") {
    Some(Object(theme_obj)) => {
      // Core colors
      let primary_color = @json_utils.extract_string_opt(
        theme_obj, "primaryColor",
      )
      let secondary_color = @json_utils.extract_string_opt(
        theme_obj, "secondaryColor",
      )
      let accent_color = @json_utils.extract_string_opt(
        theme_obj, "accentColor",
      )

      // Semantic colors
      let success_color = @json_utils.extract_string_opt(
        theme_obj, "successColor",
      )
      let warning_color = @json_utils.extract_string_opt(
        theme_obj, "warningColor",
      )
      let error_color = @json_utils.extract_string_opt(
        theme_obj, "errorColor",
      )

      // Text colors
      let text_color = @json_utils.extract_string_opt(theme_obj, "textColor")
      let text_muted_color = @json_utils.extract_string_opt(
        theme_obj, "textMutedColor",
      )
      let heading_color = @json_utils.extract_string_opt(
        theme_obj, "headingColor",
      )
      let link_color = @json_utils.extract_string_opt(theme_obj, "linkColor")
      let link_hover_color = @json_utils.extract_string_opt(
        theme_obj, "linkHoverColor",
      )

      // Background colors
      let background_color = @json_utils.extract_string_opt(
        theme_obj, "backgroundColor",
      )
      let surface_color = @json_utils.extract_string_opt(
        theme_obj, "surfaceColor",
      )
      let sidebar_bg_color = @json_utils.extract_string_opt(
        theme_obj, "sidebarBgColor",
      )
      let input_bg_color = @json_utils.extract_string_opt(
        theme_obj, "inputBgColor",
      )
      let code_bg_color = @json_utils.extract_string_opt(
        theme_obj, "codeBgColor",
      )

      // UI colors
      let border_color = @json_utils.extract_string_opt(
        theme_obj, "borderColor",
      )
      let focus_ring_color = @json_utils.extract_string_opt(
        theme_obj, "focusRingColor",
      )

      // Non-color settings
      let logo = @json_utils.extract_string_opt(theme_obj, "logo")
      let header : @ssg.HeaderConfig? = None // TODO: parse header
      let footer : @ssg.FooterConfig? = None // TODO: parse footer
      let social_links : Array[@ssg.SocialLink] = [] // TODO: parse social links
      @ssg.ThemeConfig::{
        primary_color,
        secondary_color,
        accent_color,
        success_color,
        warning_color,
        error_color,
        text_color,
        text_muted_color,
        heading_color,
        link_color,
        link_hover_color,
        background_color,
        surface_color,
        sidebar_bg_color,
        input_bg_color,
        code_bg_color,
        border_color,
        focus_ring_color,
        logo,
        header,
        footer,
        social_links,
      }
    }
    _ => @ssg.ThemeConfig::default()
  }
}

///|
/// Parse OGP configuration
fn parse_ogp_config(obj : Map[String, Json]) -> @ssg.OgpConfig {
  match obj.get("ogp") {
    Some(Object(ogp_obj)) => {
      let site_url = @json_utils.extract_string_opt(ogp_obj, "site_url")
      let image = @json_utils.extract_string_opt(ogp_obj, "image")
      let twitter_handle = @json_utils.extract_string_opt(
        ogp_obj, "twitter_handle",
      )
      let twitter_card = @json_utils.extract_string_opt(ogp_obj, "twitter_card")
      @ssg.OgpConfig::{ site_url, image, twitter_handle, twitter_card }
    }
    _ => @ssg.OgpConfig::default()
  }
}

///|
/// Get project name from moon.mod.json
fn get_project_name(cwd : String) -> String {
  let fs = @fs_adapter.NodeFsAdapter::new()
  get_project_name_with_fs(fs, cwd)
}

///|
fn[FS : @env.FileSystem] get_project_name_with_fs(
  fs : FS,
  cwd : String,
) -> String {
  let mod_path = @path.join2(cwd, "moon.mod.json")
  if not(fs.exists_sync(mod_path)) {
    return "unknown"
  }
  try {
    let content = fs.read_file_sync(mod_path)
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
        if after_first.find("\"") is Some(end_quote) {
          let pkg_path = after_first.unsafe_substring(start=0, end=end_quote)
          // Extract alias (last part of path)
          let parts = pkg_path.split("/").to_array()
          if parts.length() > 0 {
            let alias_part = parts[parts.length() - 1].to_string()
            result[alias_part] = pkg_path
          }
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
    let trimmed = line_str.trim_start(chars=" \t").to_string()
    // Look for "pub fn name(...) -> RetType"
    if trimmed.has_prefix("pub fn ") {
      let rest = trimmed.unsafe_substring(start=7, end=trimmed.length()) // After "pub fn "
      // Find function name (up to first '(')
      if rest.find("(") is Some(paren_idx) {
        let name = rest.unsafe_substring(start=0, end=paren_idx)
        // Get signature (from '(' to end of line)
        let sig = rest.unsafe_substring(start=paren_idx, end=rest.length())
        // Rewrite type references
        let rewritten_sig = rewrite_type_refs(sig, imports)
        result.push((name, rewritten_sig))
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
  let fs = @fs_adapter.NodeFsAdapter::new()
  find_mbti_files_with_fs(fs, cwd, patterns)
}

///|
fn[FS : @env.FileSystem] find_mbti_files_with_fs(
  fs : FS,
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
      if fs.exists_sync(parent) {
        try {
          let entries = fs.readdir_sync(parent)
          for entry in entries {
            let entry_path = @path.join2(parent, entry)
            let mbti_path = @path.join2(entry_path, "pkg.generated.mbti")
            if fs.exists_sync(mbti_path) {
              let content = fs.read_file_sync(mbti_path)
              // For glob patterns, use the actual subdirectory as the pattern
              let sub_pattern = pattern.substring(end=pattern.length() - 2) +
                "/" +
                entry.to_string()
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
      if fs.exists_sync(mbti_path) {
        try {
          let content = fs.read_file_sync(mbti_path)
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
    let trimmed = line_str.trim_start(chars=" \t").to_string()
    if trimmed.has_prefix("package \"") {
      let start = 9 // len of 'package "'
      let after_prefix = trimmed.unsafe_substring(start~, end=trimmed.length())
      if after_prefix.find("\"") is Some(end_quote) {
        return Some(trimmed.unsafe_substring(start~, end=end_quote + start))
      }
    }
  }
  None
}

// =============================================================================
// Code Generators
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
    buf.write_string(
      "// =============================================================================\n",
    )
    buf.write_string("// ComponentRef Factory Functions\n")
    buf.write_string(
      "// =============================================================================\n\n",
    )
  }
  for s in structs {
    let component_name = extract_component_name_from_props(s.name)
    let url = "/static/\{component_name}.js"
    let is_wc = is_web_component(component_name)
    buf.write_string("///|\n")
    buf.write_string(
      "///| Create ComponentRef for \{component_name} component\n",
    )
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
  buf.write_string(
    "    { \"path\": \"mizchi/luna/luna\", \"alias\": \"luna\" }\n",
  )
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
/// Generate hydrate functions for __gen__/client/__gen__.mbt
/// These functions import from user's client package via @client alias
fn generate_hydrate_mbt(
  funcs : Array[FuncExport],
  client_alias : String,
) -> String {
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
        "///| When is_rerender is true, performs full re-render instead of hydration\n",
      )
      buf.write_string(
        "pub fn __sol_internal__client_\{func.name}(element : @js.Any, state : @js.Any, _id : String, is_rerender : Bool) -> Unit {\n",
      )
      buf.write_string("  let jsdom_el : @js_dom.Element = element.cast()\n")
      buf.write_string(
        "  // state is already a JS object from JSON.parse in loader\n",
      )
      buf.write_string(
        "  // Direct cast via FFI identity - JS object matches MoonBit struct layout\n",
      )
      buf.write_string(
        "  let props : @\{client_alias}.\{props_type} = @js.identity(state)\n",
      )
      buf.write_string("  let node = @\{client_alias}.\{func.name}(props)\n")
      buf.write_string("  // Auto-detect WC (shadowRoot) vs Luna mode\n")
      if returns_dom_node {
        buf.write_string(
          "  @wc.hydrate_auto_dom(jsdom_el, node, is_rerender~)\n",
        )
      } else {
        buf.write_string("  @wc.hydrate_auto(jsdom_el, node, is_rerender~)\n")
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
/// Read module name and source from moon.mod.json
/// Returns (name, source) tuple
fn read_mod_info(mod_json_path : String) -> (String, String) {
  let fs = @fs_adapter.NodeFsAdapter::new()
  read_mod_info_with_fs(fs, mod_json_path)
}

///|
fn[FS : @env.FileSystem] read_mod_info_with_fs(
  fs : FS,
  mod_json_path : String,
) -> (String, String) {
  let content : String = fs.read_file_sync(mod_json_path) catch {
    _ => return ("", "")
  }
  if content.length() == 0 {
    return ("", "")
  }
  let json = @json.parse(content.view()) catch { _ => return ("", "") }
  match json {
    Object(obj) => {
      let name = match obj.get("name") {
        Some(String(n)) => n
        _ => ""
      }
      let source = match obj.get("source") {
        Some(String(s)) => s
        _ => ""
      }
      (name, source)
    }
    _ => ("", "")
  }
}

///|
/// Required imports for hydrate functions (runtime dependencies only)
let hydrate_required_imports : Array[(String, String)] = [
  ("mizchi/js/core", "js"),
  ("mizchi/js/browser/dom", "js_dom"),
  ("mizchi/luna/luna/dom", "wc"),
]

///|
/// Generate moon.pkg.json for __gen__/client/ directory
fn generate_client_gen_pkg_json(
  client_pkg_path : String,
  client_alias : String,
  exports : Array[String],
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"supported-targets\": [\"js\"],\n")
  buf.write_string("  \"import\": [\n")
  // Add user's client package import
  buf.write_string(
    "    { \"path\": \"\{client_pkg_path}\", \"alias\": \"\{client_alias}\" },\n",
  )
  // Add runtime imports
  for i, item in hydrate_required_imports {
    let (pkg_path, pkg_alias) = item
    buf.write_string(
      "    { \"path\": \"\{pkg_path}\", \"alias\": \"\{pkg_alias}\" }",
    )
    if i < hydrate_required_imports.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  ],\n")
  buf.write_string("  \"link\": {\n")
  buf.write_string("    \"js\": {\n")
  buf.write_string("      \"exports\": [")
  for i, name in exports {
    buf.write_string("\"\{name}\"")
    if i < exports.length() - 1 {
      buf.write_string(", ")
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
/// Read exports from moon.pkg.json (for user-managed exports mode)
fn read_exports_from_pkg_json(pkg_json_path : String) -> Array[String] {
  let fs = @fs_adapter.NodeFsAdapter::new()
  read_exports_from_pkg_json_with_fs(fs, pkg_json_path)
}

///|
fn[FS : @env.FileSystem] read_exports_from_pkg_json_with_fs(
  fs : FS,
  pkg_json_path : String,
) -> Array[String] {
  let content : String = fs.read_file_sync(pkg_json_path) catch {
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

///|
/// Convert snake_case to PascalCase
fn snake_to_pascal(s : String) -> String {
  let buf = StringBuilder::new()
  let mut capitalize_next = true
  for c in s {
    if c == '_' {
      capitalize_next = true
    } else if capitalize_next {
      if c >= 'a' && c <= 'z' {
        buf.write_char(Char::from_int(c.to_int() - 32))
      } else {
        buf.write_char(c)
      }
      capitalize_next = false
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Generate server main.mbt
fn generate_server_main_mbt(
  routes_pkg : String,
  route_info : RouteInfo,
  static_dirs : Array[StaticDirEntry],
) -> String {
  let _ = routes_pkg
  let _ = route_info
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated server entry point\n")
  buf.write_string("///| Generated by: sol generate\n")
  buf.write_string("///|\n")
  buf.write_string(
    "///| DO NOT EDIT - This file is auto-generated from server/routes.mbt\n\n",
  )
  buf.write_string("///| Configure the application using typed routes\n")
  buf.write_string("pub fn configure_app(app : @sol.App) -> @sol.App {\n")
  buf.write_string("  // Get routes and config from server/routes.mbt\n")
  buf.write_string("  let routes = @app_server.routes()\n")
  buf.write_string("  let config = @app_server.config()\n\n")
  buf.write_string(
    "  // Register routes with typed handlers (no resolver needed)\n",
  )
  buf.write_string(
    "  let app = @router.register_sol_routes(app, routes, config=config)\n\n",
  )
  buf.write_string(
    "  // Register Server Actions (if action_registry is defined in routes.mbt)\n",
  )
  buf.write_string(
    "  let app = @action.register_actions(app, @app_server.action_registry())\n\n",
  )

  // Generate static directory routes
  if not(static_dirs.is_empty()) {
    buf.write_string("  // Serve static directories (SSG)\n")
    for entry in static_dirs {
      let path_prefix = entry.path_prefix
      let source_dir = entry.source_dir
      buf.write_string(
        "  let app = @sol.serve_static_dir(app, @sol.StaticDirServeConfig::new(\"\{path_prefix}\", \"\{source_dir}\"))\n",
      )
    }
    buf.write_string("\n")
  }
  buf.write_string("  // Serve static files\n")
  buf.write_string("  @sol.serve_static(app)\n")
  buf.write_string("}\n\n")
  buf.write_string("///|\n")
  buf.write_string("fn main {\n")
  buf.write_string("  @sol.run(configure_app)\n")
  buf.write_string("}\n")
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
    "    { \"path\": \"mizchi/luna/sol/action\", \"alias\": \"action\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"mizchi/js/core\", \"alias\": \"core\" },\n",
  )
  buf.write_string(
    "    { \"path\": \"\{routes_pkg}\", \"alias\": \"app_server\" }\n",
  )
  buf.write_string("  ],\n")
  buf.write_string("  \"link\": {\n")
  buf.write_string("    \"js\": {\n")
  buf.write_string("      \"exports\": [\"configure_app\"],\n")
  buf.write_string("      \"format\": \"esm\"\n")
  buf.write_string("    }\n")
  buf.write_string("  },\n")
  buf.write_string("  \"warn-list\": \"-29\"\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Generate client entry JS file (new architecture)
/// Path: .sol/{mode}/client/{name}.js
/// - Component function: from target/js/release/build/{relative_path}/pkg.js (user's client package)
/// - Hydrate function: from target/js/release/build/__gen__/client/client.js (generated)
/// relative_path: path with source prefix removed (e.g., "client" not "app/client")
fn generate_island_entry_js_v2(
  func : FuncExport,
  include_hydrate : Bool,
  relative_path : String,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Client entry for: \{func.name}\n")
  buf.write_string("// Generated by: sol generate\n\n")
  // Path from .sol/{mode}/client/ to target/ is ../../../target/
  // Component: from user's client package (e.g., client - without source prefix)
  // Hydrate: from generated __gen__/client package
  let pkg_name = relative_path.split("/").last().unwrap_or(relative_path)
  let client_path = "../../../target/js/release/build/\{relative_path}/\{pkg_name}.js"
  let hydrate_path = "../../../target/js/release/build/__gen__/client/client.js"
  if include_hydrate {
    buf.write_string("import { \{func.name} } from '\{client_path}';\n")
    buf.write_string(
      "import { __sol_internal__client_\{func.name} as hydrate } from '\{hydrate_path}';\n\n",
    )
    buf.write_string("export { \{func.name}, hydrate };\n")
    buf.write_string("export default hydrate;\n")
  } else {
    buf.write_string("import { \{func.name} } from '\{client_path}';\n\n")
    buf.write_string("export { \{func.name} };\n")
    buf.write_string("export default \{func.name};\n")
  }
  buf.to_string()
}

///|
/// Generate island manifest JSON (for programmatic rolldown build)
fn generate_island_manifest_json(
  funcs : Array[FuncExport],
  mode : String,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"output_dir\": \"./.sol/\{mode}/static\",\n")
  buf.write_string("  \"islands\": [\n")
  for i, func in funcs {
    buf.write_string(
      "    { \"name\": \"\{func.name}\", \"entry_path\": \"./.sol/\{mode}/client/\{func.name}.js\" }",
    )
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
pub fn generate_sol_server_main_js(
  routes_pkg : String,
  runtime : ServerRuntime,
) -> String {
  let _ = routes_pkg
  let buf = StringBuilder::new()
  buf.write_string("// Server entry point\n")
  buf.write_string("// Generated by: sol generate\n")
  buf.write_string("// Runtime: \{runtime}\n\n")
  // Generate runtime-specific entry point
  match runtime {
    RuntimeNode => {
      buf.write_string(
        "import * as server from '../../../target/js/release/build/__gen__/server/server.js';\n\n",
      )
      buf.write_string("// Node.js runtime using @hono/node-server\n")
      buf.write_string(
        "// The server module already handles startup via @sol.run()\n",
      )
      buf.write_string(
        "export * from '../../../target/js/release/build/__gen__/server/server.js';\n",
      )
    }
    RuntimeCloudflare => {
      // Cloudflare Workers: Import Hono and configure app directly
      buf.write_string("import { Hono } from 'hono';\n")
      buf.write_string(
        "import { configure_app } from '../../../target/js/release/build/__gen__/server/server.js';\n\n",
      )
      buf.write_string("// Cloudflare Workers runtime\n")
      buf.write_string(
        "// Create and configure Hono app directly (no Node.js APIs)\n",
      )
      buf.write_string("const app = configure_app(new Hono());\n\n")
      buf.write_string("export default app;\n")
    }
    RuntimeDeno => {
      buf.write_string("import { Hono } from 'hono';\n")
      buf.write_string(
        "import { configure_app } from '../../../target/js/release/build/__gen__/server/server.js';\n\n",
      )
      buf.write_string("// Deno runtime\n")
      buf.write_string("const app = configure_app(new Hono());\n")
      buf.write_string(
        "const port = parseInt(Deno.env.get('PORT') || '3000', 10);\n",
      )
      buf.write_string(
        "console.log(`Server running at http://localhost:${port}`);\n",
      )
      buf.write_string("Deno.serve({ port }, app.fetch);\n")
    }
    RuntimeBun => {
      buf.write_string("import { Hono } from 'hono';\n")
      buf.write_string(
        "import { configure_app } from '../../../target/js/release/build/__gen__/server/server.js';\n\n",
      )
      buf.write_string("// Bun runtime\n")
      buf.write_string("const app = configure_app(new Hono());\n")
      buf.write_string(
        "const port = parseInt(process.env.PORT || '3000', 10);\n",
      )
      buf.write_string(
        "console.log(`Server running at http://localhost:${port}`);\n",
      )
      buf.write_string("export default {\n")
      buf.write_string("  port,\n")
      buf.write_string("  fetch: app.fetch\n")
      buf.write_string("};\n")
    }
  }
  buf.to_string()
}

// =============================================================================
// Main Generate Command (New Architecture)
// =============================================================================

///|
fn run_generate_command(args : Array[String]) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_generate_command_with_fs(fs, args)
}

///|
fn[FS : @env.FileSystem] run_generate_command_with_fs(
  fs : FS,
  args : Array[String],
) -> Unit {
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(
        key="config",
        short="c",
        multiple=false,
        default=Some("sol.config.json"),
      ),
      @util.String(key="mode", short="m", multiple=false, default=Some("prod")),
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
  if not(fs.exists_sync(full_config_path)) {
    @cli_common.console_error(
      @colorette.red("Error: Config file not found: \{config_path}"),
    )
    @process.exit(1)
  }
  let config_content : String = fs.read_file_sync(full_config_path) catch {
    e => {
      @cli_common.console_error(@colorette.red("Error reading config: \{e}"))
      @process.exit(1)
      "" // unreachable
    }
  }
  guard parse_sol_config(config_content) is Some(config) else {
    @cli_common.console_error(
      @colorette.red("Error: Invalid config file format"),
    )
    @process.exit(1)
  }
  println(@colorette.cyan("Generating app/__gen__ and .sol directories..."))
  let runtime_name = match config.runtime {
    RuntimeNode => "node"
    RuntimeCloudflare => "cloudflare"
    RuntimeDeno => "deno"
    RuntimeBun => "bun"
  }
  println(@colorette.gray("  Runtime: \{runtime_name}"))
  // Create output directories first (needed for types)
  let output_dir = @path.join2(cwd, config.output) // app/__gen__
  let types_dir = @path.join2(output_dir, "types")
  fs.mkdir_sync(types_dir, true) catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error creating types directory: \{e}"),
      )
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
      fs.write_file_sync(types_mbt_path, types_mbt_content)
      fs.write_file_sync(types_pkg_path, types_pkg_content)
      println(@colorette.gray("  Generated __gen__/types/ from source"))
    } catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error writing types package: \{e}"),
        )
        @process.exit(1)
      }
    }
  } else {
    // Create empty stub if no Props found
    let stub_types_mbt_path = @path.join2(types_dir, "types.mbt")
    let stub_types_pkg_path = @path.join2(types_dir, "moon.pkg.json")
    if not(fs.exists_sync(stub_types_mbt_path)) {
      try {
        fs.write_file_sync(stub_types_mbt_path, "///| No Props types found\n")
        fs.write_file_sync(
          stub_types_pkg_path, "{\n  \"supported-targets\": [\"js\"],\n  \"warn-list\": \"-29\"\n}\n",
        )
      } catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error writing stub types: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
  }
  // Step 2.5: Pre-create server moon.pkg.json with warn-list (before moon info)
  // This ensures warnings are suppressed during moon info
  let server_dir = @path.join2(output_dir, "server")
  fs.mkdir_sync(server_dir, true) catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error creating server directory: \{e}"),
      )
      @process.exit(1)
    }
  }
  let routes_pkg = get_routes_package_path(cwd, config.routes)
  let server_pkg = generate_server_pkg_json(routes_pkg)
  let server_pkg_path = @path.join2(server_dir, "moon.pkg.json")
  fs.write_file_sync(server_pkg_path, server_pkg) catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error writing server/moon.pkg.json: \{e}"),
      )
      @process.exit(1)
    }
  }
  // Create stub main.mbt so is-main: true doesn't fail
  let stub_main_path = @path.join2(server_dir, "main.mbt")
  fs.write_file_sync(
    stub_main_path, "///| Stub - will be replaced\nfn main { () }\n",
  ) catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error writing stub main.mbt: \{e}"),
      )
      @process.exit(1)
    }
  }
  // Step 3: Collect island exports
  // If client_auto_exports is true, run moon info and parse mbti
  // If client_auto_exports is false, read exports from moon.pkg.json (faster)
  let funcs : Array[FuncExport] = if config.client_auto_exports {
    println(@colorette.gray("  Running moon info..."))
    try {
      let info_result = @child_process.spawnSync(
        "moon",
        args=["info", "--target", "js"],
        stdio="inherit",
      )
      if info_result.status() != Some(0) {
        @cli_common.console_error(@colorette.red("moon info failed"))
        @process.exit(1)
      }
    } catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error running moon info: \{e}"),
        )
        @process.exit(1)
      }
    }
    // Collect all pub functions from island directories (using mbti)
    collect_island_functions(cwd, config)
  } else {
    // User-managed exports mode: read from moon.pkg.json directly
    println(
      @colorette.gray("  Reading exports from moon.pkg.json (user-managed)..."),
    )
    let result : Array[FuncExport] = []
    for island_pattern in config.islands {
      let island_dir = @path.join2(cwd, island_pattern)
      let pkg_json_path = @path.join2(island_dir, "moon.pkg.json")
      let exports = read_exports_from_pkg_json(pkg_json_path)
      for export_name in exports {
        // Skip __sol_internal__client_* exports (they are generated, not source functions)
        if not(export_name.has_prefix("__sol_internal__client_")) {
          result.push(func_export_from_name(export_name, island_pattern))
        }
      }
    }
    result
  }
  println(@colorette.gray("  Found \{funcs.length()} island exports"))
  // Create remaining output directories (types_dir and server_dir already created above)
  // Use mode-specific .sol directory: .sol/dev or .sol/prod
  let sol_dir = @path.join2(@path.join2(cwd, ".sol"), mode)
  let sol_client_dir = @path.join2(sol_dir, "client")
  let sol_server_dir = @path.join2(sol_dir, "server")
  try {
    fs.mkdir_sync(sol_client_dir, true)
    fs.mkdir_sync(sol_server_dir, true)
  } catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error creating directories: \{e}"),
      )
      @process.exit(1)
    }
  }
  // Get module name and source from moon.mod.json (needed for both __gen__/client and JS entries)
  let mod_json_path = @path.join2(cwd, "moon.mod.json")
  let (mod_name, source_dir) = read_mod_info(mod_json_path)
  // Generate hydrate functions in __gen__/client/ directory
  // This separates generated code from user's client code
  if not(funcs.is_empty()) {
    // Create __gen__/client directory
    let client_gen_dir = @path.join2(output_dir, "client")
    fs.mkdir_sync(client_gen_dir, true) catch {
      _ => ()
    }
    // Group functions by source_pattern (for now assume single client pattern)
    let patterns_seen : Map[String, Bool] = {}
    for f in funcs {
      patterns_seen[f.source_pattern] = true
    }
    // For each island pattern, determine client package path
    for island_pattern in patterns_seen.keys() {
      let island_funcs = funcs.filter(fn(f) {
        f.source_pattern == island_pattern
      })
      if island_funcs.is_empty() {
        continue
      }
      // Construct client package path
      // If source is set (e.g., "app"), remove it from island_pattern
      // island_pattern: "app/client" -> relative_path: "client" (when source="app")
      let relative_path = if source_dir.length() > 0 &&
        island_pattern.has_prefix(source_dir) {
        let prefix_len = source_dir.length()
        // Remove source_dir prefix and leading slash
        if island_pattern.length() > prefix_len + 1 {
          island_pattern.substring(start=prefix_len + 1)
        } else {
          island_pattern
        }
      } else {
        island_pattern
      }
      let client_pkg_path = if mod_name.length() > 0 {
        "\{mod_name}/\{relative_path}"
      } else {
        relative_path
      }
      let client_alias_name = "app_client"
      // Collect export names for __sol_internal__client_* functions only
      let export_names : Array[String] = []
      for f in island_funcs {
        let props_type = extract_props_type(f.signature, "")
        let returns_dom_node = f.signature.contains("DomNode")
        let returns_vnode = f.signature.contains("Node[")
        if props_type.length() > 0 && (returns_dom_node || returns_vnode) {
          export_names.push("__sol_internal__client_\{f.name}")
        }
      }
      // Generate __gen__.mbt with client alias references
      let hydrate_content = generate_hydrate_mbt(
        island_funcs, client_alias_name,
      )
      let hydrate_path = @path.join2(client_gen_dir, "__gen__.mbt")
      try {
        fs.write_file_sync(hydrate_path, hydrate_content)
        println(@colorette.gray("  Generated __gen__/client/__gen__.mbt"))
      } catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error writing __gen__/client/__gen__.mbt: \{e}"),
          )
          @process.exit(1)
        }
      }
      // Generate moon.pkg.json for __gen__/client/
      let pkg_json_content = generate_client_gen_pkg_json(
        client_pkg_path, client_alias_name, export_names,
      )
      let pkg_json_path = @path.join2(client_gen_dir, "moon.pkg.json")
      try {
        fs.write_file_sync(pkg_json_path, pkg_json_content)
        println(@colorette.gray("  Generated __gen__/client/moon.pkg.json"))
      } catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error writing __gen__/client/moon.pkg.json: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
  }
  // Parse routes.mbt to extract component/handler info
  let routes_file_path = @path.join2(
    @path.join2(cwd, config.routes),
    "routes.mbt",
  )
  let route_info = parse_routes_file(routes_file_path)
  // Generate server main.mbt
  let server_main = generate_server_main_mbt(
    routes_pkg,
    route_info,
    config.static_dirs,
  )
  let server_main_path = @path.join2(server_dir, "main.mbt")
  try {
    fs.write_file_sync(server_main_path, server_main)
    println(@colorette.gray("  Generated __gen__/server/main.mbt"))
  } catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error writing server/main.mbt: \{e}"),
      )
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
      // Calculate relative_path by removing source_dir prefix from source_pattern
      let relative_path = if source_dir.length() > 0 &&
        func.source_pattern.has_prefix(source_dir) {
        let prefix_len = source_dir.length()
        if func.source_pattern.length() > prefix_len + 1 {
          func.source_pattern.substring(start=prefix_len + 1)
        } else {
          func.source_pattern
        }
      } else {
        func.source_pattern
      }
      let island_entry_content = generate_island_entry_js_v2(
        func, include_hydrate, relative_path,
      )
      let island_entry_path = @path.join2(sol_client_dir, "\{func.name}.js")
      fs.write_file_sync(island_entry_path, island_entry_content) catch {
        e => {
          @cli_common.console_error(
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
      fs.write_file_sync(manifest_path, manifest_content)
      println(@colorette.gray("  Generated .sol/\{mode}/manifest.json"))
    } catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error writing manifest.json: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  // Generate .sol/{mode}/server/main.js (server entry point)
  let server_main_js = generate_sol_server_main_js(routes_pkg, config.runtime)
  let server_main_js_path = @path.join2(sol_server_dir, "main.js")
  try {
    fs.write_file_sync(server_main_js_path, server_main_js)
    println(@colorette.gray("  Generated .sol/\{mode}/server/main.js"))
  } catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error writing .sol/\{mode}/server/main.js: \{e}"),
      )
      @process.exit(1)
    }
  }
  println(@colorette.green("✓ Generation complete"))
}

///|
/// Get routes package path from moon.mod.json
fn get_routes_package_path(cwd : String, routes_dir : String) -> String {
  let fs = @fs_adapter.NodeFsAdapter::new()
  get_routes_package_path_with_fs(fs, cwd, routes_dir)
}

///|
fn[FS : @env.FileSystem] get_routes_package_path_with_fs(
  fs : FS,
  cwd : String,
  routes_dir : String,
) -> String {
  // Read moon.mod.json to get package name
  let mod_path = @path.join2(cwd, "moon.mod.json")
  if fs.exists_sync(mod_path) {
    try {
      let content = fs.read_file_sync(mod_path)
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
