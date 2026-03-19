///| Routes for SQLite ISR Demo
///|
///| Demonstrates ISR (Incremental Static Regeneration) with SQLite database.
///| Uses node:sqlite (Node.js 22+) for database access.

// =============================================================================
// Route Definitions
// =============================================================================

///|
pub fn routes() -> Array[@sol.SolRoutes] {
  [
    @sol.with_mw(
      [@mw.logger()],
      [
        // Layout wrapping all pages
        @sol.wrap("", root_layout, [
          // Home page - navigation hub
          @sol.route("/", home_page, title="SQLite ISR Demo"),
          // Blog index with ISR - 60s TTL (warm tier)
          @sol.route("/blog", blog_index, title="Blog", revalidate=Some(60)),
          // Individual blog posts with ISR - 120s TTL
          @sol.route("/blog/:slug", blog_post, title="Blog Post", revalidate=Some(120)),
          // Stats page with ISR - 10s TTL (near real-time)
          @sol.route("/stats", stats_page, title="Statistics", revalidate=Some(10)),
        ]),
      ],
    ),
  ]
}

// =============================================================================
// Layout
// =============================================================================

///|
fn root_layout(
  _props : @sol.PageProps,
  content : @server_dom.ServerNode,
) -> @server_dom.ServerNode raise Error {
  @server_dom.ServerNode::async_(async fn() {
    let inner = content.resolve()
    @luna.fragment([
      nav([
        div([
          strong([text("SQLite ISR Demo")]),
          text(" | "),
          a(href="/", [text("Home")]),
          text(" | "),
          a(href="/blog", [text("Blog (ISR 60s)")]),
          text(" | "),
          a(href="/stats", [text("Stats (ISR 10s)")]),
        ]),
      ]),
      div([inner]),
    ])
  })
}

// =============================================================================
// Page Handlers
// =============================================================================

///| Home page - explains the demo
async fn home_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content : Array[@luna.Node[Unit, String]] = [
    h1([text("SQLite ISR Demo")]),
    p([text("This demo shows ISR (Incremental Static Regeneration) with SQLite database.")]),
    div([
      h2([text("How It Works")]),
      ul([
        li([text("Pages are pre-rendered and cached on first request")]),
        li([text("Cached pages are served instantly while within TTL")]),
        li([text("After TTL expires, stale page is served while regenerating in background")]),
        li([text("Next request gets the fresh page with updated database data")]),
      ]),
    ]),
    div([
      h2([text("Demo Pages")]),
      ul([
        li([
          a(href="/blog", [text("/blog")]),
          text(" - Blog index (ISR TTL: 60s)"),
        ]),
        li([
          a(href="/blog/hello-world", [text("/blog/hello-world")]),
          text(" - Individual post (ISR TTL: 120s)"),
        ]),
        li([
          a(href="/stats", [text("/stats")]),
          text(" - Statistics (ISR TTL: 10s - near real-time)"),
        ]),
      ]),
    ]),
    div([
      h2([text("Setup")]),
      pre([
        code([text("# Initialize database\nnpm run init-db\n\n# Start dev server\nnpm run dev")]),
      ]),
    ]),
  ]
  @sol.nodes(content)
}

///| Blog index page - lists all posts from SQLite
async fn blog_index(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let posts = db_get_all_posts()
  let generated_at = get_timestamp()
  let len = array_len(posts)

  let post_items : Array[@luna.Node[Unit, String]] = []
  for i = 0; i < len; i = i + 1 {
    let post = array_get(posts, i)
    let slug = get_str(post, "slug")
    let title = get_str(post, "title")
    let content_preview = get_str(post, "content")
    let author = get_str(post, "author")
    let views = get_int(post, "views")

    post_items.push(
      div([
        h3([a(href="/blog/" + slug, [text(title)])]),
        p([text(content_preview)]),
        p([
          em([text("By " + author)]),
          text(" | Views: " + views.to_string()),
        ]),
      ])
    )
  }

  let content : Array[@luna.Node[Unit, String]] = [
    div([
      p([strong([text("Generated at: " + generated_at)])]),
      p([text("This page uses ISR with 60 second TTL. Refresh after 60s to see regeneration.")]),
    ]),
    h1([text("Blog Posts")]),
    p([text("Total posts: " + len.to_string())]),
    div(post_items),
  ]
  @sol.nodes(content)
}

