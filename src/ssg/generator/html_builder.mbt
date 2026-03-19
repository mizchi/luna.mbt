// HTML Builder - Page layout building and HTML document generation

// =============================================================================
// Page HTML Building
// =============================================================================

///|
/// Build complete HTML page
fn build_page_html(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit, String],
  toc : Array[@markdown.TocItem],
) -> String {
  // Determine layout
  let layout = frontmatter.layout.unwrap_or("doc")

  // Build page VNode based on layout
  let page_vnode = match layout {
    "home" => build_home_layout(ctx, page, frontmatter, content)
    "default" => build_default_layout(ctx, page, frontmatter, content)
    "blog" => build_blog_layout(ctx, page, frontmatter, content)
    "blog-post" => build_blog_post_layout(ctx, page, frontmatter, content)
    _ => build_doc_layout(ctx, page, frontmatter, content, toc)
  }

  // Render to HTML string
  let result = @render.render_to_string(page_vnode, preload=true)

  // Wrap in full HTML document
  build_html_document(ctx, page, frontmatter, result)
}

// =============================================================================
// Layout Builders
// =============================================================================

///|
/// Build home layout (landing page)
fn build_home_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit, String],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)
  let main = h("main", [attr("class", "home-content")], [content])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-home")], [nav, main, footer])
}

///|
/// Build default layout (nav + content)
fn build_default_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit, String],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)
  let main = h("main", [attr("class", "main-content")], [content])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-default")], [nav, main, footer])
}

///|
/// Build blog layout (nav + post list)
/// Used for blog index pages that list all posts
fn build_blog_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit, String],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)

  // Page content (from markdown)
  let intro = h("div", [attr("class", "blog-intro")], [content])

  // Blog post list
  let post_list = @components.build_blog_post_list(ctx, None, false)

  // Tags cloud (collect all tags)
  let all_tags = collect_all_tags(ctx.pages)
  let tags_section = if not(all_tags.is_empty()) {
    h("aside", [attr("class", "blog-tags-section")], [
      h("h3", [], [@luna.text("Tags")]),
      @components.build_tag_list(all_tags),
    ])
  } else {
    @luna.fragment([])
  }
  let main = h("main", [attr("class", "blog-content")], [
    h("div", [attr("class", "blog-container")], [
      h("div", [attr("class", "blog-main")], [intro, post_list]),
      tags_section,
    ]),
  ])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-blog")], [nav, main, footer])
}

///|
/// Collect all unique tags from blog posts
fn collect_all_tags(pages : Array[@ssg.PageMeta]) -> Array[String] {
  let tags_set : Map[String, Bool] = {}
  for page in pages {
    let fm = page.frontmatter
    if fm.date is Some(_) && not(fm.draft) {
      for tag in fm.tags {
        tags_set[tag] = true
      }
    }
  }
  tags_set.keys().collect()
}

///|
/// Build blog post layout (nav + article with meta)
/// Used for individual blog posts
fn build_blog_post_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit, String],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)

  // Post header with meta
  let title = frontmatter.title.unwrap_or("Untitled")
  let date = frontmatter.date.unwrap_or("")
  let author = frontmatter.author.unwrap_or("")
  let header_children : Array[@luna.Node[Unit, String]] = []

  // Cover image
  if frontmatter.cover_image is Some(src) {
    header_children.push(
      h("div", [attr("class", "post-cover")], [
        h("img", [attr("src", src), attr("alt", title)], []),
      ]),
    )
  }

  // Title
  header_children.push(
    h("h1", [attr("class", "post-title")], [@luna.text(title)]),
  )

  // Meta (date, author)
  if not(date.is_empty()) || not(author.is_empty()) {
    header_children.push(@components.build_post_meta(date, author, None))
  }

  // Tags
  if not(frontmatter.tags.is_empty()) {
    header_children.push(@components.build_tag_list(frontmatter.tags))
  }
  let header = h("header", [attr("class", "post-header")], header_children)

  // Article content
  let article = h("article", [attr("class", "post-content markdown-body")], [
    content,
  ])

  // Prev/Next navigation
  let prev_next = @components.build_prev_next(ctx, page)
  let main = h("main", [attr("class", "blog-post-main")], [
    h("div", [attr("class", "blog-post-container")], [
      header, article, prev_next,
    ]),
  ])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-blog-post")], [nav, main, footer])
}

///|
/// Build doc layout (nav + sidebar + content + toc)
fn build_doc_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit, String],
  toc : Array[@markdown.TocItem],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)

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
  let breadcrumb = @components.build_breadcrumb(ctx, page)

  // Main content
  let article = h("article", [attr("class", "doc-content markdown-body")], [
    content,
  ])

  // TOC (outline)
  let toc_vnode = if not(toc.is_empty()) {
    @components.build_toc(toc)
  } else {
    @luna.fragment([])
  }

  // Prev/Next navigation
  let prev_next = @components.build_prev_next(ctx, page)
  let main = h("main", [attr("class", "doc-main")], [
    mobile_sidebar, breadcrumb, article, prev_next,
  ])
  let content_wrapper = h("div", [attr("class", "doc-container")], [
    sidebar, main, toc_vnode,
  ])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-doc")], [nav, content_wrapper, footer])
}

