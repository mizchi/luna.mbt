///| DOM Rendering - Fine-grained reactive DOM bindings

///|
/// Create a reactive text node that updates when the content changes
pub fn text_node(content : () -> String) -> Node {
  let doc = @js_dom.document()
  let initial = content()
  let node = doc.createTextNode(initial)

  // Set up effect to update text when content changes
  let _ = @signal.effect(fn() {
    let new_content = content()
    node.as_node().setTextContent(new_content)
  })
  Txt(node)
}

///|
/// Create a reactive text node from a signal
pub fn[T : Show] text_from_signal(sig : @signal.Signal[T]) -> Node {
  text_node(fn() { sig.get().to_string() })
}

///|
/// Reactive attribute value type
pub(all) enum AttrValue {
  Static(String)
  Dynamic(() -> String)
  Handler((@core.Any) -> Unit)
}

///|
/// Create an element with reactive attributes (returns Node for easy composition)
pub fn create_element(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  let doc = @js_dom.document()
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
  elem : @js_dom.Element,
  name : String,
  value : AttrValue,
) -> Unit {
  match value {
    Static(s) =>
      if name == "style" {
        apply_style_string(elem, s)
      } else {
        apply_static_attr(elem, name, s)
      }
    Dynamic(getter) => {
      // Set up effect to update attribute when value changes
      let _ = @signal.effect(fn() {
        let new_value = getter()
        if name == "style" {
          apply_style_string(elem, new_value)
        } else {
          apply_static_attr(elem, name, new_value)
        }
      })

    }
    Handler(handler) => apply_event_handler(elem, name, handler)
  }
}

///|
/// Apply a static attribute value
fn apply_static_attr(
  elem : @js_dom.Element,
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
/// Event names are already lowercase (click, input, etc.) - no conversion needed
extern "js" fn apply_event_handler(
  elem : @js_dom.Element,
  name : String,
  handler : (@core.Any) -> Unit,
) -> Unit =
  #|(elem, name, handler) => elem.addEventListener(name, handler)

///|
/// Apply style string (e.g. "color: red; margin: 10px")
fn apply_style_string(elem : @js_dom.Element, style : String) -> Unit {
  elem.setAttribute("style", style)
}

///|
/// Mount a node to a container
pub fn mount(container : Element, n : Node) -> Unit {
  container.to_jsdom().as_node().appendChild(n.to_jsdom()) |> ignore
}

///|
/// Mount to a jsdom container (for tests)
pub fn mount_to(container : @js_dom.Element, n : Node) -> Unit {
  container.as_node().appendChild(n.to_jsdom()) |> ignore
}

///|
/// Clear a container
pub fn clear(container : Element) -> Unit {
  container.to_jsdom().as_node().setTextContent("")
}

///|
/// Clear a jsdom container (for tests)
pub fn clear_jsdom(container : @js_dom.Element) -> Unit {
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
pub fn render_to(container : @js_dom.Element, n : Node) -> Unit {
  clear_jsdom(container)
  mount_to(container, n)
}

///|
/// Conditional rendering - shows content when condition is true
pub fn show(when : () -> Bool, render_fn : () -> Node) -> Node {
  let doc = @js_dom.document()
  let placeholder = doc.createComment("show")
  let mut current_node : @js_dom.Node? = None
  let _ = @signal.effect(fn() {
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
/// List rendering with reference-based DOM reuse (Solid-style)
///
/// Items are tracked by reference equality (JavaScript ===).
/// When items are reordered, their DOM nodes are moved rather than recreated.
pub fn[T] for_each(
  items : () -> Array[T],
  render_item : (T, Int) -> Node,
) -> Node {
  let doc = @js_dom.document()
  let placeholder = doc.createComment("for")
  let entries : Ref[Array[ItemEntry[T]]] = { val: [] }
  let is_first = { val: true }

  // Initial render
  let fragment = doc.createDocumentFragment()
  let initial_items = items()
  for i = 0; i < initial_items.length(); i = i + 1 {
    let item = initial_items[i]
    let dom = render_item(item, i).to_jsdom()
    entries.val.push(ItemEntry::new(item, dom))
    fragment.as_node().appendChild(dom) |> ignore
  }
  fragment.as_node().appendChild(placeholder) |> ignore

  // Update effect using reconciliation
  let _ = @signal.effect(fn() {
    let new_items = items()
    if is_first.val {
      is_first.val = false
      return
    }
    reconcile_for_each(
      entries,
      placeholder,
      new_items,
      fn(item, i) { render_item(item, i).to_jsdom() },
    )
  })

  Raw(fragment.as_node())
}
