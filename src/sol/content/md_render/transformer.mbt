// Markdown AST to VNode Transformer

// =============================================================================
// Helper Functions
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
// Link Resolution
// =============================================================================

///|
/// Resolve a relative link to an absolute path
/// - Absolute links (starting with /) are returned as-is
/// - External links (http://, https://, etc.) are returned as-is
/// - For index pages: use standard browser behavior (./foo = child)
/// - For content pages: use sibling behavior (./foo = sibling in parent dir)
/// - locale_prefix: prepended to relative links for i18n (e.g., "/ja" for Japanese)
/// - available_urls: list of available page URLs for fallback (if empty, no fallback check)
fn resolve_href(
  href : String,
  current_url_path : String,
  is_index : Bool,
  locale_prefix : String,
  available_urls : Array[String],
) -> String {
  // External links - return as-is
  if href.has_prefix("http://") ||
    href.has_prefix("https://") ||
    href.has_prefix("mailto:") ||
    href.has_prefix("javascript:") {
    return href
  }

  // Hash-only links - return as-is
  if href.has_prefix("#") {
    return href
  }

  // Already absolute - just normalize (don't add locale prefix for explicit absolute paths)
  if href.has_prefix("/") {
    return normalize_href(href)
  }

  // Handle ./ prefix
  let clean_href = if href.has_prefix("./") {
    let slice_result : String = href[2:].to_string() catch { _ => href }
    slice_result
  } else {
    href
  }

  // For index pages, use the current URL as base (standard browser behavior)
  // For content pages, use parent directory (sibling behavior)
  // Note: current_url_path already includes locale prefix (e.g., /ja/intro/)
  // We need to use the canonical path (without locale) and add locale prefix
  let canonical_base = strip_locale_prefix(current_url_path, locale_prefix)
  let base = if is_index {
    canonical_base
  } else {
    get_parent_directory(canonical_base)
  }

  // Resolve the canonical path (without locale)
  let canonical_resolved = normalize_href(base + clean_href)

  // If no locale prefix, just return the resolved path
  if locale_prefix.is_empty() {
    return canonical_resolved
  }

  // Try localized URL first
  let localized_url = locale_prefix + canonical_resolved

  // If available_urls is provided and not empty, check if localized URL exists
  if available_urls.length() > 0 {
    // Check if localized version exists
    if url_exists(localized_url, available_urls) {
      return localized_url
    }
    // Fallback to default locale (canonical path without prefix)
    return canonical_resolved
  }

  // No URL list provided - assume localized URL exists
  localized_url
}

///|
/// Check if a URL exists in the available URLs list
fn url_exists(url : String, available_urls : Array[String]) -> Bool {
  for u in available_urls {
    if u == url {
      return true
    }
  }
  false
}

///|
/// Strip locale prefix from URL path
/// "/ja/intro/" with prefix "/ja" -> "/intro/"
fn strip_locale_prefix(url_path : String, locale_prefix : String) -> String {
  if locale_prefix.is_empty() {
    return url_path
  }
  let prefix_with_slash = locale_prefix + "/"
  if url_path.has_prefix(prefix_with_slash) {
    let rest : String = url_path[prefix_with_slash.length():].to_string() catch {
      _ => return url_path
    }
    "/" + rest
  } else if url_path == locale_prefix + "/" {
    "/"
  } else {
    url_path
  }
}

///|
/// Get parent directory of a URL path
/// /luna/tutorial-js/introduction_basics/ -> /luna/tutorial-js/
fn get_parent_directory(url_path : String) -> String {
  // Remove trailing slash if present
  let trimmed = if url_path.has_suffix("/") {
    let slice_result : String = url_path[:url_path.length() - 1].to_string() catch {
      _ => url_path
    }
    slice_result
  } else {
    url_path
  }

  // Find last slash
  let chars = trimmed.to_array()
  let mut last_slash = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash > 0 {
    String::from_array(chars[:last_slash + 1].to_array())
  } else {
    "/"
  }
}

