// Client-side Rendering - Create new DOM nodes from VNode
//

///|
/// Render VNode to DOM node (for client-side rendering after hydration)
pub fn render_vnode_to_dom(node : @luna.Node[@js.Any]) -> @js_dom.Node {
  let doc = @js_dom.document()
  match node {
    @luna.Text(content) => doc.createTextNode(content).as_node()
    @luna.RawHtml(html) =>
      // Create a template element and parse the HTML using JS
      parse_html_to_node(html)
    @luna.DynamicText(getter) => {
      let text_node = doc.createTextNode(getter())
      let node_ref = text_node.as_node()
      let _ = @signal.render_effect(fn() {
        let new_text = getter()
        node_ref.setTextContent(new_text)
      })
      node_ref
    }
    @luna.Fragment(children) => {
      let fragment = doc.createDocumentFragment()
      for child in children {
        fragment.as_node().appendChild(render_vnode_to_dom(child)) |> ignore
      }
      fragment.as_node()
    }
    @luna.Element(elem) => {
      let dom_elem = doc.createElement(elem.tag)

      // Apply attributes
      for attr in elem.attrs {
        let (name, value) = attr
        apply_vattr(dom_elem, name, value)
      }

      // Append children
      for child in elem.children {
        dom_elem.as_node().appendChild(render_vnode_to_dom(child)) |> ignore
      }
      dom_elem.as_node()
    }
    @luna.Show(condition=cond, child=child_fn) => {
      let placeholder = doc.createComment("show")
      let mut current_node : @js_dom.Node? = None
      let _ = @signal.render_effect(fn() {
        let should_show = cond()
        match (should_show, current_node) {
          (true, None) =>
            if placeholder.parentNode() is Some(par) {
              // Use untracked to prevent child signals from being registered
              // as dependencies of this Show's effect. This prevents infinite
              // loops when nested Show components access signals.
              let rendered = @signal.untracked(fn() {
                render_vnode_to_dom(child_fn())
              })
              par.insertBefore(rendered, Some(placeholder)) |> ignore
              current_node = Some(rendered)
            }
          (false, Some(n)) =>
            if n.parentNode() is Some(par) {
              par.removeChild(n) |> ignore
              current_node = None
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
      let is_first_render : Ref[Bool] = Ref::new(true)

      // Create a fragment for initial render
      let fragment = doc.createDocumentFragment()
      let fragment_node = fragment.as_node()

      // Initial render - use untracked to prevent dependency tracking
      let initial_items = @signal.untracked(fn() { render_fn() })
      for item in initial_items {
        let rendered = @signal.untracked(fn() { render_vnode_to_dom(item) })
        current_nodes.push(rendered)
        fragment_node.appendChild(rendered) |> ignore
      }
      // Append placeholder at end
      fragment_node.appendChild(placeholder) |> ignore

      // Set up effect for updates (skip first run since we already rendered)
      let _ = @signal.render_effect(fn() {
        let new_items = render_fn()
        if is_first_render.val {
          is_first_render.val = false
          return
        }

        // Remove old nodes
        for node in current_nodes {
          if node.parentNode() is Some(par) {
            par.removeChild(node) |> ignore
          }
        }
        current_nodes.clear()

        // Insert new items before the placeholder
        // Use untracked to prevent child signals from being registered
        // as dependencies of this For's effect
        if placeholder.parentNode() is Some(parent) {
          for item in new_items {
            let rendered = @signal.untracked(fn() { render_vnode_to_dom(item) })
            current_nodes.push(rendered)
            parent.insertBefore(rendered, Some(placeholder)) |> ignore
          }
        }
      })
      fragment_node
    }
    @luna.Component(render=render_fn) => render_vnode_to_dom(render_fn())
    @luna.Island(island) => {
      // For client-side rendering, create a wrapper div with island attributes
      // and render children inside
      let wrapper = doc.createElement("div")
      wrapper.setAttribute("luna:id", island.id)
      wrapper.setAttribute("luna:url", island.url)
      wrapper.setAttribute("luna:state", island.state)
      wrapper.setAttribute("luna:client-trigger", island.trigger.to_string())
      for child in island.children {
        wrapper.as_node().appendChild(render_vnode_to_dom(child)) |> ignore
      }
      wrapper.as_node()
    }
    @luna.WcIsland(wc_island) => {
      // For client-side rendering, create the custom element with shadow DOM
      let wrapper = doc.createElement(wc_island.name)
      wrapper.setAttribute("data-state", wc_island.state)
      wrapper.setAttribute("data-trigger", wc_island.trigger.to_string())
      // Note: Shadow DOM would be created by the custom element itself
      // For CSR, we just create the host element with data attributes
      for child in wc_island.children {
        wrapper.as_node().appendChild(render_vnode_to_dom(child)) |> ignore
      }
      wrapper.as_node()
    }
    @luna.InternalRef(iref) =>
      // For client-side rendering, create appropriate element based on wc flag
      if iref.wc {
        // Web Components island - extract name from URL
        let name = extract_wc_name_from_url(iref.url)
        let wrapper = doc.createElement(name)
        wrapper.setAttribute("luna:wc-url", iref.url)
        wrapper.setAttribute("luna:wc-state", iref.state)
        wrapper.setAttribute("luna:wc-trigger", iref.trigger.to_string())
        for child in iref.children {
          wrapper.as_node().appendChild(render_vnode_to_dom(child)) |> ignore
        }
        wrapper.as_node()
      } else {
        // Regular island
        let wrapper = doc.createElement("div")
        let id = iref.url.replace(old="/", new="_").replace(old=".", new="_")
        wrapper.setAttribute("luna:id", id)
        wrapper.setAttribute("luna:url", iref.url)
        wrapper.setAttribute("luna:state", iref.state)
        wrapper.setAttribute("luna:client-trigger", iref.trigger.to_string())
        for child in iref.children {
          wrapper.as_node().appendChild(render_vnode_to_dom(child)) |> ignore
        }
        wrapper.as_node()
      }
    @luna.Async(async_node) =>
      // For client-side rendering, render fallback initially
      // Async replacement would be handled separately
      render_vnode_to_dom((async_node.fallback)())
    @luna.ErrorBoundary(boundary) =>
      // Client-side ErrorBoundary with reset support
      render_error_boundary_to_dom(boundary)
    @luna.Switch(switch_node) =>
      // Client-side Switch rendering
      render_switch_to_dom(switch_node)
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
      let _ = @signal.render_effect(fn() {
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

///|
/// Render ErrorBoundary to DOM with error catching and reset support
fn render_error_boundary_to_dom(
  boundary : @luna.VErrorBoundary[@js.Any],
) -> @js_dom.Node {
  let doc = @js_dom.document()
  let container = doc.createDocumentFragment()
  let container_node = container.as_node()

  // State for error handling
  let error_state : Ref[Error?] = Ref::new(None)
  let content_nodes : Array[@js_dom.Node] = []

  // Reset function clears error and re-renders children
  let reset = fn() {
    error_state.val = None
    // Clear current content
    for node in content_nodes {
      if node.parentNode() is Some(par) {
        par.removeChild(node) |> ignore
      }
    }
    content_nodes.clear()
    // Re-render children
    try {
      let child_node = render_vnode_to_dom((boundary.children)())
      content_nodes.push(child_node)
      // Need to re-append to parent - this is complex in fragment context
      // For now, this is a best-effort implementation
    } catch {
      err => error_state.val = Some(err)
    }
  }

  // Initial render
  try {
    let child_node = render_vnode_to_dom((boundary.children)())
    content_nodes.push(child_node)
    container_node.appendChild(child_node) |> ignore
  } catch {
    err => {
      error_state.val = Some(err)
      try {
        let fallback_node = render_vnode_to_dom((boundary.fallback)(err, reset))
        content_nodes.push(fallback_node)
        container_node.appendChild(fallback_node) |> ignore
      } catch {
        _ => () // Ignore errors in fallback
      }
    }
  }
  container_node
}

///|
/// Render Switch to DOM with reactive updates
fn render_switch_to_dom(switch_node : @luna.VSwitch[@js.Any]) -> @js_dom.Node {
  let doc = @js_dom.document()
  let placeholder = doc.createComment("switch")
  let mut current_node : @js_dom.Node? = None
  let mut current_case_index : Int = -1 // -1 means fallback, -2 means no match

  // Helper to find which case matches
  let find_matching_case = fn() -> Int {
    for i, case_ in switch_node.cases {
      if (case_.when)() {
        return i
      }
    }
    // No case matched
    if switch_node.fallback is Some(_) {
      return -1 // fallback
    }
    -2 // no match, no fallback
  }

  // Initial render
  let initial_case = find_matching_case()
  current_case_index = initial_case
  let fragment = doc.createDocumentFragment()
  let fragment_node = fragment.as_node()
  if initial_case >= 0 {
    let node = render_vnode_to_dom((switch_node.cases[initial_case].render)())
    current_node = Some(node)
    fragment_node.appendChild(node) |> ignore
  } else if initial_case == -1 {
    match switch_node.fallback {
      Some(fallback_fn) => {
        let node = render_vnode_to_dom(fallback_fn())
        current_node = Some(node)
        fragment_node.appendChild(node) |> ignore
      }
      None => ()
    }
  }
  fragment_node.appendChild(placeholder) |> ignore

  // Set up effect for reactive updates
  let is_first_render : Ref[Bool] = Ref::new(true)
  let _ = @signal.render_effect(fn() {
    let new_case = find_matching_case()

    // Skip first render
    if is_first_render.val {
      is_first_render.val = false
      return
    }

    // If case hasn't changed, do nothing
    if new_case == current_case_index {
      return
    }

    // Remove current node
    match current_node {
      Some(node) =>
        if node.parentNode() is Some(par) {
          par.removeChild(node) |> ignore
        }
      None => ()
    }
    current_node = None

    // Render new content
    // Use untracked to prevent child signals from being registered
    // as dependencies of this Switch's effect
    if new_case >= 0 {
      let node = @signal.untracked(fn() {
        render_vnode_to_dom((switch_node.cases[new_case].render)())
      })
      current_node = Some(node)
      if placeholder.parentNode() is Some(par) {
        par.insertBefore(node, Some(placeholder)) |> ignore
      }
    } else if new_case == -1 {
      match switch_node.fallback {
        Some(fallback_fn) => {
          let node = @signal.untracked(fn() {
            render_vnode_to_dom(fallback_fn())
          })
          current_node = Some(node)
          if placeholder.parentNode() is Some(par) {
            par.insertBefore(node, Some(placeholder)) |> ignore
          }
        }
        None => ()
      }
    }
    current_case_index = new_case
  })
  fragment_node
}

///|
/// Parse HTML string to DOM Node using template element
/// Used for RawHtml VNode - when you need a detached DOM node from HTML
extern "js" fn parse_html_to_node(html : String) -> @js_dom.Node =
  #| (html) => {
  #|   const template = document.createElement('template');
  #|   template.innerHTML = html;
  #|   return template.content.cloneNode(true);
  #| }

///|
/// Set innerHTML directly on an element (fast for bulk insertion)
extern "js" fn set_inner_html(el : @js_dom.Element, html : String) -> Unit =
  #| (el, html) => { el.innerHTML = html; }

// =============================================================================
// Static Content - innerHTML-based fast rendering for static content
// =============================================================================
//
// Static content uses innerHTML for maximum performance:
// - Browser's native HTML parser is highly optimized
// - 2-3x faster than createElement for 100+ elements
// - No hydration or reconciliation needed
//
// SSR Integration:
// - Server renders static HTML (no special markers)
// - Client receives pre-rendered content - nothing to do
// - For CSR, use inject_static() or static_block()
//

///|
/// Inject static content directly into a container using innerHTML
///
/// This is the fastest way to render static content:
/// - Uses innerHTML for one-time bulk insertion (2-3x faster than createElement)
/// - Container becomes the static content holder
/// - Content is never updated after initial render
///
/// Works seamlessly with SSR:
/// - Server: @render.render_to_string(node) → HTML in response
/// - Client: inject_static(container, node) for CSR parts
///
/// Example:
/// ```moonbit
/// let container = doc.getElementById("static-header")
/// inject_static(container, header_vnode())
/// ```
pub fn inject_static(
  container : @js_dom.Element,
  node : @luna.Node[Unit],
) -> Unit {
  let html = @render.render_to_string(node).html
  set_inner_html(container, html)
}

///|
/// Inject pre-rendered HTML directly into a container
///
/// Use when HTML is already available (e.g., from SSR cache or fetch).
/// This is the fastest path - no VNode rendering needed.
///
/// Security: Ensure HTML is trusted/sanitized before injection.
pub fn inject_static_html(container : @js_dom.Element, html : String) -> Unit {
  set_inner_html(container, html)
}

///|
/// Create a static block that can be composed with dynamic content
///
/// Returns a wrapper element with static content injected via innerHTML.
/// Use when you need to compose static content within a dynamic component.
///
/// Example:
/// ```moonbit
/// fn my_page() -> DomNode {
///   let header = static_block("header", header_vnode())
///   let footer = static_block("footer", footer_vnode())
///   div([
///       header, // Static - never updates
///       dynamic_content(), // Dynamic - updates on signal change
///       footer,
///     ], // Static - never updates
///   )
/// }
/// ```
///
/// Note: Creates a wrapper element. Use inject_static() if you want
/// to avoid the wrapper and have a dedicated container.
pub fn static_block(tag : String, node : @luna.Node[Unit]) -> @element.DomNode {
  let doc = @js_dom.document()
  let wrapper = doc.createElement(tag)
  let html = @render.render_to_string(node).html
  set_inner_html(wrapper, html)
  @element.static_node(wrapper.as_node())
}

///|
/// Create a static div block (convenience wrapper for static_block)
pub fn static_div(node : @luna.Node[Unit]) -> @element.DomNode {
  static_block("div", node)
}

///|
/// Create a static span block (convenience wrapper for static_block)
pub fn static_span(node : @luna.Node[Unit]) -> @element.DomNode {
  static_block("span", node)
}
