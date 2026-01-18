///| Server Layout Component

///|

///| Provides the basic HTML structure for all pages.

///| This is a server component - no event handlers.

///|
/// Styled theme CSS variables (light/dark mode support)
fn styled_css() -> String {
  @styled.theme_variables() +
  @styled_alert.alert_css() +
  @styled_table.table_css() +
  app_css()
}

///|
/// App-specific CSS styles
fn app_css() -> String {
  let css =
    #|/* Base styles */
    #|body {
    #|  font-family: system-ui, -apple-system, sans-serif;
    #|  max-width: 900px;
    #|  margin: 0 auto;
    #|  padding: 2rem;
    #|  background: var(--background);
    #|  color: var(--foreground);
    #|  line-height: 1.6;
    #|}
    #|
    #|/* Navigation */
    #|nav {
    #|  display: flex;
    #|  gap: 1rem;
    #|  margin-bottom: 2rem;
    #|  padding-bottom: 1rem;
    #|  border-bottom: 1px solid var(--border);
    #|  flex-wrap: wrap;
    #|}
    #|
    #|nav a {
    #|  color: var(--link-color);
    #|  text-decoration: none;
    #|  font-weight: 500;
    #|  transition: color 0.15s;
    #|}
    #|
    #|nav a:hover {
    #|  color: var(--link-hover);
    #|}
    #|
    #|/* Cards */
    #|.card {
    #|  padding: 1.5rem;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.5rem;
    #|  background: var(--background);
    #|  margin-bottom: 1rem;
    #|}
    #|
    #|.card-header {
    #|  margin-bottom: 1rem;
    #|  padding-bottom: 0.75rem;
    #|  border-bottom: 1px solid var(--border);
    #|}
    #|
    #|.card-title {
    #|  margin: 0;
    #|  font-size: 1.25rem;
    #|  font-weight: 600;
    #|}
    #|
    #|/* User Profile */
    #|.user-profile {
    #|  max-width: 600px;
    #|}
    #|
    #|.user-header {
    #|  display: flex;
    #|  gap: 1.5rem;
    #|  align-items: center;
    #|  margin-bottom: 2rem;
    #|}
    #|
    #|.user-avatar {
    #|  width: 80px;
    #|  height: 80px;
    #|  border-radius: 50%;
    #|  background: var(--accent);
    #|  color: var(--accent-foreground);
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  font-size: 2rem;
    #|  font-weight: 600;
    #|  text-transform: uppercase;
    #|}
    #|
    #|.user-info h1 {
    #|  margin: 0 0 0.25rem 0;
    #|  font-size: 1.5rem;
    #|}
    #|
    #|.user-bio {
    #|  color: var(--muted-foreground);
    #|  margin: 0;
    #|}
    #|
    #|.user-pages {
    #|  margin-top: 2rem;
    #|}
    #|
    #|.user-pages h2 {
    #|  font-size: 1.25rem;
    #|  margin: 0 0 1rem 0;
    #|}
    #|
    #|.user-pages ul {
    #|  list-style: none;
    #|  padding: 0;
    #|  margin: 0;
    #|}
    #|
    #|.user-pages li {
    #|  padding: 0.75rem 0;
    #|  border-bottom: 1px solid var(--border);
    #|}
    #|
    #|.user-pages li:last-child {
    #|  border-bottom: none;
    #|}
    #|
    #|.user-pages a {
    #|  color: var(--link-color);
    #|  text-decoration: none;
    #|}
    #|
    #|.user-pages a:hover {
    #|  color: var(--link-hover);
    #|  text-decoration: underline;
    #|}
    #|
    #|/* User Page */
    #|.user-page {
    #|  max-width: 700px;
    #|}
    #|
    #|.page-header {
    #|  margin-bottom: 1.5rem;
    #|}
    #|
    #|.breadcrumb {
    #|  color: var(--muted-foreground);
    #|  font-size: 0.875rem;
    #|}
    #|
    #|.breadcrumb a {
    #|  color: var(--link-color);
    #|  text-decoration: none;
    #|}
    #|
    #|.breadcrumb a:hover {
    #|  text-decoration: underline;
    #|}
    #|
    #|.page-content {
    #|  margin: 1.5rem 0;
    #|}
    #|
    #|.page-footer {
    #|  margin-top: 2rem;
    #|  padding-top: 1rem;
    #|  border-top: 1px solid var(--border);
    #|  color: var(--muted-foreground);
    #|  font-size: 0.875rem;
    #|}
    #|
    #|/* Counter component */
    #|.counter {
    #|  margin: 2rem 0;
    #|  padding: 1.5rem;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.5rem;
    #|}
    #|
    #|.buttons {
    #|  display: flex;
    #|  gap: 0.5rem;
    #|  margin-top: 1rem;
    #|}
    #|
    #|.buttons button {
    #|  font-size: 1.25rem;
    #|  padding: 0.5rem 1rem;
    #|  cursor: pointer;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.375rem;
    #|  background: var(--muted);
    #|  color: var(--foreground);
    #|  transition: background 0.15s;
    #|}
    #|
    #|.buttons button:hover {
    #|  background: var(--border);
    #|}
    #|
    #|/* Forms */
    #|.contact-form {
    #|  margin: 2rem 0;
    #|  padding: 1.5rem;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.5rem;
    #|}
    #|
    #|.form-group {
    #|  margin-bottom: 1rem;
    #|}
    #|
    #|.form-group label {
    #|  display: block;
    #|  margin-bottom: 0.5rem;
    #|  font-weight: 500;
    #|}
    #|
    #|.form-group input {
    #|  width: 100%;
    #|  padding: 0.5rem 0.75rem;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.375rem;
    #|  background: var(--background);
    #|  color: var(--foreground);
    #|  box-sizing: border-box;
    #|}
    #|
    #|.form-group input:focus {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -1px;
    #|}
    #|
    #|.form-preview {
    #|  margin: 1rem 0;
    #|  padding: 0.75rem;
    #|  background: var(--muted);
    #|  border-radius: 0.375rem;
    #|}
    #|
    #|.form-actions button {
    #|  padding: 0.5rem 1rem;
    #|  background: var(--accent);
    #|  color: var(--accent-foreground);
    #|  border: none;
    #|  border-radius: 0.375rem;
    #|  cursor: pointer;
    #|  font-weight: 500;
    #|}
    #|
    #|.form-actions button:hover {
    #|  opacity: 0.9;
    #|}
    #|
    #|/* Admin */
    #|.admin-container {
    #|  display: flex;
    #|  gap: 2rem;
    #|}
    #|
    #|.admin-sidebar {
    #|  width: 200px;
    #|  padding: 1rem;
    #|  background: var(--muted);
    #|  border-radius: 0.5rem;
    #|}
    #|
    #|.admin-sidebar h3 {
    #|  margin: 0 0 1rem 0;
    #|  font-size: 1rem;
    #|}
    #|
    #|.admin-sidebar ul {
    #|  list-style: none;
    #|  padding: 0;
    #|  margin: 0;
    #|}
    #|
    #|.admin-sidebar li {
    #|  margin-bottom: 0.5rem;
    #|}
    #|
    #|.admin-sidebar a {
    #|  color: var(--link-color);
    #|  text-decoration: none;
    #|}
    #|
    #|.admin-content {
    #|  flex: 1;
    #|}
    #|
    #|.admin-stats {
    #|  display: flex;
    #|  gap: 1rem;
    #|  margin-top: 1rem;
    #|}
    #|
    #|.stat-card {
    #|  padding: 1rem;
    #|  background: var(--muted);
    #|  border-radius: 0.5rem;
    #|  text-align: center;
    #|  flex: 1;
    #|}
    #|
    #|.stat-card h4 {
    #|  margin: 0 0 0.5rem 0;
    #|  font-size: 0.875rem;
    #|  color: var(--muted-foreground);
    #|}
    #|
    #|.stat-value {
    #|  font-size: 1.5rem;
    #|  font-weight: bold;
    #|  color: var(--accent);
    #|}
    #|
    #|/* Settings */
    #|.settings-section {
    #|  margin-top: 1.5rem;
    #|}
    #|
    #|.setting-item {
    #|  margin-bottom: 1rem;
    #|}
    #|
    #|.setting-item label {
    #|  display: block;
    #|  margin-bottom: 0.5rem;
    #|  font-weight: 500;
    #|}
    #|
    #|.setting-item input {
    #|  padding: 0.5rem 0.75rem;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.375rem;
    #|}
    #|
    #|/* Users list */
    #|.users-list {
    #|  margin-top: 1rem;
    #|}
    #|
    #|.user-row {
    #|  display: flex;
    #|  padding: 0.75rem;
    #|  border-bottom: 1px solid var(--border);
    #|}
    #|
    #|.user-row:last-child {
    #|  border-bottom: none;
    #|}
    #|
    #|.user-row.user-header {
    #|  font-weight: 600;
    #|  background: var(--muted);
    #|}
    #|
    #|.user-cell {
    #|  flex: 1;
    #|}
  css
}

///|
/// Default page styles
let default_style : String = "<style>" + styled_css() + "</style>"

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
      // Auth pages
      sol_link(href="/login", [text("Login")]),
      sol_link(href="/profile", [text("Profile")]),
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
