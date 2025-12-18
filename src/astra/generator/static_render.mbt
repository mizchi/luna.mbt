///| Static Site Generator - Main Render Pipeline

// =============================================================================
// Helper Functions (same pattern as transformer.mbt)
// =============================================================================

///|
/// Create a server-side element
fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Create a static attribute
fn attr(key : String, value : String) -> (String, @luna.Attr[Unit]) {
  (key, @luna.attr_static(value))
}

// =============================================================================
// Site Generation
// =============================================================================

///|
/// Generate entire static site (sync version without syntax highlighting)
pub fn generate_site(
  config : @astra.SsgConfig,
  cwd : String,
) -> Result[Unit, String] {
  generate_site_internal(config, cwd, None)
}

///|
/// Generate entire static site with Shiki syntax highlighting (async)
pub async fn generate_site_async(
  config : @astra.SsgConfig,
  cwd : String,
) -> Result[Unit, String] {
  // Create Shiki highlighter
  let highlighter = @shiki.create_default_highlighter().wait()
  generate_site_internal(config, cwd, Some(highlighter))
}

///|
/// Generate entire static site with pre-created highlighter
pub fn generate_site_with_highlighter(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
) -> Result[Unit, String] {
  generate_site_internal(config, cwd, Some(highlighter))
}

///|
/// Internal site generation
fn generate_site_internal(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter?,
) -> Result[Unit, String] {
  println("Scanning docs directory: \{config.docs_dir}")

  // Step 1: Scan docs directory with i18n and exclude support
  let pages = @routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
  )
  if pages.is_empty() {
    return Err("No markdown files found in \{config.docs_dir}")
  }
  println("Found \{pages.length()} pages")

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @astra.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @astra.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Create build context
  let ctx = @astra.BuildContext::{ config, pages, sidebar, cwd }

  // Step 4: Create output directory
  let output_dir = @path.join2(cwd, config.output_dir)
  ensure_dir(output_dir)

  // Step 5: Generate each page
  for page in pages {
    match generate_page_with_highlight(ctx, page, highlighter) {
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

///|
/// Generate single page (sync, no highlighting)
fn generate_page(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> Result[Unit, String] {
  generate_page_with_highlight(ctx, page, None)
}

///|
/// Generate single page with optional syntax highlighting
fn generate_page_with_highlight(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  highlighter : @shiki.Highlighter?,
) -> Result[Unit, String] {
  // Read markdown file
  let source_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    page.source_path,
  )
  let content : String = @fs.readFileSync(source_path).to_string() catch {
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

  // Apply syntax highlighting if highlighter is available
  let final_html = match highlighter {
    Some(h) => apply_syntax_highlighting(html, h)
    None => html
  }

  // Write to output
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    @routes.url_to_output_path(page.url_path),
  )

  // Ensure parent directory exists
  let parent_dir = @path.dirname(output_path)
  ensure_dir(parent_dir)
  try {
    @fs.writeFileSync(output_path, @js.any(final_html))
    Ok(())
  } catch {
    e => Err("Failed to write \{output_path}: \{e}")
  }
}

// =============================================================================
// HTML Building
// =============================================================================

///|
/// Build complete HTML page
fn build_page_html(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit],
  toc : Array[@markdown.TocItem],
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

///|
/// Build home layout (landing page)
fn build_home_layout(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  _frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit],
) -> @luna.Node[Unit] {
  let nav = build_nav(ctx, page)
  let main = h("main", [attr("class", "home-content")], [content])
  let footer = build_footer(ctx)
  h("div", [attr("class", "layout layout-home")], [nav, main, footer])
}

///|
/// Build default layout (nav + content)
fn build_default_layout(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  _frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit],
) -> @luna.Node[Unit] {
  let nav = build_nav(ctx, page)
  let main = h("main", [attr("class", "main-content")], [content])
  let footer = build_footer(ctx)
  h("div", [attr("class", "layout layout-default")], [nav, main, footer])
}

