///| Hydration - Connect VNode to existing server-rendered DOM

///| Hydration context to track current position in DOM
priv struct HydrationContext {
  mut current_id : Int
}

///| Helper to get text content with default
fn get_text_content(node : @dom.Node) -> String {
  let data : @core.Any = node.as_any()._get("data")
  data.cast()
}

///| Hydrate a VNode into an existing DOM container
///| The container should already have server-rendered HTML with hydration markers
pub fn hydrate(container : @dom.Element, node : VNode) -> Unit {
  let ctx : HydrationContext = { current_id: 0 }
  hydrate_node(container.as_node(), node, ctx)
}

///| Internal: Hydrate a single node
fn hydrate_node(parent : @dom.Node, node : VNode, ctx : HydrationContext) -> Unit {
  match node {
    VText(_) => {
      // Static text doesn't need hydration
      ()
    }
    VDynamicText(getter) => {
      // Find the text marker comments and set up effect
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_dynamic_text(parent, id, getter)
    }
    VFragment(children) => {
      for i = 0; i < children.length(); i = i + 1 {
        hydrate_node(parent, children[i], ctx)
      }
    }
    VElement(elem) => {
      let id = ctx.current_id
      ctx.current_id = id + 1

      // Check if this element needs hydration
      let needs_hydration = has_dynamic_content(elem.attrs)

      if needs_hydration {
        // Find element by data-hk attribute
        match find_element_by_hk(id) {
          Some(dom_elem) => {
            // Attach event handlers and dynamic attributes
            hydrate_element(dom_elem, elem.attrs)
          }
          None => ()
        }
      }

      // Hydrate children
      match find_element_by_hk(id) {
        Some(dom_elem) => {
          for i = 0; i < elem.children.length(); i = i + 1 {
            hydrate_node(dom_elem.as_node(), elem.children[i], ctx)
          }
        }
        None => {
          // If no hk attribute, try to find by tag
          // This is a fallback for elements without handlers
          ()
        }
      }
    }
    VShow(condition=cond, child=child_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_show(parent, id, cond, child_fn, ctx)
    }
    VFor(render=render_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      hydrate_for(parent, id, render_fn, ctx)
    }
    VComponent(render=render_fn) => {
      hydrate_node(parent, render_fn(), ctx)
    }
  }
}

///| Find element with data-hk="id" attribute
fn find_element_by_hk(id : Int) -> @dom.Element? {
  let doc = @dom.document()
  let selector = "[data-hk=\"" + id.to_string() + "\"]"
  doc.querySelector(selector)
}

///| Hydrate dynamic text node
fn hydrate_dynamic_text(parent : @dom.Node, id : Int, getter : () -> String) -> Unit {
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
          Some(text_node) => {
            if text_node.nodeType() == 3 { // Text node
              // Set up effect to update text
              let _ = effect(fn() {
                let new_text = getter()
                text_node.setTextContent(new_text)
              })
            }
          }
          None => ()
        }
        break
      }
    }
  }
}

