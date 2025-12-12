///| Hydration - Connect VNode to existing server-rendered DOM

///|
/// Hydration result type
pub enum HydrationResult {
  Success
  Mismatch(String)
  Recovered(String)
}

// HydrationResult constructors for external access

///|
pub fn hydration_result_success() -> HydrationResult {
  Success
}

///|
pub fn hydration_result_mismatch(msg : String) -> HydrationResult {
  Mismatch(msg)
}

///|
pub fn hydration_result_recovered(msg : String) -> HydrationResult {
  Recovered(msg)
}

// HydrationResult predicates and accessors

///|
pub fn HydrationResult::is_success(self : HydrationResult) -> Bool {
  match self {
    Success => true
    _ => false
  }
}

///|
pub fn HydrationResult::is_mismatch(self : HydrationResult) -> Bool {
  match self {
    Mismatch(_) => true
    _ => false
  }
}

///|
pub fn HydrationResult::is_recovered(self : HydrationResult) -> Bool {
  match self {
    Recovered(_) => true
    _ => false
  }
}

///|
pub fn HydrationResult::get_message(self : HydrationResult) -> String {
  match self {
    Success => ""
    Mismatch(msg) => msg
    Recovered(msg) => msg
  }
}

///|
/// Hydration context to track current position in DOM
priv struct HydrationContext {
  container : @js_dom.Element
  mut current_id : Int
  mismatches : Array[String]
}

///|
/// Log a hydration warning to logger or console
fn warn_hydration(logger : StringBuilder?, msg : String) -> Unit {
  let full_msg = "[Hydration] " + msg
  match logger {
    Some(sb) => {
      sb.write_string(full_msg)
      sb.write_string("\n")
    }
    None => {
      let global = @global.global_this()
      let console = global["console"]
      console._call("warn", [@js.any(full_msg)]) |> ignore
    }
  }
}

///|
/// Helper to get text content with default
fn get_text_content(node : @js_dom.Node) -> String {
  let data : @js.Any = node.as_any()._get("data")
  data.cast()
}

///|
/// Hydrate a VNode into an existing DOM container.
/// The container should already have server-rendered HTML with hydration markers.
pub fn hydrate(
  container : @js_dom.Element,
  node : @luna.Node[@js.Any],
  recover_on_mismatch? : Bool,
  warn_on_mismatch? : Bool,
  logger? : StringBuilder,
) -> HydrationResult {
  let recover = recover_on_mismatch.unwrap_or(true)
  let warn = warn_on_mismatch.unwrap_or(true)
  let ctx : HydrationContext = { container, current_id: 0, mismatches: [] }
  hydrate_node(container.as_node(), node, ctx)

  // Check for mismatches
  if ctx.mismatches.length() > 0 {
    let mismatch_msg = ctx.mismatches
      .iter()
      .fold(init="", fn(acc, msg) {
        if acc == "" {
          msg
        } else {
          acc + "; " + msg
        }
      })
    if warn {
      warn_hydration(logger, "Hydration mismatch detected: " + mismatch_msg)
    }
    if recover {
      // Recovery: clear and re-render
      warn_hydration(logger, "Recovering by re-rendering...")
      container.as_node().setTextContent("")
      let dom_node = render_vnode_to_dom(node)
      container.as_node().appendChild(dom_node) |> ignore
      Recovered(mismatch_msg)
    } else {
      Mismatch(mismatch_msg)
    }
  } else {
    Success
  }
}

