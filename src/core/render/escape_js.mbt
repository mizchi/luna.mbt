///| JS Target Implementation - Uses native String.replace for best performance
///|
///| Benchmark results show JS FFI is 3-38x faster than pure MoonBit iteration

// =============================================================================
// JS FFI Functions
// =============================================================================

///|
extern "js" fn ffi_escape_html(s : String) -> String =
  #| (s) => s.replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))

///|
extern "js" fn ffi_escape_attr(s : String) -> String =
  #| (s) => s.replace(/[&"]/g, c => ({'&':'&amp;','"':'&quot;'}[c]))

///|
extern "js" fn ffi_escape_js_string(s : String) -> String =
  #| (s) => s.replace(/[\\"\n\r\t<>]/g, c => ({'\\':'\\\\','"':'\\"','\n':'\\n','\r':'\\r','\t':'\\t','<':'\\u003c','>':'\\u003e'}[c]))

// =============================================================================
// Internal Implementation (called from escape.mbt)
// =============================================================================

///|
fn escape_html_internal(s : String) -> String {
  ffi_escape_html(s)
}

///|
fn escape_html_to_internal(sb : StringBuilder, s : String) -> Unit {
  sb.write_string(ffi_escape_html(s))
}

///|
fn escape_attr_internal(s : String) -> String {
  ffi_escape_attr(s)
}

///|
fn escape_attr_to_internal(sb : StringBuilder, s : String) -> Unit {
  sb.write_string(ffi_escape_attr(s))
}

///|
fn escape_js_string_internal(s : String) -> String {
  ffi_escape_js_string(s)
}

///|
fn escape_js_string_to_internal(sb : StringBuilder, s : String) -> Unit {
  sb.write_string(ffi_escape_js_string(s))
}