///|
/// Build doc layout (nav + sidebar + content + toc)
fn build_doc_layout(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit],
  toc : Array[@markdown.TocItem],
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
  let article = h("article", [attr("class", "doc-content markdown-body")], [
    content,
  ])

  // TOC (outline)
  let toc_vnode = if not(toc.is_empty()) {
    build_toc(toc)
  } else {
    @luna.vfragment([])
  }

  // Prev/Next navigation
  let prev_next = build_prev_next(ctx, page)
  let main = h("main", [attr("class", "doc-main")], [
    mobile_sidebar, article, prev_next,
  ])
  let content_wrapper = h("div", [attr("class", "doc-container")], [
    sidebar, main, toc_vnode,
  ])
  let footer = build_footer(ctx)
  h("div", [attr("class", "layout layout-doc")], [nav, content_wrapper, footer])
}

// =============================================================================
// Component Building
// =============================================================================

///|
/// Build navigation bar with language switcher
fn build_nav(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  // Logo/Title
  let logo = match ctx.config.theme.logo {
    Some(src) =>
      h(
        "img",
        [
          attr("src", src),
          attr("alt", ctx.config.title),
          attr("class", "nav-logo"),
        ],
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

  // Theme toggle button
  let theme_toggle = build_theme_toggle()

  // Combine nav links, language switcher, and theme toggle
  let nav_children : Array[@luna.Node[Unit]] = nav_items.copy()
  nav_children.push(lang_switcher)
  nav_children.push(theme_toggle)
  let nav_links = h("div", [attr("class", "nav-links")], nav_children)
  h("header", [attr("class", "nav-bar")], [
    h("div", [attr("class", "nav-container")], [home_link, nav_links]),
  ])
}

///|
/// Build language switcher dropdown
fn build_language_switcher(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
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
      None =>
        // Fallback to default locale version
        match @routes.find_fallback_page(ctx.pages, page.canonical_path, i18n) {
          Some(fallback) => fallback.url_path
          None => page.canonical_path // Just use canonical if no fallback
        }
    }
    let is_current = locale.code == page.locale
    let class_name = if is_current {
      "lang-item lang-item-active"
    } else {
      "lang-item"
    }
    items.push(
      h("a", [attr("href", target_url), attr("class", class_name)], [
        @luna.vtext(locale.label),
      ]),
    )
  }

  // Build dropdown with details/summary
  let summary = h("summary", [attr("class", "lang-trigger")], [
    @luna.vtext(current_label),
  ])
  let menu = h("div", [attr("class", "lang-menu")], items)
  h("details", [attr("class", "lang-switcher")], [summary, menu])
}

///|
/// Build theme toggle button (dark/light mode)
fn build_theme_toggle() -> @luna.Node[Unit] {
  // Sun icon (for dark mode - click to switch to light)
  let sun_icon = h(
    "svg",
    [
      attr("class", "theme-icon theme-icon-light"),
      attr("viewBox", "0 0 24 24"),
      attr("width", "18"),
      attr("height", "18"),
      attr("fill", "none"),
      attr("stroke", "currentColor"),
      attr("stroke-width", "2"),
    ],
    [
      h(
        "circle",
        [attr("cx", "12"), attr("cy", "12"), attr("r", "5")],
        [],
      ),
      h(
        "path",
        [
          attr(
            "d",
            "M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42",
          ),
        ],
        [],
      ),
    ],
  )

  // Moon icon (for light mode - click to switch to dark)
  let moon_icon = h(
    "svg",
    [
      attr("class", "theme-icon theme-icon-dark"),
      attr("viewBox", "0 0 24 24"),
      attr("width", "18"),
      attr("height", "18"),
      attr("fill", "none"),
      attr("stroke", "currentColor"),
      attr("stroke-width", "2"),
    ],
    [
      h(
        "path",
        [attr("d", "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z")],
        [],
      ),
    ],
  )

  h(
    "button",
    [
      attr("class", "theme-toggle"),
      attr("type", "button"),
      attr("aria-label", "Toggle dark mode"),
      attr("onclick", "toggleTheme()"),
    ],
    [sun_icon, moon_icon],
  )
}

