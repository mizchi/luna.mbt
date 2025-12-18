// Sol Outlet - Partial update region marker
//
// Creates a div element with data-sol-outlet attribute
// to mark regions for partial DOM updates during CSR navigation.
// Mark a region for partial updates during CSR navigation
//
// Renders as `<div data-sol-outlet="name">` which is used by
//

///|
/// sol-nav.js to replace content during navigation.
pub fn outlet(
  name~ : String,
  children : Array[@luna.Node[Unit]],
  id? : String,
  class? : String,
  style? : String,
  attrs? : Array[(String, @luna.Attr[Unit])],
) -> @luna.Node[Unit] {
  let props = build_attrs(id, class, style, attrs)
  props.push(("data-sol-outlet", static_attr(name)))
  create_element("div", props, children)
}

///|
/// Create a template element for fragment response
/// Used internally to wrap outlet content in fragment responses.
pub fn template_outlet(
  name~ : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let props : Array[(String, @luna.Attr[Unit])] = []
  props.push(("data-sol-outlet", static_attr(name)))
  create_element("template", props, children)
}

///|
/// Create a template element for page title in fragment response
pub fn template_title(title : String) -> @luna.Node[Unit] {
  let props : Array[(String, @luna.Attr[Unit])] = []
  props.push(("data-sol-title", static_attr("")))
  create_element("template", props, [text(title)])
}
