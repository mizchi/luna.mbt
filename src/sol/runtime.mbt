// Sol - SSR-first Web Framework for MoonBit
//
// Built on top of Hono, providing SSR with Luna VNodes.
// Inspired by Next.js, Solid Start, and Qwik City.
//

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

///|
/// Create a new Sol application (async)
pub async fn create_app() -> App {
  @hono.Hono::new()
}

///|
/// Check if running in dev mode (SOL_DEV env variable)
extern "js" fn is_dev_mode() -> Bool =
  #| () => process.env.SOL_DEV === "1"

///|
/// HMR client script for dev mode
let hmr_script : String = "<script>(function(){var ws=new WebSocket('ws://'+location.hostname+':24678');ws.onmessage=function(e){var m=JSON.parse(e.data);if(m.type==='update'){location.reload()}else if(m.type==='full-reload'){location.reload()}else if(m.type==='error'){console.error('[HMR]',m.message)}};ws.onclose=function(){console.log('[HMR] Disconnected, reconnecting...');setTimeout(function(){location.reload()},1000)}})()</script>"

///|
extern "js" fn ffi_init_fs() -> @js.Promise[Unit] =
  #| () => import('node:fs').then(fs => { globalThis.__SOL_FS__ = fs; })

///|
extern "js" fn ffi_new_hono_async() -> @js.Promise[@js.Any] =
  #| () => import("hono").then(m => new m.Hono())

///|
/// Create a new Sol application and run callback with it
/// This is useful for main function that cannot be async
pub fn create_app_then(callback : (App) -> Unit) -> Unit {
  // Initialize fs module first, then create Hono app
  let _ = ffi_init_fs().then(fn(_) {
    ffi_new_hono_async().then(fn(app) {
      callback(app.cast())
      @js.Promise::resolve(@js.any(()))
    })
  })

}

// ============================================================================
// Application Runner (reduces boilerplate)
// ============================================================================

///|
/// Global app reference for non-Node runtimes (Cloudflare, Deno, Bun)
/// This is set by run() and exported as __SOL_APP__
let sol_app_ref : Ref[App?] = { val: None }

///|
extern "js" fn ffi_export_sol_app(app : @js.Any) -> Unit =
  #| (app) => { globalThis.__SOL_APP__ = app; }

///|
/// Check if running in Node.js environment
extern "js" fn ffi_is_node() -> Bool =
  #| () => typeof process !== 'undefined' && process.versions?.node != null

///|
/// Run a Sol application with standard configuration
/// This is the recommended way to start a Sol server.
///
/// Example:
/// ```moonbit
/// fn main {
///   @sol.run(fn(app) { @sol.page(app, "/", home_page) |> @sol.serve_static() })
/// }
/// ```
pub fn run(configure : (App) -> App, port? : Int) -> Unit {
  let port = port.unwrap_or_else(get_port)
  create_app_then(fn(app) {
    let app = configure(app)
    // Store app reference for non-Node runtimes
    sol_app_ref.val = Some(app)
    // Export app globally for entry point access
    ffi_export_sol_app(app.as_any())
    // Only start server in Node.js environment
    if ffi_is_node() {
      println("Server running at http://localhost:" + port.to_string())
      serve(app, port)
    }
    // For other runtimes (Cloudflare, Deno, Bun), the entry point handles startup
  })
}

///|
/// Render a VNode to HTML string with full document wrapper
/// Use hydration=true to enable hydration markers (for pages with Islands)
pub fn[E] render_page(
  node : @luna.Node[E],
  title? : String,
  head? : String,
  hydration? : Bool,
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let enable_hydration = hydration.unwrap_or(false)
  let body_html = if enable_hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title_str +
  "</title>" +
  head_str +
  "</head><body><div id=\"app\">" +
  body_html +
  "</div></body></html>"
}

///|
/// Render a VNode to HTML string without document wrapper (for partial/fragment responses)
pub fn[E] render_fragment(node : @luna.Node[E]) -> String {
  @render.render_to_string_with_hydration(node)
}

