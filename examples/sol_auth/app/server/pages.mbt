///| Additional Page Handlers
///| These pages complete the routes defined in routes.mbt

///|
/// WC Multiple page - demonstrates multiple instances of the same Web Component
async fn wc_multiple(_props : @router.PageProps) -> @server_dom.ServerNode {
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
            button(class="dec", attrs=[("data-on-click", @luna.attr_static("decrement"))], [text("-")]),
            button(class="inc", attrs=[("data-on-click", @luna.attr_static("increment"))], [text("+")]),
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
            button(class="dec", attrs=[("data-on-click", @luna.attr_static("decrement"))], [text("-")]),
            button(class="inc", attrs=[("data-on-click", @luna.attr_static("increment"))], [text("+")]),
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
            button(class="dec", attrs=[("data-on-click", @luna.attr_static("decrement"))], [text("-")]),
            button(class="inc", attrs=[("data-on-click", @luna.attr_static("increment"))], [text("+")]),
          ]),
        ]),
      ],
      styles=@client.wc_counter_css,
      state="{\"initial_count\":100}",
      trigger=@luna.TriggerType::Load,
    ),
  ]
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// Docs page - catch-all route handler for /docs/[...slug]
async fn docs_page(props : @router.PageProps) -> @server_dom.ServerNode {
  let slug = props.params.get_param("slug").unwrap_or("index")
  let content = [
    h1([text("Documentation")]),
    p([text("Current path: /docs/" + slug)]),
    div([
      h2([text("Available Docs")]),
      ul([
        li([sol_link(href="/docs/intro", [text("Introduction")])]),
        li([sol_link(href="/docs/getting-started", [text("Getting Started")])]),
        li([sol_link(href="/docs/api/overview", [text("API Overview")])]),
      ]),
    ]),
  ]
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// Blog page - optional catch-all route handler for /blog/[[...path]]
async fn blog_page(props : @router.PageProps) -> @server_dom.ServerNode {
  let path = props.params.get_param("path").unwrap_or("")
  let title = if path == "" { "Blog Home" } else { "Blog: " + path }
  let content = [
    h1([text(title)]),
    p([text(if path == "" { "Welcome to the blog!" } else { "Viewing: " + path })]),
    div([
      h2([text("Recent Posts")]),
      ul([
        li([sol_link(href="/blog/hello-world", [text("Hello World")])]),
        li([sol_link(href="/blog/moonbit-guide", [text("MoonBit Guide")])]),
        li([sol_link(href="/blog/2024/recap", [text("2024 Recap")])]),
      ]),
    ]),
  ]
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// Admin layout - wraps admin pages with sidebar navigation
pub fn admin_layout(
  _props : @router.PageProps,
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
async fn admin_home(_props : @router.PageProps) -> @server_dom.ServerNode {
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
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// Admin settings page
async fn admin_settings(_props : @router.PageProps) -> @server_dom.ServerNode {
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
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// Admin users page
async fn admin_users(_props : @router.PageProps) -> @server_dom.ServerNode {
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
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

// ============================================================================
// User Namespace Pages (/@user_id/page_id)
// ISR-enabled user content pages
// ============================================================================

///|
/// User profile page - /@[user_id]
/// Shows user's profile and list of their pages
async fn user_profile(props : @router.PageProps) -> @server_dom.ServerNode {
  let user_id = props.get_param("user_id").unwrap_or("unknown")
  let content = [
    div(class="user-profile", [
      div(class="user-header", [
        div(class="user-avatar", [text(user_id[0:1].to_string())]),
        div(class="user-info", [
          h1([text("@" + user_id)]),
          p(class="user-bio", [text("User profile for " + user_id)]),
        ]),
      ]),
      div(class="user-pages", [
        h2([text("Pages")]),
        ul([
          li([sol_link(href="/@" + user_id + "/hello", [text("Hello World")])]),
          li([sol_link(href="/@" + user_id + "/about", [text("About Me")])]),
          li([sol_link(href="/@" + user_id + "/projects", [text("Projects")])]),
        ]),
      ]),
    ]),
  ]
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// User page - /@[user_id]/[page_id]
/// Individual page within user's namespace
async fn user_page(props : @router.PageProps) -> @server_dom.ServerNode {
  let user_id = props.get_param("user_id").unwrap_or("unknown")
  let page_id = props.get_param("page_id").unwrap_or("index")
  let content = [
    article(class="user-page", [
      header_(class="page-header", [
        nav(class="breadcrumb", [
          sol_link(href="/@" + user_id, [text("@" + user_id)]),
          span([text(" / ")]),
          span([text(page_id)]),
        ]),
      ]),
      h1([text(page_id_to_title(page_id))]),
      div(class="page-content", [
        p([text("This is the \"" + page_id + "\" page by @" + user_id + ".")]),
        p([text("Content would be loaded from database via ISR.")]),
      ]),
      footer_(class="page-footer", [
        p(class="page-meta", [
          text("Author: "),
          sol_link(href="/@" + user_id, [text("@" + user_id)]),
        ]),
      ]),
    ]),
  ]
  @server_dom.ServerNode::sync(@luna.fragment(content))
}

///|
/// Convert page_id slug to title
fn page_id_to_title(page_id : String) -> String {
  // Simple slug to title conversion: "hello-world" -> "Hello World"
  page_id.replace(old="-", new=" ")
}
