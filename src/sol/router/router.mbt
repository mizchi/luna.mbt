// Sol Router - Server-side routing based on core/routes
//
// This module bridges core/routes definitions to Hono server routing.
// It provides type-safe routing with support for Pages, Islands, and APIs.

// ============================================================================
// HMR (Hot Module Replacement) Support
// ============================================================================

///|
/// Check if running in dev mode (SOL_DEV env variable)
extern "js" fn is_dev_mode() -> Bool =
  #| () => process.env.SOL_DEV === "1"

///|
/// HMR client script for dev mode (auto-reconnect on disconnect)
let hmr_script : String = "<script>(function(){var ws=new WebSocket('ws://'+location.hostname+':24678');ws.onmessage=function(e){var m=JSON.parse(e.data);if(m.type==='update'||m.type==='full-reload'){location.reload()}else if(m.type==='error'){console.error('[HMR]',m.message)}};ws.onclose=function(){setTimeout(function(){location.reload()},1000)}})()</script>"

// ============================================================================
// Router Configuration
// ============================================================================

///|
/// Chunk manifest entry (from Rolldown/Vite manifest.json)
/// Maps entry files to their output chunks and dependencies
pub struct ChunkManifestEntry {
  /// Output file path (e.g., "counter.js")
  file : String
  /// Import dependencies (e.g., ["_shared/client-abc123.js"])
  imports : Array[String]
}

///|
/// Create a chunk manifest entry
pub fn ChunkManifestEntry::new(
  file : String,
  imports : Array[String],
) -> ChunkManifestEntry {
  { file, imports }
}

///|
/// Chunk manifest - maps entry names to their output info
/// Used to resolve shared chunk dependencies for preloading
pub struct ChunkManifest {
  /// Map of entry name -> manifest entry
  entries : Map[String, ChunkManifestEntry]
  /// Base URL prefix for chunks (e.g., "/static/")
  base_url : String
}

///|
/// Create empty chunk manifest
pub fn ChunkManifest::empty() -> ChunkManifest {
  { entries: {}, base_url: "/static/" }
}

///|
/// Create chunk manifest with base URL
pub fn ChunkManifest::new(base_url : String) -> ChunkManifest {
  { entries: {}, base_url }
}

///|
/// Add entry to manifest
pub fn ChunkManifest::add(
  self : ChunkManifest,
  name : String,
  entry : ChunkManifestEntry,
) -> Unit {
  self.entries[name] = entry
}

///|
/// Get all chunk URLs for an entry (including dependencies)
pub fn ChunkManifest::get_chunks(
  self : ChunkManifest,
  entry_url : String,
) -> Array[String] {
  // Extract entry name from URL (e.g., "/static/counter.js" -> "counter.js")
  let entry_name = extract_entry_name(entry_url, self.base_url)
  match self.entries.get(entry_name) {
    Some(entry) => {
      let chunks : Array[String] = []
      // Add all import dependencies with base URL prefix
      for imp in entry.imports {
        let chunk_url = self.base_url + imp
        if not(chunks.contains(chunk_url)) {
          chunks.push(chunk_url)
        }
      }
      chunks
    }
    None => []
  }
}

///|
fn extract_entry_name(url : String, base_url : String) -> String {
  if url.has_prefix(base_url) {
    // Remove base_url prefix
    let result = url[base_url.length():].to_string() catch { _ => url }
    result
  } else {
    // Find last slash and get filename
    let mut last_slash = -1
    let chars = url.to_array()
    for i = 0; i < chars.length(); i = i + 1 {
      if chars[i] == '/' {
        last_slash = i
      }
    }
    if last_slash >= 0 && last_slash < url.length() - 1 {
      let result = url[last_slash + 1:].to_string() catch { _ => url }
      result
    } else {
      url
    }
  }
}

