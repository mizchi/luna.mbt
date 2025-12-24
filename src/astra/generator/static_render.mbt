// Static Site Generator - Main Render Pipeline

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

///|
/// Extract component name from source path
/// e.g., "counter" from "counter/" or "my-component" from "my-component/"
fn get_component_name_from_path(source_path : String) -> String {
  // Remove trailing slash if present
  let path = if source_path.has_suffix("/") {
    let len = source_path.length()
    let buf = StringBuilder::new()
    let mut idx = 0
    for c in source_path {
      if idx < len - 1 {
        buf.write_char(c)
      }
      idx = idx + 1
    }
    buf.to_string()
  } else {
    source_path
  }

  // Get last segment of path
  let mut last_slash = -1
  let mut idx = 0
  for c in path {
    if c == '/' {
      last_slash = idx
    }
    idx = idx + 1
  }
  if last_slash >= 0 && last_slash < path.length() - 1 {
    path.substring(start=last_slash + 1)
  } else {
    path
  }
}

///|
/// Simple CSS minification - removes excessive whitespace
fn minify_css(css : String) -> String {
  // Simple whitespace normalization using string operations
  css
  .replace(old="\n", new=" ")
  .replace(old="\r", new="")
  .replace(old="\t", new=" ")
  .replace(old="  ", new=" ")
  .replace(old="  ", new=" ")
  .replace(old="  ", new=" ")
  .replace(old=" {", new="{")
  .replace(old="{ ", new="{")
  .replace(old=" }", new="}")
  .replace(old="} ", new="}")
  .replace(old=" :", new=":")
  .replace(old=": ", new=":")
  .replace(old=" ;", new=";")
  .replace(old="; ", new=";")
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
/// Generate a single page (for incremental builds in dev mode)
pub fn generate_single_page(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  highlighter : @shiki.Highlighter,
) -> Result[Unit, String] {
  generate_page_with_highlight(ctx, page, Some(highlighter))
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
    trailing_slash=config.trailing_slash,
  )
  if pages.is_empty() {
    return Err("No markdown files found in \{config.docs_dir}")
  }
  println("Found \{pages.length()} pages")

  // Step 1.5: Check for duplicate pages (e.g., index.md and index.html)
  let duplicates = @routes.check_duplicate_pages(pages)
  if not(duplicates.is_empty()) {
    let errors = duplicates.map(@routes.format_duplicate_error)
    return Err("Duplicate pages detected:\n" + errors.join("\n"))
  }

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

  // Step 7: Build DocumentTree and generate meta files (sitemap, RSS, llms.txt)
  let doc_tree = @tree.build_document_tree(config, pages, cwd)
  generate_meta_files(ctx, doc_tree)

  // Step 8: Generate 404 page
  generate_404_page(ctx)

  // Step 9: Generate client manifest for chunk loading
  generate_client_manifest(ctx)

  // Step 10: Generate Cloudflare _routes.json (if deploy target is Cloudflare)
  write_routes_json(ctx)
  Ok(())
}

///|
/// Generate single page with optional syntax highlighting
fn generate_page_with_highlight(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  highlighter : @shiki.Highlighter?,
) -> Result[Unit, String] {
  // Build full source path
  let source_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    page.source_path,
  )

  // Process based on content type
  // Component type doesn't need file reading (it's a directory)
  let (frontmatter, content_vnode, toc) = match page.content_type {
    @astra.Component => {
      // Component pages - generate placeholder for now
      // TODO: Implement actual SSR rendering
      let component_name = get_component_name_from_path(page.source_path)
      let placeholder_html = "<div data-component=\"\{component_name}\" class=\"component-placeholder\"><p>Component: \{component_name}</p><p>SSR rendering not yet implemented for this component.</p></div>"
      let vnode = @luna.raw_html(placeholder_html)
      (page.frontmatter, vnode, [])
    }
    @astra.Markdown => {
      // Read source file
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // Parse markdown
      let (parsed_frontmatter, nodes) = @markdown.parse_markdown(content)

      // Auto-generate description from first paragraph if not provided
      let fm = if parsed_frontmatter.description is None {
        match @markdown.extract_description(nodes) {
          Some(desc) => { ..parsed_frontmatter, description: Some(desc) }
          None => parsed_frontmatter
        }
      } else {
        parsed_frontmatter
      }

      // Get islands base path from config
      let islands_base_path = match ctx.config.islands {
        Some(islands_config) => islands_config.base_path
        None => "/static/"
      }

      // Convert to VNode with link resolution
      // Index pages use standard browser behavior, content pages use sibling behavior
      let is_index = page.source_path.has_suffix("index.md")
      let vnode = @markdown.md_nodes_to_vnode(
        nodes,
        islands_base_path~,
        current_url_path=page.url_path,
        is_index~,
      )

      // Extract TOC
      let extracted_toc = @markdown.extract_toc(nodes)
      (fm, vnode, extracted_toc)
    }
    @astra.Html => {
      // Read source file
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // For HTML files, use the content as raw HTML
      // Optionally sanitize if configured
      let html_content = if ctx.config.sanitize_html {
        sanitize_html(content)
      } else {
        content
      }
      // Wrap raw HTML in a fragment
      let vnode = @luna.raw_html(html_content)
      // Use page frontmatter (from file_router, which is default for HTML)
      // No TOC for HTML files
      (page.frontmatter, vnode, [])
    }
  }

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
    @luna.fragment([])
  }

  // Mobile sidebar dropdown
  let mobile_sidebar = if frontmatter.sidebar {
    @routes.render_mobile_sidebar(sidebar_groups, page.url_path)
  } else {
    @luna.fragment([])
  }

  // Breadcrumb
  let breadcrumb = build_breadcrumb(ctx, page)

  // Main content
  let article = h("article", [attr("class", "doc-content markdown-body")], [
    content,
  ])

  // TOC (outline)
  let toc_vnode = if not(toc.is_empty()) {
    build_toc(toc)
  } else {
    @luna.fragment([])
  }

  // Prev/Next navigation
  let prev_next = build_prev_next(ctx, page)
  let main = h("main", [attr("class", "doc-main")], [
    mobile_sidebar, breadcrumb, article, prev_next,
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
      h("span", [attr("class", "nav-title")], [@luna.text(ctx.config.title)])
  }
  let home_link = h(
    "a",
    [attr("href", ctx.config.base_url), attr("class", "nav-home")],
    [logo],
  )

  // Nav items
  let nav_items = ctx.config.nav.map(item => build_nav_item(item))

  // Language switcher
  let lang_switcher = build_language_switcher(ctx, page)

  // Theme toggle button
  let theme_toggle = build_theme_toggle()

  // Social links (GitHub, etc.)
  let social_links = build_social_links(ctx.config.theme.social_links)

  // Combine nav links, language switcher, social links, and theme toggle
  let nav_children : Array[@luna.Node[Unit]] = nav_items.copy()
  nav_children.push(lang_switcher)
  nav_children.push(social_links)
  nav_children.push(theme_toggle)
  let nav_links = h("div", [attr("class", "nav-links")], nav_children)
  h("header", [attr("class", "nav-bar")], [
    h("div", [attr("class", "nav-container")], [home_link, nav_links]),
  ])
}

