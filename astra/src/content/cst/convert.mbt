// CST to MdNode Converter
// Converts @md_parser CST types to @markdown.MdNode for VNode transformation

// =============================================================================
// Native Parser Entry Point
// =============================================================================

///|
/// Parse markdown using the native MoonBit parser (no FFI)
pub fn parse_markdown_native(
  content : String,
) -> (@frontmatter.Frontmatter, Array[@markdown.MdNode]) {
  let result = @md_parser.parse(content)
  convert_document(result.document)
}

// =============================================================================
// CST Conversion Entry Point
// =============================================================================

///|
/// Convert CST Document to Frontmatter and MdNode array
pub fn convert_document(
  doc : @md_parser.Document,
) -> (@frontmatter.Frontmatter, Array[@markdown.MdNode]) {
  let fm = match doc.frontmatter {
    Some(cst_fm) => @frontmatter.from_cst(cst_fm)
    None => @frontmatter.Frontmatter::default()
  }
  let nodes = convert_blocks(doc.children)
  (fm, nodes)
}

// =============================================================================
// Block Conversion
// =============================================================================

///|
/// Convert array of CST Blocks to MdNode array
fn convert_blocks(blocks : Array[@md_parser.Block]) -> Array[@markdown.MdNode] {
  let nodes : Array[@markdown.MdNode] = []
  for block in blocks {
    match convert_block(block) {
      Some(node) => nodes.push(node)
      None => ()
    }
  }
  nodes
}

///|
/// Convert single CST Block to MdNode
fn convert_block(block : @md_parser.Block) -> @markdown.MdNode? {
  match block {
    @md_parser.Block::ThematicBreak(..) => Some(@markdown.MdNode::ThematicBreak)
    @md_parser.Block::Heading(level~, children~, ..) => {
      let md_children = convert_inlines(children)
      let text = @md_toc.extract_text_from_inlines(children)
      let id = @slug.generate_heading_id(text)
      Some(@markdown.MdNode::Heading(level~, children=md_children, id~))
    }
    @md_parser.Block::Paragraph(children~, ..) => {
      let md_children = convert_inlines(children)
      // Check for Island directive in raw text
      let raw_text = @md_toc.extract_text_from_inlines(children)
      match parse_island_directive(raw_text) {
        Some(island) => Some(@markdown.MdNode::Island(island))
        None => Some(@markdown.MdNode::Paragraph(children=md_children))
      }
    }
    @md_parser.Block::FencedCode(info~, code~, ..) =>
      Some(@markdown.MdNode::CodeBlock(lang=info, code~))
    @md_parser.Block::IndentedCode(code~, ..) =>
      Some(@markdown.MdNode::CodeBlock(lang="", code~))
    @md_parser.Block::Blockquote(children~, ..) => {
      let md_children = convert_blocks(children)
      Some(@markdown.MdNode::Blockquote(children=md_children))
    }
    @md_parser.Block::BulletList(items~, ..) => {
      let md_items = convert_list_items(items)
      Some(@markdown.MdNode::List(ordered=false, items=md_items))
    }
    @md_parser.Block::OrderedList(items~, ..) => {
      let md_items = convert_list_items(items)
      Some(@markdown.MdNode::List(ordered=true, items=md_items))
    }
    @md_parser.Block::HtmlBlock(html~, ..) =>
      // Check for custom element (Web Component) first
      match parse_custom_element(html) {
        Some(component) => Some(@markdown.MdNode::Component(component))
        None =>
          // Check for legacy Island directive
          match parse_island_directive(html) {
            Some(island) => Some(@markdown.MdNode::Island(island))
            None => Some(@markdown.MdNode::Html(html))
          }
      }
    @md_parser.Block::Table(header~, rows~, ..) => {
      let md_headers = header.map(fn(cell) {
        let children = convert_inlines(cell.children)
        // Flatten to single text node if possible
        if children.length() == 1 {
          children[0]
        } else {
          @markdown.MdNode::Text(
            @md_toc.extract_text_from_inlines(cell.children),
          )
        }
      })
      let md_rows = rows.map(fn(row) {
        row.map(fn(cell) {
          let children = convert_inlines(cell.children)
          if children.length() == 1 {
            children[0]
          } else {
            @markdown.MdNode::Text(
              @md_toc.extract_text_from_inlines(cell.children),
            )
          }
        })
      })
      Some(@markdown.MdNode::Table(headers=md_headers, rows=md_rows))
    }
    @md_parser.Block::BlankLines(..) => None // Skip blank lines
    @md_parser.Block::FootnoteDefinition(..) => None // Skip footnotes
  }
}

///|
/// Convert list items
fn convert_list_items(
  items : Array[@md_parser.ListItem],
) -> Array[Array[@markdown.MdNode]] {
  items.map(fn(item) { convert_blocks(item.children) })
}

// =============================================================================
// Inline Conversion
// =============================================================================

///|
/// Convert array of CST Inlines to MdNode array
fn convert_inlines(
  inlines : Array[@md_parser.Inline],
) -> Array[@markdown.MdNode] {
  let nodes : Array[@markdown.MdNode] = []
  for inline in inlines {
    match convert_inline(inline) {
      Some(node) => nodes.push(node)
      None => ()
    }
  }
  nodes
}

///|
/// Convert single CST Inline to MdNode
fn convert_inline(inline : @md_parser.Inline) -> @markdown.MdNode? {
  match inline {
    @md_parser.Inline::Text(content~, ..) =>
      Some(@markdown.MdNode::Text(content))
    @md_parser.Inline::SoftBreak(..) => Some(@markdown.MdNode::Text(" "))
    @md_parser.Inline::HardBreak(..) => Some(@markdown.MdNode::LineBreak)
    @md_parser.Inline::Emphasis(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@markdown.MdNode::Italic(children=md_children))
    }
    @md_parser.Inline::Strong(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@markdown.MdNode::Bold(children=md_children))
    }
    @md_parser.Inline::Strikethrough(children~, ..) => {
      // MdNode doesn't have strikethrough, convert to plain text with ~~
      let text = "~~" + @md_toc.extract_text_from_inlines(children) + "~~"
      Some(@markdown.MdNode::Text(text))
    }
    @md_parser.Inline::Code(content~, ..) =>
      Some(@markdown.MdNode::Code(content))
    @md_parser.Inline::Link(children~, url~, title~, ..) => {
      let md_children = convert_inlines(children)
      Some(@markdown.MdNode::Link(href=url, title~, children=md_children))
    }
    @md_parser.Inline::RefLink(children~, label~, ..) => {
      // Reference links need resolution - for now, use label as href
      let md_children = convert_inlines(children)
      Some(
        @markdown.MdNode::Link(href="#" + label, title="", children=md_children),
      )
    }
    @md_parser.Inline::Autolink(url~, ..) => {
      let children = [@markdown.MdNode::Text(url)]
      Some(@markdown.MdNode::Link(href=url, title="", children~))
    }
    @md_parser.Inline::Image(alt~, url~, title~, ..) =>
      Some(@markdown.MdNode::Image(src=url, alt~, title~))
    @md_parser.Inline::RefImage(alt~, label~, ..) =>
      // Reference images need resolution - for now, use label as src
      Some(@markdown.MdNode::Image(src="#" + label, alt~, title=""))
    @md_parser.Inline::HtmlInline(html~, ..) =>
      Some(@markdown.MdNode::Html(html))
    @md_parser.Inline::FootnoteReference(label~, ..) =>
      // Convert footnote reference to superscript link
      Some(@markdown.MdNode::Text("[^\{label}]"))
  }
}
