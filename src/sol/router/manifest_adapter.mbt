// Manifest Adapter for Sol
//
// Converts between SolRoutes and RouteManifest
//
// Two-way conversion:
// - SolRoutes → RouteManifest (for client manifest generation)
// - RouteManifest → SolRoutes (for handler injection)

// =============================================================================
// SolRoutes to RouteManifest
// =============================================================================

///|
/// Convert SolRoutes array to RouteManifest
pub fn sol_routes_to_manifest(
  routes : Array[SolRoutes],
  base? : String = "",
) -> @sol_routes.RouteManifest {
  let manifest_routes : Array[@sol_routes.RouteEntry] = []
  collect_routes(routes, base, manifest_routes)
  @sol_routes.RouteManifest::{
    routes: manifest_routes,
    fallback: @sol_routes.FallbackConfig::NotFound(path="/404.html"),
  }
}

///|
/// Recursively collect routes from SolRoutes tree
fn collect_routes(
  routes : Array[SolRoutes],
  base : String,
  result : Array[@sol_routes.RouteEntry],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, handler~, title~, meta~, revalidate~, cache~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let catch_all = extract_catch_all_info(full_path)

        // Determine render mode from revalidate
        let mode = match revalidate {
          Some(seconds) => @sol_routes.RenderMode::Isr(revalidate=seconds)
          None => @sol_routes.RenderMode::Ssr
        }

        // Create dynamic route entry
        let entry = @sol_routes.RouteEntry::Dynamic(@sol_routes.DynamicRouteEntry::{
          path: full_path,
          pattern,
          param_names,
          source: full_path, // For Sol, source is the path
          mode,
          layout: None,
          catch_all,
          title: Some(title),
          islands: [],
        })
        result.push(entry)

        // Suppress unused warnings
        let _ = handler
        let _ = meta
        let _ = cache

      }
      Layout(segment~, layout~, children~) => {
        // Recurse into children with updated base path
        let new_base = manifest_normalize_path(base + segment)
        collect_routes(children, new_base, result)
        let _ = layout

      }
      Get(path~, handler~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let entry = @sol_routes.RouteEntry::Api(@sol_routes.ApiRouteEntry::{
          path: full_path,
          pattern,
          param_names,
          http_method: @sol_routes.HttpMethod::Get,
          source: full_path,
        })
        result.push(entry)
        let _ = handler

      }
      Post(path~, handler~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let entry = @sol_routes.RouteEntry::Api(@sol_routes.ApiRouteEntry::{
          path: full_path,
          pattern,
          param_names,
          http_method: @sol_routes.HttpMethod::Post,
          source: full_path,
        })
        result.push(entry)
        let _ = handler

      }
      WithMiddleware(middleware~, children~) => {
        // Middleware doesn't affect manifest, just recurse
        collect_routes(children, base, result)
        let _ = middleware

      }
    }
  }
}

// =============================================================================
// Helper Functions (delegating to core/routes/pattern_utils)
// =============================================================================

///|
/// Normalize path for manifest (remove double slashes, ensure leading slash)
fn manifest_normalize_path(path : String) -> String {
  @sol_routes.normalize_url_path(path)
}

///|
/// Extract regex pattern and parameter names from path
fn extract_route_pattern(path : String) -> (String, Array[String]) {
  @sol_routes.extract_url_pattern(path)
}

///|
/// Extract catch-all info from path
fn extract_catch_all_info(path : String) -> @sol_routes.CatchAllInfo? {
  @sol_routes.extract_catch_all(path)
}

// =============================================================================
// RouteManifest to SolRoutes (Handler Injection)
// =============================================================================

///|
/// Handler factory type - creates a PageHandler from a route entry
/// Returns None if this factory cannot handle the entry
pub(all) struct PageHandlerFactory((@sol_routes.RouteEntry) -> PageHandler?)

///|
/// Handler factory type - creates an ApiHandler from a route entry
/// Returns None if this factory cannot handle the entry
pub(all) struct ApiHandlerFactory((@sol_routes.RouteEntry) -> ApiHandler?)

///|
/// Convert RouteManifest to SolRoutes with handler injection
///
/// This allows external modules (like Astra) to inject content processing
/// by providing factory functions that create handlers from route metadata.
///
/// Example usage:
/// ```
/// let manifest = scan_pages_dir(fs, "docs", cwd)
/// let routes = manifest_to_sol_routes(manifest, my_page_factory, my_api_factory)
/// register_sol_routes(app, routes, config)
/// ```
pub fn manifest_to_sol_routes(
  manifest : @sol_routes.RouteManifest,
  page_factory : PageHandlerFactory,
  api_factory : ApiHandlerFactory,
) -> Array[SolRoutes] {
  let routes : Array[SolRoutes] = []
  for entry in manifest.routes {
    match convert_entry_to_sol_route(entry, page_factory, api_factory) {
      Some(sol_route) => routes.push(sol_route)
      None => () // Skip entries that factories cannot handle
    }
  }
  routes
}

