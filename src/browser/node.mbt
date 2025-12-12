///| Node types - DOM-independent interface for signals/dom

// =============================================================================
// Browser-specific VNode type aliases (Event type = @core.Any)
// =============================================================================

///|
/// Browser VNode type (uses @core.Any for event type)
pub struct BrowserVNode {
  inner : @kaguya.Node[@core.Any]
}

///|
/// Browser Attr type (uses @core.Any for event type)
pub struct BrowserAttr {
  inner : @kaguya.Attr[@core.Any]
}

///|
/// Browser EventHandler type
pub struct BrowserEventHandler {
  inner : @kaguya.EventHandler[@core.Any]
}

///|
/// Create a browser event handler from a callback
pub fn browser_event_handler(f : (@core.Any) -> Unit) -> @kaguya.EventHandler[@core.Any] {
  @kaguya.handler(f)
}

///|
/// Create a noop browser event handler (for SSR compatibility in browser context)
pub fn browser_noop_handler() -> @kaguya.EventHandler[@core.Any] {
  @kaguya.handler(fn(_event) { () })
}

///|
/// Create a browser event handler from a simple callback (ignores event)
pub fn browser_handler_from_callback(f : () -> Unit) -> @kaguya.EventHandler[@core.Any] {
  @kaguya.handler(fn(_event) { f() })
}

///|
/// Element wraps a DOM element (internal jsdom.Element)
pub struct Element {
  priv inner : @js_dom.Element
}

///|
/// Create Element from jsdom.Element (internal use)
pub fn Element::from_jsdom(elem : @js_dom.Element) -> Element {
  { inner: elem }
}

///|
/// Get the inner jsdom.Element (internal use)
pub fn Element::to_jsdom(self : Element) -> @js_dom.Element {
  self.inner
}

///|
/// Convert Element to Node
pub fn Element::to_node(self : Element) -> Node {
  El(self)
}

///|
/// Internal any value type
#external
pub type AnyValue

///|
/// Node represents any DOM node
pub enum Node {
  El(Element)
  Txt(@js_dom.Text)
  Raw(@js_dom.Node)
}

///|
/// Get the inner jsdom.Node
pub fn Node::to_jsdom(self : Node) -> @js_dom.Node {
  match self {
    El(elem) => elem.inner.as_node()
    Txt(text) => text.as_node()
    Raw(node) => node
  }
}

///|
/// ToNode trait - types that can be converted to Node
pub trait ToNode {
  to_node(Self) -> Node
}

///|
/// Element -> Node
pub impl ToNode for Element with to_node(self) {
  El(self)
}

///|
/// String -> Node (creates text node)
pub impl ToNode for String with to_node(self) {
  let doc = @js_dom.document()
  Txt(doc.createTextNode(self))
}

///|
/// @js_dom.Node -> Node (raw node)
pub impl ToNode for @js_dom.Node with to_node(self) {
  Raw(self)
}

///|
/// @js_dom.Element -> Node
pub impl ToNode for @js_dom.Element with to_node(self) {
  El(Element::from_jsdom(self))
}

///|
/// @js_dom.Text -> Node
pub impl ToNode for @js_dom.Text with to_node(self) {
  Txt(self)
}

///|
/// Node -> Node (identity)
pub impl ToNode for Node with to_node(self) {
  self
}

///|
/// Helper to convert any ToNode to Node
pub fn[T : ToNode] node(value : T) -> Node {
  ToNode::to_node(value)
}

///|
/// Collect children with ToNode conversion
pub fn[T : ToNode] children(items : Array[T]) -> Array[Node] {
  let result : Array[Node] = []
  for i = 0; i < items.length(); i = i + 1 {
    result.push(ToNode::to_node(items[i]))
  }
  result
}
