// CST to MdNode Converter
// Converts @md_parser CST types to @astra.MdNode for VNode transformation
// Also provides parse_markdown_native() as a pure MoonBit alternative to FFI-based parser

// =============================================================================
// Native Parser Entry Point
// =============================================================================

///|
/// Parse markdown using the native MoonBit parser (no FFI)
/// This is a drop-in replacement for parse_markdown() from parser.mbt
pub fn parse_markdown_native(
  content : String,
) -> (@astra.Frontmatter, Array[@astra.MdNode]) {
  let result = @md_parser.parse(content)
  convert_cst_document(result.document)
}

// =============================================================================
// CST Conversion Entry Point
// =============================================================================

///|
/// Convert CST Document to SSG Frontmatter and MdNode array
pub fn convert_cst_document(
  doc : @md_parser.Document,
) -> (@astra.Frontmatter, Array[@astra.MdNode]) {
  let frontmatter = match doc.frontmatter {
    Some(fm) => convert_frontmatter(fm)
    None => @astra.Frontmatter::default()
  }
  let nodes = convert_blocks(doc.children)
  (frontmatter, nodes)
}

// =============================================================================
// Frontmatter Conversion
// =============================================================================

///|
/// Convert CST Frontmatter to SSG Frontmatter
fn convert_frontmatter(fm : @md_parser.Frontmatter) -> @astra.Frontmatter {
  let mut title : String? = None
  let mut description : String? = None
  let mut layout : String? = None
  let mut sidebar = true
  let islands : Array[String] = []
  let mut image : String? = None
  let mut og_type : String? = None
  let mut twitter_card : String? = None
  let mut ssr = false
  for entry in fm.entries {
    let (key, value) = entry
    match key {
      "title" => title = Some(value)
      "description" => description = Some(value)
      "layout" => layout = Some(value)
      "sidebar" => sidebar = value == "true"
      "ssr" => ssr = value == "true"
      "islands" => {
        // Parse comma-separated islands
        let parts = value.split(",")
        for part in parts {
          let trimmed = part.to_string().trim(chars=" \t\n\r").to_string()
          if not(trimmed.is_empty()) {
            islands.push(trimmed)
          }
        }
      }
      // OGP fields
      "image" | "ogImage" | "og_image" => image = Some(value)
      "ogType" | "og_type" => og_type = Some(value)
      "twitterCard" | "twitter_card" => twitter_card = Some(value)
      _ => () // Ignore unknown fields
    }
  }
  @astra.Frontmatter::{
    title,
    description,
    layout,
    sidebar,
    outline: None,
    islands,
    prev: None,
    next: None,
    image,
    og_type,
    twitter_card,
    ssr,
    renderer: None,
  }
}

// =============================================================================
// Block Conversion
// =============================================================================

