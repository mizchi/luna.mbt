///| Additional Page Handlers

///| These pages complete the routes defined in routes.mbt

///|
fn docs_links_section() -> @luna.Node[Unit, String] {
  div([
    h2([text("Available Docs")]),
    ul([
      li([sol_link(href="/docs/intro", [text("Introduction")])]),
      li([sol_link(href="/docs/getting-started", [text("Getting Started")])]),
      li([sol_link(href="/docs/api/overview", [text("API Overview")])]),
    ]),
  ])
}

///|
fn blog_recent_posts_section() -> @luna.Node[Unit, String] {
  div([
    h2([text("Recent Posts")]),
    ul([
      li([sol_link(href="/blog/hello-world", [text("Hello World")])]),
      li([sol_link(href="/blog/moonbit-guide", [text("MoonBit Guide")])]),
      li([sol_link(href="/blog/2024/recap", [text("2024 Recap")])]),
    ]),
  ])
}

///|
/// WC Multiple page - demonstrates multiple instances of the same Web Component
async fn wc_multiple(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("Multiple WC Counters")]),
    p([text("Multiple instances of the same Web Component on one page.")]),
    // Multiple instances with different initial values
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js",
      [
        div(class="counter", [
          span(class="count-display", [text("0")]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=@client.wc_counter_css,
      state="{\"initial_count\":0}",
      trigger=@luna.TriggerType::Load,
    ),
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js",
      [
        div(class="counter", [
          span(class="count-display", [text("10")]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=@client.wc_counter_css,
      state="{\"initial_count\":10}",
      trigger=@luna.TriggerType::Load,
    ),
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js",
      [
        div(class="counter", [
          span(class="count-display", [text("100")]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=@client.wc_counter_css,
      state="{\"initial_count\":100}",
      trigger=@luna.TriggerType::Load,
    ),
  ]
  @sol.nodes(content)
}

///|
/// Docs page - catch-all route handler for /docs/[...slug]
async fn docs_page(props : @sol.PageProps) -> @server_dom.ServerNode {
  let slug = match @types.params_docs_slug(props) {
    Ok(p) => p.slug
    Err(_) => "index"
  }
  let content = [
    h1([text("Documentation")]),
    p([text("Current path: /docs/" + slug)]),
    docs_links_section(),
  ]
  @sol.nodes(content)
}

///|
/// Blog page - optional catch-all route handler for /blog/[[...path]]
async fn blog_page(props : @sol.PageProps) -> @server_dom.ServerNode {
  let path = match @types.params_blog_path(props) {
    Ok(p) => p.path.unwrap_or("")
    Err(_) => ""
  }
  let title = if path == "" { "Blog Home" } else { "Blog: " + path }
  let content = [
    h1([text(title)]),
    p([
      text(if path == "" { "Welcome to the blog!" } else { "Viewing: " + path }),
    ]),
    blog_recent_posts_section(),
  ]
  @sol.nodes(content)
}

///|
/// Admin layout - wraps admin pages with sidebar navigation
pub fn admin_layout(
  _props : @sol.PageProps,
  content : @server_dom.ServerNode,
) -> @server_dom.ServerNode raise Error {
  @server_dom.ServerNode::async_(async fn() {
    let inner = content.resolve()
    div(class="admin-container", [
      div(class="admin-sidebar", [
        h3([text("Admin")]),
        ul([
          li([sol_link(href="/admin", [text("Dashboard")])]),
          li([sol_link(href="/admin/settings", [text("Settings")])]),
          li([sol_link(href="/admin/users", [text("Users")])]),
        ]),
      ]),
      div(class="admin-content", [inner]),
    ])
  })
}

///|
/// Admin home page - dashboard
async fn admin_home(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("Admin Dashboard")]),
    p([text("Welcome to the admin panel.")]),
    div(class="admin-stats", [
      div(class="stat-card", [
        h4([text("Users")]),
        div(class="stat-value", [text("42")]),
      ]),
      div(class="stat-card", [
        h4([text("Posts")]),
        div(class="stat-value", [text("128")]),
      ]),
      div(class="stat-card", [
        h4([text("Views")]),
        div(class="stat-value", [text("1.2k")]),
      ]),
    ]),
  ]
  @sol.nodes(content)
}

///|
/// Admin settings page
async fn admin_settings(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("Admin Settings")]),
    div(class="settings-section", [
      div(class="setting-item", [
        label(for_="site-name", [text("Site Name")]),
        input(type_="text", id="site-name", value="Sol App"),
      ]),
      div(class="setting-item", [
        label(for_="contact-email", [text("Contact Email")]),
        input(type_="email", id="contact-email", value="admin@example.com"),
      ]),
    ]),
  ]
  @sol.nodes(content)
}

///|
/// Admin users page
async fn admin_users(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("User Management")]),
    div(class="users-list", [
      div(class="user-row user-header", [
        span(class="user-cell", [text("Name")]),
        span(class="user-cell", [text("Email")]),
        span(class="user-cell", [text("Role")]),
      ]),
      div(class="user-row", [
        span(class="user-cell", [text("Alice")]),
        span(class="user-cell", [text("alice@example.com")]),
        span(class="user-cell", [text("Admin")]),
      ]),
      div(class="user-row", [
        span(class="user-cell", [text("Bob")]),
        span(class="user-cell", [text("bob@example.com")]),
        span(class="user-cell", [text("User")]),
      ]),
      div(class="user-row", [
        span(class="user-cell", [text("Charlie")]),
        span(class="user-cell", [text("charlie@example.com")]),
        span(class="user-cell", [text("User")]),
      ]),
    ]),
  ]
  @sol.nodes(content)
}