///| Hydrate element attributes and handlers
fn hydrate_element(elem : @dom.Element, attrs : Array[(String, VAttr)]) -> Unit {
  for i = 0; i < attrs.length(); i = i + 1 {
    let (name, value) = attrs[i]
    match value {
      VStatic(_) => {
        // Static attributes already rendered, nothing to do
        ()
      }
      VDynamic(getter) => {
        // Set up effect to update attribute
        let _ = effect(fn() {
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
      VHandler(handler) => {
        // Attach event handler
        let event_name = extract_event_name(name)
        let handler_any : @core.Any = @core.any(handler)
        elem.as_event_target().addEventListener(event_name, handler_any.cast())
      }
      VStyle(_) => {
        // Static style already rendered
        ()
      }
      VDynamicStyle(getter) => {
        // Set up effect to update style
        let _ = effect(fn() {
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

///| Extract event name from handler name (onClick -> click)
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

///| Hydrate conditional show
fn hydrate_show(
  parent : @dom.Node,
  id : Int,
  cond : () -> Bool,
  child_fn : () -> VNode,
  ctx : HydrationContext,
) -> Unit {
  let marker_start = "s:" + id.to_string()

  // Find the show marker
  let children = parent.childNodes()
  let mut start_marker : @dom.Node? = None

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
      let current_nodes : Array[@dom.Node] = []

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
      let _ = effect(fn() {
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

///| Hydrate child nodes with VNode
fn hydrate_child_nodes(
  nodes : Array[@dom.Node],
  node : VNode,
  ctx : HydrationContext,
) -> Unit {
  // For now, just traverse the VNode and update ctx
  let _ = nodes // suppress unused warning
  match node {
    VText(_) => ()
    VDynamicText(_) => {
      ctx.current_id = ctx.current_id + 1
    }
    VFragment(children) => {
      for i = 0; i < children.length(); i = i + 1 {
        hydrate_child_nodes(nodes, children[i], ctx)
      }
    }
    VElement(elem) => {
      ctx.current_id = ctx.current_id + 1
      for i = 0; i < elem.children.length(); i = i + 1 {
        hydrate_child_nodes(nodes, elem.children[i], ctx)
      }
    }
    VShow(condition=condition_fn, child=child_getter) => {
      ctx.current_id = ctx.current_id + 1
      if condition_fn() {
        hydrate_child_nodes(nodes, child_getter(), ctx)
      }
    }
    VFor(render=render_fn) => {
      ctx.current_id = ctx.current_id + 1
      let items = render_fn()
      for i = 0; i < items.length(); i = i + 1 {
        hydrate_child_nodes(nodes, items[i], ctx)
      }
    }
    VComponent(render=render_fn) => {
      hydrate_child_nodes(nodes, render_fn(), ctx)
    }
  }
}

///| Hydrate for loop
fn hydrate_for(
  parent : @dom.Node,
  id : Int,
  render_fn : () -> Array[VNode],
  ctx : HydrationContext,
) -> Unit {
  let marker_start = "f:" + id.to_string()

  // Find the for marker
  let children = parent.childNodes()
  let mut start_marker : @dom.Node? = None
  let mut end_marker : @dom.Node? = None

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
      let current_nodes : Array[@dom.Node] = []

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
      let _ = effect(fn() {
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

///| Render VNode to DOM node (for client-side rendering after hydration)
pub fn render_vnode_to_dom(node : VNode) -> @dom.Node {
  let doc = @dom.document()
  match node {
    VText(content) => doc.createTextNode(content).as_node()
    VDynamicText(getter) => {
      let text_node = doc.createTextNode(getter())
      let node_ref = text_node.as_node()
      let _ = effect(fn() {
        let new_text = getter()
        node_ref.setTextContent(new_text)
      })
      node_ref
    }
    VFragment(children) => {
      let fragment = doc.createDocumentFragment()
      for i = 0; i < children.length(); i = i + 1 {
        fragment.as_node().appendChild(render_vnode_to_dom(children[i])) |> ignore
      }
      fragment.as_node()
    }
    VElement(elem) => {
      let dom_elem = doc.createElement(elem.tag)

      // Apply attributes
      for i = 0; i < elem.attrs.length(); i = i + 1 {
        let (name, value) = elem.attrs[i]
        apply_vattr(dom_elem, name, value)
      }

      // Append children
      for i = 0; i < elem.children.length(); i = i + 1 {
        dom_elem.as_node().appendChild(render_vnode_to_dom(elem.children[i])) |> ignore
      }

      dom_elem.as_node()
    }
    VShow(condition=cond, child=child_fn) => {
      let placeholder = doc.createComment("show")
      let mut current_node : @dom.Node? = None

      let _ = effect(fn() {
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
          (false, Some(n)) => {
            match n.parentNode() {
              Some(par) => {
                par.removeChild(n) |> ignore
                current_node = None
              }
              None => ()
            }
          }
          _ => ()
        }
      })

      placeholder
    }
    VFor(render=render_fn) => {
      let container = doc.createDocumentFragment()
      let container_node = container.as_node()
      let current_nodes : Array[@dom.Node] = []

      let _ = effect(fn() {
        let new_items = render_fn()

        // Remove old nodes
        for i = 0; i < current_nodes.length(); i = i + 1 {
          match current_nodes[i].parentNode() {
            Some(par) => {
              par.removeChild(current_nodes[i]) |> ignore
            }
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
    VComponent(render=render_fn) => render_vnode_to_dom(render_fn())
  }
}

///| Apply VAttr to DOM element
fn apply_vattr(elem : @dom.Element, name : String, value : VAttr) -> Unit {
  match value {
    VStatic(s) => {
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
    }
    VDynamic(getter) => {
      let _ = effect(fn() {
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
    VHandler(handler) => {
      let event_name = extract_event_name(name)
      let handler_any : @core.Any = @core.any(handler)
      elem.as_event_target().addEventListener(event_name, handler_any.cast())
    }
    VStyle(styles) => {
      let style_prop : @core.Any = elem.as_any()._get("style")
      for i = 0; i < styles.length(); i = i + 1 {
        let (prop, val) = styles[i]
        style_prop._set(prop, @core.any(val)) |> ignore
      }
    }
    VDynamicStyle(getter) => {
      let _ = effect(fn() {
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

///| Convenience function: render VNode to DOM and mount
pub fn render_vnode(container : @dom.Element, node : VNode) -> Unit {
  container.as_node().setTextContent("")
  let dom_node = render_vnode_to_dom(node)
  container.as_node().appendChild(dom_node) |> ignore
}
