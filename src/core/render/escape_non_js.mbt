///| Non-JS Target Implementation - Pure MoonBit for WASM and Native

// =============================================================================
// Internal Implementation (called from escape.mbt)
// =============================================================================

///|
fn escape_html_internal(s : String) -> String {
  if not(needs_html_escape(s)) {
    return s
  }
  let sb = StringBuilder::new(size_hint=s.length() + 16)
  escape_html_to_impl(sb, s)
  sb.to_string()
}

///|
fn escape_html_to_internal(sb : StringBuilder, s : String) -> Unit {
  if not(needs_html_escape(s)) {
    sb.write_string(s)
    return
  }
  escape_html_to_impl(sb, s)
}

///|
fn escape_html_to_impl(sb : StringBuilder, s : String) -> Unit {
  for char in s {
    match char {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
      _ => sb.write_char(char)
    }
  }
}

///|
fn escape_attr_internal(s : String) -> String {
  if not(needs_attr_escape(s)) {
    return s
  }
  let sb = StringBuilder::new(size_hint=s.length() + 8)
  escape_attr_to_impl(sb, s)
  sb.to_string()
}

///|
fn escape_attr_to_internal(sb : StringBuilder, s : String) -> Unit {
  if not(needs_attr_escape(s)) {
    sb.write_string(s)
    return
  }
  escape_attr_to_impl(sb, s)
}

///|
fn escape_attr_to_impl(sb : StringBuilder, s : String) -> Unit {
  for char in s {
    match char {
      '&' => sb.write_string("&amp;")
      '"' => sb.write_string("&quot;")
      _ => sb.write_char(char)
    }
  }
}

///|
fn escape_js_string_internal(s : String) -> String {
  let sb = StringBuilder::new(size_hint=s.length() + 16)
  escape_js_string_to_impl(sb, s)
  sb.to_string()
}

///|
fn escape_js_string_to_internal(sb : StringBuilder, s : String) -> Unit {
  escape_js_string_to_impl(sb, s)
}

///|
fn escape_js_string_to_impl(sb : StringBuilder, s : String) -> Unit {
  for char in s {
    match char {
      '\\' => sb.write_string("\\\\")
      '"' => sb.write_string("\\\"")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      '<' => sb.write_string("\\u003c")
      '>' => sb.write_string("\\u003e")
      _ => sb.write_char(char)
    }
  }
}
