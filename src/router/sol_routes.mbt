// Sol Routes - Server-side route definitions with typed handlers
//
// This is a Sol-specific route type that directly takes handler functions
// instead of component ID strings. For server-side rendering only.

// ============================================================================
// ISR In-Flight Deduplication
// ============================================================================

///|
/// Tracks cache keys with in-flight STALE revalidation to prevent duplicate renders.
let isr_in_flight : Ref[Set[String]] = Ref::new(Set::new())

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
  /// PUT API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Put(path~ : String, handler~ : ApiHandler)
  /// DELETE API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Delete(path~ : String, handler~ : ApiHandler)
  /// PATCH API route
  /// - path: URL pattern
  /// - handler: Handler that returns JSON
  Patch(path~ : String, handler~ : ApiHandler)
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
  PutApi
  DeleteApi
  PatchApi
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
      Put(path~, handler~) => {
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
          kind: SolRouteKind::PutApi,
          title: "",
          meta: [],
          catch_all,
          revalidate: None,
          cache_strategy: CacheStrategy::AlwaysFetch,
        })
      }
      Delete(path~, handler~) => {
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
          kind: SolRouteKind::DeleteApi,
          title: "",
          meta: [],
          catch_all,
          revalidate: None,
          cache_strategy: CacheStrategy::AlwaysFetch,
        })
      }
      Patch(path~, handler~) => {
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
          kind: SolRouteKind::PatchApi,
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
extern "js" fn ffi_ensure_mars_to_handler_reschedule_symbol() -> Unit =
  #| () => {
  #|   if (typeof globalThis.moonbitlang$async$internal$event_loop$$reschedule !== "function") {
  #|     globalThis.moonbitlang$async$internal$event_loop$$reschedule = () => {};
  #|   }
  #| }

///|
fn ensure_mars_to_handler_compat() -> Unit {
  ffi_ensure_mars_to_handler_reschedule_symbol()
}

///|
/// Register Sol routes to Hono app
pub fn register_sol_routes(
  app : App,
  routes : Array[SolRoutes],
  config? : RouterConfig,
) -> Unit {
  ensure_mars_to_handler_compat()
  let compiled = compile_sol_routes(routes)
  let cfg = config.unwrap_or(RouterConfig::default())
  register_compiled_sol_routes(app, compiled, cfg)
}

///|
fn render_meta_tags(meta : Array[(String, String)]) -> String {
  if meta.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  for pair in meta {
    let key = @page_shell.escape_html_text(pair.0)
    let value = @page_shell.escape_html_text(pair.1)
    buf.write_string("<meta name=\"")
    buf.write_string(key)
    buf.write_string("\" content=\"")
    buf.write_string(value)
    buf.write_string("\">")
  }
  buf.to_string()
}

///|
fn build_page_head(
  default_head : String,
  meta : Array[(String, String)],
) -> String {
  default_head + render_meta_tags(meta)
}

///|
fn is_isr_with_cache(config : RouterConfig, route_revalidate : Int?) -> Bool {
  match (route_revalidate, config.isr_cache) {
    (Some(_), Some(_)) => true
    _ => false
  }
}

///|
fn should_use_streaming(
  config : RouterConfig,
  is_fragment : Bool,
  route_revalidate : Int?,
) -> Bool {
  config.enable_streaming &&
  not(is_fragment) &&
  not(is_isr_with_cache(config, route_revalidate))
}

///|
fn cache_strategy_to_header_value(strategy : CacheStrategy) -> String {
  match strategy {
    CacheStrategy::AlwaysFetch => "always-fetch"
    CacheStrategy::StaleWhileRevalidate => "stale-while-revalidate"
  }
}

///|
/// Apply CDN cache headers based on CDNCacheStrategy configuration.
/// Sets Cache-Control and X-Sol-CDN-Cache headers for ISR pages.
fn apply_cdn_cache_headers(
  c : @mars.Context,
  strategy : @isr.CDNCacheStrategy?,
  revalidate : Int,
) -> Unit {
  match strategy {
    Some(s) => {
      c.set_header("Cache-Control", s.cache_control(revalidate))
      c.set_header("X-Sol-CDN-Cache", s.header_value())
    }
    None => ()
  }
}

///|
fn apply_layouts(
  content : @server_dom.ServerNode,
  props : PageProps,
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  is_fragment : Bool,
) -> @server_dom.ServerNode raise Error {
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
  node
}

///|
fn create_streaming_response_with_async(
  header : String,
  footer : String,
  shell : @luna.Node[Unit, String],
) -> @js.Any {
  ffi_create_streaming_response_async(header, footer, async fn(write) {
    @stream_renderer.render_to_stream_with_async(
      shell,
      @stream_renderer.StreamWriter::from_callback(write),
    )
  })
}

///|
async fn send_streaming_server_page(
  c : Ctx,
  node : @server_dom.ServerNode,
  title : String,
  head : String,
  loader_url : String,
  root_template : String,
) -> Unit {
  let resolved_node = node.resolve()
  let full_head = @hot_reload.with_dev_head_script(head)
  let (header_html, footer_html) = match
    @page_shell.render_streaming_template_parts(
      root_template, title, full_head, "", loader_url,
    ) {
    Some(parts) => parts
    None =>
      (
        @page_shell.render_streaming_header(title, full_head, loader_url),
        @page_shell.render_streaming_footer(),
      )
  }
  let stream = create_streaming_response_with_async(
    header_html, footer_html, resolved_node,
  )
  ffi_set_streaming_response(c, stream)
}

///|
extern "js" fn ffi_create_streaming_response_async(
  header : String,
  footer : String,
  render_with_async : async ((String) -> Unit) -> Unit,
) -> @js.Any =
  #| (header, footer, renderWithAsync) => new ReadableStream({
  #|   async start(controller) {
  #|     const encoder = new TextEncoder();
  #|     const write = (chunk) => controller.enqueue(encoder.encode(chunk));
  #|     write(header);
  #|     await renderWithAsync(write);
  #|     write(footer);
  #|     controller.close();
  #|   }
  #| })

///|
extern "js" fn ffi_set_streaming_response(ctx : Ctx, stream : @js.Any) -> Unit =
  #| (ctx, stream) => {
  #|   const headers = { 'Content-Type': 'text/html; charset=utf-8' };
  #|   const map = ctx.response_headers;
  #|   let curr = map ? map.head : undefined;
  #|   while (curr !== undefined && curr !== -1) {
  #|     headers[curr.key] = curr.value;
  #|     curr = curr.next;
  #|   }
  #|   const response = new Response(stream, { headers });
  #|   ctx.platform.response_resolve(response);
  #|   ctx.response_sent = true;
  #| }

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
  page_head : String,
  root_template : String,
  cache_strategy : CacheStrategy,
) -> String raise Error {
  // Call handler and apply layouts
  let content : @server_dom.ServerNode = handler(props)
  let node = apply_layouts(content, props, layouts, is_fragment)
  if is_fragment {
    render_server_fragment(node, title, cache_strategy)
  } else {
    render_server_page_html(node, title, page_head, root_template)
  }
}

