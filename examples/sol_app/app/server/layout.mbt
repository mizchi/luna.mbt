///| Server Layout Component

///|

///| Provides the basic HTML structure for all pages.

///| This is a server component - no event handlers.

///|
/// Default page styles
let default_style : String = "<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; } .counter { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; } .buttons { margin-top: 1rem; } .buttons button { font-size: 1.5rem; padding: 0.5rem 1rem; margin: 0 0.5rem; cursor: pointer; } nav { margin-bottom: 1rem; } nav a { margin-right: 1rem; } .contact-form { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; } .form-group { margin-bottom: 1rem; } .form-group label { display: block; margin-bottom: 0.25rem; font-weight: 500; } .form-group input { width: 100%; padding: 0.5rem; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; } .form-preview { margin: 1rem 0; padding: 0.5rem; background: #f5f5f5; border-radius: 4px; } .form-actions { margin-top: 1rem; } .form-actions button { padding: 0.5rem 1rem; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; } .form-result { margin-top: 1rem; color: #666; } .admin-container { display: flex; gap: 2rem; } .admin-sidebar { width: 200px; padding: 1rem; background: #f5f5f5; border-radius: 8px; } .admin-sidebar h3 { margin: 0 0 1rem 0; } .admin-sidebar ul { list-style: none; padding: 0; margin: 0; } .admin-sidebar li { margin-bottom: 0.5rem; } .admin-content { flex: 1; } .admin-stats { display: flex; gap: 1rem; margin-top: 1rem; } .stat-card { padding: 1rem; background: #e3f2fd; border-radius: 8px; text-align: center; } .stat-card h4 { margin: 0 0 0.5rem 0; font-size: 0.875rem; color: #666; } .stat-value { font-size: 1.5rem; font-weight: bold; color: #1976d2; } .settings-section { margin-top: 1rem; } .setting-item { margin-bottom: 1rem; } .setting-item label { display: block; margin-bottom: 0.25rem; font-weight: 500; } .setting-item input { padding: 0.5rem; border: 1px solid #ccc; border-radius: 4px; } .users-list { margin-top: 1rem; } .user-row { display: flex; padding: 0.75rem 0; border-bottom: 1px solid #ddd; } .user-row.user-header { font-weight: bold; background: #f5f5f5; padding: 0.75rem; } .user-cell { flex: 1; }</style>"

///|
/// Luna loader script (for island hydration)
let loader_script : String = "<script type=\"module\" src=\"/static/loader.js\"></script>"

///|
/// WC loader script (for Web Components hydration)
let wc_loader_script : String = "<script type=\"module\" src=\"/static/wc-loader.js\"></script>"

///|
/// Sol navigation script
let sol_nav_script : String = "<script type=\"module\" src=\"/static/sol-nav.js\"></script>"

///| Get default head HTML (styles + loader + wc-loader + sol-nav)

///|
/// Note: HMR script is auto-injected by Sol runtime in dev mode (SOL_DEV=1)
pub fn head() -> String {
  default_style + loader_script + wc_loader_script + sol_nav_script
}

///|
/// Basic layout wrapper - wraps content in container with navigation
pub fn layout(inner : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  div(class="container", [
    nav([
      sol_link(href="/", [text("Home")]),
      sol_link(href="/about", [text("About")]),
      sol_link(href="/form", [text("Form")]),
      sol_link(href="/wc-counter", [text("WC Counter")]),
      sol_link(href="/docs/intro", [text("Docs")]),
      sol_link(href="/blog", [text("Blog")]),
      sol_link(href="/admin", [text("Admin")]),
    ]),
    outlet(name="main", inner),
  ])
}

///|
/// Root layout function for SolRoutes::Layout
/// Wraps child content with navigation and container
pub fn root_layout(
  _props : @router.PageProps,
  content : @server_dom.ServerNode,
) -> @server_dom.ServerNode raise Error {
  @server_dom.ServerNode::async_(async fn() {
    let inner = content.resolve()
    layout([inner])
  })
}
