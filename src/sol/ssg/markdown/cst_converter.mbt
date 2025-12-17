///| CST to MdNode Converter
///| Converts @md_parser CST types to @ssg.MdNode for VNode transformation
///| Also provides parse_markdown_native() as a pure MoonBit alternative to FFI-based parser

// =============================================================================
// Native Parser Entry Point
// =============================================================================

///| Parse markdown using the native MoonBit parser (no FFI)
///| This is a drop-in replacement for parse_markdown() from parser.mbt
pub fn parse_markdown_native(content : String) -> (@ssg.Frontmatter, Array[@ssg.MdNode]) {
  let result = @md_parser.parse(content)
  convert_cst_document(result.document)
}

// =============================================================================
// CST Conversion Entry Point
// =============================================================================

///| Convert CST Document to SSG Frontmatter and MdNode array
pub fn convert_cst_document(doc : @md_parser.Document) -> (@ssg.Frontmatter, Array[@ssg.MdNode]) {
  let frontmatter = match doc.frontmatter {
    Some(fm) => convert_frontmatter(fm)
    None => @ssg.Frontmatter::default()
  }

  let nodes = convert_blocks(doc.children)
  (frontmatter, nodes)
}

// =============================================================================
// Frontmatter Conversion
// =============================================================================

///| Convert CST Frontmatter to SSG Frontmatter
fn convert_frontmatter(fm : @md_parser.Frontmatter) -> @ssg.Frontmatter {
  let mut title : String? = None
  let mut description : String? = None
  let mut layout : String? = None
  let mut sidebar = true
  let islands : Array[String] = []

  for entry in fm.entries {
    let (key, value) = entry
    match key {
      "title" => title = Some(value)
      "description" => description = Some(value)
      "layout" => layout = Some(value)
      "sidebar" => sidebar = value == "true"
      "islands" => {
        // Parse comma-separated islands
        let parts = value.split(",")
        for part in parts {
          let trimmed = part.to_string().trim_space().to_string()
          if not(trimmed.is_empty()) {
            islands.push(trimmed)
          }
        }
      }
      _ => () // Ignore unknown fields
    }
  }

  @ssg.Frontmatter::{
    title,
    description,
    layout,
    sidebar,
    outline: None,
    islands,
    prev: None,
    next: None,
  }
}

// =============================================================================
// Block Conversion
// =============================================================================

///| Convert array of CST Blocks to MdNode array
fn convert_blocks(blocks : Array[@md_parser.Block]) -> Array[@ssg.MdNode] {
  let nodes : Array[@ssg.MdNode] = []
  for block in blocks {
    match convert_block(block) {
      Some(node) => nodes.push(node)
      None => ()
    }
  }
  nodes
}

///| Convert single CST Block to MdNode
fn convert_block(block : @md_parser.Block) -> @ssg.MdNode? {
  match block {
    @md_parser.Block::ThematicBreak(..) =>
      Some(@ssg.MdNode::ThematicBreak)

    @md_parser.Block::Heading(level~, children~, ..) => {
      let md_children = convert_inlines(children)
      let text = extract_text_from_inlines(children)
      let id = generate_heading_id(text)
      Some(@ssg.MdNode::Heading(level~, children=md_children, id~))
    }

    @md_parser.Block::Paragraph(children~, ..) => {
      let md_children = convert_inlines(children)
      // Check for Island directive in raw text
      let raw_text = extract_text_from_inlines(children)
      match parse_island_directive(raw_text) {
        Some(island) => Some(@ssg.MdNode::Island(island))
        None => Some(@ssg.MdNode::Paragraph(children=md_children))
      }
    }

    @md_parser.Block::FencedCode(info~, code~, ..) => {
      // Check for island code block
      if info.has_prefix("island:") {
        let name = info.unsafe_substring(start=7, end=info.length())
        Some(@ssg.MdNode::Island(
          @ssg.IslandEmbed::{ name, props: code.trim_space().to_string(), trigger: @luna.Load }
        ))
      } else {
        Some(@ssg.MdNode::CodeBlock(lang=info, code~))
      }
    }

    @md_parser.Block::IndentedCode(code~, ..) =>
      Some(@ssg.MdNode::CodeBlock(lang="", code~))

    @md_parser.Block::Blockquote(children~, ..) => {
      let md_children = convert_blocks(children)
      Some(@ssg.MdNode::Blockquote(children=md_children))
    }

    @md_parser.Block::BulletList(items~, ..) => {
      let md_items = convert_list_items(items)
      Some(@ssg.MdNode::List(ordered=false, items=md_items))
    }

    @md_parser.Block::OrderedList(items~, ..) => {
      let md_items = convert_list_items(items)
      Some(@ssg.MdNode::List(ordered=true, items=md_items))
    }

    @md_parser.Block::HtmlBlock(html~, ..) => {
      // Check for Island directive in HTML
      match parse_island_directive(html) {
        Some(island) => Some(@ssg.MdNode::Island(island))
        None => Some(@ssg.MdNode::Html(html))
      }
    }

    @md_parser.Block::Table(header~, rows~, ..) => {
      let md_headers = header.map(fn(cell) {
        let children = convert_inlines(cell.children)
        // Flatten to single text node if possible
        if children.length() == 1 {
          children[0]
        } else {
          @ssg.MdNode::Text(extract_text_from_inlines(cell.children))
        }
      })

      let md_rows = rows.map(fn(row) {
        row.map(fn(cell) {
          let children = convert_inlines(cell.children)
          if children.length() == 1 {
            children[0]
          } else {
            @ssg.MdNode::Text(extract_text_from_inlines(cell.children))
          }
        })
      })

      Some(@ssg.MdNode::Table(headers=md_headers, rows=md_rows))
    }

    @md_parser.Block::BlankLines(..) =>
      None // Skip blank lines (not represented in MdNode)
  }
}