///|
async fn handle_compiled_api_route(
  c : Ctx,
  route : CompiledSolRoute,
  middleware_chain : @middleware.Middleware,
) -> Unit {
  // Run middleware chain first
  let halted = @middleware.run_or_500(middleware_chain, c)
  if halted {
    return
  }
  let mut params = extract_route_params(
    c,
    is_fragment=false,
    param_names=route.param_names,
  )
  params = add_catch_all_param(params, route.catch_all)
  let props = PageProps::from_ctx_with_params(c, params)
  match route.api_handler {
    Some(ApiHandler(handler)) => {
      let json : @js.Any = handler(props) catch {
        e => {
          @mars_response.send_internal_error(c, message=e.to_string())
          return
        }
      }
      if c.is_response_sent() {
        return
      }
      @mars_response.send_json_any(c, json)
    }
    None => @mars_response.send_json_error(c, "No handler", status=404)
  }
}

///|
fn is_api_route_kind(kind : SolRouteKind) -> Bool {
  match kind {
    SolRouteKind::GetApi => true
    SolRouteKind::PostApi => true
    SolRouteKind::PutApi => true
    SolRouteKind::DeleteApi => true
    SolRouteKind::PatchApi => true
    SolRouteKind::Page => false
  }
}

///|
fn register_compiled_api_route(
  app : App,
  kind : SolRouteKind,
  hono_pattern : String,
  route : CompiledSolRoute,
  middleware_chain : @middleware.Middleware,
) -> Unit {
  let handler = async fn(c) {
    handle_compiled_api_route(c, route, middleware_chain)
  }
  match kind {
    SolRouteKind::GetApi => app.get(hono_pattern, handler)
    SolRouteKind::PostApi => app.post(hono_pattern, handler)
    SolRouteKind::PutApi => app.put(hono_pattern, handler)
    SolRouteKind::DeleteApi => app.delete(hono_pattern, handler)
    SolRouteKind::PatchApi => app.patch(hono_pattern, handler)
    SolRouteKind::Page => ()
  }
}