///|
/// Internal: Hydrate a single node
fn hydrate_node(
  parent : @js_dom.Node,
  node : @luna.Node[@js.Any],
  ctx : HydrationContext,
) -> Unit {
  match node {
    @luna.Text(_) =>
      // Static text doesn't need hydration
      ()
    @luna.DynamicText(getter) => {
      // Find the text marker comments and set up effect
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_dynamic_text(parent, id, getter)
    }
    @luna.Fragment(children) =>
      for i = 0; i < children.length(); i = i + 1 {
        hydrate_node(parent, children[i], ctx)
      }
    @luna.Element(elem) => {
      // Check if this element needs hydration (has handlers or dynamic attrs)
      let needs_hydration = @luna.has_dynamic_content(elem.attrs)

      // Always increment id to match SSR counter
      let id = ctx.current_id
      ctx.current_id = id + 1

      // Find the DOM element
      let dom_elem_opt : @js_dom.Element? = if needs_hydration {
        // For elements with dynamic content, find by data-hk attribute
        match find_element_by_hk(ctx.container, id) {
          Some(dom_elem) => {
            // Verify tag matches
            let dom_tag = dom_elem.tagName().to_lower()
            if dom_tag != elem.tag {
              ctx.mismatches.push(
                "Element tag mismatch at hk=" +
                id.to_string() +
                ": expected <" +
                elem.tag +
                ">, got <" +
                dom_tag +
                ">",
              )
            }
            // Attach event handlers and dynamic attributes
            hydrate_element(dom_elem, elem.attrs)
            Some(dom_elem)
          }
          None => {
            ctx.mismatches.push(
              "Element not found: expected <" +
              elem.tag +
              "> with data-hk=\"" +
              id.to_string() +
              "\"",
            )
            None
          }
        }
      } else {
        // For static elements, find by traversing from parent
        find_child_element_by_tag(parent, elem.tag)
      }

      // Hydrate children
      match dom_elem_opt {
        Some(dom_elem) =>
          for i = 0; i < elem.children.length(); i = i + 1 {
            hydrate_node(dom_elem.as_node(), elem.children[i], ctx)
          }
        None => ()
      }
    }
    @luna.Show(condition=cond, child=child_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_show(parent, id, cond, child_fn, ctx)
    }
    @luna.For(render=render_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_for(parent, id, render_fn, ctx)
    }
    @luna.Component(render=render_fn) => hydrate_node(parent, render_fn(), ctx)
    @luna.Island(island) =>
      // Island hydration is handled by the loader, not this function
      // Just hydrate children normally for nested content
      for child in island.children {
        hydrate_node(parent, child, ctx)
      }
    @luna.Async(async_node) => {
      // Async node hydration: hydrate the fallback content
      // Full async replacement would happen via streaming SSR
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_node(parent, (async_node.fallback)(), ctx)
    }
  }
}

///|
/// Find element with data-hk="id" attribute within container
fn find_element_by_hk(
  container : @js_dom.Element,
  id : Int,
) -> @js_dom.Element? {
  let selector = "[data-hk=\"" + id.to_string() + "\"]"
  container.querySelector(selector)
}

///|
/// Find first child element with matching tag name
fn find_child_element_by_tag(
  parent : @js_dom.Node,
  tag : String,
) -> @js_dom.Element? {
  let children = parent.childNodes()
  let upper_tag = tag.to_upper()
  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
    if child.nodeType() == 1 { // Element node
      let elem : @js_dom.Element = child.as_any().cast()
      if elem.tagName() == upper_tag {
        return Some(elem)
      }
    }
  }
  None
}

///|
/// Hydrate dynamic text node
fn hydrate_dynamic_text(
  parent : @js_dom.Node,
  id : Int,
  getter : () -> String,
) -> Unit {
  // Find the text marker comments <!--t:id-->...<!--/t-->
  let marker_start = "t:" + id.to_string()
  let children = parent.childNodes()
  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        // Found start marker, next sibling should be the text node
        match child.nextSibling() {
          Some(text_node) =>
            if text_node.nodeType() == 3 { // Text node
              // Set up effect to update text
              let _ = @signal.effect(fn() {
                let new_text = getter()
                text_node.setTextContent(new_text)
              })

            }
          None => ()
        }
        break
      }
    }
  }
}

///|
/// Hydrate element attributes and handlers
fn hydrate_element(
  elem : @js_dom.Element,
  attrs : Array[(String, @luna.Attr[@js.Any])],
) -> Unit {
  hydrate_element_with_dispatch(elem, attrs, None)
}

