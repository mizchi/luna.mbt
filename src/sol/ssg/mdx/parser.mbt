// MDX Parser
// Parses MDX content and converts to Frontmatter and MdNode array

// =============================================================================
// Main API
// =============================================================================

///|
/// Parse MDX content and return frontmatter and MdNode array
/// MDX extends markdown with:
/// - import/export statements
/// - JSX components (converted to WebComponents)
pub fn parse_mdx(
  content : String,
) -> (@frontmatter.Frontmatter, Array[@ssg.MdNode]) {
  // Parse using standard markdown parser
  let result = @md_parser.parse(content)

  // Extract frontmatter from YAML
  let base_fm = match result.document.frontmatter {
    Some(cst_fm) => @frontmatter.from_cst(cst_fm)
    None => @frontmatter.Frontmatter::default()
  }

  // Parse MDX blocks (imports, exports, JSX elements)
  let mdx_blocks = @md_mdx.parse_mdx_blocks(result.document)

  // Extract frontmatter from export statements
  let fm = extract_frontmatter_from_exports(base_fm, mdx_blocks)

  // Convert document blocks to MdNode, replacing JSX blocks
  let nodes = convert_document_with_mdx(result.document, mdx_blocks)
  (fm, nodes)
}

// =============================================================================
// Frontmatter Extraction from Exports
// =============================================================================

///|
/// Extract frontmatter fields from MDX export statements
/// Supports: export const title = "...", export const description = "..."
fn extract_frontmatter_from_exports(
  base : @frontmatter.Frontmatter,
  blocks : Array[@md_mdx.MdxBlock],
) -> @frontmatter.Frontmatter {
  let mut fm = base
  for block in blocks {
    match block {
      @md_mdx.MdxBlock::ExportDecl(kind~, name~, value~, ..) =>
        if kind == @md_mdx.ExportKind::Const {
          match name {
            Some(n) => {
              let cleaned = extract_string_value(value)
              if n == "title" && not(cleaned.is_empty()) {
                fm = { ..fm, title: Some(cleaned) }
              } else if n == "description" && not(cleaned.is_empty()) {
                fm = { ..fm, description: Some(cleaned) }
              }
            }
            None => ()
          }
        }
      _ => ()
    }
  }
  fm
}

///|
/// Extract string value from JavaScript expression
/// "\"hello\"" -> "hello"
/// "'hello'" -> "hello"
fn extract_string_value(value : String) -> String {
  let trimmed = value.trim(chars=" \t\n\r").to_string()
  let chars = trimmed.to_array()
  let len = chars.length()
  if len < 2 {
    return trimmed
  }
  let first = chars[0]
  let last = chars[len - 1]
  // Check for quoted string
  if (first == '"' || first == '\'') && first == last {
    // Remove quotes
    let buf = StringBuilder::new()
    for i = 1; i < len - 1; i = i + 1 {
      buf.write_char(chars[i])
    }
    return buf.to_string()
  }
  // Check for template literal
  if first == '`' && last == '`' {
    let buf = StringBuilder::new()
    for i = 1; i < len - 1; i = i + 1 {
      buf.write_char(chars[i])
    }
    return buf.to_string()
  }
  trimmed
}

// =============================================================================
// Document Conversion with MDX
// =============================================================================

///|
/// Convert document blocks to MdNode array, handling MDX blocks
fn convert_document_with_mdx(
  doc : @md_parser.Document,
  mdx_blocks : Array[@md_mdx.MdxBlock],
) -> Array[@ssg.MdNode] {
  let nodes : Array[@ssg.MdNode] = []
  for block in doc.children {
    // Check if this block is an MDX block
    match find_mdx_block_for_cst_block(block, mdx_blocks) {
      Some(mdx_block) =>
        // Convert MDX block to MdNode
        match convert_mdx_block(mdx_block) {
          Some(node) => nodes.push(node)
          None => () // Skip import/export declarations
        }
      None =>
        // Use standard CST conversion
        match convert_cst_block(block) {
          Some(node) => nodes.push(node)
          None => ()
        }
    }
  }
  nodes
}

///|
/// Find MDX block that corresponds to a CST block (by span)
fn find_mdx_block_for_cst_block(
  block : @md_parser.Block,
  mdx_blocks : Array[@md_mdx.MdxBlock],
) -> @md_mdx.MdxBlock? {
  let block_span = get_block_span(block)
  for mdx in mdx_blocks {
    let mdx_span = mdx.span()
    if spans_overlap(block_span, mdx_span) {
      return Some(mdx)
    }
  }
  None
}

