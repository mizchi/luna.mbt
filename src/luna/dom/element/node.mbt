// DomNode - Browser-specific DOM node types
//
// DomNode is designed for client-side rendering with full interactivity:
// - Event handlers (click, input, etc.)
// - Reactive updates (signals, effects)
// - DOM manipulation
//
// Unlike ServerDomNode, DomNode cannot contain ServerDomNode children.
// This enforces the Server Component / Client Component boundary.
//

///|
/// DomElement wraps a DOM element (internal @js_dom.Element)
pub struct DomElement {
  priv inner : @js_dom.Element
}

///|
/// Create DomElement from @js_dom.Element
pub fn DomElement::from_dom(elem : @js_dom.Element) -> DomElement {
  { inner: elem }
}

///|
/// Get the inner @js_dom.Element
pub fn DomElement::to_dom(self : DomElement) -> @js_dom.Element {
  self.inner
}

///|
/// Convert DomElement to DomNode
pub fn DomElement::to_node(self : DomElement) -> DomNode {
  El(self)
}

///|
/// DomNode represents any DOM node for client-side rendering
pub enum DomNode {
  El(DomElement)
  Txt(@js_dom.Text)
  Raw(@js_dom.Node)
  /// Static node - content is pre-rendered and skipped during reconciliation/hydration
  /// Use static_content() to create static nodes from VNode trees
  Static(@js_dom.Node)
}

///|
/// Get the inner @js_dom.Node
pub fn DomNode::to_dom(self : DomNode) -> @js_dom.Node {
  match self {
    El(elem) => elem.inner.as_node()
    Txt(text) => text.as_node()
    Raw(node) => node
    Static(node) => node
  }
}

///|
/// ToDomNode trait - types that can be converted to DomNode
pub trait ToDomNode {
  to_dom_node(Self) -> DomNode
}

///|
/// DomElement -> DomNode
pub impl ToDomNode for DomElement with to_dom_node(self) {
  El(self)
}

///|
/// String -> DomNode (creates text node)
pub impl ToDomNode for String with to_dom_node(self) {
  let doc = @js_dom.document()
  Txt(doc.createTextNode(self))
}

///|
/// @js_dom.Node -> DomNode (raw node)
pub impl ToDomNode for @js_dom.Node with to_dom_node(self) {
  Raw(self)
}

///|
/// @js_dom.Element -> DomNode
pub impl ToDomNode for @js_dom.Element with to_dom_node(self) {
  El(DomElement::from_dom(self))
}

///|
/// @js_dom.Text -> DomNode
pub impl ToDomNode for @js_dom.Text with to_dom_node(self) {
  Txt(self)
}

///|
/// DomNode -> DomNode (identity)
pub impl ToDomNode for DomNode with to_dom_node(self) {
  self
}

///|
/// Helper to convert any ToDomNode to DomNode
pub fn[T : ToDomNode] dom_node(value : T) -> DomNode {
  ToDomNode::to_dom_node(value)
}

///|
/// Collect children with ToDomNode conversion
pub fn[T : ToDomNode] dom_children(items : Array[T]) -> Array[DomNode] {
  items.map(ToDomNode::to_dom_node)
}

///|
/// Create a Static DomNode from a @js_dom.Node
/// Static nodes are skipped during reconciliation and hydration
pub fn static_node(node : @js_dom.Node) -> DomNode {
  Static(node)
}
