// VNode to JsonNode renderer
// Evaluates dynamic content at render time
//

///|
/// Render a VNode to JsonNode
/// Dynamic values are evaluated at the time of rendering
pub fn render_to_json(node : @luna.Node[Unit, String]) -> JsonNode {
  match node {
    @core.Text(content) => Text(content)
    @core.DynamicText(getter) => Text(getter())
    @core.RawHtml(html) => Text(html) // Treat raw HTML as text in JSON
    @core.Fragment(children) => {
      let json_children : Array[JsonNode] = []
      for child in children {
        json_children.push(render_to_json(child))
      }
      Fragment(json_children)
    }
    @core.Element(elem) => {
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
    @core.Show(condition~, child~) =>
      if condition() {
        render_to_json(child())
      } else {
        Fragment([])
      }
    @core.For(render~) => {
      let items = render()
      let children : Array[JsonNode] = []
      for item in items {
        children.push(render_to_json(item))
      }
      Fragment(children)
    }
    @core.Component(render~) => render_to_json(render())
    @core.Island(island) => {
      // Render Island as an element with luna:* attributes
      let attrs : Map[String, JsonAttrValue] = {}
      attrs.set("luna:id", Static(island.id))
      attrs.set("luna:url", Static(island.url))
      attrs.set("luna:state", Static(island.state))
      attrs.set("luna:client-trigger", Static(island.trigger.to_string()))
      let children : Array[JsonNode] = []
      for child in island.children {
        children.push(render_to_json(child))
      }
      Element({ tag: "div", attrs, children })
    }
    @core.WcIsland(wc_island) => {
      // Render WcIsland as a custom element with data-* attributes
      let attrs : Map[String, JsonAttrValue] = {}
      attrs.set("data-state", Static(wc_island.state))
      attrs.set("data-trigger", Static(wc_island.trigger.to_string()))
      let children : Array[JsonNode] = []
      for child in wc_island.children {
        children.push(render_to_json(child))
      }
      Element({ tag: wc_island.name, attrs, children })
    }
    @core.InternalRef(iref) => {
      // Render InternalRef as element with luna:* or luna:wc-* attributes
      let attrs : Map[String, JsonAttrValue] = {}
      if iref.wc {
        attrs.set("luna:wc-url", Static(iref.url))
        attrs.set("luna:wc-state", Static(iref.state))
        attrs.set("luna:wc-trigger", Static(iref.trigger.to_string()))
      } else {
        attrs.set("luna:url", Static(iref.url))
        attrs.set("luna:state", Static(iref.state))
        attrs.set("luna:client-trigger", Static(iref.trigger.to_string()))
      }
      let children : Array[JsonNode] = []
      for child in iref.children {
        children.push(render_to_json(child))
      }
      let tag = if iref.wc { "wc-internal-ref" } else { "div" }
      Element({ tag, attrs, children })
    }
    @core.Async(async_node) =>
      // Render fallback content for async nodes
      render_to_json((async_node.fallback)())
    @core.ErrorBoundary(boundary) =>
      // For JSON rendering, try to render children, fallback on error
      render_to_json((boundary.children)()) catch {
        err => {
          let reset = fn() { () }
          render_to_json((boundary.fallback)(err, reset)) catch {
            _ => Fragment([]) // Return empty fragment if fallback also fails
          }
        }
      }
    @core.Switch(switch_node) => {
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          return render_to_json((case_.render)())
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) => render_to_json(fallback_fn())
        None => Fragment([])
      }
    }
  }
}

///|
/// Convert VNode attribute to JsonAttrValue
fn convert_attr(attr : @luna.Attr[Unit, String]) -> JsonAttrValue {
  match attr {
    @core.VStatic(value) => Static(value)
    @core.VDynamic(getter) => Dynamic(getter())
    @core.VHandler(_) => Handler
    @core.VAction(name) => Dynamic("action:" + name)
  }
}

///|
/// Render to JSON string (for debugging/serialization)
pub fn render_to_json_string(node : @luna.Node[Unit, String]) -> String {
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