///|
/// Build social links (GitHub, Twitter, etc.)
fn build_social_links(links : Array[@astra.SocialLink]) -> @luna.Node[Unit] {
  if links.is_empty() {
    return @luna.fragment([])
  }
  let link_nodes = links.map(link => {
    let icon = build_social_icon(link.icon)
    h(
      "a",
      [
        attr("href", link.link),
        attr("class", "social-link"),
        attr("target", "_blank"),
        attr("rel", "noopener noreferrer"),
        attr("aria-label", link.icon),
      ],
      [icon],
    )
  })
  h("div", [attr("class", "social-links")], link_nodes)
}

///|
/// Build SVG icon element for social platform
fn build_social_icon(icon : String) -> @luna.Node[Unit] {
  let path_d = match icon {
    "github" =>
      "M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"
    "twitter" | "x" =>
      "M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
    _ => ""
  }
  if path_d.is_empty() {
    return @luna.fragment([])
  }
  h(
    "svg",
    [
      attr("viewBox", "0 0 24 24"),
      attr("width", "20"),
      attr("height", "20"),
      attr("fill", "currentColor"),
    ],
    [h("path", [attr("d", path_d)], [])],
  )
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
    return @luna.fragment([])
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
    .find_first(l => l.code == page.locale)
    .map(l => l.label)
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
        @luna.text(locale.label),
      ]),
    )
  }

  // Build dropdown with details/summary
  let summary = h("summary", [attr("class", "lang-trigger")], [
    @luna.text(current_label),
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
      h("circle", [attr("cx", "12"), attr("cy", "12"), attr("r", "5")], []),
      h(
        "path",
        [
          attr(
            "d", "M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42",
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
      @luna.text(item.text),
    ])
  } else {
    // Dropdown (simplified - actual dropdown needs JS)
    let dropdown_items = item.items.map(fn(sub) {
      h("a", [attr("href", sub.link), attr("class", "nav-dropdown-item")], [
        @luna.text(sub.text),
      ])
    })
    h("div", [attr("class", "nav-dropdown")], [
      h("span", [attr("class", "nav-dropdown-trigger")], [@luna.text(item.text)]),
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
      h("a", [attr("href", "#" + item.id)], [@luna.text(item.text)]),
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
    @luna.text("On this page"),
  ])
  let content = h("div", [attr("class", "toc-content")], [
    title,
    h("ul", [attr("class", "toc-list")], items),
  ])
  h("aside", [attr("class", "toc")], [content, collapse_btn])
}

///|
/// Slice string from start to end (for breadcrumb)
fn bc_slice(s : String, start : Int, end : Int) -> String {
  let arr = s.to_array()
  let chars : Array[Char] = []
  for i = start; i < end && i < arr.length(); i = i + 1 {
    chars.push(arr[i])
  }
  String::from_array(chars)
}

///|
/// Slice string from start to end (for breadcrumb)
fn bc_slice_from(s : String, start : Int) -> String {
  let arr = s.to_array()
  let chars : Array[Char] = []
  for i = start; i < arr.length(); i = i + 1 {
    chars.push(arr[i])
  }
  String::from_array(chars)
}

///|
/// Build breadcrumb navigation
fn build_breadcrumb(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  // Parse URL path into segments
  let path = page.url_path.trim_start(chars="/").trim_end(chars="/").to_string()
  if path.is_empty() {
    return @luna.fragment([])
  }

  // Split path into segments
  let segments : Array[String] = []
  let chars = path.to_array()
  let mut start = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      if i > start {
        segments.push(bc_slice(path, start, i))
      }
      start = i + 1
    }
  }
  if start < chars.length() {
    segments.push(bc_slice_from(path, start))
  }
  if segments.is_empty() {
    return @luna.fragment([])
  }

  // Build breadcrumb items
  let items : Array[@luna.Node[Unit]] = []
  let mut current_path = ""
  for i = 0; i < segments.length(); i = i + 1 {
    let segment = segments[i]
    current_path = current_path + "/" + segment

    // Find page title for this path
    let title = find_page_title(ctx.pages, current_path + "/", page.locale).unwrap_or(
      capitalize_segment(segment),
    )

    // Add separator (except for first item)
    if i > 0 {
      items.push(
        h("span", [attr("class", "breadcrumb-separator")], [@luna.text("/")]),
      )
    }

    // Last item is current page (no link)
    if i == segments.length() - 1 {
      items.push(
        h("span", [attr("class", "breadcrumb-current")], [@luna.text(title)]),
      )
    } else {
      items.push(
        h(
          "a",
          [attr("href", current_path + "/"), attr("class", "breadcrumb-link")],
          [@luna.text(title)],
        ),
      )
    }
  }
  h("nav", [attr("class", "breadcrumb")], items)
}

