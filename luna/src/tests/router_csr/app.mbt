//

///|
/// CSR Router Demo - Client-Side Routing with History API

// =============================================================================
// FFI
// =============================================================================

extern "js" fn js_querySelector(selector : String) -> @js_dom.Element =
  #| (s) => document.querySelector(s)

///|
extern "js" fn js_setAttribute(
  el : @js_dom.Element,
  name : String,
  value : String,
) -> Unit =
  #| (el, n, v) => el.setAttribute(n, v)

///|
extern "js" fn prevent_default_event(e : @js.Any) -> Unit =
  #| (e) => e.preventDefault()

// =============================================================================
// Routes Definition
// =============================================================================

///|
fn get_routes() -> Array[@routes.Routes] {
  [
    @routes.Routes::Layout(segment="/csr-router", layout="main", children=[
      @routes.Routes::Page(path="/home", component="home", title="Home", meta=[]),
      @routes.Routes::Page(path="/about", component="about", title="About", meta=[]),
      @routes.Routes::Page(
        path="/contact",
        component="contact",
        title="Contact",
        meta=[],
      ),
      @routes.Routes::Page(
        path="/posts/:id",
        component="post",
        title="Post Detail",
        meta=[],
      ),
    ]),
  ]
}

// =============================================================================
// Page Components
// =============================================================================

///|
fn home_page() -> @dom.DomNode {
  @dom.div(attrs=[("data-page", @dom.Attr::AttrString("home"))], [
    @dom.h1([@dom.text("Home Page")]),
    @dom.p([@dom.text("Welcome to the CSR Router Demo!")]),
  ])
}

///|
fn about_page() -> @dom.DomNode {
  @dom.div(attrs=[("data-page", @dom.Attr::AttrString("about"))], [
    @dom.h1([@dom.text("About Page")]),
    @dom.p([@dom.text("This is the about page.")]),
  ])
}

///|
fn contact_page() -> @dom.DomNode {
  @dom.div(attrs=[("data-page", @dom.Attr::AttrString("contact"))], [
    @dom.h1([@dom.text("Contact Page")]),
    @dom.p([@dom.text("Get in touch with us!")]),
  ])
}

///|
fn post_page(post_id : String) -> @dom.DomNode {
  @dom.div(
    attrs=[
      ("data-page", @dom.Attr::AttrString("post")),
      ("data-post-id", @dom.Attr::AttrString(post_id)),
    ],
    [
      @dom.h1([@dom.text("Post: " + post_id)]),
      @dom.p([@dom.text("Viewing post #" + post_id)]),
    ],
  )
}

///|
fn not_found_page() -> @dom.DomNode {
  @dom.div(attrs=[("data-page", @dom.Attr::AttrString("404"))], [
    @dom.h1([@dom.text("404 Not Found")]),
    @dom.p([@dom.text("The page you are looking for does not exist.")]),
  ])
}

// =============================================================================
// Router App
// =============================================================================

///|
/// Render page based on current match
fn render_page_for_match(
  router : @browser_router.BrowserRouter,
) -> @dom.DomNode {
  match router.get_match() {
    Some(m) => {
      let component = m.component()
      if component == "home" {
        home_page()
      } else if component == "about" {
        about_page()
      } else if component == "contact" {
        contact_page()
      } else if component == "post" {
        // /csr-router/posts/:id case
        match m.get_param("id") {
          Some(id) => post_page(id)
          None => not_found_page()
        }
      } else {
        not_found_page()
      }
    }
    None => not_found_page()
  }
}

///|
fn nav_link(
  router : @browser_router.BrowserRouter,
  href : String,
  label : String,
) -> @dom.DomNode {
  @dom.create_element(
    "a",
    [
      ("href", @dom.AttrValue::Static(href)),
      (
        "onclick",
        @dom.AttrValue::Handler(fn(e) {
          prevent_default_event(e)
          router.navigate(href)
        }),
      ),
      ("data-nav", @dom.AttrValue::Static(href)),
      ("style", @dom.AttrValue::Static("margin-right: 10px;")),
    ],
    [@dom.text(label)],
  )
}

///|
/// Replace link - uses replace instead of navigate (does not add to history)
fn replace_link(
  router : @browser_router.BrowserRouter,
  href : String,
  label : String,
) -> @dom.DomNode {
  @dom.create_element(
    "a",
    [
      ("href", @dom.AttrValue::Static(href)),
      (
        "onclick",
        @dom.AttrValue::Handler(fn(e) {
          prevent_default_event(e)
          router.replace(href)
        }),
      ),
      ("data-replace", @dom.AttrValue::Static(href)),
      ("style", @dom.AttrValue::Static("margin-right: 10px; color: green;")),
    ],
    [@dom.text(label)],
  )
}

///|
fn router_app(router : @browser_router.BrowserRouter) -> @dom.DomNode {
  @dom.div(attrs=[("data-router-app", @dom.Attr::AttrString("true"))], [
    // Navigation
    @dom.create_element(
      "nav",
      [("data-nav-container", @dom.AttrValue::Static("true"))],
      [
        nav_link(router, "/csr-router/home", "Home"),
        nav_link(router, "/csr-router/about", "About"),
        nav_link(router, "/csr-router/contact", "Contact"),
        nav_link(router, "/csr-router/posts/123", "Post 123"),
        nav_link(router, "/csr-router/posts/456", "Post 456"),
      ],
    ),
    // Replace navigation (does not add to history)
    @dom.create_element(
      "nav",
      [("data-replace-nav-container", @dom.AttrValue::Static("true"))],
      [
        @dom.text("Replace: "),
        replace_link(router, "/csr-router/home", "Home (replace)"),
        replace_link(router, "/csr-router/about", "About (replace)"),
      ],
    ),
    // Current path display (reactive)
    @dom.div(
      attrs=[("data-current-path-container", @dom.Attr::AttrString("true"))],
      [@dom.text("Current path: "), @dom.text_dyn(fn() { router.get_path() })],
    ),
    // Base path display
    @dom.div(
      attrs=[("data-base-path-container", @dom.Attr::AttrString("true"))],
      [@dom.text("Base path: "), @dom.text(router.get_base())],
    ),
    // Page content - render based on current match
    @dom.div(attrs=[("data-content", @dom.Attr::AttrString("true"))], [
      render_page_for_match(router),
    ]),
  ])
}

// =============================================================================
// Entry Point
// =============================================================================

///|
/// Mount the router app to #app element
pub fn mount_router_app() -> Unit {
  let routes = get_routes()
  let router = @browser_router.BrowserRouter::new(routes)
  let app = router_app(router)
  let container = js_querySelector("#app")
  @dom.mount_to(container, app)

  // Mark as mounted
  js_setAttribute(container, "data-mounted", "true")
}
