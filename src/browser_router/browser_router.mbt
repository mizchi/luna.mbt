// BrowserRouter - Client-side SPA router with History API
//
// Provides reactive routing for single-page applications using
//

///|
/// the browser's History API and Signals for state management.

// =============================================================================
// Browser API FFI (History API)
// =============================================================================

extern "js" fn get_pathname() -> String =
  #| () => window.location.pathname

///|
extern "js" fn get_search() -> String =
  #| () => window.location.search

///|
extern "js" fn push_state(path : String) -> Unit =
  #| (path) => window.history.pushState(null, '', path)

///|
extern "js" fn replace_state(path : String) -> Unit =
  #| (path) => window.history.replaceState(null, '', path)

///|
extern "js" fn add_popstate_listener(callback : () -> Unit) -> Unit =
  #| (callback) => window.addEventListener('popstate', () => callback())

///|
/// Get current URL (pathname + search)
fn get_current_url() -> String {
  let pathname = get_pathname()
  let search = get_search()
  if not(search.is_empty()) {
    pathname + search
  } else {
    pathname
  }
}

// =============================================================================
// BrowserRouter
// =============================================================================

///|
/// Browser router
/// SPA navigation using History API and Signals
pub struct BrowserRouter {
  routes : Array[@routes.CompiledRoutes]
  base : String
  current_path : @signal.Signal[String]
  current_match : @signal.Signal[@routes.RoutesMatch?]
}

///|
/// Create BrowserRouter from route definitions
/// base~: base path (e.g., "/demo/browser_router")
pub fn BrowserRouter::new(
  routes : Array[@routes.Routes],
  base? : String = "",
) -> BrowserRouter {
  let compiled = @routes.compile(routes, base~)
  let initial_path = get_current_url()
  let initial_match = @routes.match_url(initial_path, compiled)
  let router : BrowserRouter = {
    routes: compiled,
    base,
    current_path: @signal.signal(initial_path),
    current_match: @signal.signal(initial_match),
  }
  add_popstate_listener(fn() { router.sync_from_url() })
  router
}

///|
/// Create BrowserRouter from compiled routes
pub fn BrowserRouter::from_compiled(
  routes : Array[@routes.CompiledRoutes],
  base? : String = "",
) -> BrowserRouter {
  let initial_path = get_current_url()
  let initial_match = @routes.match_url(initial_path, routes)
  let router : BrowserRouter = {
    routes,
    base,
    current_path: @signal.signal(initial_path),
    current_match: @signal.signal(initial_match),
  }
  add_popstate_listener(fn() { router.sync_from_url() })
  router
}

///|
/// Get base path
pub fn BrowserRouter::get_base(self : BrowserRouter) -> String {
  self.base
}

///|
/// Sync Signal state from URL
fn BrowserRouter::sync_from_url(self : BrowserRouter) -> Unit {
  let path = get_current_url()
  self.current_path.set(path)
  self.current_match.set(@routes.match_url(path, self.routes))
}

///|
/// Update Signal state with specified path
fn BrowserRouter::update_state(self : BrowserRouter, path : String) -> Unit {
  self.current_path.set(path)
  self.current_match.set(@routes.match_url(path, self.routes))
}

///|
/// Programmatic navigation (adds to history)
pub fn BrowserRouter::navigate(self : BrowserRouter, path : String) -> Unit {
  push_state(path)
  self.update_state(path)
}

///|
/// Replace navigation (not added to back button history)
pub fn BrowserRouter::replace(self : BrowserRouter, path : String) -> Unit {
  replace_state(path)
  self.update_state(path)
}

///|
/// Get current path
pub fn BrowserRouter::get_path(self : BrowserRouter) -> String {
  self.current_path.get()
}

///|
/// Get current match result
pub fn BrowserRouter::get_match(self : BrowserRouter) -> @routes.RoutesMatch? {
  self.current_match.get()
}

///|
/// Get current component ID
pub fn BrowserRouter::get_component(self : BrowserRouter) -> String? {
  self.current_match.get().map(m => m.component())
}

///|
/// Get navigate function (for passing to components)
pub fn BrowserRouter::get_navigate(self : BrowserRouter) -> (String) -> Unit {
  path => self.navigate(path)
}

///|
/// Get path Signal (for reactive UI)
pub fn BrowserRouter::path_signal(
  self : BrowserRouter,
) -> @signal.Signal[String] {
  self.current_path
}

///|
/// Get match result Signal (for reactive UI)
pub fn BrowserRouter::match_signal(
  self : BrowserRouter,
) -> @signal.Signal[@routes.RoutesMatch?] {
  self.current_match
}