///|
fn register_compiled_sol_routes(
  app : App,
  routes : Array[CompiledSolRoute],
  config : RouterConfig,
) -> Unit {
  for route in routes {
    // Convert catch-all pattern to Hono wildcard pattern
    let hono_pattern = convert_to_hono_pattern(route.pattern, route.catch_all)
    let middleware_chain = @middleware.pipeline(route.middlewares)
    match route.kind {
      SolRouteKind::Page =>
        app.get(hono_pattern, async fn(c) {
          // Run middleware chain first
          let halted = @middleware.run_or_500(middleware_chain, c)
          if halted {
            return
          }
          let is_fragment = has_fragment_header(c)
          let mut params = extract_route_params(
            c,
            is_fragment~,
            param_names=route.param_names,
          )
          // Add catch-all parameter if present
          params = add_catch_all_param(params, route.catch_all)
          let props = PageProps::from_ctx_with_params(c, params)
          let page_title = format_title(
            route.title,
            title_prefix=config.title_prefix,
            default_title=config.default_title,
          )
          let page_head = build_page_head(config.default_head, route.meta)
          c.set_header(
            "X-Sol-Cache-Strategy",
            cache_strategy_to_header_value(route.cache_strategy),
          )
          match route.page_handler {
            Some(PageHandler(handler)) =>
              // Check if ISR is enabled for this route (only for full page requests)
              match (route.revalidate, config.isr_cache, is_fragment) {
                (Some(revalidate), Some(cache), false) => {
                  // Apply CDN cache headers if strategy is configured
                  apply_cdn_cache_headers(c, config.cache_strategy, revalidate)
                  // ISR enabled - check cache
                  let cache_key = @isr.cache_key(params.path, params.query)
                  let entry = @isr.ISRCache::get(cache, cache_key)
                  let now = @isr.now_ms()
                  let status = @isr.check_status(entry, now)
                  // Set X-Sol-ISR-Status header for diagnostics
                  let isr_status_str = match status {
                    @isr.Fresh => "HIT"
                    @isr.Stale => "STALE"
                    @isr.Miss => "MISS"
                  }
                  c.set_header("X-Sol-ISR-Status", isr_status_str)
                  // ISR render props: mark as ISR to warn against ctx header access
                  let isr_props = { ..props, is_isr_render: true }
                  match status {
                    @isr.Fresh =>
                      // Return cached HTML directly
                      match entry {
                        Some(e) => c.html(e.html)
                        None => c.text("Cache error", status=500)
                      }
                    @isr.Stale =>
                      // Return cached HTML and schedule background revalidation
                      match entry {
                        Some(e) => {
                          // Deduplicate in-flight revalidations for same cache key
                          if not(isr_in_flight.val.contains(cache_key)) {
                            isr_in_flight.val.add(cache_key)
                            @isr.ISRCache::schedule_revalidation(cache, async fn() {
                              let html = render_page_to_html(
                                c,
                                isr_props,
                                handler,
                                route.layouts,
                                false,
                                page_title,
                                page_head,
                                config.root_template,
                                route.cache_strategy,
                              ) catch {
                                _ => {
                                  isr_in_flight.val.remove(cache_key)
                                  return
                                }
                              }
                              let new_entry = @isr.CacheEntry::new(
                                html,
                                @isr.now_ms(),
                                revalidate,
                              )
                              @isr.ISRCache::put(cache, cache_key, new_entry)
                              isr_in_flight.val.remove(cache_key)
                            })
                          }
                          c.html(e.html)
                        }
                        None => c.text("Cache error", status=500)
                      }
                    @isr.Miss => {
                      // Render, cache, and return
                      let html = render_page_to_html(
                        c,
                        isr_props,
                        handler,
                        route.layouts,
                        false,
                        page_title,
                        page_head,
                        config.root_template,
                        route.cache_strategy,
                      ) catch {
                        e =>
                          return c.text("Error: " + e.to_string(), status=500)
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
                    e => return c.text("Error: " + e.to_string(), status=500)
                  }
                  if c.is_response_sent() {
                    return
                  }
                  let node = apply_layouts(
                    content,
                    props,
                    route.layouts,
                    is_fragment,
                  ) catch {
                    e =>
                      return c.text(
                        "Layout error: " + e.to_string(),
                        status=500,
                      )
                  }
                  if is_fragment {
                    let fragment_html = render_server_fragment(
                      node,
                      page_title,
                      route.cache_strategy,
                    )
                    send_fragment_response(c, fragment_html)
                  } else if should_use_streaming(
                      config,
                      is_fragment,
                      route.revalidate,
                    ) {
                    send_streaming_server_page(
                      c,
                      node,
                      page_title,
                      page_head,
                      config.loader_url,
                      config.root_template,
                    )
                  } else {
                    let html = render_server_page_html(
                      node,
                      page_title,
                      page_head,
                      config.root_template,
                    )
                    c.html(html)
                  }
                }
              }
            None => c.text("No handler for route", status=404)
          }
        })
      kind =>
        if is_api_route_kind(kind) {
          register_compiled_api_route(
            app, kind, hono_pattern, route, middleware_chain,
          )
        }
    }
  }
}

///|
/// Render ServerNode to fragment HTML (for CSR navigation)
async fn render_server_fragment(
  node : @server_dom.ServerNode,
  title : String,
  cache_strategy : CacheStrategy,
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
  buf.write_string(@page_shell.escape_html_text(title))
  buf.write_string("</template>")
  buf.write_string("<template data-sol-cache-strategy>")
  buf.write_string(cache_strategy_to_header_value(cache_strategy))
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
  let full_head = @hot_reload.with_dev_head_script(head)
  @page_shell.render_template(template, title, full_head, "", body_html)
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
