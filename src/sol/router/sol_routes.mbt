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
// Cache Strategy
// ============================================================================

///|
/// Cache strategy for CSR navigation
/// Controls how the client handles navigation to the same page
pub(all) enum CacheStrategy {
  /// Always fetch from server (default)
  /// Each navigation triggers a fresh server request
  AlwaysFetch
  /// Stale-While-Revalidate
  /// Shows cached content immediately, then fetches and updates in background
  StaleWhileRevalidate
} derive(Eq, Show)

///|
/// Default cache strategy is AlwaysFetch
pub fn CacheStrategy::default() -> CacheStrategy {
  CacheStrategy::AlwaysFetch
}

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
  /// - revalidate: ISR revalidation interval in seconds (None = no caching)
  /// - cache: CSR cache strategy (default: AlwaysFetch)
  Page(
    path~ : String,
    handler~ : PageHandler,
    title~ : String,
    meta~ : Array[(String, String)],
    revalidate~ : Int?,
    cache~ : CacheStrategy?
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
  /// Middleware wrapper for route groups
  /// - middleware: Array of middlewares to apply
  /// - children: Nested routes
  WithMiddleware(
    middleware~ : Array[@middleware.Middleware],
    children~ : Array[SolRoutes]
  )
}

// ============================================================================
// Compiled Routes
// ============================================================================

///|
/// Catch-all parameter info
pub(all) struct CatchAllInfo {
  /// Parameter name (e.g., "slug")
  name : String
  /// Whether it's optional ([[...slug]] = true)
  optional : Bool
}

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
  /// Middleware chain (from outermost to innermost)
  middlewares : Array[@middleware.Middleware]
  /// Route kind
  kind : SolRouteKind
  /// Page title
  title : String
  /// Meta information
  meta : Array[(String, String)]
  /// Catch-all parameter info (for [...slug] or [[...slug]])
  catch_all : CatchAllInfo?
  /// ISR revalidation interval in seconds (None = no caching)
  revalidate : Int?
  /// CSR cache strategy
  cache_strategy : CacheStrategy
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
/// Extract parameter names from path pattern (excludes catch-all)
/// Example: "/user/:id/posts/:postId" -> ["id", "postId"]
fn extract_param_names(path : String) -> Array[String] {
  let result : Array[String] = []
  let segments = split_by_char(path, '/')
  for segment in segments {
    if segment.has_prefix(":") && segment.length() > 1 {
      let name = segment[1:].to_string() catch { _ => continue }
      result.push(name)
    } else if segment.has_prefix("[") &&
      not(segment.has_prefix("[...")) &&
      not(segment.has_prefix("[[...")) {
      // [id] style param (Next.js style)
      if segment.has_suffix("]") && segment.length() > 2 {
        let name = segment[1:segment.length() - 1].to_string() catch {
          _ => continue
        }
        result.push(name)
      }
    }
  }
  result
}

///|
/// Extract catch-all info from path pattern
/// Example: "/docs/[...slug]" -> Some({ name: "slug", optional: false })
///          "/docs/[[...slug]]" -> Some({ name: "slug", optional: true })
fn extract_catch_all(path : String) -> CatchAllInfo? {
  let segments = split_by_char(path, '/')
  if segments.is_empty() {
    return None
  }
  let last = segments[segments.length() - 1]
  // Optional catch-all: [[...name]]
  if last.has_prefix("[[...") && last.has_suffix("]]") && last.length() > 7 {
    let name = last[5:last.length() - 2].to_string() catch { _ => return None }
    return Some({ name, optional: true })
  }
  // Required catch-all: [...name]
  if last.has_prefix("[...") && last.has_suffix("]") && last.length() > 5 {
    let name = last[4:last.length() - 1].to_string() catch { _ => return None }
    return Some({ name, optional: false })
  }
  None
}

