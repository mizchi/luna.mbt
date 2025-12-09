///| DOM Renderer - Render VNode to actual DOM

///| JS-specific: uses JSVNode and JSHandler

///|

///|
/// Logger function type - receives warning messages
pub type Logger = (String) -> Unit

///|

///|
/// Console logger - outputs to console.warn
pub let console_logger : Logger = fn(message) { console_warn(message) }

///|

///|
/// Silent logger - no output (for tests)
pub let silent_logger : Logger = fn(_message) { () }

///|

///|
/// DOM Renderer - manages rendering VNode to container element
/// JS-specific: uses JSVNode
pub struct DomRenderer {
  container : @dom.Element
  mut root_vnode : JSVNode?
  mut root_node : @dom.Node?
  logger : Logger
}

///|

///|
/// Create new DOM renderer with default console logger
pub fn DomRenderer::new(container : @dom.Element) -> DomRenderer {
  { container, root_vnode: None, root_node: None, logger: console_logger }
}

///|

///|
/// Create new DOM renderer with custom logger
pub fn DomRenderer::new_with_logger(
  container : @dom.Element,
  logger : Logger,
) -> DomRenderer {
  { container, root_vnode: None, root_node: None, logger }
}

///|

///|
/// Render VNode to container (Phase 4: Uses reconciliation for updates)
pub fn DomRenderer::render(self : DomRenderer, vnode : JSVNode) -> Unit {
  match self.root_vnode {
    None => {
      // Initial render - create new DOM tree
      self.container.as_node().setTextContent("")
      match vnode {
        Fragment(_) => {
          // For fragments, add children directly to container
          // and track container as root_node
          let dom_node = create_dom_node(vnode)
          self.container.as_node().appendChild(dom_node) |> ignore
          self.root_vnode = Some(vnode)
          self.root_node = Some(self.container.as_node())
        }
        _ => {
          let dom_node = create_dom_node(vnode)
          self.container.as_node().appendChild(dom_node) |> ignore
          self.root_vnode = Some(vnode)
          self.root_node = Some(dom_node)
        }
      }
    }
    Some(old_vnode) => {
      // Update - use reconciliation
      let patches = diff(
        Some(old_vnode),
        Some(vnode),
        self.root_node,
        Some(self.container.as_node()),
      )
      apply_patches(patches)
      self.root_vnode = Some(vnode)
    }
  }
}

///|

///|
/// Hydrate existing server-rendered DOM with VNode
/// Reuses existing DOM nodes and attaches event handlers
pub fn DomRenderer::hydrate(self : DomRenderer, vnode : JSVNode) -> Unit {
  // Get first child of container (SSR content)
  let first_child = self.container.as_node().firstChild()
  match first_child {
    Some(dom_node) => {
      // Hydrate the existing DOM tree
      let success = hydrate_node(self.logger, vnode, dom_node)
      if success {
        // Hydration succeeded
        self.root_vnode = Some(vnode)
        self.root_node = Some(dom_node)
      } else {
        // Hydration failed - fallback to full render
        (self.logger)(
          "Hydration failed - falling back to client-side render. This may cause content flash.",
        )
        self.container.as_node().setTextContent("")
        self.render(vnode)
      }
    }
    None =>
      // No SSR content - fallback to regular render
      self.render(vnode)
  }
}

///|

///|
/// Hydrate with serialized hooks state (Qwik-like resumability)
/// Extracts and restores state from embedded script tag
/// JavaScript backend only (uses JSON deserialization)
pub fn DomRenderer::hydrate_with_state(
  self : DomRenderer,
  vnode : JSVNode,
  hooks_state : HooksState,
) -> Unit {
  // Get container's innerHTML to extract state
  let container_html : String = self.container.as_any()._get("innerHTML").cast()

  // Extract and restore state if found
  match extract_state_from_html(container_html) {
    Some(state_json) => {
      // Restore hooks state (JavaScript backend)
      hooks_state.restore_from_json(state_json)

      // Remove the state script tag from DOM
      remove_state_script(self.container)
    }
    None => ()
  }

  // Proceed with normal hydration
  self.hydrate(vnode)
}

///|

///|
/// Remove state script tag from container
fn remove_state_script(container : @dom.Element) -> Unit {
  // Find and remove script tag with data-hooks-state
  let scripts = container.querySelectorAll("script[data-hooks-state]")
  for i = 0; i < scripts.length(); i = i + 1 {
    let script = scripts[i]
    container.as_node().removeChild(script.as_node()) |> ignore
  }
}

