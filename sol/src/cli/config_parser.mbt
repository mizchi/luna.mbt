// Config Parser - Sol configuration types and parsing

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
  /// Auto-generate exports in island moon.pkg (default: true)
  client_auto_exports : Bool
  /// Server runtime for deployment (node, cloudflare, deno, bun)
  runtime : ServerRuntime
  /// Adapter for local dev/serve (defaults to runtime)
  adapter : ServerRuntime
  /// Static directories for SSG (markdown -> HTML)
  static_dirs : Array[StaticDirEntry]
  /// Per-route wasm entrypoints (.mbtx/.wasm)
  wasm_entrypoints : Array[WasmEntrypointConfig]
  /// Experimental feature flags
  experimental : Array[String]
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
  /// Route paths (from path="..." in route definitions)
  route_paths : Array[String]
  /// Action IDs (from ActionDef::new("id", ...) calls)
  action_ids : Array[String]
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
  let route_paths : Array[String] = []
  let action_ids : Array[String] = []
  let empty = RouteInfo::{
    _page_components: page_components,
    _api_handlers: api_handlers,
    route_paths,
    action_ids,
  }
  if !(fs.exists_sync(routes_path)) {
    return empty
  }
  let content = fs.read_file_sync(routes_path) catch { _ => return empty }

  // Find all component="..." values (for Page and Island routes)
  extract_quoted_values(content, "component=\"", page_components)
  // Find all handler="..." values (for API routes)
  extract_quoted_values(content, "handler=\"", api_handlers)
  // Find all path="..." values (route paths for typed constants)
  extract_quoted_values(content, "path=\"", route_paths)
  // Find all segment="..." values (layout segments)
  extract_quoted_values(content, "segment=\"", route_paths)
  // Find all ActionDef::new("id", ...) patterns
  extract_quoted_values(content, "ActionDef::new(\"", action_ids)
  RouteInfo::{
    _page_components: page_components,
    _api_handlers: api_handlers,
    route_paths,
    action_ids,
  }
}

///|
/// Extract quoted string values after a prefix pattern
fn extract_quoted_values(
  content : String,
  prefix : String,
  result : Array[String],
) -> Unit {
  let prefix_len = prefix.length()
  let mut search_pos = 0
  while search_pos < content.length() {
    let remaining = content.unsafe_substring(
      start=search_pos,
      end=content.length(),
    )
    match remaining.find(prefix) {
      Some(start) => {
        let after_key = remaining.unsafe_substring(
          start=start + prefix_len,
          end=remaining.length(),
        )
        match after_key.find("\"") {
          Some(end_idx) => {
            let value = after_key.unsafe_substring(start=0, end=end_idx)
            if !(result.contains(value)) {
              result.push(value)
            }
            search_pos = search_pos + start + prefix_len + end_idx + 1
          }
          None => search_pos = search_pos + start + prefix_len
        }
      }
      None => break
    }
  }
}

///|
/// Check if an experimental feature is enabled
pub fn SolConfig::has_experimental(self : SolConfig, flag : String) -> Bool {
  self.experimental.contains(flag)
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
/// Validate top-level config keys and warn about unknown ones
fn validate_config_keys(obj : Map[String, Json]) -> Unit {
  let valid_keys = [
    "islands", "routes", "output", "clientAutoExports", "client_auto_exports",
    "runtime", "adapter", "staticDirs", "static_dirs", "wasmEntrypoints",
    "wasm_entrypoints", "experimental",
  ]
  for key in obj.keys() {
    if !(valid_keys.contains(key)) {
      println(
        "Warning: unknown config key \"\{key}\" in sol.config.json",
      )
    }
  }
}

///|
/// Parse sol.config.json
pub fn parse_sol_config(json_str : String) -> SolConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    let islands = @json_utils.extract_string_array(obj, "islands")
    let routes = @json_utils.extract_string(obj, "routes", "app/server")
    let output = @json_utils.extract_string(obj, "output", "app/__gen__")
    let client_auto_exports = @json_utils.extract_bool(
      obj, "client_auto_exports", true,
    )
    let runtime = match @json_utils.extract_string_opt(obj, "runtime") {
      Some(s) => parse_runtime(s)
      None => RuntimeNode
    }
    // adapter defaults to same as runtime
    let adapter = match @json_utils.extract_string_opt(obj, "adapter") {
      Some(s) => parse_runtime(s)
      None => runtime
    }
    let static_dirs = parse_static_dirs(obj)
    let wasm_entrypoints = parse_wasm_entrypoints(obj)
    let experimental = @json_utils.extract_string_array(obj, "experimental")
    validate_config_keys(obj)
    Some(SolConfig::{
      islands,
      routes,
      output,
      client_auto_exports,
      runtime,
      adapter,
      static_dirs,
      wasm_entrypoints,
      experimental,
    })
  } catch {
    _ => None
  }
}

