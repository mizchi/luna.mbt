///| Static Site Generator - Main Render Pipeline

// =============================================================================
// Helper Functions (same pattern as transformer.mbt)
// =============================================================================

///| Create a server-side element
fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]]
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///| Create a static attribute
fn attr(key : String, value : String) -> (String, @luna.Attr[Unit]) {
  (key, @luna.attr_static(value))
}

// =============================================================================
// Site Generation
// =============================================================================

///| Generate entire static site
pub fn generate_site(config : @ssg.SsgConfig, cwd : String) -> Result[Unit, String] {
  println("Scanning docs directory: \{config.docs_dir}")

  // Step 1: Scan docs directory with i18n support
  let pages = @routes.scan_docs_dir(config.docs_dir, cwd, i18n=config.i18n)
  if pages.is_empty() {
    return Err("No markdown files found in \{config.docs_dir}")
  }
  println("Found \{pages.length()} pages")

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @ssg.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @ssg.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Create build context
  let ctx = @ssg.BuildContext::{
    config,
    pages,
    sidebar,
    cwd,
  }

  // Step 4: Create output directory
  let output_dir = @path.join2(cwd, config.output_dir)
  ensure_dir(output_dir)

  // Step 5: Generate each page
  for page in pages {
    match generate_page(ctx, page) {
      Ok(_) => println("  Generated: \{page.url_path}")
      Err(e) => println("  Error generating \{page.url_path}: \{e}")
    }
  }

  // Step 6: Copy static assets (if any)
  copy_static_assets(ctx)

  // Step 7: Generate sitemap
  generate_sitemap(ctx)

  Ok(())
}

///| Generate single page
fn generate_page(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta
) -> Result[Unit, String] {
  // Read markdown file
  let source_path = @path.join2(@path.join2(ctx.cwd, ctx.config.docs_dir), page.source_path)
  let content : String = try {
    @fs.readFileSync(source_path).to_string()
  } catch {
    e => return Err("Failed to read \{source_path}: \{e}")
  }

  // Parse markdown
  let (frontmatter, nodes) = @markdown.parse_markdown(content)

  // Convert to VNode
  let content_vnode = @markdown.md_nodes_to_vnode(nodes)

  // Extract TOC
  let toc = @markdown.extract_toc(nodes)

  // Build page HTML
  let html = build_page_html(ctx, page, frontmatter, content_vnode, toc)

  // Write to output
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    @routes.url_to_output_path(page.url_path),
  )

  // Ensure parent directory exists
  let parent_dir = @path.dirname(output_path)
  ensure_dir(parent_dir)

  try {
    @fs.writeFileSync(output_path, @js.any(html))
    Ok(())
  } catch {
    e => Err("Failed to write \{output_path}: \{e}")
  }
}

// =============================================================================
// HTML Building
// =============================================================================

///| Build complete HTML page
fn build_page_html(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
  toc : Array[@markdown.TocItem]
) -> String {
  // Determine layout
  let layout = frontmatter.layout.unwrap_or("doc")

  // Build page VNode based on layout
  let page_vnode = match layout {
    "home" => build_home_layout(ctx, page, frontmatter, content)
    "default" => build_default_layout(ctx, page, frontmatter, content)
    _ => build_doc_layout(ctx, page, frontmatter, content, toc)
  }

  // Render to HTML string
  let result = @render.render_to_string(page_vnode, preload=true)

  // Wrap in full HTML document
  build_html_document(ctx, page, frontmatter, result)
}

///| Build home layout (landing page)
fn build_home_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit]
) -> @luna.Node[Unit] {
  let nav = build_nav(ctx, page)
  let main = h("main", [attr("class", "home-content")], [content])
  let footer = build_footer(ctx)
  h("div", [attr("class", "layout layout-home")], [nav, main, footer])
}

///| Build default layout (nav + content)
fn build_default_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit]
) -> @luna.Node[Unit] {
  let nav = build_nav(ctx, page)
  let main = h("main", [attr("class", "main-content")], [content])
  let footer = build_footer(ctx)
  h("div", [attr("class", "layout layout-default")], [nav, main, footer])
}

