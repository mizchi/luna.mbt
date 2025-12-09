///| SSR Renderer - Render VNode to HTML string

///| JS-specific: uses JSVNode (event handlers are ignored in SSR)

///|

///|
/// Render VNode to HTML string
/// JS-specific: uses JSVNode
pub fn render_to_string(vnode : JSVNode) -> String {
  match vnode {
    Empty => ""
    Text(content) => escape_html(content)
    Element({ tag, props, children, .. }) =>
      render_element_to_string(tag, props, children)
    Fragment(children) => {
      let mut html = ""
      for child in children {
        html = html + render_to_string(child)
      }
      html
    }
    Component(_) => abort("Components must be rendered to VNode before SSR")
  }
}

///|

///|
/// Render element to HTML string
fn render_element_to_string(
  tag : String,
  props : JSProps,
  children : Array[JSVNode],
) -> String {
  let mut html = "<" + tag

  // Add props as attributes
  let attrs = props_to_attributes(props)
  if attrs != "" {
    html = html + " " + attrs
  }
  html = html + ">"

  // Void elements don't have closing tags
  if is_void_element(tag) {
    return html
  }

  // Add children
  for child in children {
    html = html + render_to_string(child)
  }
  html = html + "</" + tag + ">"
  html
}

///|

///|
/// Convert props to HTML attributes string
/// JS-specific: uses JSProps
fn props_to_attributes(props : JSProps) -> String {
  let mut attrs = ""
  let mut first = true
  for i = 0; i < props.length(); i = i + 1 {
    let (key, value) = props[i]
    match value {
      Str(s) =>
        // Handle className specially - convert to "class"
        if key == "className" {
          if not(first) {
            attrs = attrs + " "
          }
          attrs = attrs + "class=\"" + escape_html(s) + "\""
          first = false
        } else {
          if not(first) {
            attrs = attrs + " "
          }
          attrs = attrs + key + "=\"" + escape_html(s) + "\""
          first = false
        }
      Num(n) => {
        if not(first) {
          attrs = attrs + " "
        }
        attrs = attrs + key + "=\"" + n.to_string() + "\""
        first = false
      }
      Bool(b) =>
        // Boolean attributes: only add attribute name if true
        if b {
          if not(first) {
            attrs = attrs + " "
          }
          attrs = attrs + key
          first = false
        }
      Handler(_) =>
        // Skip event handlers in SSR
        continue
      StyleObj(styles) => {
        let style_str = style_array_to_string(styles)
        if style_str != "" {
          if not(first) {
            attrs = attrs + " "
          }
          attrs = attrs + "style=\"" + style_str + "\""
          first = false
        }
      }
    }
  }
  attrs
}

///|

///|
/// Convert style array to CSS string
fn style_array_to_string(styles : Array[(String, String)]) -> String {
  let mut css = ""
  let mut first = true
  for i = 0; i < styles.length(); i = i + 1 {
    let (key, value) = styles[i]
    if not(first) {
      css = css + "; "
    }
    css = css + key + ": " + value
    first = false
  }
  css
}

///|

///|
/// HTML escape - manually iterate to replace all occurrences
fn escape_html(text : String) -> String {
  let mut result = ""
  let iter = text.iter()
  for char in iter {
    match char {
      '&' => result = result + "&amp;"
      '<' => result = result + "&lt;"
      '>' => result = result + "&gt;"
      '"' => result = result + "&quot;"
      '\'' => result = result + "&#39;"
      _ => result = result + char.to_string()
    }
  }
  result
}

///|

///|
/// Check if tag is a void element (self-closing)
fn is_void_element(tag : String) -> Bool {
  tag == "area" ||
  tag == "base" ||
  tag == "br" ||
  tag == "col" ||
  tag == "embed" ||
  tag == "hr" ||
  tag == "img" ||
  tag == "input" ||
  tag == "link" ||
  tag == "meta" ||
  tag == "param" ||
  tag == "source" ||
  tag == "track" ||
  tag == "wbr"
}

///|

///|
/// Render VNode with serialized hooks state (Qwik-like resumability)
/// Returns HTML with embedded state data for hydration
/// JavaScript backend only (uses JSON serialization)
pub fn render_to_string_with_state(
  vnode : JSVNode,
  hooks_state : HooksState,
) -> String {
  let html = render_to_string(vnode)
  let state_json = hooks_state.serialize_js()
  let escaped_json = escape_html(state_json)
  // Embed state in a script tag with data attribute
  html +
  "<script type=\"application/json\" data-hooks-state>" +
  escaped_json +
  "</script>"
}

///|

///|
/// Extract serialized state from SSR HTML
/// Returns None if no state found
pub fn extract_state_from_html(html : String) -> String? {
  // Find the script tag with data-hooks-state
  // Simple string search - in production, use proper HTML parsing
  let start_tag = "<script type=\"application/json\" data-hooks-state>"
  let end_tag = "</script>"
  let mut start_idx = 0
  let mut found_start = false
  let html_len = html.length()

  // Find start tag
  for i = 0; i < html_len - start_tag.length(); i = i + 1 {
    let mut matches = true
    for j = 0; j < start_tag.length(); j = j + 1 {
      if html.code_unit_at(i + j) != start_tag.code_unit_at(j) {
        matches = false
        break
      }
    }
    if matches {
      start_idx = i + start_tag.length()
      found_start = true
      break
    }
  }
  if not(found_start) {
    return None
  }

  // Find end tag
  for i = start_idx; i < html_len - end_tag.length(); i = i + 1 {
    let mut matches = true
    for j = 0; j < end_tag.length(); j = j + 1 {
      if html.code_unit_at(i + j) != end_tag.code_unit_at(j) {
        matches = false
        break
      }
    }
    if matches {
      // Extract substring
      let mut result = ""
      for k = start_idx; k < i; k = k + 1 {
        result = result +
          html.code_unit_at(k).to_int().unsafe_to_char().to_string()
      }
      return Some(result)
    }
  }
  None
}