///|
/// Register a page route that renders a VNode
/// Use hydration=true for pages with Islands (adds loader script and hydration markers)
pub fn[E] page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[E],
  title? : String,
  head? : String,
  hydration? : Bool,
  loader_url? : String,
) -> App {
  app.get(path, fn(c) {
    let node = render_fn(c)
    let enable_hydration = hydration.unwrap_or(false)
    // Add HMR script in dev mode
    let dev_script = if is_dev_mode() { hmr_script } else { "" }
    if enable_hydration {
      // Hydration enabled: render with hydration markers and include loader script
      let loader = loader_url.unwrap_or(default_loader_url)
      let loader_script = "<script type=\"module\" src=\"" +
        loader +
        "\"></script>"
      let full_head = head.unwrap_or("") + loader_script + dev_script
      let html = render_page(node, title?, head=full_head, hydration=true)
      c.html(html)
    } else {
      // Static page: render without hydration (but still add HMR in dev)
      let full_head = head.unwrap_or("") + dev_script
      let html = render_page(node, title?, head=full_head)
      c.html(html)
    }
  })
}

///|
/// Register an API route that returns JSON
pub fn api(app : App, path : String, handler : (Ctx) -> @js.Any) -> App {
  app.get(path, fn(c) { c.json(handler(c)) })
}

///|
/// Create a plain JavaScript object from key-value pairs
/// Use this for API responses instead of MoonBit Map
extern "js" fn ffi_create_json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any =
  #| (pairs) => Object.fromEntries(pairs.map(p => [p._0, p._1]))

///|
/// Create a JSON object for API responses
pub fn json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any {
  ffi_create_json_obj(pairs)
}

///|
/// Register a POST API route
pub fn api_post(app : App, path : String, handler : (Ctx) -> @js.Any) -> App {
  app.post(path, fn(c) { c.json(handler(c)) })
}

///|
/// Serve the app using @hono/node-server
pub fn serve(app : App, port : Int) -> Unit {
  ffi_serve(app.as_any(), port)
}

///|
extern "js" fn ffi_serve(app : @js.Any, port : Int) -> Unit =
  #|(app, port) => {
  #|  import('@hono/node-server').then(({ serve }) => {
  #|    serve({ fetch: app.fetch, port });
  #|  });
  #|}

///|
/// Get port from PORT environment variable, default to 3000
pub fn get_port() -> Int {
  ffi_get_port()
}

///|
extern "js" fn ffi_get_port() -> Int =
  #| () => parseInt(process.env.PORT || '3000', 10)

///|
/// Set environment variable
pub fn set_env(key : String, value : String) -> Unit {
  ffi_set_env(key, value)
}

///|
extern "js" fn ffi_set_env(key : String, value : String) -> Unit =
  #| (key, value) => { process.env[key] = value }

// ============================================================================
// Island Architecture Support
// ============================================================================

///|
/// Default loader script URL
pub let default_loader_url : String = "/loader.js"

///|
/// Island configuration
pub struct IslandConfig[E] {
  /// Unique identifier for the island
  id : String
  /// ES module URL for hydration script
  script_url : String
  /// Hydration trigger type
  trigger : @luna.TriggerType
  /// State configuration
  state : @stella.StateConfig
  /// SSR rendered content (VNode)
  content : @luna.Node[E]?
  /// SSR rendered HTML string (alternative to content)
  ssr_html : String?
}

///|
/// Create a new island configuration
pub fn[E] IslandConfig::new(
  id : String,
  script_url : String,
) -> IslandConfig[E] {
  {
    id,
    script_url,
    trigger: @luna.TriggerType::Load,
    state: @stella.StateConfig::Empty,
    content: None,
    ssr_html: None,
  }
}

///|
/// Builder: set trigger type
pub fn[E] IslandConfig::with_trigger(
  self : IslandConfig[E],
  trigger : @luna.TriggerType,
) -> IslandConfig[E] {
  { ..self, trigger, }
}

///|
/// Builder: set inline state from JSON
pub fn[E] IslandConfig::with_state(
  self : IslandConfig[E],
  json : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::Inline(json) }
}

///|
/// Builder: set state from script reference
pub fn[E] IslandConfig::with_state_ref(
  self : IslandConfig[E],
  script_id : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::ScriptRef(script_id) }
}

///|
/// Builder: set state from URL
pub fn[E] IslandConfig::with_state_url(
  self : IslandConfig[E],
  url : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::Url(url) }
}

///|
/// Builder: set SSR content from VNode
pub fn[E] IslandConfig::with_content(
  self : IslandConfig[E],
  node : @luna.Node[E],
) -> IslandConfig[E] {
  { ..self, content: Some(node) }
}