///|
/// Find page title by URL path
fn find_page_title(
  pages : Array[@astra.PageMeta],
  url_path : String,
  locale : String,
) -> String? {
  for page in pages {
    if page.url_path == url_path && page.locale == locale {
      return page.frontmatter.title
    }
  }
  None
}

///|
/// Capitalize first letter
fn capitalize(s : String) -> String {
  if s.is_empty() {
    return s
  }
  let chars = s.to_array()
  let first = chars[0]
  if first >= 'a' && first <= 'z' {
    chars[0] = Int::unsafe_to_char(first.to_int() - 32)
  }
  String::from_array(chars)
}

///|
/// Capitalize segment for display (remove numbers prefix, replace dashes)
fn capitalize_segment(segment : String) -> String {
  // Remove leading number prefix (e.g., "01_" or "01-")
  let mut s = segment
  let chars = s.to_array()
  let mut skip = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] >= '0' && chars[i] <= '9' {
      skip = i + 1
    } else if (chars[i] == '_' || chars[i] == '-') && skip == i {
      skip = i + 1
      break
    } else {
      break
    }
  }
  if skip > 0 && skip < chars.length() {
    s = bc_slice_from(s, skip)
  }

  // Replace dashes/underscores with spaces and capitalize
  let result = s.replace(old="-", new=" ").replace(old="_", new=" ")
  capitalize(result)
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
  if prev is Some(link) {
    children.push(
      h("a", [attr("href", link.link), attr("class", "prev-link")], [
        h("span", [attr("class", "label")], [@luna.text("Previous")]),
        h("span", [attr("class", "title")], [@luna.text(link.text)]),
      ]),
    )
  }
  if next is Some(link) {
    children.push(
      h("a", [attr("href", link.link), attr("class", "next-link")], [
        h("span", [attr("class", "label")], [@luna.text("Next")]),
        h("span", [attr("class", "title")], [@luna.text(link.text)]),
      ]),
    )
  }
  h("nav", [attr("class", "prev-next")], children)
}

