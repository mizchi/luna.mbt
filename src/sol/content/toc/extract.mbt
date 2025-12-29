// Table of Contents and Description Extraction
// Extract structured data from MdNode arrays

// =============================================================================
// Table of Contents Extraction
// =============================================================================

///|
/// Extract table of contents from MdNode array
pub fn extract_toc(nodes : Array[@markdown.MdNode]) -> Array[TocItem] {
  let toc : Array[TocItem] = []
  extract_toc_recursive(nodes, toc)
  toc
}

///|
/// Extract headings recursively
fn extract_toc_recursive(
  nodes : Array[@markdown.MdNode],
  toc : Array[TocItem],
) -> Unit {
  for node in nodes {
    match node {
      @markdown.MdNode::Heading(level~, children~, id~) =>
        // Only include h2-h4 in TOC
        if level >= 2 && level <= 4 {
          let text = extract_text_from_nodes(children)
          toc.push(TocItem::{ level, text, id })
        }
      @markdown.MdNode::Blockquote(children~) =>
        extract_toc_recursive(children, toc)
      @markdown.MdNode::List(items~, ..) =>
        for item in items {
          extract_toc_recursive(item, toc)
        }
      _ => ()
    }
  }
}

// =============================================================================
// Description Extraction (for meta description)
// =============================================================================

///|
/// Extract description from markdown nodes
/// Returns the first paragraph's text, truncated to max_length
pub fn extract_description(
  nodes : Array[@markdown.MdNode],
  max_length? : Int = 160,
) -> String? {
  // Find the first paragraph
  for node in nodes {
    match node {
      @markdown.MdNode::Paragraph(children~) => {
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
// Text Extraction from MdNode
// =============================================================================

///|
/// Extract plain text from MdNode array
pub fn extract_text_from_nodes(nodes : Array[@markdown.MdNode]) -> String {
  let buf = StringBuilder::new()
  for node in nodes {
    extract_text_recursive(node, buf)
  }
  buf.to_string()
}

///|
/// Extract text recursively
fn extract_text_recursive(node : @markdown.MdNode, buf : StringBuilder) -> Unit {
  match node {
    @markdown.MdNode::Text(text) => buf.write_string(text)
    @markdown.MdNode::Bold(children~) | @markdown.MdNode::Italic(children~) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    @markdown.MdNode::Code(code) => buf.write_string(code)
    @markdown.MdNode::Link(children~, ..) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    _ => ()
  }
}
