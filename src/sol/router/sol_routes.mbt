// Sol Routes - Server-side route definitions with typed handlers
//
// This is a Sol-specific route type that directly takes handler functions
// instead of component ID strings. For server-side rendering only.

// ============================================================================
// Handler Types
// ============================================================================

///|
/// Page handler type - async function that receives PageProps and returns ServerNode
pub(all) struct PageHandler(async (PageProps) -> @server_dom.ServerNode)

///|
/// API handler type - async function that receives PageProps and returns JSON response
pub(all) struct ApiHandler(async (PageProps) -> @js.Any)

// ============================================================================
// Sol Routes Definition
// ============================================================================

///|
/// Sol route definition with typed handlers
pub(all) enum SolRoutes {
  /// Page route with async handler
  /// - path: URL pattern (e.g., "/", "/user/:id")
  /// - handler: Async function that returns ServerNode
  /// - title: Page title
  /// - meta: Meta information
  Page(
    path~ : String,
    handler~ : PageHandler,
    title~ : String,
    meta~ : Array[(String, String)]
  )
  /// Layout wrapper for nested routes
  /// - segment: Path segment (e.g., "/admin")
  /// - layout: Layout handler that wraps children
  /// - children: Nested routes
  Layout(
    segment~ : String,
    layout~ : (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
    children~ : Array[SolRoutes]
  )
  /// GET API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Get(path~ : String, handler~ : ApiHandler)
  /// POST API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Post(path~ : String, handler~ : ApiHandler)
}

// ============================================================================
// Compiled Routes
// ============================================================================

///|
/// Compiled route for efficient matching
pub struct CompiledSolRoute {
  /// Full path pattern
  pattern : String
  /// Parameter names extracted from path
  param_names : Array[String]
  /// Page handler (if page route)
  page_handler : PageHandler?
  /// API handler (if API route)
  api_handler : ApiHandler?
  /// Layout handlers (from outermost to innermost)
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ]
  /// Route kind
  kind : SolRouteKind
  /// Page title
  title : String
  /// Meta information
  meta : Array[(String, String)]
}

///|
/// Route kind
pub enum SolRouteKind {
  Page
  GetApi
  PostApi
} derive(Eq, Show)

// ============================================================================
// Compilation
// ============================================================================

///|
/// Extract parameter names from path pattern
/// Example: "/user/:id/posts/:postId" -> ["id", "postId"]
fn extract_param_names(path : String) -> Array[String] {
  let result : Array[String] = []
  let segments = split_by_char(path, '/')
  for segment in segments {
    if segment.has_prefix(":") && segment.length() > 1 {
      let name = segment[1:].to_string() catch { _ => continue }
      result.push(name)
    }
  }
  result
}

///|
fn split_by_char(s : String, c : Char) -> Array[String] {
  let result : Array[String] = []
  let current : Array[Char] = []
  for ch in s {
    if ch == c {
      if current.length() > 0 {
        result.push(String::from_array(current))
        current.clear()
      }
    } else {
      current.push(ch)
    }
  }
  if current.length() > 0 {
    result.push(String::from_array(current))
  }
  result
}

///|
/// Normalize path (remove duplicate slashes, trailing slash)
fn normalize_path(path : String) -> String {
  if path == "" || path == "/" {
    return "/"
  }
  let chars = path.to_array()
  let result : Array[Char] = []
  let mut prev_slash = false
  for c in chars {
    if c == '/' {
      if not(prev_slash) {
        result.push(c)
      }
      prev_slash = true
    } else {
      result.push(c)
      prev_slash = false
    }
  }
  // Remove trailing slash (except for root)
  let len = result.length()
  if len > 1 && result[len - 1] == '/' {
    let _ = result.pop()

  }
  String::from_array(result)
}

///|
/// Compile SolRoutes to optimized format
pub fn compile_sol_routes(
  routes : Array[SolRoutes],
  base? : String = "",
) -> Array[CompiledSolRoute] {
  let result : Array[CompiledSolRoute] = []
  compile_sol_routes_inner(routes, base, [], result)
  result
}

///|
fn compile_sol_routes_inner(
  routes : Array[SolRoutes],
  prefix : String,
  inherited_layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  result : Array[CompiledSolRoute],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, handler~, title~, meta~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        result.push({
          pattern: full_path,
          param_names,
          page_handler: Some(handler),
          api_handler: None,
          layouts: inherited_layouts.copy(),
          kind: SolRouteKind::Page,
          title,
          meta,
        })
      }
      Layout(segment~, layout~, children~) => {
        let new_prefix = normalize_path(prefix + segment)
        let new_layouts = inherited_layouts.copy()
        new_layouts.push(layout)
        compile_sol_routes_inner(children, new_prefix, new_layouts, result)
      }
      Get(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        result.push({
          pattern: full_path,
          param_names,
          page_handler: None,
          api_handler: Some(handler),
          layouts: [],
          kind: SolRouteKind::GetApi,
          title: "",
          meta: [],
        })
      }
      Post(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        result.push({
          pattern: full_path,
          param_names,
          page_handler: None,
          api_handler: Some(handler),
          layouts: [],
          kind: SolRouteKind::PostApi,
          title: "",
          meta: [],
        })
      }
    }
  }
}

// ============================================================================
// Route Registration to Hono
// ============================================================================

