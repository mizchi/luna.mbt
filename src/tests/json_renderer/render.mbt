///| VNode to JsonNode renderer
///| Evaluates dynamic content at render time

///|
/// Render a VNode to JsonNode
/// Dynamic values are evaluated at the time of rendering
pub fn render_to_json(node : @kaguya.Node[Unit]) -> JsonNode {
  match node {
    @kaguya.Text(content) => Text(content)
    @kaguya.DynamicText(getter) => Text(getter())
    @kaguya.Fragment(children) => {
      let json_children : Array[JsonNode] = []
      for child in children {
        json_children.push(render_to_json(child))
      }
      Fragment(json_children)
    }
    @kaguya.Element(elem) => {
      let attrs : Map[String, JsonAttrValue] = {}
      for pair in elem.attrs {
        let (name, value) = pair
        attrs.set(name, convert_attr(value))
      }
      let children : Array[JsonNode] = []
      for child in elem.children {
        children.push(render_to_json(child))
      }
      Element({ tag: elem.tag, attrs, children })
    }
    @kaguya.Show(condition~, child~) => {
      if condition() {
        render_to_json(child())
      } else {
        Fragment([])
      }
    }
    @kaguya.For(render~) => {
      let items = render()
      let children : Array[JsonNode] = []
      for item in items {
        children.push(render_to_json(item))
      }
      Fragment(children)
    }
    @kaguya.Component(render~) => render_to_json(render())
    @kaguya.Island(island) => {
      // Render Island as an element with kg:* attributes
      let attrs : Map[String, JsonAttrValue] = {}
      attrs.set("kg:id", Static(island.id))
      attrs.set("kg:url", Static(island.url))
      attrs.set("kg:state", Static(island.state))
      attrs.set("kg:trigger", Static(@kaguya.trigger_to_string(island.trigger)))
      let children : Array[JsonNode] = []
      for child in island.children {
        children.push(render_to_json(child))
      }
      Element({ tag: "div", attrs, children })
    }
  }
}

///|
/// Convert VNode attribute to JsonAttrValue
fn convert_attr(attr : @kaguya.Attr[Unit]) -> JsonAttrValue {
  match attr {
    @kaguya.VStatic(value) => Static(value)
    @kaguya.VDynamic(getter) => Dynamic(getter())
    @kaguya.VHandler(_) => Handler
    @kaguya.VAction(name) => Dynamic("action:" + name)
  }
}

///|
/// Render to JSON string (for debugging/serialization)
pub fn render_to_json_string(node : @kaguya.Node[Unit]) -> String {
  let json_node = render_to_json(node)
  json_node_to_string(json_node)
}

///|
/// Convert JsonNode to JSON string
pub fn json_node_to_string(node : JsonNode) -> String {
  let sb = StringBuilder::new()
  write_json_node(sb, node)
  sb.to_string()
}

///|
fn write_json_node(sb : StringBuilder, node : JsonNode) -> Unit {
  match node {
    Text(content) => {
      sb.write_string("{\"type\":\"text\",\"content\":")
      write_json_string(sb, content)
      sb.write_string("}")
    }
    Fragment(children) => {
      sb.write_string("{\"type\":\"fragment\",\"children\":[")
      for i, child in children {
        if i > 0 {
          sb.write_string(",")
        }
        write_json_node(sb, child)
      }
      sb.write_string("]}")
    }
    Element(elem) => {
      sb.write_string("{\"type\":\"element\",\"tag\":")
      write_json_string(sb, elem.tag)
      sb.write_string(",\"attrs\":{")
      let mut first = true
      elem.attrs.each(fn(name, value) {
        if not(first) {
          sb.write_string(",")
        }
        first = false
        write_json_string(sb, name)
        sb.write_string(":")
        write_attr_value(sb, value)
      })
      sb.write_string("},\"children\":[")
      for i, child in elem.children {
        if i > 0 {
          sb.write_string(",")
        }
        write_json_node(sb, child)
      }
      sb.write_string("]}")
    }
  }
}

///|
fn write_attr_value(sb : StringBuilder, value : JsonAttrValue) -> Unit {
  match value {
    Static(s) => {
      sb.write_string("{\"type\":\"static\",\"value\":")
      write_json_string(sb, s)
      sb.write_string("}")
    }
    Dynamic(s) => {
      sb.write_string("{\"type\":\"dynamic\",\"value\":")
      write_json_string(sb, s)
      sb.write_string("}")
    }
    Handler => sb.write_string("{\"type\":\"handler\"}")
  }
}

///|
fn write_json_string(sb : StringBuilder, s : String) -> Unit {
  sb.write_string("\"")
  for c in s {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
  sb.write_string("\"")
}