///|
/// Builder: set SSR content from raw HTML string
pub fn[E] IslandConfig::with_ssr_html(
  self : IslandConfig[E],
  html : String,
) -> IslandConfig[E] {
  { ..self, ssr_html: Some(html) }
}

///|
/// Render an island to HTML string
pub fn[E] render_island(config : IslandConfig[E]) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @render.render_to_string_with_hydration(node)
        None => ""
      }
  }

  // Convert state to shard format
  let shard_config = @stella.ShardConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)

  // Apply state configuration
  let final_config = match config.state {
    @stella.StateConfig::Empty => shard_config
    @stella.StateConfig::Inline(json) => shard_config.with_state(json)
    @stella.StateConfig::ScriptRef(id) => shard_config.with_state_ref(id)
    @stella.StateConfig::Url(url) => shard_config.with_state_url(url)
  }
  @stella.generate_shard(final_config).html
}

///|
/// Render a page with islands
/// Includes the loader script automatically
pub fn render_island_page(
  islands : Array[String],
  title? : String,
  head? : String,
  loader_url? : String,
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let loader = loader_url.unwrap_or(default_loader_url)
  let sb = StringBuilder::new(size_hint=4096)
  sb.write_string(
    "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>",
  )
  sb.write_string(title_str)
  sb.write_string("</title>")
  sb.write_string(head_str)
  sb.write_string("<script type=\"module\" src=\"")
  sb.write_string(loader)
  sb.write_string("\"></script></head><body>")
  for island_html in islands {
    sb.write_string(island_html)
  }
  sb.write_string("</body></html>")
  sb.to_string()
}

///|
/// Register an island page route
pub fn[E] island_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> Array[IslandConfig[E]],
  title? : String,
  head? : String,
  loader_url? : String,
) -> App {
  app.get(path, fn(c) {
    let islands = render_fn(c)
    let island_htmls = islands.map(fn(config) { render_island(config) })
    let html = render_island_page(island_htmls, title?, head?, loader_url?)
    c.html(html)
  })
}

///|
/// Render island with separate state script (for large state)
pub fn[E] render_island_with_state_script(
  config : IslandConfig[E],
  state_json : String,
) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @render.render_to_string_with_hydration(node)
        None => ""
      }
  }
  let shard_config = @stella.ShardConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)
  @stella.generate_shard_with_state_script(shard_config, state_json).html
}

///|
/// Generate state script tag for external state
pub fn generate_state_script(id : String, json : String) -> String {
  @stella.generate_state_script(id, json)
}

///|
/// Escape JSON for safe embedding in HTML attributes
/// @deprecated Use `@render.escape_json_for_attr` instead
#deprecated("Use @render.escape_json_for_attr instead")
pub fn escape_json_for_attr(json : String) -> String {
  @render.escape_json_for_attr(json)
}

///|
/// Escape JSON for safe embedding in script tags
/// @deprecated Use `@render.escape_json_for_script` instead
#deprecated("Use @render.escape_json_for_script instead")
pub fn escape_json_for_html(json : String) -> String {
  @render.escape_json_for_script(json)
}

// ============================================================================
// Island VNode Support (using @luna.island)
// ============================================================================

///|
/// Create an Island VNode from a component render function
/// This is the recommended way to create Islands with type-safe VNode children
pub fn[E] island(
  id : String,
  url : String,
  state : String,
  children : Array[@luna.Node[E]],
  trigger? : @luna.TriggerType = @luna.Load,
) -> @luna.Node[E] {
  @luna.island(id, url, state, children, trigger~)
}

///|
/// Create an Island VNode with a render function for children
pub fn[E] island_with(
  id : String,
  url : String,
  state : String,
  render : () -> @luna.Node[E],
  trigger? : @luna.TriggerType = @luna.Load,
) -> @luna.Node[E] {
  @luna.island(id, url, state, [render()], trigger~)
}

///|
/// Render a VNode to HTML string
/// Use hydration=true to enable hydration markers
pub fn[E] render_node(
  node : @luna.Node[E],
  hydration? : Bool = false,
) -> String {
  if hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }
}

// ============================================================================
// Web Components Island VNode Support (using @luna.wc_island)
// ============================================================================