///|
/// Convert a single RouteEntry to SolRoutes
fn convert_entry_to_sol_route(
  entry : @sol_routes.RouteEntry,
  page_factory : PageHandlerFactory,
  api_factory : ApiHandlerFactory,
) -> SolRoutes? {
  match entry {
    @sol_routes.Static(e) => convert_static_entry(e, page_factory)
    @sol_routes.Dynamic(e) => convert_dynamic_entry(e, page_factory)
    @sol_routes.Api(e) => convert_api_entry(e, api_factory)
    @sol_routes.Component(e) => convert_component_entry(e, page_factory)
  }
}

///|
/// Convert Static route entry to SolRoutes::Page
fn convert_static_entry(
  entry : @sol_routes.StaticRouteEntry,
  page_factory : PageHandlerFactory,
) -> SolRoutes? {
  let route_entry = @sol_routes.RouteEntry::Static(entry)
  match (page_factory.0)(route_entry) {
    Some(handler) =>
      Some(
        SolRoutes::Page(
          path=entry.path,
          handler~,
          title=entry.title.unwrap_or(""),
          meta=[],
          revalidate=None,
          cache=None,
        ),
      )
    None => None
  }
}

///|
/// Convert Dynamic route entry to SolRoutes::Page
fn convert_dynamic_entry(
  entry : @sol_routes.DynamicRouteEntry,
  page_factory : PageHandlerFactory,
) -> SolRoutes? {
  let route_entry = @sol_routes.RouteEntry::Dynamic(entry)
  match (page_factory.0)(route_entry) {
    Some(handler) => {
      // Extract revalidate from render mode
      let revalidate = match entry.mode {
        @sol_routes.RenderMode::Isr(revalidate~) => Some(revalidate)
        _ => None
      }
      Some(
        SolRoutes::Page(
          path=entry.path,
          handler~,
          title=entry.title.unwrap_or(""),
          meta=[],
          revalidate~,
          cache=None,
        ),
      )
    }
    None => None
  }
}

///|
/// Convert API route entry to SolRoutes::Get or SolRoutes::Post
fn convert_api_entry(
  entry : @sol_routes.ApiRouteEntry,
  api_factory : ApiHandlerFactory,
) -> SolRoutes? {
  let route_entry = @sol_routes.RouteEntry::Api(entry)
  match (api_factory.0)(route_entry) {
    Some(handler) =>
      match entry.http_method {
        @sol_routes.HttpMethod::Get =>
          Some(SolRoutes::Get(path=entry.path, handler~))
        @sol_routes.HttpMethod::Post =>
          Some(SolRoutes::Post(path=entry.path, handler~))
        @sol_routes.HttpMethod::Put =>
          Some(SolRoutes::Post(path=entry.path, handler~)) // Use POST for PUT
        @sol_routes.HttpMethod::Delete =>
          Some(SolRoutes::Post(path=entry.path, handler~)) // Use POST for DELETE
        @sol_routes.HttpMethod::Patch =>
          Some(SolRoutes::Post(path=entry.path, handler~)) // Use POST for PATCH
        @sol_routes.HttpMethod::All =>
          Some(SolRoutes::Get(path=entry.path, handler~)) // Use GET for ALL
      }
    None => None
  }
}

///|
/// Convert Component route entry to SolRoutes::Page
fn convert_component_entry(
  entry : @sol_routes.ComponentRouteEntry,
  page_factory : PageHandlerFactory,
) -> SolRoutes? {
  let route_entry = @sol_routes.RouteEntry::Component(entry)
  match (page_factory.0)(route_entry) {
    Some(handler) => {
      // Extract revalidate from render mode
      let revalidate = match entry.mode {
        @sol_routes.RenderMode::Isr(revalidate~) => Some(revalidate)
        _ => None
      }
      Some(
        SolRoutes::Page(
          path=entry.path,
          handler~,
          title="",
          meta=[],
          revalidate~,
          cache=None,
        ),
      )
    }
    None => None
  }
}

// =============================================================================
// Factory Combinators
// =============================================================================

///|
/// Combine multiple page factories into one
/// Tries each factory in order until one returns a handler
pub fn combine_page_factories(
  factories : Array[PageHandlerFactory],
) -> PageHandlerFactory {
  PageHandlerFactory(fn(entry) {
    for factory in factories {
      match (factory.0)(entry) {
        Some(handler) => return Some(handler)
        None => continue
      }
    }
    None
  })
}

///|
/// Combine multiple API factories into one
/// Tries each factory in order until one returns a handler
pub fn combine_api_factories(
  factories : Array[ApiHandlerFactory],
) -> ApiHandlerFactory {
  ApiHandlerFactory(fn(entry) {
    for factory in factories {
      match (factory.0)(entry) {
        Some(handler) => return Some(handler)
        None => continue
      }
    }
    None
  })
}

///|
/// Create a page factory that always returns None (fallback/null factory)
pub fn null_page_factory() -> PageHandlerFactory {
  PageHandlerFactory(fn(_entry) { None })
}

///|
/// Create an API factory that always returns None (fallback/null factory)
pub fn null_api_factory() -> ApiHandlerFactory {
  ApiHandlerFactory(fn(_entry) { None })
}
