// DOM Rendering - Fine-grained reactive DOM bindings
//

///|
/// Create a reactive text node that updates when the content changes
pub fn text_node(content : () -> String) -> DomNode {
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
pub fn[T : Show] text_from_signal(sig : @signal.Signal[T]) -> DomNode {
  text_node(fn() { sig.get().to_string() })
}

///|
/// Reactive attribute value type
pub(all) enum AttrValue {
  Static(String)
  Dynamic(() -> String)
  Handler((@js.Any) -> Unit)
}

///|
/// Create an element with reactive attributes (returns Node for easy composition)
pub fn create_element(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[DomNode],
) -> DomNode {
  let doc = @js_dom.document()
  let elem = doc.createElement(tag)

  // Apply attributes
  for attr in attrs {
    let (name, value) = attr
    apply_attribute(elem, name, value)
  }

  // Append children
  for child in children {
    elem.as_node().appendChild(child.to_jsdom()) |> ignore
  }
  El(DomElement::from_jsdom(elem))
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
    Handler(handler) =>
      if name == "__ref" {
        // Call ref callback with element (not an event listener)
        handler(elem.as_any())
      } else {
        apply_event_handler(elem, name, handler)
      }
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
    elem.as_any()._set("value", @js.any(value)) |> ignore
  } else if name == "checked" {
    elem.as_any()._set("checked", @js.any(value == "true")) |> ignore
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
  handler : (@js.Any) -> Unit,
) -> Unit =
  #|(elem, name, handler) => elem.addEventListener(name, handler)

///|
/// Apply style string (e.g. "color: red; margin: 10px")
fn apply_style_string(elem : @js_dom.Element, style : String) -> Unit {
  elem.setAttribute("style", style)
}

///|
/// Mount a node to a container
pub fn mount(container : DomElement, n : DomNode) -> Unit {
  container.to_jsdom().as_node().appendChild(n.to_jsdom()) |> ignore
}

///|
/// Mount to a jsdom container (for tests)
pub fn mount_to(container : @js_dom.Element, n : DomNode) -> Unit {
  container.as_node().appendChild(n.to_jsdom()) |> ignore
}

///|
/// Clear a container
pub fn clear(container : DomElement) -> Unit {
  container.to_jsdom().as_node().setTextContent("")
}

///|
/// Clear a jsdom container (for tests)
pub fn clear_jsdom(container : @js_dom.Element) -> Unit {
  container.as_node().setTextContent("")
}

///|
/// Render to a container (clear and mount)
pub fn render(container : DomElement, n : DomNode) -> Unit {
  clear(container)
  mount(container, n)
}

///|
/// Render to a jsdom container (for tests)
pub fn render_to(container : @js_dom.Element, n : DomNode) -> Unit {
  clear_jsdom(container)
  mount_to(container, n)
}

///|
/// Conditional rendering - shows content when condition is true
pub fn show(when : () -> Bool, render_fn : () -> DomNode) -> DomNode {
  let doc = @js_dom.document()
  let placeholder = doc.createComment("show")
  // Capture current owner for context inheritance
  let captured_owner = @signal.get_owner()

  // Evaluate initial state immediately
  let initial_show = when()
  let initial_node : @js_dom.Node? = if initial_show {
    let n = match captured_owner {
      Some(owner) => @signal.run_with_owner(owner, render_fn)
      None => render_fn()
    }
    Some(n.to_jsdom())
  } else {
    None
  }
  let current_node : Ref[@js_dom.Node?] = { val: initial_node }

  // Effect handles subsequent updates only
  let _ = @signal.effect(fn() {
    let should_show = when()
    match (should_show, current_node.val) {
      (true, None) =>
        // Need to show - create and insert node
        if placeholder.parentNode() is Some(parent) {
          let n = match captured_owner {
            Some(owner) => @signal.run_with_owner(owner, render_fn)
            None => render_fn()
          }
          parent.insertBefore(n.to_jsdom(), Some(placeholder)) |> ignore
          current_node.val = Some(n.to_jsdom())
        }
      (false, Some(n)) =>
        // Need to hide - remove node
        if n.parentNode() is Some(parent) {
          parent.removeChild(n) |> ignore
          current_node.val = None
        }
      _ => () // No change needed
    }
  })

  // Return fragment containing initial node (if any) and placeholder
  match initial_node {
    Some(node) => fragment([Raw(node), Raw(placeholder)])
    None => Raw(placeholder)
  }
}

///|
/// List rendering with reference-based DOM reuse (Solid-style)
///
/// Items are tracked by reference equality (JavaScript ===).
/// When items are reordered, their DOM nodes are moved rather than recreated.
pub fn[T] for_each(
  items : () -> Array[T],
  render_item : (T, Int) -> DomNode,
) -> DomNode {
  let doc = @js_dom.document()
  let placeholder = doc.createComment("for")
  let entries : Ref[Array[ItemEntry[T]]] = { val: [] }
  let is_first = { val: true }
  // Capture current owner for context inheritance
  let captured_owner = @signal.get_owner()

  // Helper to run render with captured owner
  fn render_with_owner(item : T, i : Int) -> @js_dom.Node {
    match captured_owner {
      Some(owner) =>
        @signal.run_with_owner(owner, fn() { render_item(item, i) }).to_jsdom()
      None => render_item(item, i).to_jsdom()
    }
  }

  // Initial render
  let fragment = doc.createDocumentFragment()
  let initial_items = items()
  for i, item in initial_items {
    let dom = render_with_owner(item, i)
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
    reconcile_for_each(entries, placeholder, new_items, render_with_owner)
  })
  Raw(fragment.as_node())
}

