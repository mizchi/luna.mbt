// Markdown Parser - Pure MoonBit Implementation
// Uses the CST-based parser from @md_parser for parsing

// =============================================================================
// Markdown Parsing
// =============================================================================

///| Parse markdown content and return frontmatter + AST

///|
/// This uses the native MoonBit parser (no external dependencies)
pub fn parse_markdown(
  content : String,
) -> (@astra.Frontmatter, Array[@astra.MdNode]) {
  parse_markdown_native(content)
}

// =============================================================================
// Island Directive Parsing (legacy)
// =============================================================================

///|
/// Parse Island directive from HTML string
/// Format: <Island name="counter" :props='{"initial": 0}' trigger="visible" />
fn parse_island_directive(html : String) -> @astra.IslandEmbed? {
  let trimmed = html.trim().to_string()
  if not(trimmed.has_prefix("<Island")) && not(trimmed.has_prefix("<island")) {
    return None
  }

  // Extract name attribute
  let name = match extract_attribute(trimmed, "name") {
    Some(n) => n
    None => return None
  }

  // Extract props attribute (may use :props or props)
  let props = match extract_attribute(trimmed, ":props") {
    Some(p) => p
    None =>
      match extract_attribute(trimmed, "props") {
        Some(p) => p
        None => "{}"
      }
  }

  // Extract trigger attribute
  let trigger = match extract_attribute(trimmed, "trigger") {
    Some("visible") => @luna.Visible
    Some("idle") => @luna.Idle
    Some("media") => @luna.Media("")
    _ => @luna.Load
  }
  Some(@astra.IslandEmbed::{ name, props, trigger, ssr: false })
}

// =============================================================================
// Web Component Parsing
// =============================================================================

///|
/// Parse custom element tag from HTML string
/// Custom elements must have a hyphen in their name (e.g., <my-counter>, <foo-bar>)
/// Supports luna:trigger attribute for hydration timing
fn parse_custom_element(html : String) -> @astra.ComponentEmbed? {
  let trimmed = html.trim().to_string()
  if not(trimmed.has_prefix("<")) {
    return None
  }

  // Extract tag name
  let tag = match extract_tag_name(trimmed) {
    Some(t) => t
    None => return None
  }

  // Custom elements must contain a hyphen
  if not(tag.contains("-")) {
    return None
  }

  // Extract all attributes
  let attrs = extract_all_attributes(trimmed)

  // Extract trigger (luna:trigger attribute)
  let trigger = match extract_attribute(trimmed, "luna:trigger") {
    Some("visible") => @luna.Visible
    Some("idle") => @luna.Idle
    Some("media") => @luna.Media("")
    Some("none") => @luna.None
    _ => @luna.Load
  }

  // Extract inner content (if not self-closing)
  let content = extract_inner_content(trimmed, tag)
  Some(@astra.ComponentEmbed::{ tag, attrs, content, trigger })
}

///|
/// Extract tag name from HTML element
fn extract_tag_name(html : String) -> String? {
  if not(html.has_prefix("<")) {
    return None
  }
  // Skip the opening <
  let rest = html.unsafe_substring(start=1, end=html.length())
  let buf = StringBuilder::new()
  for c in rest {
    if c == ' ' || c == '>' || c == '/' {
      break
    }
    buf.write_char(c)
  }
  let tag = buf.to_string()
  if tag.is_empty() {
    None
  } else {
    Some(tag)
  }
}