///|

///|
/// Create DOM node from VNode
/// JS-specific: uses JSVNode
fn create_dom_node(vnode : JSVNode) -> @dom.Node {
  match vnode {
    Empty => @dom.document().createTextNode("").as_node()
    Text(content) => @dom.document().createTextNode(content).as_node()
    Element({ tag, props, children, .. }) => {
      let element = @dom.document().createElement(tag)
      apply_props(element, props)
      for child in children {
        let child_node = create_dom_node(child)
        element.as_node().appendChild(child_node) |> ignore
      }
      element.as_node()
    }
    Fragment(children) => {
      let fragment = @dom.document().createDocumentFragment()
      for child in children {
        let child_node = create_dom_node(child)
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
/// JS-specific: uses JSProps
fn apply_props(element : @dom.Element, props : JSProps) -> Unit {
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
        set_event_handler(element, key, h)
      StyleObj(styles) =>
        // Style object
        apply_style(element, styles)
    }
  }
}

///|

///|
/// Set event handler on element
/// JS-specific: uses JSHandler
fn set_event_handler(
  element : @dom.Element,
  event_name : String,
  handler : JSHandler,
) -> Unit {
  // Convert "onClick" to "click", "onChange" to "change"
  // Simply lowercase the entire event name after removing "on" prefix
  let event_type = if event_name.length() >= 2 {
    let mut result = ""
    let iter = event_name.iter()
    let mut skip_count = 0
    for char in iter {
      if skip_count < 2 {
        // Skip "on" prefix
        skip_count = skip_count + 1
        continue
      }
      // Convert uppercase to lowercase
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

  // Use addEventListener
  let handler_any : @core.Any = @core.any(handler)
  element.as_event_target().addEventListener(event_type, handler_any.cast())
}

///|

///|
/// Apply style object to element
fn apply_style(
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
/// Hydration mismatch error types
priv enum HydrationError {
  TagMismatch(String, String) // (expected, actual)
  TextMismatch(String, String) // (expected, actual)
  NodeTypeMismatch(String, Int) // (expected, actual)
  ChildCountMismatch(Int, Int) // (expected, actual)
  MissingNode
}

///|

///|
/// Call console.warn from JavaScript
fn console_warn(message : String) -> Unit = "console" "warn"

///|

///|
/// Log hydration warning using provided logger
fn warn_hydration_mismatch(
  logger : Logger,
  error : HydrationError,
  path : String,
) -> Unit {
  let message = match error {
    TagMismatch(expected, actual) =>
      "Hydration mismatch at '\{path}': expected tag '\{expected}', got '\{actual}'"
    TextMismatch(expected, actual) =>
      "Hydration mismatch at '\{path}': expected text '\{expected}', got '\{actual}'"
    NodeTypeMismatch(expected, actual) =>
      "Hydration mismatch at '\{path}': expected node type '\{expected}', got type \{actual}"
    ChildCountMismatch(expected, actual) =>
      "Hydration mismatch at '\{path}': expected \{expected} children, got \{actual}"
    MissingNode =>
      "Hydration mismatch at '\{path}': expected DOM node, but none found"
  }
  logger(message)
}

///|

///|
/// Hydrate a VNode with an existing DOM node
/// Reuses the DOM structure and only attaches event handlers
/// Returns true if hydration succeeded, false if recovery needed
fn hydrate_node(logger : Logger, vnode : JSVNode, dom_node : @dom.Node) -> Bool {
  hydrate_node_with_path(logger, vnode, dom_node, "root")
}

///|

///|
/// Hydrate with path tracking for better error messages
fn hydrate_node_with_path(
  logger : Logger,
  vnode : JSVNode,
  dom_node : @dom.Node,
  path : String,
) -> Bool {
  match vnode {
    Empty => {
      // Empty node should be an empty text node
      let node_type = dom_node.nodeType()
      if node_type != 3 {
        // Not a text node
        warn_hydration_mismatch(
          logger,
          NodeTypeMismatch("TEXT_NODE", node_type),
          path,
        )
        return false
      }
      true
    }
    Text(content) => {
      // Verify it's a text node
      let node_type = dom_node.nodeType()
      if node_type != 3 {
        // Not a text node - type mismatch
        warn_hydration_mismatch(
          logger,
          NodeTypeMismatch("TEXT_NODE", node_type),
          path,
        )
        return false
      }

      // Verify text content matches
      let actual_text = dom_node.textContent()
      if actual_text != content {
        warn_hydration_mismatch(
          logger,
          TextMismatch(content, actual_text),
          path,
        )
        // Still recoverable - update text content
        dom_node.setTextContent(content)
      }
      true
    }
    Element({ tag, props, children, .. }) => {
      // Verify it's an element node
      let node_type = dom_node.nodeType()
      if node_type != 1 {
        // Not an element node
        warn_hydration_mismatch(
          logger,
          NodeTypeMismatch("ELEMENT_NODE", node_type),
          path,
        )
        return false
      }

      // Verify tag name matches
      let node_name = dom_node.nodeName()
      let expected_name = to_uppercase(tag)
      if node_name != expected_name {
        warn_hydration_mismatch(
          logger,
          TagMismatch(expected_name, node_name),
          path,
        )
        // Tag mismatch is critical - cannot recover safely
        return false
      }

      // Apply props (especially event handlers which SSR skips)
      let element : @dom.Element = dom_node.as_any().cast()
      apply_props(element, props)

      // Hydrate children
      let child_nodes = dom_node.childNodes()
      let expected_count = children.length()
      let actual_count = child_nodes.length()

      // Warn if child count differs
      if expected_count != actual_count {
        warn_hydration_mismatch(
          logger,
          ChildCountMismatch(expected_count, actual_count),
          path,
        )
      }

      // Hydrate existing children and track success
      let mut all_success = true
      for i = 0; i < children.length(); i = i + 1 {
        let child_vnode = children[i]
        let child_path = path + "[" + i.to_string() + "]"
        if i < child_nodes.length() {
          let child_node = child_nodes[i]
          let success = hydrate_node_with_path(
            logger, child_vnode, child_node, child_path,
          )
          if not(success) {
            // Child hydration failed - replace it
            let new_child = create_dom_node(child_vnode)
            dom_node.replaceChild(new_child, child_node) |> ignore
            all_success = false
          }
        } else {
          // Missing child - create and append
          warn_hydration_mismatch(logger, MissingNode, child_path)
          let new_child = create_dom_node(child_vnode)
          dom_node.appendChild(new_child) |> ignore
          all_success = false
        }
      }

      // Remove extra DOM children if VNode has fewer children
      if actual_count > expected_count {
        for i = expected_count; i < actual_count; i = i + 1 {
          // Remove from the end backwards to avoid index shifts
          let last_child = dom_node.lastChild()
          match last_child {
            Some(child) => dom_node.removeChild(child) |> ignore
            None => ()
          }
        }
      }
      all_success
    }
    Fragment(children) => {
      // For fragments, hydrate children with sibling nodes
      let child_nodes = dom_node.childNodes()
      let expected_count = children.length()
      let actual_count = child_nodes.length()

      // Warn if child count differs
      if expected_count != actual_count {
        warn_hydration_mismatch(
          logger,
          ChildCountMismatch(expected_count, actual_count),
          path,
        )
      }
      let mut all_success = true
      for i = 0; i < children.length(); i = i + 1 {
        let child_vnode = children[i]
        let child_path = path + "[" + i.to_string() + "]"
        if i < child_nodes.length() {
          let child_node = child_nodes[i]
          let success = hydrate_node_with_path(
            logger, child_vnode, child_node, child_path,
          )
          if not(success) {
            // Child hydration failed - replace it
            let new_child = create_dom_node(child_vnode)
            dom_node.replaceChild(new_child, child_node) |> ignore
            all_success = false
          }
        } else {
          // Missing child - create and append
          warn_hydration_mismatch(logger, MissingNode, child_path)
          let new_child = create_dom_node(child_vnode)
          dom_node.appendChild(new_child) |> ignore
          all_success = false
        }
      }
      all_success
    }
    Component(_) =>
      abort("Components must be rendered to VNode before hydration")
  }
}

///|

///|
/// Convert string to uppercase (helper for tag name comparison)
fn to_uppercase(s : String) -> String {
  let mut result = ""
  let iter = s.iter()
  for char in iter {
    let upper_char = if char >= 'a' && char <= 'z' {
      (char.to_int() - 32).unsafe_to_char()
    } else {
      char
    }
    result = result + upper_char.to_string()
  }
  result
}