///| Convert list items
fn convert_list_items(items : Array[@md_parser.ListItem]) -> Array[Array[@ssg.MdNode]] {
  items.map(fn(item) { convert_blocks(item.children) })
}

// =============================================================================
// Inline Conversion
// =============================================================================

///| Convert array of CST Inlines to MdNode array
fn convert_inlines(inlines : Array[@md_parser.Inline]) -> Array[@ssg.MdNode] {
  let nodes : Array[@ssg.MdNode] = []
  for inline in inlines {
    match convert_inline(inline) {
      Some(node) => nodes.push(node)
      None => ()
    }
  }
  nodes
}

///| Convert single CST Inline to MdNode
fn convert_inline(inline : @md_parser.Inline) -> @ssg.MdNode? {
  match inline {
    @md_parser.Inline::Text(content~, ..) =>
      Some(@ssg.MdNode::Text(content))

    @md_parser.Inline::SoftBreak(..) =>
      Some(@ssg.MdNode::Text(" ")) // Convert soft break to space

    @md_parser.Inline::HardBreak(..) =>
      Some(@ssg.MdNode::LineBreak)

    @md_parser.Inline::Emphasis(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Italic(children=md_children))
    }

    @md_parser.Inline::Strong(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Bold(children=md_children))
    }

    @md_parser.Inline::Strikethrough(children~, ..) => {
      // MdNode doesn't have strikethrough, convert to plain text with ~~
      let text = "~~" + extract_text_from_inlines(children) + "~~"
      Some(@ssg.MdNode::Text(text))
    }

    @md_parser.Inline::Code(content~, ..) =>
      Some(@ssg.MdNode::Code(content))

    @md_parser.Inline::Link(children~, url~, title~, ..) => {
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Link(href=url, title~, children=md_children))
    }

    @md_parser.Inline::RefLink(children~, label~, ..) => {
      // Reference links need resolution - for now, use label as href
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Link(href="#" + label, title="", children=md_children))
    }

    @md_parser.Inline::Autolink(url~, ..) => {
      let children = [@ssg.MdNode::Text(url)]
      Some(@ssg.MdNode::Link(href=url, title="", children~))
    }

    @md_parser.Inline::Image(alt~, url~, title~, ..) =>
      Some(@ssg.MdNode::Image(src=url, alt~, title~))

    @md_parser.Inline::RefImage(alt~, label~, ..) =>
      // Reference images need resolution - for now, use label as src
      Some(@ssg.MdNode::Image(src="#" + label, alt~, title=""))

    @md_parser.Inline::HtmlInline(html~, ..) =>
      Some(@ssg.MdNode::Html(html))
  }
}

// =============================================================================
// Utility Functions (CST-specific)
// =============================================================================

///| Extract plain text from CST inline nodes
fn extract_text_from_inlines(inlines : Array[@md_parser.Inline]) -> String {
  let buf = StringBuilder::new()
  for inline in inlines {
    cst_extract_text_recursive(inline, buf)
  }
  buf.to_string()
}

///| Extract text recursively from CST Inline nodes
fn cst_extract_text_recursive(inline : @md_parser.Inline, buf : StringBuilder) -> Unit {
  match inline {
    @md_parser.Inline::Text(content~, ..) => buf.write_string(content)
    @md_parser.Inline::SoftBreak(..) => buf.write_string(" ")
    @md_parser.Inline::HardBreak(..) => buf.write_string("\n")
    @md_parser.Inline::Emphasis(children~, ..) | @md_parser.Inline::Strong(children~, ..) =>
      for child in children {
        cst_extract_text_recursive(child, buf)
      }
    @md_parser.Inline::Strikethrough(children~, ..) =>
      for child in children {
        cst_extract_text_recursive(child, buf)
      }
    @md_parser.Inline::Code(content~, ..) => buf.write_string(content)
    @md_parser.Inline::Link(children~, ..) =>
      for child in children {
        cst_extract_text_recursive(child, buf)
      }
    @md_parser.Inline::RefLink(children~, ..) =>
      for child in children {
        cst_extract_text_recursive(child, buf)
      }
    @md_parser.Inline::Autolink(url~, ..) => buf.write_string(url)
    @md_parser.Inline::Image(alt~, ..) => buf.write_string(alt)
    @md_parser.Inline::RefImage(alt~, ..) => buf.write_string(alt)
    @md_parser.Inline::HtmlInline(..) => () // Skip HTML in text extraction
  }
}

// Note: generate_heading_id, parse_island_directive, extract_attribute
// are reused from parser.mbt (same package)