///|
/// Convert catch-all pattern to Hono v4 regex pattern
/// Example: "/docs/[...slug]" -> "/docs/:slug{.+}"    (required: 1+ chars)
///          "/blog/[[...path]]" -> "/blog/:path{.*}?" (optional: 0+ chars)
fn convert_to_hono_pattern(path : String, catch_all : CatchAllInfo?) -> String {
  match catch_all {
    Some(info) => {
      // Remove the catch-all segment and add Hono v4 regex pattern
      let segments = split_by_char(path, '/')
      let base_segments = segments[0:segments.length() - 1]
      let base = if base_segments.length() == 0 {
        ""
      } else {
        "/" + join_segments(base_segments)
      }
      // Hono v4: :name{regex} for named catch-all
      // Required: {.+} matches 1 or more chars (must have at least one segment)
      // Optional: {.*}? matches 0 or more chars (can be empty)
      if info.optional {
        base + "/:" + info.name + "{.*}?"
      } else {
        base + "/:" + info.name + "{.+}"
      }
    }
    None => path
  }
}

///|
/// Join segments with "/"
fn join_segments(segments : ArrayView[String]) -> String {
  if segments.length() == 0 {
    return ""
  }
  let result = StringBuilder::new()
  for i, seg in segments {
    if i > 0 {
      result.write_string("/")
    }
    result.write_string(seg)
  }
  result.to_string()
}

///|
/// Add catch-all parameter (Hono v4 compatibility)
/// With Hono v4's `:name{regex}` pattern, the parameter is already
/// available with the correct name, so this function just returns params as-is.
fn add_catch_all_param(
  params : RouteParams,
  _catch_all : CatchAllInfo?,
) -> RouteParams {
  // Hono v4 uses named regex patterns like :slug{.+} which automatically
  // populate the params with the correct key name.
  // No transformation needed.
  params
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
  compile_sol_routes_inner(routes, base, [], [], result)
  result
}

