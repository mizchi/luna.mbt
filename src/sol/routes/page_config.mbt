// Page Configuration (page.json)
//
// Defines the configuration schema for page.json files.

// =============================================================================
// Page Config
// =============================================================================

///|
/// Configuration from page.json
pub(all) struct PageConfig {
  /// Rendering mode: "static" | "ssr" | "isr" | "spa"
  mode : String?
  /// ISR revalidation interval in seconds
  revalidate : Int?
  /// Page title
  title : String?
  /// Page description
  description : String?
  /// Layout identifier
  layout : String?
  /// Islands to hydrate on client
  islands : Array[String]
  /// Generate static params for dynamic routes (deprecated, use static_params)
  generate_params : Bool
  /// Static parameters for pre-generation (replaces generate_params)
  static_params : Array[Map[String, String]]
  /// Enable SPA fallback for this route
  fallback : Bool
  /// Enable SPA mode for this segment (client-side routing within)
  spa : Bool
  /// Fallback behavior for unmatched routes: "spa" or "404"
  fallback_behavior : String?
  /// Parent config to extend
  extends : String?
  /// File type specific handlers
  handlers : Map[String, FileHandlerConfig]
  /// Component directory configuration
  component : ComponentConfig?
}

///|
/// Component directory configuration (for moon.pkg.json directories)
pub(all) struct ComponentConfig {
  /// Enable server-side rendering for this component
  ssr : Bool
  /// Props struct name (e.g., "CounterProps")
  props_type : String?
  /// Client export function name (e.g., "counter")
  client_export : String?
  /// Server export function name (e.g., "render_ssr")
  server_export : String?
}

///|
/// File handler configuration
pub(all) struct FileHandlerConfig {
  /// Layout for this file type
  layout : String?
  /// Islands for this file type
  islands : Array[String]
  /// Pass through without processing
  passthrough : Bool
}

// =============================================================================
// Defaults
// =============================================================================

///|
/// Default page config
pub fn PageConfig::default() -> PageConfig {
  {
    mode: None,
    revalidate: None,
    title: None,
    description: None,
    layout: None,
    islands: [],
    generate_params: false,
    static_params: [],
    fallback: false,
    spa: false,
    fallback_behavior: None,
    extends: None,
    handlers: {},
    component: None,
  }
}

///|
/// Default file handler config
pub fn FileHandlerConfig::default() -> FileHandlerConfig {
  { layout: None, islands: [], passthrough: false }
}

///|
/// Default component config
pub fn ComponentConfig::default() -> ComponentConfig {
  { ssr: false, props_type: None, client_export: None, server_export: None }
}

// =============================================================================
// Parsing
// =============================================================================

///|
/// Parse page.json content
pub fn parse_page_config(json_str : String) -> PageConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    parse_page_config_object(obj)
  } catch {
    _ => None
  }
}

///|
/// Parse page config from JSON object
fn parse_page_config_object(obj : Map[String, Json]) -> PageConfig? {
  let mode = @json_utils.extract_string_opt(obj, "mode")
  let revalidate = @json_utils.extract_int_opt(obj, "revalidate")
  let title = @json_utils.extract_string_opt(obj, "title")
  let description = @json_utils.extract_string_opt(obj, "description")
  let layout = @json_utils.extract_string_opt(obj, "layout")
  let islands = @json_utils.extract_string_array(obj, "islands")
  let generate_params = @json_utils.extract_bool(obj, "generateParams", false)
  let static_params = parse_static_params(obj)
  let fallback = @json_utils.extract_bool(obj, "fallback", false)
  let spa = @json_utils.extract_bool(obj, "spa", false)
  let fallback_behavior = @json_utils.extract_string_opt(
    obj, "fallbackBehavior",
  )
  let extends = @json_utils.extract_string_opt(obj, "extends")
  let handlers = parse_handlers(obj)
  let component = parse_component_config(obj)
  Some(PageConfig::{
    mode,
    revalidate,
    title,
    description,
    layout,
    islands,
    generate_params,
    static_params,
    fallback,
    spa,
    fallback_behavior,
    extends,
    handlers,
    component,
  })
}

///|
/// Parse staticParams array from config
fn parse_static_params(obj : Map[String, Json]) -> Array[Map[String, String]] {
  let result : Array[Map[String, String]] = []
  match obj.get("staticParams") {
    Some(Array(arr)) =>
      for item in arr {
        if item is Object(param_obj) {
          let param_map : Map[String, String] = {}
          for k, v in param_obj {
            if v is String(s) {
              param_map[k] = s
            } else if v is Number(n, ..) {
              param_map[k] = n.to_string()
            }
          }
          result.push(param_map)
        }
      }
    _ => ()
  }
  result
}