///|
/// Build footer
fn build_footer(ctx : @astra.BuildContext) -> @luna.Node[Unit] {
  match ctx.config.theme.footer {
    Some(footer_config) => {
      let children : Array[@luna.Node[Unit]] = []

      // Render link columns if present
      if not(footer_config.links.is_empty()) {
        let columns = footer_config.links.map(fn(col) {
          let links = col.items.map(fn(link) {
            h("li", [], [
              h("a", [attr("href", link.href), attr("class", "footer-link")], [
                @luna.text(link.label),
              ]),
            ])
          })
          h("div", [attr("class", "footer-column")], [
            h("h3", [attr("class", "footer-column-title")], [
              @luna.text(col.title),
            ]),
            h("ul", [attr("class", "footer-links")], links),
          ])
        })
        children.push(h("div", [attr("class", "footer-columns")], columns))
      }

      // Bottom section with message and copyright
      let bottom_items : Array[@luna.Node[Unit]] = []
      if footer_config.message is Some(msg) {
        bottom_items.push(
          h("p", [attr("class", "footer-message")], [@luna.text(msg)]),
        )
      }
      if footer_config.copyright is Some(copyright) {
        bottom_items.push(
          h("p", [attr("class", "footer-copyright")], [@luna.text(copyright)]),
        )
      }
      if not(bottom_items.is_empty()) {
        children.push(h("div", [attr("class", "footer-bottom")], bottom_items))
      }
      h("footer", [attr("class", "site-footer")], children)
    }
    None => @luna.fragment([])
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
  let desc_tag = if desc.is_empty() {
    ""
  } else {
    "\n  <meta name=\"description\" content=\"\{desc}\">"
  }
  let base = ctx.config.base_url

  // Generate preload tags for islands
  let preloads = if render_result.preload_urls.length() > 0 {
    @render.generate_preload_tags(render_result.preload_urls)
  } else {
    ""
  }

  // Generate prefetch tags for prev/next pages
  let prefetch_tags = {
    let tags = StringBuilder::new()
    let prev = @routes.find_prev_page(ctx.pages, page.url_path)
    let next = @routes.find_next_page(ctx.pages, page.url_path)
    if prev is Some(link) {
      tags.write_string("\n  <link rel=\"prefetch\" href=\"\{link.link}\">")
    }
    if next is Some(link) {
      tags.write_string("\n  <link rel=\"prefetch\" href=\"\{link.link}\">")
    }
    tags.to_string()
  }

  // Primary color CSS variable
  let primary = ctx.config.theme.primary_color.unwrap_or("#3451b2")

  // Combine all CSS into inline style (eliminates render-blocking external CSS)
  let main_css = @assets.get_default_css(ctx.config)
  let markdown_css = @assets.get_github_markdown_css()
  let shiki_css = @shiki.generate_shiki_css()
  let combined_css = minify_css(
    main_css + "\n" + markdown_css + "\n" + shiki_css,
  )

  // Get page order for current locale
  let page_order = get_page_order(ctx.pages, page.locale)

  // Navigation script for SPA/View Transitions
  let nav_script = get_navigation_script(page_order, ctx.config.navigation)

  // Theme initialization script (runs early to prevent flash)
  let theme_script = @assets.get_theme_script()

  // Sidebar state script
  let sidebar_script = @assets.get_sidebar_script()

  // TOC scroll spy script
  let toc_script = @assets.get_toc_script()

  // Web Components loader script
  let wc_loader_script = @assets.get_wc_loader_script()

  // Generate OGP meta tags
  let ogp_tags = build_ogp_meta_tags(ctx, page, frontmatter)

  // Custom OGP text (added after generated OGP tags)
  let ogp_text = match ctx.config.ogp_text {
    Some(text) => "\n  " + text
    None => ""
  }

  // Custom HTML snippets
  let head_snippets = if ctx.config.head_snippets.length() > 0 {
    "\n  " + ctx.config.head_snippets.join("\n  ")
  } else {
    ""
  }
  let body_snippets = if ctx.config.body_snippets.length() > 0 {
    "\n  " + ctx.config.body_snippets.join("\n  ")
  } else {
    ""
  }
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>\{page_title}</title>\{desc_tag}\{ogp_tags}\{ogp_text}\n  <link rel=\"preload\" href=\"\{base}assets/loader.js\" as=\"script\">\n  <script>\{theme_script}</script>\n  <style>\{combined_css}:root{--primary-color:\{primary};}</style>\n  \{preloads}\{prefetch_tags}\{head_snippets}\n</head>\n<body>\n  <div id=\"app\">\{render_result.html}</div>\n  <script type=\"module\" async src=\"\{base}assets/loader.js\"></script>\n  \{wc_loader_script}\n  \{nav_script}\n  \{sidebar_script}\n  \{toc_script}\{body_snippets}\n</body>\n</html>"
}

///|
/// Build OGP (Open Graph Protocol) meta tags
fn build_ogp_meta_tags(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
) -> String {
  let ogp = ctx.config.ogp
  let tags = StringBuilder::new()

  // Get title and description
  let title = frontmatter.title.unwrap_or(ctx.config.title)
  let desc = frontmatter.description.unwrap_or("")

  // og:title (always include)
  tags.write_string("\n  <meta property=\"og:title\" content=\"\{title}\">")

  // og:description
  if not(desc.is_empty()) {
    tags.write_string(
      "\n  <meta property=\"og:description\" content=\"\{desc}\">",
    )
  }

  // og:type (article for docs, website for home)
  let og_type = frontmatter.og_type.unwrap_or("article")
  tags.write_string("\n  <meta property=\"og:type\" content=\"\{og_type}\">")

  // og:url (requires site_url config)
  match ogp.site_url {
    Some(site_url) => {
      let url = "\{site_url}\{page.url_path}"
      tags.write_string("\n  <meta property=\"og:url\" content=\"\{url}\">")
    }
    None => ()
  }

  // og:image (frontmatter overrides config default)
  let image : String? = match frontmatter.image {
    Some(img) => Some(img)
    None => ogp.image
  }
  match image {
    Some(img) => {
      // Make absolute URL if site_url is configured
      let img_url = match ogp.site_url {
        Some(site_url) =>
          if img.has_prefix("http://") || img.has_prefix("https://") {
            img
          } else if img.has_prefix("/") {
            "\{site_url}\{img}"
          } else {
            "\{site_url}/\{img}"
          }
        None => img
      }
      tags.write_string(
        "\n  <meta property=\"og:image\" content=\"\{img_url}\">",
      )
    }
    None => ()
  }

  // og:site_name
  tags.write_string(
    "\n  <meta property=\"og:site_name\" content=\"\{ctx.config.title}\">",
  )

  // Twitter Card meta tags
  let twitter_card = match frontmatter.twitter_card {
    Some(tc) => tc
    None =>
      match ogp.twitter_card {
        Some(tc) => tc
        None => "summary"
      }
  }
  tags.write_string(
    "\n  <meta name=\"twitter:card\" content=\"\{twitter_card}\">",
  )
  tags.write_string("\n  <meta name=\"twitter:title\" content=\"\{title}\">")
  if not(desc.is_empty()) {
    tags.write_string(
      "\n  <meta name=\"twitter:description\" content=\"\{desc}\">",
    )
  }

  // Twitter image (same as og:image)
  match image {
    Some(img) => {
      let img_url = match ogp.site_url {
        Some(site_url) =>
          if img.has_prefix("http://") || img.has_prefix("https://") {
            img
          } else if img.has_prefix("/") {
            "\{site_url}\{img}"
          } else {
            "\{site_url}/\{img}"
          }
        None => img
      }
      tags.write_string(
        "\n  <meta name=\"twitter:image\" content=\"\{img_url}\">",
      )
    }
    None => ()
  }

  // Twitter site handle
  match ogp.twitter_handle {
    Some(handle) =>
      tags.write_string(
        "\n  <meta name=\"twitter:site\" content=\"\{handle}\">",
      )
    None => ()
  }
  tags.to_string()
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
/// Get inline script for navigation (SPA / View Transitions / Keyboard)
fn get_navigation_script(
  page_order : Array[String],
  config : @astra.NavigationConfig,
) -> String {
  // If all navigation features are disabled, return empty
  if not(config.spa) && not(config.view_transitions) && not(config.keyboard) {
    return ""
  }
  // Build JSON array of page URLs
  let urls_json = page_order.map(fn(url) { "\"\{url}\"" }).join(", ")

  // Generate script parts based on config
  let parts : Array[String] = []

  // Common utilities
  let page_order_start =
    #|const pageOrder = [
  parts.push(page_order_start)
  parts.push(urls_json)
  let page_order_end =
    #|];
    #|function getPageIndex(url) {
    #|  if (!url) return -1;
    #|  const path = new URL(url).pathname.replace(/\/$/, '') || '/';
    #|  return pageOrder.findIndex(p => p.replace(/\/$/, '') === path || p === path + '/');
    #|}
    #|function isHomePage(url) {
    #|  const path = new URL(url, location.origin).pathname;
    #|  return path === '/' || path === '/ja/' || path === '/en/';
    #|}
  parts.push(page_order_end)

  // SPA navigation
  if config.spa {
    let spa_script =
      #|let currentAbortController = null;
      #|let lastPathname = location.pathname;
      #|function scrollToHash(hash) {
      #|  if (!hash) return;
      #|  const id = hash.startsWith('#') ? hash.slice(1) : hash;
      #|  const el = document.getElementById(id);
      #|  if (el) el.scrollIntoView({ behavior: 'instant', block: 'start' });
      #|}
      #|function closeAccordion(details) {
      #|  if (!details.open) return Promise.resolve();
      #|  details.classList.add('closing');
      #|  return new Promise(r => {
      #|    const done = () => { details.open = false; details.classList.remove('closing'); r(); };
      #|    details.querySelector('.sidebar-items')?.addEventListener('transitionend', done, { once: true });
      #|    setTimeout(done, 220);
      #|  });
      #|}
      #|async function spaNavigate(url, pushState = true) {
      #|  // Abort any pending navigation
      #|  if (currentAbortController) currentAbortController.abort();
      #|  currentAbortController = new AbortController();
      #|  const urlObj = new URL(url, location.origin);
      #|  const hash = urlObj.hash;
      #|  // Save sidebar scroll position before navigation
      #|  const sidebar = document.querySelector('.sidebar-content');
      #|  const sidebarScrollTop = sidebar ? sidebar.scrollTop : 0;
      #|  // Close non-target accordions with animation before fetching
      #|  const targetPath = urlObj.pathname;
      #|  const openDetails = document.querySelectorAll('.sidebar-collapse[open]');
      #|  const closePromises = [];
      #|  openDetails.forEach(d => {
      #|    const link = d.querySelector('.sidebar-group-link');
      #|    if (link && !targetPath.startsWith(link.getAttribute('href')?.replace(/\/$/, '') || '###')) {
      #|      closePromises.push(closeAccordion(d));
      #|    }
      #|  });
      #|  try {
      #|    // Fetch in parallel with close animation
      #|    const [res] = await Promise.all([fetch(url, { signal: currentAbortController.signal }), ...closePromises]);
      #|    if (!res.ok) { location.href = url; return; }
      #|    const html = await res.text();
      #|    const parser = new DOMParser();
      #|    const doc = parser.parseFromString(html, 'text/html');
      #|    const newApp = doc.getElementById('app');
      #|    const newTitle = doc.querySelector('title')?.textContent;
      #|    if (!newApp) { location.href = url; return; }
      #|    // Update DOM
      #|    document.getElementById('app').innerHTML = newApp.innerHTML;
      #|    if (newTitle) document.title = newTitle;
      #|    if (pushState) history.pushState({}, '', url);
      #|    lastPathname = urlObj.pathname;
      #|    // Restore sidebar scroll position
      #|    const newSidebar = document.querySelector('.sidebar-content');
      #|    if (newSidebar) newSidebar.scrollTop = sidebarScrollTop;
      #|    // Scroll: to hash target or top
      #|    if (hash) { scrollToHash(hash); } else { window.scrollTo({ top: 0, behavior: 'instant' }); }
      #|    // Re-run loader for new islands
      #|    if (window.__LUNA_CLEAR_LOADED__) window.__LUNA_CLEAR_LOADED__();
      #|    if (window.__LUNA_SCAN__) window.__LUNA_SCAN__();
      #|    // Re-run Web Components loader
      #|    if (window.__LUNA_WC_CLEAR_LOADED__) window.__LUNA_WC_CLEAR_LOADED__();
      #|    if (window.__LUNA_WC_SCAN__) window.__LUNA_WC_SCAN__();
      #|    // Re-init TOC scroll spy
      #|    if (window.__ASTRA_INIT_TOC_SPY__) window.__ASTRA_INIT_TOC_SPY__();
      #|  } catch (e) {
      #|    if (e.name !== 'AbortError') location.href = url;
      #|  }
      #|}
      #|function navigateTo(url) {
      #|  // Skip SPA for home page transitions
      #|  if (isHomePage(url) || isHomePage(location.href)) {
      #|    window.scrollTo({ top: 0, behavior: 'instant' });
      #|    location.href = url;
      #|    return;
      #|  }
      #|  spaNavigate(url);
      #|}
      #|// Handle sidebar chevron clicks (toggle only, no navigation)
      #|document.addEventListener('click', (e) => {
      #|  const chevron = e.target.closest('.sidebar-chevron');
      #|  if (!chevron) return;
      #|  e.preventDefault();
      #|  e.stopPropagation();
      #|  const details = chevron.closest('details');
      #|  if (!details) return;
      #|  if (details.open) { closeAccordion(details); } else { details.open = true; }
      #|});
      #|// Intercept link clicks
      #|document.addEventListener('click', (e) => {
      #|  const link = e.target.closest('a');
      #|  if (!link) return;
      #|  const href = link.getAttribute('href');
      #|  if (!href || href.startsWith('javascript:')) return;
      #|  // Handle hash-only links explicitly (TOC links)
      #|  if (href.startsWith('#')) {
      #|    e.preventDefault();
      #|    const hash = href;
      #|    history.pushState({}, '', location.pathname + hash);
      #|    scrollToHash(hash);
      #|    return;
      #|  }
      #|  if (link.target === '_blank' || link.hasAttribute('download')) return;
      #|  const url = new URL(href, location.origin);
      #|  if (url.origin !== location.origin) return;
      #|  // Same page with hash - scroll to hash
      #|  if (url.pathname === location.pathname && url.hash) {
      #|    e.preventDefault();
      #|    history.pushState({}, '', url.pathname + url.hash);
      #|    scrollToHash(url.hash);
      #|    return;
      #|  }
      #|  // Skip if same page without hash (prevent default to avoid scroll jump)
      #|  if (url.pathname === location.pathname) { e.preventDefault(); return; }
      #|  // Skip SPA for home page
      #|  if (isHomePage(url.href) || isHomePage(location.href)) return;
      #|  e.preventDefault();
      #|  spaNavigate(url.href);
      #|});
      #|// Handle back/forward
      #|window.addEventListener('popstate', () => {
      #|  if (isHomePage(location.href)) {
      #|    location.reload();
      #|    return;
      #|  }
      #|  // If only hash changed (same page), just scroll
      #|  if (location.pathname === lastPathname && location.hash) {
      #|    scrollToHash(location.hash);
      #|    return;
      #|  }
      #|  lastPathname = location.pathname;
      #|  spaNavigate(location.href, false);
      #|});
      #|// Hover prefetch for internal links
      #|const prefetched = new Set();
      #|function prefetchUrl(url) {
      #|  if (prefetched.has(url)) return;
      #|  prefetched.add(url);
      #|  const link = document.createElement('link');
      #|  link.rel = 'prefetch';
      #|  link.href = url;
      #|  document.head.appendChild(link);
      #|}
      #|document.addEventListener('mouseover', (e) => {
      #|  const anchor = e.target.closest('a');
      #|  if (!anchor) return;
      #|  const href = anchor.getAttribute('href');
      #|  if (!href || href.startsWith('#') || href.startsWith('javascript:')) return;
      #|  if (anchor.target === '_blank' || anchor.hasAttribute('download')) return;
      #|  try {
      #|    const url = new URL(href, location.origin);
      #|    if (url.origin !== location.origin) return;
      #|    if (url.pathname === location.pathname) return;
      #|    prefetchUrl(url.href);
      #|  } catch {}
      #|}, { passive: true });
    parts.push(spa_script)
  } else {
    // Non-SPA navigation (full page reload)
    let non_spa_script =
      #|function navigateTo(url) {
      #|  window.scrollTo({ top: 0, behavior: 'instant' });
      #|  location.href = url;
      #|}
    parts.push(non_spa_script)
  }

  // View Transitions API
  if config.view_transitions {
    let view_transitions_script =
      #|window.addEventListener('pagereveal', (e) => {
      #|  if (!e.viewTransition || !navigation.activation) return;
      #|  const nav = navigation.activation;
      #|  const fromIdx = getPageIndex(nav.from?.url);
      #|  const toIdx = getPageIndex(nav.entry?.url);
      #|  if (fromIdx !== -1 && toIdx !== -1) {
      #|    e.viewTransition.types.add(toIdx > fromIdx ? 'forwards' : 'backwards');
      #|  } else {
      #|    e.viewTransition.types.add('forwards');
      #|  }
      #|});
    parts.push(view_transitions_script)
  }

  // Keyboard navigation
  if config.keyboard {
    let keyboard_script =
      #|document.addEventListener('keydown', (e) => {
      #|  if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
      #|  const idx = getPageIndex(location.href);
      #|  if (idx === -1) return;
      #|  if (e.key === 'ArrowRight' && idx < pageOrder.length - 1) {
      #|    e.preventDefault();
      #|    navigateTo(pageOrder[idx + 1]);
      #|  } else if (e.key === 'ArrowLeft' && idx > 0) {
      #|    const prevPage = pageOrder[idx - 1];
      #|    if (isHomePage(prevPage)) return;
      #|    e.preventDefault();
      #|    navigateTo(prevPage);
      #|  }
      #|});
    parts.push(keyboard_script)
  }
  let script_body = parts.join("\n")
  "<script>\n(function() {\n\{script_body}\n})();\n</script>"
}

// =============================================================================
// HTML Sanitization
// =============================================================================

///|
/// Sanitize HTML by removing potentially dangerous tags
/// Removes: <script>, <iframe>, <object>, <embed>, <form>, on* event handlers
fn sanitize_html(html : String) -> String {
  sanitize_html_js(html)
}

///|
/// JavaScript implementation of HTML sanitization
extern "js" fn sanitize_html_js(html : String) -> String =
  #| (html) => {
  #|   // Remove script tags and their content
  #|   let result = html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  #|   // Remove iframe, object, embed tags
  #|   result = result.replace(/<iframe\b[^>]*>.*?<\/iframe>/gi, '');
  #|   result = result.replace(/<object\b[^>]*>.*?<\/object>/gi, '');
  #|   result = result.replace(/<embed\b[^>]*\/?>/gi, '');
  #|   // Remove form tags (keep content)
  #|   result = result.replace(/<\/?form\b[^>]*>/gi, '');
  #|   // Remove on* event handlers from all tags
  #|   result = result.replace(/\s+on\w+\s*=\s*["'][^"']*["']/gi, '');
  #|   result = result.replace(/\s+on\w+\s*=\s*[^\s>]+/gi, '');
  #|   // Remove javascript: URLs
  #|   result = result.replace(/\bhref\s*=\s*["']javascript:[^"']*["']/gi, 'href="#"');
  #|   result = result.replace(/\bsrc\s*=\s*["']javascript:[^"']*["']/gi, 'src=""');
  #|   return result;
  #| }

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
/// Copy static assets to output directory
pub fn copy_static_assets(ctx : @astra.BuildContext) -> Unit {
  let output_assets = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "assets",
  )
  ensure_dir(output_assets)

  // Write default CSS
  let css = @assets.get_default_css(ctx.config)
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
  let github_md_css = @assets.get_github_markdown_css()
  let github_md_css_path = @path.join2(output_assets, "github-markdown.css")
  @fs.writeFileSync(github_md_css_path, @js.any(github_md_css)) catch {
    _ => ()
  }

  // Write loader.js (for island hydration)
  let loader_js = @assets.get_island_loader_js()
  let loader_js_path = @path.join2(output_assets, "loader.js")
  @fs.writeFileSync(loader_js_path, @js.any(loader_js)) catch {
    _ => ()
  }

  // Copy public directory if it exists
  copy_public_dir(ctx)

  // Copy islands directory if configured
  copy_islands_dir(ctx)

  // Copy boot runtime files to _luna/
  copy_boot_runtime(ctx)
}

///|
/// Copy boot runtime files to _luna/ directory
fn copy_boot_runtime(ctx : @astra.BuildContext) -> Unit {
  // Try to find boot files in various locations
  let possible_sources = [
    // Development: monorepo structure
    @path.join2(ctx.cwd, "js/loader/dist"),
    // NPM package: node_modules
    @path.join2(ctx.cwd, "node_modules/@luna_ui/luna-loader/dist"),
  ]

  // Find first existing source
  let mut boot_src : String? = None
  for src in possible_sources {
    let boot_file = @path.join2(src, "boot.iife.js")
    if @fs.existsSync(boot_file) {
      boot_src = Some(src)
      break
    }
  }

  // Skip if no boot files found
  guard boot_src is Some(src_dir) else { return }

  // Create _luna/ directory
  let luna_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_luna",
  )
  ensure_dir(luna_dir)

  // Copy boot.iife.js (self-contained boot runtime)
  let boot_src_file = @path.join2(src_dir, "boot.iife.js")
  let boot_dest_file = @path.join2(luna_dir, "boot.js")
  @fs.copyFileSync(boot_src_file, boot_dest_file) catch {
    e => {
      println("  Warning: Failed to copy boot.js: \{e}")
      return
    }
  }
  println("  Copied: /_luna/boot.js")

  // Optionally copy modular boot files for advanced usage
  let boot_dir = @path.join2(src_dir, "boot")
  if @fs.existsSync(boot_dir) {
    let luna_boot_dir = @path.join2(luna_dir, "boot")
    ensure_dir(luna_boot_dir)
    @fs.cpSync(boot_dir, luna_boot_dir, recursive=true) catch {
      _ => ()
    }
    println("  Copied: /_luna/boot/ (modular)")
  }
}

