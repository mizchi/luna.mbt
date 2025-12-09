///| DOM Rendering - Fine-grained reactive DOM bindings

///|
/// Create a reactive text node that updates when the content changes
pub fn text_node(content : () -> String) -> Node {
  let doc = @jsdom.document()
  let initial = content()
  let node = doc.createTextNode(initial)

  // Set up effect to update text when content changes
  let _ = @signals.effect(fn() {
    let new_content = content()
    node.as_node().setTextContent(new_content)
  })
  Txt(node)
}

///|
/// Create a reactive text node from a signal
pub fn[T : Show] text_from_signal(sig : @signals.Signal[T]) -> Node {
  text_node(fn() { sig.get().to_string() })
}

///|
/// Reactive attribute value type
pub enum AttrValue {
  Static(String)
  Dynamic(() -> String)
  Handler((@core.Any) -> Unit)
  StyleObj(Array[(String, String)])
  DynamicStyle(() -> Array[(String, String)])
}

///|
/// Create an element with reactive attributes (returns Node for easy composition)
pub fn create_element(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  let doc = @jsdom.document()
  let elem = doc.createElement(tag)

  // Apply attributes
  for i = 0; i < attrs.length(); i = i + 1 {
    let (name, value) = attrs[i]
    apply_attribute(elem, name, value)
  }

  // Append children
  for i = 0; i < children.length(); i = i + 1 {
    elem.as_node().appendChild(children[i].to_jsdom()) |> ignore
  }
  El(Element::from_jsdom(elem))
}

///|
/// Apply a single attribute to an element
fn apply_attribute(
  elem : @jsdom.Element,
  name : String,
  value : AttrValue,
) -> Unit {
  match value {
    Static(s) => apply_static_attr(elem, name, s)
    Dynamic(getter) => {
      // Set up effect to update attribute when value changes
      let _ = @signals.effect(fn() {
        let new_value = getter()
        apply_static_attr(elem, name, new_value)
      })

    }
    Handler(handler) => apply_event_handler(elem, name, handler)
    StyleObj(styles) => apply_style_object(elem, styles)
    DynamicStyle(getter) => {
      let _ = @signals.effect(fn() {
        let styles = getter()
        apply_style_object(elem, styles)
      })

    }
  }
}

///|
/// Apply a static attribute value
fn apply_static_attr(
  elem : @jsdom.Element,
  name : String,
  value : String,
) -> Unit {
  if name == "className" {
    elem.setClassName(value)
  } else if name == "value" {
    // Special handling for input value
    elem.as_any()._set("value", @core.any(value)) |> ignore
  } else if name == "checked" {
    elem.as_any()._set("checked", @core.any(value == "true")) |> ignore
  } else if name == "disabled" {
    if value == "true" {
      elem.setAttribute("disabled", "")
    } else {
      elem.removeAttribute("disabled")
    }
  } else {
    elem.setAttribute(name, value)
  }
}

///|
/// Apply an event handler
fn apply_event_handler(
  elem : @jsdom.Element,
  name : String,
  handler : (@core.Any) -> Unit,
) -> Unit {
  // Convert "onClick" to "click", "onInput" to "input", etc.
  let event_name = if name.length() >= 2 {
    // Check if starts with "on"
    if name.code_unit_at(0) == "o".code_unit_at(0) &&
      name.code_unit_at(1) == "n".code_unit_at(0) {
      // Convert rest to lowercase manually
      let mut result = ""
      let iter = name.iter()
      let mut skip_count = 0
      for char in iter {
        if skip_count < 2 {
          skip_count = skip_count + 1
          continue
        }
        let lower_char = if char >= 'A' && char <= 'Z' {
          (char.to_int() + 32).unsafe_to_char()
        } else {
          char
        }
        result = result + lower_char.to_string()
      }
      result
    } else {
      name
    }
  } else {
    name
  }
  let handler_any : @core.Any = @core.any(handler)
  elem.as_event_target().addEventListener(event_name, handler_any.cast())
}

///|
/// Apply style object
fn apply_style_object(
  elem : @jsdom.Element,
  styles : Array[(String, String)],
) -> Unit {
  let style_prop : @core.Any = elem.as_any()._get("style")
  for i = 0; i < styles.length(); i = i + 1 {
    let (prop, value) = styles[i]
    style_prop._set(prop, @core.any(value)) |> ignore
  }
}

///|
/// Mount a node to a container
pub fn mount(container : Element, n : Node) -> Unit {
  container.to_jsdom().as_node().appendChild(n.to_jsdom()) |> ignore
}

///|
/// Mount to a jsdom container (for tests)
pub fn mount_to(container : @jsdom.Element, n : Node) -> Unit {
  container.as_node().appendChild(n.to_jsdom()) |> ignore
}

///|
/// Clear a container
pub fn clear(container : Element) -> Unit {
  container.to_jsdom().as_node().setTextContent("")
}

///|
/// Clear a jsdom container (for tests)
pub fn clear_jsdom(container : @jsdom.Element) -> Unit {
  container.as_node().setTextContent("")
}

///|
/// Render to a container (clear and mount)
pub fn render(container : Element, n : Node) -> Unit {
  clear(container)
  mount(container, n)
}

///|
/// Render to a jsdom container (for tests)
pub fn render_to(container : @jsdom.Element, n : Node) -> Unit {
  clear_jsdom(container)
  mount_to(container, n)
}

///|
/// Conditional rendering - shows content when condition is true
pub fn show(when : () -> Bool, render_fn : () -> Node) -> Node {
  let doc = @jsdom.document()
  let placeholder = doc.createComment("show")
  let mut current_node : @jsdom.Node? = None
  let _ = @signals.effect(fn() {
    let should_show = when()
    match (should_show, current_node) {
      (true, None) => {
        // Need to show - create and insert node
        let n = render_fn()
        match placeholder.parentNode() {
          Some(parent) => {
            parent.insertBefore(n.to_jsdom(), Some(placeholder)) |> ignore
            current_node = Some(n.to_jsdom())
          }
          None => ()
        }
      }
      (false, Some(n)) =>
        // Need to hide - remove node
        match n.parentNode() {
          Some(parent) => {
            parent.removeChild(n) |> ignore
            current_node = None
          }
          None => ()
        }
      _ => () // No change needed
    }
  })
  Raw(placeholder)
}

///|
/// List rendering with keyed updates
pub fn[T] for_each(
  items : () -> Array[T],
  render_item : (T, Int) -> Node,
) -> Node {
  let doc = @jsdom.document()
  let container = doc.createDocumentFragment()
  let mut current_nodes : Array[@jsdom.Node] = []
  let _ = @signals.effect(fn() {
    let new_items = items()

    // Simple strategy: remove all and re-render
    // (Can be optimized with keyed reconciliation later)
    for i = 0; i < current_nodes.length(); i = i + 1 {
      match current_nodes[i].parentNode() {
        Some(parent) => parent.removeChild(current_nodes[i]) |> ignore
        None => ()
      }
    }
    current_nodes = []
    for i = 0; i < new_items.length(); i = i + 1 {
      let n = render_item(new_items[i], i)
      let jsdom_node = n.to_jsdom()
      current_nodes.push(jsdom_node)
      container.as_node().appendChild(jsdom_node) |> ignore
    }
  })
  Raw(container.as_node())
}
