// HTML Renderer for AbstractNode
//
// Converts AbstractNode tree to HTML string.
// Framework-agnostic, pure MoonBit implementation.

///|
/// Render AbstractNode to HTML string
pub fn AbstractNode::render_html(self : AbstractNode) -> String {
  let sb = StringBuilder::new(size_hint=256)
  self.render_html_to(sb)
  sb.to_string()
}

///|
/// Render AbstractNode to StringBuilder
fn AbstractNode::render_html_to(
  self : AbstractNode,
  sb : StringBuilder,
) -> Unit {
  match self {
    Text(content) => escape_html_to(sb, content)
    RawHtml(html) => sb.write_string(html)
    Fragment(children) =>
      for child in children {
        child.render_html_to(sb)
      }
    Element(tag~, attrs~, children~) => {
      sb.write_char('<')
      sb.write_string(tag)
      render_attrs_to(sb, attrs)
      if is_void_element(tag) {
        sb.write_string(" />")
      } else {
        sb.write_char('>')
        for child in children {
          child.render_html_to(sb)
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    Component(config~, children~) => render_component_to(sb, config, children)
    Slot(name~, fallback~) => {
      // Render slot as a marker comment + fallback content
      sb.write_string("<!--slot:")
      sb.write_string(name)
      sb.write_string("-->")
      for child in fallback {
        child.render_html_to(sb)
      }
      sb.write_string("<!--/slot-->")
    }
  }
}

///|
/// Render component based on its render mode
fn render_component_to(
  sb : StringBuilder,
  config : ComponentConfig,
  children : Array[AbstractNode],
) -> Unit {
  match config.mode {
    SSROnly =>
      // Just render children, no hydration markers
      for child in children {
        child.render_html_to(sb)
      }
    Hydration(trigger) => {
      // Render with hydration wrapper
      sb.write_string("<div data-island=\"")
      sb.write_string(config.name)
      sb.write_string("\" data-trigger=\"")
      sb.write_string(trigger.to_attr_string())
      sb.write_string("\" data-props=\"")
      escape_attr_to(sb, config.props.to_string())
      sb.write_string("\">")
      for child in children {
        child.render_html_to(sb)
      }
      sb.write_string("</div>")
    }
    ClientOnly => {
      // Render placeholder for client-side rendering
      sb.write_string("<div data-client-only=\"")
      sb.write_string(config.name)
      sb.write_string("\" data-props=\"")
      escape_attr_to(sb, config.props.to_string())
      sb.write_string("\">")
      // Show loading placeholder or nothing
      sb.write_string("<!--loading-->")
      sb.write_string("</div>")
    }
    ServerDefer => {
      // Server Islands - placeholder for deferred server rendering
      sb.write_string("<div data-server-island=\"")
      sb.write_string(config.name)
      sb.write_string("\" data-props=\"")
      escape_attr_to(sb, config.props.to_string())
      sb.write_string("\">")
      // Show fallback content
      for child in children {
        child.render_html_to(sb)
      }
      sb.write_string("</div>")
    }
  }
}

///|
/// Render attributes to StringBuilder
fn render_attrs_to(
  sb : StringBuilder,
  attrs : Array[(String, AttrValue)],
) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      Str(s) => render_attr_value(sb, name, s)
      Bool(b) =>
        if b {
          // Boolean attribute - just add the name
          sb.write_char(' ')
          sb.write_string(name)
        }
      Num(n) => {
        sb.write_char(' ')
        sb.write_string(name)
        sb.write_string("=\"")
        sb.write_string(n.to_string())
        sb.write_char('"')
      }
      Json(j) => {
        sb.write_char(' ')
        sb.write_string(name)
        sb.write_string("=\"")
        escape_attr_to(sb, j.to_string())
        sb.write_char('"')
      }
    }
  }
}

///|
/// Render a single attribute value
fn render_attr_value(sb : StringBuilder, name : String, s : String) -> Unit {
  if s.is_empty() {
    // Boolean attribute (like disabled, checked)
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

///|
/// Escape HTML content
fn escape_html_to(sb : StringBuilder, s : String) -> Unit {
  for c in s {
    match c {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '\'' => sb.write_string("&#39;")
      '"' => sb.write_string("&quot;")
      _ => sb.write_char(c)
    }
  }
}

///|
/// Escape attribute value
fn escape_attr_to(sb : StringBuilder, s : String) -> Unit {
  for c in s {
    match c {
      '&' => sb.write_string("&amp;")
      '"' => sb.write_string("&quot;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      _ => sb.write_char(c)
    }
  }
}

///|
/// Check if tag is a void element (self-closing)
fn is_void_element(tag : String) -> Bool {
  match tag {
    "area"
    | "base"
    | "br"
    | "col"
    | "embed"
    | "hr"
    | "img"
    | "input"
    | "link"
    | "meta"
    | "param"
    | "source"
    | "track"
    | "wbr" => true
    _ => false
  }
}