///|
/// Build single nav item
fn build_nav_item(item : @astra.NavItem) -> @luna.Node[Unit] {
  if item.items.is_empty() {
    // Simple link
    h("a", [attr("href", item.link), attr("class", "nav-link")], [
      @luna.vtext(item.text),
    ])
  } else {
    // Dropdown (simplified - actual dropdown needs JS)
    let dropdown_items = item.items.map(fn(sub) {
      h("a", [attr("href", sub.link), attr("class", "nav-dropdown-item")], [
        @luna.vtext(sub.text),
      ])
    })
    h("div", [attr("class", "nav-dropdown")], [
      h("span", [attr("class", "nav-dropdown-trigger")], [
        @luna.vtext(item.text),
      ]),
      h("div", [attr("class", "nav-dropdown-menu")], dropdown_items),
    ])
  }
}

///|
/// Build table of contents
fn build_toc(toc : Array[@markdown.TocItem]) -> @luna.Node[Unit] {
  let items = toc.map(fn(item) {
    let indent_class = "toc-item toc-level-\{item.level}"
    h("li", [attr("class", indent_class)], [
      h("a", [attr("href", "#" + item.id)], [@luna.vtext(item.text)]),
    ])
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
  let title = h("div", [attr("class", "toc-title")], [
    @luna.vtext("On this page"),
  ])
  let content = h("div", [attr("class", "toc-content")], [
    title,
    h("ul", [attr("class", "toc-list")], items),
  ])
  h("aside", [attr("class", "toc")], [content, collapse_btn])
}

///|
/// Build prev/next navigation
fn build_prev_next(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  let prev = @routes.find_prev_page(ctx.pages, page.url_path)
  let next = @routes.find_next_page(ctx.pages, page.url_path)
  let children : Array[@luna.Node[Unit]] = []
  match prev {
    Some(link) =>
      children.push(
        h("a", [attr("href", link.link), attr("class", "prev-link")], [
          h("span", [attr("class", "label")], [@luna.vtext("Previous")]),
          h("span", [attr("class", "title")], [@luna.vtext(link.text)]),
        ]),
      )
    None => ()
  }
  match next {
    Some(link) =>
      children.push(
        h("a", [attr("href", link.link), attr("class", "next-link")], [
          h("span", [attr("class", "label")], [@luna.vtext("Next")]),
          h("span", [attr("class", "title")], [@luna.vtext(link.text)]),
        ]),
      )
    None => ()
  }
  h("nav", [attr("class", "prev-next")], children)
}

///|
/// Build footer
fn build_footer(ctx : @astra.BuildContext) -> @luna.Node[Unit] {
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

///|
/// Build complete HTML document
fn build_html_document(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
  render_result : @render.SSRResult,
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

  // Get page order for current locale
  let page_order = get_page_order(ctx.pages, page.locale)

  // Navigation script for View Transition direction
  let nav_script = get_navigation_script(page_order)

  // Theme initialization script (runs early to prevent flash)
  let theme_script = get_theme_script()
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>\{page_title}</title>\n  <meta name=\"description\" content=\"\{desc}\">\n  <script>\{theme_script}</script>\n  <link rel=\"stylesheet\" href=\"\{base}assets/github-markdown.css\">\n  <link rel=\"stylesheet\" href=\"\{base}assets/shiki.css\">\n  <link rel=\"stylesheet\" href=\"\{base}assets/style.css\">\n  <style>:root { --primary-color: \{primary}; }</style>\n  \{preloads}\n</head>\n<body>\n  <div id=\"app\">\{render_result.html}</div>\n  <script type=\"module\" src=\"\{base}assets/loader.js\"></script>\n  \{nav_script}\n</body>\n</html>"
}

// =============================================================================
// Navigation Script
// =============================================================================

///|
/// Get page order (URL list) for a locale based on sidebar order
fn get_page_order(
  pages : Array[@astra.PageMeta],
  locale : String,
) -> Array[String] {
  // Generate sidebar groups for this locale to get the correct order
  let sidebar_groups = @routes.generate_auto_sidebar(pages, locale~)
  @routes.get_sidebar_page_order(sidebar_groups)
}

///|
/// Get inline script for View Transition direction detection
fn get_navigation_script(page_order : Array[String]) -> String {
  // Build JSON array of page URLs
  let urls_json = page_order.map(fn(url) { "\"\{url}\"" }).join(", ")
  "<script>\n(function() {\n  const pageOrder = [\{urls_json}];\n  function getPageIndex(url) {\n    if (!url) return -1;\n    const path = new URL(url).pathname.replace(/\\/$/, '') || '/';\n    return pageOrder.findIndex(p => p.replace(/\\/$/, '') === path || p === path + '/');\n  }\n  function getCurrentIndex() {\n    return getPageIndex(location.href);\n  }\n  function navigateTo(url) {\n    window.scrollTo({ top: 0, behavior: 'instant' });\n    location.href = url;\n  }\n  window.addEventListener('pagereveal', (e) => {\n    if (!e.viewTransition || !navigation.activation) return;\n    const nav = navigation.activation;\n    const fromIdx = getPageIndex(nav.from?.url);\n    const toIdx = getPageIndex(nav.entry?.url);\n    if (fromIdx !== -1 && toIdx !== -1) {\n      e.viewTransition.types.add(toIdx > fromIdx ? 'forwards' : 'backwards');\n    } else {\n      e.viewTransition.types.add('forwards');\n    }\n  });\n  document.addEventListener('keydown', (e) => {\n    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;\n    const idx = getCurrentIndex();\n    if (idx === -1) return;\n    if (e.key === 'ArrowRight' && idx < pageOrder.length - 1) {\n      e.preventDefault();\n      navigateTo(pageOrder[idx + 1]);\n    } else if (e.key === 'ArrowLeft' && idx > 0) {\n      const prevPage = pageOrder[idx - 1];\n      if (prevPage === '/' || prevPage === '') return;\n      e.preventDefault();\n      navigateTo(prevPage);\n    }\n  });\n})();\n</script>"
}

///|
/// Get theme toggle script (early load to prevent flash)
fn get_theme_script() -> String {
  let script =
    #|(function(){
    #|  var theme = localStorage.getItem('theme');
    #|  var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    #|  var isDark = theme === 'dark' || (theme !== 'light' && prefersDark);
    #|  if (isDark) {
    #|    document.documentElement.classList.add('dark');
    #|  }
    #|  window.toggleTheme = function() {
    #|    var html = document.documentElement;
    #|    var wasDark = html.classList.contains('dark');
    #|    if (wasDark) {
    #|      html.classList.remove('dark');
    #|      localStorage.setItem('theme', 'light');
    #|    } else {
    #|      html.classList.add('dark');
    #|      localStorage.setItem('theme', 'dark');
    #|    }
    #|  };
    #|})();
  script
}

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Apply syntax highlighting to code blocks in HTML
/// Finds <pre class="code-block" data-lang="xxx"> elements and highlights them
fn apply_syntax_highlighting(
  html : String,
  highlighter : @shiki.Highlighter,
) -> String {
  apply_syntax_highlighting_js(html, highlighter)
}

///|
/// JS implementation of syntax highlighting
extern "js" fn apply_syntax_highlighting_js(
  html : String,
  highlighter : @shiki.Highlighter,
) -> String =
  #| (html, h) => {
  #|   // Match <pre class="code-block" data-lang="xxx"><code ...>...</code></pre>
  #|   const codeBlockRegex = /<pre class="code-block"(?: data-lang="([^"]*)")?(?: data-filename="([^"]*)")?(?: data-meta="([^"]*)")?><code[^>]*>([\s\S]*?)<\/code><\/pre>/g;
  #|   const aliases = { js: "javascript", ts: "typescript", mbt: "rust", moonbit: "rust", sh: "bash", shell: "bash", yml: "yaml" };
  #|
  #|   let result = html;
  #|   let match;
  #|   const replacements = [];
  #|
  #|   while ((match = codeBlockRegex.exec(html)) !== null) {
  #|     const [fullMatch, lang, filename, meta, codeContent] = match;
  #|     if (!lang) continue;
  #|
  #|     // Decode HTML entities
  #|     const code = codeContent
  #|       .replace(/&lt;/g, '<')
  #|       .replace(/&gt;/g, '>')
  #|       .replace(/&quot;/g, '"')
  #|       .replace(/&#39;/g, "'")
  #|       .replace(/&amp;/g, '&');
  #|
  #|     const resolved = aliases[lang] || lang;
  #|
  #|     // Try to highlight (sync since we preloaded themes)
  #|     try {
  #|       const loaded = h.getLoadedLanguages();
  #|       if (!loaded.includes(resolved)) {
  #|         // Skip if language not loaded (will use fallback styling)
  #|         continue;
  #|       }
  #|       const highlighted = h.codeToHtml(code, {
  #|         lang: resolved,
  #|         themes: { light: "github-light", dark: "github-dark" },
  #|         defaultColor: false,
  #|       });
  #|       replacements.push({ original: fullMatch, replacement: highlighted });
  #|     } catch (e) {
  #|       // Keep original on error
  #|     }
  #|   }
  #|
  #|   // Apply replacements
  #|   for (const { original, replacement } of replacements) {
  #|     result = result.replace(original, replacement);
  #|   }
  #|
  #|   return result;
  #| }

///|
/// Ensure directory exists
fn ensure_dir(path : String) -> Unit {
  @fs.mkdirSync(path, recursive=true) catch {
    _ => ()
  }
}

///|
/// Copy static assets
fn copy_static_assets(ctx : @astra.BuildContext) -> Unit {
  let output_assets = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "assets",
  )
  ensure_dir(output_assets)

  // Write default CSS
  let css = get_default_css(ctx.config)
  let css_path = @path.join2(output_assets, "style.css")
  @fs.writeFileSync(css_path, @js.any(css)) catch {
    _ => ()
  }

  // Write shiki CSS
  let shiki_css = @shiki.generate_shiki_css()
  let shiki_css_path = @path.join2(output_assets, "shiki.css")
  @fs.writeFileSync(shiki_css_path, @js.any(shiki_css)) catch {
    _ => ()
  }

  // Write github-markdown CSS
  let github_md_css = get_github_markdown_css()
  let github_md_css_path = @path.join2(output_assets, "github-markdown.css")
  @fs.writeFileSync(github_md_css_path, @js.any(github_md_css)) catch {
    _ => ()
  }

  // Write loader.js (for island hydration)
  let loader_js = get_loader_js()
  let loader_js_path = @path.join2(output_assets, "loader.js")
  @fs.writeFileSync(loader_js_path, @js.any(loader_js)) catch {
    _ => ()
  }
}

///|
/// Generate sitemap.xml
fn generate_sitemap(ctx : @astra.BuildContext) -> Unit {
  let buf = StringBuilder::new()
  buf.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
  buf.write_string(
    "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n",
  )
  for page in ctx.pages {
    let url = ctx.config.base_url +
      page.url_path.trim_start(chars="/").to_string()
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
  @fs.writeFileSync(sitemap_path, @js.any(buf.to_string())) catch {
    _ => ()
  }
}

///|
/// Get default CSS styles
fn get_default_css(config : @astra.SsgConfig) -> String {
  let primary_color = config.theme.primary_color.unwrap_or("#3451b2")
  let css_rest =
    #|  --text-color: #213547;
    #|  --bg-color: #ffffff;
    #|  --sidebar-bg: #f6f6f7;
    #|  --border-color: #e2e2e3;
    #|  --code-bg: #f6f6f7;
    #|}
    #|
    #|/* Dark mode - controlled by .dark class on html */
    #|html.dark {
    #|  --text-color: #e5e7eb;
    #|  --bg-color: #1a1a1a;
    #|  --sidebar-bg: #242424;
    #|  --border-color: #3f3f3f;
    #|  --code-bg: #2d2d2d;
    #|}
    #|
    #|/* Theme toggle button */
    #|.theme-toggle {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 36px;
    #|  height: 36px;
    #|  padding: 0;
    #|  border: 1px solid var(--border-color);
    #|  border-radius: 6px;
    #|  background: transparent;
    #|  color: var(--text-color);
    #|  cursor: pointer;
    #|  transition: background 0.2s, border-color 0.2s;
    #|}
    #|.theme-toggle:hover {
    #|  background: var(--sidebar-bg);
    #|}
    #|
    #|/* Theme icons - moon in light mode, sun in dark mode */
    #|.theme-icon-dark { display: block; }
    #|.theme-icon-light { display: none; }
    #|html.dark .theme-icon-dark { display: none; }
    #|html.dark .theme-icon-light { display: block; }
    #|
    #|/* View Transition API (MPA) */
    #|@view-transition {
    #|  navigation: auto;
    #|}
    #|
    #|/* Disable root transition, only transition main content */
    #|::view-transition-old(root),
    #|::view-transition-new(root) {
    #|  animation: none;
    #|  mix-blend-mode: normal;
    #|}
    #|
    #|/* Main content transition */
    #|.doc-content {
    #|  view-transition-name: main-content;
    #|}
    #|
    #|::view-transition-old(main-content),
    #|::view-transition-new(main-content) {
    #|  animation-duration: 0.2s;
    #|  animation-timing-function: ease-out;
    #|}
    #|
    #|/* Direction-based animations */
    #|@keyframes slide-out-to-left {
    #|  from { transform: translateX(0); opacity: 1; }
    #|  to { transform: translateX(-5%); opacity: 0; }
    #|}
    #|@keyframes slide-in-from-right {
    #|  from { transform: translateX(5%); opacity: 0; }
    #|  to { transform: translateX(0); opacity: 1; }
    #|}
    #|@keyframes slide-out-to-right {
    #|  from { transform: translateX(0); opacity: 1; }
    #|  to { transform: translateX(5%); opacity: 0; }
    #|}
    #|@keyframes slide-in-from-left {
    #|  from { transform: translateX(-5%); opacity: 0; }
    #|  to { transform: translateX(0); opacity: 1; }
    #|}
    #|
    #|html:active-view-transition-type(forwards) {
    #|  &::view-transition-old(main-content) { animation-name: slide-out-to-right; }
    #|  &::view-transition-new(main-content) { animation-name: slide-in-from-left; }
    #|}
    #|html:active-view-transition-type(backwards) {
    #|  &::view-transition-old(main-content) { animation-name: slide-out-to-left; }
    #|  &::view-transition-new(main-content) { animation-name: slide-in-from-right; }
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
    #|/* Markdown body container */
    #|.markdown-body {
    #|  box-sizing: border-box;
    #|  min-width: 200px;
    #|  max-width: 980px;
    #|  margin: 0 auto;
    #|}
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
    #|  .doc-main { margin-left: 0; margin-right: 0; max-width: none; }
    #|}
  "/* Luna SSG Default Theme */\n:root {\n  --primary-color: \{primary_color};\n" +
  css_rest
}

///|
/// Get GitHub Markdown CSS (minimal subset)
fn get_github_markdown_css() -> String {
  let css =
    #|/* GitHub Markdown CSS - minimal subset for Astra */
    #|.markdown-body {
    #|  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
    #|  font-size: 16px;
    #|  line-height: 1.5;
    #|  word-wrap: break-word;
    #|}
    #|.markdown-body h1, .markdown-body h2 {
    #|  padding-bottom: 0.3em;
    #|  border-bottom: 1px solid var(--border-color, #d0d7de);
    #|}
    #|.markdown-body h1 { font-size: 2em; }
    #|.markdown-body h2 { font-size: 1.5em; }
    #|.markdown-body h3 { font-size: 1.25em; }
    #|.markdown-body h4 { font-size: 1em; }
    #|.markdown-body code {
    #|  padding: 0.2em 0.4em;
    #|  margin: 0;
    #|  font-size: 85%;
    #|  background-color: var(--code-bg, rgba(175, 184, 193, 0.2));
    #|  border-radius: 6px;
    #|  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
    #|}
    #|.markdown-body pre {
    #|  padding: 16px;
    #|  overflow: auto;
    #|  font-size: 85%;
    #|  line-height: 1.45;
    #|  background-color: var(--code-bg, #f6f8fa);
    #|  border-radius: 6px;
    #|}
    #|.markdown-body pre code {
    #|  padding: 0;
    #|  margin: 0;
    #|  background: transparent;
    #|  border: 0;
    #|  font-size: 100%;
    #|}
    #|.markdown-body blockquote {
    #|  padding: 0 1em;
    #|  color: #656d76;
    #|  border-left: 0.25em solid #d0d7de;
    #|}
    #|.markdown-body table {
    #|  border-spacing: 0;
    #|  border-collapse: collapse;
    #|  width: 100%;
    #|  overflow: auto;
    #|}
    #|.markdown-body td, .markdown-body th {
    #|  padding: 6px 13px;
    #|  border: 1px solid #d0d7de;
    #|}
    #|.markdown-body tr:nth-child(2n) {
    #|  background-color: var(--code-bg, #f6f8fa);
    #|}
    #|.markdown-body hr {
    #|  height: 0.25em;
    #|  padding: 0;
    #|  margin: 24px 0;
    #|  background-color: #d0d7de;
    #|  border: 0;
    #|}
    #|.markdown-body ul, .markdown-body ol {
    #|  padding-left: 2em;
    #|}
    #|.markdown-body li + li {
    #|  margin-top: 0.25em;
    #|}
    #|@media (prefers-color-scheme: dark) {
    #|  .markdown-body blockquote { color: #9198a1; border-left-color: #3d444d; }
    #|  .markdown-body td, .markdown-body th { border-color: #3d444d; }
    #|  .markdown-body hr { background-color: #3d444d; }
    #|}
  css
}

///|
/// Get loader.js for island hydration (IIFE format)
fn get_loader_js() -> String {
  let js =
    #|(function(){function setupTrigger(e,t,n){if(t==="load")document.readyState==="loading"?document.addEventListener("DOMContentLoaded",()=>n(),{once:true}):n();else if(t==="idle")requestIdleCallback(()=>n());else if(t[0]==="v")new IntersectionObserver((r,o)=>{r.some(i=>i.isIntersecting)&&(o.disconnect(),n())},{rootMargin:"50px"}).observe(e);else if(t[0]==="m"){const r=matchMedia(t.slice(6)),o=()=>{r.matches&&(r.removeEventListener("change",o),n())};r.matches?n():r.addEventListener("change",o)}}function onReady(e){document.readyState==="loading"?document.addEventListener("DOMContentLoaded",e,{once:true}):e()}function observeAdditions(e,t){new MutationObserver(n=>n.forEach(r=>r.addedNodes.forEach(o=>{o.nodeType===1&&e(o)&&t(o)}))).observe(document.body??document.documentElement,{childList:true,subtree:true})}function createLoadedTracker(){const e=new Set;return{loaded:e,unload:t=>e.delete(t),clear:()=>e.clear()}}const d=document,w=window,S={},{loaded,unload,clear}=createLoadedTracker(),parseState=async e=>{const t=e.getAttribute("luna:state");if(t){if(t[0]==="#")return JSON.parse(d.getElementById(t.slice(1))?.textContent??"null");try{return JSON.parse(t)}catch{}}},hydrate=async e=>{const t=e.getAttribute("luna:id");if(!t||loaded.has(t))return;loaded.add(t);const n=e.getAttribute("luna:url");if(!n)return;S[t]=await parseState(e);const r=await import(n),o=e.getAttribute("luna:export");(o?r[o]:r.hydrate??r.default)?.(e,S[t],t)},setup=e=>{setupTrigger(e,e.getAttribute("luna:trigger")??"load",()=>hydrate(e))},scan=()=>{d.querySelectorAll("[luna\\:id]").forEach(setup)};d.querySelectorAll('script[type="luna/json"]').forEach(e=>{e.id&&(S[e.id]=JSON.parse(e.textContent??"{}"))});onReady(scan);observeAdditions(e=>e.hasAttribute("luna:id"),setup);const unloadAll=(e=d.body)=>{e.querySelectorAll("[luna\\:id]").forEach(t=>{const n=t.getAttribute("luna:id");n&&loaded.delete(n)})};w.__LUNA_STATE__=S;w.__LUNA_HYDRATE__=hydrate;w.__LUNA_SCAN__=scan;w.__LUNA_UNLOAD__=unload;w.__LUNA_UNLOAD_ALL__=unloadAll;w.__LUNA_CLEAR_LOADED__=clear})();
  js
}
