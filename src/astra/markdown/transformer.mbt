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
fn resolve_href(
  href : String,
  current_url_path : String,
  is_index : Bool,
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

  // Already absolute - just normalize
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
  let base = if is_index {
    // Index page: /luna/api-js/ + signals = /luna/api-js/signals/
    current_url_path
  } else {
    // Content page: /luna/tutorial-js/introduction_basics/ -> parent /luna/tutorial-js/
    get_parent_directory(current_url_path)
  }
  normalize_href(base + clean_href)
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
  nodes : Array[@astra.MdNode],
  islands_base_path? : String = "/static/",
  current_url_path? : String = "/",
  is_index? : Bool = true,
) -> @luna.Node[Unit] {
  let children = nodes.map(fn(n) {
    md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
  })
  @luna.fragment(children)
}

///|
/// Convert single MdNode to VNode
pub fn md_node_to_vnode(
  node : @astra.MdNode,
  islands_base_path? : String = "/static/",
  current_url_path? : String = "/",
  is_index? : Bool = true,
) -> @luna.Node[Unit] {
  match node {
    @astra.MdNode::Heading(level~, children~, id~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
      })
      let attrs = [attr("id", id), attr("class", "heading heading-\{level}")]
      let tag = "h\{level}"
      h(tag, attrs, child_vnodes)
    }
    @astra.MdNode::Paragraph(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
      })
      h("p", [], child_vnodes)
    }
    @astra.MdNode::Text(text) => @luna.text(text)
    @astra.MdNode::Bold(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
      })
      h("strong", [], child_vnodes)
    }
    @astra.MdNode::Italic(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
      })
      h("em", [], child_vnodes)
    }
    @astra.MdNode::Code(code) => h("code", [], [@luna.text(code)])
    @astra.MdNode::CodeBlock(lang~, code~) => {
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
    @astra.MdNode::Link(href~, title~, children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
      })
      // Resolve relative links to absolute paths
      let resolved_href = resolve_href(href, current_url_path, is_index)
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
    @astra.MdNode::Image(src~, alt~, title~) => {
      let attrs : Array[(String, @luna.Attr[Unit])] = [
        attr("src", src),
        attr("alt", alt),
      ]
      if not(title.is_empty()) {
        attrs.push(attr("title", title))
      }
      h("img", attrs, [])
    }
    @astra.MdNode::List(ordered~, items~) => {
      let item_vnodes = items.map(fn(item_nodes) {
        let children = item_nodes.map(fn(n) {
          md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
        })
        h("li", [], children)
      })
      if ordered {
        h("ol", [], item_vnodes)
      } else {
        h("ul", [], item_vnodes)
      }
    }
    @astra.MdNode::Blockquote(children~) => {
      let child_vnodes = children.map(fn(n) {
        md_node_to_vnode(n, islands_base_path~, current_url_path~, is_index~)
      })
      h("blockquote", [], child_vnodes)
    }
    @astra.MdNode::Table(headers~, rows~) => {
      // Build header row
      let header_cells = headers.map(fn(h_node) {
        h("th", [], [
          md_node_to_vnode(
            h_node,
            islands_base_path~,
            current_url_path~,
            is_index~,
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
            ),
          ])
        })
        h("tr", [], cells)
      })
      let tbody = h("tbody", [], body_rows)
      h("table", [attr("class", "md-table")], [thead, tbody])
    }
    @astra.MdNode::Html(_html) =>
      // Raw HTML - TODO: implement raw HTML support
      // For now, skip raw HTML blocks
      @luna.fragment([])
    @astra.MdNode::Island(embed) =>
      // Convert to VIsland for hydration (legacy)
      create_island_vnode(embed, islands_base_path)
    @astra.MdNode::Component(embed) =>
      // Convert to Web Component with luna:wc-* attributes
      create_component_vnode(embed, islands_base_path)
    @astra.MdNode::ThematicBreak => h("hr", [], [])
    @astra.MdNode::LineBreak => h("br", [], [])
  }
}