// =============================================================================
// TypeScript Config Loader
// =============================================================================

///|
/// FFI to load TypeScript config file using tsx (async for ESM compatibility)
extern "js" fn ffi_load_ts_config(ts_path : String) -> @js.Promise[String] =
  #| async (tsPath) => {
  #|   try {
  #|     const cp = await import('child_process');
  #|     // Use tsx to evaluate the TypeScript config and output JSON
  #|     // Escape the path for use in a require() call
  #|     const escapedPath = tsPath.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
  #|     const script = "const c = require('" + escapedPath + "'); console.log(JSON.stringify(c.default || c));";
  #|     const result = cp.execSync('npx tsx -e "' + script + '"', {
  #|       encoding: 'utf-8',
  #|       stdio: ['pipe', 'pipe', 'pipe']
  #|     });
  #|     return result.trim();
  #|   } catch (e) {
  #|     console.error('Error loading TypeScript config:', e.message);
  #|     return '';
  #|   }
  #| }

///|
/// Load TypeScript config file (sol.config.ts) using tsx
pub async fn load_ts_config(ts_path : String) -> SolConfig? {
  let json_str = ffi_load_ts_config(ts_path).wait()
  if json_str.length() == 0 {
    return None
  }
  parse_sol_config(json_str)
}

///|
/// Load config from sol.config.ts or sol.config.json (TS takes priority)
pub async fn load_config(cwd : String) -> (SolConfig?, String) {
  let fs = @fs_adapter.NodeFsAdapter::new()
  load_config_with_fs(fs, cwd)
}

