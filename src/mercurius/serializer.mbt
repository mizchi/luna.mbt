///| State Serialization with XSS Prevention

///|

///| Safely serialize state for embedding in HTML.

///| Prevents XSS attacks from malicious state values.

///|
/// Check if JSON string contains characters that need escaping for HTML attribute
fn needs_html_attr_escape(s : String) -> Bool {
  // Check for characters that need escaping in HTML attributes
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
pub fn escape_json_for_html(json : String) -> String {
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
  if not(needs_html_attr_escape(json)) {
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

///|
/// Format state for ln:state attribute
/// Returns the attribute value based on StateConfig
pub fn format_state_attr(state : StateConfig) -> String? {
  match state {
    Empty => None
    Inline(json) => Some(escape_json_for_attr(json))
    ScriptRef(id) => Some("#" + id)
    Url(url) => Some("url:" + url)
  }
}

///|
/// Generate a <script type="ln/json"> element for state
/// Used when state is too large for inline attribute
pub fn generate_state_script(id : String, json : String) -> String {
  let escaped = escape_json_for_html(json)
  let sb = StringBuilder::new(size_hint=escaped.length() + 64)
  sb.write_string("<script id=\"")
  sb.write_string(id)
  sb.write_string("\" type=\"ln/json\">")
  sb.write_string(escaped)
  sb.write_string("</script>")
  sb.to_string()
}

///|
/// Recommended state format based on size
/// - < 1KB: Inline in attribute
/// - 1KB - 100KB: Script reference
/// - > 100KB: URL reference (needs server support)
pub fn recommend_state_format(json_size : Int) -> String {
  if json_size < 1024 {
    "inline"
  } else if json_size < 102400 {
    "script_ref"
  } else {
    "url"
  }
}
