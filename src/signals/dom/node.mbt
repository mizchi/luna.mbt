///| Node types - DOM-independent interface for signals/dom

///|
/// Element wraps a DOM element (internal jsdom.Element)
pub struct Element {
  priv inner : @jsdom.Element
}

///|
/// Create Element from jsdom.Element (internal use)
pub fn Element::from_jsdom(elem : @jsdom.Element) -> Element {
  { inner: elem }
}

///|
/// Get the inner jsdom.Element (internal use)
pub fn Element::to_jsdom(self : Element) -> @jsdom.Element {
  self.inner
}

///|
/// Convert Element to Node
pub fn Element::to_node(self : Element) -> Node {
  El(self)
}

///|
/// Node represents any DOM node
pub enum Node {
  El(Element)
  Txt(@jsdom.Text)
  Raw(@jsdom.Node)
}

///|
/// Get the inner jsdom.Node
pub fn Node::to_jsdom(self : Node) -> @jsdom.Node {
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
  let doc = @jsdom.document()
  Txt(doc.createTextNode(self))
}

///|
/// @jsdom.Node -> Node (raw node)
pub impl ToNode for @jsdom.Node with to_node(self) {
  Raw(self)
}

///|
/// @jsdom.Element -> Node
pub impl ToNode for @jsdom.Element with to_node(self) {
  El(Element::from_jsdom(self))
}

///|
/// @jsdom.Text -> Node
pub impl ToNode for @jsdom.Text with to_node(self) {
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