///|
/// Parse component config from page.json
fn parse_component_config(obj : Map[String, Json]) -> ComponentConfig? {
  match obj.get("component") {
    Some(Object(comp_obj)) =>
      Some(ComponentConfig::{
        ssr: @json_utils.extract_bool(comp_obj, "ssr", false),
        props_type: @json_utils.extract_string_opt(comp_obj, "propsType"),
        client_export: @json_utils.extract_string_opt(comp_obj, "clientExport"),
        server_export: @json_utils.extract_string_opt(comp_obj, "serverExport"),
      })
    _ => None
  }
}

///|
/// Parse file handlers from config
fn parse_handlers(obj : Map[String, Json]) -> Map[String, FileHandlerConfig] {
  let result : Map[String, FileHandlerConfig] = {}
  match obj.get("handlers") {
    Some(Object(handlers_obj)) =>
      for k, v in handlers_obj {
        if v is Object(handler_obj) {
          let config = FileHandlerConfig::{
            layout: @json_utils.extract_string_opt(handler_obj, "layout"),
            islands: @json_utils.extract_string_array(handler_obj, "islands"),
            passthrough: @json_utils.extract_bool(
              handler_obj, "passthrough", false,
            ),
          }
          result[k] = config
        }
      }
    _ => ()
  }
  result
}

// =============================================================================
// Merging
// =============================================================================

///|
/// Merge two page configs (child overrides base)
pub fn PageConfig::merge(base : PageConfig, child : PageConfig) -> PageConfig {
  // Child values override base values
  let mode = match child.mode {
    Some(_) => child.mode
    None => base.mode
  }
  let revalidate = match child.revalidate {
    Some(_) => child.revalidate
    None => base.revalidate
  }
  let title = match child.title {
    Some(_) => child.title
    None => base.title
  }
  let description = match child.description {
    Some(_) => child.description
    None => base.description
  }
  let layout = match child.layout {
    Some(_) => child.layout
    None => base.layout
  }

  // Arrays: if child has items, use child's; otherwise use base's
  let islands = if child.islands.is_empty() {
    base.islands
  } else {
    child.islands
  }

  // static_params: child overrides if non-empty
  let static_params = if child.static_params.is_empty() {
    base.static_params
  } else {
    child.static_params
  }

  // Booleans: child values if true, otherwise base
  let generate_params = child.generate_params || base.generate_params
  let fallback = child.fallback || base.fallback
  let spa = child.spa || base.spa

  // fallback_behavior: child overrides
  let fallback_behavior = match child.fallback_behavior {
    Some(_) => child.fallback_behavior
    None => base.fallback_behavior
  }

  // extends is not inherited
  let extends = child.extends

  // Merge handlers (child overrides)
  let handlers : Map[String, FileHandlerConfig] = {}
  for k, v in base.handlers {
    handlers[k] = v
  }
  for k, v in child.handlers {
    handlers[k] = v
  }

  // Component config: child overrides
  let component = match child.component {
    Some(_) => child.component
    None => base.component
  }
  PageConfig::{
    mode,
    revalidate,
    title,
    description,
    layout,
    islands,
    generate_params,
    static_params,
    fallback,
    spa,
    fallback_behavior,
    extends,
    handlers,
    component,
  }
}

// =============================================================================
// Conversion
// =============================================================================

///|
/// Convert page config mode string to RenderMode
pub fn PageConfig::to_render_mode(self : PageConfig) -> RenderMode {
  match self.mode {
    Some("ssr") => RenderMode::Ssr
    Some("isr") => RenderMode::Isr(revalidate=self.revalidate.unwrap_or(3600))
    Some("spa") => RenderMode::Spa
    Some("static") | _ =>
      // Static mode doesn't use RenderMode (it's pre-rendered)
      // Default to SSR for dynamic routes
      RenderMode::Ssr
  }
}

///|
/// Check if this config represents a static page
pub fn PageConfig::is_static(self : PageConfig) -> Bool {
  match self.mode {
    Some("static") | None => true
    _ => false
  }
}

///|
/// Check if this config represents a dynamic page
pub fn PageConfig::is_dynamic(self : PageConfig) -> Bool {
  match self.mode {
    Some("ssr") | Some("isr") => true
    _ => false
  }
}

///|
/// Check if this config represents a SPA page
pub fn PageConfig::is_spa(self : PageConfig) -> Bool {
  match self.mode {
    Some("spa") => true
    _ => false
  }
}

///|
/// Check if this config has static params defined
pub fn PageConfig::has_static_params(self : PageConfig) -> Bool {
  not(self.static_params.is_empty())
}

///|
/// Check if this config is for a component directory
pub fn PageConfig::is_component(self : PageConfig) -> Bool {
  self.component is Some(_)
}

///|
/// Check if this config represents ISR mode
pub fn PageConfig::is_isr(self : PageConfig) -> Bool {
  match self.mode {
    Some("isr") => true
    _ => false
  }
}
