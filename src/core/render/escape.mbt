// HTML/Attribute/JS String Escaping Utilities
//
// Basic escape functions are re-exported from mizchi/signals/ui/render.
// Luna-specific JSON escaping functions are defined here.

// =============================================================================
// Re-export from signals/ui/render
// =============================================================================

///|
/// Check if string needs HTML escaping
pub fn needs_html_escape(s : String) -> Bool {
  @ui_render.needs_html_escape(s)
}

///|
/// Escape HTML special characters and write to StringBuilder
pub fn escape_html_to(sb : StringBuilder, s : String) -> Unit {
  @ui_render.escape_html_to(sb, s)
}

///|
/// Escape HTML and return new string
pub fn escape_html(s : String) -> String {
  @ui_render.escape_html(s)
}

///|
/// Check if string needs attribute escaping (subset of HTML)
pub fn needs_attr_escape(s : String) -> Bool {
  @ui_render.needs_attr_escape(s)
}

///|
/// Escape attribute value and write to StringBuilder
pub fn escape_attr_to(sb : StringBuilder, s : String) -> Unit {
  @ui_render.escape_attr_to(sb, s)
}

///|
/// Escape attribute and return new string
pub fn escape_attr(s : String) -> String {
  @ui_render.escape_attr(s)
}

///|
/// Escape JS string for embedding in script tags
/// Handles </script> injection prevention
pub fn escape_js_string(s : String) -> String {
  @ui_render.escape_js_string(s)
}

///|
/// Escape JS string and write to StringBuilder
pub fn escape_js_string_to(sb : StringBuilder, s : String) -> Unit {
  @ui_render.escape_js_string_to(sb, s)
}

///|
/// Check if HTML tag is a void (self-closing) element
pub fn is_void_element(tag : String) -> Bool {
  @ui_render.is_void_element(tag)
}

// =============================================================================
// JSON Escaping for HTML embedding - Luna-specific
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