///|
/// Normalize a URL path (ensure trailing slash for directory-like paths)
fn normalize_href(href : String) -> String {
  // If it looks like a file (has extension), don't add trailing slash
  if has_file_extension(href) {
    return href
  }

  // Add trailing slash if not present
  if href.has_suffix("/") {
    href
  } else {
    href + "/"
  }
}

///|
/// Check if path has a file extension
fn has_file_extension(path : String) -> Bool {
  let chars = path.to_array()
  let mut last_dot = -1
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '.' {
      last_dot = i
    }
    if chars[i] == '/' {
      last_slash = i
    }
  }
  last_dot > last_slash && last_dot > 0
}

// =============================================================================
// Main Transformer
// =============================================================================

///|
/// Convert MdNode array to VNode
pub fn md_nodes_to_vnode(
  nodes : Array[@markdown.MdNode],
  islands_base_path? : String = "/static/",
  current_url_path? : String = "/",
  is_index? : Bool = true,
  locale_prefix? : String = "",
  available_urls? : Array[String] = [],
) -> @luna.Node[Unit] {
  let children = nodes.map(fn(n) {
    md_node_to_vnode(
      n,
      islands_base_path~,
      current_url_path~,
      is_index~,
      locale_prefix~,
      available_urls~,
    )
  })
  @luna.fragment(children)
}

