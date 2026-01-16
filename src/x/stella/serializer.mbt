// State Serialization with XSS Prevention
//
// Safely serialize state for embedding in HTML.
// Prevents XSS attacks from malicious state values.
//
// Note: Escape functions are now delegated to @render module.
// The functions here are kept for backward compatibility.

///|
/// Format state for luna:state attribute
/// Returns the attribute value based on StateConfig
pub fn format_state_attr(state : StateConfig) -> String? {
  match state {
    Empty => None
    Inline(json) => Some(@render.escape_json_for_attr(json))
    ScriptRef(id) => Some("#" + id)
    Url(url) => Some("url:" + url)
  }
}

///|
/// Generate a <script type="luna/json"> element for state
/// Used when state is too large for inline attribute
pub fn generate_state_script(id : String, json : String) -> String {
  let escaped = @render.escape_json_for_script(json)
  let sb = StringBuilder::new(size_hint=escaped.length() + 64)
  sb.write_string("<script id=\"")
  sb.write_string(id)
  sb.write_string("\" type=\"luna/json\">")
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
