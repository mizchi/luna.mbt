///| SSR - Server-Side Rendering for VNode
///| Pure MoonBit implementation with no external dependencies

///| Self-closing tags that don't need a closing tag
///| Optimized with length check and first char dispatch
fn is_void_element(tag : String) -> Bool {
  let len = tag.length()
  // Fast reject: most common tags are not void elements
  // void elements have length 2-6
  if len < 2 || len > 6 {
    return false
  }
  // Check by length first, then by content
  match len {
    2 => tag == "br" || tag == "hr"
    3 => tag == "img" || tag == "col" || tag == "wbr"
    4 => tag == "area" || tag == "base" || tag == "link" || tag == "meta"
    5 => tag == "embed" || tag == "input" || tag == "track"
    6 => tag == "param" || tag == "source"
    _ => false
  }
}

///| Check if string needs HTML escaping
fn needs_html_escape(s : String) -> Bool {
  for char in s {
    match char {
      '&' | '<' | '>' | '"' | '\'' => return true
      _ => ()
    }
  }
  false
}

///| Escape HTML special characters and write to StringBuilder
fn escape_html_to(sb : StringBuilder, s : String) -> Unit {
  // Fast path: most strings don't need escaping
  if not(needs_html_escape(s)) {
    sb.write_string(s)
    return
  }
  // Slow path: escape character by character
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

///| Check if string needs attribute escaping
fn needs_attr_escape(s : String) -> Bool {
  for char in s {
    match char {
      '&' | '"' => return true
      _ => ()
    }
  }
  false
}

///| Escape attribute value and write to StringBuilder
fn escape_attr_to(sb : StringBuilder, s : String) -> Unit {
  // Fast path: most attribute values don't need escaping
  if not(needs_attr_escape(s)) {
    sb.write_string(s)
    return
  }
  // Slow path: escape character by character
  for char in s {
    match char {
      '&' => sb.write_string("&amp;")
      '"' => sb.write_string("&quot;")
      _ => sb.write_char(char)
    }
  }
}

///| Convert style array to CSS string and write to StringBuilder
fn style_to_sb(sb : StringBuilder, styles : Array[(String, String)]) -> Unit {
  for i = 0; i < styles.length(); i = i + 1 {
    let (prop, value) = styles[i]
    if i > 0 {
      sb.write_string("; ")
    }
    // Convert camelCase to kebab-case
    camel_to_kebab_to(sb, prop)
    sb.write_string(": ")
    sb.write_string(value)
  }
}

///| Check if string has uppercase letters (needs camelCase conversion)
fn needs_kebab_convert(s : String) -> Bool {
  for char in s {
    if char >= 'A' && char <= 'Z' {
      return true
    }
  }
  false
}

///| Convert camelCase to kebab-case and write to StringBuilder
fn camel_to_kebab_to(sb : StringBuilder, s : String) -> Unit {
  // Fast path: already kebab-case or lowercase
  if not(needs_kebab_convert(s)) {
    sb.write_string(s)
    return
  }
  // Slow path: convert camelCase to kebab-case
  for char in s {
    if char >= 'A' && char <= 'Z' {
      sb.write_char('-')
      sb.write_char((char.to_int() + 32).unsafe_to_char())
    } else {
      sb.write_char(char)
    }
  }
}

///| Render attributes to StringBuilder
fn render_attrs_to(sb : StringBuilder, attrs : Array[(String, VAttr)]) -> Unit {
  let len = attrs.length()
  for i = 0; i < len; i = i + 1 {
    let (name, value) = attrs[i]
    match value {
      VStatic(s) => {
        if s != "__remove__" {
          if s == "" {
            // Boolean attribute (like disabled)
            sb.write_char(' ')
            sb.write_string(name)
          } else {
            sb.write_char(' ')
            sb.write_string(name)
            sb.write_string("=\"")
            escape_attr_to(sb, s)
            sb.write_char('"')
          }
        }
      }
      VDynamic(getter) => {
        let s = getter()
        if s != "__remove__" {
          if s == "" {
            sb.write_char(' ')
            sb.write_string(name)
          } else {
            sb.write_char(' ')
            sb.write_string(name)
            sb.write_string("=\"")
            escape_attr_to(sb, s)
            sb.write_char('"')
          }
        }
      }
      VHandler(_) => {
        // Event handlers are not rendered in SSR
        ()
      }
      VStyle(styles) => {
        if styles.length() > 0 {
          sb.write_string(" style=\"")
          style_to_sb(sb, styles)
          sb.write_char('"')
        }
      }
      VDynamicStyle(getter) => {
        let styles = getter()
        if styles.length() > 0 {
          sb.write_string(" style=\"")
          style_to_sb(sb, styles)
          sb.write_char('"')
        }
      }
    }
  }
}

///| Render a VNode to StringBuilder
fn render_to_sb(sb : StringBuilder, node : VNode) -> Unit {
  match node {
    VText(content) => escape_html_to(sb, content)
    VDynamicText(getter) => escape_html_to(sb, getter())
    VFragment(children) => {
      let len = children.length()
      for i = 0; i < len; i = i + 1 {
        render_to_sb(sb, children[i])
      }
    }
    VElement(elem) => {
      let tag = elem.tag
      sb.write_char('<')
      sb.write_string(tag)
      render_attrs_to(sb, elem.attrs)
      if is_void_element(tag) {
        sb.write_string(" />")
      } else {
        sb.write_char('>')
        let len = elem.children.length()
        for i = 0; i < len; i = i + 1 {
          render_to_sb(sb, elem.children[i])
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    VShow(condition=cond, child=child_fn) => {
      if cond() {
        render_to_sb(sb, child_fn())
      } else {
        sb.write_string("<!--show-->")
      }
    }
    VFor(render=render_fn) => {
      let items = render_fn()
      let len = items.length()
      for i = 0; i < len; i = i + 1 {
        render_to_sb(sb, items[i])
      }
    }
    VComponent(render=render_fn) => render_to_sb(sb, render_fn())
  }
}

///| Render a VNode to HTML string
pub fn render_to_string(node : VNode) -> String {
  let sb = StringBuilder::new(size_hint=256)
  render_to_sb(sb, node)
  sb.to_string()
}

///| Render with data-ssr-id markers for hydration
pub fn render_to_string_with_hydration(node : VNode) -> String {
  let sb = StringBuilder::new(size_hint=256)
  let id_counter = { val: 0 }
  render_with_id_to(sb, node, id_counter)
  sb.to_string()
}

///| Internal: Render with hydration markers to StringBuilder
fn render_with_id_to(
  sb : StringBuilder,
  node : VNode,
  id_counter : Ref[Int]
) -> Unit {
  match node {
    VText(content) => escape_html_to(sb, content)
    VDynamicText(getter) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--t:")
      sb.write_object(id)
      sb.write_string("-->")
      escape_html_to(sb, getter())
      sb.write_string("<!--/t-->")
    }
    VFragment(children) => {
      let len = children.length()
      for i = 0; i < len; i = i + 1 {
        render_with_id_to(sb, children[i], id_counter)
      }
    }
    VElement(elem) => {
      let tag = elem.tag
      let id = id_counter.val
      id_counter.val = id + 1

      // Check if element has dynamic attributes or handlers
      let needs_hydration = has_dynamic_content(elem.attrs)

      sb.write_char('<')
      sb.write_string(tag)
      render_attrs_to(sb, elem.attrs)
      if needs_hydration {
        sb.write_string(" data-hk=\"")
        sb.write_object(id)
        sb.write_char('"')
      }

      if is_void_element(tag) {
        sb.write_string(" />")
      } else {
        sb.write_char('>')
        let len = elem.children.length()
        for i = 0; i < len; i = i + 1 {
          render_with_id_to(sb, elem.children[i], id_counter)
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    VShow(condition=cond, child=child_fn) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--s:")
      sb.write_object(id)
      sb.write_string("-->")
      if cond() {
        render_with_id_to(sb, child_fn(), id_counter)
      }
      sb.write_string("<!--/s-->")
    }
    VFor(render=render_fn) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--f:")
      sb.write_object(id)
      sb.write_string("-->")
      let items = render_fn()
      let len = items.length()
      for i = 0; i < len; i = i + 1 {
        render_with_id_to(sb, items[i], id_counter)
      }
      sb.write_string("<!--/f-->")
    }
    VComponent(render=render_fn) => render_with_id_to(sb, render_fn(), id_counter)
  }
}

///| Check if element has dynamic content that needs hydration
fn has_dynamic_content(attrs : Array[(String, VAttr)]) -> Bool {
  let len = attrs.length()
  for i = 0; i < len; i = i + 1 {
    let (_, value) = attrs[i]
    match value {
      VDynamic(_) | VHandler(_) | VDynamicStyle(_) => return true
      _ => ()
    }
  }
  false
}