///|
/// Convert single MdNode to VNode
pub fn md_node_to_vnode(
  node : @markdown.MdNode,
  islands_base_path? : String = "/static/",
  current_url_path? : String = "/",
  is_index? : Bool = true,
  locale_prefix? : String = "",
  available_urls? : Array[String] = [],
) -> @luna.Node[Unit] {
  match node {
    @markdown.MdNode::Heading(level~, children~, id~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(
          n,
          islands_base_path~,
          current_url_path~,
          is_index~,
          locale_prefix~,
          available_urls~,
        )
      })
      let attrs = [attr("id", id), attr("class", "heading heading-\{level}")]
      let tag = "h\{level}"
      h(tag, attrs, child_vnodes)
    }
    @markdown.MdNode::Paragraph(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(
          n,
          islands_base_path~,
          current_url_path~,
          is_index~,
          locale_prefix~,
          available_urls~,
        )
      })
      h("p", [], child_vnodes)
    }
    @markdown.MdNode::Text(text) => @luna.text(text)
    @markdown.MdNode::Bold(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(
          n,
          islands_base_path~,
          current_url_path~,
          is_index~,
          locale_prefix~,
          available_urls~,
        )
      })
      h("strong", [], child_vnodes)
    }
    @markdown.MdNode::Italic(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(
          n,
          islands_base_path~,
          current_url_path~,
          is_index~,
          locale_prefix~,
          available_urls~,
        )
      })
      h("em", [], child_vnodes)
    }
    @markdown.MdNode::Code(code) => h("code", [], [@luna.text(code)])
    @markdown.MdNode::CodeBlock(lang~, code~) => {
      // Parse info string to extract lang, filename, and meta
      let info = parse_code_block_info(lang)

      // Build code element attributes
      let code_attrs : Array[(String, @luna.Attr[Unit])] = []
      if not(info.lang.is_empty()) {
        code_attrs.push(attr("class", "language-\{info.lang}"))
      }
      let code_el = h("code", code_attrs, [@luna.text(code)])

      // Build pre element attributes with data for shiki processing
      let pre_attrs : Array[(String, @luna.Attr[Unit])] = [
        attr("class", "code-block"),
      ]
      if not(info.lang.is_empty()) {
        pre_attrs.push(attr("data-lang", info.lang))
      }
      if not(info.filename.is_empty()) {
        pre_attrs.push(attr("data-filename", info.filename))
      }
      if not(info.meta.is_empty()) {
        pre_attrs.push(attr("data-meta", info.meta))
      }
      h("pre", pre_attrs, [code_el])
    }
    @markdown.MdNode::Link(href~, title~, children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(
          n,
          islands_base_path~,
          current_url_path~,
          is_index~,
          locale_prefix~,
          available_urls~,
        )
      })
      // Resolve relative links to absolute paths with locale prefix and fallback
      let resolved_href = resolve_href(
        href, current_url_path, is_index, locale_prefix, available_urls,
      )
      let attrs : Array[(String, @luna.Attr[Unit])] = [
        attr("href", resolved_href),
      ]
      if not(title.is_empty()) {
        attrs.push(attr("title", title))
      }
      // Add external link attributes for external URLs
      if href.has_prefix("http://") || href.has_prefix("https://") {
        attrs.push(attr("target", "_blank"))
        attrs.push(attr("rel", "noopener noreferrer"))
      }
      h("a", attrs, child_vnodes)
    }
    @markdown.MdNode::Image(src~, alt~, title~) => {
      let attrs : Array[(String, @luna.Attr[Unit])] = [
        attr("src", src),
        attr("alt", alt),
      ]
      if not(title.is_empty()) {
        attrs.push(attr("title", title))
      }
      h("img", attrs, [])
    }
    @markdown.MdNode::List(ordered~, items~) => {
      let item_vnodes = items.map(fn(item_nodes) {
        let children = item_nodes.map(fn(n) {
          md_node_to_vnode(
            n,
            islands_base_path~,
            current_url_path~,
            is_index~,
            locale_prefix~,
            available_urls~,
          )
        })
        h("li", [], children)
      })
      if ordered {
        h("ol", [], item_vnodes)
      } else {
        h("ul", [], item_vnodes)
      }
    }
    @markdown.MdNode::Blockquote(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(
          n,
          islands_base_path~,
          current_url_path~,
          is_index~,
          locale_prefix~,
          available_urls~,
        )
      })
      h("blockquote", [], child_vnodes)
    }
    @markdown.MdNode::Table(headers~, rows~) => {
      // Build header row
      let header_cells = headers.map(fn(h_node) {
        h("th", [], [
          md_node_to_vnode(
            h_node,
            islands_base_path~,
            current_url_path~,
            is_index~,
            locale_prefix~,
            available_urls~,
          ),
        ])
      })
      let header_row = h("tr", [], header_cells)
      let thead = h("thead", [], [header_row])

      // Build body rows
      let body_rows = rows.map(fn(row) {
        let cells = row.map(fn(cell) {
          h("td", [], [
            md_node_to_vnode(
              cell,
              islands_base_path~,
              current_url_path~,
              is_index~,
              locale_prefix~,
              available_urls~,
            ),
          ])
        })
        h("tr", [], cells)
      })
      let tbody = h("tbody", [], body_rows)
      h("table", [attr("class", "md-table")], [thead, tbody])
    }
    @markdown.MdNode::Html(_html) =>
      // Raw HTML - TODO: implement raw HTML support
      // For now, skip raw HTML blocks
      @luna.fragment([])
    @markdown.MdNode::Island(embed) =>
      // Convert to VIsland for hydration (legacy)
      create_island_vnode(embed, islands_base_path)
    @markdown.MdNode::Component(embed) =>
      // Convert to Web Component with luna:wc-* attributes
      create_component_vnode(embed, islands_base_path)
    @markdown.MdNode::JsxComponent(embed) => {
      // Convert JSX component to Web Component
      let component = jsx_to_component_embed(embed, islands_base_path)
      create_component_vnode(component, islands_base_path)
    }
    @markdown.MdNode::ThematicBreak => h("hr", [], [])
    @markdown.MdNode::LineBreak => h("br", [], [])
  }
}

///|
/// Create island VNode from IslandEmbed (legacy)
fn create_island_vnode(
  embed : @markdown.IslandEmbed,
  base_path : String,
) -> @luna.Node[Unit] {
  let url = "\{base_path}\{embed.name}.js"
  @luna.island(embed.name, url, embed.props, [], trigger=embed.trigger)
}