///|
/// Get span from a CST block
fn get_block_span(block : @md_parser.Block) -> @md_parser.Span {
  match block {
    @md_parser.Block::ThematicBreak(span~, ..) => span
    @md_parser.Block::Heading(span~, ..) => span
    @md_parser.Block::Paragraph(span~, ..) => span
    @md_parser.Block::FencedCode(span~, ..) => span
    @md_parser.Block::IndentedCode(span~, ..) => span
    @md_parser.Block::Blockquote(span~, ..) => span
    @md_parser.Block::BulletList(span~, ..) => span
    @md_parser.Block::OrderedList(span~, ..) => span
    @md_parser.Block::HtmlBlock(span~, ..) => span
    @md_parser.Block::Table(span~, ..) => span
    @md_parser.Block::BlankLines(span~, ..) => span
    @md_parser.Block::FootnoteDefinition(span~, ..) => span
  }
}

///|
/// Check if two spans overlap
fn spans_overlap(a : @md_parser.Span, b : @md_parser.Span) -> Bool {
  // Spans overlap if they share any characters
  a.from < b.to && b.from < a.to
}

// =============================================================================
// MDX Block Conversion
// =============================================================================

///|
/// Convert MDX block to MdNode
/// Returns None for import/export (they don't render)
fn convert_mdx_block(block : @md_mdx.MdxBlock) -> @ssg.MdNode? {
  match block {
    @md_mdx.MdxBlock::ImportDecl(..) => None // Imports don't render
    @md_mdx.MdxBlock::ExportDecl(..) => None // Exports don't render
    @md_mdx.MdxBlock::JsxElement(
      tag~,
      attributes~,
      children~,
      self_closing~,
      ..
    ) => {
      // Convert to JsxComponentEmbed
      let embed = convert_jsx_to_embed(tag, attributes, children, self_closing)
      Some(@ssg.MdNode::JsxComponent(embed))
    }
  }
}

///|
/// Convert JSX element to JsxComponentEmbed
fn convert_jsx_to_embed(
  tag : String,
  attributes : Array[@md_mdx.MdxAttribute],
  children : String,
  self_closing : Bool,
) -> @ssg.JsxComponentEmbed {
  // Convert attributes
  let attrs : Array[(String, @ssg.MdxAttrValue)] = []
  let mut cls_hints : @ssg.ClsHints? = None
  let mut width : String? = None
  let mut height : String? = None
  for attr in attributes {
    let key = attr.name
    let value = convert_attr_value(attr.value)
    // Check for CLS hints
    if key == "cls:width" {
      width = Some(mdx_attr_to_string(value))
    } else if key == "cls:height" {
      height = Some(mdx_attr_to_string(value))
    } else {
      attrs.push((key, value))
    }
  }

  // Build CLS hints if any
  if width is Some(_) || height is Some(_) {
    cls_hints = Some(@ssg.ClsHints::{ width, height })
  }
  @ssg.JsxComponentEmbed::{ tag, attrs, children, self_closing, cls_hints }
}

///|
/// Convert MDX attribute value to Astra MdxAttrValue
fn convert_attr_value(value : @md_mdx.MdxAttrValue) -> @ssg.MdxAttrValue {
  match value {
    @md_mdx.MdxAttrValue::StringValue(s) =>
      @ssg.MdxAttrValue::StringLiteral(s)
    @md_mdx.MdxAttrValue::ExpressionValue(e) =>
      @ssg.MdxAttrValue::Expression(e)
    @md_mdx.MdxAttrValue::BooleanValue => @ssg.MdxAttrValue::Boolean
  }
}

///|
/// Convert MdxAttrValue to string
fn mdx_attr_to_string(value : @ssg.MdxAttrValue) -> String {
  match value {
    @ssg.MdxAttrValue::StringLiteral(s) => s
    @ssg.MdxAttrValue::Expression(e) => e
    @ssg.MdxAttrValue::Boolean => "true"
  }
}

// =============================================================================
// Standard CST Block Conversion (delegate to @cst)
// =============================================================================