///|
/// Hydrate element attributes with optional action dispatcher
fn hydrate_element_with_dispatch(
  elem : @js_dom.Element,
  attrs : Array[(String, @luna.Attr[@js.Any])],
  dispatcher : ((String) -> Unit)?,
) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      @luna.VStatic(_) =>
        // Static attributes already rendered, nothing to do
        ()
      @luna.VDynamic(getter) => {
        // Set up effect to update attribute
        let _ = @signal.effect(fn() {
          let new_value = getter()
          if new_value == "__remove__" {
            elem.removeAttribute(name)
          } else if name == "class" || name == "className" {
            elem.setClassName(new_value)
          } else if name == "value" {
            elem.as_any()._set("value", @js.any(new_value)) |> ignore
          } else {
            elem.setAttribute(name, new_value)
          }
        })

      }
      @luna.VHandler(handler) => {
        // Attach event handler
        let event_name = extract_event_name(name)
        let callback = handler.get_callback()
        // Pass event to callback
        let wrapper : (@js.Any) -> Unit = fn(event) { callback(event) }
        elem
        .as_event_target()
        .addEventListener(event_name, @js.any(wrapper).cast())
      }
      @luna.VAction(action_name) =>
        // Attach action handler - dispatch action when event fires
        match dispatcher {
          Some(dispatch) => {
            let event_name = extract_event_name(name)
            let captured_action = action_name
            let wrapper : (@js.Any) -> Unit = fn(_event) {
              dispatch(captured_action)
            }
            elem
            .as_event_target()
            .addEventListener(event_name, @js.any(wrapper).cast())
          }
          None =>
            // No dispatcher provided, action won't work
            ()
        }
    }
  }
}

///|
/// Extract event name from handler name (onClick -> click)
fn extract_event_name(name : String) -> String {
  if name.length() >= 2 {
    // Check if starts with "on"
    if name.code_unit_at(0) == "o".code_unit_at(0) &&
      name.code_unit_at(1) == "n".code_unit_at(0) {
      // Convert rest to lowercase
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
}

///|
/// Hydrate conditional show
fn hydrate_show(
  parent : @js_dom.Node,
  id : Int,
  cond : () -> Bool,
  child_fn : () -> @luna.Node[@js.Any],
  ctx : HydrationContext,
) -> Unit {
  let marker_start = "s:" + id.to_string()

  // Find the show marker
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        start_marker = Some(child)
        break
      }
    }
  }
  match start_marker {
    Some(marker) => {
      let current_nodes : Array[@js_dom.Node] = []

      // Collect nodes between markers
      let mut sibling = marker.nextSibling()
      while true {
        match sibling {
          Some(node) => {
            if node.nodeType() == 8 { // Comment
              let text = get_text_content(node)
              if text == "/s" {
                break
              }
            }
            current_nodes.push(node)
            sibling = node.nextSibling()
          }
          None => break
        }
      }

      // If currently showing, hydrate the child
      if cond() && current_nodes.length() > 0 {
        let child_vnode = child_fn()
        // We need to hydrate the existing nodes
        hydrate_child_nodes(current_nodes, child_vnode, ctx)
      }

      // Set up effect for show/hide
      let _ = @signal.effect(fn() {
        let should_show = cond()
        if should_show && current_nodes.is_empty() {
          // Need to show - render and insert
          let child_vnode = child_fn()
          let new_node = render_vnode_to_dom(child_vnode)
          match marker.nextSibling() {
            Some(end_marker) => {
              parent.insertBefore(new_node, Some(end_marker)) |> ignore
              current_nodes.push(new_node)
            }
            None => ()
          }
        } else if not(should_show) && not(current_nodes.is_empty()) {
          // Need to hide - remove nodes
          for node in current_nodes {
            parent.removeChild(node) |> ignore
          }
          current_nodes.clear()
        }
      })

    }
    None => ()
  }
}

