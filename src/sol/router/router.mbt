///| Sol Router - Server-side routing based on core/routes

///|

///| This module bridges core/routes definitions to Hono server routing.

///| It provides type-safe routing with support for Pages, Islands, and APIs.

// ============================================================================
// Router Configuration
// ============================================================================

///|
/// Router configuration for customizing routing behavior
pub struct RouterConfig {
  /// Prefix for page titles (e.g., "MyApp - ")
  title_prefix : String
  /// Default title when page has no title
  default_title : String
  /// Default head HTML (styles, meta tags, etc.)
  default_head : String
  /// URL for the island loader script
  loader_url : String
}

///|
/// Create default router configuration
pub fn RouterConfig::default() -> RouterConfig {
  {
    title_prefix: "",
    default_title: "App",
    default_head: "",
    loader_url: "/static/loader.js",
  }
}

///|
/// Set default head HTML
pub fn RouterConfig::with_default_head(
  self : RouterConfig,
  head : String,
) -> RouterConfig {
  { ..self, default_head: head }
}

///|
/// Set loader URL
pub fn RouterConfig::with_loader_url(
  self : RouterConfig,
  url : String,
) -> RouterConfig {
  { ..self, loader_url: url }
}

///|
/// Set title prefix
pub fn RouterConfig::with_title_prefix(
  self : RouterConfig,
  prefix : String,
) -> RouterConfig {
  { ..self, title_prefix: prefix }
}

///|
/// Set default title
pub fn RouterConfig::with_default_title(
  self : RouterConfig,
  title : String,
) -> RouterConfig {
  { ..self, default_title: title }
}

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
  /// Whether this is a fragment request (CSR navigation)
  is_fragment : Bool
}

///|
/// Create empty route params
pub fn RouteParams::empty() -> RouteParams {
  { params: [], query: [], path: "", is_fragment: false }
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
// Page Props
// ============================================================================

///|
/// Props passed to page components
pub struct PageProps {
  /// Request context (Hono Context)
  ctx : Ctx
  /// Route parameters (path params, query params)
  params : RouteParams
  /// Whether this is a fragment request (CSR navigation)
  /// When true, page should return content without layout wrapper
  is_fragment : Bool
}

///|
/// Create PageProps from context
pub fn PageProps::from_ctx(ctx : Ctx) -> PageProps {
  let params = extract_route_params(ctx)
  { ctx, params, is_fragment: false }
}

///|
/// Create PageProps for fragment request
pub fn PageProps::from_ctx_fragment(ctx : Ctx) -> PageProps {
  let params = extract_route_params(ctx)
  { ctx, params, is_fragment: true }
}

///|
/// Create PageProps from context and pre-extracted params
/// Use this when params are already extracted by the router
pub fn PageProps::from_ctx_with_params(
  ctx : Ctx,
  params : RouteParams,
) -> PageProps {
  { ctx, params, is_fragment: params.is_fragment }
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
  title_prefix? : String = "",
  default_title? : String = "App",
  default_head? : String = "",
  loader_url? : String = "/static/loader.js",
) -> App {
  // Use config if provided, otherwise use individual parameters
  let (tp, dt, dh, lu) = match config {
    Some(c) => (c.title_prefix, c.default_title, c.default_head, c.loader_url)
    None => (title_prefix, default_title, default_head, loader_url)
  }
  register_routes_inner(
    app,
    routes,
    "",
    page_resolver,
    api_resolver,
    title_prefix=tp,
    default_title=dt,
    default_head=dh,
    loader_url=lu,
  )
}

///|
fn[E] register_routes_inner(
  app : App,
  routes : Array[@routes.Routes],
  prefix : String,
  page_resolver : (String, Ctx, RouteParams) -> @luna.Node[E]?,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
  title_prefix~ : String,
  default_title~ : String,
  default_head~ : String,
  loader_url~ : String,
) -> App {
  let mut result = app
  for route in routes {
    result = match route {
      @routes.Page(path~, component~, title~, meta~) => {
        let _ = meta
        let full_path = prefix + path
        result.get(full_path, fn(c) {
          let is_fragment = has_fragment_header(c)
          let params = extract_route_params(c, is_fragment~)
          match page_resolver(component, c, params) {
            Some(node) => {
              let page_title = format_title(
                title,
                title_prefix~,
                default_title~,
              )
              // Check for fragment request
              if is_fragment {
                let fragment_html = render_fragment_response(
                  node,
                  page_title,
                  false,
                )
                send_fragment_response(c, fragment_html)
              } else {
                let html = render_page_html(node, page_title, default_head, false)
                c.html(html)
              }
            }
            None => c.text("Page not found: " + component)
          }
        })
      }
      @routes.Island(path~, component~, url~, trigger~, title~, meta~) => {
        let _ = (url, trigger, meta)
        let full_path = prefix + path
        result.get(full_path, fn(c) {
          let is_fragment = has_fragment_header(c)
          let params = extract_route_params(c, is_fragment~)
          match page_resolver(component, c, params) {
            Some(node) => {
              let page_title = format_title(
                title,
                title_prefix~,
                default_title~,
              )
              // Check for fragment request
              if is_fragment {
                let fragment_html = render_fragment_response(node, page_title, true)
                send_fragment_response(c, fragment_html)
              } else {
                let loader_script = "<script type=\"module\" src=\"" +
                  loader_url +
                  "\"></script>"
                let head = default_head + loader_script
                let html = render_page_html(node, page_title, head, true)
                c.html(html)
              }
            }
            None => c.text("Page not found: " + component)
          }
        })
      }
      @routes.Param(key~, children~) => {
        let new_prefix = prefix + "/:" + key
        register_routes_inner(
          result,
          children,
          new_prefix,
          page_resolver,
          api_resolver,
          title_prefix~,
          default_title~,
          default_head~,
          loader_url~,
        )
      }
      @routes.Layout(segment~, children~, layout~) => {
        let _ = layout // TODO: Layout support
        let new_prefix = prefix + segment
        register_routes_inner(
          result,
          children,
          new_prefix,
          page_resolver,
          api_resolver,
          title_prefix~,
          default_title~,
          default_head~,
          loader_url~,
        )
      }
      @routes.Group(segment~, children~) => {
        let new_prefix = prefix + segment
        register_routes_inner(
          result,
          children,
          new_prefix,
          page_resolver,
          api_resolver,
          title_prefix~,
          default_title~,
          default_head~,
          loader_url~,
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
fn extract_route_params(c : Ctx, is_fragment~ : Bool = false) -> RouteParams {
  let params = ffi_get_all_params(c.as_any())
  let query = ffi_get_query_params(c.as_any())
  let path = ffi_get_path(c.as_any())
  { params, query, path, is_fragment }
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
fn format_title(
  title : String,
  title_prefix~ : String,
  default_title~ : String,
) -> String {
  if title.is_empty() {
    default_title
  } else if title_prefix.is_empty() {
    title
  } else {
    title_prefix + " - " + title
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