///|
/// Convert array of CST Blocks to MdNode array
fn convert_blocks(blocks : Array[@md_parser.Block]) -> Array[@astra.MdNode] {
  let nodes : Array[@astra.MdNode] = []
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
fn convert_block(block : @md_parser.Block) -> @astra.MdNode? {
  match block {
    @md_parser.Block::ThematicBreak(..) => Some(@astra.MdNode::ThematicBreak)
    @md_parser.Block::Heading(level~, children~, ..) => {
      let md_children = convert_inlines(children)
      let text = extract_text_from_inlines(children)
      let id = generate_heading_id(text)
      Some(@astra.MdNode::Heading(level~, children=md_children, id~))
    }
    @md_parser.Block::Paragraph(children~, ..) => {
      let md_children = convert_inlines(children)
      // Check for Island directive in raw text
      let raw_text = extract_text_from_inlines(children)
      match parse_island_directive(raw_text) {
        Some(island) => Some(@astra.MdNode::Island(island))
        None => Some(@astra.MdNode::Paragraph(children=md_children))
      }
    }
    @md_parser.Block::FencedCode(info~, code~, ..) =>
      Some(@astra.MdNode::CodeBlock(lang=info, code~))
    @md_parser.Block::IndentedCode(code~, ..) =>
      Some(@astra.MdNode::CodeBlock(lang="", code~))
    @md_parser.Block::Blockquote(children~, ..) => {
      let md_children = convert_blocks(children)
      Some(@astra.MdNode::Blockquote(children=md_children))
    }
    @md_parser.Block::BulletList(items~, ..) => {
      let md_items = convert_list_items(items)
      Some(@astra.MdNode::List(ordered=false, items=md_items))
    }
    @md_parser.Block::OrderedList(items~, ..) => {
      let md_items = convert_list_items(items)
      Some(@astra.MdNode::List(ordered=true, items=md_items))
    }
    @md_parser.Block::HtmlBlock(html~, ..) =>
      // Check for custom element (Web Component) first
      match parse_custom_element(html) {
        Some(component) => Some(@astra.MdNode::Component(component))
        None =>
          // Check for legacy Island directive
          match parse_island_directive(html) {
            Some(island) => Some(@astra.MdNode::Island(island))
            None => Some(@astra.MdNode::Html(html))
          }
      }
    @md_parser.Block::Table(header~, rows~, ..) => {
      let md_headers = header.map(fn(cell) {
        let children = convert_inlines(cell.children)
        // Flatten to single text node if possible
        if children.length() == 1 {
          children[0]
        } else {
          @astra.MdNode::Text(extract_text_from_inlines(cell.children))
        }
      })
      let md_rows = rows.map(fn(row) {
        row.map(fn(cell) {
          let children = convert_inlines(cell.children)
          if children.length() == 1 {
            children[0]
          } else {
            @astra.MdNode::Text(extract_text_from_inlines(cell.children))
          }
        })
      })
      Some(@astra.MdNode::Table(headers=md_headers, rows=md_rows))
    }
    @md_parser.Block::BlankLines(..) => None // Skip blank lines (not represented in MdNode)
    @md_parser.Block::FootnoteDefinition(..) => None // Skip footnotes (not supported in MdNode)
  }
}

///|
/// Convert list items
fn convert_list_items(
  items : Array[@md_parser.ListItem],
) -> Array[Array[@astra.MdNode]] {
  items.map(fn(item) { convert_blocks(item.children) })
}

// =============================================================================
// Inline Conversion
// =============================================================================

///|
/// Convert array of CST Inlines to MdNode array
fn convert_inlines(inlines : Array[@md_parser.Inline]) -> Array[@astra.MdNode] {
  let nodes : Array[@astra.MdNode] = []
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
fn convert_inline(inline : @md_parser.Inline) -> @astra.MdNode? {
  match inline {
    @md_parser.Inline::Text(content~, ..) => Some(@astra.MdNode::Text(content))
    @md_parser.Inline::SoftBreak(..) => Some(@astra.MdNode::Text(" ")) // Convert soft break to space
    @md_parser.Inline::HardBreak(..) => Some(@astra.MdNode::LineBreak)
    @md_parser.Inline::Emphasis(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@astra.MdNode::Italic(children=md_children))
    }
    @md_parser.Inline::Strong(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@astra.MdNode::Bold(children=md_children))
    }
    @md_parser.Inline::Strikethrough(children~, ..) => {
      // MdNode doesn't have strikethrough, convert to plain text with ~~
      let text = "~~" + extract_text_from_inlines(children) + "~~"
      Some(@astra.MdNode::Text(text))
    }
    @md_parser.Inline::Code(content~, ..) => Some(@astra.MdNode::Code(content))
    @md_parser.Inline::Link(children~, url~, title~, ..) => {
      let md_children = convert_inlines(children)
      Some(@astra.MdNode::Link(href=url, title~, children=md_children))
    }
    @md_parser.Inline::RefLink(children~, label~, ..) => {
      // Reference links need resolution - for now, use label as href
      let md_children = convert_inlines(children)
      Some(
        @astra.MdNode::Link(href="#" + label, title="", children=md_children),
      )
    }
    @md_parser.Inline::Autolink(url~, ..) => {
      let children = [@astra.MdNode::Text(url)]
      Some(@astra.MdNode::Link(href=url, title="", children~))
    }
    @md_parser.Inline::Image(alt~, url~, title~, ..) =>
      Some(@astra.MdNode::Image(src=url, alt~, title~))
    @md_parser.Inline::RefImage(alt~, label~, ..) =>
      // Reference images need resolution - for now, use label as src
      Some(@astra.MdNode::Image(src="#" + label, alt~, title=""))
    @md_parser.Inline::HtmlInline(html~, ..) => Some(@astra.MdNode::Html(html))
    @md_parser.Inline::FootnoteReference(label~, ..) =>
      // Convert footnote reference to superscript link
      Some(@astra.MdNode::Text("[^\{label}]"))
  }
}

// =============================================================================
// Utility Functions (CST-specific)
// =============================================================================

///|
/// Extract plain text from CST inline nodes
fn extract_text_from_inlines(inlines : Array[@md_parser.Inline]) -> String {
  let buf = StringBuilder::new()
  for inline in inlines {
    cst_extract_text_recursive(inline, buf)
  }
  buf.to_string()
}

///|
/// Extract text recursively from CST Inline nodes
fn cst_extract_text_recursive(
  inline : @md_parser.Inline,
  buf : StringBuilder,
) -> Unit {
  match inline {
    @md_parser.Inline::Text(content~, ..) => buf.write_string(content)
    @md_parser.Inline::SoftBreak(..) => buf.write_string(" ")
    @md_parser.Inline::HardBreak(..) => buf.write_string("\n")
    @md_parser.Inline::Emphasis(children~, ..)
    | @md_parser.Inline::Strong(children~, ..) =>
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
    @md_parser.Inline::FootnoteReference(label~, ..) =>
      buf.write_string("[^\{label}]")
  }
}

// Note: generate_heading_id, parse_island_directive, extract_attribute
// are reused from parser.mbt (same package)

// =============================================================================
// Info String Parsing
// =============================================================================

///|
/// Parsed info string from code block fence
/// Format: "lang:filename {meta}"
/// Examples:
///   "javascript" → (lang="javascript", filename="", meta="")
///   "js:app.js" → (lang="js", filename="app.js", meta="")
///   "ts:index.ts {highlight=[1,3]}" → (lang="ts", filename="index.ts", meta="{highlight=[1,3]}")
pub(all) struct CodeBlockInfo {
  lang : String
  filename : String
  meta : String
}

///|
/// Parse code block info string into components
pub fn parse_code_block_info(info : String) -> CodeBlockInfo {
  let trimmed = info.trim(chars=" \t\n\r").to_string()
  if trimmed.is_empty() {
    return { lang: "", filename: "", meta: "" }
  }

  // Find meta section (starts with space + {)
  let (main_part, meta) = match trimmed.find(" {") {
    Some(idx) => {
      let main = trimmed.unsafe_substring(start=0, end=idx)
      let meta_str = trimmed
        .unsafe_substring(start=idx + 1, end=trimmed.length())
        .trim(chars=" \t\n\r")
        .to_string()
      (main, meta_str)
    }
    None => (trimmed, "")
  }

  // Split lang:filename
  match main_part.find(":") {
    Some(idx) => {
      let lang = main_part.unsafe_substring(start=0, end=idx)
      let filename = main_part.unsafe_substring(
        start=idx + 1,
        end=main_part.length(),
      )
      { lang, filename, meta }
    }
    None => { lang: main_part, filename: "", meta }
  }
}
