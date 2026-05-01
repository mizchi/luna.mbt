// Demo Component SSR Generators
// Generates SSR markup for demo components from data attributes

// =============================================================================
// Accordion Demo
// =============================================================================

///|
/// Accordion item data
pub struct AccordionDemoItem {
  id : String
  title : String
  content : String
  open : Bool
} derive(Eq)

///|
/// Parse accordion items from JSON-like string
/// Format: [{"id":"1","title":"...","content":"...","open":true}, ...]
pub fn parse_accordion_items(json : String) -> Array[AccordionDemoItem] {
  let items : Array[AccordionDemoItem] = []
  // Simple JSON array parsing
  let trimmed = json.trim(chars=" \t\n\r").to_string()
  if !(trimmed.has_prefix("[")) || !(trimmed.has_suffix("]")) {
    return items
  }
  // Remove outer brackets
  let inner : String = trimmed[1:trimmed.length() - 1].to_string() catch {
    _ => return items
  }

  // Split by },{ pattern (simplified parsing)
  let parts = split_json_objects(inner)
  for part in parts {
    match parse_accordion_item(part) {
      Some(item) => items.push(item)
      None => ()
    }
  }
  items
}

///|
/// Split JSON array content into individual object strings
fn split_json_objects(s : String) -> Array[String] {
  let result : Array[String] = []
  let chars = s.to_array()
  let buf = StringBuilder::new()
  let mut depth = 0
  let mut in_string = false
  let mut escape_next = false

  for c in chars {
    if escape_next {
      buf.write_char(c)
      escape_next = false
      continue
    }
    if c == '\\' {
      buf.write_char(c)
      escape_next = true
      continue
    }
    if c == '"' {
      in_string = !(in_string)
      buf.write_char(c)
      continue
    }
    if !(in_string) {
      if c == '{' {
        depth = depth + 1
        buf.write_char(c)
      } else if c == '}' {
        depth = depth - 1
        buf.write_char(c)
        if depth == 0 {
          result.push(buf.to_string().trim(chars=" \t\n\r,").to_string())
          buf.reset()
        }
      } else if depth > 0 {
        buf.write_char(c)
      }
    } else {
      buf.write_char(c)
    }
  }
  result
}

///|
/// Parse single accordion item from JSON object string
fn parse_accordion_item(json : String) -> AccordionDemoItem? {
  let trimmed = json.trim(chars=" \t\n\r").to_string()
  if !(trimmed.has_prefix("{")) || !(trimmed.has_suffix("}")) {
    return None
  }

  let id = extract_json_string(trimmed, "id").unwrap_or("")
  let title = extract_json_string(trimmed, "title").unwrap_or("")
  let content = extract_json_string(trimmed, "content").unwrap_or("")
  let open = extract_json_bool(trimmed, "open").unwrap_or(false)

  if id.is_empty() && title.is_empty() {
    return None
  }
  Some({ id, title, content, open })
}

///|
/// Extract string value from JSON object
fn extract_json_string(json : String, key : String) -> String? {
  // Look for "key":"value" or "key": "value"
  let pattern = "\"" + key + "\""
  let idx = index_of(json, pattern)
  if idx < 0 {
    return None
  }

  // Find the colon after key
  let after_key = idx + pattern.length()
  let chars = json.to_array()
  let mut pos = after_key

  // Skip whitespace and colon
  while pos < chars.length() &&
        (chars[pos] == ' ' || chars[pos] == ':' || chars[pos] == '\t') {
    pos = pos + 1
  }

  // Check for opening quote
  if pos >= chars.length() || chars[pos] != '"' {
    return None
  }
  pos = pos + 1

  // Read until closing quote
  let buf = StringBuilder::new()
  let mut escape_next = false
  while pos < chars.length() {
    let c = chars[pos]
    if escape_next {
      buf.write_char(c)
      escape_next = false
      pos = pos + 1
      continue
    }
    if c == '\\' {
      escape_next = true
      pos = pos + 1
      continue
    }
    if c == '"' {
      break
    }
    buf.write_char(c)
    pos = pos + 1
  }
  Some(buf.to_string())
}