///|
/// Extract all attributes from HTML element (excluding luna:trigger)
fn extract_all_attributes(html : String) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = []

  // Find the end of tag name
  let tag_end = match html.find(" ") {
    Some(idx) => idx
    None => return attrs
  }

  // Find the end of attributes (> or />)
  let attr_end = match html.find(">") {
    Some(idx) => idx
    None => html.length()
  }
  let attr_str = html.unsafe_substring(start=tag_end, end=attr_end)

  // Simple attribute parsing: key="value" or key='value'
  let mut i = 0
  let chars = attr_str.to_array()
  let len = chars.length()
  while i < len {
    // Skip whitespace
    while i < len && (chars[i] == ' ' || chars[i] == '\n' || chars[i] == '\t') {
      i = i + 1
    }
    if i >= len {
      break
    }

    // Skip self-closing /
    if chars[i] == '/' {
      break
    }

    // Read attribute name
    let name_buf = StringBuilder::new()
    while i < len &&
          chars[i] != '=' &&
          chars[i] != ' ' &&
          chars[i] != '>' &&
          chars[i] != '/' {
      name_buf.write_char(chars[i])
      i = i + 1
    }
    let attr_name = name_buf.to_string()
    if attr_name.is_empty() {
      break
    }

    // Check for =
    if i < len && chars[i] == '=' {
      i = i + 1 // skip =

      // Get quote character
      if i < len && (chars[i] == '"' || chars[i] == '\'') {
        let quote = chars[i]
        i = i + 1 // skip opening quote

        // Read value
        let value_buf = StringBuilder::new()
        while i < len && chars[i] != quote {
          value_buf.write_char(chars[i])
          i = i + 1
        }
        if i < len {
          i = i + 1 // skip closing quote
        }
        let attr_value = value_buf.to_string()
        // Skip luna:trigger (handled separately)
        if attr_name != "luna:trigger" {
          attrs.push((attr_name, attr_value))
        }
      }
      // Boolean attribute (no value)
    } else if attr_name != "luna:trigger" {
      attrs.push((attr_name, ""))
    }
  }
  attrs
}

///|
/// Extract inner content from HTML element
fn extract_inner_content(html : String, tag : String) -> String {
  // Check if self-closing
  if html.has_suffix("/>") {
    return ""
  }

  // Find end of opening tag
  let open_end = match html.find(">") {
    Some(idx) => idx + 1
    None => return ""
  }

  // Find closing tag
  let close_tag = "</" + tag + ">"
  match html.find(close_tag) {
    Some(close_start) => html.unsafe_substring(start=open_end, end=close_start)
    None => ""
  }
}

///|
/// Extract attribute value from HTML tag
fn extract_attribute(html : String, attr_name : String) -> String? {
  // Look for attr_name="..." or attr_name='...'
  let pattern1 = attr_name + "=\""
  let pattern2 = attr_name + "='"
  match html.find(pattern1) {
    Some(start) => {
      let value_start = start + pattern1.length()
      let remaining = html.unsafe_substring(
        start=value_start,
        end=html.length(),
      )
      match remaining.find("\"") {
        Some(end_pos) => Some(remaining.unsafe_substring(start=0, end=end_pos))
        None => None
      }
    }
    None =>
      match html.find(pattern2) {
        Some(start) => {
          let value_start = start + pattern2.length()
          let remaining = html.unsafe_substring(
            start=value_start,
            end=html.length(),
          )
          match remaining.find("'") {
            Some(end_pos) =>
              Some(remaining.unsafe_substring(start=0, end=end_pos))
            None => None
          }
        }
        None => None
      }
  }
}

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Generate heading ID from text (for anchor links)
fn generate_heading_id(text : String) -> String {
  let buf = StringBuilder::new()
  let lower = text.to_lower()
  let mut prev_was_separator = false
  for c in lower {
    if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') {
      buf.write_char(c)
      prev_was_separator = false
    } else if c == ' ' || c == '-' || c == '_' {
      // Avoid multiple consecutive separators
      if not(prev_was_separator) {
        buf.write_char('-')
        prev_was_separator = true
      }
    } else if c.to_uint() > 127 {
      // Keep non-ASCII characters (Japanese, Chinese, etc.)
      buf.write_char(c)
      prev_was_separator = false
    }
    // Skip other ASCII special characters
  }

  // Remove trailing separator
  let result = buf.to_string()
  if result.has_suffix("-") {
    result.unsafe_substring(start=0, end=result.length() - 1)
  } else {
    result
  }
}