// =============================================================================
// Index - Index-based list rendering (like Solid.js <Index>)
// =============================================================================

///|
/// Entry for index_each - stores node and its dispose function
priv struct IndexEntry {
  node : @js_dom.Node
  dispose : () -> Unit
}

///|
fn IndexEntry::new(node : @js_dom.Node, dispose : () -> Unit) -> IndexEntry {
  { node, dispose }
}

///|
/// Index-based list rendering - optimized for lists where items are identified by index
/// Unlike for_each which tracks by reference, index_each tracks by index position.
/// When items change at an index, only that element is re-rendered.
///
/// Best used when:
/// - Items are primitives (strings, numbers)
/// - Item identity is by position, not by value
/// - Lists are frequently mutated by index
///
/// Example:
/// ```
/// index_each(
///   fn() { items.get() },
///   fn(item_getter, index) {
///     div(children=[
///       // item_getter() returns current item at this index
///       text_node(fn() { item_getter().to_string() })
///     ])
///   }
/// )
/// ```
pub fn[T] index_each(
  items : () -> Array[T],
  render_item : (() -> T, Int) -> DomNode,
) -> DomNode {
  let doc = @js_dom.document()
  let placeholder = doc.createComment("index")
  let entries : Array[IndexEntry] = []
  let is_first = { val: true }
  // Capture current owner for context inheritance
  let captured_owner = @signal.get_owner()

  // Helper to render item with owner scope for proper cleanup
  fn render_with_scope(index : Int) -> IndexEntry {
    let item_getter = fn() -> T { items()[index] }
    let (dom, dispose) = @signal.create_root_with_dispose(fn() {
      match captured_owner {
        Some(owner) => @signal.run_with_owner(owner, fn() { render_item(item_getter, index) })
        None => render_item(item_getter, index)
      }
    })
    IndexEntry::new(dom.to_jsdom(), dispose)
  }

  // Initial render
  let fragment = doc.createDocumentFragment()
  let initial_items = items()
  for i, _ in initial_items {
    let entry = render_with_scope(i)
    entries.push(entry)
    fragment.as_node().appendChild(entry.node) |> ignore
  }
  fragment.as_node().appendChild(placeholder) |> ignore

  // Update effect
  let _ = @signal.effect(fn() {
    let new_items = items()
    if is_first.val {
      is_first.val = false
      return
    }
    let old_len = entries.length()
    let new_len = new_items.length()

    // Remove excess nodes and dispose their effects
    while entries.length() > new_len {
      let entry = entries.pop()
      match entry {
        Some(e) => {
          // Dispose effects first to prevent stale callbacks
          (e.dispose)()
          if e.node.parentNode() is Some(par) {
            par.removeChild(e.node) |> ignore
          }
        }
        None => ()
      }
    }

    // Add new nodes for indices beyond old length
    while entries.length() < new_len {
      let i = entries.length()
      let entry = render_with_scope(i)
      entries.push(entry)
      if placeholder.parentNode() is Some(par) {
        par.insertBefore(entry.node, Some(placeholder)) |> ignore
      }
    }

    // Note: Existing nodes at indices 0..<min(old_len, new_len) don't need
    // to be re-created since render_item uses a getter that reads current value
    let _ = old_len
    // suppress warning
  })
  Raw(fragment.as_node())
}

// =============================================================================
// Portal - Render content outside the component tree
// =============================================================================

///|
/// Portal - renders content into a different DOM container
/// Similar to Solid.js <Portal>
///
/// Use cases:
/// - Modals that need to render at body level to avoid z-index issues
/// - Dropdowns/tooltips that need to escape overflow: hidden
/// - Full-screen overlays
///
/// Example:
/// ```
/// portal(
///   target=@js_dom.document().body_(),
///   children=[modal_content()]
/// )
/// ```
///
/// Note: For SSR, portals should be handled separately or use a placeholder.
/// The portal content won't appear in the SSR output at the original location.
pub fn portal(target~ : @js_dom.Element, children~ : Array[DomNode]) -> DomNode {
  // Render children into the target container instead of where the portal is placed
  for child in children {
    target.as_node().appendChild(child.to_jsdom()) |> ignore
  }

  // Return a comment placeholder at the original location
  let doc = @js_dom.document()
  let placeholder = doc.createComment("portal")
  Raw(placeholder)
}

///|
/// Portal to body - convenience function for rendering to document.body
pub fn portal_to_body(children : Array[DomNode]) -> DomNode {
  let doc = @js_dom.document()
  match doc.body() {
    Some(body) => portal(target=body.as_element(), children~)
    None => {
      // Fallback: render inline if body not available
      let fragment = doc.createDocumentFragment()
      for child in children {
        fragment.as_node().appendChild(child.to_jsdom()) |> ignore
      }
      Raw(fragment.as_node())
    }
  }
}

///|
/// Portal to a selector - find element by CSS selector and portal to it
pub fn portal_to(selector : String, children : Array[DomNode]) -> DomNode {
  let doc = @js_dom.document()
  match doc.querySelector(selector) {
    Some(target) => portal(target~, children~)
    None => {
      // Fallback: render inline if target not found
      let fragment = doc.createDocumentFragment()
      for child in children {
        fragment.as_node().appendChild(child.to_jsdom()) |> ignore
      }
      Raw(fragment.as_node())
    }
  }
}