///|
/// Hydrate child nodes with VNode
fn hydrate_child_nodes(
  nodes : Array[@js_dom.Node],
  node : @luna.Node[@js.Any],
  ctx : HydrationContext,
) -> Unit {
  // For now, just traverse the VNode and update ctx
  let _ = nodes // suppress unused warning
  match node {
    @luna.Text(_) => ()
    @luna.DynamicText(_) => ctx.current_id = ctx.current_id + 1
    @luna.Fragment(children) =>
      for i = 0; i < children.length(); i = i + 1 {
        hydrate_child_nodes(nodes, children[i], ctx)
      }
    @luna.Element(elem) => {
      ctx.current_id = ctx.current_id + 1
      for i = 0; i < elem.children.length(); i = i + 1 {
        hydrate_child_nodes(nodes, elem.children[i], ctx)
      }
    }
    @luna.Show(condition=condition_fn, child=child_getter) => {
      ctx.current_id = ctx.current_id + 1
      if condition_fn() {
        hydrate_child_nodes(nodes, child_getter(), ctx)
      }
    }
    @luna.For(render=render_fn) => {
      ctx.current_id = ctx.current_id + 1
      let items = render_fn()
      for i = 0; i < items.length(); i = i + 1 {
        hydrate_child_nodes(nodes, items[i], ctx)
      }
    }
    @luna.Component(render=render_fn) =>
      hydrate_child_nodes(nodes, render_fn(), ctx)
    @luna.Island(island) =>
      for child in island.children {
        hydrate_child_nodes(nodes, child, ctx)
      }
    @luna.Async(async_node) => {
      ctx.current_id = ctx.current_id + 1
      hydrate_child_nodes(nodes, (async_node.fallback)(), ctx)
    }
  }
}

///|
/// Hydrate for loop
fn hydrate_for(
  parent : @js_dom.Node,
  id : Int,
  render_fn : () -> Array[@luna.Node[@js.Any]],
  ctx : HydrationContext,
) -> Unit {
  let marker_start = "f:" + id.to_string()

  // Find the for marker
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  let mut end_marker : @js_dom.Node? = None
  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        start_marker = Some(child)
      } else if comment_text == "/f" {
        match start_marker {
          Some(_) => {
            end_marker = Some(child)
            break
          }
          None => ()
        }
      }
    }
  }
  match (start_marker, end_marker) {
    (Some(start), Some(end)) => {
      let current_nodes : Array[@js_dom.Node] = []

      // Collect nodes between markers
      let mut sibling = start.nextSibling()
      while true {
        match sibling {
          Some(node) => {
            if node.nodeType() == 8 {
              let text = get_text_content(node)
              if text == "/f" {
                break
              }
            }
            current_nodes.push(node)
            sibling = node.nextSibling()
          }
          None => break
        }
      }

      // Hydrate existing items
      let items = render_fn()
      for i = 0; i < items.length(); i = i + 1 {
        if i < current_nodes.length() {
          hydrate_child_nodes([current_nodes[i]], items[i], ctx)
        }
      }

      // Set up effect for list updates
      let _ = @signal.effect(fn() {
        let new_items = render_fn()

        // Simple strategy: clear and re-render
        for node in current_nodes {
          parent.removeChild(node) |> ignore
        }
        current_nodes.clear()
        for item in new_items {
          let new_node = render_vnode_to_dom(item)
          parent.insertBefore(new_node, Some(end)) |> ignore
          current_nodes.push(new_node)
        }
      })

    }
    _ => ()
  }
}

