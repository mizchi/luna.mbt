// Node types - DOM-independent interface for signals/dom
//

///|
/// Element wraps a DOM element (internal @js_dom.Element)
pub struct Element {
  priv inner : @js_dom.Element
}

///|
/// Create Element from @js_dom.Element
pub fn Element::from_dom(elem : @js_dom.Element) -> Element {
  { inner: elem }
}

///|
/// Get the inner @js_dom.Element
pub fn Element::to_dom(self : Element) -> @js_dom.Element {
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
/// Get the inner @js_dom.Node
pub fn Node::to_dom(self : Node) -> @js_dom.Node {
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
  El(Element::from_dom(self))
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
  items.map(ToNode::to_node)
}
