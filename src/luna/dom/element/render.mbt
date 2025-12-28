// DOM Rendering - Fine-grained reactive DOM bindings
//

///|
/// Create a reactive text node that updates when the content changes
pub fn text_node(content : () -> String) -> DomNode {
  let doc = @js_dom.document()
  let initial = content()
  let node = doc.createTextNode(initial)

  // RenderEffect for DOM updates (synchronous)
  let _ = @signal.render_effect(fn() {
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
/// SVG namespace constant
pub let svg_ns : String = "http://www.w3.org/2000/svg"

///|
/// MathML namespace constant
pub let mathml_ns : String = "http://www.w3.org/1998/Math/MathML"

///|
/// FFI for createElementNS
extern "js" fn create_element_ns_ffi(
  ns : String,
  tag : String,
) -> @js_dom.Element =
  #| (ns, tag) => document.createElementNS(ns, tag)

///|
/// Create an element with namespace (for SVG, MathML, etc.)
/// Use this for SVG elements since they require the SVG namespace.
///
/// Example:
/// ```moonbit
/// // Create an SVG rectangle
/// let rect = create_element_ns(
///   svg_ns,
///   "rect",
///   [
///     ("x", Static("10")),
///     ("y", Static("10")),
///     ("width", Static("100")),
///     ("height", Static("50")),
///     ("fill", Static("blue")),
///   ],
///   [],
/// )
/// ```
pub fn create_element_ns(
  ns : String,
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[DomNode],
) -> DomNode {
  let elem = create_element_ns_ffi(ns, tag)

  // Apply attributes
  for attr in attrs {
    let (name, value) = attr
    apply_attribute(elem, name, value)
  }

  // Append children
  for child in children {
    elem.as_node().appendChild(child.to_dom()) |> ignore
  }
  El(DomElement::from_dom(elem))
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
    elem.as_node().appendChild(child.to_dom()) |> ignore
  }
  El(DomElement::from_dom(elem))
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
      // RenderEffect for DOM updates (synchronous)
      let _ = @signal.render_effect(fn() {
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
  container.to_dom().as_node().appendChild(n.to_dom()) |> ignore
}

///|
/// Mount to a jsdom container (for tests)
pub fn mount_to(container : @js_dom.Element, n : DomNode) -> Unit {
  container.as_node().appendChild(n.to_dom()) |> ignore
}

///|
/// Clear a container
pub fn clear(container : DomElement) -> Unit {
  container.to_dom().as_node().setTextContent("")
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
/// Helper to collect child nodes from a DomNode.
/// If it's a DocumentFragment, collects all children; otherwise returns single node.
fn collect_child_nodes(node : @js_dom.Node) -> Array[@js_dom.Node] {
  // Check if node is a DocumentFragment by nodeType (11 = DocumentFragment)
  if node.nodeType() == 11 {
    // DocumentFragment: collect all children before they are moved
    let children : Array[@js_dom.Node] = []
    while node.firstChild() is Some(child) {
      children.push(child)
      node.removeChild(child) |> ignore
    }
    children
  } else {
    [node]
  }
}

///|
/// Conditional rendering - shows content when condition is true
/// Creates a child owner for proper cleanup when content is hidden
pub fn show(when : () -> Bool, render_fn : () -> DomNode) -> DomNode {
  let doc = @js_dom.document()
  let placeholder = doc.createComment("show")
  // Capture current owner for context inheritance
  let captured_owner = @signal.get_owner()

  // Track current dispose function (for cleanup when hiding)
  let current_dispose : Ref[(() -> Unit)?] = { val: None }

  // Helper to render with a new child owner scope
  fn render_with_scope() -> Array[@js_dom.Node] {
    // Set parent owner context first so the new root becomes its child
    // Then create a child root that owns the rendered content
    let result : Ref[Array[@js_dom.Node]] = { val: [] }
    fn do_render() {
      let (dom, dispose) = @signal.create_root_with_dispose(fn() {
        // render_fn runs with the new root as current owner
        // so onMount/onCleanup are registered on this root
        render_fn()
      })
      current_dispose.val = Some(dispose)
      result.val = collect_child_nodes(dom.to_dom())
    }
    match captured_owner {
      Some(parent) => @signal.run_with_owner(parent, do_render)
      None => do_render()
    }
    result.val
  }

  // Evaluate initial state immediately
  let initial_show = when()
  let initial_nodes : Array[@js_dom.Node] = if initial_show {
    render_with_scope()
  } else {
    []
  }
  // Track all child nodes (may be multiple if fragment was used)
  let current_nodes : Ref[Array[@js_dom.Node]] = { val: initial_nodes }

  // RenderEffect handles subsequent updates only (synchronous DOM updates)
  let _ = @signal.render_effect(fn() {
    let should_show = when()
    let has_nodes = current_nodes.val.length() > 0
    match (should_show, has_nodes) {
      (true, false) =>
        // Need to show - create and insert nodes
        if placeholder.parentNode() is Some(parent) {
          let nodes = render_with_scope()
          for node in nodes {
            parent.insertBefore(node, Some(placeholder)) |> ignore
          }
          current_nodes.val = nodes
        }
      (false, true) => {
        // Need to hide - dispose child owner first (runs cleanups)
        match current_dispose.val {
          Some(dispose) => {
            dispose()
            current_dispose.val = None
          }
          None => ()
        }
        // Then remove all nodes
        for node in current_nodes.val {
          if node.parentNode() is Some(parent) {
            parent.removeChild(node) |> ignore
          }
        }
        current_nodes.val = ([] : Array[@js_dom.Node])
      }
      _ => () // No change needed
    }
  })

  // Return fragment containing initial nodes (if any) and placeholder
  if initial_nodes.length() > 0 {
    let all_nodes : Array[DomNode] = []
    for node in initial_nodes {
      all_nodes.push(Raw(node))
    }
    all_nodes.push(Raw(placeholder))
    fragment(all_nodes)
  } else {
    Raw(placeholder)
  }
}

///|
/// List rendering with reference-based DOM reuse (Solid-style)
///
/// Items are tracked by reference equality (JavaScript ===).
/// When items are reordered, their DOM nodes are moved rather than recreated.
/// Each item gets its own owner scope for proper cleanup when removed.
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

  // Helper to render with a new child owner scope
  // Returns both the DOM node and a dispose function
  fn render_with_scope(item : T, i : Int) -> (@js_dom.Node, () -> Unit) {
    fn do_render() -> (@js_dom.Node, () -> Unit) {
      let (dom, dispose) = @signal.create_root_with_dispose(fn() {
        render_item(item, i)
      })
      (dom.to_dom(), dispose)
    }
    match captured_owner {
      Some(parent) => @signal.run_with_owner(parent, fn() { do_render() })
      None => do_render()
    }
  }

  // Initial render - create entries with proper dispose functions
  let fragment = doc.createDocumentFragment()
  let initial_items = items()
  for i, item in initial_items {
    let (dom, dispose) = render_with_scope(item, i)
    entries.val.push(ItemEntry::new_with_dispose(item, dom, dispose))
    fragment.as_node().appendChild(dom) |> ignore
  }
  fragment.as_node().appendChild(placeholder) |> ignore

  // RenderEffect for DOM updates (synchronous)
  let _ = @signal.render_effect(fn() {
    let new_items = items()
    if is_first.val {
      is_first.val = false
      return
    }
    reconcile_for_each_with_dispose(entries, placeholder, new_items, render_with_scope)
  })
  Raw(fragment.as_node())
}

// =============================================================================
// Index - Index-based list rendering (like Solid.js <Index>)
// =============================================================================

///|
/// Entry for index_each - stores node, dispose function, and disposed flag
priv struct IndexEntry {
  node : @js_dom.Node
  dispose : () -> Unit
  disposed : Ref[Bool]
}

///|
fn IndexEntry::new(
  node : @js_dom.Node,
  dispose : () -> Unit,
  disposed : Ref[Bool],
) -> IndexEntry {
  { node, dispose, disposed }
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
    let disposed : Ref[Bool] = { val: false }
    // Cache last valid value for when array shrinks and effect hasn't been disposed yet
    let cached_value : Ref[T?] = { val: None }
    // Guard against out-of-bounds access during effect cleanup transition.
    // When items are deleted, effects may still run briefly before disposal.
    // Use cached value when index is out of bounds.
    let item_getter = fn() -> T {
      let arr = items()
      let len = arr.length()
      if disposed.val || len == 0 || index >= len {
        // Effect is disposed or index is out of bounds
        // Return cached value if available
        match cached_value.val {
          Some(v) => v
          None =>
            // No cached value - this can happen if items() changed before first access
            // Use first item as fallback if available
            if len > 0 {
              arr[0]
            } else {
              // Array is empty, no valid fallback
              // This is a race condition during cleanup - abort with clear message
              abort("index_each: array is empty during stale effect execution")
            }
        }
      } else {
        let value = arr[index]
        cached_value.val = Some(value)
        value
      }
    }
    let (dom, dispose) = @signal.create_root_with_dispose(fn() {
      match captured_owner {
        Some(owner) =>
          @signal.run_with_owner(owner, fn() { render_item(item_getter, index) })
        None => render_item(item_getter, index)
      }
    })
    IndexEntry::new(dom.to_dom(), dispose, disposed)
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

  // RenderEffect for DOM updates (synchronous)
  let _ = @signal.render_effect(fn() {
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
          // Mark as disposed FIRST to prevent stale effect execution
          e.disposed.val = true
          // Then dispose effects
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
    target.as_node().appendChild(child.to_dom()) |> ignore
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
        fragment.as_node().appendChild(child.to_dom()) |> ignore
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
        fragment.as_node().appendChild(child.to_dom()) |> ignore
      }
      Raw(fragment.as_node())
    }
  }
}
