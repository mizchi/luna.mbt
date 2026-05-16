// HTML Builder - Page layout building and HTML document generation

// =============================================================================
// Page HTML Building
// =============================================================================

///|
/// Build complete HTML page
fn build_page_html(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit, String],
  toc : Array[@md_render.TocItem],
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
  let result = @luna_render.render_to_string(page_vnode, preload=true)

  // Wrap in full HTML document
  build_html_document(ctx, page, frontmatter, result)
}

// =============================================================================
// Layout Builders
// =============================================================================

///|
/// Build home layout (landing page)
fn build_home_layout(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  _frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit, String],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)
  let main = h(
    "main",
    [attr("class", "home-content"), attr("data-pagefind-body", "")],
    [content],
  )
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-home")], [nav, main, footer])
}

///|
/// Build default layout (nav + content)
fn build_default_layout(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  _frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit, String],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)
  let main = h(
    "main",
    [attr("class", "main-content"), attr("data-pagefind-body", "")],
    [content],
  )
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-default")], [nav, main, footer])
}

///|
/// Build blog layout (nav + post list)
/// Used for blog index pages that list all posts
fn build_blog_layout(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  _frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit, String],
) -> @luna.Node[Unit, String] {
  let nav = @components.build_nav(ctx, page)

  // Page content (from markdown)
  let intro = h("div", [attr("class", "blog-intro")], [content])

  // Blog post list
  let post_list = @components.build_blog_post_list(ctx, None, false)

  // Tags cloud (collect all tags)
  let all_tags = collect_all_tags(ctx.pages)
  let tags_section = if !all_tags.is_empty() {
    h("aside", [attr("class", "blog-tags-section")], [
      h("h3", [], [@luna.text("Tags")]),
      @components.build_tag_list(ctx, all_tags),
    ])
  } else {
    @luna.fragment([])
  }
  let main = h(
    "main",
    [attr("class", "blog-content"), attr("data-pagefind-body", "")],
    [
      h("div", [attr("class", "blog-container")], [
        h("div", [attr("class", "blog-main")], [intro, post_list]),
        tags_section,
      ]),
    ],
  )
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-blog")], [nav, main, footer])
}

