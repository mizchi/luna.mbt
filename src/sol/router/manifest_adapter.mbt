// Manifest Adapter for Sol
//
// Converts between SolRoutes and RouteManifest

// =============================================================================
// SolRoutes to RouteManifest
// =============================================================================

///|
/// Convert SolRoutes array to RouteManifest
pub fn sol_routes_to_manifest(
  routes : Array[SolRoutes],
  base? : String = "",
) -> @core_routes.RouteManifest {
  let manifest_routes : Array[@core_routes.RouteEntry] = []
  collect_routes(routes, base, manifest_routes)
  @core_routes.RouteManifest::{
    routes: manifest_routes,
    fallback: @core_routes.FallbackConfig::NotFound(path="/404.html"),
  }
}

///|
/// Recursively collect routes from SolRoutes tree
fn collect_routes(
  routes : Array[SolRoutes],
  base : String,
  result : Array[@core_routes.RouteEntry],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, handler~, title~, meta~, revalidate~, cache~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let catch_all = extract_catch_all_info(full_path)

        // Determine render mode from revalidate
        let mode = match revalidate {
          Some(seconds) => @core_routes.RenderMode::Isr(revalidate=seconds)
          None => @core_routes.RenderMode::Ssr
        }

        // Create dynamic route entry
        let entry = @core_routes.RouteEntry::Dynamic(@core_routes.DynamicRouteEntry::{
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
        let entry = @core_routes.RouteEntry::Api(@core_routes.ApiRouteEntry::{
          path: full_path,
          pattern,
          param_names,
          http_method: @core_routes.HttpMethod::Get,
          source: full_path,
        })
        result.push(entry)
        let _ = handler

      }
      Post(path~, handler~) => {
        let full_path = manifest_normalize_path(base + path)
        let (pattern, param_names) = extract_route_pattern(full_path)
        let entry = @core_routes.RouteEntry::Api(@core_routes.ApiRouteEntry::{
          path: full_path,
          pattern,
          param_names,
          http_method: @core_routes.HttpMethod::Post,
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
  @core_routes.normalize_url_path(path)
}

///|
/// Extract regex pattern and parameter names from path
fn extract_route_pattern(path : String) -> (String, Array[String]) {
  @core_routes.extract_url_pattern(path)
}

///|
/// Extract catch-all info from path
fn extract_catch_all_info(path : String) -> @core_routes.CatchAllInfo? {
  @core_routes.extract_catch_all(path)
}
