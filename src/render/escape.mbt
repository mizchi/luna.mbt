// HTML/Attribute/JS String Escaping Utilities
//
// Cross-platform implementation with target-specific optimizations:
// - JS target: Uses native String.replace (fastest)
// - WASM/Native: Pure MoonBit implementation

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
// JSON Escaping for HTML embedding - Public API
// =============================================================================

///|
/// Check if JSON string needs escaping for HTML attribute
fn needs_json_attr_escape(s : String) -> Bool {
  s.iter().any(fn(c) { c == '"' || c == '&' || c == '<' || c == '>' })
}

///|
/// Escape JSON for safe embedding in HTML <script> tags
///
/// Prevents XSS by escaping:
/// - `</` -> `<\/` (prevents </script> injection)
/// - `<s` / `<S` -> `<\u0073` / `<\u0053` (additional safety)
///
/// Reference: https://sophiebits.com/2012/08/03/preventing-xss-json
pub fn escape_json_for_script(json : String) -> String {
  let chars = json.to_array()
  let len = chars.length()

  // Check if escaping is needed
  let mut needs_escape = false
  for i, c in chars {
    if c == '<' && i + 1 < len {
      let next = chars[i + 1]
      if next == '/' || next == 's' || next == 'S' {
        needs_escape = true
        break
      }
    }
  }
  if not(needs_escape) {
    return json
  }

  // Slow path: build escaped string
  let sb = StringBuilder::new(size_hint=json.length() + 16)
  let mut i = 0
  while i < len {
    let c = chars[i]
    if c == '<' && i + 1 < len {
      let next = chars[i + 1]
      if next == '/' {
        sb.write_string("<\\/")
        i = i + 2
        continue
      } else if next == 's' {
        sb.write_string("<\\u0073")
        i = i + 2
        continue
      } else if next == 'S' {
        sb.write_string("<\\u0053")
        i = i + 2
        continue
      }
    }
    sb.write_char(c)
    i = i + 1
  }
  sb.to_string()
}

///|
/// Escape JSON for safe embedding in HTML attribute values
///
/// Escapes:
/// - `"` -> `&quot;`
/// - `&` -> `&amp;`
/// - `<` -> `&lt;`
/// - `>` -> `&gt;`
pub fn escape_json_for_attr(json : String) -> String {
  if not(needs_json_attr_escape(json)) {
    return json
  }
  let sb = StringBuilder::new(size_hint=json.length() + 32)
  for c in json {
    match c {
      '"' => sb.write_string("&quot;")
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
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