///|
fn compile_sol_routes_inner(
  routes : Array[SolRoutes],
  prefix : String,
  inherited_layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  inherited_middlewares : Array[@middleware.Middleware],
  result : Array[CompiledSolRoute],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, handler~, title~, meta~, revalidate~, cache~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        let catch_all = extract_catch_all(full_path)
        result.push({
          pattern: full_path,
          param_names,
          page_handler: Some(handler),
          api_handler: None,
          layouts: inherited_layouts.copy(),
          middlewares: inherited_middlewares.copy(),
          kind: SolRouteKind::Page,
          title,
          meta,
          catch_all,
          revalidate,
          cache_strategy: cache.unwrap_or(CacheStrategy::AlwaysFetch),
        })
      }
      Layout(segment~, layout~, children~) => {
        let new_prefix = normalize_path(prefix + segment)
        let new_layouts = inherited_layouts.copy()
        new_layouts.push(layout)
        compile_sol_routes_inner(
          children, new_prefix, new_layouts, inherited_middlewares, result,
        )
      }
      Get(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        let catch_all = extract_catch_all(full_path)
        result.push({
          pattern: full_path,
          param_names,
          page_handler: None,
          api_handler: Some(handler),
          layouts: [],
          middlewares: inherited_middlewares.copy(),
          kind: SolRouteKind::GetApi,
          title: "",
          meta: [],
          catch_all,
          revalidate: None,
          cache_strategy: CacheStrategy::AlwaysFetch,
        })
      }
      Post(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        let catch_all = extract_catch_all(full_path)
        result.push({
          pattern: full_path,
          param_names,
          page_handler: None,
          api_handler: Some(handler),
          layouts: [],
          middlewares: inherited_middlewares.copy(),
          kind: SolRouteKind::PostApi,
          title: "",
          meta: [],
          catch_all,
          revalidate: None,
          cache_strategy: CacheStrategy::AlwaysFetch,
        })
      }
      WithMiddleware(middleware~, children~) => {
        let new_middlewares = inherited_middlewares.copy()
        for mw in middleware {
          new_middlewares.push(mw)
        }
        compile_sol_routes_inner(
          children, prefix, inherited_layouts, new_middlewares, result,
        )
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
/// Execute middleware chain and return halted response or continue with context
async fn run_middlewares(
  c : Ctx,
  middlewares : Array[@middleware.Middleware],
) -> @middleware.Flow[@middleware.MwContext] {
  if middlewares.is_empty() {
    return @middleware.Flow::Continue(@middleware.MwContext::from_ctx(c))
  }
  let mw_ctx = @middleware.MwContext::from_ctx(c)
  let pipeline = @middleware.pipeline(middlewares)
  @middleware.run(pipeline, mw_ctx) catch {
    e =>
      @middleware.Flow::Halt(
        @middleware.MwResponse::text(e.to_string(), status=500),
      )
  }
}

///|
/// Convert MwResponse to Hono response
fn send_mw_response(c : Ctx, resp : @middleware.MwResponse) -> @http.Response {
  // Set headers
  for header in resp.headers {
    ffi_set_header(c.as_any(), header.0, header.1)
  }
  // Set content type
  ffi_set_header(c.as_any(), "Content-Type", resp.content_type)
  // Return response
  match resp.status {
    301 | 302 | 303 | 307 | 308 =>
      c.redirect(
        resp.headers
        .iter()
        .find_first(fn(h) { h.0 == "Location" })
        .map(fn(h) { h.1 })
        .unwrap_or("/"),
      )
    _ => ffi_create_response(c.as_any(), resp.body, resp.status)
  }
}

///|
extern "js" fn ffi_set_header(
  c : @js.Any,
  name : String,
  value : String,
) -> Unit =
  #| (c, name, value) => c.header(name, value)

///|
extern "js" fn ffi_create_response(
  c : @js.Any,
  body : String,
  status : Int,
) -> @http.Response =
  #| (c, body, status) => c.body(body, status)

///|
/// Apply response headers from middleware context
fn apply_response_headers(c : Ctx, mw_ctx : @middleware.MwContext) -> Unit {
  for header in mw_ctx.response_headers {
    ffi_set_header(c.as_any(), header.0, header.1)
  }
}

///|
/// Render page and return HTML (helper for ISR)
async fn render_page_to_html(
  _c : Ctx,
  props : PageProps,
  handler : async (PageProps) -> @server_dom.ServerNode,
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  is_fragment : Bool,
  title : String,
  default_head : String,
  root_template : String,
) -> String raise Error {
  // Call handler and apply layouts
  let content : @server_dom.ServerNode = handler(props)

  // Apply layouts from innermost to outermost
  // For fragments: skip root layout (index 0), apply nested layouts
  // For full pages: apply all layouts
  let mut node = content
  let end_idx = if is_fragment { 1 } else { 0 }
  let mut i = layouts.length() - 1
  while i >= end_idx {
    let layout_fn = layouts[i]
    node = layout_fn(props, node)
    i -= 1
  }
  if is_fragment {
    render_server_fragment(node, title)
  } else {
    render_server_page_html(node, title, default_head, root_template)
  }
}

///|
fn register_compiled_sol_routes(
  app : App,
  routes : Array[CompiledSolRoute],
  config : RouterConfig,
) -> App {
  let mut result = app
  for route in routes {
    // Convert catch-all pattern to Hono wildcard pattern
    let hono_pattern = convert_to_hono_pattern(route.pattern, route.catch_all)
    result = match route.kind {
      SolRouteKind::Page =>
        result.get(hono_pattern, async fn(c) {
          // Run middleware chain first
          let mw_result = run_middlewares(c, route.middlewares)
          let mw_ctx = match mw_result {
            @middleware.Flow::Halt(resp) => return send_mw_response(c, resp)
            @middleware.Flow::Continue(ctx) => ctx
          }
          apply_response_headers(c, mw_ctx)
          let is_fragment = has_fragment_header(c)
          let mut params = extract_route_params(c, is_fragment~)
          // Add catch-all parameter if present
          params = add_catch_all_param(params, route.catch_all)
          let props = PageProps::from_ctx_with_params(c, params)
          let page_title = format_title(
            route.title,
            title_prefix=config.title_prefix,
            default_title=config.default_title,
          )
          match route.page_handler {
            Some(PageHandler(handler)) =>
              // Check if ISR is enabled for this route (only for full page requests)
              match (route.revalidate, config.isr_cache, is_fragment) {
                (Some(revalidate), Some(cache), false) => {
                  // ISR enabled - check cache
                  let cache_key = @isr.cache_key(params.path, params.query)
                  let entry = @isr.ISRCache::get(cache, cache_key)
                  let now = @isr.now_ms()
                  let status = @isr.check_status(entry, now)
                  match status {
                    @isr.Fresh =>
                      // Return cached HTML directly
                      match entry {
                        Some(e) => c.html(e.html)
                        None => c.text("Cache error")
                      }
                    @isr.Stale =>
                      // Return cached HTML and schedule background revalidation
                      match entry {
                        Some(e) => {
                          // Schedule background revalidation
                          @isr.ISRCache::schedule_revalidation(cache, async fn() {
                            let html = render_page_to_html(
                              c,
                              props,
                              handler,
                              route.layouts,
                              false,
                              page_title,
                              config.default_head,
                              config.root_template,
                            ) catch {
                              _ => return
                            }
                            let new_entry = @isr.CacheEntry::new(
                              html,
                              @isr.now_ms(),
                              revalidate,
                            )
                            @isr.ISRCache::put(cache, cache_key, new_entry)
                          })
                          c.html(e.html)
                        }
                        None => c.text("Cache error")
                      }
                    @isr.Miss => {
                      // Render, cache, and return
                      let html = render_page_to_html(
                        c,
                        props,
                        handler,
                        route.layouts,
                        false,
                        page_title,
                        config.default_head,
                        config.root_template,
                      ) catch {
                        e => return c.text("Error: " + e.to_string())
                      }
                      let new_entry = @isr.CacheEntry::new(
                        html, now, revalidate,
                      )
                      @isr.ISRCache::put(cache, cache_key, new_entry)
                      c.html(html)
                    }
                  }
                }
                _ => {
                  // No ISR - render normally
                  let content : @server_dom.ServerNode = handler(props) catch {
                    e => return c.text("Error: " + e.to_string())
                  }

                  // Apply layouts from innermost to outermost
                  // For fragments: skip root layout (index 0), apply nested layouts
                  // For full pages: apply all layouts
                  let mut node = content
                  let layouts = route.layouts
                  let end_idx = if is_fragment { 1 } else { 0 }
                  let mut i = layouts.length() - 1
                  while i >= end_idx {
                    let layout_fn = layouts[i]
                    node = layout_fn(props, node) catch {
                      e => return c.text("Layout error: " + e.to_string())
                    }
                    i -= 1
                  }
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
              }
            None => c.text("No handler for route")
          }
        })
      SolRouteKind::GetApi =>
        result.get(hono_pattern, async fn(c) {
          // Run middleware chain first
          let mw_result = run_middlewares(c, route.middlewares)
          let mw_ctx = match mw_result {
            @middleware.Flow::Halt(resp) => return send_mw_response(c, resp)
            @middleware.Flow::Continue(ctx) => ctx
          }
          apply_response_headers(c, mw_ctx)
          let mut params = extract_route_params(c)
          params = add_catch_all_param(params, route.catch_all)
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
        result.post(hono_pattern, async fn(c) {
          // Run middleware chain first
          let mw_result = run_middlewares(c, route.middlewares)
          let mw_ctx = match mw_result {
            @middleware.Flow::Halt(resp) => return send_mw_response(c, resp)
            @middleware.Flow::Continue(ctx) => ctx
          }
          apply_response_headers(c, mw_ctx)
          let mut params = extract_route_params(c)
          params = add_catch_all_param(params, route.catch_all)
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