///|
/// Convert standard CST block to MdNode
/// This reuses the convert_block function logic from @cst
fn convert_cst_block(block : @md_parser.Block) -> @ssg.MdNode? {
  match block {
    @md_parser.Block::ThematicBreak(..) => Some(@ssg.MdNode::ThematicBreak)
    @md_parser.Block::Heading(level~, children~, ..) => {
      let md_children = convert_inlines(children)
      let text = @md_toc.extract_text_from_inlines(children)
      let id = @slug.generate_heading_id(text)
      Some(@ssg.MdNode::Heading(level~, children=md_children, id~))
    }
    @md_parser.Block::Paragraph(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Paragraph(children=md_children))
    }
    @md_parser.Block::FencedCode(info~, code~, ..) =>
      Some(@ssg.MdNode::CodeBlock(lang=info, code~))
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
    @md_parser.Block::HtmlBlock(html~, ..) => Some(@ssg.MdNode::Html(html))
    @md_parser.Block::Table(header~, rows~, ..) => {
      let md_headers = header.map(fn(cell) {
        let children = convert_inlines(cell.children)
        if children.length() == 1 {
          children[0]
        } else {
          @ssg.MdNode::Text(@md_toc.extract_text_from_inlines(cell.children))
        }
      })
      let md_rows = rows.map(fn(row) {
        row.map(fn(cell) {
          let children = convert_inlines(cell.children)
          if children.length() == 1 {
            children[0]
          } else {
            @ssg.MdNode::Text(
              @md_toc.extract_text_from_inlines(cell.children),
            )
          }
        })
      })
      Some(@ssg.MdNode::Table(headers=md_headers, rows=md_rows))
    }
    @md_parser.Block::BlankLines(..) => None
    @md_parser.Block::FootnoteDefinition(..) => None
  }
}

///|
fn convert_blocks(blocks : Array[@md_parser.Block]) -> Array[@ssg.MdNode] {
  let nodes : Array[@ssg.MdNode] = []
  for block in blocks {
    match convert_cst_block(block) {
      Some(node) => nodes.push(node)
      None => ()
    }
  }
  nodes
}

///|
fn convert_list_items(
  items : Array[@md_parser.ListItem],
) -> Array[Array[@ssg.MdNode]] {
  items.map(fn(item) { convert_blocks(item.children) })
}

///|
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

///|
fn convert_inline(inline : @md_parser.Inline) -> @ssg.MdNode? {
  match inline {
    @md_parser.Inline::Text(content~, ..) => Some(@ssg.MdNode::Text(content))
    @md_parser.Inline::SoftBreak(..) => Some(@ssg.MdNode::Text(" "))
    @md_parser.Inline::HardBreak(..) => Some(@ssg.MdNode::LineBreak)
    @md_parser.Inline::Emphasis(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Italic(children=md_children))
    }
    @md_parser.Inline::Strong(children~, ..) => {
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Bold(children=md_children))
    }
    @md_parser.Inline::Strikethrough(children~, ..) => {
      let text = "~~" + @md_toc.extract_text_from_inlines(children) + "~~"
      Some(@ssg.MdNode::Text(text))
    }
    @md_parser.Inline::Code(content~, ..) => Some(@ssg.MdNode::Code(content))
    @md_parser.Inline::Link(children~, url~, title~, ..) => {
      let md_children = convert_inlines(children)
      Some(@ssg.MdNode::Link(href=url, title~, children=md_children))
    }
    @md_parser.Inline::RefLink(children~, label~, ..) => {
      let md_children = convert_inlines(children)
      Some(
        @ssg.MdNode::Link(href="#" + label, title="", children=md_children),
      )
    }
    @md_parser.Inline::Autolink(url~, ..) => {
      let children = [@ssg.MdNode::Text(url)]
      Some(@ssg.MdNode::Link(href=url, title="", children~))
    }
    @md_parser.Inline::Image(alt~, url~, title~, ..) =>
      Some(@ssg.MdNode::Image(src=url, alt~, title~))
    @md_parser.Inline::RefImage(alt~, label~, ..) =>
      Some(@ssg.MdNode::Image(src="#" + label, alt~, title=""))
    @md_parser.Inline::HtmlInline(html~, ..) => Some(@ssg.MdNode::Html(html))
    @md_parser.Inline::FootnoteReference(label~, ..) =>
      Some(@ssg.MdNode::Text("[^\{label}]"))
  }
}
