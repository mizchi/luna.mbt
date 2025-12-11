///| HTML State Embedding - Embed and extract state from HTML

///|
/// State script tag attribute name
let state_attr : String = "data-resumable-state"

///|
/// Generate script tag with embedded state (global state, no ID)
pub fn state_to_script_tag(state : ResumableState) -> String {
  let json = state.to_json()
  "<script type=\"application/json\" " +
  state_attr +
  ">" +
  escape_html_content(json) +
  "</script>"
}

///|
/// Generate script tag with embedded state and ID
pub fn state_to_script_tag_with_id(state : ResumableState, id : String) -> String {
  let json = state.to_json()
  "<script type=\"application/json\" " +
  state_attr +
  "=\"" +
  id +
  "\">" +
  escape_html_content(json) +
  "</script>"
}

///|
/// Generate a container div with state endpoint for lazy loading
pub fn state_endpoint_tag(id : String, endpoint : String, content : String) -> String {
  "<div data-state-id=\"" +
  id +
  "\" data-state-src=\"" +
  endpoint +
  "\">" +
  content +
  "</div>"
}

///|
/// Escape HTML special characters in content
fn escape_html_content(s : String) -> String {
  let buf = StringBuilder::new()
  for char in s {
    match char {
      '<' => buf.write_string("\\u003c")
      '>' => buf.write_string("\\u003e")
      '&' => buf.write_string("\\u0026")
      _ => buf.write_char(char)
    }
  }
  buf.to_string()
}

///|
/// Extract state JSON from HTML string
pub fn extract_state_from_html(html : String) -> String? {
  // Find the script tag with data-resumable-state
  let start_marker = "<script type=\"application/json\" " + state_attr + ">"
  let end_marker = "</script>"
  // Find start position
  let mut start_pos : Int? = None
  let html_len = html.length()
  let start_len = start_marker.length()
  for i = 0; i <= html_len - start_len; i = i + 1 {
    if substring_matches(html, i, start_marker) {
      start_pos = Some(i + start_len)
      break
    }
  }
  let start = match start_pos {
    Some(pos) => pos
    None => return None
  }
  // Find end position
  let end_len = end_marker.length()
  for i = start; i <= html_len - end_len; i = i + 1 {
    if substring_matches(html, i, end_marker) {
      // Extract the JSON content
      let json = extract_substring(html, start, i)
      return Some(unescape_html_content(json))
    }
  }
  None
}

///|
/// Check if substring matches at position
fn substring_matches(s : String, pos : Int, pattern : String) -> Bool {
  let s_len = s.length()
  let p_len = pattern.length()
  if pos + p_len > s_len {
    return false
  }
  let s_iter = s.iter()
  let p_iter = pattern.iter()
  // Skip to position
  let s_chars : Array[Char] = []
  let mut idx = 0
  for c in s_iter {
    if idx >= pos && idx < pos + p_len {
      s_chars.push(c)
    }
    idx = idx + 1
    if idx >= pos + p_len {
      break
    }
  }
  // Compare with pattern
  idx = 0
  for c in p_iter {
    if idx >= s_chars.length() || s_chars[idx] != c {
      return false
    }
    idx = idx + 1
  }
  true
}

///|
/// Extract substring from start to end position
fn extract_substring(s : String, start : Int, end : Int) -> String {
  let buf = StringBuilder::new()
  let mut idx = 0
  for c in s {
    if idx >= start && idx < end {
      buf.write_char(c)
    }
    idx = idx + 1
    if idx >= end {
      break
    }
  }
  buf.to_string()
}

///|
/// Unescape HTML entities in content
fn unescape_html_content(s : String) -> String {
  let buf = StringBuilder::new()
  let chars : Array[Char] = []
  for c in s {
    chars.push(c)
  }
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '\\' && i + 5 < chars.length() && chars[i + 1] == 'u' {
      // Check for \u003c, \u003e, \u0026
      let code = [chars[i + 2], chars[i + 3], chars[i + 4], chars[i + 5]]
      if code[0] == '0' && code[1] == '0' && code[2] == '3' && code[3] == 'c' {
        buf.write_char('<')
        i = i + 6
        continue
      } else if code[0] == '0' &&
        code[1] == '0' &&
        code[2] == '3' &&
        code[3] == 'e' {
        buf.write_char('>')
        i = i + 6
        continue
      } else if code[0] == '0' &&
        code[1] == '0' &&
        code[2] == '2' &&
        code[3] == '6' {
        buf.write_char('&')
        i = i + 6
        continue
      }
    }
    buf.write_char(chars[i])
    i = i + 1
  }
  buf.to_string()
}

///|
/// Parse state from HTML and return ResumableState
pub fn parse_state_from_html(html : String) -> ResumableState? {
  match extract_state_from_html(html) {
    Some(json) => ResumableState::from_json(json)
    None => None
  }
}