///| Build doc layout (nav + sidebar + content + toc)
fn build_doc_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
  toc : Array[@markdown.TocItem]
) -> @luna.Node[Unit] {
  let nav = build_nav(ctx, page)

  // Sidebar (filtered by current locale)
  let sidebar_groups = @routes.get_sidebar_for_path(
    ctx.config,
    ctx.pages,
    page.url_path,
    locale=page.locale,
  )
  let sidebar = if frontmatter.sidebar {
    @routes.render_sidebar(sidebar_groups, page.url_path)
  } else {
    @luna.vfragment([])
  }

  // Mobile sidebar dropdown
  let mobile_sidebar = if frontmatter.sidebar {
    @routes.render_mobile_sidebar(sidebar_groups, page.url_path)
  } else {
    @luna.vfragment([])
  }

  // Main content
  let article = h("article", [attr("class", "doc-content")], [content])

  // TOC (outline)
  let toc_vnode = if not(toc.is_empty()) {
    build_toc(toc)
  } else {
    @luna.vfragment([])
  }

  // Prev/Next navigation
  let prev_next = build_prev_next(ctx, page)

  let main = h("main", [attr("class", "doc-main")], [mobile_sidebar, article, prev_next])

  let content_wrapper = h(
    "div",
    [attr("class", "doc-container")],
    [sidebar, main, toc_vnode],
  )

  let footer = build_footer(ctx)

  h("div", [attr("class", "layout layout-doc")], [nav, content_wrapper, footer])
}

// =============================================================================
// Component Building
// =============================================================================

///| Build navigation bar with language switcher
fn build_nav(ctx : @ssg.BuildContext, page : @ssg.PageMeta) -> @luna.Node[Unit] {
  // Logo/Title
  let logo = match ctx.config.theme.logo {
    Some(src) =>
      h(
        "img",
        [attr("src", src), attr("alt", ctx.config.title), attr("class", "nav-logo")],
        [],
      )
    None =>
      h("span", [attr("class", "nav-title")], [@luna.vtext(ctx.config.title)])
  }

  let home_link = h(
    "a",
    [attr("href", ctx.config.base_url), attr("class", "nav-home")],
    [logo],
  )

  // Nav items
  let nav_items = ctx.config.nav.map(fn(item) { build_nav_item(item) })

  // Language switcher
  let lang_switcher = build_language_switcher(ctx, page)

  // Combine nav links and language switcher
  let nav_children : Array[@luna.Node[Unit]] = nav_items.copy()
  nav_children.push(lang_switcher)
  let nav_links = h("div", [attr("class", "nav-links")], nav_children)

  h(
    "header",
    [attr("class", "nav-bar")],
    [h("div", [attr("class", "nav-container")], [home_link, nav_links])],
  )
}

///| Build language switcher dropdown
fn build_language_switcher(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta
) -> @luna.Node[Unit] {
  let i18n = ctx.config.i18n

  // Only show if more than one locale
  if i18n.locales.length() <= 1 {
    return @luna.vfragment([])
  }

  // Get available translations
  let translations = @routes.get_available_translations(
    ctx.pages,
    page.canonical_path,
    i18n,
  )

  // Find current locale label
  let current_label = i18n.locales
    .iter()
    .find_first(fn(l) { l.code == page.locale })
    .map(fn(l) { l.label })
    .unwrap_or(page.locale)

  // Build dropdown items
  let items : Array[@luna.Node[Unit]] = []
  for item in translations {
    let (locale, translation) = item
    let target_url = match translation {
      Some(p) => p.url_path
      None => {
        // Fallback to default locale version
        match @routes.find_fallback_page(ctx.pages, page.canonical_path, i18n) {
          Some(fallback) => fallback.url_path
          None => page.canonical_path // Just use canonical if no fallback
        }
      }
    }
    let is_current = locale.code == page.locale
    let class_name = if is_current {
      "lang-item lang-item-active"
    } else {
      "lang-item"
    }
    items.push(
      h(
        "a",
        [attr("href", target_url), attr("class", class_name)],
        [@luna.vtext(locale.label)],
      ),
    )
  }

  // Build dropdown with details/summary
  let summary = h(
    "summary",
    [attr("class", "lang-trigger")],
    [@luna.vtext(current_label)],
  )
  let menu = h("div", [attr("class", "lang-menu")], items)

  h("details", [attr("class", "lang-switcher")], [summary, menu])
}