///|
/// Collect all unique tags from blog posts
fn collect_all_tags(pages : Array[@astra.PageMeta]) -> Array[String] {
  let tags_set : Map[String, Bool] = {}
  for page in pages {
    let fm = page.frontmatter
    if fm.date is Some(_) && !fm.draft {
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
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
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
  if !date.is_empty() || !author.is_empty() {
    header_children.push(@components.build_post_meta(date, author, None))
  }

  // Tags
  if !frontmatter.tags.is_empty() {
    header_children.push(@components.build_tag_list(ctx, frontmatter.tags))
  }
  let header = h("header", [attr("class", "post-header")], header_children)

  // Article content
  let article = h("article", [attr("class", "post-content markdown-body")], [
    content,
  ])

  // Prev/Next navigation
  let prev_next = @components.build_prev_next(ctx, page)
  let main = h(
    "main",
    [attr("class", "blog-post-main"), attr("data-pagefind-body", "")],
    [
      h("div", [attr("class", "blog-post-container")], [
        header, article, prev_next,
      ]),
    ],
  )
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-blog-post")], [nav, main, footer])
}

///|
/// Build doc layout (nav + sidebar + content + toc)
fn build_doc_layout(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
  content : @luna.Node[Unit, String],
  toc : Array[@md_render.TocItem],
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
  let article = h(
    "article",
    [attr("class", "doc-content markdown-body"), attr("data-pagefind-body", "")],
    [content],
  )

  // TOC (outline)
  let toc_vnode = if !toc.is_empty() {
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
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
  render_result : @luna_render.SSRResult,
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
  if !desc.is_empty() {
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
  // Preload tags for islands
  if render_result.preload_urls.length() > 0 {
    html.write_string(
      @luna_render.generate_preload_tags(render_result.preload_urls),
    )
  }

  // Prefetch prev/next pages
  write_prefetch_tags(html, ctx.pages, page.url_path, base)

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
  // Web Components loader (inlined)
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
  if !ctx.is_dev {
    for snippet in ctx.config.prod_body_snippets {
      html.write_string("  \{snippet}\n")
    }
  }
  html.write_string("</body>\n</html>")
  let result = html.to_string()
  // Post-process: rewrite remaining bare absolute paths in content HTML
  if base != "/" {
    rewrite_content_links(result, base)
  } else {
    result
  }
}

///|
/// Rewrite absolute href/src links in HTML content to include base_url prefix.
/// Handles: href="/path" → href="/base/path", src="/path" → src="/base/path"
/// Skips external URLs, anchors, and already-prefixed paths.
fn rewrite_content_links(html : String, base_url : String) -> String {
  let base = if base_url.has_suffix("/") {
    base_url[:base_url.length() - 1].to_owned()
  } else {
    base_url
  }
  // Step 1: Replace bare href="/..." with href="{base}/..."
  // Use a placeholder to avoid double-replacement
  let placeholder = "%%BASE_HREF%%"
  let step1 = replace_all_occurrences(
    html,
    "href=\"" + base + "/",
    "href=\"" + placeholder + "/",
  )
  let step2 = replace_all_occurrences(step1, "href=\"/", "href=\"" + base + "/")
  let step3 = replace_all_occurrences(
    step2,
    "href=\"" + placeholder + "/",
    "href=\"" + base + "/",
  )
  // Step 2: Same for src
  let step4 = replace_all_occurrences(
    step3,
    "src=\"" + base + "/",
    "src=\"" + placeholder + "/",
  )
  let step5 = replace_all_occurrences(step4, "src=\"/", "src=\"" + base + "/")
  replace_all_occurrences(
    step5,
    "src=\"" + placeholder + "/",
    "src=\"" + base + "/",
  )
}

///|
fn replace_all_occurrences(
  input : String,
  old : String,
  new_ : String,
) -> String {
  if old.is_empty() || !input.contains(old) {
    return input
  }
  let buf = StringBuilder::new()
  let old_len = old.length()
  let mut pos = 0
  while true {
    match input[pos:].find(old) {
      Some(idx) => {
        buf.write_string(input[pos:pos + idx].to_owned())
        buf.write_string(new_)
        pos = pos + idx + old_len
      }
      None => {
        buf.write_string(input[pos:].to_owned())
        break
      }
    }
  }
  buf.to_string()
}

///|
/// Write prefetch tags for prev/next pages
fn write_prefetch_tags(
  html : StringBuilder,
  pages : Array[@astra.PageMeta],
  current_path : String,
  base_url : String,
) -> Unit {
  if @routes.find_prev_page(pages, current_path) is Some(link) {
    let url = @astra.resolve_base_url(base_url, link.link)
    html.write_string("  <link rel=\"prefetch\" href=\"\{url}\">\n")
  }
  if @routes.find_next_page(pages, current_path) is Some(link) {
    let url = @astra.resolve_base_url(base_url, link.link)
    html.write_string("  <link rel=\"prefetch\" href=\"\{url}\">\n")
  }
}

///|
/// Write OGP meta tags to StringBuilder
fn write_ogp_meta_tags(
  html : StringBuilder,
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  frontmatter : @astra.Frontmatter,
) -> Unit {
  let ogp = ctx.config.ogp
  let title = frontmatter.title.unwrap_or(ctx.config.title)
  let desc = frontmatter.description.unwrap_or("")

  // og:title (always include)
  html.write_string("  <meta property=\"og:title\" content=\"\{title}\">\n")

  // og:description
  if !desc.is_empty() {
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
  if !desc.is_empty() {
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
  pages : Array[@astra.PageMeta],
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
  let sub = s[from:]
  match sub.find(needle) {
    Some(idx) => Some(from + idx)
    None => None
  }
}

///|
/// Finds <pre class="code-block" data-lang="xxx"> elements and highlights them.
/// Pure MoonBit implementation using syntree (no JS FFI).
fn apply_syntax_highlighting(
  html : String,
  highlighter : @shiki.Highlighter,
) -> String {
  let marker = "<pre class=\"code-block\""
  if !html.contains(marker) {
    return html
  }
  let result = StringBuilder::new()
  let mut pos = 0
  let len = html.length()
  while pos < len {
    match find_from(html, marker, from=pos) {
      None => {
        result.write_string(html[pos:].to_owned())
        break
      }
      Some(start) => {
        // Copy everything before the match
        result.write_string(html[pos:start].to_owned())
        // Find the end of </pre>
        let end_marker = "</pre>"
        match find_from(html, end_marker, from=start) {
          None => {
            result.write_string(html[start:].to_owned())
            break
          }
          Some(end_pos) => {
            let block_end = end_pos + end_marker.length()
            let block = html[start:block_end].to_owned()
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
        Some(val_end) => Some(html[val_start:val_end].to_owned())
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
            Some(content_end) => Some(html[cs:content_end].to_owned())
          }
        }
      }
  }
}

///|
test "rewrite_content_links replaces bare links" {
  let html = "<a href=\"/intro/\">Intro</a><a href=\"/about/\">About</a>"
  let result = rewrite_content_links(html, "/sol.mbt/")
  assert_true(result.contains("href=\"/sol.mbt/intro/\""))
  assert_true(result.contains("href=\"/sol.mbt/about/\""))
}

///|
test "rewrite_content_links preserves modulepreload" {
  let html = "<link rel=\"modulepreload\" href=\"/sol.mbt/assets/wc-loader.js\">"
  let result = rewrite_content_links(html, "/sol.mbt/")
  assert_false(result.contains("hhref"))
  assert_true(result.contains("href=\"/sol.mbt/assets/wc-loader.js\""))
}

///|
test "rewrite_content_links skips already-prefixed links" {
  let html = "<a href=\"/sol.mbt/luna/\">Luna</a><a href=\"/intro/\">Intro</a>"
  let result = rewrite_content_links(html, "/sol.mbt/")
  // luna link should not be double-prefixed
  assert_true(result.contains("href=\"/sol.mbt/luna/\""))
  assert_false(result.contains("href=\"/sol.mbt/sol.mbt/"))
  // intro link should be prefixed
  assert_true(result.contains("href=\"/sol.mbt/intro/\""))
}