///|
async fn[FS : @env.FileSystem] load_config_with_fs(
  fs : FS,
  cwd : String,
) -> (SolConfig?, String) {
  let ts_path = @path.join2(cwd, "sol.config.ts")
  let json_path = @path.join2(cwd, "sol.config.json")

  // TypeScript config takes priority
  if fs.exists_sync(ts_path) {
    (load_ts_config(ts_path), ts_path)
  } else if fs.exists_sync(json_path) {
    let content : String = fs.read_file_sync(json_path) catch {
      _ => return (None, json_path)
    }
    (parse_sol_config(content), json_path)
  } else {
    (None, "")
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
          if !(text.is_empty()) && !(link.is_empty()) {
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
    Some(Array(arr)) => {
      let groups : Array[@ssg.SidebarGroup] = []
      for item in arr {
        if item is Object(item_obj) {
          let text = @json_utils.extract_string(item_obj, "text", "")
          let link = @json_utils.extract_string_opt(item_obj, "link")
          let collapsed = @json_utils.extract_bool(item_obj, "collapsed", false)
          let items : Array[@ssg.SidebarItem] = []
          match item_obj.get("items") {
            Some(Array(sub_arr)) =>
              for sub in sub_arr {
                if sub is Object(sub_obj) {
                  let sub_text = @json_utils.extract_string(sub_obj, "text", "")
                  let sub_link = @json_utils.extract_string(sub_obj, "link", "")
                  if !(sub_text.is_empty()) && !(sub_link.is_empty()) {
                    items.push(@ssg.SidebarItem::Link(text=sub_text, link=sub_link))
                  }
                }
              }
            _ => ()
          }
          if !(text.is_empty()) {
            groups.push(@ssg.SidebarGroup::{ text, link, collapsed, items })
          }
        }
      }
      @ssg.SidebarConfig::Manual(groups)
    }
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
/// Extract color option with both camelCase and snake_case support
fn extract_color_opt(
  obj : Map[String, Json],
  camel_key : String,
  snake_key : String,
) -> String? {
  match @json_utils.extract_string_opt(obj, camel_key) {
    Some(v) => Some(v)
    None => @json_utils.extract_string_opt(obj, snake_key)
  }
}

///|
/// Parse theme configuration
fn parse_theme_config(obj : Map[String, Json]) -> @ssg.ThemeConfig {
  match obj.get("theme") {
    Some(Object(theme_obj)) => {
      // Core colors (support both camelCase and snake_case)
      let primary_color = extract_color_opt(
        theme_obj, "primaryColor", "primary_color",
      )
      let secondary_color = extract_color_opt(
        theme_obj, "secondaryColor", "secondary_color",
      )
      let accent_color = extract_color_opt(
        theme_obj, "accentColor", "accent_color",
      )

      // Semantic colors
      let success_color = extract_color_opt(
        theme_obj, "successColor", "success_color",
      )
      let warning_color = extract_color_opt(
        theme_obj, "warningColor", "warning_color",
      )
      let error_color = extract_color_opt(
        theme_obj, "errorColor", "error_color",
      )

      // Text colors
      let text_color = extract_color_opt(theme_obj, "textColor", "text_color")
      let text_muted_color = extract_color_opt(
        theme_obj, "textMutedColor", "text_muted_color",
      )
      let heading_color = extract_color_opt(
        theme_obj, "headingColor", "heading_color",
      )
      let link_color = extract_color_opt(theme_obj, "linkColor", "link_color")
      let link_hover_color = extract_color_opt(
        theme_obj, "linkHoverColor", "link_hover_color",
      )

      // Background colors
      let background_color = extract_color_opt(
        theme_obj, "backgroundColor", "background_color",
      )
      let surface_color = extract_color_opt(
        theme_obj, "surfaceColor", "surface_color",
      )
      let sidebar_bg_color = extract_color_opt(
        theme_obj, "sidebarBgColor", "sidebar_bg_color",
      )
      let input_bg_color = extract_color_opt(
        theme_obj, "inputBgColor", "input_bg_color",
      )
      let code_bg_color = extract_color_opt(
        theme_obj, "codeBgColor", "code_bg_color",
      )

      // UI colors
      let border_color = extract_color_opt(
        theme_obj, "borderColor", "border_color",
      )
      let focus_ring_color = extract_color_opt(
        theme_obj, "focusRingColor", "focus_ring_color",
      )

      // Non-color settings
      let logo = @json_utils.extract_string_opt(theme_obj, "logo")
      let header = parse_header_config(theme_obj)
      let footer = parse_footer_config(theme_obj)
      let social_links = parse_social_links(theme_obj)
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
/// Parse a string to HeaderElement (case-insensitive, unknown maps to Custom)
fn parse_header_element(s : String) -> @ssg.HeaderElement {
  match s.to_lower() {
    "logo" => @ssg.HeaderElement::Logo
    "navlinks" => @ssg.HeaderElement::NavLinks
    "search" => @ssg.HeaderElement::Search
    "themetoggle" => @ssg.HeaderElement::ThemeToggle
    "sociallinks" => @ssg.HeaderElement::SocialLinks
    "langswitcher" => @ssg.HeaderElement::LangSwitcher
    "spacer" => @ssg.HeaderElement::Spacer
    _ => @ssg.HeaderElement::Custom(s)
  }
}

///|
/// Parse header configuration from theme object
fn parse_header_config(obj : Map[String, Json]) -> @ssg.HeaderConfig? {
  match obj.get("header") {
    Some(Object(header_obj)) => {
      let left : Array[@ssg.HeaderElement] = []
      let center : Array[@ssg.HeaderElement] = []
      let right : Array[@ssg.HeaderElement] = []
      match header_obj.get("left") {
        Some(Array(arr)) =>
          for item in arr {
            if item is String(s) {
              left.push(parse_header_element(s))
            }
          }
        _ => ()
      }
      match header_obj.get("center") {
        Some(Array(arr)) =>
          for item in arr {
            if item is String(s) {
              center.push(parse_header_element(s))
            }
          }
        _ => ()
      }
      match header_obj.get("right") {
        Some(Array(arr)) =>
          for item in arr {
            if item is String(s) {
              right.push(parse_header_element(s))
            }
          }
        _ => ()
      }
      let sticky = @json_utils.extract_bool(header_obj, "sticky", false)
      Some(@ssg.HeaderConfig::{ left, center, right, sticky })
    }
    _ => None
  }
}

///|
/// Parse a string to FooterElement (case-insensitive, unknown maps to Custom)
fn parse_footer_element(s : String) -> @ssg.FooterElement {
  match s.to_lower() {
    "columns" => @ssg.FooterElement::Columns
    "message" => @ssg.FooterElement::Message
    "copyright" => @ssg.FooterElement::Copyright
    "sociallinks" => @ssg.FooterElement::SocialLinks
    _ => @ssg.FooterElement::Custom(s)
  }
}

///|
/// Parse footer configuration from theme object
fn parse_footer_config(obj : Map[String, Json]) -> @ssg.FooterConfig? {
  match obj.get("footer") {
    Some(Object(footer_obj)) => {
      let message = @json_utils.extract_string_opt(footer_obj, "message")
      let copyright = @json_utils.extract_string_opt(footer_obj, "copyright")
      let links : Array[@ssg.FooterColumn] = []
      match footer_obj.get("links") {
        Some(Array(arr)) =>
          for item in arr {
            if item is Object(col_obj) {
              let title = @json_utils.extract_string(col_obj, "title", "")
              let col_items : Array[@ssg.FooterLink] = []
              match col_obj.get("items") {
                Some(Array(link_arr)) =>
                  for link_item in link_arr {
                    if link_item is Object(link_obj) {
                      let label = @json_utils.extract_string(
                        link_obj, "label", "",
                      )
                      let href = @json_utils.extract_string(
                        link_obj, "href", "",
                      )
                      if !(label.is_empty()) && !(href.is_empty()) {
                        col_items.push(@ssg.FooterLink::{ label, href })
                      }
                    }
                  }
                _ => ()
              }
              links.push(@ssg.FooterColumn::{ title, items: col_items })
            }
          }
        _ => ()
      }
      let top : Array[@ssg.FooterElement] = []
      match footer_obj.get("top") {
        Some(Array(arr)) =>
          for item in arr {
            if item is String(s) {
              top.push(parse_footer_element(s))
            }
          }
        _ => ()
      }
      let bottom : Array[@ssg.FooterElement] = []
      match footer_obj.get("bottom") {
        Some(Array(arr)) =>
          for item in arr {
            if item is String(s) {
              bottom.push(parse_footer_element(s))
            }
          }
        _ => ()
      }
      Some(@ssg.FooterConfig::{ message, copyright, links, top, bottom })
    }
    _ => None
  }
}

///|
/// Parse social links array from theme object
fn parse_social_links(obj : Map[String, Json]) -> Array[@ssg.SocialLink] {
  let result : Array[@ssg.SocialLink] = []
  match obj.get("socialLinks") {
    Some(Array(arr)) =>
      for item in arr {
        if item is Object(link_obj) {
          let icon = @json_utils.extract_string(link_obj, "icon", "")
          let link = @json_utils.extract_string(link_obj, "link", "")
          if !(icon.is_empty()) && !(link.is_empty()) {
            result.push(@ssg.SocialLink::{ icon, link })
          }
        }
      }
    _ => ()
  }
  result
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