// =============================================================================
// HTML Document Building
// =============================================================================

///|
/// Build complete HTML document
fn build_html_document(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  render_result : @render.SSRResult,
) -> String {
  let html = StringBuilder::new()
  let page_title = frontmatter.title.unwrap_or(ctx.config.title)
  let desc = frontmatter.description.unwrap_or("")
  let base = ctx.config.base_url

  // === HEAD: Document metadata ===
  html.write_string("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n")
  html.write_string("  <meta charset=\"UTF-8\">\n")
  html.write_string(
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n",
  )
  html.write_string("  <title>\{page_title}</title>\n")

  // Description meta tag
  if not(desc.is_empty()) {
    html.write_string("  <meta name=\"description\" content=\"\{desc}\">\n")
  }

  // Robots meta tag
  if frontmatter.noindex {
    html.write_string("  <meta name=\"robots\" content=\"noindex\">\n")
  }

  // OGP meta tags
  write_ogp_meta_tags(html, ctx, page, frontmatter)

  // Custom OGP text
  if ctx.config.ogp_text is Some(text) {
    html.write_string("  \{text}\n")
  }

  // === HEAD: Preload and prefetch ===
  html.write_string(
    "  <link rel=\"modulepreload\" href=\"\{base}assets/loader.js\">\n",
  )

  // Preload tags for islands
  if render_result.preload_urls.length() > 0 {
    html.write_string(@render.generate_preload_tags(render_result.preload_urls))
  }

  // Prefetch prev/next pages
  write_prefetch_tags(html, ctx.pages, page.url_path)

  // === HEAD: Critical inline scripts ===
  // Theme script (runs early to prevent flash of unstyled content)
  let theme_script = @assets.get_theme_script()
  html.write_string("  <script>\{theme_script}</script>\n")

  // === HEAD: Inline critical CSS ===
  let combined_css = build_combined_css(ctx.config, is_dev=ctx.is_dev)
  html.write_string("  <style>\{combined_css}</style>\n")

  // Custom head snippets
  for snippet in ctx.config.head_snippets {
    html.write_string("  \{snippet}\n")
  }
  html.write_string("</head>\n")

  // === BODY: Content ===
  html.write_string("<body>\n")
  html.write_string("  <div id=\"app\">\{render_result.html}</div>\n")

  // === BODY: Deferred scripts ===
  // Island loader (module, async)
  html.write_string(
    "  <script type=\"module\" async src=\"\{base}assets/loader.js\"></script>\n",
  )

  // Web Components loader
  html.write_string(@assets.get_wc_loader_script())
  html.write_string("\n")

  // Navigation script (keyboard shortcuts, View Transitions)
  let page_order = get_page_order(ctx.pages, page.locale)
  html.write_string(
    @assets.build_navigation_script(page_order, ctx.config.navigation),
  )
  html.write_string("\n")

  // Sidebar state persistence
  html.write_string(@assets.get_sidebar_script())
  html.write_string("\n")

  // TOC scroll spy
  html.write_string(@assets.get_toc_script())
  html.write_string("\n")

  // Custom body snippets
  for snippet in ctx.config.body_snippets {
    html.write_string("  \{snippet}\n")
  }

  // Production-only body snippets (analytics, etc.)
  if not(ctx.is_dev) {
    for snippet in ctx.config.prod_body_snippets {
      html.write_string("  \{snippet}\n")
    }
  }
  html.write_string("</body>\n</html>")
  html.to_string()
}

///|
/// Write prefetch tags for prev/next pages
fn write_prefetch_tags(
  html : StringBuilder,
  pages : Array[@ssg.PageMeta],
  current_path : String,
) -> Unit {
  if @routes.find_prev_page(pages, current_path) is Some(link) {
    html.write_string("  <link rel=\"prefetch\" href=\"\{link.link}\">\n")
  }
  if @routes.find_next_page(pages, current_path) is Some(link) {
    html.write_string("  <link rel=\"prefetch\" href=\"\{link.link}\">\n")
  }
}