///| Build single nav item
fn build_nav_item(item : @ssg.NavItem) -> @luna.Node[Unit] {
  if item.items.is_empty() {
    // Simple link
    h(
      "a",
      [attr("href", item.link), attr("class", "nav-link")],
      [@luna.vtext(item.text)],
    )
  } else {
    // Dropdown (simplified - actual dropdown needs JS)
    let dropdown_items = item.items.map(fn(sub) {
      h(
        "a",
        [attr("href", sub.link), attr("class", "nav-dropdown-item")],
        [@luna.vtext(sub.text)],
      )
    })
    h(
      "div",
      [attr("class", "nav-dropdown")],
      [
        h(
          "span",
          [attr("class", "nav-dropdown-trigger")],
          [@luna.vtext(item.text)],
        ),
        h("div", [attr("class", "nav-dropdown-menu")], dropdown_items),
      ],
    )
  }
}

///| Build table of contents
fn build_toc(toc : Array[@markdown.TocItem]) -> @luna.Node[Unit] {
  let items = toc.map(fn(item) {
    let indent_class = "toc-item toc-level-\{item.level}"
    h(
      "li",
      [attr("class", indent_class)],
      [h("a", [attr("href", "#" + item.id)], [@luna.vtext(item.text)])],
    )
  })

  // Collapse button at bottom
  let collapse_btn = h(
    "button",
    [
      attr("class", "toc-collapse-btn"),
      attr("type", "button"),
      attr("onclick", "document.body.classList.toggle('toc-collapsed')"),
      attr("aria-label", "Toggle table of contents"),
    ],
    [h("span", [attr("class", "toc-collapse-icon")], [])],
  )

  let title = h("div", [attr("class", "toc-title")], [@luna.vtext("On this page")])
  let content = h("div", [attr("class", "toc-content")], [title, h("ul", [attr("class", "toc-list")], items)])

  h("aside", [attr("class", "toc")], [content, collapse_btn])
}

///| Build prev/next navigation
fn build_prev_next(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta
) -> @luna.Node[Unit] {
  let prev = @routes.find_prev_page(ctx.pages, page.url_path)
  let next = @routes.find_next_page(ctx.pages, page.url_path)

  let children : Array[@luna.Node[Unit]] = []

  match prev {
    Some(link) =>
      children.push(
        h(
          "a",
          [attr("href", link.link), attr("class", "prev-link")],
          [
            h("span", [attr("class", "label")], [@luna.vtext("Previous")]),
            h("span", [attr("class", "title")], [@luna.vtext(link.text)]),
          ],
        ),
      )
    None => ()
  }

  match next {
    Some(link) =>
      children.push(
        h(
          "a",
          [attr("href", link.link), attr("class", "next-link")],
          [
            h("span", [attr("class", "label")], [@luna.vtext("Next")]),
            h("span", [attr("class", "title")], [@luna.vtext(link.text)]),
          ],
        ),
      )
    None => ()
  }

  h("nav", [attr("class", "prev-next")], children)
}

///| Build footer
fn build_footer(ctx : @ssg.BuildContext) -> @luna.Node[Unit] {
  match ctx.config.theme.footer {
    Some(footer_config) => {
      let children : Array[@luna.Node[Unit]] = []
      match footer_config.message {
        Some(msg) =>
          children.push(
            h("p", [attr("class", "footer-message")], [@luna.vtext(msg)]),
          )
        None => ()
      }
      match footer_config.copyright {
        Some(copyright) =>
          children.push(
            h("p", [attr("class", "footer-copyright")], [@luna.vtext(copyright)]),
          )
        None => ()
      }
      h("footer", [attr("class", "site-footer")], children)
    }
    None => @luna.vfragment([])
  }
}

// =============================================================================
// HTML Document
// =============================================================================

