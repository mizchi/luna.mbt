///| HTML/Attribute/JS String Escaping Utilities
///|
///| Cross-platform implementation with target-specific optimizations:
///| - JS target: Uses native String.replace (fastest)
///| - WASM/Native: Pure MoonBit implementation

// =============================================================================
// HTML Escaping - Public API
// =============================================================================

///|
/// Check if string needs HTML escaping
pub fn needs_html_escape(s : String) -> Bool {
  for char in s {
    match char {
      '&' | '<' | '>' | '"' | '\'' => return true
      _ => ()
    }
  }
  false
}

///|
/// Escape HTML special characters and write to StringBuilder
pub fn escape_html_to(sb : StringBuilder, s : String) -> Unit {
  escape_html_to_internal(sb, s)
}

///|
/// Escape HTML and return new string
pub fn escape_html(s : String) -> String {
  escape_html_internal(s)
}

// =============================================================================
// Attribute Escaping - Public API
// =============================================================================

///|
/// Check if string needs attribute escaping (subset of HTML)
pub fn needs_attr_escape(s : String) -> Bool {
  for char in s {
    match char {
      '&' | '"' => return true
      _ => ()
    }
  }
  false
}

///|
/// Escape attribute value and write to StringBuilder
pub fn escape_attr_to(sb : StringBuilder, s : String) -> Unit {
  escape_attr_to_internal(sb, s)
}

///|
/// Escape attribute and return new string
pub fn escape_attr(s : String) -> String {
  escape_attr_internal(s)
}

// =============================================================================
// JavaScript String Escaping - Public API
// =============================================================================

///|
/// Escape JS string for embedding in script tags
/// Handles </script> injection prevention
pub fn escape_js_string(s : String) -> String {
  escape_js_string_internal(s)
}

///|
/// Escape JS string and write to StringBuilder
pub fn escape_js_string_to(sb : StringBuilder, s : String) -> Unit {
  escape_js_string_to_internal(sb, s)
}

// =============================================================================
// Void Element Check (shared across all targets)
// =============================================================================

///|
/// Check if HTML tag is a void (self-closing) element
/// Optimized with length check and first char dispatch
pub fn is_void_element(tag : String) -> Bool {
  let len = tag.length()
  // Fast reject: most common tags are not void elements
  // void elements have length 2-6
  if len < 2 || len > 6 {
    return false
  }
  // Check by length first, then by content
  match len {
    2 => tag == "br" || tag == "hr"
    3 => tag == "img" || tag == "col" || tag == "wbr"
    4 => tag == "area" || tag == "base" || tag == "link" || tag == "meta"
    5 => tag == "embed" || tag == "input" || tag == "track" || tag == "param"
    6 => tag == "source" || tag == "keygen"
    _ => false
  }
}
