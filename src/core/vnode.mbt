///| VNode - DOM-independent virtual node representation for SSR

///|
/// Event handler type - wraps a callback function
/// For SSR: noop function. For DOM: actual event handler
pub struct EventHandler {
  /// The callback function (no-arg for simplicity, event can be captured via closure)
  callback : () -> Unit
}

///|
/// Create a placeholder event handler (for SSR - creates noop function)
pub fn event_handler() -> EventHandler {
  { callback: fn() { () } }
}

///|
/// Create an event handler from a simple callback
pub fn handler_from_callback(f : () -> Unit) -> EventHandler {
  { callback: f }
}

///|
/// Get the callback function
pub fn EventHandler::get_callback(self : EventHandler) -> () -> Unit {
  self.callback
}

///|
/// Attribute value that can be static or dynamic (signal-based)
pub enum Attr {
  VStatic(String)
  VDynamic(() -> String)
  VHandler(EventHandler)
  VAction(String) // Action name for declarative event handling
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
pub fn text_dyn(content : () -> String) -> Node {
  DynamicText(content)
}

///|
/// Create a text VNode from a signal
pub fn[T : Show] vtext_sig(sig : @signal.Signal[T]) -> Node {
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

///|
/// Check if element has dynamic content that needs hydration
pub fn has_dynamic_content(attrs : Array[(String, Attr)]) -> Bool {
  for attr in attrs {
    let (_, value) = attr
    match value {
      VDynamic(_) | VHandler(_) | VAction(_) => return true
      _ => ()
    }
  }
  false
}

// Attr factory functions for external packages

///|
/// Create a static attribute value
pub fn attr_static(value : String) -> Attr {
  VStatic(value)
}

///|
/// Create a dynamic attribute value
pub fn attr_dynamic(getter : () -> String) -> Attr {
  VDynamic(getter)
}

///|
/// Create a handler attribute value
pub fn attr_handler(handler : EventHandler) -> Attr {
  VHandler(handler)
}

///|
/// Create a style attribute value (string form, e.g. "color: red; margin: 10px")
pub fn attr_style(style : String) -> Attr {
  VStatic(style)
}

///|
/// Create a dynamic style attribute value
pub fn attr_dynamic_style(getter : () -> String) -> Attr {
  VDynamic(getter)
}

///|
/// Create an action attribute value - dispatches named action on event
/// Used for declarative event handling: ("onclick", action("increment"))
pub fn action(name : String) -> Attr {
  VAction(name)
}
