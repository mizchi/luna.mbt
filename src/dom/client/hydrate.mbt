// Hydration - Connect VNode to existing server-rendered DOM
//

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
  self is Success
}

///|
pub fn HydrationResult::is_mismatch(self : HydrationResult) -> Bool {
  self is Mismatch(_)
}

///|
pub fn HydrationResult::is_recovered(self : HydrationResult) -> Bool {
  self is Recovered(_)
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
  mut hk_cache : @hashmap.HashMap[Int, @js_dom.Element]?
}

///|
/// Log a hydration warning to logger or console
fn warn_hydration(logger : StringBuilder?, msg : String) -> Unit {
  let full_msg = "[Hydration] " + msg
  if logger is Some(sb) {
    sb.write_string(full_msg)
    sb.write_string("\n")
  } else {
    let global = @global.global_this()
    let console = global["console"]
    console._call("warn", [@js.any(full_msg)]) |> ignore
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
  node : @luna.Node[@js.Any, String],
  recover_on_mismatch? : Bool,
  warn_on_mismatch? : Bool,
  logger? : StringBuilder,
) -> HydrationResult {
  let recover = recover_on_mismatch.unwrap_or(true)
  let warn = warn_on_mismatch.unwrap_or(true)
  let ctx : HydrationContext = {
    container,
    current_id: 0,
    mismatches: [],
    hk_cache: None,
  }
  let root_cursor : Ref[@js_dom.Node?] = Ref::new(None)
  hydrate_node(container.as_node(), node, ctx, root_cursor, None) catch {
    err =>
      // If hydration throws, treat as mismatch and recover
      ctx.mismatches.push("Hydration error: " + err.to_string())
  }

  // Check for mismatches
  if not(ctx.mismatches.is_empty()) {
    let mismatch_msg = ctx.mismatches.iter().join("; ")
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
  node : @luna.Node[@js.Any, String],
  ctx : HydrationContext,
  cursor : Ref[@js_dom.Node?],
  stop : @js_dom.Node?,
) -> Unit raise {
  match node {
    @core.Text(_) =>
      // Static text doesn't need hydration
      ()
    @core.RawHtml(_) =>
      // Raw HTML doesn't need hydration
      ()
    @core.DynamicText(getter) => {
      // Find the text marker comments and set up effect
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_dynamic_text(parent, id, getter)
    }
    @core.Fragment(children) =>
      for child in children {
        hydrate_node(parent, child, ctx, cursor, stop)
      }
    @core.Element(elem) => {
      // Check if this element needs hydration (has handlers or dynamic attrs)
      let needs_hydration = @luna.has_dynamic_content(elem.attrs)

      // Always increment id to match SSR counter
      let id = ctx.current_id
      ctx.current_id = id + 1

      // Find the DOM element
      let dom_elem_opt : @js_dom.Element? = if needs_hydration {
        // For elements with dynamic content, find by sol:hk attribute
        match find_element_by_hk(ctx, id) {
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
              "> with sol:hk=\"" +
              id.to_string() +
              "\"",
            )
            None
          }
        }
      } else {
        // For static elements, find by traversing from parent
        find_child_element_by_tag(parent, elem.tag, cursor, stop)
      }

      // Hydrate children
      if dom_elem_opt is Some(dom_elem) {
        match dom_elem.as_node().parentNode() {
          Some(par) =>
            if node_ref_equal(par, parent) {
              cursor.val = Some(dom_elem.as_node())
            }
          None => ()
        }
        let child_cursor : Ref[@js_dom.Node?] = Ref::new(None)
        for child in elem.children {
          hydrate_node(dom_elem.as_node(), child, ctx, child_cursor, None)
        }
      }
    }
    @core.Show(condition=cond, child=child_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_show(parent, id, cond, child_fn, ctx, cursor, stop)
    }
    @core.For(render=render_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_for(parent, id, render_fn, ctx, cursor, stop)
    }
    @core.Component(render=render_fn) =>
      hydrate_node(parent, render_fn(), ctx, cursor, stop)
    @core.Island(island) =>
      // Island hydration is handled by the loader, not this function
      // Just hydrate children normally for nested content
      for child in island.children {
        hydrate_node(parent, child, ctx, cursor, stop)
      }
    @core.WcIsland(wc_island) =>
      // WcIsland hydration is handled by wcssr client runtime
      // Just hydrate children normally for nested content
      for child in wc_island.children {
        hydrate_node(parent, child, ctx, cursor, stop)
      }
    @core.InternalRef(iref) =>
      // InternalRef hydration is handled by the loader (same as Island/WcIsland)
      // Just hydrate children normally for nested content
      for child in iref.children {
        hydrate_node(parent, child, ctx, cursor, stop)
      }
    @core.Async(async_node) => {
      // Async node hydration: hydrate the fallback content
      // Full async replacement would happen via streaming SSR
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_node(parent, (async_node.fallback)(), ctx, cursor, stop)
    }
    @core.ErrorBoundary(boundary) => {
      // ErrorBoundary hydration with error catching
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_error_boundary(parent, id, boundary, ctx, cursor, stop)
    }
    @core.Switch(switch_node) => {
      // Switch hydration: evaluate conditions and hydrate matching case
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_switch(parent, id, switch_node, ctx, cursor, stop)
    }
  }
}

