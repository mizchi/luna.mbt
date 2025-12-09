///| SSR - Server-Side Rendering for VNode

///| Self-closing tags that don't need a closing tag
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

///| Escape a single HTML character
fn escape_html_char(char : Char) -> String {
  match char {
    '&' => "&amp;"
    '<' => "&lt;"
    '>' => "&gt;"
    '"' => "&quot;"
    '\'' => "&#39;"
    _ => char.to_string()
  }
}

///| Escape HTML special characters
fn escape_html(s : String) -> String {
  let mut result = ""
  for char in s {
    result = result + escape_html_char(char)
  }
  result
}

///| Escape a single attribute character
fn escape_attr_char(char : Char) -> String {
  match char {
    '&' => "&amp;"
    '"' => "&quot;"
    _ => char.to_string()
  }
}

///| Escape attribute value
fn escape_attr(s : String) -> String {
  let mut result = ""
  for char in s {
    result = result + escape_attr_char(char)
  }
  result
}

///| Convert style array to CSS string
fn style_to_string(styles : Array[(String, String)]) -> String {
  let mut result = ""
  for i = 0; i < styles.length(); i = i + 1 {
    let (prop, value) = styles[i]
    if i > 0 {
      result = result + "; "
    }
    // Convert camelCase to kebab-case
    result = result + camel_to_kebab(prop) + ": " + value
  }
  result
}

///| Convert camelCase to kebab-case
fn camel_to_kebab(s : String) -> String {
  let mut result = ""
  for char in s {
    if char >= 'A' && char <= 'Z' {
      result = result + "-" + (char.to_int() + 32).unsafe_to_char().to_string()
    } else {
      result = result + char.to_string()
    }
  }
  result
}

///| Render attributes to string
fn render_attrs(attrs : Array[(String, VAttr)]) -> String {
  let mut result = ""
  for i = 0; i < attrs.length(); i = i + 1 {
    let (name, value) = attrs[i]
    match value {
      VStatic(s) => {
        if s != "__remove__" {
          if s == "" {
            // Boolean attribute (like disabled)
            result = result + " " + name
          } else {
            result = result + " " + name + "=\"" + escape_attr(s) + "\""
          }
        }
      }
      VDynamic(getter) => {
        let s = getter()
        if s != "__remove__" {
          if s == "" {
            result = result + " " + name
          } else {
            result = result + " " + name + "=\"" + escape_attr(s) + "\""
          }
        }
      }
      VHandler(_) => {
        // Event handlers are not rendered in SSR
        ()
      }
      VStyle(styles) => {
        if styles.length() > 0 {
          result = result + " style=\"" + escape_attr(style_to_string(styles)) + "\""
        }
      }
      VDynamicStyle(getter) => {
        let styles = getter()
        if styles.length() > 0 {
          result = result + " style=\"" + escape_attr(style_to_string(styles)) + "\""
        }
      }
    }
  }
  result
}

///| Render a VNode to HTML string
pub fn render_to_string(node : VNode) -> String {
  match node {
    VText(content) => escape_html(content)
    VDynamicText(getter) => escape_html(getter())
    VFragment(children) => {
      let mut result = ""
      for i = 0; i < children.length(); i = i + 1 {
        result = result + render_to_string(children[i])
      }
      result
    }
    VElement(elem) => {
      let tag = elem.tag
      let attrs_str = render_attrs(elem.attrs)
      if is_void_element(tag) {
        "<" + tag + attrs_str + " />"
      } else {
        let mut result = "<" + tag + attrs_str + ">"
        for i = 0; i < elem.children.length(); i = i + 1 {
          result = result + render_to_string(elem.children[i])
        }
        result = result + "</" + tag + ">"
        result
      }
    }
    VShow(condition=cond, child=child_fn) => {
      if cond() {
        render_to_string(child_fn())
      } else {
        "<!--show-->"
      }
    }
    VFor(render=render_fn) => {
      let items = render_fn()
      let mut result = ""
      for i = 0; i < items.length(); i = i + 1 {
        result = result + render_to_string(items[i])
      }
      result
    }
    VComponent(render=render_fn) => render_to_string(render_fn())
  }
}

///| Render with data-ssr-id markers for hydration
pub fn render_to_string_with_hydration(node : VNode) -> String {
  let id_counter = { val: 0 }
  render_with_id(node, id_counter)
}

///| Internal: Render with hydration markers
fn render_with_id(node : VNode, id_counter : Ref[Int]) -> String {
  match node {
    VText(content) => escape_html(content)
    VDynamicText(getter) => {
      let id = id_counter.val
      id_counter.val = id + 1
      "<!--t:" + id.to_string() + "-->" + escape_html(getter()) + "<!--/t-->"
    }
    VFragment(children) => {
      let mut result = ""
      for i = 0; i < children.length(); i = i + 1 {
        result = result + render_with_id(children[i], id_counter)
      }
      result
    }
    VElement(elem) => {
      let tag = elem.tag
      let id = id_counter.val
      id_counter.val = id + 1

      // Check if element has dynamic attributes or handlers
      let needs_hydration = has_dynamic_content(elem.attrs)

      let attrs_str = render_attrs(elem.attrs)
      let hydration_attr = if needs_hydration {
        " data-hk=\"" + id.to_string() + "\""
      } else {
        ""
      }

      if is_void_element(tag) {
        "<" + tag + attrs_str + hydration_attr + " />"
      } else {
        let mut result = "<" + tag + attrs_str + hydration_attr + ">"
        for i = 0; i < elem.children.length(); i = i + 1 {
          result = result + render_with_id(elem.children[i], id_counter)
        }
        result = result + "</" + tag + ">"
        result
      }
    }
    VShow(condition=cond, child=child_fn) => {
      let id = id_counter.val
      id_counter.val = id + 1
      if cond() {
        "<!--s:" + id.to_string() + "-->" + render_with_id(child_fn(), id_counter) + "<!--/s-->"
      } else {
        "<!--s:" + id.to_string() + "--><!--/s-->"
      }
    }
    VFor(render=render_fn) => {
      let id = id_counter.val
      id_counter.val = id + 1
      let items = render_fn()
      let mut result = "<!--f:" + id.to_string() + "-->"
      for i = 0; i < items.length(); i = i + 1 {
        result = result + render_with_id(items[i], id_counter)
      }
      result = result + "<!--/f-->"
      result
    }
    VComponent(render=render_fn) => render_with_id(render_fn(), id_counter)
  }
}

///| Check if element has dynamic content that needs hydration
fn has_dynamic_content(attrs : Array[(String, VAttr)]) -> Bool {
  for i = 0; i < attrs.length(); i = i + 1 {
    let (_, value) = attrs[i]
    match value {
      VDynamic(_) | VHandler(_) | VDynamicStyle(_) => return true
      _ => ()
    }
  }
  false
}
