///| Patch application - applies diff results to DOM
///| Extracted from proto_vdom

///|
/// Apply an array of patches to the DOM
pub fn apply_patches(patches : Array[Patch[JSHandler]]) -> Unit {
  for patch in patches {
    apply_patch(patch)
  }
}

///|
/// Apply a single patch to the DOM
fn apply_patch(patch : Patch[JSHandler]) -> Unit {
  match patch {
    CreateElement(vnode, parent, before) => {
      let dom_node = create_dom_node(vnode)
      match before {
        Some(ref_node) =>
          parent.insertBefore(dom_node, Some(ref_node)) |> ignore
        None => parent.appendChild(dom_node) |> ignore
      }
    }
    RemoveNode(node, parent) => parent.removeChild(node) |> ignore
    ReplaceNode(old_node, new_vnode, parent) => {
      let new_dom_node = create_dom_node(new_vnode)
      parent.replaceChild(new_dom_node, old_node) |> ignore
    }
    UpdateProps(element, old_props, new_props) =>
      update_props(element, old_props, new_props)
    UpdateText(text_node, new_text) =>
      text_node.as_node().setTextContent(new_text)
    ReconcileChildren(parent, old_vnodes, new_vnodes, old_dom_nodes) =>
      reconcile_children(parent, old_vnodes, new_vnodes, old_dom_nodes)
  }
}

///|
/// Create DOM node from VNode
fn create_dom_node(vnode : JSVNode) -> @js_dom.Node {
  match vnode {
    Empty => @js_dom.document().createTextNode("").as_node()
    Text(content) => @js_dom.document().createTextNode(content).as_node()
    Element({ tag, props, children, .. }) => {
      let element = @js_dom.document().createElement(tag)
      apply_props(element, props)
      for child in children {
        let child_node = create_dom_node(child)
        element.as_node().appendChild(child_node) |> ignore
      }
      element.as_node()
    }
    Fragment(children) => {
      let fragment = @js_dom.document().createDocumentFragment()
      for child in children {
        let child_node = create_dom_node(child)
        fragment.as_node().appendChild(child_node) |> ignore
      }
      fragment.as_node()
    }
  }
}

///|
/// Apply props to DOM element
fn apply_props(element : @js_dom.Element, props : JSProps) -> Unit {
  for i = 0; i < props.length(); i = i + 1 {
    let (key, value) = props[i]
    match value {
      Str(s) =>
        if key == "className" {
          element.setClassName(s)
        } else {
          element.setAttribute(key, s)
        }
      Num(n) => element.setAttribute(key, n.to_string())
      Bool(b) =>
        if b {
          element.setAttribute(key, "")
        } else {
          element.removeAttribute(key)
        }
      Handler(h) => set_event_handler(element, key, h)
      StyleObj(styles) => apply_style(element, styles)
    }
  }
}

///|
/// Set event handler on element
fn set_event_handler(
  element : @js_dom.Element,
  event_name : String,
  handler : JSHandler,
) -> Unit {
  // Convert "onClick" to "click", "onInput" to "input", etc.
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
  let handler_any : @core.Any = @core.any(handler)
  element.as_event_target().addEventListener(event_type, handler_any.cast())
}

///|
/// Apply style object to element
fn apply_style(
  element : @js_dom.Element,
  styles : Array[(String, String)],
) -> Unit {
  let style_prop : @core.Any = element.as_any()._get("style")
  for i = 0; i < styles.length(); i = i + 1 {
    let (key, value) = styles[i]
    style_prop._set(key, @core.any(value)) |> ignore
  }
}

///|
/// Update DOM element props (remove old, add new)
fn update_props(
  element : @js_dom.Element,
  old_props : JSProps,
  new_props : JSProps,
) -> Unit {
  // Remove old props that are not in new props
  for i = 0; i < old_props.length(); i = i + 1 {
    let (old_key, _) = old_props[i]
    // Skip event handlers
    if old_key.length() >= 2 {
      if old_key.code_unit_at(0) == "o".code_unit_at(0) &&
        old_key.code_unit_at(1) == "n".code_unit_at(0) {
        continue
      }
    }
    // Check if key exists in new props
    let mut exists_in_new = false
    for j = 0; j < new_props.length(); j = j + 1 {
      let (new_key, _) = new_props[j]
      if new_key == old_key {
        exists_in_new = true
        break
      }
    }
    if not(exists_in_new) {
      if old_key != "style" {
        element.removeAttribute(old_key)
      }
    }
  }
  // Apply new props
  apply_props(element, new_props)
}

///|
/// Reconcile children (simple non-keyed algorithm)
fn reconcile_children(
  parent : @js_dom.Element,
  old_vnodes : Array[JSVNode],
  new_vnodes : Array[JSVNode],
  old_dom_nodes : Array[@js_dom.Node],
) -> Unit {
  let old_len = old_vnodes.length()
  let new_len = new_vnodes.length()
  let max_len = if old_len > new_len { old_len } else { new_len }
  for i = 0; i < max_len; i = i + 1 {
    let old_vnode : JSVNode? = if i < old_len { Some(old_vnodes[i]) } else { None }
    let new_vnode : JSVNode? = if i < new_len { Some(new_vnodes[i]) } else { None }
    let old_dom = if i < old_dom_nodes.length() {
      Some(old_dom_nodes[i])
    } else {
      None
    }
    let patches = diff(old_vnode, new_vnode, old_dom, Some(parent.as_node()))
    apply_patches(patches)
  }
}