///|
/// Extract boolean value from JSON object
fn extract_json_bool(json : String, key : String) -> Bool? {
  let pattern = "\"" + key + "\""
  let idx = index_of(json, pattern)
  if idx < 0 {
    return None
  }

  let after_key = idx + pattern.length()
  let chars = json.to_array()
  let mut pos = after_key

  // Skip whitespace and colon
  while pos < chars.length() &&
        (chars[pos] == ' ' || chars[pos] == ':' || chars[pos] == '\t') {
    pos = pos + 1
  }

  // Check for true/false
  let rest : String = json[pos:].to_string() catch { _ => return None }
  if rest.has_prefix("true") {
    return Some(true)
  }
  if rest.has_prefix("false") {
    return Some(false)
  }
  None
}

///|
/// Find index of substring
fn index_of(s : String, pattern : String) -> Int {
  let chars = s.to_array()
  let pat_chars = pattern.to_array()
  let s_len = chars.length()
  let p_len = pat_chars.length()

  if p_len > s_len {
    return -1
  }

  for i = 0; i <= s_len - p_len; i = i + 1 {
    let mut match_ = true
    for j = 0; j < p_len; j = j + 1 {
      if chars[i + j] != pat_chars[j] {
        match_ = false
        break
      }
    }
    if match_ {
      return i
    }
  }
  -1
}

///|
/// Generate accordion demo SSR markup
pub fn accordion_demo_ssr(items : Array[AccordionDemoItem]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("<div class=\"accordion\" data-accordion>")

  for item in items {
    let state = if item.open { "open" } else { "closed" }
    let expanded = if item.open { "true" } else { "false" }
    let hidden = if item.open { "" } else { " hidden" }
    let aria_hidden = if item.open { "false" } else { "true" }

    buf.write_string(
      "<div class=\"accordion__item\" data-accordion-item data-item-id=\"",
    )
    buf.write_string(item.id)
    buf.write_string("\" data-state=\"")
    buf.write_string(state)
    buf.write_string("\">")

    // Header
    buf.write_string("<h3>")
    buf.write_string(
      "<button class=\"accordion__header\" data-accordion-trigger data-state=\"",
    )
    buf.write_string(state)
    buf.write_string("\" aria-expanded=\"")
    buf.write_string(expanded)
    buf.write_string("\" aria-controls=\"panel-")
    buf.write_string(item.id)
    buf.write_string("\" id=\"header-")
    buf.write_string(item.id)
    buf.write_string("\">")
    buf.write_string(escape_html(item.title))
    buf.write_string("<span class=\"accordion__icon\">▼</span>")
    buf.write_string("</button>")
    buf.write_string("</h3>")

    // Panel
    buf.write_string(
      "<div class=\"accordion__panel\" data-accordion-content data-state=\"",
    )
    buf.write_string(state)
    buf.write_string("\" id=\"panel-")
    buf.write_string(item.id)
    buf.write_string("\" role=\"region\" aria-labelledby=\"header-")
    buf.write_string(item.id)
    buf.write_string("\" aria-hidden=\"")
    buf.write_string(aria_hidden)
    buf.write_string("\"")
    buf.write_string(hidden)
    buf.write_string(">")
    buf.write_string("<div class=\"accordion__panel-content\">")
    buf.write_string(escape_html(item.content))
    buf.write_string("</div>")
    buf.write_string("</div>")

    buf.write_string("</div>")
  }

  buf.write_string("</div>")
  buf.to_string()
}

///|
/// Escape HTML special characters
fn escape_html(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Generate accordion demo SSR from items JSON string
pub fn accordion_demo_ssr_from_json(items_json : String) -> String {
  let items = parse_accordion_items(items_json)
  accordion_demo_ssr(items)
}

// =============================================================================
// Demo Component Registry
// =============================================================================

///|
/// Check if a component tag is a demo component that needs SSR generation
pub fn is_demo_component(tag : String) -> Bool {
  tag == "accordion-demo" || tag == "styled-accordion-demo"
}

///|
/// Generate SSR for a demo component
/// Returns None if not a demo component or no items attribute
pub fn generate_demo_ssr(
  tag : String,
  attrs : Array[(String, String)],
) -> String? {
  // Find items attribute
  let mut items_json : String? = None
  for pair in attrs {
    let (key, value) = pair
    if key == "items" {
      items_json = Some(value)
      break
    }
  }

  match items_json {
    None => None
    Some(json) =>
      if tag == "accordion-demo" || tag == "styled-accordion-demo" {
        Some(accordion_demo_ssr_from_json(json))
      } else {
        None
      }
  }
}
