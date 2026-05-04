// Sol Link - CSR navigation link component
//
// Creates an anchor element with data-sol-link attribute
// for client-side navigation without full page reload.
// Create a Sol Link for CSR navigation
//
// Renders as `<a href="..." data-sol-link>` which is intercepted
//

///|
/// by sol-nav.js for client-side navigation.
pub fn sol_link(
  href~ : String,
  children : Array[@luna.Node[Unit, String]],
  id? : String,
  class? : String,
  style? : String,
  prefetch? : Bool,
  replace? : Bool,
  attrs? : Array[(String, @luna.Attr[Unit, String])],
) -> @luna.Node[Unit, String] {
  let props = build_attrs(id, class, style, attrs)
  props.push(("href", static_attr(href)))
  props.push(("data-sol-link", static_attr("")))
  if prefetch is Some(true) {
    props.push(("data-sol-prefetch", static_attr("")))
  }
  if replace is Some(true) {
    props.push(("data-sol-replace", static_attr("")))
  }
  create_element("a", props, children)
}