///|
/// Render VNode to DOM node (for client-side rendering after hydration)
pub fn render_vnode_to_dom(node : @luna.Node[@js.Any]) -> @js_dom.Node {
  let doc = @js_dom.document()
  match node {
    @luna.Text(content) => doc.createTextNode(content).as_node()
    @luna.DynamicText(getter) => {
      let text_node = doc.createTextNode(getter())
      let node_ref = text_node.as_node()
      let _ = @signal.effect(fn() {
        let new_text = getter()
        node_ref.setTextContent(new_text)
      })
      node_ref
    }
    @luna.Fragment(children) => {
      let fragment = doc.createDocumentFragment()
      for i = 0; i < children.length(); i = i + 1 {
        fragment.as_node().appendChild(render_vnode_to_dom(children[i]))
        |> ignore
      }
      fragment.as_node()
    }
    @luna.Element(elem) => {
      let dom_elem = doc.createElement(elem.tag)

      // Apply attributes
      for i = 0; i < elem.attrs.length(); i = i + 1 {
        let (name, value) = elem.attrs[i]
        apply_vattr(dom_elem, name, value)
      }

      // Append children
      for i = 0; i < elem.children.length(); i = i + 1 {
        dom_elem.as_node().appendChild(render_vnode_to_dom(elem.children[i]))
        |> ignore
      }
      dom_elem.as_node()
    }
    @luna.Show(condition=cond, child=child_fn) => {
      let placeholder = doc.createComment("show")
      let mut current_node : @js_dom.Node? = None
      let _ = @signal.effect(fn() {
        let should_show = cond()
        match (should_show, current_node) {
          (true, None) => {
            let rendered = render_vnode_to_dom(child_fn())
            match placeholder.parentNode() {
              Some(par) => {
                par.insertBefore(rendered, Some(placeholder)) |> ignore
                current_node = Some(rendered)
              }
              None => ()
            }
          }
          (false, Some(n)) =>
            match n.parentNode() {
              Some(par) => {
                par.removeChild(n) |> ignore
                current_node = None
              }
              None => ()
            }
          _ => ()
        }
      })
      placeholder
    }
    @luna.For(render=render_fn) => {
      // Use a comment as a placeholder/marker for where to insert items
      let placeholder = doc.createComment("for")
      let current_nodes : Array[@js_dom.Node] = []
      let is_first_render : Ref[Bool] = { val: true }

      // Create a fragment for initial render
      let fragment = doc.createDocumentFragment()
      let fragment_node = fragment.as_node()

      // Initial render
      let initial_items = render_fn()
      for item in initial_items {
        let rendered = render_vnode_to_dom(item)
        current_nodes.push(rendered)
        fragment_node.appendChild(rendered) |> ignore
      }
      // Append placeholder at end
      fragment_node.appendChild(placeholder) |> ignore

      // Set up effect for updates (skip first run since we already rendered)
      let _ = @signal.effect(fn() {
        let new_items = render_fn()
        if is_first_render.val {
          is_first_render.val = false
          return
        }

        // Remove old nodes
        for node in current_nodes {
          match node.parentNode() {
            Some(par) => par.removeChild(node) |> ignore
            None => ()
          }
        }
        current_nodes.clear()

        // Insert new items before the placeholder
        match placeholder.parentNode() {
          Some(parent) =>
            for item in new_items {
              let rendered = render_vnode_to_dom(item)
              current_nodes.push(rendered)
              parent.insertBefore(rendered, Some(placeholder)) |> ignore
            }
          None => ()
        }
      })
      fragment_node
    }
    @luna.Component(render=render_fn) => render_vnode_to_dom(render_fn())
    @luna.Island(island) => {
      // For client-side rendering, create a wrapper div with island attributes
      // and render children inside
      let wrapper = doc.createElement("div")
      wrapper.setAttribute("ln:id", island.id)
      wrapper.setAttribute("ln:url", island.url)
      wrapper.setAttribute("ln:state", island.state)
      wrapper.setAttribute(
        "ln:trigger",
        @luna.trigger_to_string(island.trigger),
      )
      for child in island.children {
        wrapper.as_node().appendChild(render_vnode_to_dom(child)) |> ignore
      }
      wrapper.as_node()
    }
    @luna.Async(async_node) => {
      // For client-side rendering, render fallback initially
      // Async replacement would be handled separately
      render_vnode_to_dom((async_node.fallback)())
    }
  }
}

///|
/// Apply VAttr to DOM element
fn apply_vattr(
  elem : @js_dom.Element,
  name : String,
  value : @luna.Attr[@js.Any],
) -> Unit {
  match value {
    @luna.VStatic(s) =>
      if s != "__remove__" {
        if name == "class" || name == "className" {
          elem.setClassName(s)
        } else if name == "value" {
          elem.as_any()._set("value", @js.any(s)) |> ignore
        } else if s == "" {
          elem.setAttribute(name, "")
        } else {
          elem.setAttribute(name, s)
        }
      }
    @luna.VDynamic(getter) => {
      let _ = @signal.effect(fn() {
        let new_value = getter()
        if new_value == "__remove__" {
          elem.removeAttribute(name)
        } else if name == "class" || name == "className" {
          elem.setClassName(new_value)
        } else if name == "value" {
          elem.as_any()._set("value", @js.any(new_value)) |> ignore
        } else {
          elem.setAttribute(name, new_value)
        }
      })

    }
    @luna.VHandler(handler) => {
      let event_name = extract_event_name(name)
      let callback = handler.get_callback()
      // Pass event to callback
      let wrapper : (@js.Any) -> Unit = fn(event) { callback(event) }
      elem
      .as_event_target()
      .addEventListener(event_name, @js.any(wrapper).cast())
    }
    @luna.VAction(_) =>
      // VAction without dispatcher does nothing in CSR context
      // Actions are meant to be bound during action-based hydration
      ()
  }
}

