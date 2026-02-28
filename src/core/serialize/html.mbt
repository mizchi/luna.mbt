// HTML State Embedding - Embed and extract state from HTML
//

///|
/// State script tag attribute name
let state_attr : String = "data-resumable-state"

///|
/// Generate script tag with embedded state
/// If id is provided, includes it as attribute value
pub fn state_to_script_tag(state : ResumableState, id? : String) -> String {
  let json = state.to_json()
  let id_part = match id {
    Some(i) => "=\"" + escape_html_attr(i) + "\""
    None => ""
  }
  "<script type=\"application/json\" " +
  state_attr +
  id_part +
  ">" +
  escape_html_content(json) +
  "</script>"
}

///|
/// Generate a container div with state endpoint for lazy loading
pub fn state_endpoint_tag(
  id : String,
  endpoint : String,
  content : String,
) -> String {
  "<div data-state-id=\"" +
  escape_html_attr(id) +
  "\" data-state-src=\"" +
  escape_html_attr(endpoint) +
  "\">" +
  content +
  "</div>"
}

///|
/// Escape HTML attribute value
fn escape_html_attr(s : String) -> String {
  let buf = StringBuilder::new()
  for char in s {
    match char {
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(char)
    }
  }
  buf.to_string()
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
  let chars = html.to_array()
  let start_marker = "<script type=\"application/json\" " + state_attr
  let start_pattern = start_marker.to_array()
  let end_pattern = "</script>".to_array()
  match find_pattern(chars, start_pattern, 0) {
    None => None
    Some(script_start) =>
      match find_tag_end(chars, script_start + start_pattern.length()) {
        None => None
        Some(content_start) =>
          match find_pattern(chars, end_pattern, content_start) {
            None => None
            Some(content_end) =>
              Some(
                unescape_html_content(
                  chars_range_to_string(chars, content_start, content_end),
                ),
              )
          }
      }
  }
}

///|
/// Find `>` for a start tag and return content start index (index after `>`)
fn find_tag_end(chars : Array[Char], start : Int) -> Int? {
  if start < 0 || start >= chars.length() {
    return None
  }
  for i in start..<chars.length() {
    if chars[i] == '>' {
      return Some(i + 1)
    }
  }
  None
}

///|
/// Find pattern in char array, returns start index when found
fn find_pattern(
  chars : Array[Char],
  pattern : Array[Char],
  start : Int,
) -> Int? {
  let c_len = chars.length()
  let p_len = pattern.length()
  if p_len == 0 {
    return Some(start)
  }
  let last = c_len - p_len
  if start < 0 || start > last {
    return None
  }

  for i in start..<=last {
    let mut matched = true
    for j in 0..<p_len {
      if chars[i + j] != pattern[j] {
        matched = false
        break
      }
    }
    if matched {
      return Some(i)
    }
  }
  None
}

///|
/// Build String from char range [start, end)
fn chars_range_to_string(chars : Array[Char], start : Int, end : Int) -> String {
  if start < 0 || end < start || end > chars.length() {
    return ""
  }
  let buf = StringBuilder::new(size_hint=end - start)
  for i in start..<end {
    buf.write_char(chars[i])
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
