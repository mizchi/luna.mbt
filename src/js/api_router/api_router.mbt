// JS Router API - focused wrappers for tree-shake friendly router entrypoint

///|
/// Create a page route (simple version for JS)
pub fn route_page(path : String, component : String) -> @routes.Routes {
  @routes.Routes::Page(path~, component~, title="", meta=[])
}

///|
/// Create a page route with title
pub fn route_page_titled(
  path : String,
  component : String,
  title : String,
) -> @routes.Routes {
  @routes.Routes::Page(path~, component~, title~, meta=[])
}

///|
/// Create a page route with full options
pub fn route_page_full(
  path : String,
  component : String,
  title : String,
  meta : Array[(String, String)],
) -> @routes.Routes {
  @routes.Routes::Page(path~, component~, title~, meta~)
}

///|
/// BrowserRouter for SPA navigation
pub struct BrowserRouter(@browser_router.BrowserRouter)

///|
/// Create a BrowserRouter from routes definition
pub fn create_router(
  routes : Array[@routes.Routes],
  base? : String = "",
) -> BrowserRouter {
  @browser_router.BrowserRouter::new(routes, base~)
}

///|
/// Navigate to a path (adds to history)
pub fn router_navigate(router : BrowserRouter, path : String) -> Unit {
  router.0.navigate(path)
}

///|
/// Replace current path (does not add to history)
pub fn router_replace(router : BrowserRouter, path : String) -> Unit {
  router.0.replace(path)
}

///|
/// Get current path
pub fn router_get_path(router : BrowserRouter) -> String {
  router.0.get_path()
}

///|
/// Get current match result
pub fn router_get_match(router : BrowserRouter) -> @routes.RoutesMatch? {
  router.0.get_match()
}

///|
/// Get base path
pub fn router_get_base(router : BrowserRouter) -> String {
  router.0.get_base()
}