///|
/// Create island VNode from IslandEmbed (legacy)
fn create_island_vnode(
  embed : @astra.IslandEmbed,
  base_path : String,
) -> @luna.Node[Unit] {
  let url = "\{base_path}\{embed.name}.js"
  @luna.island(embed.name, url, embed.props, [], trigger=embed.trigger)
}

///|
/// Create Web Component VNode from ComponentEmbed
/// Generates custom element with luna:wc-url and luna:wc-trigger attributes
fn create_component_vnode(
  embed : @astra.ComponentEmbed,
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

  // Build children (inner content as text)
  let children : Array[@luna.Node[Unit]] = if embed.content.is_empty() {
    []
  } else {
    [@luna.text(embed.content)]
  }
  h(embed.tag, attrs, children)
}

// =============================================================================
// Description Extraction (for meta description)
// =============================================================================

///|
/// Extract description from markdown nodes
/// Returns the first paragraph's text, truncated to max_length
pub fn extract_description(
  nodes : Array[@astra.MdNode],
  max_length? : Int = 160,
) -> String? {
  // Find the first paragraph
  for node in nodes {
    match node {
      @astra.MdNode::Paragraph(children~) => {
        let text = extract_text_from_nodes(children)
        if not(text.is_empty()) {
          return Some(truncate_text(text, max_length))
        }
      }
      _ => continue
    }
  }
  None
}

///|
/// Truncate text to max_length, adding ellipsis if needed
fn truncate_text(text : String, max_length : Int) -> String {
  let chars = text.to_array()
  if chars.length() <= max_length {
    return text
  }
  // Find last space before max_length to avoid cutting words
  let mut cut_point = max_length
  for i = max_length - 1; i >= max_length - 30 && i >= 0; i = i - 1 {
    if chars[i] == ' ' {
      cut_point = i
      break
    }
  }
  // Build truncated string
  let result : Array[Char] = []
  for i = 0; i < cut_point; i = i + 1 {
    result.push(chars[i])
  }
  String::from_array(result) + "..."
}

// =============================================================================
// Table of Contents Extraction
// =============================================================================

///|
/// Table of contents item
pub(all) struct TocItem {
  level : Int
  text : String
  id : String
}

///|
/// Extract table of contents from MdNode array
pub fn extract_toc(nodes : Array[@astra.MdNode]) -> Array[TocItem] {
  let toc : Array[TocItem] = []
  extract_toc_recursive(nodes, toc)
  toc
}

///|
/// Extract headings recursively
fn extract_toc_recursive(
  nodes : Array[@astra.MdNode],
  toc : Array[TocItem],
) -> Unit {
  for node in nodes {
    match node {
      @astra.MdNode::Heading(level~, children~, id~) =>
        // Only include h2-h4 in TOC
        if level >= 2 && level <= 4 {
          let text = extract_text_from_nodes(children)
          toc.push(TocItem::{ level, text, id })
        }
      @astra.MdNode::Blockquote(children~) =>
        extract_toc_recursive(children, toc)
      @astra.MdNode::List(items~, ..) =>
        for item in items {
          extract_toc_recursive(item, toc)
        }
      _ => ()
    }
  }
}

///|
/// Extract plain text from MdNode array
fn extract_text_from_nodes(nodes : Array[@astra.MdNode]) -> String {
  let buf = StringBuilder::new()
  for node in nodes {
    extract_text_recursive(node, buf)
  }
  buf.to_string()
}

///|
/// Extract text recursively
fn extract_text_recursive(node : @astra.MdNode, buf : StringBuilder) -> Unit {
  match node {
    @astra.MdNode::Text(text) => buf.write_string(text)
    @astra.MdNode::Bold(children~) | @astra.MdNode::Italic(children~) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    @astra.MdNode::Code(code) => buf.write_string(code)
    @astra.MdNode::Link(children~, ..) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    _ => ()
  }
}