///|
/// Write OGP meta tags to StringBuilder
fn write_ogp_meta_tags(
  html : StringBuilder,
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
) -> Unit {
  let ogp = ctx.config.ogp
  let title = frontmatter.title.unwrap_or(ctx.config.title)
  let desc = frontmatter.description.unwrap_or("")

  // og:title (always include)
  html.write_string("  <meta property=\"og:title\" content=\"\{title}\">\n")

  // og:description
  if not(desc.is_empty()) {
    html.write_string(
      "  <meta property=\"og:description\" content=\"\{desc}\">\n",
    )
  }

  // og:type
  let og_type = frontmatter.og_type.unwrap_or("article")
  html.write_string("  <meta property=\"og:type\" content=\"\{og_type}\">\n")

  // og:url
  if ogp.site_url is Some(site_url) {
    html.write_string(
      "  <meta property=\"og:url\" content=\"\{site_url}\{page.url_path}\">\n",
    )
  }

  // og:image
  let image : String? = match frontmatter.image {
    Some(img) => Some(img)
    None => ogp.image
  }
  if image is Some(img) {
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
    html.write_string("  <meta property=\"og:image\" content=\"\{img_url}\">\n")
  }

  // og:site_name
  html.write_string(
    "  <meta property=\"og:site_name\" content=\"\{ctx.config.title}\">\n",
  )

  // Twitter Card
  let twitter_card = match frontmatter.twitter_card {
    Some(tc) => tc
    None => ogp.twitter_card.unwrap_or("summary")
  }
  html.write_string(
    "  <meta name=\"twitter:card\" content=\"\{twitter_card}\">\n",
  )
  html.write_string("  <meta name=\"twitter:title\" content=\"\{title}\">\n")
  if not(desc.is_empty()) {
    html.write_string(
      "  <meta name=\"twitter:description\" content=\"\{desc}\">\n",
    )
  }

  // Twitter image
  if image is Some(img) {
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
    html.write_string(
      "  <meta name=\"twitter:image\" content=\"\{img_url}\">\n",
    )
  }

  // Twitter site handle
  if ogp.twitter_handle is Some(handle) {
    html.write_string("  <meta name=\"twitter:site\" content=\"\{handle}\">\n")
  }
}

// =============================================================================
// Navigation Helpers
// =============================================================================

///|
/// Get page order (URL list) for a locale based on sidebar order
fn get_page_order(
  pages : Array[@ssg.PageMeta],
  locale : String,
) -> Array[String] {
  // Generate sidebar groups for this locale to get the correct order
  let sidebar_groups = @routes.generate_auto_sidebar(pages, locale~)
  @routes.get_sidebar_page_order(sidebar_groups)
}

// =============================================================================
// Syntax Highlighting
// =============================================================================

///|
/// Apply syntax highlighting to code blocks in HTML
/// Find substring position starting from `from` index
fn find_from(s : String, needle : String, from? : Int = 0) -> Int? {
  let sub = s.substring(start=from)
  match sub.find(needle) {
    Some(idx) => Some(from + idx)
    None => None
  }
}

/// Finds <pre class="code-block" data-lang="xxx"> elements and highlights them.
/// Pure MoonBit implementation using syntree (no JS FFI).
fn apply_syntax_highlighting(
  html : String,
  highlighter : @shiki.Highlighter,
) -> String {
  let marker = "<pre class=\"code-block\""
  if not(html.contains(marker)) {
    return html
  }
  let result = StringBuilder::new()
  let mut pos = 0
  let len = html.length()
  while pos < len {
    match find_from(html, marker, from=pos) {
      None => {
        result.write_string(html.substring(start=pos))
        break
      }
      Some(start) => {
        // Copy everything before the match
        result.write_string(html.substring(start=pos, end=start))
        // Find the end of </pre>
        let end_marker = "</pre>"
        match find_from(html, end_marker, from=start) {
          None => {
            result.write_string(html.substring(start=start))
            break
          }
          Some(end_pos) => {
            let block_end = end_pos + end_marker.length()
            let block = html.substring(start=start, end=block_end)
            // Extract lang from data-lang="xxx"
            let lang = extract_data_attr(block, "data-lang")
            // Extract code content between <code...>...</code>
            let code_content = extract_code_content(block)
            match (lang, code_content) {
              (Some(l), Some(code)) => {
                let decoded = @shiki.decode_html_entities(code)
                result.write_string(highlighter.highlight(decoded, l))
              }
              _ => result.write_string(block) // keep original
            }
            pos = block_end
          }
        }
      }
    }
  }
  result.to_string()
}

///|
fn extract_data_attr(html : String, attr : String) -> String? {
  let needle = attr + "=\""
  match find_from(html, needle) {
    None => None
    Some(start) => {
      let val_start = start + needle.length()
      match find_from(html, "\"", from=val_start) {
        None => None
        Some(val_end) => Some(html.substring(start=val_start, end=val_end))
      }
    }
  }
}

///|
fn extract_code_content(html : String) -> String? {
  let code_start_marker = "<code"
  match find_from(html, code_start_marker) {
    None => None
    Some(tag_start) =>
      match find_from(html, ">", from=tag_start) {
        None => None
        Some(content_start) => {
          let cs = content_start + 1
          match find_from(html, "</code>") {
            None => None
            Some(content_end) => Some(html.substring(start=cs, end=content_end))
          }
        }
      }
  }
}