///|
/// Copy components directory to output (convention: docs/components -> /components/)
fn copy_islands_dir(ctx : @astra.BuildContext) -> Unit {
  // Use config if provided, otherwise use convention (docs/components)
  let (src_dir, base_path) = match ctx.config.islands {
    Some(islands_config) => (islands_config.dir, islands_config.base_path)
    None => {
      // Convention-based: look for docs/components
      let docs_components = @path.join2(ctx.config.docs_dir, "components")
      (docs_components, "/components/")
    }
  }
  let islands_src = @path.join2(ctx.cwd, src_dir)

  // Check if source directory exists
  if not(@fs.existsSync(islands_src)) {
    // Silently skip if using convention and directory doesn't exist
    return
  }

  // Output path: strip leading slash from base_path
  let output_subdir = if base_path.has_prefix("/") {
    base_path.unsafe_substring(start=1, end=base_path.length())
  } else {
    base_path
  }
  // Remove trailing slash for directory path
  let output_subdir_clean = if output_subdir.has_suffix("/") {
    output_subdir.unsafe_substring(start=0, end=output_subdir.length() - 1)
  } else {
    output_subdir
  }
  let islands_dest = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    output_subdir_clean,
  )

  // Ensure destination directory exists
  ensure_dir(islands_dest)

  // Copy components directory
  println("  Copying components from \{src_dir}...")
  @fs.cpSync(islands_src, islands_dest, recursive=true) catch {
    e => println("  Warning: Failed to copy components directory: \{e}")
  }
}

