///| Markdown Parser using JS FFI (marked.js)

// =============================================================================
// JS FFI Declarations
// =============================================================================

///| Parse markdown to tokens using marked.js
extern "js" fn ffi_parse_markdown(content : String) -> @js.Any =
  #| (content) => {
  #|   const { marked } = require('marked');
  #|   return marked.lexer(content);
  #| }

///| Parse YAML frontmatter
extern "js" fn ffi_parse_frontmatter(content : String) -> @js.Any =
  #| (content) => {
  #|   const matter = require('gray-matter');
  #|   const result = matter(content);
  #|   return { data: result.data, content: result.content };
  #| }

///| Get array length from JS
extern "js" fn ffi_array_length(arr : @js.Any) -> Int =
  #| (arr) => arr.length

///| Get array element from JS
extern "js" fn ffi_array_get(arr : @js.Any, index : Int) -> @js.Any =
  #| (arr, index) => arr[index]

///| Get property from JS object
extern "js" fn ffi_get_prop(obj : @js.Any, key : String) -> @js.Any =
  #| (obj, key) => obj[key]

///| Check if JS value is undefined
extern "js" fn ffi_is_undefined(val : @js.Any) -> Bool =
  #| (val) => val === undefined || val === null

///| Get string value
extern "js" fn ffi_to_string(val : @js.Any) -> String =
  #| (val) => String(val ?? '')

///| Get boolean value
extern "js" fn ffi_to_bool(val : @js.Any) -> Bool =
  #| (val) => Boolean(val)

///| Get int value
extern "js" fn ffi_to_int(val : @js.Any) -> Int =
  #| (val) => Number(val) | 0

// =============================================================================
// Markdown Parsing
// =============================================================================

///| Parse markdown content and return frontmatter + AST
pub fn parse_markdown(content : String) -> (@ssg.Frontmatter, Array[@ssg.MdNode]) {
  // Parse frontmatter
  let matter_result = ffi_parse_frontmatter(content)
  let frontmatter = parse_frontmatter_data(ffi_get_prop(matter_result, "data"))
  let body = ffi_to_string(ffi_get_prop(matter_result, "content"))

  // Parse markdown body to tokens
  let tokens = ffi_parse_markdown(body)
  let nodes = convert_tokens_to_nodes(tokens)

  (frontmatter, nodes)
}

///| Parse frontmatter data object
fn parse_frontmatter_data(data : @js.Any) -> @ssg.Frontmatter {
  if ffi_is_undefined(data) {
    return @ssg.Frontmatter::default()
  }

  let title = {
    let val = ffi_get_prop(data, "title")
    if ffi_is_undefined(val) {
      None
    } else {
      Some(ffi_to_string(val))
    }
  }

  let description = {
    let val = ffi_get_prop(data, "description")
    if ffi_is_undefined(val) {
      None
    } else {
      Some(ffi_to_string(val))
    }
  }

  let layout = {
    let val = ffi_get_prop(data, "layout")
    if ffi_is_undefined(val) {
      None
    } else {
      Some(ffi_to_string(val))
    }
  }

  let sidebar = {
    let val = ffi_get_prop(data, "sidebar")
    if ffi_is_undefined(val) {
      true
    } else {
      ffi_to_bool(val)
    }
  }

  let islands : Array[String] = []
  let islands_val = ffi_get_prop(data, "islands")
  if not(ffi_is_undefined(islands_val)) {
    let len = ffi_array_length(islands_val)
    for i = 0; i < len; i = i + 1 {
      islands.push(ffi_to_string(ffi_array_get(islands_val, i)))
    }
  }

  @ssg.Frontmatter::{
    title,
    description,
    layout,
    sidebar,
    outline: None,
    islands,
    prev: None,
    next: None,
  }
}

///| Convert marked.js tokens to MdNode array
fn convert_tokens_to_nodes(tokens : @js.Any) -> Array[@ssg.MdNode] {
  let nodes : Array[@ssg.MdNode] = []
  let len = ffi_array_length(tokens)

  for i = 0; i < len; i = i + 1 {
    let token = ffi_array_get(tokens, i)
    match convert_token_to_node(token) {
      Some(node) => nodes.push(node)
      None => ()
    }
  }

  nodes
}

