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
pub enum VAttr {
  VStatic(String)
  VDynamic(() -> String)
  VHandler(EventHandler)
  VStyle(Array[(String, String)])
  VDynamicStyle(() -> Array[(String, String)])
}

///|
/// Virtual DOM node types
pub enum VNode {
  VElement(VElement)
  VText(String)
  VDynamicText(() -> String)
  VFragment(Array[VNode])
  VShow(condition~ : () -> Bool, child~ : () -> VNode)
  VFor(render~ : () -> Array[VNode])
  VComponent(render~ : () -> VNode)
}

///|
/// Virtual element node
pub struct VElement {
  tag : String
  attrs : Array[(String, VAttr)]
  children : Array[VNode]
}

///|
/// Create a VNode element
pub fn vnode(
  tag : String,
  attrs : Array[(String, VAttr)],
  children : Array[VNode],
) -> VNode {
  VElement({ tag, attrs, children })
}

///|
/// Create a text VNode
pub fn vtext(content : String) -> VNode {
  VText(content)
}

///|
/// Create a dynamic text VNode
pub fn vtext_dyn(content : () -> String) -> VNode {
  VDynamicText(content)
}

///|
/// Create a text VNode from a signal
pub fn[T : Show] vtext_sig(sig : Signal[T]) -> VNode {
  VDynamicText(fn() { sig.get().to_string() })
}

///|
/// Create a fragment VNode
pub fn vfragment(children : Array[VNode]) -> VNode {
  VFragment(children)
}

///|
/// Create a conditional VNode
pub fn vshow(when : () -> Bool, child : () -> VNode) -> VNode {
  VShow(condition=when, child~)
}

///|
/// Create a list VNode
pub fn vfor(items : () -> Array[VNode]) -> VNode {
  VFor(render=items)
}

///|
/// Create a component VNode
pub fn vcomponent(render : () -> VNode) -> VNode {
  VComponent(render~)
}

// Element helpers

///|
/// Create a div VNode
pub fn vdiv(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("div", attrs, children)
}

///|
/// Create a span VNode
pub fn vspan(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("span", attrs, children)
}

///|
/// Create a p VNode
pub fn vp(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("p", attrs, children)
}

///|
/// Create a button VNode
pub fn vbutton(
  attrs : Array[(String, VAttr)],
  children : Array[VNode],
) -> VNode {
  vnode("button", attrs, children)
}

///|
/// Create an a VNode
pub fn va(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("a", attrs, children)
}

///|
/// Create an input VNode
pub fn vinput(attrs : Array[(String, VAttr)]) -> VNode {
  vnode("input", attrs, [])
}

///|
/// Create a form VNode
pub fn vform(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("form", attrs, children)
}

///|
/// Create a label VNode
pub fn vlabel(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("label", attrs, children)
}

///|
/// Create h1 VNode
pub fn vh1(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("h1", attrs, children)
}

///|
/// Create h2 VNode
pub fn vh2(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("h2", attrs, children)
}

///|
/// Create h3 VNode
pub fn vh3(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("h3", attrs, children)
}

///|
/// Create ul VNode
pub fn vul(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("ul", attrs, children)
}

///|
/// Create ol VNode
pub fn vol(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("ol", attrs, children)
}

///|
/// Create li VNode
pub fn vli(attrs : Array[(String, VAttr)], children : Array[VNode]) -> VNode {
  vnode("li", attrs, children)
}

///|
/// Create img VNode
pub fn vimg(attrs : Array[(String, VAttr)]) -> VNode {
  vnode("img", attrs, [])
}

///|
/// Create br VNode
pub fn vbr() -> VNode {
  vnode("br", [], [])
}

///|
/// Create hr VNode
pub fn vhr() -> VNode {
  vnode("hr", [], [])
}

// Attribute helpers

///|
/// Create a static attribute
pub fn vattr(key : String, value : String) -> (String, VAttr) {
  (key, VStatic(value))
}

///|
/// Create a dynamic attribute
pub fn vattr_dyn(key : String, getter : () -> String) -> (String, VAttr) {
  (key, VDynamic(getter))
}

///|
/// Create a className attribute
pub fn vclass(value : String) -> (String, VAttr) {
  ("class", VStatic(value))
}

///|
/// Create a dynamic className attribute
pub fn vclass_dyn(getter : () -> String) -> (String, VAttr) {
  ("class", VDynamic(getter))
}

///|
/// Create an id attribute
pub fn vid(value : String) -> (String, VAttr) {
  ("id", VStatic(value))
}

///|
/// Create a href attribute
pub fn vhref(value : String) -> (String, VAttr) {
  ("href", VStatic(value))
}

///|
/// Create a src attribute
pub fn vsrc(value : String) -> (String, VAttr) {
  ("src", VStatic(value))
}

///|
/// Create an alt attribute
pub fn valt(value : String) -> (String, VAttr) {
  ("alt", VStatic(value))
}

///|
/// Create a type attribute
pub fn vtype(value : String) -> (String, VAttr) {
  ("type", VStatic(value))
}

///|
/// Create a value attribute
pub fn vvalue(value : String) -> (String, VAttr) {
  ("value", VStatic(value))
}

///|
/// Create a dynamic value attribute
pub fn vvalue_dyn(getter : () -> String) -> (String, VAttr) {
  ("value", VDynamic(getter))
}

///|
/// Create a placeholder attribute
pub fn vplaceholder(value : String) -> (String, VAttr) {
  ("placeholder", VStatic(value))
}

///|
/// Create a disabled attribute
pub fn vdisabled(value : Bool) -> (String, VAttr) {
  if value {
    ("disabled", VStatic(""))
  } else {
    ("disabled", VStatic("__remove__"))
  }
}

///|
/// Create an onClick handler (placeholder for SSR, actual handler set in DOM)
pub fn von_click(handler : EventHandler) -> (String, VAttr) {
  ("onClick", VHandler(handler))
}

///|
/// Create an onInput handler
pub fn von_input(handler : EventHandler) -> (String, VAttr) {
  ("onInput", VHandler(handler))
}

///|
/// Create an onChange handler
pub fn von_change(handler : EventHandler) -> (String, VAttr) {
  ("onChange", VHandler(handler))
}

///|
/// Create an onSubmit handler
pub fn von_submit(handler : EventHandler) -> (String, VAttr) {
  ("onSubmit", VHandler(handler))
}

///|
/// Create a style attribute
pub fn vstyle(styles : Array[(String, String)]) -> (String, VAttr) {
  ("style", VStyle(styles))
}

///|
/// Create a dynamic style attribute
pub fn vstyle_dyn(getter : () -> Array[(String, String)]) -> (String, VAttr) {
  ("style", VDynamicStyle(getter))
}

///|
/// Check if element has dynamic content that needs hydration
pub fn has_dynamic_content(attrs : Array[(String, VAttr)]) -> Bool {
  for attr in attrs {
    let (_, value) = attr
    match value {
      VDynamic(_) | VHandler(_) | VDynamicStyle(_) => return true
      _ => ()
    }
  }
  false
}
