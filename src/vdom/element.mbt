///| Element creation DSL - Generic over handler type H

///|

///|
/// Create element VNode - accepts Props type
pub fn[H] el(
  tag : String,
  props : Props[H],
  children : Array[VNode[H]],
) -> VNode[H] {
  VNode::Element(ElementNode::{ tag, props, children, key: None })
}

///|

///|
/// Create element with key
pub fn[H] el_key(
  tag : String,
  props : Props[H],
  children : Array[VNode[H]],
  key : String,
) -> VNode[H] {
  VNode::Element(ElementNode::{ tag, props, children, key: Some(key) })
}

///| Common HTML elements

///|
pub fn[H] div(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("div", props, children)
}

///|
pub fn[H] span(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("span", props, children)
}

///|
pub fn[H] p(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("p", props, children)
}

///|
pub fn[H] button(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("button", props, children)
}

///|
pub fn[H] a(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("a", props, children)
}

///|
pub fn[H] input(props : Props[H]) -> VNode[H] {
  el("input", props, [])
}

///|
pub fn[H] textarea(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("textarea", props, children)
}

///|
pub fn[H] form(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("form", props, children)
}

///|
pub fn[H] label(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("label", props, children)
}

///|
pub fn[H] h1(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("h1", props, children)
}

///|
pub fn[H] h2(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("h2", props, children)
}

///|
pub fn[H] h3(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("h3", props, children)
}

///|
pub fn[H] h4(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("h4", props, children)
}

///|
pub fn[H] h5(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("h5", props, children)
}

///|
pub fn[H] h6(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("h6", props, children)
}

///|
pub fn[H] ul(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("ul", props, children)
}

///|
pub fn[H] ol(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("ol", props, children)
}

///|
pub fn[H] li(props : Props[H], children : Array[VNode[H]]) -> VNode[H] {
  el("li", props, children)
}

///|
pub fn[H] img(props : Props[H]) -> VNode[H] {
  el("img", props, [])
}

///|
/// br with no props
pub fn[H] br() -> VNode[H] {
  el("br", [], [])
}

///|
/// hr with no props
pub fn[H] hr() -> VNode[H] {
  el("hr", [], [])
}

///| Text and Fragment

///|

///|
/// Create text node
pub fn[H] text(content : String) -> VNode[H] {
  VNode::Text(content)
}

///|

///|
/// Create fragment
pub fn[H] fragment(children : Array[VNode[H]]) -> VNode[H] {
  VNode::Fragment(children)
}

///|

///|
/// Empty node (renders nothing)
pub fn[H] empty() -> VNode[H] {
  VNode::Empty
}
