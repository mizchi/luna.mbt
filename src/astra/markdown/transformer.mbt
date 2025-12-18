///| Markdown AST to VNode Transformer

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
// Main Transformer
// =============================================================================

///|
/// Convert MdNode array to VNode
pub fn md_nodes_to_vnode(nodes : Array[@astra.MdNode]) -> @luna.Node[Unit] {
  let children = nodes.map(fn(n) { md_node_to_vnode(n) })
  @luna.fragment(children)
}

///|
/// Convert single MdNode to VNode
pub fn md_node_to_vnode(node : @astra.MdNode) -> @luna.Node[Unit] {
  match node {
    @astra.MdNode::Heading(level~, children~, id~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      let attrs = [attr("id", id), attr("class", "heading heading-\{level}")]
      let tag = "h\{level}"
      h(tag, attrs, child_vnodes)
    }
    @astra.MdNode::Paragraph(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      h("p", [], child_vnodes)
    }
    @astra.MdNode::Text(text) => @luna.text(text)
    @astra.MdNode::Bold(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      h("strong", [], child_vnodes)
    }
    @astra.MdNode::Italic(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
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
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      let attrs : Array[(String, @luna.Attr[Unit])] = [attr("href", href)]
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
        let children = item_nodes.map(fn(n) { md_node_to_vnode(n) })
        h("li", [], children)
      })
      if ordered {
        h("ol", [], item_vnodes)
      } else {
        h("ul", [], item_vnodes)
      }
    }
    @astra.MdNode::Blockquote(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      h("blockquote", [], child_vnodes)
    }
    @astra.MdNode::Table(headers~, rows~) => {
      // Build header row
      let header_cells = headers.map(fn(h_node) {
        h("th", [], [md_node_to_vnode(h_node)])
      })
      let header_row = h("tr", [], header_cells)
      let thead = h("thead", [], [header_row])

      // Build body rows
      let body_rows = rows.map(fn(row) {
        let cells = row.map(fn(cell) { h("td", [], [md_node_to_vnode(cell)]) })
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
      // Convert to VIsland for hydration
      create_island_vnode(embed)
    @astra.MdNode::ThematicBreak => h("hr", [], [])
    @astra.MdNode::LineBreak => h("br", [], [])
  }
}

///|
/// Create island VNode from IslandEmbed
fn create_island_vnode(embed : @astra.IslandEmbed) -> @luna.Node[Unit] {
  let url = "/static/\{embed.name}.js"
  @luna.island(embed.name, url, embed.props, [], trigger=embed.trigger)
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