///|
/// Default wc-loader script URL
pub let default_wc_loader_url : String = "/static/wc-loader.js"

///|
/// Create a Web Components Island VNode
/// Uses Declarative Shadow DOM for SSR and wc-loader for hydration
pub fn[E] wc_island(
  name : String,
  url : String,
  styles : String,
  state : String,
  children : Array[@luna.Node[E]],
  trigger? : @luna.TriggerType = @luna.Load,
) -> @luna.Node[E] {
  @luna.wc_island(name, url, styles, state, children, trigger~)
}

///|
/// Create a Web Components Island VNode with a render function for children
pub fn[E] wc_island_with(
  name : String,
  url : String,
  styles : String,
  state : String,
  render : () -> @luna.Node[E],
  trigger? : @luna.TriggerType = @luna.Load,
) -> @luna.Node[E] {
  @luna.wc_island(name, url, styles, state, [render()], trigger~)
}

///|
/// Register a page route with Web Components islands
/// Uses wc-loader for hydration
pub fn[E] wc_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[E],
  title? : String,
  head? : String,
  wc_loader_url? : String,
) -> App {
  app.get(path, fn(c) {
    let node = render_fn(c)
    let loader = wc_loader_url.unwrap_or(default_wc_loader_url)
    let loader_script = "<script type=\"module\" src=\"" +
      loader +
      "\"></script>"
    // Add HMR script in dev mode
    let dev_script = if is_dev_mode() { hmr_script } else { "" }
    let full_head = head.unwrap_or("") + loader_script + dev_script
    let html = render_page(node, title?, head=full_head, hydration=true)
    c.html(html)
  })
}

// ============================================================================
// Streaming SSR Support
// ============================================================================

///|
/// Render a page with streaming SSR and async boundaries (VAsync nodes)
/// Returns a ReadableStream for HTTP response
/// VAsync nodes in the tree will be rendered with fallback first,
/// then resolved content will be streamed as replacement scripts
pub fn render_streaming_page(
  shell : @luna.Node[Unit],
  title? : String,
  head? : String,
  loader_url? : String,
) -> @http.Response {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let loader = loader_url.unwrap_or(default_loader_url)

  // Build header HTML
  let header_html = "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
    title_str +
    "</title>" +
    head_str +
    "<script type=\"module\" src=\"" +
    loader +
    "\"></script></head><body><div id=\"app\">"

  // Build footer HTML
  let footer_html = "</div></body></html>"

  // Create streaming response with async resolution
  let stream = create_streaming_response_with_async(
    header_html, footer_html, shell,
  )
  ffi_create_stream_response(stream)
}

///|
/// Create a ReadableStream that streams HTML with async resolution
fn create_streaming_response_with_async(
  header : String,
  footer : String,
  shell : @luna.Node[Unit],
) -> @js.Any {
  ffi_create_streaming_response_async(header, footer, async fn(write) {
    // Use render_to_stream_with_async which handles VAsync nodes
    @stream_renderer.render_to_stream_with_async(
      shell,
      @stream_renderer.StreamWriter::from_callback(write),
    )
  })
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
extern "js" fn ffi_create_stream_response(stream : @js.Any) -> @http.Response =
  #| (stream) => new Response(stream, { headers: { 'Content-Type': 'text/html; charset=utf-8' } })

///|
/// Register a streaming page route with async support
/// VAsync nodes in the rendered tree will be handled automatically
pub fn streaming_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[Unit],
  title? : String,
  head? : String,
  loader_url? : String,
) -> App {
  app.get(path, fn(c) {
    let shell = render_fn(c)
    let title_str = title.unwrap_or("App")
    let head_str = head.unwrap_or("")
    let loader = loader_url.unwrap_or(default_loader_url)
    let header_html = "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
      title_str +
      "</title>" +
      head_str +
      "<script type=\"module\" src=\"" +
      loader +
      "\"></script></head><body><div id=\"app\">"
    let footer_html = "</div></body></html>"
    let stream = create_streaming_response_with_async(
      header_html, footer_html, shell,
    )
    ffi_create_stream_response(stream)
  })
}

///|
/// Render a VNode to HTML with preload URLs for islands
/// Returns SSRResult with html and preload_urls
pub fn[E] render_with_island_preloads(
  node : @luna.Node[E],
) -> @render.SSRResult {
  @render.render_to_string(node, preload=true)
}

