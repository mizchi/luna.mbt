///| Sol Router - Server-side routing based on core/routes
///|
///| This module bridges core/routes definitions to Hono server routing.
///| It provides type-safe routing with support for Pages, Islands, and APIs.

// ============================================================================
// Type Aliases
// ============================================================================

///|
/// Environment bindings (e.g., Cloudflare Workers KV)
pub type Env = Unit

///|
/// Execution context (e.g., Cloudflare Workers context)
pub type ExecutionContext = Unit

///|
/// Hono app type alias
pub type App = @hono.Hono[Env, ExecutionContext]

///|
/// Hono context type alias
pub type Ctx = @hono.Context[Env, ExecutionContext]

// ============================================================================
// Route Registration Helper Types
// ============================================================================

///|
/// Route parameters extracted from URL
pub struct RouteParams {
  /// Path parameters (e.g., {:id} -> [("id", "123")])
  params : Array[(String, String)]
  /// Query parameters
  query : Array[(String, String)]
  /// Full path
  path : String
}

///|
/// Create empty route params
pub fn RouteParams::empty() -> RouteParams {
  { params: [], query: [], path: "" }
}

///|
/// Get path parameter by name
pub fn RouteParams::get_param(self : RouteParams, key : String) -> String? {
  for pair in self.params {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get query parameter by name
pub fn RouteParams::get_query(self : RouteParams, key : String) -> String? {
  for pair in self.query {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

// ============================================================================
// Router Configuration
// ============================================================================

///|
/// Router configuration
pub struct RouterConfig {
  /// Page title prefix
  title_prefix : String
  /// Default title for pages without title
  default_title : String
  /// Head HTML to include in all pages
  default_head : String
  /// Loader script URL for hydration
  loader_url : String
}

///|
/// Create default router config
pub fn RouterConfig::default() -> RouterConfig {
  {
    title_prefix: "",
    default_title: "App",
    default_head: "",
    loader_url: "/static/loader.min.js",
  }
}

///|
/// Builder: set title prefix
pub fn RouterConfig::with_title_prefix(
  self : RouterConfig,
  prefix : String,
) -> RouterConfig {
  { ..self, title_prefix: prefix }
}

///|
/// Builder: set default title
pub fn RouterConfig::with_default_title(
  self : RouterConfig,
  title : String,
) -> RouterConfig {
  { ..self, default_title: title }
}

///|
/// Builder: set default head
pub fn RouterConfig::with_default_head(
  self : RouterConfig,
  head : String,
) -> RouterConfig {
  { ..self, default_head: head }
}

///|
/// Builder: set loader URL
pub fn RouterConfig::with_loader_url(
  self : RouterConfig,
  url : String,
) -> RouterConfig {
  { ..self, loader_url: url }
}

// ============================================================================
// Route Registration from Routes Definition
// ============================================================================

///|
/// Register routes from Routes definition to Hono app
/// Uses a resolver function to map component IDs to render functions
pub fn[E] register_routes(
  app : App,
  routes : Array[@routes.Routes],
  page_resolver : (String, Ctx, RouteParams) -> @luna.Node[E]?,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
  config? : RouterConfig,
) -> App {
  let cfg = config.unwrap_or(RouterConfig::default())
  register_routes_inner(app, routes, "", page_resolver, api_resolver, cfg)
}

///|
fn[E] register_routes_inner(
  app : App,
  routes : Array[@routes.Routes],
  prefix : String,
  page_resolver : (String, Ctx, RouteParams) -> @luna.Node[E]?,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
  config : RouterConfig,
) -> App {
  let mut result = app
  for route in routes {
    result = match route {
      @routes.Page(path~, component~, title~, meta~) => {
        let _ = meta
        let full_path = prefix + path
        result.get(full_path, fn(c) {
          let params = extract_route_params(c)
          match page_resolver(component, c, params) {
            Some(node) => {
              let page_title = format_title(title, config)
              let html = render_page_html(node, page_title, config.default_head, false)
              c.html(html)
            }
            None => c.text("Page not found: " + component)
          }
        })
      }
      @routes.Island(path~, component~, url~, trigger~, title~, meta~) => {
        let _ = (url, trigger, meta)
        let full_path = prefix + path
        result.get(full_path, fn(c) {
          let params = extract_route_params(c)
          match page_resolver(component, c, params) {
            Some(node) => {
              let page_title = format_title(title, config)
              let loader_script = "<script type=\"module\" src=\"" +
                config.loader_url +
                "\"></script>"
              let head = config.default_head + loader_script
              let html = render_page_html(node, page_title, head, true)
              c.html(html)
            }
            None => c.text("Page not found: " + component)
          }
        })
      }
      @routes.Param(key~, children~) => {
        let new_prefix = prefix + "/:" + key
        register_routes_inner(
          result, children, new_prefix, page_resolver, api_resolver, config,
        )
      }
      @routes.Layout(segment~, children~, layout~) => {
        let _ = layout // TODO: Layout support
        let new_prefix = prefix + segment
        register_routes_inner(
          result, children, new_prefix, page_resolver, api_resolver, config,
        )
      }
      @routes.Group(segment~, children~) => {
        let new_prefix = prefix + segment
        register_routes_inner(
          result, children, new_prefix, page_resolver, api_resolver, config,
        )
      }
      @routes.Get(path~, handler~) => {
        let full_path = prefix + path
        result.get(full_path, fn(c) {
          let params = extract_route_params(c)
          match api_resolver(handler, c, params) {
            Some(json) => c.json(json)
            None => c.json(@js.any({ "error": "Handler not found" }))
          }
        })
      }
      @routes.Post(path~, handler~) => {
        let full_path = prefix + path
        result.post(full_path, fn(c) {
          let params = extract_route_params(c)
          match api_resolver(handler, c, params) {
            Some(json) => c.json(json)
            None => c.json(@js.any({ "error": "Handler not found" }))
          }
        })
      }
    }
  }
  result
}

///|
/// Extract route parameters from Hono context
fn extract_route_params(c : Ctx) -> RouteParams {
  let params = ffi_get_all_params(c.as_any())
  let query = ffi_get_query_params(c.as_any())
  let path = ffi_get_path(c.as_any())
  { params, query, path }
}

///|
extern "js" fn ffi_get_all_params(c : @js.Any) -> Array[(String, String)] =
  #| (c) => {
  #|   const p = c.req.param();
  #|   return Object.entries(p || {}).map(([k, v]) => ({_0: k, _1: v}));
  #| }

///|
extern "js" fn ffi_get_query_params(c : @js.Any) -> Array[(String, String)] =
  #| (c) => {
  #|   const url = new URL(c.req.url);
  #|   return Array.from(url.searchParams.entries()).map(([k, v]) => ({_0: k, _1: v}));
  #| }

///|
extern "js" fn ffi_get_path(c : @js.Any) -> String =
  #| (c) => new URL(c.req.url).pathname

///|
/// Format page title with prefix
fn format_title(title : String, config : RouterConfig) -> String {
  if title.is_empty() {
    config.default_title
  } else if config.title_prefix.is_empty() {
    title
  } else {
    config.title_prefix + " - " + title
  }
}

// ============================================================================
// HTML Rendering
// ============================================================================

///|
/// Render VNode to full HTML page
fn[E] render_page_html(
  node : @luna.Node[E],
  title : String,
  head : String,
  hydration : Bool,
) -> String {
  let body_html = if hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title +
  "</title>" +
  head +
  "</head><body><div id=\"app\">" +
  body_html +
  "</div></body></html>"
}