///|
/// Copy docs/public directory to output root
fn copy_public_dir(ctx : @astra.BuildContext) -> Unit {
  let public_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    "public",
  )
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)

  // Check if public directory exists
  if not(@fs.existsSync(public_dir)) {
    return
  }

  // Copy entire public directory contents to output
  println("  Copying public assets...")
  @fs.cpSync(public_dir, output_dir, recursive=true) catch {
    e => println("  Warning: Failed to copy public directory: \{e}")
  }
}

///|
/// Generate meta files (sitemap.xml, feed.xml, llms.txt) using DocumentTree
pub fn generate_meta_files(
  ctx : @astra.BuildContext,
  doc_tree : @ssg.DocumentTree,
) -> Unit {
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)

  // Generate sitemap.xml
  let sitemap_content = @tree.generate_sitemap(doc_tree)
  let sitemap_path = @path.join2(output_dir, "sitemap.xml")
  @fs.writeFileSync(sitemap_path, @js.any(sitemap_content)) catch {
    e => println("  Warning: Failed to generate sitemap.xml: \{e}")
  }
  println("  Generated: /sitemap.xml")

  // Generate feed.xml (RSS)
  let rss_content = @tree.generate_rss(doc_tree)
  let rss_path = @path.join2(output_dir, "feed.xml")
  @fs.writeFileSync(rss_path, @js.any(rss_content)) catch {
    e => println("  Warning: Failed to generate feed.xml: \{e}")
  }
  println("  Generated: /feed.xml")

  // Generate llms.txt
  let llms_content = @tree.generate_llms_txt(doc_tree)
  let llms_path = @path.join2(output_dir, "llms.txt")
  @fs.writeFileSync(llms_path, @js.any(llms_content)) catch {
    e => println("  Warning: Failed to generate llms.txt: \{e}")
  }
  println("  Generated: /llms.txt")
}