///| Convert single marked.js token to MdNode
fn convert_token_to_node(token : @js.Any) -> @ssg.MdNode? {
  let token_type = ffi_to_string(ffi_get_prop(token, "type"))

  match token_type {
    "heading" => {
      let depth = ffi_to_int(ffi_get_prop(token, "depth"))
      let text = ffi_to_string(ffi_get_prop(token, "text"))
      let id = generate_heading_id(text)
      let children = convert_inline_tokens(ffi_get_prop(token, "tokens"))
      Some(@ssg.MdNode::Heading(level=depth, children~, id~))
    }
    "paragraph" => {
      let children = convert_inline_tokens(ffi_get_prop(token, "tokens"))
      // Check for Island directive in raw text
      let raw = ffi_to_string(ffi_get_prop(token, "raw"))
      match parse_island_directive(raw) {
        Some(island) => Some(@ssg.MdNode::Island(island))
        None => Some(@ssg.MdNode::Paragraph(children~))
      }
    }
    "text" => {
      // Check if text token has inline tokens (for list items, etc.)
      let tokens = ffi_get_prop(token, "tokens")
      if not(ffi_is_undefined(tokens)) && ffi_array_length(tokens) > 0 {
        let children = convert_inline_tokens(tokens)
        Some(@ssg.MdNode::Paragraph(children~))
      } else {
        let text = ffi_to_string(ffi_get_prop(token, "text"))
        Some(@ssg.MdNode::Text(text))
      }
    }
    "code" => {
      let code = ffi_to_string(ffi_get_prop(token, "text"))
      let lang = ffi_to_string(ffi_get_prop(token, "lang"))
      // Check for island code block
      if lang.has_prefix("island:") {
        let name = lang.substring(start=7)
        Some(
          @ssg.MdNode::Island(
            @ssg.IslandEmbed::{ name, props: code.trim_space().to_string(), trigger: @luna.Load },
          ),
        )
      } else {
        Some(@ssg.MdNode::CodeBlock(lang~, code~))
      }
    }
    "blockquote" => {
      let children = convert_tokens_to_nodes(ffi_get_prop(token, "tokens"))
      Some(@ssg.MdNode::Blockquote(children~))
    }
    "list" => {
      let ordered = ffi_to_bool(ffi_get_prop(token, "ordered"))
      let items_arr = ffi_get_prop(token, "items")
      let items : Array[Array[@ssg.MdNode]] = []
      let items_len = ffi_array_length(items_arr)
      for i = 0; i < items_len; i = i + 1 {
        let item = ffi_array_get(items_arr, i)
        let item_tokens = ffi_get_prop(item, "tokens")
        items.push(convert_tokens_to_nodes(item_tokens))
      }
      Some(@ssg.MdNode::List(ordered~, items~))
    }
    "html" => {
      let html = ffi_to_string(ffi_get_prop(token, "text"))
      // Check for Island directive in HTML
      match parse_island_directive(html) {
        Some(island) => Some(@ssg.MdNode::Island(island))
        None => Some(@ssg.MdNode::Html(html))
      }
    }
    "hr" => Some(@ssg.MdNode::ThematicBreak)
    "space" => None // Skip whitespace
    "table" => {
      let header_arr = ffi_get_prop(token, "header")
      let rows_arr = ffi_get_prop(token, "rows")
      let headers : Array[@ssg.MdNode] = []
      let header_len = ffi_array_length(header_arr)
      for i = 0; i < header_len; i = i + 1 {
        let cell = ffi_array_get(header_arr, i)
        let text = ffi_to_string(ffi_get_prop(cell, "text"))
        headers.push(@ssg.MdNode::Text(text))
      }
      let rows : Array[Array[@ssg.MdNode]] = []
      let rows_len = ffi_array_length(rows_arr)
      for i = 0; i < rows_len; i = i + 1 {
        let row_arr = ffi_array_get(rows_arr, i)
        let row : Array[@ssg.MdNode] = []
        let row_len = ffi_array_length(row_arr)
        for j = 0; j < row_len; j = j + 1 {
          let cell = ffi_array_get(row_arr, j)
          let text = ffi_to_string(ffi_get_prop(cell, "text"))
          row.push(@ssg.MdNode::Text(text))
        }
        rows.push(row)
      }
      Some(@ssg.MdNode::Table(headers~, rows~))
    }
    _ => None
  }
}

