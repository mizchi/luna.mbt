///| Reconciliation - Diff algorithm and patch generation

///|

///| The diff algorithm is generic over handler type H, but DOM operations

///| are JS-specific and use JSHandler.

///|

///|
/// Patch operations - represents changes to apply to the DOM
/// Generic over handler type H for VNode compatibility
enum Patch[H] {
  CreateElement(VNode[H], @dom.Node, @dom.Node?) // vnode, parent, before
  RemoveNode(@dom.Node, @dom.Node) // node, parent
  ReplaceNode(@dom.Node, VNode[H], @dom.Node) // old_node, new_vnode, parent
  UpdateProps(@dom.Element, Props[H], Props[H]) // element, old_props, new_props
  UpdateText(@dom.Text, String) // text_node, new_text
  ReconcileChildren(
    @dom.Element,
    Array[VNode[H]],
    Array[VNode[H]],
    Array[@dom.Node]
  ) // parent, old_vnodes, new_vnodes, old_dom_nodes
}

///|

///|
/// Diff two optional VNodes and generate patches
/// Generic over handler type H
pub fn[H] diff(
  old_vnode : VNode[H]?,
  new_vnode : VNode[H]?,
  dom_node : @dom.Node?,
  parent : @dom.Node?,
) -> Array[Patch[H]] {
  match (old_vnode, new_vnode) {
    (None, Some(new_v)) =>
      // Create new node
      match parent {
        Some(p) => [Patch::CreateElement(new_v, p, None)]
        None => []
      }
    (Some(_), None) =>
      // Remove old node
      match (dom_node, parent) {
        (Some(node), Some(p)) => [Patch::RemoveNode(node, p)]
        _ => []
      }
    (Some(old_v), Some(new_v)) =>
      // Diff existing nodes
      match dom_node {
        Some(node) => diff_nodes(old_v, new_v, node)
        None => []
      }
    (None, None) => []
  }
}

///|

///|
/// Diff two non-null VNodes
/// Generic over handler type H
fn[H] diff_nodes(
  old : VNode[H],
  new : VNode[H],
  dom_node : @dom.Node,
) -> Array[Patch[H]] {
  match (old, new) {
    (Empty, Empty) => []
    (Text(old_text), Text(new_text)) =>
      if old_text != new_text {
        let text_node : @dom.Text = dom_node.as_any().cast()
        [Patch::UpdateText(text_node, new_text)]
      } else {
        []
      }
    (Element(old_el), Element(new_el)) =>
      // If tag changed, replace entire element
      if old_el.tag != new_el.tag {
        match dom_node.parentNode() {
          Some(parent) =>
            [Patch::ReplaceNode(dom_node, Element(new_el), parent)]
          None => []
        }
      } else {
        let patches = []
        let dom_element : @dom.Element = dom_node.as_any().cast()

        // Diff props
        if props_differ(old_el.props, new_el.props) {
          patches.push(
            Patch::UpdateProps(dom_element, old_el.props, new_el.props),
          )
        }

        // Diff children
        let old_dom_children = dom_element.as_node().childNodes()
        patches.push(
          Patch::ReconcileChildren(
            dom_element,
            old_el.children,
            new_el.children,
            old_dom_children,
          ),
        )
        patches
      }
    (Fragment(old_children), Fragment(new_children)) => {
      // For fragments, reconcile children directly
      let dom_element : @dom.Element = dom_node.as_any().cast()
      let old_dom_children = dom_element.as_node().childNodes()
      [
        Patch::ReconcileChildren(
          dom_element, old_children, new_children, old_dom_children,
        ),
      ]
    }
    _ =>
      // Different node types - replace
      match dom_node.parentNode() {
        Some(parent) => [Patch::ReplaceNode(dom_node, new, parent)]
        None => []
      }
  }
}

///|

///|
/// Check if two props differ - uses compare_props from vdom.mbt
/// Generic over handler type H
fn[H] props_differ(old_props : Props[H], new_props : Props[H]) -> Bool {
  not(compare_props(old_props, new_props))
}

///|

///|
/// Apply an array of patches to the DOM
/// JS-specific: uses JSHandler for event handlers
pub fn apply_patches(patches : Array[Patch[JSHandler]]) -> Unit {
  for patch in patches {
    apply_patch(patch)
  }
}

///|

///|
/// Apply a single patch to the DOM
/// JS-specific: uses JSHandler for event handlers
fn apply_patch(patch : Patch[JSHandler]) -> Unit {
  match patch {
    CreateElement(vnode, parent, before) => {
      let dom_node = create_dom_node_from_vnode(vnode)
      match before {
        Some(ref_node) =>
          parent.insertBefore(dom_node, Some(ref_node)) |> ignore
        None => parent.appendChild(dom_node) |> ignore
      }
    }
    RemoveNode(node, parent) => parent.removeChild(node) |> ignore
    ReplaceNode(old_node, new_vnode, parent) => {
      let new_dom_node = create_dom_node_from_vnode(new_vnode)
      parent.replaceChild(new_dom_node, old_node) |> ignore
    }
    UpdateProps(element, old_props, new_props) =>
      update_dom_props(element, old_props, new_props)
    UpdateText(text_node, new_text) =>
      text_node.as_node().setTextContent(new_text)
    ReconcileChildren(parent, old_vnodes, new_vnodes, old_dom_nodes) =>
      reconcile_children(parent, old_vnodes, new_vnodes, old_dom_nodes)
  }
}