///|
/// Generate client manifest.json for chunk loading
/// This enables dynamic chunk loading in the client-side router
pub fn generate_client_manifest(ctx : @astra.BuildContext) -> Unit {
  // Convert PageMeta to RouteManifest
  let route_manifest = @routes.page_metas_to_manifest(ctx.pages, ctx.config)

  // Define chunk file mappings
  let chunk_files : Array[(String, String)] = [
    ("boot", "boot.js"),
    ("hydrate", "boot/index.js"),
    ("signal", "boot/loader.js"),
    ("router", "boot/router.js"),
  ]

  // Convert RouteManifest to ChunkManifest with chunk mappings
  let chunk_manifest = @core_routes.build_chunk_manifest(
    route_manifest,
    chunk_files~,
    base="/_luna/",
  )

  // Serialize to JSON
  let manifest_json = chunk_manifest.to_json()

  // Write to output directory
  let luna_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_luna",
  )
  ensure_dir(luna_dir)
  let manifest_path = @path.join2(luna_dir, "manifest.json")
  @fs.writeFileSync(manifest_path, @js.any(manifest_json)) catch {
    e => println("  Warning: Failed to generate manifest.json: \{e}")
  }
  println("  Generated: /_luna/manifest.json")
}

///|
/// Generate 404.html page
pub fn generate_404_page(ctx : @astra.BuildContext) -> Unit {
  let base = ctx.config.base_url
  let title = "Page Not Found"
  let site_title = ctx.config.title
  let primary = ctx.config.theme.primary_color.unwrap_or("#3451b2")
  let theme_script = @assets.get_theme_script()

  // Build 404 page content
  let content =
    #|<div style="display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; text-align: center; padding: 2rem;">
    #|  <h1 style="font-size: 6rem; margin: 0; color: var(--text-muted);">404</h1>
    #|  <h2 style="font-size: 1.5rem; margin: 1rem 0; color: var(--text-color);">Page Not Found</h2>
    #|  <p style="color: var(--text-muted); margin-bottom: 2rem;">The page you're looking for doesn't exist or has been moved.</p>
    #|  <a href="/" style="color: var(--primary-color); text-decoration: none; padding: 0.75rem 1.5rem; border: 1px solid var(--primary-color); border-radius: 0.5rem;">Go to Home</a>
    #|</div>
  let html =
    #|<!DOCTYPE html>
    #|<html lang="en">
    #|<head>
    #|  <meta charset="UTF-8">
    #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
    #|  <title>
  let html2 =
    #|</title>
    #|  <meta name="robots" content="noindex">
    #|  <script>
  let html3 =
    #|</script>
    #|  <link rel="stylesheet" href="
  let html4 =
    #|assets/style.css">
    #|  <style>:root { --primary-color:
  let html5 =
    #|; }</style>
    #|</head>
    #|<body>
    #|  <div id="app">
  let html6 =
    #|  </div>
    #|</body>
    #|</html>
  let full_html = html +
    title +
    " | " +
    site_title +
    html2 +
    theme_script +
    html3 +
    base +
    html4 +
    primary +
    html5 +
    content +
    html6
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "404.html",
  )
  @fs.writeFileSync(output_path, @js.any(full_html)) catch {
    e => println("  Warning: Failed to generate 404.html: \{e}")
  }
  println("  Generated: /404.html")
}
