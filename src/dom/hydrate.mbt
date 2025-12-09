///| Hydration - Connect VNode to existing server-rendered DOM

///|
/// Hydration result type
pub enum HydrationResult {
  Success
  Mismatch(String)
  Recovered(String)
}

///|
/// Hydration options for controlling behavior
pub struct HydrationOptions {
  /// If true, re-render on mismatch instead of failing
  recover_on_mismatch : Bool
  /// If true, log warnings
  warn_on_mismatch : Bool
  /// Optional logger for capturing warnings (if None, uses console)
  logger : StringBuilder?
}

///|
/// Default hydration options
pub fn HydrationOptions::default() -> HydrationOptions {
  { recover_on_mismatch: true, warn_on_mismatch: true, logger: None }
}

///|
/// Strict hydration options - fail on any mismatch
pub fn HydrationOptions::strict() -> HydrationOptions {
  { recover_on_mismatch: false, warn_on_mismatch: true, logger: None }
}

///|
/// Create options with a custom logger
pub fn HydrationOptions::with_logger(
  logger : StringBuilder,
) -> HydrationOptions {
  { recover_on_mismatch: true, warn_on_mismatch: true, logger: Some(logger) }
}

///|
/// Create strict options with a custom logger
pub fn HydrationOptions::strict_with_logger(
  logger : StringBuilder,
) -> HydrationOptions {
  { recover_on_mismatch: false, warn_on_mismatch: true, logger: Some(logger) }
}

///|
/// Hydration context to track current position in DOM
priv struct HydrationContext {
  mut current_id : Int
  mismatches : Array[String]
  options : HydrationOptions
  logger : StringBuilder?
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
      console._call("warn", [@core.any(full_msg)]) |> ignore
    }
  }
}

///|
/// Helper to get text content with default
fn get_text_content(node : @js_dom.Node) -> String {
  let data : @core.Any = node.as_any()._get("data")
  data.cast()
}

///| Hydrate a VNode into an existing DOM container

///|
/// The container should already have server-rendered HTML with hydration markers
pub fn hydrate(container : @js_dom.Element, node : @ui.VNode) -> Unit {
  let _ = hydrate_with_options(container, node, HydrationOptions::default())

}

