///| Markdown AST to VNode Transformer

// =============================================================================
// Helper Functions
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
// Main Transformer
// =============================================================================

///| Convert MdNode array to VNode
pub fn md_nodes_to_vnode(nodes : Array[@ssg.MdNode]) -> @luna.Node[Unit] {
  let children = nodes.map(fn(n) { md_node_to_vnode(n) })
  @luna.vfragment(children)
}

///| Convert single MdNode to VNode
pub fn md_node_to_vnode(node : @ssg.MdNode) -> @luna.Node[Unit] {
  match node {
    @ssg.MdNode::Heading(level~, children~, id~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      let attrs = [
        attr("id", id),
        attr("class", "heading heading-\{level}"),
      ]
      let tag = "h\{level}"
      h(tag, attrs, child_vnodes)
    }
    @ssg.MdNode::Paragraph(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      h("p", [], child_vnodes)
    }
    @ssg.MdNode::Text(text) => @luna.vtext(text)
    @ssg.MdNode::Bold(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      h("strong", [], child_vnodes)
    }
    @ssg.MdNode::Italic(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      h("em", [], child_vnodes)
    }
    @ssg.MdNode::Code(code) => h("code", [], [@luna.vtext(code)])
    @ssg.MdNode::CodeBlock(lang~, code~) => {
      let code_el = h(
        "code",
        [attr("class", "language-\{lang}")],
        [@luna.vtext(code)],
      )
      h("pre", [attr("class", "code-block")], [code_el])
    }
    @ssg.MdNode::Link(href~, title~, children~) => {
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
    @ssg.MdNode::Image(src~, alt~, title~) => {
      let attrs : Array[(String, @luna.Attr[Unit])] = [
        attr("src", src),
        attr("alt", alt),
      ]
      if not(title.is_empty()) {
        attrs.push(attr("title", title))
      }
      h("img", attrs, [])
    }
    @ssg.MdNode::List(ordered~, items~) => {
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
    @ssg.MdNode::Blockquote(children~) => {
      let child_vnodes = children.map(fn(n) { md_node_to_vnode(n) })
      h("blockquote", [], child_vnodes)
    }
    @ssg.MdNode::Table(headers~, rows~) => {
      // Build header row
      let header_cells = headers.map(fn(h_node) {
        h("th", [], [md_node_to_vnode(h_node)])
      })
      let header_row = h("tr", [], header_cells)
      let thead = h("thead", [], [header_row])

      // Build body rows
      let body_rows = rows.map(fn(row) {
        let cells = row.map(fn(cell) {
          h("td", [], [md_node_to_vnode(cell)])
        })
        h("tr", [], cells)
      })
      let tbody = h("tbody", [], body_rows)

      h("table", [attr("class", "md-table")], [thead, tbody])
    }
    @ssg.MdNode::Html(_html) =>
      // Raw HTML - TODO: implement raw HTML support
      // For now, skip raw HTML blocks
      @luna.vfragment([])
    @ssg.MdNode::Island(embed) =>
      // Convert to VIsland for hydration
      create_island_vnode(embed)
    @ssg.MdNode::ThematicBreak => h("hr", [], [])
    @ssg.MdNode::LineBreak => h("br", [], [])
  }
}

///| Create island VNode from IslandEmbed
fn create_island_vnode(embed : @ssg.IslandEmbed) -> @luna.Node[Unit] {
  let url = "/static/\{embed.name}.js"
  @luna.visland(embed.name, url, embed.props, [], trigger=embed.trigger)
}

// =============================================================================
// Table of Contents Extraction
// =============================================================================

///| Table of contents item
pub(all) struct TocItem {
  level : Int
  text : String
  id : String
}

///| Extract table of contents from MdNode array
pub fn extract_toc(nodes : Array[@ssg.MdNode]) -> Array[TocItem] {
  let toc : Array[TocItem] = []
  extract_toc_recursive(nodes, toc)
  toc
}

///| Extract headings recursively
fn extract_toc_recursive(nodes : Array[@ssg.MdNode], toc : Array[TocItem]) -> Unit {
  for node in nodes {
    match node {
      @ssg.MdNode::Heading(level~, children~, id~) => {
        // Only include h2-h4 in TOC
        if level >= 2 && level <= 4 {
          let text = extract_text_from_nodes(children)
          toc.push(TocItem::{ level, text, id })
        }
      }
      @ssg.MdNode::Blockquote(children~) => extract_toc_recursive(children, toc)
      @ssg.MdNode::List(items~, ..) =>
        for item in items {
          extract_toc_recursive(item, toc)
        }
      _ => ()
    }
  }
}

///| Extract plain text from MdNode array
fn extract_text_from_nodes(nodes : Array[@ssg.MdNode]) -> String {
  let buf = StringBuilder::new()
  for node in nodes {
    extract_text_recursive(node, buf)
  }
  buf.to_string()
}

///| Extract text recursively
fn extract_text_recursive(node : @ssg.MdNode, buf : StringBuilder) -> Unit {
  match node {
    @ssg.MdNode::Text(text) => buf.write_string(text)
    @ssg.MdNode::Bold(children~) | @ssg.MdNode::Italic(children~) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    @ssg.MdNode::Code(code) => buf.write_string(code)
    @ssg.MdNode::Link(children~, ..) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    _ => ()
  }
}