///|
/// Render a page with automatic modulepreload tags for islands
pub fn[E] render_page_with_preloads(
  node : @luna.Node[E],
  title? : String,
  head? : String,
  hydration? : Bool,
) -> String {
  let title_str = title.unwrap_or("App")
  let enable_hydration = hydration.unwrap_or(false)

  // Render and collect preload URLs
  let _ = enable_hydration // Reserved for future use
  let result = @render.render_to_string(node, preload=true)

  // Generate preload tags
  let preload_tags = @render.generate_preload_tags(result.preload_urls)

  // Combine head with preload tags
  let head_str = head.unwrap_or("") + preload_tags
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title_str +
  "</title>" +
  head_str +
  "</head><body><div id=\"app\">" +
  result.html +
  "</div></body></html>"
}

// ============================================================================
// Static File Serving
// ============================================================================

///|
extern "js" fn ffi_create_js_response(
  body : String,
  content_type : String,
) -> @http.Response =
  #| (body, contentType) => new Response(body, { headers: { 'Content-Type': contentType } })

///|
/// Create a response for static files with security headers
extern "js" fn ffi_create_static_response(
  body : String,
  content_type : String,
  cache_control : String,
) -> @http.Response =
  #| (body, contentType, cacheControl) => new Response(body, { headers: { 'Content-Type': contentType, 'X-Content-Type-Options': 'nosniff', 'Cache-Control': cacheControl } })

///|
extern "js" fn ffi_read_file_sync(path : String) -> String? =
  #| (path) => {
  #|   try {
  #|     if (!globalThis.__SOL_FS__) {
  #|       throw new Error('fs module not initialized. Call __SOL_INIT_FS__ first.');
  #|     }
  #|     return globalThis.__SOL_FS__.readFileSync(path, 'utf-8');
  #|   } catch (e) {
  #|     return undefined;
  #|   }
  #| }

///|
extern "js" fn ffi_get_req_path(c : @js.Any) -> String =
  #| (c) => new URL(c.req.url).pathname

///|
/// Create a text response with content type
pub fn text_response(body : String, content_type : String) -> @http.Response {
  ffi_create_js_response(body, content_type)
}

///|
/// Create a JavaScript response
pub fn js_response(body : String) -> @http.Response {
  ffi_create_js_response(body, "application/javascript")
}

///|
/// Create a static file response with security headers
pub fn static_response(
  body : String,
  content_type : String,
  cache_control? : String,
) -> @http.Response {
  let cache = cache_control.unwrap_or("max-age=3600")
  ffi_create_static_response(body, content_type, cache)
}

///|
/// Read file synchronously (for static file serving)
pub fn read_file_sync(path : String) -> String? {
  ffi_read_file_sync(path)
}

///|
/// Get request pathname from context
pub fn get_request_path(ctx : Ctx) -> String {
  ffi_get_req_path(ctx.as_any())
}

///|
/// Static file configuration
pub struct StaticFileConfig {
  /// URL path prefix (e.g., "/static")
  path_prefix : String
  /// Local directory path (e.g., "static")
  local_dir : String
  /// File mappings: (url_filename, local_path)
  mappings : Array[(String, String)]
}

///|
/// Create default static file config for Luna apps
pub fn StaticFileConfig::default() -> StaticFileConfig {
  {
    path_prefix: "/static",
    local_dir: "static",
    mappings: [("loader.js", "static/loader.js")],
  }
}

///|
/// Builder: add file mapping
pub fn StaticFileConfig::with_mapping(
  self : StaticFileConfig,
  url_filename : String,
  local_path : String,
) -> StaticFileConfig {
  let new_mappings = self.mappings.copy()
  new_mappings.push((url_filename, local_path))
  { ..self, mappings: new_mappings }
}

///|
/// Configuration for serving a static directory (SSG output)
pub(all) struct StaticDirServeConfig {
  /// URL path prefix (e.g., "/docs")
  path_prefix : String
  /// Local directory path (relative to cwd)
  local_dir : String
}

///|
/// Create default StaticDirServeConfig
pub fn StaticDirServeConfig::new(
  path_prefix : String,
  _source_dir : String,
) -> StaticDirServeConfig {
  // Map to .sol/prod/static/{path_prefix}
  let local_dir = ".sol/prod/static" +
    path_prefix.trim_end(chars="/").to_string()
  { path_prefix, local_dir }
}

