///| Element helpers - HTML element factory functions
///|
///| This module provides convenient factory functions for creating HTML elements.
///| Separated from core vnode for smaller bundle size when not needed.

// Element helpers

///|
/// Create a div VNode
pub fn vdiv(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("div", attrs, children)
}

///|
/// Create a span VNode
pub fn vspan(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("span", attrs, children)
}

///|
/// Create a p VNode
pub fn vp(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("p", attrs, children)
}

///|
/// Create a button VNode
pub fn vbutton(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("button", attrs, children)
}

///|
/// Create an a VNode
pub fn va(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("a", attrs, children)
}

///|
/// Create an input VNode
pub fn vinput(attrs : Array[(String, @ui.Attr)]) -> @ui.Node {
  @ui.vnode("input", attrs, [])
}

///|
/// Create a form VNode
pub fn vform(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("form", attrs, children)
}

///|
/// Create a label VNode
pub fn vlabel(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("label", attrs, children)
}

///|
/// Create h1 VNode
pub fn vh1(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("h1", attrs, children)
}

///|
/// Create h2 VNode
pub fn vh2(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("h2", attrs, children)
}

///|
/// Create h3 VNode
pub fn vh3(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("h3", attrs, children)
}

///|
/// Create ul VNode
pub fn vul(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("ul", attrs, children)
}

///|
/// Create ol VNode
pub fn vol(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("ol", attrs, children)
}

///|
/// Create li VNode
pub fn vli(attrs : Array[(String, @ui.Attr)], children : Array[@ui.Node]) -> @ui.Node {
  @ui.vnode("li", attrs, children)
}

///|
/// Create img VNode
pub fn vimg(attrs : Array[(String, @ui.Attr)]) -> @ui.Node {
  @ui.vnode("img", attrs, [])
}

///|
/// Create br VNode
pub fn vbr() -> @ui.Node {
  @ui.vnode("br", [], [])
}

///|
/// Create hr VNode
pub fn vhr() -> @ui.Node {
  @ui.vnode("hr", [], [])
}