///|
/// Hydrate with custom options, returning result
pub fn hydrate_with_options(
  container : @js_dom.Element,
  node : @ui.VNode,
  options : HydrationOptions,
) -> HydrationResult {
  let logger = options.logger
  let ctx : HydrationContext = {
    current_id: 0,
    mismatches: [],
    options,
    logger,
  }
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
    if options.warn_on_mismatch {
      warn_hydration(logger, "Hydration mismatch detected: " + mismatch_msg)
    }
    if options.recover_on_mismatch {
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
  node : @ui.VNode,
  ctx : HydrationContext,
) -> Unit {
  match node {
    @ui.VText(_) =>
      // Static text doesn't need hydration
      ()
    @ui.VDynamicText(getter) => {
      // Find the text marker comments and set up effect
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_dynamic_text(parent, id, getter)
    }
    @ui.VFragment(children) =>
      for i = 0; i < children.length(); i = i + 1 {
        hydrate_node(parent, children[i], ctx)
      }
    @ui.VElement(elem) => {
      // Check if this element needs hydration (has handlers or dynamic attrs)
      let needs_hydration = @ui.has_dynamic_content(elem.attrs)

      // Find the DOM element
      let dom_elem_opt : @js_dom.Element? = if needs_hydration {
        // For elements with dynamic content, find by data-hk attribute
        let id = ctx.current_id
        ctx.current_id = id + 1
        match find_element_by_hk(id) {
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
    @ui.VShow(condition=cond, child=child_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_show(parent, id, cond, child_fn, ctx)
    }
    @ui.VFor(render=render_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_for(parent, id, render_fn, ctx)
    }
    @ui.VComponent(render=render_fn) => hydrate_node(parent, render_fn(), ctx)
  }
}

///|
/// Find element with data-hk="id" attribute
fn find_element_by_hk(id : Int) -> @js_dom.Element? {
  let doc = @js_dom.document()
  let selector = "[data-hk=\"" + id.to_string() + "\"]"
  doc.querySelector(selector)
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
              let _ = @ui.effect(fn() {
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
  attrs : Array[(String, @ui.VAttr)],
) -> Unit {
  for i = 0; i < attrs.length(); i = i + 1 {
    let (name, value) = attrs[i]
    match value {
      @ui.VStatic(_) =>
        // Static attributes already rendered, nothing to do
        ()
      @ui.VDynamic(getter) => {
        // Set up effect to update attribute
        let _ = @ui.effect(fn() {
          let new_value = getter()
          if new_value == "__remove__" {
            elem.removeAttribute(name)
          } else if name == "class" || name == "className" {
            elem.setClassName(new_value)
          } else if name == "value" {
            elem.as_any()._set("value", @core.any(new_value)) |> ignore
          } else {
            elem.setAttribute(name, new_value)
          }
        })

      }
      @ui.VHandler(handler) => {
        // Attach event handler
        let event_name = extract_event_name(name)
        let handler_any : @core.Any = @core.any(handler)
        elem.as_event_target().addEventListener(event_name, handler_any.cast())
      }
      @ui.VStyle(_) =>
        // Static style already rendered
        ()
      @ui.VDynamicStyle(getter) => {
        // Set up effect to update style
        let _ = @ui.effect(fn() {
          let styles = getter()
          let style_prop : @core.Any = elem.as_any()._get("style")
          for j = 0; j < styles.length(); j = j + 1 {
            let (prop, val) = styles[j]
            style_prop._set(prop, @core.any(val)) |> ignore
          }
        })

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
  child_fn : () -> @ui.VNode,
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
      let _ = @ui.effect(fn() {
        let should_show = cond()
        if should_show && current_nodes.length() == 0 {
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
        } else if not(should_show) && current_nodes.length() > 0 {
          // Need to hide - remove nodes
          for j = 0; j < current_nodes.length(); j = j + 1 {
            parent.removeChild(current_nodes[j]) |> ignore
          }
          while current_nodes.length() > 0 {
            let _ = current_nodes.pop()

          }
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
  node : @ui.VNode,
  ctx : HydrationContext,
) -> Unit {
  // For now, just traverse the VNode and update ctx
  let _ = nodes // suppress unused warning
  match node {
    @ui.VText(_) => ()
    @ui.VDynamicText(_) => ctx.current_id = ctx.current_id + 1
    @ui.VFragment(children) =>
      for i = 0; i < children.length(); i = i + 1 {
        hydrate_child_nodes(nodes, children[i], ctx)
      }
    @ui.VElement(elem) => {
      ctx.current_id = ctx.current_id + 1
      for i = 0; i < elem.children.length(); i = i + 1 {
        hydrate_child_nodes(nodes, elem.children[i], ctx)
      }
    }
    @ui.VShow(condition=condition_fn, child=child_getter) => {
      ctx.current_id = ctx.current_id + 1
      if condition_fn() {
        hydrate_child_nodes(nodes, child_getter(), ctx)
      }
    }
    @ui.VFor(render=render_fn) => {
      ctx.current_id = ctx.current_id + 1
      let items = render_fn()
      for i = 0; i < items.length(); i = i + 1 {
        hydrate_child_nodes(nodes, items[i], ctx)
      }
    }
    @ui.VComponent(render=render_fn) =>
      hydrate_child_nodes(nodes, render_fn(), ctx)
  }
}

///|
/// Hydrate for loop
fn hydrate_for(
  parent : @js_dom.Node,
  id : Int,
  render_fn : () -> Array[@ui.VNode],
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
      let _ = @ui.effect(fn() {
        let new_items = render_fn()

        // Simple strategy: clear and re-render
        for j = 0; j < current_nodes.length(); j = j + 1 {
          parent.removeChild(current_nodes[j]) |> ignore
        }
        while current_nodes.length() > 0 {
          let _ = current_nodes.pop()

        }
        for j = 0; j < new_items.length(); j = j + 1 {
          let new_node = render_vnode_to_dom(new_items[j])
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
pub fn render_vnode_to_dom(node : @ui.VNode) -> @js_dom.Node {
  let doc = @js_dom.document()
  match node {
    @ui.VText(content) => doc.createTextNode(content).as_node()
    @ui.VDynamicText(getter) => {
      let text_node = doc.createTextNode(getter())
      let node_ref = text_node.as_node()
      let _ = @ui.effect(fn() {
        let new_text = getter()
        node_ref.setTextContent(new_text)
      })
      node_ref
    }
    @ui.VFragment(children) => {
      let fragment = doc.createDocumentFragment()
      for i = 0; i < children.length(); i = i + 1 {
        fragment.as_node().appendChild(render_vnode_to_dom(children[i]))
        |> ignore
      }
      fragment.as_node()
    }
    @ui.VElement(elem) => {
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
    @ui.VShow(condition=cond, child=child_fn) => {
      let placeholder = doc.createComment("show")
      let mut current_node : @js_dom.Node? = None
      let _ = @ui.effect(fn() {
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
    @ui.VFor(render=render_fn) => {
      let container = doc.createDocumentFragment()
      let container_node = container.as_node()
      let current_nodes : Array[@js_dom.Node] = []
      let _ = @ui.effect(fn() {
        let new_items = render_fn()

        // Remove old nodes
        for i = 0; i < current_nodes.length(); i = i + 1 {
          match current_nodes[i].parentNode() {
            Some(par) => par.removeChild(current_nodes[i]) |> ignore
            None => ()
          }
        }
        while current_nodes.length() > 0 {
          let _ = current_nodes.pop()

        }
        for i = 0; i < new_items.length(); i = i + 1 {
          let rendered = render_vnode_to_dom(new_items[i])
          current_nodes.push(rendered)
          container_node.appendChild(rendered) |> ignore
        }
      })
      container_node
    }
    @ui.VComponent(render=render_fn) => render_vnode_to_dom(render_fn())
  }
}

///|
/// Apply VAttr to DOM element
fn apply_vattr(
  elem : @js_dom.Element,
  name : String,
  value : @ui.VAttr,
) -> Unit {
  match value {
    @ui.VStatic(s) =>
      if s != "__remove__" {
        if name == "class" || name == "className" {
          elem.setClassName(s)
        } else if name == "value" {
          elem.as_any()._set("value", @core.any(s)) |> ignore
        } else if s == "" {
          elem.setAttribute(name, "")
        } else {
          elem.setAttribute(name, s)
        }
      }
    @ui.VDynamic(getter) => {
      let _ = @ui.effect(fn() {
        let new_value = getter()
        if new_value == "__remove__" {
          elem.removeAttribute(name)
        } else if name == "class" || name == "className" {
          elem.setClassName(new_value)
        } else if name == "value" {
          elem.as_any()._set("value", @core.any(new_value)) |> ignore
        } else {
          elem.setAttribute(name, new_value)
        }
      })

    }
    @ui.VHandler(handler) => {
      let event_name = extract_event_name(name)
      let handler_any : @core.Any = @core.any(handler)
      elem.as_event_target().addEventListener(event_name, handler_any.cast())
    }
    @ui.VStyle(styles) => {
      let style_prop : @core.Any = elem.as_any()._get("style")
      for i = 0; i < styles.length(); i = i + 1 {
        let (prop, val) = styles[i]
        style_prop._set(prop, @core.any(val)) |> ignore
      }
    }
    @ui.VDynamicStyle(getter) => {
      let _ = @ui.effect(fn() {
        let styles = getter()
        let style_prop : @core.Any = elem.as_any()._get("style")
        for i = 0; i < styles.length(); i = i + 1 {
          let (prop, val) = styles[i]
          style_prop._set(prop, @core.any(val)) |> ignore
        }
      })

    }
  }
}

///|
/// Convenience function: render VNode to DOM and mount
pub fn render_vnode(container : @js_dom.Element, node : @ui.VNode) -> Unit {
  container.as_node().setTextContent("")
  let dom_node = render_vnode_to_dom(node)
  container.as_node().appendChild(dom_node) |> ignore
}