///| Build complete HTML document
fn build_html_document(
  ctx : @ssg.BuildContext,
  _page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  render_result : @render.SSRResult
) -> String {
  let page_title = frontmatter.title.unwrap_or(ctx.config.title)
  let desc = frontmatter.description.unwrap_or("")
  let base = ctx.config.base_url

  // Generate preload tags for islands
  let preloads = if render_result.preload_urls.length() > 0 {
    @render.generate_preload_tags(render_result.preload_urls)
  } else {
    ""
  }

  // Primary color CSS variable
  let primary = ctx.config.theme.primary_color.unwrap_or("#3451b2")

  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>\{page_title}</title>\n  <meta name=\"description\" content=\"\{desc}\">\n  <link rel=\"stylesheet\" href=\"\{base}assets/style.css\">\n  <style>:root { --primary-color: \{primary}; }</style>\n  \{preloads}\n</head>\n<body>\n  <div id=\"app\">\{render_result.html}</div>\n  <script type=\"module\" src=\"\{base}assets/loader.js\"></script>\n</body>\n</html>"
}

// =============================================================================
// Utility Functions
// =============================================================================

///| Ensure directory exists
fn ensure_dir(path : String) -> Unit {
  try {
    @fs.mkdirSync(path, recursive=true)
  } catch {
    _ => ()
  }
}

///| Copy static assets
fn copy_static_assets(ctx : @ssg.BuildContext) -> Unit {
  let output_assets = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "assets",
  )
  ensure_dir(output_assets)

  // Write default CSS
  let css = get_default_css(ctx.config)
  let css_path = @path.join2(output_assets, "style.css")
  try {
    @fs.writeFileSync(css_path, @js.any(css))
  } catch {
    _ => ()
  }
}

///| Generate sitemap.xml
fn generate_sitemap(ctx : @ssg.BuildContext) -> Unit {
  let buf = StringBuilder::new()
  buf.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
  buf.write_string("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n")

  for page in ctx.pages {
    let url = ctx.config.base_url + page.url_path.trim_start(chars="/").to_string()
    buf.write_string("  <url>\n")
    buf.write_string("    <loc>\{url}</loc>\n")
    match page.last_modified {
      Some(date) => buf.write_string("    <lastmod>\{date}</lastmod>\n")
      None => ()
    }
    buf.write_string("  </url>\n")
  }

  buf.write_string("</urlset>\n")

  let sitemap_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "sitemap.xml",
  )
  try {
    @fs.writeFileSync(sitemap_path, @js.any(buf.to_string()))
  } catch {
    _ => ()
  }
}