///|
/// Parse chunk manifest from JSON string (Rolldown/Vite format)
pub fn ChunkManifest::parse(
  json_str : String,
  base_url : String,
) -> ChunkManifest? {
  let json : Json = @json.parse(json_str) catch { _ => return None }
  let obj = match json {
    Object(o) => o
    _ => return None
  }
  let manifest = ChunkManifest::new(base_url)
  for entry in obj {
    let name = entry.0
    let entry_obj = match entry.1 {
      Object(o) => o
      _ => continue
    }
    // Get "file" field
    let file = match entry_obj.get("file") {
      Some(String(s)) => s
      _ => continue
    }
    // Get "imports" field (optional)
    let imports : Array[String] = match entry_obj.get("imports") {
      Some(Array(arr)) => {
        let result : Array[String] = []
        for item in arr {
          match item {
            String(s) => result.push(s)
            _ => continue
          }
        }
        result
      }
      _ => []
    }
    manifest.add(name, { file, imports })
  }
  Some(manifest)
}

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
  /// URL for the Web Components loader script
  wc_loader_url : String
  /// Enable modulepreload for island scripts (default: true)
  enable_preload : Bool
  /// Additional library URLs to preload (e.g., ["/static/lib.js"])
  preload_libs : Array[String]
  /// Chunk manifest for resolving shared chunk dependencies
  chunk_manifest : ChunkManifest?
  /// Root HTML template with placeholders:
  /// - __LUNA_TITLE__ : Page title
  /// - __LUNA_PRELOAD__ : Modulepreload tags
  /// - __LUNA_HEAD__ : Custom head HTML
  /// - __LUNA_MAIN__ : Main content
  root_template : String
}

///|
/// Default root HTML template
pub fn default_root_template() -> String {
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>__LUNA_TITLE__</title>__LUNA_PRELOAD____LUNA_HEAD__</head><body><div id=\"__sol__\">__LUNA_MAIN__</div></body></html>"
}

///|
/// Create default router configuration
pub fn RouterConfig::default() -> RouterConfig {
  {
    title_prefix: "",
    default_title: "App",
    default_head: "",
    loader_url: "/static/loader.js",
    wc_loader_url: "/static/wc-loader.js",
    enable_preload: true,
    preload_libs: [],
    chunk_manifest: None,
    root_template: default_root_template(),
  }
}

///|
/// Set chunk manifest for resolving shared chunk dependencies
pub fn RouterConfig::with_chunk_manifest(
  self : RouterConfig,
  manifest : ChunkManifest,
) -> RouterConfig {
  { ..self, chunk_manifest: Some(manifest) }
}

