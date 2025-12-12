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

// =============================================================================
// Routes Definition
// =============================================================================

///|
fn get_routes() -> Array[@router.Route] {
  [
    @router.Path(
      "/csr-router",
      [
        @router.Page(path="/home", title="Home", meta=[]),
        @router.Page(path="/about", title="About", meta=[]),
        @router.Page(path="/contact", title="Contact", meta=[]),
        @router.Path(
          "/posts",
          [
            @router.Param("id", key="id", title="", meta=[]),
            @router.Page(path="", title="Post Detail", meta=[]),
          ],
          title="",
          meta=[],
        ),
      ],
      title="",
      meta=[],
    ),
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
/// 現在のマッチに基づいてページをレンダリング
fn render_page_for_match(router : @client.ClientRouter) -> @dom.DomNode {
  match router.get_match() {
    Some(m) => {
      let path = m.props.path
      if path == "/csr-router/home" {
        home_page()
      } else if path == "/csr-router/about" {
        about_page()
      } else if path == "/csr-router/contact" {
        contact_page()
      } else {
        // /csr-router/posts/:id の場合
        match m.props.get_param("id") {
          Some(id) => post_page(id)
          None => not_found_page()
        }
      }
    }
    None => not_found_page()
  }
}

///|
fn nav_link(
  router : @client.ClientRouter,
  href : String,
  label : String,
) -> @dom.DomNode {
  let attrs = @client.link_attrs(href, router)
  @dom.create_element(
    "a",
    [
      ..attrs,
      ("data-nav", @dom.AttrValue::Static(href)),
      ("style", @dom.AttrValue::Static("margin-right: 10px;")),
    ],
    [@dom.text(label)],
  )
}

///|
fn router_app(router : @client.ClientRouter) -> @dom.DomNode {
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
    // Current path display (reactive)
    @dom.div(
      attrs=[("data-current-path-container", @dom.Attr::AttrString("true"))],
      [@dom.text("Current path: "), @dom.text_dyn(fn() { router.get_path() })],
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
  let router = @client.ClientRouter::new(routes)
  let app = router_app(router)
  let container = js_querySelector("#app")
  @dom.mount_to(container, app)

  // Mark as mounted
  js_setAttribute(container, "data-mounted", "true")
}