///|
/// Node reference equality helper
extern "js" fn node_ref_equal(a : @js_dom.Node, b : @js_dom.Node) -> Bool =
  #| (a, b) => a === b

///|
/// Build hk_cache by scanning all elements with sol:hk attribute once
fn build_hk_cache(
  container : @js_dom.Element,
) -> @hashmap.HashMap[Int, @js_dom.Element] {
  let cache : @hashmap.HashMap[Int, @js_dom.Element] = @hashmap.new()
  build_hk_cache_recursive(container.as_node(), cache)
  cache
}

///|
/// Recursively collect elements with sol:hk attribute into cache
fn build_hk_cache_recursive(
  node : @js_dom.Node,
  cache : @hashmap.HashMap[Int, @js_dom.Element],
) -> Unit {
  if node.nodeType() == 1 {
    let elem : @js_dom.Element = node.as_any().cast()
    match elem.getAttribute("sol:hk") {
      Some(id_str) => {
        let mut id = 0
        let mut valid = true
        for c in id_str {
          if c >= '0' && c <= '9' {
            id = id * 10 + (c.to_int() - '0'.to_int())
          } else {
            valid = false
            break
          }
        }
        if valid && not(id_str.is_empty()) {
          cache.set(id, elem)
        }
      }
      None => ()
    }
  }
  let children = node.childNodes()
  for child in children {
    build_hk_cache_recursive(child, cache)
  }
}

///|
/// Find element with sol:hk="id" attribute using cache (O(1))
fn find_element_by_hk(ctx : HydrationContext, id : Int) -> @js_dom.Element? {
  let cache = match ctx.hk_cache {
    Some(cache) => cache
    None => {
      let built = build_hk_cache(ctx.container)
      ctx.hk_cache = Some(built)
      built
    }
  }
  cache.get(id)
}