///|
/// Register Sol routes to Hono app
pub fn register_sol_routes(
  app : App,
  routes : Array[SolRoutes],
  config? : RouterConfig,
) -> App {
  let compiled = compile_sol_routes(routes)
  let cfg = config.unwrap_or(RouterConfig::default())
  register_compiled_sol_routes(app, compiled, cfg)
}

///|
fn register_compiled_sol_routes(
  app : App,
  routes : Array[CompiledSolRoute],
  config : RouterConfig,
) -> App {
  let mut result = app
  for route in routes {
    result = match route.kind {
      SolRouteKind::Page =>
        result.get(route.pattern, async fn(c) {
          let is_fragment = has_fragment_header(c)
          let params = extract_route_params(c, is_fragment~)
          let props = PageProps::from_ctx_with_params(c, params)
          match route.page_handler {
            Some(PageHandler(handler)) => {
              // Call handler and apply layouts
              let content : @server_dom.ServerNode = handler(props) catch {
                e => return c.text("Error: " + e.to_string())
              }

              // Apply layouts from innermost to outermost
              let mut node = content
              let layouts = route.layouts
              let mut i = layouts.length() - 1
              while i >= 0 {
                let layout_fn = layouts[i]
                node = layout_fn(props, node) catch {
                  e => return c.text("Layout error: " + e.to_string())
                }
                i -= 1
              }
              let page_title = format_title(
                route.title,
                title_prefix=config.title_prefix,
                default_title=config.default_title,
              )
              if is_fragment {
                let fragment_html = render_server_fragment(node, page_title)
                send_fragment_response(c, fragment_html)
              } else {
                let html = render_server_page_html(
                  node,
                  page_title,
                  config.default_head,
                  config.root_template,
                )
                c.html(html)
              }
            }
            None => c.text("No handler for route")
          }
        })
      SolRouteKind::GetApi =>
        result.get(route.pattern, async fn(c) {
          let params = extract_route_params(c)
          let props = PageProps::from_ctx_with_params(c, params)
          match route.api_handler {
            Some(ApiHandler(handler)) => {
              let json : @js.Any = handler(props) catch {
                e => return c.json(@js.any({ "error": e.to_string() }))
              }
              c.json(json)
            }
            None => c.json(@js.any({ "error": "No handler" }))
          }
        })
      SolRouteKind::PostApi =>
        result.post(route.pattern, async fn(c) {
          let params = extract_route_params(c)
          let props = PageProps::from_ctx_with_params(c, params)
          match route.api_handler {
            Some(ApiHandler(handler)) => {
              let json : @js.Any = handler(props) catch {
                e => return c.json(@js.any({ "error": e.to_string() }))
              }
              c.json(json)
            }
            None => c.json(@js.any({ "error": "No handler" }))
          }
        })
    }
  }
  result
}

///|
/// Render ServerNode to fragment HTML (for CSR navigation)
async fn render_server_fragment(
  node : @server_dom.ServerNode,
  title : String,
) -> String {
  // Resolve the ServerNode to get the actual Node
  let resolved_node = node.resolve()
  let body_html = @render.render_to_string(resolved_node).html

  // Wrap in templates like fragment.mbt does
  let buf = StringBuilder::new()
  buf.write_string("<template data-sol-outlet=\"main\">")
  buf.write_string(body_html)
  buf.write_string("</template>")
  buf.write_string("<template data-sol-title>")
  buf.write_string(escape_html_title(title))
  buf.write_string("</template>")
  buf.to_string()
}

///|
/// Render ServerNode to full page HTML
async fn render_server_page_html(
  node : @server_dom.ServerNode,
  title : String,
  head : String,
  template : String,
) -> String {
  // Resolve the ServerNode to get the actual Node
  let resolved_node = node.resolve()
  let body_html = @render.render_to_string(resolved_node).html
  // Add HMR script in dev mode
  let full_head = if is_dev_mode() { head + hmr_script } else { head }
  // Replace placeholders in template
  template
  .replace(old="__LUNA_TITLE__", new=title)
  .replace(old="__LUNA_PRELOAD__", new="")
  .replace(old="__LUNA_HEAD__", new=full_head)
  .replace(old="__LUNA_MAIN__", new=body_html)
}

///|
/// Escape HTML entities in title
fn escape_html_title(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    match ch {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(ch)
    }
  }
  buf.to_string()
}

// ============================================================================
// Static Directory (SSG Integration)
// ============================================================================

///|
/// Configuration for static directory generation (minimal, backend-independent)
pub(all) struct StaticDirConfig {
  /// Internationalization configuration
  i18n : @ssg.I18nConfig
  /// Navigation configuration (SPA, View Transitions, Keyboard)
  navigation : @ssg.NavigationConfig
  /// Directories to exclude from scanning
  exclude : Array[String]
  /// Use trailing slash in URLs
  trailing_slash : Bool
}

///|
/// Default static directory configuration
pub fn StaticDirConfig::default() -> StaticDirConfig {
  {
    i18n: @ssg.I18nConfig::default(),
    navigation: @ssg.NavigationConfig::default(),
    exclude: [],
    trailing_slash: true,
  }
}

///|
/// Static directory route definition
pub(all) struct StaticDir {
  /// URL path prefix (e.g., "/docs")
  path_prefix : String
  /// Source directory containing markdown files (e.g., "docs")
  source_dir : String
  /// Section title
  title : String
  /// SSG configuration
  config : StaticDirConfig
}
