///|
extern "js" fn set_location_path(path : String) -> Unit =
  #| (path) => window.history.replaceState(null, '', path)

///|
extern "js" fn dispatch_popstate() -> Unit =
  #| () => window.dispatchEvent(new PopStateEvent('popstate'))

///|
extern "js" fn cleanup_dom() -> Unit =
  #| () => {
  #|   if (typeof document !== 'undefined' && document.body) {
  #|     document.body.innerHTML = '';
  #|   }
  #| }

///|
test "BrowserRouter syncs path on popstate" {
  @global_jsdom.register()
  defer cleanup_dom()
  set_location_path("/")
  let routes = [
    @routes.Routes::Page(path="/", component="home", title="Home", meta=[]),
    @routes.Routes::Page(path="/about", component="about", title="About", meta=[]),
  ]
  let router = BrowserRouter::new(routes)
  assert_eq(router.get_path(), "/")
  set_location_path("/about")
  dispatch_popstate()
  assert_eq(router.get_path(), "/about")
  router.dispose()
}

///|
test "BrowserRouter dispose removes popstate listener" {
  @global_jsdom.register()
  defer cleanup_dom()
  set_location_path("/")
  let routes = [
    @routes.Routes::Page(path="/", component="home", title="Home", meta=[]),
    @routes.Routes::Page(path="/about", component="about", title="About", meta=[]),
  ]
  let router = BrowserRouter::new(routes)
  set_location_path("/about")
  dispatch_popstate()
  assert_eq(router.get_path(), "/about")
  router.dispose()
  set_location_path("/")
  dispatch_popstate()
  assert_eq(router.get_path(), "/about")
}

///|
test "BrowserRouter navigate applies base path" {
  @global_jsdom.register()
  defer cleanup_dom()
  set_location_path("/app")
  let routes = [
    @routes.Routes::Page(path="/", component="home", title="Home", meta=[]),
    @routes.Routes::Page(path="/users", component="users", title="Users", meta=[]),
  ]
  let router = BrowserRouter::new(routes, base="/app")
  assert_eq(router.get_path(), "/app")
  assert_eq(router.get_component(), Some("home"))
  router.navigate("/users")
  assert_eq(router.get_path(), "/app/users")
  assert_eq(router.get_component(), Some("users"))
  router.replace("/users?tab=active")
  assert_eq(router.get_path(), "/app/users?tab=active")
  assert_eq(router.get_component(), Some("users"))
  match router.get_match() {
    Some(matched) => assert_eq(matched.get_query("tab"), Some("active"))
    None => fail("expected matched route")
  }
  router.dispose()
}
