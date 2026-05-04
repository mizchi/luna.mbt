///|
/// BrowserRouter - Client-side SPA router with History API
///
/// Provides reactive routing for single-page applications using
/// the browser's History API and Signals for state management.
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
extern "js" fn add_popstate_listener(callback : () -> Unit) -> () -> Unit =
  #| (callback) => {
  #|   const handler = () => callback();
  #|   window.addEventListener('popstate', handler);
  #|   return () => window.removeEventListener('popstate', handler);
  #| }

///|
fn get_current_url() -> String {
  let pathname = get_pathname()
  let search = get_search()
  if search.is_empty() {
    pathname
  } else {
    pathname + search
  }
}

///|
/// Browser router for SPA navigation using History API and Signals
pub struct BrowserRouter {
  routes : Array[@routes.CompiledRoutes]
  base : String
  current_path : @resource.Signal[String]
  current_match : @resource.Signal[@routes.RoutesMatch?]
  dispose_popstate : () -> Unit
}

///|
/// Create BrowserRouter from route definitions
pub fn BrowserRouter::new(
  routes : Array[@routes.Routes],
  base? : String = "",
) -> BrowserRouter {
  BrowserRouter::from_compiled(@routes.compile(routes, base~), base~)
}

///|
/// Create BrowserRouter from compiled routes
pub fn BrowserRouter::from_compiled(
  routes : Array[@routes.CompiledRoutes],
  base? : String = "",
) -> BrowserRouter {
  let current_path : @resource.Signal[String] = @resource.signal("")
  let current_match : @resource.Signal[@routes.RoutesMatch?] = @resource.signal(
    None,
  )
  let sync = fn() {
    let path = get_current_url()
    current_path.set(path)
    current_match.set(@routes.match_url(path, routes))
  }
  let dispose = add_popstate_listener(sync)
  sync()
  { routes, base, current_path, current_match, dispose_popstate: dispose }
}

///|
/// Get base path
pub fn BrowserRouter::get_base(self : BrowserRouter) -> String {
  self.base
}

///|
/// Update Signal state with specified path
fn BrowserRouter::update_state(self : BrowserRouter, path : String) -> Unit {
  self.current_path.set(path)
  self.current_match.set(@routes.match_url(path, self.routes))
}

///|
fn BrowserRouter::resolve_path(self : BrowserRouter, path : String) -> String {
  if self.base == "" || self.base == "/" {
    path
  } else if path.has_prefix(self.base) {
    path
  } else if path.has_prefix("/") {
    self.base + path
  } else {
    self.base + "/" + path
  }
}

///|
/// Programmatic navigation (adds to history)
pub fn BrowserRouter::navigate(self : BrowserRouter, path : String) -> Unit {
  let resolved = self.resolve_path(path)
  push_state(resolved)
  self.update_state(resolved)
}

///|
/// Replace navigation (not added to back button history)
pub fn BrowserRouter::replace(self : BrowserRouter, path : String) -> Unit {
  let resolved = self.resolve_path(path)
  replace_state(resolved)
  self.update_state(resolved)
}

///|
/// Dispose router side effects (popstate listener)
pub fn BrowserRouter::dispose(self : BrowserRouter) -> Unit {
  (self.dispose_popstate)()
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
  self.current_match.get().map(fn(m) { m.component() })
}

///|
/// Get navigate function (for passing to components)
pub fn BrowserRouter::get_navigate(self : BrowserRouter) -> (String) -> Unit {
  fn(path) { self.navigate(path) }
}

///|
/// Get path Signal (for reactive UI)
pub fn BrowserRouter::path_signal(
  self : BrowserRouter,
) -> @resource.Signal[String] {
  self.current_path
}

///|
/// Get match result Signal (for reactive UI)
pub fn BrowserRouter::match_signal(
  self : BrowserRouter,
) -> @resource.Signal[@routes.RoutesMatch?] {
  self.current_match
}