///|

///|
/// Create DOM node from VNode (imported from renderer_dom logic)
/// JS-specific: uses JSHandler for event handlers
fn create_dom_node_from_vnode(vnode : JSVNode) -> @dom.Node {
  match vnode {
    Empty => @dom.document().createTextNode("").as_node()
    Text(content) => @dom.document().createTextNode(content).as_node()
    Element({ tag, props, children, .. }) => {
      let element = @dom.document().createElement(tag)
      apply_props_to_element(element, props)
      for child in children {
        let child_node = create_dom_node_from_vnode(child)
        element.as_node().appendChild(child_node) |> ignore
      }
      element.as_node()
    }
    Fragment(children) => {
      let fragment = @dom.document().createDocumentFragment()
      for child in children {
        let child_node = create_dom_node_from_vnode(child)
        fragment.as_node().appendChild(child_node) |> ignore
      }
      fragment.as_node()
    }
    Component(_) =>
      abort("Components must be rendered to VNode before DOM rendering")
  }
}

///|

///|
/// Apply props to DOM element (using typed Props)
/// JS-specific: uses JSHandler for event handlers
fn apply_props_to_element(element : @dom.Element, props : JSProps) -> Unit {
  for i = 0; i < props.length(); i = i + 1 {
    let (key, value) = props[i]
    match value {
      Str(s) =>
        // Handle className specially
        if key == "className" {
          element.setClassName(s)
        } else {
          element.setAttribute(key, s)
        }
      Num(n) =>
        // Numeric attributes (tabIndex, maxLength, etc.)
        element.setAttribute(key, n.to_string())
      Bool(b) =>
        // Boolean attributes (disabled, checked, etc.)
        if b {
          element.setAttribute(key, "")
        } else {
          element.removeAttribute(key)
        }
      Handler(h) =>
        // Event handlers (onClick, onChange, etc.)
        set_event_handler_on_element(element, key, h)
      StyleObj(styles) =>
        // Style object
        apply_style_to_element(element, styles)
    }
  }
}

///|

///|
/// Set event handler on element
/// JS-specific: uses JSHandler = (@core.Any) -> Unit
fn set_event_handler_on_element(
  element : @dom.Element,
  event_name : String,
  handler : JSHandler,
) -> Unit {
  let event_type = if event_name.length() >= 2 {
    let mut result = ""
    let iter = event_name.iter()
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
    event_name
  }
  // JSHandler is (@core.Any) -> Unit, so we can cast it directly
  let handler_any : @core.Any = @core.any(handler)
  element.as_event_target().addEventListener(event_type, handler_any.cast())
}

///|

///|
/// Apply style object to element
fn apply_style_to_element(
  element : @dom.Element,
  styles : Array[(String, String)],
) -> Unit {
  let style_prop : @core.Any = element.as_any()._get("style")
  for i = 0; i < styles.length(); i = i + 1 {
    let (key, value) = styles[i]
    style_prop._set(key, @core.any(value)) |> ignore
  }
}

///|

///|
/// Update DOM element props (remove old, add new)
/// JS-specific: uses JSProps
fn update_dom_props(
  element : @dom.Element,
  old_props : JSProps,
  new_props : JSProps,
) -> Unit {
  // Remove old props that are not in new props
  for i = 0; i < old_props.length(); i = i + 1 {
    let (old_key, _old_value) = old_props[i]

    // Skip event handlers (will be handled separately in the future)
    if old_key.length() >= 2 {
      // Check if starts with "on"
      if old_key.code_unit_at(0) == "o".code_unit_at(0) &&
        old_key.code_unit_at(1) == "n".code_unit_at(0) {
        continue // Event handlers
      }
    }

    // Check if key exists in new props
    let mut exists_in_new = false
    for j = 0; j < new_props.length(); j = j + 1 {
      let (new_key, _new_value) = new_props[j]
      if new_key == old_key {
        exists_in_new = true
        break
      }
    }
    if not(exists_in_new) {
      // Remove attribute (skip style as it needs special handling)
      if old_key != "style" {
        element.removeAttribute(old_key)
      }
    }
  }

  // Apply new props
  apply_props_to_element(element, new_props)
}

///|

///|
/// Reconcile children (simple non-keyed algorithm for now)
/// JS-specific: uses JSVNode
fn reconcile_children(
  parent : @dom.Element,
  old_vnodes : Array[JSVNode],
  new_vnodes : Array[JSVNode],
  old_dom_nodes : Array[@dom.Node],
) -> Unit {
  let old_len = old_vnodes.length()
  let new_len = new_vnodes.length()
  let max_len = if old_len > new_len { old_len } else { new_len }
  for i = 0; i < max_len; i = i + 1 {
    let old_vnode = if i < old_len { Some(old_vnodes[i]) } else { None }
    let new_vnode = if i < new_len { Some(new_vnodes[i]) } else { None }
    let old_dom = if i < old_dom_nodes.length() {
      Some(old_dom_nodes[i])
    } else {
      None
    }
    let patches = diff(old_vnode, new_vnode, old_dom, Some(parent.as_node()))
    apply_patches(patches)
  }
}