///| Convert inline tokens (for paragraph, heading, etc.)
fn convert_inline_tokens(tokens : @js.Any) -> Array[@ssg.MdNode] {
  let nodes : Array[@ssg.MdNode] = []
  if ffi_is_undefined(tokens) {
    return nodes
  }

  let len = ffi_array_length(tokens)
  for i = 0; i < len; i = i + 1 {
    let token = ffi_array_get(tokens, i)
    let token_type = ffi_to_string(ffi_get_prop(token, "type"))

    match token_type {
      "text" => {
        let text = ffi_to_string(ffi_get_prop(token, "text"))
        nodes.push(@ssg.MdNode::Text(text))
      }
      "strong" => {
        let children = convert_inline_tokens(ffi_get_prop(token, "tokens"))
        nodes.push(@ssg.MdNode::Bold(children~))
      }
      "em" => {
        let children = convert_inline_tokens(ffi_get_prop(token, "tokens"))
        nodes.push(@ssg.MdNode::Italic(children~))
      }
      "codespan" => {
        let code = ffi_to_string(ffi_get_prop(token, "text"))
        nodes.push(@ssg.MdNode::Code(code))
      }
      "link" => {
        let href = ffi_to_string(ffi_get_prop(token, "href"))
        let title_val = ffi_get_prop(token, "title")
        let title = if ffi_is_undefined(title_val) {
          ""
        } else {
          ffi_to_string(title_val)
        }
        let children = convert_inline_tokens(ffi_get_prop(token, "tokens"))
        nodes.push(@ssg.MdNode::Link(href~, title~, children~))
      }
      "image" => {
        let src = ffi_to_string(ffi_get_prop(token, "href"))
        let alt = ffi_to_string(ffi_get_prop(token, "text"))
        let title_val = ffi_get_prop(token, "title")
        let title = if ffi_is_undefined(title_val) {
          ""
        } else {
          ffi_to_string(title_val)
        }
        nodes.push(@ssg.MdNode::Image(src~, alt~, title~))
      }
      "br" => nodes.push(@ssg.MdNode::LineBreak)
      "html" => {
        let html = ffi_to_string(ffi_get_prop(token, "text"))
        nodes.push(@ssg.MdNode::Html(html))
      }
      _ => ()
    }
  }

  nodes
}

// =============================================================================
// Island Directive Parsing
// =============================================================================

///| Parse Island directive from HTML string
/// Format: <Island name="counter" :props='{"initial": 0}' trigger="visible" />
fn parse_island_directive(html : String) -> @ssg.IslandEmbed? {
  let trimmed = html.trim_space().to_string()
  if not(trimmed.has_prefix("<Island")) && not(trimmed.has_prefix("<island")) {
    return None
  }

  // Extract name attribute
  let name = match extract_attribute(trimmed, "name") {
    Some(n) => n
    None => return None
  }

  // Extract props attribute (may use :props or props)
  let props = match extract_attribute(trimmed, ":props") {
    Some(p) => p
    None =>
      match extract_attribute(trimmed, "props") {
        Some(p) => p
        None => "{}"
      }
  }

  // Extract trigger attribute
  let trigger = match extract_attribute(trimmed, "trigger") {
    Some("visible") => @luna.Visible
    Some("idle") => @luna.Idle
    Some("media") => @luna.Media("")
    _ => @luna.Load
  }

  Some(@ssg.IslandEmbed::{ name, props, trigger })
}

///| Extract attribute value from HTML tag
fn extract_attribute(html : String, attr_name : String) -> String? {
  // Look for attr_name="..." or attr_name='...'
  let pattern1 = attr_name + "=\""
  let pattern2 = attr_name + "='"

  match html.find(pattern1) {
    Some(start) => {
      let value_start = start + pattern1.length()
      let remaining = html.substring(start=value_start)
      match remaining.find("\"") {
        Some(end) => Some(remaining.substring(end=end))
        None => None
      }
    }
    None =>
      match html.find(pattern2) {
        Some(start) => {
          let value_start = start + pattern2.length()
          let remaining = html.substring(start=value_start)
          match remaining.find("'") {
            Some(end) => Some(remaining.substring(end=end))
            None => None
          }
        }
        None => None
      }
  }
}

// =============================================================================
// Utility Functions
// =============================================================================

///| Generate heading ID from text (for anchor links)
fn generate_heading_id(text : String) -> String {
  let buf = StringBuilder::new()
  let lower = text.to_lower()
  let mut prev_was_separator = false

  for c in lower {
    if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') {
      buf.write_char(c)
      prev_was_separator = false
    } else if c == ' ' || c == '-' || c == '_' {
      // Avoid multiple consecutive separators
      if not(prev_was_separator) {
        buf.write_char('-')
        prev_was_separator = true
      }
    } else if c.to_uint() > 127 {
      // Keep non-ASCII characters (Japanese, Chinese, etc.)
      buf.write_char(c)
      prev_was_separator = false
    }
    // Skip other ASCII special characters
  }

  // Remove trailing separator
  let result = buf.to_string()
  if result.has_suffix("-") {
    result.substring(end=result.length() - 1)
  } else {
    result
  }
}
