///| VNode - DOM-independent virtual node representation for SSR

///|
/// Event handler type (opaque for SSR, actual handler in DOM)
pub struct EventHandler(Unit)

///|
/// Create a placeholder event handler (for SSR testing)
pub fn event_handler() -> EventHandler {
  EventHandler(())
}

///|
/// Attribute value that can be static or dynamic (signal-based)
pub enum Attr {
  VStatic(String)
  VDynamic(() -> String)
  VHandler(EventHandler)
  VStyle(Array[(String, String)])
  VDynamicStyle(() -> Array[(String, String)])
}

///|
/// Virtual DOM node types
pub enum Node {
  Element(VElement)
  Text(String)
  DynamicText(() -> String)
  Fragment(Array[Node])
  Show(condition~ : () -> Bool, child~ : () -> Node)
  For(render~ : () -> Array[Node])
  Component(render~ : () -> Node)
}

///|
/// Virtual element node
pub struct VElement {
  tag : String
  attrs : Array[(String, Attr)]
  children : Array[Node]
}

///|
/// Create a VNode element
pub fn vnode(
  tag : String,
  attrs : Array[(String, Attr)],
  children : Array[Node],
) -> Node {
  Element({ tag, attrs, children })
}

///|
/// Create a text VNode
pub fn vtext(content : String) -> Node {
  Text(content)
}

///|
/// Create a dynamic text VNode
pub fn vtext_dyn(content : () -> String) -> Node {
  DynamicText(content)
}

///|
/// Create a text VNode from a signal
pub fn[T : Show] vtext_sig(sig : Signal[T]) -> Node {
  DynamicText(fn() { sig.get().to_string() })
}

///|
/// Create a fragment VNode
pub fn vfragment(children : Array[Node]) -> Node {
  Fragment(children)
}

///|
/// Create a conditional VNode
pub fn vshow(when : () -> Bool, child : () -> Node) -> Node {
  Show(condition=when, child~)
}

///|
/// Create a list VNode
pub fn vfor(items : () -> Array[Node]) -> Node {
  For(render=items)
}

///|
/// Create a component VNode
pub fn vcomponent(render : () -> Node) -> Node {
  Component(render~)
}

// Element helpers

///|
/// Create a div VNode
pub fn vdiv(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("div", attrs, children)
}

///|
/// Create a span VNode
pub fn vspan(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("span", attrs, children)
}

///|
/// Create a p VNode
pub fn vp(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("p", attrs, children)
}

///|
/// Create a button VNode
pub fn vbutton(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("button", attrs, children)
}

///|
/// Create an a VNode
pub fn va(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("a", attrs, children)
}

///|
/// Create an input VNode
pub fn vinput(attrs : Array[(String, Attr)]) -> Node {
  vnode("input", attrs, [])
}

///|
/// Create a form VNode
pub fn vform(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("form", attrs, children)
}

///|
/// Create a label VNode
pub fn vlabel(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("label", attrs, children)
}

///|
/// Create h1 VNode
pub fn vh1(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("h1", attrs, children)
}

///|
/// Create h2 VNode
pub fn vh2(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("h2", attrs, children)
}

///|
/// Create h3 VNode
pub fn vh3(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("h3", attrs, children)
}

///|
/// Create ul VNode
pub fn vul(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("ul", attrs, children)
}

///|
/// Create ol VNode
pub fn vol(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("ol", attrs, children)
}

///|
/// Create li VNode
pub fn vli(attrs : Array[(String, Attr)], children : Array[Node]) -> Node {
  vnode("li", attrs, children)
}

///|
/// Create img VNode
pub fn vimg(attrs : Array[(String, Attr)]) -> Node {
  vnode("img", attrs, [])
}

///|
/// Create br VNode
pub fn vbr() -> Node {
  vnode("br", [], [])
}

///|
/// Create hr VNode
pub fn vhr() -> Node {
  vnode("hr", [], [])
}

// Attribute helpers

///|
/// Create a static attribute
pub fn vattr(key : String, value : String) -> (String, Attr) {
  (key, VStatic(value))
}

///|
/// Create a dynamic attribute
pub fn vattr_dyn(key : String, getter : () -> String) -> (String, Attr) {
  (key, VDynamic(getter))
}

///|
/// Create a className attribute
pub fn vclass(value : String) -> (String, Attr) {
  ("class", VStatic(value))
}

///|
/// Create a dynamic className attribute
pub fn vclass_dyn(getter : () -> String) -> (String, Attr) {
  ("class", VDynamic(getter))
}

///|
/// Create an id attribute
pub fn vid(value : String) -> (String, Attr) {
  ("id", VStatic(value))
}

///|
/// Create a href attribute
pub fn vhref(value : String) -> (String, Attr) {
  ("href", VStatic(value))
}

///|
/// Create a src attribute
pub fn vsrc(value : String) -> (String, Attr) {
  ("src", VStatic(value))
}

///|
/// Create an alt attribute
pub fn valt(value : String) -> (String, Attr) {
  ("alt", VStatic(value))
}

///|
/// Create a type attribute
pub fn vtype(value : String) -> (String, Attr) {
  ("type", VStatic(value))
}

///|
/// Create a value attribute
pub fn vvalue(value : String) -> (String, Attr) {
  ("value", VStatic(value))
}

///|
/// Create a dynamic value attribute
pub fn vvalue_dyn(getter : () -> String) -> (String, Attr) {
  ("value", VDynamic(getter))
}

///|
/// Create a placeholder attribute
pub fn vplaceholder(value : String) -> (String, Attr) {
  ("placeholder", VStatic(value))
}

///|
/// Create a disabled attribute
pub fn vdisabled(value : Bool) -> (String, Attr) {
  if value {
    ("disabled", VStatic(""))
  } else {
    ("disabled", VStatic("__remove__"))
  }
}

///|
/// Create an onClick handler (placeholder for SSR, actual handler set in DOM)
pub fn von_click(handler : EventHandler) -> (String, Attr) {
  ("onClick", VHandler(handler))
}

///|
/// Create an onInput handler
pub fn von_input(handler : EventHandler) -> (String, Attr) {
  ("onInput", VHandler(handler))
}

///|
/// Create an onChange handler
pub fn von_change(handler : EventHandler) -> (String, Attr) {
  ("onChange", VHandler(handler))
}

///|
/// Create an onSubmit handler
pub fn von_submit(handler : EventHandler) -> (String, Attr) {
  ("onSubmit", VHandler(handler))
}

///|
/// Create a style attribute
pub fn vstyle(styles : Array[(String, String)]) -> (String, Attr) {
  ("style", VStyle(styles))
}

///|
/// Create a dynamic style attribute
pub fn vstyle_dyn(getter : () -> Array[(String, String)]) -> (String, Attr) {
  ("style", VDynamicStyle(getter))
}

///|
/// Check if element has dynamic content that needs hydration
pub fn has_dynamic_content(attrs : Array[(String, Attr)]) -> Bool {
  for attr in attrs {
    let (_, value) = attr
    match value {
      VDynamic(_) | VHandler(_) | VDynamicStyle(_) => return true
      _ => ()
    }
  }
  false
}
