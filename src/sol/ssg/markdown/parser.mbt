///| Markdown Parser - Pure MoonBit Implementation
///| Uses the CST-based parser from @md_parser for parsing

// =============================================================================
// Markdown Parsing
// =============================================================================

///| Parse markdown content and return frontmatter + AST
///| This uses the native MoonBit parser (no external dependencies)
pub fn parse_markdown(content : String) -> (@ssg.Frontmatter, Array[@ssg.MdNode]) {
  parse_markdown_native(content)
}

// =============================================================================
// Island Directive Parsing
// =============================================================================

///| Parse Island directive from HTML string
/// Format: <Island name="counter" :props='{"initial": 0}' trigger="visible" />
fn parse_island_directive(html : String) -> @ssg.IslandEmbed? {
  let trimmed = html.trim_space().to_string()
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

  Some(@ssg.IslandEmbed::{ name, props, trigger })
}

///| Extract attribute value from HTML tag
fn extract_attribute(html : String, attr_name : String) -> String? {
  // Look for attr_name="..." or attr_name='...'
  let pattern1 = attr_name + "=\""
  let pattern2 = attr_name + "='"

  match html.find(pattern1) {
    Some(start) => {
      let value_start = start + pattern1.length()
      let remaining = html.unsafe_substring(start=value_start, end=html.length())
      match remaining.find("\"") {
        Some(end_pos) => Some(remaining.unsafe_substring(start=0, end=end_pos))
        None => None
      }
    }
    None =>
      match html.find(pattern2) {
        Some(start) => {
          let value_start = start + pattern2.length()
          let remaining = html.unsafe_substring(start=value_start, end=html.length())
          match remaining.find("'") {
            Some(end_pos) => Some(remaining.unsafe_substring(start=0, end=end_pos))
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

///| Generate heading ID from text (for anchor links)
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