///|
/// Find first child element with matching tag name, advancing cursor
fn find_child_element_by_tag(
  parent : @js_dom.Node,
  tag : String,
  cursor : Ref[@js_dom.Node?],
  stop : @js_dom.Node?,
) -> @js_dom.Element? {
  let upper_tag = tag.to_upper()
  let mut current = match cursor.val {
    Some(node) => node.nextSibling()
    None => parent.firstChild()
  }
  while current is Some(node) {
    match stop {
      Some(stop_node) => if node_ref_equal(node, stop_node) { return None }
      None => ()
    }
    if node.nodeType() == 1 {
      let elem : @js_dom.Element = node.as_any().cast()
      if elem.tagName() == upper_tag {
        cursor.val = Some(node)
        return Some(elem)
      }
    }
    current = node.nextSibling()
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
  for child in children {
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        // Found start marker, next sibling should be the text node
        if child.nextSibling() is Some(text_node) && text_node.nodeType() == 3 {
          // Set up effect to update text
          let _ = @resource.render_effect(fn() {
            let new_text = getter()
            text_node.setTextContent(new_text)
          })

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
  attrs : Array[(String, @luna.Attr[@js.Any, String])],
) -> Unit {
  hydrate_element_with_dispatch(elem, attrs, None)
}

///|
/// Hydrate element attributes with optional action dispatcher
fn hydrate_element_with_dispatch(
  elem : @js_dom.Element,
  attrs : Array[(String, @luna.Attr[@js.Any, String])],
  dispatcher : ((String) -> Unit)?,
) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      @core.VStatic(_) =>
        // Static attributes already rendered, nothing to do
        ()
      @core.VDynamic(getter) => {
        // Set up effect to update attribute
        let _ = @resource.render_effect(fn() {
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
      @core.VHandler(handler) => {
        // Attach event handler
        let event_name = extract_event_name(name)
        let callback = handler.get_callback()
        // Pass event to callback
        let wrapper : (@js.Any) -> Unit = fn(event) { callback(event) }
        elem
        .as_event_target()
        .addEventListener(event_name, @js.any(wrapper).cast())
      }
      @core.VAction(action_name) =>
        // Attach action handler - dispatch action when event fires
        if dispatcher is Some(dispatch) {
          let event_name = extract_event_name(name)
          let captured_action = action_name
          let wrapper : (@js.Any) -> Unit = fn(_event) {
            dispatch(captured_action)
          }
          elem
          .as_event_target()
          .addEventListener(event_name, @js.any(wrapper).cast())
        }
      // No dispatcher provided, action won't work
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
  child_fn : () -> @luna.Node[@js.Any, String],
  ctx : HydrationContext,
  cursor : Ref[@js_dom.Node?],
  stop : @js_dom.Node?,
) -> Unit {
  let marker_start = "s:" + id.to_string()

  // Find the show marker
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  let mut end_marker : @js_dom.Node? = None
  for child in children {
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        start_marker = Some(child)
        break
      }
    }
  }
  guard start_marker is Some(marker) else { return }
  let current_nodes : Array[@js_dom.Node] = []

  // Collect nodes between markers
  let mut sibling = marker.nextSibling()
  while true {
    match sibling {
      Some(node) => {
        if node.nodeType() == 8 { // Comment
          let text = get_text_content(node)
          if text == "/s" {
            end_marker = Some(node)
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
  if cond() && not(current_nodes.is_empty()) && end_marker is Some(end_node) {
    let child_vnode = child_fn()
    // We need to hydrate the existing nodes
    let region_cursor : Ref[@js_dom.Node?] = Ref::new(Some(marker))
    hydrate_child_nodes(parent, region_cursor, Some(end_node), child_vnode, ctx) catch {
      _ => () // Ignore errors during hydration of show content
    }
  }

  // Set up effect for show/hide
  let _ = @resource.render_effect(fn() {
    let should_show = cond()
    if should_show && current_nodes.is_empty() {
      // Need to show - render and insert
      let child_vnode = child_fn()
      let new_node = render_vnode_to_dom(child_vnode)
      if end_marker is Some(end_node) {
        let nodes_to_track = collect_dom_nodes(new_node)
        parent.insertBefore(new_node, Some(end_node)) |> ignore
        for node in nodes_to_track {
          current_nodes.push(node)
        }
      }
    } else if not(should_show) && not(current_nodes.is_empty()) {
      // Need to hide - remove nodes
      for node in current_nodes {
        parent.removeChild(node) |> ignore
      }
      current_nodes.clear()
    }
  })

  // Advance cursor to end marker for sibling matching
  if end_marker is Some(end_node) {
    cursor.val = Some(end_node)
  } else {
    match stop {
      Some(_) => ()
      None => ()
    }
  }
}

///|
/// Hydrate child nodes with VNode inside a bounded region
fn hydrate_child_nodes(
  parent : @js_dom.Node,
  cursor : Ref[@js_dom.Node?],
  stop : @js_dom.Node?,
  node : @luna.Node[@js.Any, String],
  ctx : HydrationContext,
) -> Unit raise {
  hydrate_node(parent, node, ctx, cursor, stop)
}

///|
/// Hydrate for loop
fn hydrate_for(
  parent : @js_dom.Node,
  id : Int,
  render_fn : () -> Array[@luna.Node[@js.Any, String]],
  ctx : HydrationContext,
  cursor : Ref[@js_dom.Node?],
  stop : @js_dom.Node?,
) -> Unit {
  let _ = stop // reserved for bounded search
  let marker_start = "f:" + id.to_string()

  // Find the for marker
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  let mut end_marker : @js_dom.Node? = None
  for child in children {
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        start_marker = Some(child)
      } else if comment_text == "/f" && start_marker is Some(_) {
        end_marker = Some(child)
        break
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
      let region_cursor : Ref[@js_dom.Node?] = Ref::new(Some(start))
      for item in items {
        hydrate_child_nodes(parent, region_cursor, Some(end), item, ctx) catch {
          _ => () // Ignore errors during hydration of for items
        }
      }

      // Set up effect for list updates
      let _ = @resource.render_effect(fn() {
        let new_items = render_fn()

        // Simple strategy: clear and re-render
        for node in current_nodes {
          parent.removeChild(node) |> ignore
        }
        current_nodes.clear()
        for item in new_items {
          let new_node = render_vnode_to_dom(item)
          let nodes_to_track = collect_dom_nodes(new_node)
          parent.insertBefore(new_node, Some(end)) |> ignore
          for node in nodes_to_track {
            current_nodes.push(node)
          }
        }
      })

      // Advance cursor to end marker for sibling matching
      cursor.val = Some(end)
    }
    _ => ()
  }
}

///|
/// Hydrate error boundary node
fn hydrate_error_boundary(
  parent : @js_dom.Node,
  id : Int,
  boundary : @luna.VErrorBoundary[@js.Any, String],
  ctx : HydrationContext,
  cursor : Ref[@js_dom.Node?],
  stop : @js_dom.Node?,
) -> Unit {
  let _ = stop // reserved for bounded search
  // Find the error boundary markers
  let marker_start = "eb:" + id.to_string()
  let children = parent.childNodes()
  let mut found = false
  for child in children {
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        found = true
        break
      }
    }
  }
  if found {
    // Try to hydrate children, catch errors
    hydrate_node(parent, (boundary.children)(), ctx, cursor, stop) catch {
      err => {
        // On error during hydration, we need to re-render with fallback
        // Find and clear the boundary content, then render fallback
        let reset = fn() {
          // Reset re-renders children - clear and re-render
          // This is a simplified reset - full implementation would track DOM nodes
          ()
        }
        hydrate_node(parent, (boundary.fallback)(err, reset), ctx, cursor, stop) catch {
          _ => () // Ignore errors in fallback rendering
        }
      }
    }
  }
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
  render : (State) -> @luna.Node[@js.Any, String],
  update : (State, String) -> State,
) -> Unit {
  let state_signal = @resource.signal(initial_state)

  // Create dispatcher that updates state
  let dispatch : (String) -> Unit = fn(action : String) {
    let current = state_signal.peek()
    let new_state = update(current, action)
    state_signal.set(new_state)
  }

  // Bind actions from existing DOM
  bind_actions_from_dom(container, dispatch)

  // Set up effect to re-render when state changes
  let is_first_render : Ref[Bool] = Ref::new(true)
  let _ = @resource.render_effect(fn() {
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

// =============================================================================
// Switch Hydration and Rendering
// =============================================================================

///|
/// Hydrate switch node
fn hydrate_switch(
  parent : @js_dom.Node,
  id : Int,
  switch_node : @luna.VSwitch[@js.Any, String],
  ctx : HydrationContext,
  cursor : Ref[@js_dom.Node?],
  stop : @js_dom.Node?,
) -> Unit raise {
  let _ = stop // reserved for bounded search
  // Find the switch markers
  let marker_start = "sw:" + id.to_string()
  let children = parent.childNodes()
  let mut found = false
  for child in children {
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        found = true
        break
      }
    }
  }
  if found {
    // Find first matching case and hydrate it
    for case_ in switch_node.cases {
      if (case_.when)() {
        hydrate_node(parent, (case_.render)(), ctx, cursor, stop)
        return
      }
    }
    // No case matched, hydrate fallback if present
    match switch_node.fallback {
      Some(fallback_fn) =>
        hydrate_node(parent, fallback_fn(), ctx, cursor, stop)
      None => ()
    }
  }
}