///|
/// Add library URLs to preload
pub fn RouterConfig::with_preload_libs(
  self : RouterConfig,
  libs : Array[String],
) -> RouterConfig {
  { ..self, preload_libs: libs }
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
/// Set Web Components loader URL
pub fn RouterConfig::with_wc_loader_url(
  self : RouterConfig,
  url : String,
) -> RouterConfig {
  { ..self, wc_loader_url: url }
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

///|
/// Set root HTML template
/// Template placeholders:
/// - __LUNA_TITLE__ : Page title
/// - __LUNA_PRELOAD__ : Modulepreload tags
/// - __LUNA_HEAD__ : Custom head HTML
/// - __LUNA_MAIN__ : Main content
pub fn RouterConfig::with_root_template(
  self : RouterConfig,
  template : String,
) -> RouterConfig {
  { ..self, root_template: template }
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
  /// URLPatternResult for advanced pattern matching (optional)
  url_pattern_result : @url.URLPatternResult?
}

///|
/// Create empty route params
pub fn RouteParams::empty() -> RouteParams {
  { params: [], query: [], path: "", is_fragment: false, url_pattern_result: None }
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

///|
/// Get pathname group from URLPatternResult
/// Returns None if URLPatternResult is not available or group doesn't exist
pub fn RouteParams::get_pathname_group(
  self : RouteParams,
  name : String,
) -> String? {
  match self.url_pattern_result {
    Some(result) => {
      let value = result.pathname.groups[name]
      if @js.is_nullish(value) {
        None
      } else {
        Some(@js.identity(value))
      }
    }
    None => None
  }
}

///|
/// Get search group from URLPatternResult
/// Returns None if URLPatternResult is not available or group doesn't exist
pub fn RouteParams::get_search_group(
  self : RouteParams,
  name : String,
) -> String? {
  match self.url_pattern_result {
    Some(result) => {
      let value = result.search.groups[name]
      if @js.is_nullish(value) {
        None
      } else {
        Some(@js.identity(value))
      }
    }
    None => None
  }
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

///|
/// Get path parameter by name (convenience method)
pub fn PageProps::get_param(self : PageProps, key : String) -> String? {
  self.params.get_param(key)
}

///|
/// Get query parameter by name (convenience method)
pub fn PageProps::get_query(self : PageProps, key : String) -> String? {
  self.params.get_query(key)
}

///|
/// Get pathname group from URLPatternResult (convenience method)
pub fn PageProps::get_pathname_group(self : PageProps, name : String) -> String? {
  self.params.get_pathname_group(name)
}

///|
/// Get search group from URLPatternResult (convenience method)
pub fn PageProps::get_search_group(self : PageProps, name : String) -> String? {
  self.params.get_search_group(name)
}

///|
/// Get the full path
pub fn PageProps::path(self : PageProps) -> String {
  self.params.path
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
  wc_loader_url? : String = "/static/wc-loader.js",
) -> App {
  // Use config if provided, otherwise use individual parameters
  let (tp, dt, dh, lu, wlu, ep, pl, cm, rt) = match config {
    Some(c) =>
      (
        c.title_prefix,
        c.default_title,
        c.default_head,
        c.loader_url,
        c.wc_loader_url,
        c.enable_preload,
        c.preload_libs,
        c.chunk_manifest,
        c.root_template,
      )
    None =>
      (
        title_prefix,
        default_title,
        default_head,
        loader_url,
        wc_loader_url,
        true,
        [],
        None,
        default_root_template(),
      )
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
    wc_loader_url=wlu,
    enable_preload=ep,
    preload_libs=pl,
    chunk_manifest=cm,
    root_template=rt,
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
  wc_loader_url~ : String,
  enable_preload~ : Bool,
  preload_libs~ : Array[String],
  chunk_manifest~ : ChunkManifest?,
  root_template~ : String,
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
                  node, page_title, false,
                )
                send_fragment_response(c, fragment_html)
              } else {
                let html = render_page_html(
                  node,
                  page_title,
                  default_head,
                  false,
                  root_template,
                  enable_preload~,
                  preload_libs~,
                  chunk_manifest~,
                )
                c.html(html)
              }
            }
            None => c.text("Page not found: " + component)
          }
        })
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
          wc_loader_url~,
          enable_preload~,
          preload_libs~,
          chunk_manifest~,
          root_template~,
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
fn extract_route_params(c : Ctx, is_fragment? : Bool = false) -> RouteParams {
  let params = ffi_get_all_params(c.as_any())
  let query = ffi_get_query_params(c.as_any())
  let path = ffi_get_path(c.as_any())
  { params, query, path, is_fragment, url_pattern_result: None }
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
/// Render VNode to full HTML page with template-based rendering
fn[E] render_page_html(
  node : @luna.Node[E],
  title : String,
  head : String,
  hydration : Bool,
  template : String,
  enable_preload? : Bool = true,
  preload_libs? : Array[String] = [],
  chunk_manifest? : ChunkManifest? = None,
) -> String {
  let (body_html, preload_tags) = if hydration {
    // With hydration, always collect preload URLs
    let result = @render.render_to_string(node, preload=enable_preload)
    let tags = if enable_preload {
      // Build preload URLs: libs first, then chunks for each island, then islands
      let all_urls = preload_libs.copy()
      // Add chunk dependencies for each island URL (if manifest provided)
      match chunk_manifest {
        Some(manifest) =>
          for url in result.preload_urls {
            // Add chunk dependencies for this entry
            let chunks = manifest.get_chunks(url)
            for chunk in chunks {
              if not(all_urls.contains(chunk)) {
                all_urls.push(chunk)
              }
            }
          }
        None => ()
      }
      // Add island entry URLs
      for url in result.preload_urls {
        if not(all_urls.contains(url)) {
          all_urls.push(url)
        }
      }
      @render.generate_preload_tags(all_urls)
    } else {
      ""
    }
    // Add hydration markers
    let html = @render.render_to_string_with_hydration(node)
    (html, tags)
  } else {
    let result = @render.render_to_string(node, preload=enable_preload)
    let tags = if enable_preload {
      // Build preload URLs: libs first, then chunks for each island, then islands
      let all_urls = preload_libs.copy()
      // Add chunk dependencies for each island URL (if manifest provided)
      match chunk_manifest {
        Some(manifest) =>
          for url in result.preload_urls {
            // Add chunk dependencies for this entry
            let chunks = manifest.get_chunks(url)
            for chunk in chunks {
              if not(all_urls.contains(chunk)) {
                all_urls.push(chunk)
              }
            }
          }
        None => ()
      }
      // Add island entry URLs
      for url in result.preload_urls {
        if not(all_urls.contains(url)) {
          all_urls.push(url)
        }
      }
      @render.generate_preload_tags(all_urls)
    } else {
      ""
    }
    (result.html, tags)
  }
  // Add HMR script in dev mode
  let full_head = if is_dev_mode() { head + hmr_script } else { head }
  // Replace placeholders in template
  template
  .replace(old="__LUNA_TITLE__", new=title)
  .replace(old="__LUNA_PRELOAD__", new=preload_tags)
  .replace(old="__LUNA_HEAD__", new=full_head)
  .replace(old="__LUNA_MAIN__", new=body_html)
}

// ============================================================================
// Async Server Routes Registration (ServerNode support)
// ============================================================================

///|
/// Async page resolver type - returns ServerNode for async server components
pub type AsyncPageResolver = (String, Ctx, RouteParams) -> @server_dom.ServerNode?

///|
/// Register routes with async server component support
/// Uses ServerNode which supports both sync and async server components
pub fn register_server_routes(
  app : App,
  routes : Array[@routes.Routes],
  page_resolver : AsyncPageResolver,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
  config? : RouterConfig,
  title_prefix? : String = "",
  default_title? : String = "App",
  default_head? : String = "",
  loader_url? : String = "/static/loader.js",
  wc_loader_url? : String = "/static/wc-loader.js",
) -> App {
  // Use config if provided, otherwise use individual parameters
  let (tp, dt, dh, lu, wlu, rt) = match config {
    Some(c) =>
      (
        c.title_prefix,
        c.default_title,
        c.default_head,
        c.loader_url,
        c.wc_loader_url,
        c.root_template,
      )
    None =>
      (
        title_prefix,
        default_title,
        default_head,
        loader_url,
        wc_loader_url,
        default_root_template(),
      )
  }
  register_server_routes_inner(
    app,
    routes,
    "",
    page_resolver,
    api_resolver,
    title_prefix=tp,
    default_title=dt,
    default_head=dh,
    loader_url=lu,
    wc_loader_url=wlu,
    root_template=rt,
  )
}

///|
fn register_server_routes_inner(
  app : App,
  routes : Array[@routes.Routes],
  prefix : String,
  page_resolver : AsyncPageResolver,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
  title_prefix~ : String,
  default_title~ : String,
  default_head~ : String,
  loader_url~ : String,
  wc_loader_url~ : String,
  root_template~ : String,
) -> App {
  let mut result = app
  for route in routes {
    result = match route {
      @routes.Page(path~, component~, title~, meta~) => {
        let _ = meta
        let full_path = prefix + path
        result.get(full_path, async fn(c) {
          let is_fragment = has_fragment_header(c)
          let params = extract_route_params(c, is_fragment~)
          match page_resolver(component, c, params) {
            Some(server_node) => {
              // Resolve ServerNode (await if async)
              let node = server_node.resolve()
              let page_title = format_title(
                title,
                title_prefix~,
                default_title~,
              )
              // Check for fragment request
              if is_fragment {
                let fragment_html = render_fragment_response(
                  node, page_title, false,
                )
                send_fragment_response(c, fragment_html)
              } else {
                let html = render_page_html(
                  node, page_title, default_head, false, root_template,
                )
                c.html(html)
              }
            }
            None => c.text("Page not found: " + component)
          }
        })
      }
      @routes.Layout(segment~, children~, layout~) => {
        let _ = layout // TODO: Layout support
        let new_prefix = prefix + segment
        register_server_routes_inner(
          result,
          children,
          new_prefix,
          page_resolver,
          api_resolver,
          title_prefix~,
          default_title~,
          default_head~,
          loader_url~,
          wc_loader_url~,
          root_template~,
        )
      }
      @routes.Get(path~, handler~) => {
        let full_path = prefix + path
        result.get(full_path, async fn(c) {
          let params = extract_route_params(c)
          match api_resolver(handler, c, params) {
            Some(json) => c.json(json)
            None => c.json(@js.any({ "error": "Handler not found" }))
          }
        })
      }
      @routes.Post(path~, handler~) => {
        let full_path = prefix + path
        result.post(full_path, async fn(c) {
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
