// Portal - Render content outside the component tree
//
// Similar to SolidJS <Portal>
// https://docs.solidjs.com/reference/components/portal
//

///|
/// DomNode type (imported from element package for now)
pub(all) enum DomNode {
  El(@js_dom.Element)
  Txt(@js_dom.Text)
  Raw(@js_dom.Node)
}

///|
/// Convert DomNode to @js_dom.Node
pub fn DomNode::to_dom(self : DomNode) -> @js_dom.Node {
  match self {
    El(elem) => elem.as_node()
    Txt(text) => text.as_node()
    Raw(node) => node
  }
}

///|
/// Cast Element to HTMLElement (for attachShadow)
fn element_to_html_element(el : @js_dom.Element) -> @js_dom.HTMLElement = "%identity"

///|
/// Portal configuration options
pub struct PortalOptions {
  /// Target element to mount to (defaults to document.body)
  mount : @js_dom.Element?
  /// Whether to use Shadow DOM for encapsulation
  use_shadow : Bool
  /// Whether the content is SVG
  is_svg : Bool
}

///|
/// Default portal options
pub fn PortalOptions::default() -> PortalOptions {
  { mount: None, use_shadow: false, is_svg: false }
}

///|
/// Create portal options with mount target
pub fn PortalOptions::with_mount(mount : @js_dom.Element) -> PortalOptions {
  { mount: Some(mount), use_shadow: false, is_svg: false }
}

///|
/// Create portal options with shadow DOM
pub fn PortalOptions::with_shadow() -> PortalOptions {
  { mount: None, use_shadow: true, is_svg: false }
}

///|
/// Create a portal that renders children into a different DOM location
///
/// Portal teleports its children to another part of the DOM tree,
/// outside the normal component hierarchy.
///
/// Use cases:
/// - Modals that need to render at body level to avoid z-index issues
/// - Dropdowns/tooltips that need to escape overflow: hidden containers
/// - Full-screen overlays
///
/// Example:
/// ```
/// portal(
///   options=PortalOptions::default(),
///   children=[modal_content()]
/// )
/// ```
pub fn portal(options : PortalOptions, children : Array[DomNode]) -> DomNode {
  let doc = @js_dom.document()

  // Determine mount target
  let mount_target = match options.mount {
    Some(el) => el
    None =>
      match doc.body() {
        Some(body) => body.as_element()
        None =>
          // Fallback: create a div and append to document
          doc.createElement("div")
      }
  }

  // Create container element
  let container = if options.is_svg {
    doc.createElementNs("http://www.w3.org/2000/svg", "g")
  } else {
    doc.createElement("div")
  }

  // Setup Shadow DOM if requested
  let render_target : @js_dom.Node = if options.use_shadow {
    let html_el = element_to_html_element(mount_target)
    let shadow = html_el.attachShadow(@js_dom.ShadowRootInit::new("open"))
    shadow.as_node().appendChild(container.as_node()) |> ignore
    container.as_node()
  } else {
    mount_target.as_node().appendChild(container.as_node()) |> ignore
    container.as_node()
  }

  // Render children into the portal container
  let child_nodes : Array[@js_dom.Node] = []
  for child in children {
    let node = child.to_dom()
    render_target.appendChild(node) |> ignore
    child_nodes.push(node)
  }

  // Register cleanup with current owner
  let cleanup_fn = fn() {
    // Remove children
    for node in child_nodes {
      match node.parentNode() {
        Some(parent) => parent.removeChild(node) |> ignore
        None => ()
      }
    }
    // Remove container
    match container.as_node().parentNode() {
      Some(parent) => parent.removeChild(container.as_node()) |> ignore
      None => ()
    }
  }
  @signal.on_cleanup(cleanup_fn)

  // Return a comment placeholder at the original location
  let placeholder = doc.createComment("portal")
  Raw(placeholder)
}

///|
/// Convenience function: portal to document.body
pub fn portal_to_body(children : Array[DomNode]) -> DomNode {
  portal(PortalOptions::default(), children)
}

///|
/// Convenience function: portal to a specific selector
pub fn portal_to_selector(
  selector : String,
  children : Array[DomNode],
) -> DomNode {
  let doc = @js_dom.document()
  let options = match doc.querySelector(selector) {
    Some(el) => PortalOptions::with_mount(el)
    None => PortalOptions::default()
  }
  portal(options, children)
}

///|
/// Convenience function: portal with shadow DOM encapsulation
pub fn portal_with_shadow(children : Array[DomNode]) -> DomNode {
  portal(PortalOptions::with_shadow(), children)
}

///|
/// Portal to a specific element with shadow DOM
pub fn portal_to_with_shadow(
  mount : @js_dom.Element,
  children : Array[DomNode],
) -> DomNode {
  let options : PortalOptions = {
    mount: Some(mount),
    use_shadow: true,
    is_svg: false,
  }
  portal(options, children)
}