///|
/// Register a static directory for serving SSG output
/// This serves HTML files from .sol/prod/static/{path_prefix}
pub fn serve_static_dir(app : App, config : StaticDirServeConfig) -> App {
  let prefix = config.path_prefix.trim_end(chars="/").to_string()
  let local_dir = config.local_dir

  // Serve index.html for directory roots
  let app = app.get(prefix, fn(c) {
    serve_static_html(c, local_dir, "index.html")
  })

  // Serve all paths under the prefix
  app.get(prefix + "/*", fn(c) {
    let path = get_request_path(c)
    let start_idx = prefix.length() + 1
    let rest = path[start_idx:].to_string().trim_end(chars="/").to_string()

    // Try exact path first, then as directory index
    if rest.is_empty() {
      serve_static_html(c, local_dir, "index.html")
    } else if rest.has_suffix(".html") {
      serve_static_html(c, local_dir, rest)
    } else if rest.has_suffix(".css") {
      serve_static_css(c, local_dir, rest)
    } else if rest.has_suffix(".js") {
      serve_static_js(c, local_dir, rest)
    } else {
      // Try as directory with index.html
      serve_static_html(c, local_dir, rest + "/index.html")
    }
  })
}

///|
fn serve_static_html(
  _c : Ctx,
  local_dir : String,
  filename : String,
) -> @http.Response {
  let path = local_dir + "/" + filename
  match read_file_sync(path) {
    Some(content) => html_response(content)
    None => text_response("Not found: " + filename, "text/plain")
  }
}

///|
fn serve_static_css(
  _c : Ctx,
  local_dir : String,
  filename : String,
) -> @http.Response {
  let path = local_dir + "/" + filename
  match read_file_sync(path) {
    Some(content) => text_response(content, "text/css")
    None => text_response("/* Not found: " + filename + " */", "text/css")
  }
}

///|
fn serve_static_js(
  _c : Ctx,
  local_dir : String,
  filename : String,
) -> @http.Response {
  let path = local_dir + "/" + filename
  match read_file_sync(path) {
    Some(content) => text_response(content, "application/javascript")
    None => text_response("// Not found: " + filename, "application/javascript")
  }
}

///|
fn html_response(content : String) -> @http.Response {
  text_response(content, "text/html; charset=utf-8")
}

///|
/// Register static file serving middleware
pub fn serve_static(app : App, config? : StaticFileConfig) -> App {
  let cfg = config.unwrap_or(StaticFileConfig::default())
  let prefix = cfg.path_prefix
  let mappings = cfg.mappings
  app.get(prefix + "/*", fn(c) {
    let path = get_request_path(c)
    let start_idx = prefix.length() + 1
    let filename = path[start_idx:].to_string() // Remove prefix + "/"

    // Check mappings
    for mapping in mappings {
      let (url_file, local_path) = mapping
      if filename == url_file {
        match read_file_sync(local_path) {
          Some(content) => {
            let content_type = if url_file.has_suffix(".js") {
              "application/javascript"
            } else if url_file.has_suffix(".css") {
              "text/css"
            } else {
              "text/plain"
            }
            return static_response(content, content_type)
          }
          None =>
            return static_response(
              "// " + url_file + " not found",
              "application/javascript",
            )
        }
      }
    }

    // Fallback: try to read from local_dir/filename, then .sol/{dev,prod}/static/filename
    // Dev is checked first as it's more commonly used during development
    let local_path = cfg.local_dir + "/" + filename
    let sol_dev_path = ".sol/dev/static/" + filename
    let sol_prod_path = ".sol/prod/static/" + filename
    let content = match read_file_sync(local_path) {
      Some(c) => Some(c)
      None =>
        match read_file_sync(sol_dev_path) {
          Some(c) => Some(c)
          None => read_file_sync(sol_prod_path)
        }
    }
    match content {
      Some(c) => {
        let content_type = if filename.has_suffix(".js") {
          "application/javascript"
        } else if filename.has_suffix(".css") {
          "text/css"
        } else if filename.has_suffix(".html") {
          "text/html"
        } else {
          "text/plain"
        }
        static_response(c, content_type)
      }
      None => static_response("Not found: " + filename, "text/plain")
    }
  })
}