///|
/// Convenience function: render VNode to DOM and mount
pub fn render_vnode(
  container : @js_dom.Element,
  node : @luna.Node[@js.Any],
) -> Unit {
  container.as_node().setTextContent("")
  let dom_node = render_vnode_to_dom(node)
  container.as_node().appendChild(dom_node) |> ignore
}

// =============================================================================
// Action-based Hydration
// =============================================================================

///|
/// Bind action handlers by scanning DOM for data-action-* attributes
/// This is used for declarative action binding without VNode traversal
pub fn bind_actions_from_dom(
  container : @js_dom.Element,
  dispatch : (String) -> Unit,
) -> Unit {
  // Find all elements with data-action-* attributes
  let all_elements = query_all_with_action_attrs(container)
  for elem_any in all_elements {
    let elem : @js_dom.Element = elem_any.cast()
    bind_action_handlers(elem, dispatch)
  }
}

///|
extern "js" fn query_all_with_action_attrs(
  container : @js_dom.Element,
) -> Array[@js.Any] =
  #| (container) => {
  #|   const result = [];
  #|   const walk = (node) => {
  #|     if (node.nodeType === 1) {
  #|       const attrs = node.attributes;
  #|       for (let i = 0; i < attrs.length; i++) {
  #|         if (attrs[i].name.startsWith('data-action-')) {
  #|           result.push(node);
  #|           break;
  #|         }
  #|       }
  #|       for (const child of node.childNodes) walk(child);
  #|     }
  #|   };
  #|   walk(container);
  #|   return result;
  #| }

///|
extern "js" fn get_action_attrs(
  elem : @js_dom.Element,
) -> Array[(String, String)] =
  #| (elem) => {
  #|   const result = [];
  #|   const attrs = elem.attributes;
  #|   for (let i = 0; i < attrs.length; i++) {
  #|     const name = attrs[i].name;
  #|     if (name.startsWith('data-action-')) {
  #|       const eventName = name.slice(12); // Remove 'data-action-'
  #|       // MoonBit tuple format: {_0: first, _1: second}
  #|       result.push({_0: eventName, _1: attrs[i].value});
  #|     }
  #|   }
  #|   return result;
  #| }

///|
/// Bind action handlers to a single element based on data-action-* attributes
fn bind_action_handlers(
  elem : @js_dom.Element,
  dispatch : (String) -> Unit,
) -> Unit {
  let action_attrs = get_action_attrs(elem)
  for attr in action_attrs {
    let (event_name, action_name) = attr
    let captured_action = action_name
    let wrapper : (@js.Any) -> Unit = fn(_event) { dispatch(captured_action) }
    elem.as_event_target().addEventListener(event_name, @js.any(wrapper).cast())
  }
}

///|
/// High-level hydration function for action-based components
/// Takes an element, dispatcher function, and render function
/// Binds actions and sets up re-rendering on state changes
pub fn[State] hydrate_with_actions(
  container : @js_dom.Element,
  initial_state : State,
  render : (State) -> @luna.Node[@js.Any],
  update : (State, String) -> State,
) -> Unit {
  let state_signal = @signal.signal(initial_state)

  // Create dispatcher that updates state
  let dispatch : (String) -> Unit = fn(action : String) {
    let current = state_signal.peek()
    let new_state = update(current, action)
    state_signal.set(new_state)
  }

  // Bind actions from existing DOM
  bind_actions_from_dom(container, dispatch)

  // Set up effect to re-render when state changes
  let is_first_render : Ref[Bool] = { val: true }
  let _ = @signal.effect(fn() {
    let current_state = state_signal.get()

    // Skip first render as DOM already contains SSR content
    if is_first_render.val {
      is_first_render.val = false
      return
    }

    // Re-render on state change
    let new_vnode = render(current_state)
    container.as_node().setTextContent("")
    let dom_node = render_vnode_to_dom(new_vnode)
    container.as_node().appendChild(dom_node) |> ignore

    // Re-bind actions after re-render
    bind_actions_from_dom(container, dispatch)
  })

}