///| Individual blog post page
async fn blog_post(props : @sol.PageProps) -> @server_dom.ServerNode {
  let slug = props.params.get_param("slug").unwrap_or("")
  let post = db_get_post_by_slug(slug)
  let generated_at = get_timestamp()

  let content = if is_null(post) {
    [
      h1([text("Post Not Found")]),
      p([text("The post \"" + slug + "\" was not found.")]),
      a(href="/blog", [text("Back to Blog")]),
    ]
  } else {
    // Increment view count (side effect)
    db_increment_views(slug)

    let title = get_str(post, "title")
    let body = get_str(post, "content")
    let author = get_str(post, "author")
    let views = get_int(post, "views")
    let updated_at = get_str(post, "updated_at")

    [
      div([
        p([strong([text("Generated at: " + generated_at)])]),
        p([text("ISR TTL: 120 seconds")]),
      ]),
      h1([text(title)]),
      p([
        em([text("By " + author)]),
        text(" | Views: " + views.to_string()),
        text(" | Updated: " + updated_at),
      ]),
      div([p([text(body)])]),
      a(href="/blog", [text("Back to Blog")]),
    ]
  }
  @sol.nodes(content)
}

///| Statistics page - shows aggregate data
async fn stats_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let stats = db_get_stats()
  let generated_at = get_timestamp()

  let total_posts = get_int(stats, "total_posts")
  let total_views = get_int(stats, "total_views")
  let avg_views = get_int(stats, "avg_views")
  let max_views = get_int(stats, "max_views")
  let min_views = get_int(stats, "min_views")

  let content : Array[@luna.Node[Unit, String]] = [
    div([
      p([strong([text("Generated at: " + generated_at)])]),
      p([text("ISR TTL: 10 seconds (near real-time)")]),
      p([text("This page regenerates frequently to show updated statistics.")]),
    ]),
    h1([text("Blog Statistics")]),
    div([
      h2([text("Overview")]),
      ul([
        li([text("Total Posts: " + total_posts.to_string())]),
        li([text("Total Views: " + total_views.to_string())]),
        li([text("Average Views: " + avg_views.to_string())]),
        li([text("Max Views: " + max_views.to_string())]),
        li([text("Min Views: " + min_views.to_string())]),
      ]),
    ]),
    div([
      h2([text("ISR Tiers")]),
      ul([
        li([text("Hot (300s): Homepage, popular pages")]),
        li([text("Warm (60-120s): Blog posts, documentation")]),
        li([text("Cold (30-60s): Archive, old content")]),
        li([text("Real-time (10s): Stats, dashboards - like this page!")]),
      ]),
    ]),
    p([a(href="/blog", [text("View Blog Posts")])]),
  ]
  @sol.nodes(content)
}

// =============================================================================
// Router Configuration
// =============================================================================

///|
const ROOT : String =
  #|<!DOCTYPE html>
  #|<html lang="en">
  #|<head>
  #|  <meta charset="UTF-8">
  #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  #|  <title>__LUNA_TITLE__</title>
  #|  <style>
  #|    body { font-family: system-ui, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
  #|    nav { background: #f5f5f5; padding: 10px; margin-bottom: 20px; border-radius: 4px; }
  #|    pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
  #|    a { color: #0066cc; }
  #|  </style>
  #|  __LUNA_HEAD__
  #|</head>
  #|<body>
  #|  <div id="__sol__">__LUNA_MAIN__</div>
  #|</body>
  #|</html>

///|
pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
  .with_root_template(ROOT)
}

///|
/// Empty action registry (no server actions in this demo)
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=[])
}