///| Get default CSS styles
fn get_default_css(config : @ssg.SsgConfig) -> String {
  let primary_color = config.theme.primary_color.unwrap_or("#3451b2")
  let css_rest =
    #|  --text-color: #213547;
  #|  --bg-color: #ffffff;
  #|  --sidebar-bg: #f6f6f7;
  #|  --border-color: #e2e2e3;
  #|  --code-bg: #f6f6f7;
  #|}
  #|
  #|@media (prefers-color-scheme: dark) {
  #|  :root {
  #|    --text-color: #e5e7eb;
  #|    --bg-color: #1a1a1a;
  #|    --sidebar-bg: #242424;
  #|    --border-color: #3f3f3f;
  #|    --code-bg: #2d2d2d;
  #|  }
  #|}
  #|
  #|* { box-sizing: border-box; margin: 0; padding: 0; }
  #|
  #|body {
  #|  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
  #|  color: var(--text-color);
  #|  background: var(--bg-color);
  #|  line-height: 1.6;
  #|}
  #|
  #|/* Navigation */
  #|.nav-bar {
  #|  position: sticky;
  #|  top: 0;
  #|  z-index: 100;
  #|  background: var(--bg-color);
  #|  border-bottom: 1px solid var(--border-color);
  #|  padding: 0.75rem 1.5rem;
  #|}
  #|
  #|.nav-container {
  #|  max-width: 1400px;
  #|  margin: 0 auto;
  #|  display: flex;
  #|  justify-content: space-between;
  #|  align-items: center;
  #|}
  #|
  #|.nav-home { text-decoration: none; font-weight: 600; color: var(--text-color); }
  #|.nav-logo { height: 32px; }
  #|.nav-title { font-size: 1.25rem; }
  #|.nav-links { display: flex; gap: 1.5rem; align-items: center; }
  #|.nav-link { color: var(--text-color); text-decoration: none; }
  #|.nav-link:hover { color: var(--primary-color); }
  #|
  #|/* Language Switcher */
  #|.lang-switcher {
  #|  position: relative;
  #|  margin-left: 0.5rem;
  #|}
  #|.lang-trigger {
  #|  cursor: pointer;
  #|  padding: 0.375rem 0.75rem;
  #|  border: 1px solid var(--border-color);
  #|  border-radius: 4px;
  #|  font-size: 0.875rem;
  #|  color: var(--text-color);
  #|  list-style: none;
  #|  display: flex;
  #|  align-items: center;
  #|  gap: 0.375rem;
  #|}
  #|.lang-trigger::-webkit-details-marker { display: none; }
  #|.lang-trigger::after {
  #|  content: '';
  #|  border-left: 4px solid transparent;
  #|  border-right: 4px solid transparent;
  #|  border-top: 5px solid currentColor;
  #|}
  #|.lang-switcher[open] .lang-trigger::after {
  #|  border-top: none;
  #|  border-bottom: 5px solid currentColor;
  #|}
  #|.lang-menu {
  #|  position: absolute;
  #|  top: 100%;
  #|  right: 0;
  #|  margin-top: 0.25rem;
  #|  background: var(--bg-color);
  #|  border: 1px solid var(--border-color);
  #|  border-radius: 4px;
  #|  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  #|  min-width: 120px;
  #|  z-index: 200;
  #|}
  #|.lang-item {
  #|  display: block;
  #|  padding: 0.5rem 0.75rem;
  #|  color: var(--text-color);
  #|  text-decoration: none;
  #|  font-size: 0.875rem;
  #|}
  #|.lang-item:hover { background: var(--sidebar-bg); }
  #|.lang-item-active {
  #|  color: var(--primary-color);
  #|  font-weight: 500;
  #|}
  #|
  #|/* Layout */
  #|.layout-doc { display: flex; flex-direction: column; min-height: 100vh; }
  #|.doc-container { display: flex; flex: 1; width: 100%; }
  #|
  #|/* Home Layout */
  #|.layout-home { min-height: 100vh; display: flex; flex-direction: column; }
  #|.home-content {
  #|  flex: 1;
  #|  max-width: 800px;
  #|  margin: 0 auto;
  #|  padding: 3rem 2rem;
  #|  width: 100%;
  #|}
  #|.home-content h1:first-child {
  #|  font-size: 2.5rem;
  #|  text-align: center;
  #|  margin-bottom: 1.5rem;
  #|  border: none;
  #|}
  #|.home-content > p:first-of-type {
  #|  font-size: 1.25rem;
  #|  text-align: center;
  #|  color: #666;
  #|  margin-bottom: 2rem;
  #|}
  #|
  #|/* Sidebar */
  #|.sidebar {
  #|  position: fixed;
  #|  left: 0;
  #|  top: 60px;
  #|  width: 260px;
  #|  height: calc(100vh - 60px);
  #|  background: var(--sidebar-bg);
  #|  border-right: 1px solid var(--border-color);
  #|  display: flex;
  #|  flex-direction: column;
  #|  transition: width 0.2s ease;
  #|  z-index: 10;
  #|}
  #|.sidebar-collapsed .sidebar {
  #|  width: 32px;
  #|}
  #|.sidebar-content {
  #|  flex: 1;
  #|  padding: 1rem 1.5rem;
  #|  overflow-y: auto;
  #|}
  #|.sidebar-collapse-btn {
  #|  display: flex;
  #|  align-items: center;
  #|  justify-content: center;
  #|  padding: 0.75rem;
  #|  border: none;
  #|  border-top: 1px solid var(--border-color);
  #|  background: transparent;
  #|  cursor: pointer;
  #|  color: var(--text-color);
  #|  opacity: 0.6;
  #|  transition: opacity 0.2s;
  #|  margin-top: auto;
  #|}
  #|.sidebar-collapse-btn:hover { opacity: 1; }
  #|.collapse-icon::before {
  #|  content: '«';
  #|  font-size: 1.25rem;
  #|  font-weight: bold;
  #|}
  #|.sidebar-collapsed .sidebar-content { display: none; }
  #|.sidebar-collapsed .sidebar .collapse-icon::before { content: '»'; }
  #|
  #|.sidebar-group { margin-bottom: 1rem; }
  #|.sidebar-group-title {
  #|  font-weight: 600;
  #|  margin-bottom: 0.5rem;
  #|  color: var(--text-color);
  #|  font-size: 0.875rem;
  #|  text-transform: uppercase;
  #|  letter-spacing: 0.05em;
  #|}
  #|.sidebar-items { list-style: none; }
  #|.sidebar-link {
  #|  display: block;
  #|  padding: 0.375rem 0;
  #|  color: #666;
  #|  text-decoration: none;
  #|  font-size: 0.9375rem;
  #|}
  #|.sidebar-link:hover { color: var(--primary-color); }
  #|.sidebar-link.active { color: var(--primary-color); font-weight: 500; }
  #|
  #|/* Collapsible sidebar groups */
  #|.sidebar-collapse {
  #|  border: none;
  #|  margin-bottom: 0.5rem;
  #|}
  #|.sidebar-collapse summary {
  #|  cursor: pointer;
  #|  font-weight: 600;
  #|  font-size: 0.875rem;
  #|  color: var(--text-color);
  #|  padding: 0.375rem 0;
  #|  list-style: none;
  #|  display: flex;
  #|  align-items: center;
  #|  gap: 0.5rem;
  #|}
  #|.sidebar-collapse summary::-webkit-details-marker { display: none; }
  #|.sidebar-collapse summary::before {
  #|  content: '';
  #|  width: 0;
  #|  height: 0;
  #|  border-left: 5px solid currentColor;
  #|  border-top: 4px solid transparent;
  #|  border-bottom: 4px solid transparent;
  #|  transition: transform 0.2s;
  #|}
  #|.sidebar-collapse[open] summary::before {
  #|  transform: rotate(90deg);
  #|}
  #|.sidebar-collapse .sidebar-items {
  #|  padding-left: 0.75rem;
  #|  margin-top: 0.25rem;
  #|}
  #|
  #|/* Main Content */
  #|.doc-main { flex: 1; padding: 2rem; max-width: 800px; margin-left: 260px; margin-right: 220px; }
  #|.sidebar-collapsed .doc-main { margin-left: 32px; }
  #|.toc-collapsed .doc-main { margin-right: 32px; }
  #|.sidebar-collapsed.toc-collapsed .doc-main { margin-left: auto; margin-right: auto; padding-left: 48px; padding-right: 48px; }
  #|.doc-content { line-height: 1.7; }
  #|
  #|/* Typography */
  #|.heading { margin: 1.5rem 0 1rem; font-weight: 600; }
  #|.heading-1 { font-size: 2rem; border-bottom: 1px solid var(--border-color); padding-bottom: 0.5rem; }
  #|.heading-2 { font-size: 1.5rem; }
  #|.heading-3 { font-size: 1.25rem; }
  #|
  #|p { margin: 1rem 0; }
  #|
  #|a { color: var(--primary-color); }
  #|
  #|code {
  #|  background: var(--code-bg);
  #|  padding: 0.2rem 0.4rem;
  #|  border-radius: 4px;
  #|  font-size: 0.9em;
  #|}
  #|
  #|pre {
  #|  background: var(--code-bg);
  #|  padding: 1rem;
  #|  border-radius: 8px;
  #|  overflow-x: auto;
  #|  margin: 1rem 0;
  #|}
  #|
  #|pre code { background: none; padding: 0; }
  #|
  #|/* TOC */
  #|.toc {
  #|  position: fixed;
  #|  right: 0;
  #|  top: 60px;
  #|  width: 220px;
  #|  height: calc(100vh - 60px);
  #|  display: flex;
  #|  flex-direction: column;
  #|  border-left: 1px solid var(--border-color);
  #|  background: var(--bg-color);
  #|  transition: width 0.2s ease;
  #|}
  #|.toc-collapsed .toc {
  #|  width: 32px;
  #|}
  #|.toc-content {
  #|  flex: 1;
  #|  padding: 1rem;
  #|  overflow-y: auto;
  #|}
  #|.toc-collapse-btn {
  #|  display: flex;
  #|  align-items: center;
  #|  justify-content: center;
  #|  padding: 0.75rem;
  #|  border: none;
  #|  border-top: 1px solid var(--border-color);
  #|  background: transparent;
  #|  cursor: pointer;
  #|  color: var(--text-color);
  #|  opacity: 0.6;
  #|  transition: opacity 0.2s;
  #|  margin-top: auto;
  #|}
  #|.toc-collapse-btn:hover { opacity: 1; }
  #|.toc-collapse-icon::before { content: '»'; font-size: 1.25rem; font-weight: bold; }
  #|.toc-collapsed .toc-content { display: none; }
  #|.toc-collapsed .toc-collapse-icon::before { content: '«'; }
  #|.toc-title { font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem; }
  #|.toc-list { list-style: none; font-size: 0.875rem; }
  #|.toc-item { padding: 0.25rem 0; }
  #|.toc-item a { color: #666; text-decoration: none; }
  #|.toc-item a:hover { color: var(--primary-color); }
  #|.toc-level-3 { padding-left: 0.75rem; }
  #|.toc-level-4 { padding-left: 1.5rem; }
  #|
  #|/* Prev/Next */
  #|.prev-next {
  #|  display: flex;
  #|  justify-content: space-between;
  #|  margin-top: 2rem;
  #|  padding-top: 1rem;
  #|  border-top: 1px solid var(--border-color);
  #|}
  #|
  #|.prev-link, .next-link {
  #|  display: flex;
  #|  flex-direction: column;
  #|  text-decoration: none;
  #|}
  #|
  #|.prev-link .label, .next-link .label { font-size: 0.75rem; color: #666; }
  #|.prev-link .title, .next-link .title { color: var(--primary-color); font-weight: 500; }
  #|.next-link { text-align: right; margin-left: auto; }
  #|
  #|/* Footer */
  #|.site-footer {
  #|  padding: 2rem;
  #|  text-align: center;
  #|  border-top: 1px solid var(--border-color);
  #|  color: #666;
  #|  font-size: 0.875rem;
  #|}
  #|
  #|/* Dark mode overrides */
  #|@media (prefers-color-scheme: dark) {
  #|  .sidebar-link { color: #9ca3af; }
  #|  .toc-item a { color: #9ca3af; }
  #|  .prev-link .label, .next-link .label { color: #9ca3af; }
  #|  .site-footer { color: #9ca3af; }
  #|  .home-content > p:first-of-type { color: #9ca3af; }
  #|  .lang-menu { background: var(--bg-color); }
  #|}
  #|
  #|/* Mobile Sidebar Dropdown */
  #|.mobile-sidebar {
  #|  display: none;
  #|  margin-bottom: 1rem;
  #|  border: 1px solid var(--border-color);
  #|  border-radius: 8px;
  #|  background: var(--sidebar-bg);
  #|}
  #|.mobile-sidebar-trigger {
  #|  display: flex;
  #|  justify-content: space-between;
  #|  align-items: center;
  #|  padding: 0.75rem 1rem;
  #|  cursor: pointer;
  #|  list-style: none;
  #|  font-weight: 500;
  #|}
  #|.mobile-sidebar-trigger::-webkit-details-marker { display: none; }
  #|.mobile-sidebar-arrow {
  #|  border-left: 5px solid transparent;
  #|  border-right: 5px solid transparent;
  #|  border-top: 6px solid currentColor;
  #|  transition: transform 0.2s;
  #|}
  #|.mobile-sidebar[open] .mobile-sidebar-arrow {
  #|  transform: rotate(180deg);
  #|}
  #|.mobile-sidebar-content {
  #|  border-top: 1px solid var(--border-color);
  #|  padding: 0.5rem 0;
  #|  max-height: 60vh;
  #|  overflow-y: auto;
  #|}
  #|.mobile-sidebar-content .sidebar-collapse { border: none; }
  #|.mobile-sidebar-content .sidebar-collapse summary { padding: 0.5rem 1rem; }
  #|.mobile-sidebar-content .sidebar-items { padding-left: 1.5rem; }
  #|
  #|/* Responsive */
  #|@media (max-width: 960px) {
  #|  .sidebar-desktop { display: none; }
  #|  .mobile-sidebar { display: block; }
  #|  .toc { display: none; }
  #|}
  "/* Luna SSG Default Theme */\n:root {\n  --primary-color: \{primary_color};\n" + css_rest
}