///|
/// Create Web Component VNode from ComponentEmbed
/// Generates custom element with luna:wc-url and luna:wc-trigger attributes
fn create_component_vnode(
  embed : @markdown.ComponentEmbed,
  base_path : String,
) -> @luna.Node[Unit] {
  // Build URL from tag name (e.g., "my-counter" -> "/components/my-counter.js")
  let url = "\{base_path}\{embed.tag}.js"

  // Build attributes array
  let attrs : Array[(String, @luna.Attr[Unit])] = []

  // Add luna:wc-url for hydration
  attrs.push(attr("luna:wc-url", url))

  // Add luna:wc-trigger
  let trigger_str = match embed.trigger {
    @luna.Load => "load"
    @luna.Idle => "idle"
    @luna.Visible => "visible"
    @luna.Media(_) => "media"
    @luna.None => "none"
  }
  attrs.push(attr("luna:wc-trigger", trigger_str))

  // Add user-provided attributes
  for pair in embed.attrs {
    let (key, value) = pair
    attrs.push(attr(key, value))
  }

  // Build children (inner content as raw HTML for SSR)
  let children : Array[@luna.Node[Unit]] = if embed.content.is_empty() {
    []
  } else {
    [@luna.raw_html(embed.content)]
  }
  h(embed.tag, attrs, children)
}

///|
/// Convert JSX component name to WebComponent tag
/// "Button" -> "luna-button"
/// "MyCounter" -> "luna-my-counter"
/// "my-counter" -> "my-counter" (already a WebComponent, no prefix added)
fn jsx_to_wc_tag(name : String) -> String {
  // If name already contains hyphen, it's already a WebComponent tag
  if name.contains("-") {
    return name
  }
  "luna-" + camel_to_kebab(name)
}

///|
/// Convert camelCase to kebab-case
/// "MyCounter" -> "my-counter"
/// "Button" -> "button"
fn camel_to_kebab(s : String) -> String {
  let result : Array[Char] = []
  let chars = s.to_array()
  for i, c in chars {
    if c >= 'A' && c <= 'Z' {
      // Uppercase letter
      if i > 0 {
        result.push('-')
      }
      // Convert to lowercase
      result.push(Int::unsafe_to_char(c.to_int() + 32))
    } else {
      result.push(c)
    }
  }
  String::from_array(result)
}

///|
/// Convert MdxAttrValue to string
fn mdx_attr_to_string(value : @markdown.MdxAttrValue) -> String {
  match value {
    @markdown.MdxAttrValue::StringLiteral(s) => s
    @markdown.MdxAttrValue::Expression(expr) => expr
    @markdown.MdxAttrValue::Boolean => "true"
  }
}

///|
/// Convert JsxComponentEmbed to ComponentEmbed (WebComponent)
fn jsx_to_component_embed(
  jsx : @markdown.JsxComponentEmbed,
  _base_path : String,
) -> @markdown.ComponentEmbed {
  // Convert JSX tag to WebComponent tag
  let tag = jsx_to_wc_tag(jsx.tag)

  // Convert attributes
  let attrs : Array[(String, String)] = []
  for pair in jsx.attrs {
    let (key, value) = pair
    // Handle CLS hints as style
    if key == "cls:width" || key == "cls:height" {
      // Skip CLS hints - they're handled separately
      continue
    }
    attrs.push((key, mdx_attr_to_string(value)))
  }

  // Add CLS hints as style attribute if present
  match jsx.cls_hints {
    Some(hints) => {
      let mut style = ""
      match hints.width {
        Some(w) => style = style + "min-width:\{w};"
        None => ()
      }
      match hints.height {
        Some(h) => style = style + "min-height:\{h};"
        None => ()
      }
      if not(style.is_empty()) {
        attrs.push(("style", style))
      }
    }
    None => ()
  }
  @markdown.ComponentEmbed::{
    tag,
    attrs,
    content: jsx.children,
    trigger: @luna.Load,
  }
}

// =============================================================================
// Re-exports from @toc
// =============================================================================

///|
pub type TocItem = @toc.TocItem

///|
/// Extract table of contents from MdNode array
/// Re-exported from @toc
pub fn extract_toc(nodes : Array[@markdown.MdNode]) -> Array[@toc.TocItem] {
  @toc.extract_toc(nodes)
}

///|
/// Extract description from markdown nodes
/// Re-exported from @toc
pub fn extract_description(
  nodes : Array[@markdown.MdNode],
  max_length? : Int = 160,
) -> String? {
  @toc.extract_description(nodes, max_length~)
}
